/*
 * AI background removal worker (Golden Paw Animation Creation Tool, Pro).
 * Runs the IS-Net segmentation model (Apache-2.0) with onnxruntime-web, entirely
 * on the visitor's device. Uses the graphics card (WebGPU) where available and
 * falls back to the processor (WebAssembly).
 *
 * Messages in:  {type:'init', model:ArrayBuffer}
 *               {type:'mask', id, bitmap:ImageBitmap}
 * Messages out: {type:'ready', provider}
 *               {type:'mask', id, mask:Uint8ClampedArray(size*size), size}
 *               {type:'error', id, message}
 */
importScripts('../vendor/ort/ort.webgpu.min.js');

const SIZE = 1024; // IS-Net's fixed input size
ort.env.wasm.wasmPaths = new URL('../vendor/ort/', self.location.href).href;
// Multi-threading needs a cross-origin-isolated page (the desktop app is); the website runs single-threaded.
ort.env.wasm.numThreads = self.crossOriginIsolated ? Math.max(1, Math.min(4, (navigator.hardwareConcurrency || 4) - 1)) : 1;

let session = null;
let provider = '';

async function createSession(model) {
    const tryGpu = 'gpu' in navigator && await navigator.gpu.requestAdapter().then(a => !!a).catch(() => false);
    if (tryGpu) {
        try {
            const s = await ort.InferenceSession.create(model, { executionProviders: ['webgpu'] });
            provider = 'webgpu';
            return s;
        } catch (e) { /* fall through to the processor */ }
    }
    provider = 'wasm';
    return ort.InferenceSession.create(model, { executionProviders: ['wasm'] });
}

self.onmessage = async (e) => {
    const m = e.data;
    try {
        if (m.type === 'init') {
            if (!session) session = await createSession(m.model);
            self.postMessage({ type: 'ready', id: m.id, provider });
            return;
        }
        if (m.type === 'mask') {
            if (!session) throw new Error('The AI model is not loaded yet.');
            const c = new OffscreenCanvas(SIZE, SIZE);
            const x = c.getContext('2d', { willReadFrequently: true });
            x.drawImage(m.bitmap, 0, 0, SIZE, SIZE);
            m.bitmap.close();
            const px = x.getImageData(0, 0, SIZE, SIZE).data;
            const P = SIZE * SIZE;
            const input = new Float32Array(3 * P);
            for (let i = 0; i < P; i++) {
                input[i] = px[i * 4] / 255 - 0.5;
                input[P + i] = px[i * 4 + 1] / 255 - 0.5;
                input[2 * P + i] = px[i * 4 + 2] / 255 - 0.5;
            }
            const out = await session.run({ [session.inputNames[0]]: new ort.Tensor('float32', input, [1, 3, SIZE, SIZE]) });
            const o = out[session.outputNames[0]].data;
            let mn = Infinity, mx = -Infinity;
            for (let i = 0; i < P; i++) { const v = o[i]; if (v < mn) mn = v; if (v > mx) mx = v; }
            // The model outputs a 0..1 probability map. Only stretch it if it isn't one,
            // so an empty frame isn't amplified into noise.
            const stretch = mn < -0.01 || mx > 1.01;
            const span = mx - mn || 1;
            const mask = new Uint8ClampedArray(P);
            for (let i = 0; i < P; i++) mask[i] = 255 * (stretch ? (o[i] - mn) / span : o[i]);
            self.postMessage({ type: 'mask', id: m.id, mask, size: SIZE }, [mask.buffer]);
        }
    } catch (err) {
        self.postMessage({ type: 'error', id: m.id, message: (err && err.message) || String(err) });
    }
};
