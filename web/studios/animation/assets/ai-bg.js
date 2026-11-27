/*
 * AI background removal (Pro): page-side helper for ai-worker.js.
 *
 *   await GP_AI.ensure(progress)   // downloads the model once (~46 MB), starts the worker
 *   await GP_AI.cutOut(ctx, w, h, edge)   // makes everything but the subject transparent
 *
 * Nothing is uploaded: the model runs on the visitor's own device.
 */
window.GP_AI = (function () {
    const base = document.currentScript ? document.currentScript.src : location.href;
    const MODEL_URL = new URL('../models/isnet-general-use-q8.onnx', base).href;
    const MODEL_MB = 46;
    // How hard the edge is: [lower, upper] confidence that maps to fully clear / fully solid.
    const EDGES = { soft: [0.03, 0.97], normal: [0.15, 0.85], crisp: [0.35, 0.65] };

    let worker = null, ready = null, nextId = 1, provider = '';
    const pending = new Map();

    function call(msg, transfer) {
        return new Promise((resolve, reject) => {
            const id = nextId++;
            pending.set(id, { resolve, reject });
            worker.postMessage(Object.assign({ id }, msg), transfer || []);
        });
    }

    async function download(onProgress) {
        const res = await fetch(MODEL_URL);
        if (!res.ok) throw new Error(`Couldn't download the AI model (HTTP ${res.status}).`);
        const total = +res.headers.get('content-length') || MODEL_MB * 1e6;
        if (!res.body || !res.body.getReader) return res.arrayBuffer();
        const reader = res.body.getReader();
        const chunks = []; let got = 0;
        for (;;) {
            const { done, value } = await reader.read();
            if (done) break;
            chunks.push(value); got += value.length;
            if (onProgress) onProgress(Math.min(1, got / total), got);
        }
        const buf = new Uint8Array(got); let off = 0;
        for (const c of chunks) { buf.set(c, off); off += c.length; }
        return buf.buffer;
    }

    function ensure(onProgress) {
        if (ready) return ready;
        ready = (async () => {
            worker = new Worker(new URL('ai-worker.js', base));
            worker.onmessage = (e) => {
                const m = e.data;
                if (m.type === 'ready') provider = m.provider;
                const p = pending.get(m.id);
                if (!p) return;
                pending.delete(m.id);
                if (m.type === 'error') p.reject(new Error(m.message)); else p.resolve(m);
            };
            worker.onerror = (e) => { for (const p of pending.values()) p.reject(new Error(e.message || 'The AI worker stopped.')); pending.clear(); };
            const model = await download(onProgress);
            await call({ type: 'init', model }, [model]);
        })();
        ready.catch(() => { ready = null; if (worker) worker.terminate(); worker = null; });
        return ready;
    }

    /**
     * Cleans the AI mask: keeps the subject and any large parts (at least 2% of the
     * biggest), drops small loose specks the model sometimes leaves in busy backgrounds,
     * and keeps soft edges only within EDGE_PX of what's kept. a: alpha bytes with the
     * given stride (1 for a plain mask, 4 for RGBA), w × h pixels. Edits a in place.
     */
    function dropSpecks(a, w, h, stride) {
        const P = w * h, CORE = 64, EDGE_PX = Math.max(4, Math.round(Math.max(w, h) / 80));
        const label = new Int32Array(P), queue = new Int32Array(P), sizes = [0];
        const al = i => a[i * stride];
        // 1. Solid parts ("cores"): 8-connected pixels at least 25% opaque.
        for (let s = 0; s < P; s++) {
            if (label[s] || al(s) < CORE) continue;
            const id = sizes.length; let n = 0, head = 0, tail = 0;
            label[s] = id; queue[tail++] = s;
            while (head < tail) {
                const i = queue[head++], x = i % w, y = (i - x) / w; n++;
                for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                    const nx = x + dx, ny = y + dy;
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    const j = ny * w + nx;
                    if (!label[j] && al(j) >= CORE) { label[j] = id; queue[tail++] = j; }
                }
            }
            sizes.push(n);
        }
        if (sizes.length < 2) return; // nothing solid: leave the mask as it is
        const keep = Math.max(1, Math.max(...sizes) * 0.02);
        // 2. Spread from the kept parts through softer pixels, up to EDGE_PX away.
        const dist = new Int32Array(P).fill(-1);
        let head = 0, tail = 0;
        for (let i = 0; i < P; i++) if (label[i] && sizes[label[i]] >= keep) { dist[i] = 0; queue[tail++] = i; }
        while (head < tail) {
            const i = queue[head++], x = i % w, y = (i - x) / w;
            if (dist[i] >= EDGE_PX) continue;
            for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                const nx = x + dx, ny = y + dy;
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                const j = ny * w + nx;
                if (dist[j] < 0 && al(j) > 0 && !label[j]) { dist[j] = dist[i] + 1; queue[tail++] = j; }
            }
        }
        // 3. Everything not reached becomes transparent.
        for (let i = 0; i < P; i++) if (dist[i] < 0) a[i * stride] = 0;
    }

    async function cutOut(ctx, w, h, edge) {
        const [lo, hi] = EDGES[edge] || EDGES.normal;
        const bmp = await createImageBitmap(ctx.canvas, 0, 0, w, h);
        const { mask, size } = await call({ type: 'mask', bitmap: bmp }, [bmp]);
        const mc = document.createElement('canvas');
        mc.width = size; mc.height = size;
        const mx = mc.getContext('2d');
        const id = mx.createImageData(size, size);
        const k = 1 / (hi - lo), l = lo * 255;
        // Map the model's confidence through the chosen edge window: below lo → clear,
        // above hi → solid, smooth in between (the Uint8ClampedArray clamps for us).
        for (let i = 0; i < mask.length; i++) id.data[i * 4 + 3] = (mask[i] - l) * k;
        dropSpecks(id.data.subarray(3), size, size, 4);
        mx.putImageData(id, 0, 0);
        ctx.save();
        ctx.globalCompositeOperation = 'destination-in';
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(mc, 0, 0, w, h);
        ctx.restore();
    }

    return {
        ensure,
        cutOut,
        get provider() { return provider; },
        get loaded() { return !!worker && !!provider; },
        MODEL_MB
    };
})();
