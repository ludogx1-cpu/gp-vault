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
