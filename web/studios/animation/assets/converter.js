// Golden Paw Animation Creation Tool: video to sprite sheet converter.
/* global JSZip, GIF */

// ============ Element refs ============
const $ = (id) => document.getElementById(id);
const videoUpload = $('videoUpload');
const uploadZone = $('uploadZone');
const sourceVideoPlayer = $('sourceVideoPlayer');
const timeDisplayContainer = $('timeDisplayContainer');
const videoTimeDisplay = $('videoTimeDisplay');
const timeShortcuts = $('timeShortcuts');

const startH = $('startH'), startM = $('startM'), startS = $('startS'), startMs = $('startMs');
const endH = $('endH'), endM = $('endM'), endS = $('endS'), endMs = $('endMs');
const startInputs = [startH, startM, startS, startMs];
const endInputs = [endH, endM, endS, endMs];

const fpsInput = $('fps');
const loopMode = $('loopMode');
const bakeLoopFrames = $('bakeLoopFrames');
const bakeLoopRow = $('bakeLoopRow');

const removeBgToggle = $('removeBgToggle');
const aiBgToggle = $('aiBgToggle');
const aiSettings = $('aiSettings');
const aiLocked = $('aiLocked');
const aiEdge = $('aiEdge');
const aiStatus = $('aiStatus');
const aiPreviewBtn = $('aiPreviewBtn');
const bgColorInput = $('bgColor');
const pickColorBtn = $('pickColorBtn');
const bgToleranceInput = $('bgTolerance');
const toleranceValue = $('toleranceValue');
const bgFeatherInput = $('bgFeather');
const featherValue = $('featherValue');
const chromaPreviewCanvas = $('chromaPreviewCanvas');
const matchMode = $('matchMode');
const despillInput = $('despill');
const despillValue = $('despillValue');

const addBgToggle = $('addBgToggle');
const addBgColor = $('addBgColor');
const bgSettings = $('bgSettings');
const addBgSettings = $('addBgSettings');

const outSpriteWebp = $('outSpriteWebp');
const outZipWebp = $('outZipWebp');
const outAnimGif = $('outAnimGif');
const outMetaJson = $('outMetaJson');
const webpScale = $('webpScale');
const webpScaleValue = $('webpScaleValue');
const webpQuality = $('webpQuality');
const webpQualityValue = $('webpQualityValue');
const spriteCols = $('spriteCols');
const spriteColsValue = $('spriteColsValue');
const estimateBox = $('estimateBox');
const imageFormat = $('imageFormat');
const autoTrim = $('autoTrim');
const potPad = $('potPad');
const supportNotice = $('supportNotice');

const generateBtn = $('generateBtn');
const cancelBtn = $('cancelBtn');
const progressBar = $('progressBar');
const downloadContainer = $('downloadContainer');
const previewImg = $('previewImg');
const playBtn = $('playBtn');
const previewFpsInput = $('previewFps');
const frameScrub = $('frameScrub');
const frameCounter = $('frameCounter');
const canvas = $('outputCanvas');
const ctx = canvas.getContext('2d', { willReadFrequently: true });
const spritePreviewImg = $('spritePreviewImg');
const spriteDims = $('spriteDims');
const rebuildBtn = $('rebuildBtn');
const rebuildStatus = $('rebuildStatus');

const themeToggle = $('themeToggle');
const transformDesc = $('transformDesc');

// ============ State (Blob-based, not data-URL) ============
/** @type {{blob: Blob, url: string}[]} */ let frames = [];
let isPlaying = false;
let playInterval;
let currentFrameIndex = 0;
/** @type {string[]} */ let activeUrls = [];
let isCancelled = false;
let currentVideoUrl = null;
/** Live GIF encoder, so Cancel can abort it mid-render. */
let activeGif = null;
/** Raw (transformed, un-keyed) pixels behind the chroma preview, for accurate colour picking. */
let rawPreviewData = null;
/** Bounding box of visible pixels, unioned across every frame. Null when trimming is off. */
let trimBox = null;
/** Encoded frame size before trimming, so metadata can describe the original. */
let untrimmedSize = null;

// Transform state
const transform = { rotate: 0, flipH: false, flipV: false };

// ============ Encoding format ============
// Some browsers silently hand back a PNG when asked for WebP, which would give you
// .webp files that aren't WebP. Detect it once and take WebP off the menu if so.
let webpSupported = true;
(function detectWebp() {
    const c = document.createElement('canvas');
    c.width = c.height = 1;
    webpSupported = c.toDataURL('image/webp').startsWith('data:image/webp');
    if (!webpSupported) {
        imageFormat.value = 'image/png';
        imageFormat.querySelector('option[value="image/webp"]').disabled = true;
        supportNotice.classList.remove('hidden');
        supportNotice.innerHTML = '<strong>This browser can\'t encode WebP.</strong> Frame format has been switched to PNG. Chrome, Edge, Firefox and Safari 16.4+ all support WebP if you want the smaller files.';
    }
})();

function outFormat() { return imageFormat.value; }
function outExt() { return imageFormat.value === 'image/png' ? 'png' : 'webp'; }
function outQuality() {
    // PNG is lossless; passing a quality argument does nothing but confuse.
    return imageFormat.value === 'image/png' ? undefined : parseInt(webpQuality.value) / 100;
}

// ============ Theme ============
// Safari on file:// and some private-browsing modes throw on localStorage access.
// Unguarded, that exception killed the rest of the script and the tool did nothing at all.
function readStored(key) {
    try { return localStorage.getItem(key); } catch (e) { return null; }
}
function writeStored(key, value) {
    try { localStorage.setItem(key, value); } catch (e) { /* theme just won't persist */ }
}
// Reads the old v5 key once so existing users keep their choice.
const savedTheme = readStored('acv7-theme') || readStored('acv5-theme') || 'light';
if (savedTheme === 'dark') { document.documentElement.setAttribute('data-theme', 'dark'); themeToggle.innerText = '☀️ Light'; }
themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    if (isDark) { document.documentElement.removeAttribute('data-theme'); themeToggle.innerText = '🌙 Dark'; writeStored('acv7-theme','light'); }
    else { document.documentElement.setAttribute('data-theme','dark'); themeToggle.innerText = '☀️ Light'; writeStored('acv7-theme','dark'); }
});

// ============ Slider live labels ============
webpScale.addEventListener('input', () => { webpScaleValue.innerText = webpScale.value; updateEstimate(); });
webpQuality.addEventListener('input', () => { webpQualityValue.innerText = webpQuality.value; updateEstimate(); });
spriteCols.addEventListener('input', () => { spriteColsValue.innerText = spriteCols.value === '0' ? 'auto' : spriteCols.value; });
bgToleranceInput.addEventListener('input', () => { toleranceValue.innerText = bgToleranceInput.value; requestChromaPreview(); });
bgFeatherInput.addEventListener('input', () => { featherValue.innerText = bgFeatherInput.value; requestChromaPreview(); });
despillInput.addEventListener('input', () => { despillValue.innerText = despillInput.value; requestChromaPreview(); });
matchMode.addEventListener('change', requestChromaPreview);
bgColorInput.addEventListener('input', requestChromaPreview);
imageFormat.addEventListener('change', () => { webpQuality.disabled = imageFormat.value === 'image/png'; updateEstimate(); });
webpQuality.disabled = imageFormat.value === 'image/png';

// Keep the two background panels in step with their checkboxes.
function syncBgPanels() {
    // bgSettings stays visible even when the toggle is off: it holds the live preview
    // you click to pick a colour, and clicking it is what turns the toggle on.
    addBgSettings.classList.toggle('hidden', !addBgToggle.checked);
    // Trimming needs transparency to find an edge, so it can't run under a solid fill.
    autoTrim.disabled = addBgToggle.checked || !(removeBgToggle.checked || aiBgToggle.checked);
    const pro = !!(window.GP_PRO && GP_PRO.isPro());
    aiSettings.classList.toggle('hidden', !(aiBgToggle.checked && pro));
}
removeBgToggle.addEventListener('change', () => { syncBgPanels(); requestChromaPreview(); });
addBgToggle.addEventListener('change', syncBgPanels);

// ============ AI background removal (Pro) ============
document.querySelectorAll('[data-pro-price]').forEach(el => { if (window.GP_PRO) el.textContent = GP_PRO.price; });
function aiEnabled() { return aiBgToggle.checked && !!(window.GP_PRO && GP_PRO.isPro()) && !!window.GP_AI; }
aiBgToggle.addEventListener('change', () => {
    const pro = !!(window.GP_PRO && GP_PRO.isPro());
    if (aiBgToggle.checked && !pro) {
        aiBgToggle.checked = false;
        aiLocked.classList.remove('hidden');
        aiLocked.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    } else {
        aiLocked.classList.add('hidden');
    }
    syncBgPanels();
});
if (window.GP_PRO) GP_PRO.onChange(() => { aiLocked.classList.add('hidden'); syncBgPanels(); });

function aiProgressText(frac) {
    return `Downloading the AI (${Math.round(frac * GP_AI.MODEL_MB)} of ${GP_AI.MODEL_MB} MB, one time only)…`;
}
async function loadAi() {
    if (!GP_AI.loaded) aiStatus.textContent = aiProgressText(0);
    await GP_AI.ensure(f => { aiStatus.textContent = aiProgressText(f); generateBtn.innerText = aiProgressText(f); });
    aiStatus.textContent = GP_AI.provider === 'webgpu'
        ? 'AI ready, running on your graphics card.'
        : 'AI ready, running on your processor. This can take a few seconds per frame; Chrome or Edge on a computer with a graphics card is much faster.';
}

aiPreviewBtn.addEventListener('click', async () => {
    if (!aiEnabled()) return;
    if (sourceVideoPlayer.style.display === 'none' || !sourceVideoPlayer.videoWidth) {
        aiStatus.textContent = 'Load a video first, then pause it on the frame you want to check.';
        return;
    }
    aiPreviewBtn.disabled = true;
    try {
        await loadAi();
        updateChromaPreview();
        const pctx = chromaPreviewCanvas.getContext('2d', { willReadFrequently: true });
        if (rawPreviewData) pctx.putImageData(rawPreviewData, 0, 0);
        aiStatus.textContent = 'Cutting out this frame…';
        const t0 = performance.now();
        await GP_AI.cutOut(pctx, chromaPreviewCanvas.width, chromaPreviewCanvas.height, aiEdge.value);
        if (removeBgToggle.checked) applyChromaKey(pctx, chromaPreviewCanvas.width, chromaPreviewCanvas.height, currentKeyOptions());
        chromaPreviewMode.innerText = '(showing the AI cut-out)';
        aiStatus.textContent = `Done in ${((performance.now() - t0) / 1000).toFixed(1)} s. The preview below shows the result.`;
        chromaPreviewCanvas.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    } catch (e) {
        aiStatus.textContent = 'AI preview failed: ' + e.message;
    } finally {
        aiPreviewBtn.disabled = false;
    }
});
syncBgPanels();

// The "bake loop frames" choice only means anything once a loop mode is picked.
function syncBakeLoopRow() { bakeLoopRow.classList.toggle('hidden', loopMode.value === 'none'); }
loopMode.addEventListener('change', syncBakeLoopRow);
syncBakeLoopRow();

// ============ Cancel ============
cancelBtn.addEventListener('click', () => {
    isCancelled = true;
    cancelBtn.innerText = 'Cancelling...';
    cancelBtn.disabled = true;
    // The GIF encoder runs in workers and won't notice the flag on its own.
    if (activeGif) { try { activeGif.abort(); } catch (e) { /* already finished */ } }
});

// ============ File loading (input + drag-drop) ============
function loadFile(file) {
    if (!file) return;
    if (currentVideoUrl) { URL.revokeObjectURL(currentVideoUrl); currentVideoUrl = null; }
    if (file.type.startsWith('video/')) {
        currentVideoUrl = URL.createObjectURL(file);
        sourceVideoPlayer.src = currentVideoUrl;
        sourceVideoPlayer.style.display = 'block';
        timeDisplayContainer.style.display = 'block';
        timeShortcuts.style.display = 'flex';
    } else {
        sourceVideoPlayer.style.display = 'none';
        timeDisplayContainer.style.display = 'none';
        timeShortcuts.style.display = 'none';
    }
    // Reflect the file in the input so generateBtn sees it
    const dt = new DataTransfer();
    dt.items.add(file);
    videoUpload.files = dt.files;
    rawPreviewData = null;
    validateTimes();
    updateEstimate();
    requestChromaPreview();
}

videoUpload.addEventListener('change', () => {
    if (videoUpload.files && videoUpload.files[0]) loadFile(videoUpload.files[0]);
});

['dragenter','dragover'].forEach(evt =>
    uploadZone.addEventListener(evt, (e) => { e.preventDefault(); uploadZone.classList.add('dragging'); }));
['dragleave','drop'].forEach(evt =>
    uploadZone.addEventListener(evt, (e) => { e.preventDefault(); if (evt === 'drop' || e.target === uploadZone) uploadZone.classList.remove('dragging'); }));
uploadZone.addEventListener('drop', (e) => {
    uploadZone.classList.remove('dragging');
    const file = e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0];
    if (file) loadFile(file);
});

// ============ Video time display ============
sourceVideoPlayer.addEventListener('timeupdate', () => {
    const t = sourceVideoPlayer.currentTime;
    const h = Math.floor(t / 3600);
    const m = Math.floor((t % 3600) / 60);
    const s = Math.floor(t % 60);
    const ms = Math.floor((t % 1) * 1000);
    videoTimeDisplay.innerText = `${h}h ${m}m ${s}s ${ms}ms`;
});

sourceVideoPlayer.addEventListener('seeked', requestChromaPreview);
sourceVideoPlayer.addEventListener('loadeddata', requestChromaPreview);
sourceVideoPlayer.addEventListener('canplay', requestChromaPreview);
sourceVideoPlayer.addEventListener('timeupdate', requestChromaPreview);
sourceVideoPlayer.addEventListener('loadedmetadata', () => { updateEstimate(); requestChromaPreview(); });

// ============ Set-from-current buttons ============
function secondsToInputs(t, inputs) {
    const h = Math.floor(t / 3600);
    const m = Math.floor((t % 3600) / 60);
    const s = Math.floor(t % 60);
    const ms = Math.floor((t % 1) * 1000);
    inputs[0].value = h; inputs[1].value = m; inputs[2].value = s; inputs[3].value = ms;
    validateTimes(); updateEstimate();
}
$('setStartFromCurrent').addEventListener('click', () => secondsToInputs(sourceVideoPlayer.currentTime, startInputs));
$('setEndFromCurrent').addEventListener('click', () => secondsToInputs(sourceVideoPlayer.currentTime, endInputs));

// ============ Time inputs -> validation + estimate ============
function inputsToSeconds(inputs) {
    return (parseInt(inputs[0].value) || 0) * 3600
         + (parseInt(inputs[1].value) || 0) * 60
         + (parseInt(inputs[2].value) || 0)
         + (parseInt(inputs[3].value) || 0) / 1000;
}
function validateTimes() {
    if (!sourceVideoPlayer.duration || !isFinite(sourceVideoPlayer.duration)) return true;
    const startSec = inputsToSeconds(startInputs);
    let endSec = inputsToSeconds(endInputs);
    const endIsSentinel = endInputs.every(i => (parseInt(i.value)||0) === 0);
    if (endIsSentinel) endSec = sourceVideoPlayer.duration;
    const invalid = startSec >= endSec || startSec >= sourceVideoPlayer.duration;
    [...startInputs, ...endInputs].forEach(i => i.classList.toggle('invalid', invalid));
    return !invalid;
}
[...startInputs, ...endInputs, fpsInput].forEach(i => i.addEventListener('input', () => { validateTimes(); updateEstimate(); }));

// ============ Limits ============
// Above this many frames the blob cache gets heavy enough to be worth a warning.
const FRAME_WARN_THRESHOLD = 600;
// Browsers refuse to allocate canvases past roughly these bounds; Chrome is the tightest.
const MAX_CANVAS_SIDE = 16384;
const MAX_CANVAS_AREA = 268435456; // ~268 megapixels

// ============ Estimate ============
function updateEstimate() {
    if (!sourceVideoPlayer.duration || !isFinite(sourceVideoPlayer.duration)) {
        // maybe an image
        const file = videoUpload.files && videoUpload.files[0];
        if (file && file.type.startsWith('image/')) {
            estimateBox.innerHTML = `<strong>Estimate:</strong> Single image, ~${(file.size/1024).toFixed(0)} KB source.`;
        }
        return;
    }
    const startSec = inputsToSeconds(startInputs);
    let endSec = inputsToSeconds(endInputs);
    const endIsSentinel = endInputs.every(i => (parseInt(i.value)||0) === 0);
    if (endIsSentinel || endSec > sourceVideoPlayer.duration) endSec = sourceVideoPlayer.duration;
    const dur = Math.max(0, endSec - startSec);
    const fps = parseInt(fpsInput.value) || 12;
    const count = Math.floor(dur * fps);
    const scale = parseInt(webpScale.value) / 100;
    const w = Math.floor(sourceVideoPlayer.videoWidth * scale);
    const h = Math.floor(sourceVideoPlayer.videoHeight * scale);
    const q = parseInt(webpQuality.value) / 100;
    // Very rough bytes-per-pixel. WebP at quality q ≈ 0.15 + q*0.6; PNG runs far heavier.
    const bpp = outFormat() === 'image/png' ? 2.0 : (0.15 + q * 0.6);
    const bytesPerFrame = w * h * bpp;
    const totalKB = (bytesPerFrame * count) / 1024;
    const sizeStr = totalKB > 1024 ? `${(totalKB/1024).toFixed(1)} MB` : `${totalKB.toFixed(0)} KB`;
    let msg = `<strong>Estimate:</strong> ${count} frames at ${w}×${h} · ~${sizeStr} total (rough).`;
    if (count > FRAME_WARN_THRESHOLD) {
        msg += ` <span style="color:var(--danger)">That's a lot of frames to hold in memory — trim the clip or drop the capture FPS if the tab struggles.</span>`;
    }
    estimateBox.innerHTML = msg;
}

// ============ Transform ============
document.querySelectorAll('[data-transform]').forEach(btn => {
    btn.addEventListener('click', () => {
        const t = btn.dataset.transform;
        if (t === 'rotate') transform.rotate = (transform.rotate + 90) % 360;
        else if (t === 'flipH') transform.flipH = !transform.flipH;
        else if (t === 'flipV') transform.flipV = !transform.flipV;
        else if (t === 'reset') { transform.rotate = 0; transform.flipH = false; transform.flipV = false; }
        const parts = [];
        if (transform.rotate) parts.push(`rotated ${transform.rotate}°`);
        if (transform.flipH) parts.push('flipped horizontally');
        if (transform.flipV) parts.push('flipped vertically');
        transformDesc.innerText = parts.length ? 'Currently ' + parts.join(', ') + '.' : 'No transform applied.';
        requestChromaPreview();
    });
});

// Draws a source (video/image) onto ctx with current transform applied.
// Returns the {w,h} of the resulting canvas.
function drawWithTransform(destCtx, source, srcW, srcH, destW, destH) {
    let outW = destW, outH = destH;
    if (transform.rotate % 180 !== 0) { outW = destH; outH = destW; }
    destCtx.canvas.width = outW;
    destCtx.canvas.height = outH;
    destCtx.save();
    destCtx.translate(outW / 2, outH / 2);
    destCtx.rotate(transform.rotate * Math.PI / 180);
    destCtx.scale(transform.flipH ? -1 : 1, transform.flipV ? -1 : 1);
    destCtx.drawImage(source, -destW / 2, -destH / 2, destW, destH);
    destCtx.restore();
    return { w: outW, h: outH };
}

// ============ Eyedropper ============
pickColorBtn.addEventListener('click', () => {
    if (sourceVideoPlayer.style.display === 'none' || !sourceVideoPlayer.src) {
        alert('Please upload a video first.');
        return;
    }
    pickColorBtn.innerText = 'Click on the video player...';
    sourceVideoPlayer.style.cursor = 'crosshair';
    const resetPicker = () => {
        pickColorBtn.innerText = '🔍 Pick exact color from video';
        sourceVideoPlayer.style.cursor = 'default';
    };
    const pickColor = (e) => {
        // A <video> letterboxes inside its box (object-fit: contain), so the drawn image
        // is usually smaller than the element. Work out the real content rectangle first
        // or clicks on tall/wide clips land on the wrong pixel — or on a black bar.
        const rect = sourceVideoPlayer.getBoundingClientRect();
        const vw = sourceVideoPlayer.videoWidth, vh = sourceVideoPlayer.videoHeight;
        const fit = Math.min(rect.width / vw, rect.height / vh);
        const dispW = vw * fit, dispH = vh * fit;
        const offX = (rect.width - dispW) / 2, offY = (rect.height - dispH) / 2;
        const x = Math.floor((e.clientX - rect.left - offX) / fit);
        const y = Math.floor((e.clientY - rect.top - offY) / fit);
        if (x < 0 || y < 0 || x >= vw || y >= vh) {
            pickColorBtn.innerText = 'That was outside the picture — click again';
            sourceVideoPlayer.addEventListener('click', pickColor, { once: true });
            return;
        }
        const tempCanvas = document.createElement('canvas');
        tempCanvas.width = vw;
        tempCanvas.height = vh;
        const tempCtx = tempCanvas.getContext('2d', { willReadFrequently: true });
        tempCtx.drawImage(sourceVideoPlayer, 0, 0, vw, vh);
        const pixel = tempCtx.getImageData(x, y, 1, 1).data;
        bgColorInput.value = rgbToHex(pixel[0], pixel[1], pixel[2]);
        removeBgToggle.checked = true;
        syncBgPanels();
        resetPicker();
        updateChromaPreview();
    };
    sourceVideoPlayer.addEventListener('click', pickColor, { once: true });
});

// ============ Live chroma preview (also serves as color picker) ============
const chromaPreviewMode = $('chromaPreviewMode');
let pickerModeActive = false; // when true, next click on preview picks color

// The preview does a full getImageData/putImageData pass, and video timeupdate fires
// several times a second during playback. Coalesce redraws into one per frame.
let previewQueued = false;
function requestChromaPreview() {
    if (previewQueued) return;
    previewQueued = true;
    requestAnimationFrame(() => { previewQueued = false; updateChromaPreview(); });
}

function updateChromaPreview() {
    // Show preview whenever we have a decoded video frame available
    if (sourceVideoPlayer.style.display === 'none' || !sourceVideoPlayer.videoWidth) {
        chromaPreviewCanvas.width = 0;
        rawPreviewData = null;
        chromaPreviewMode.innerText = '(upload a video to enable)';
        return;
    }
    if (sourceVideoPlayer.readyState < 2) {
        sourceVideoPlayer.addEventListener('loadeddata', updateChromaPreview, { once: true });
        return;
    }
    const previewW = Math.min(320, sourceVideoPlayer.videoWidth);
    const previewH = Math.floor(sourceVideoPlayer.videoHeight * (previewW / sourceVideoPlayer.videoWidth));
    const pctx = chromaPreviewCanvas.getContext('2d', { willReadFrequently: true });
    const { w, h } = drawWithTransform(pctx, sourceVideoPlayer, sourceVideoPlayer.videoWidth, sourceVideoPlayer.videoHeight, previewW, previewH);
    // Keep the untouched, already-transformed pixels so a click samples the same
    // orientation the user is looking at. Sampling the raw video instead would pick
    // the wrong pixel the moment a rotate or flip is active.
    rawPreviewData = pctx.getImageData(0, 0, w, h);
    if (removeBgToggle.checked) {
        applyChromaKey(pctx, w, h, currentKeyOptions());
        chromaPreviewMode.innerText = '(showing removal effect — click a pixel to pick color)';
    } else {
        chromaPreviewMode.innerText = '(showing raw frame — tick "Remove Background" to see removal, or click a pixel to pick color)';
    }
}

// Clicking the preview canvas picks a colour from the cached raw pixels.
chromaPreviewCanvas.addEventListener('click', (e) => {
    if (!rawPreviewData) return;
    const rect = chromaPreviewCanvas.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) * (rawPreviewData.width / rect.width));
    const y = Math.floor((e.clientY - rect.top) * (rawPreviewData.height / rect.height));
    if (x < 0 || y < 0 || x >= rawPreviewData.width || y >= rawPreviewData.height) return;
    const i = (y * rawPreviewData.width + x) * 4;
    const d = rawPreviewData.data;
    bgColorInput.value = rgbToHex(d[i], d[i+1], d[i+2]);
    removeBgToggle.checked = true;
    syncBgPanels();
    updateChromaPreview();
});
chromaPreviewCanvas.style.cursor = 'crosshair';

// ============ Colour helpers ============
function rgbToHex(r, g, b) {
    return '#' + (1 << 24 | r << 16 | g << 8 | b).toString(16).slice(1);
}
function hexToRgb(hex) {
    return {
        r: parseInt(hex.slice(1, 3), 16),
        g: parseInt(hex.slice(3, 5), 16),
        b: parseInt(hex.slice(5, 7), 16)
    };
}
/**
 * Chromaticity coordinates: each channel as a share of the pixel's total light.
 * Dividing out the total is what makes brightness genuinely stop counting, so a
 * shadowed corner of a backdrop keys on the same tolerance as a hot spot. (YCbCr
 * chrominance looks like the obvious choice here but still scales with luma, so a
 * dark green sits far from a bright one and the mode wouldn't do its job.)
 * Scaled back up to 0-255 so the tolerance slider behaves the same in both modes.
 */
function toChromaticity(r, g, b) {
    const sum = r + g + b;
    if (sum < 12) return null; // near-black: no meaningful hue to compare
    return { r: (r / sum) * 255, g: (g / sum) * 255 };
}

/** Gathers the current keying settings from the UI into one object. */
function currentKeyOptions() {
    const { r, g, b } = hexToRgb(bgColorInput.value);
    return {
        r, g, b,
        tolerance: parseInt(bgToleranceInput.value),
        feather: parseInt(bgFeatherInput.value),
        mode: matchMode.value,
        despill: parseInt(despillInput.value) / 100
    };
}

// ============ Core chroma-key (squared-distance + feathering + despill) ============
function applyChromaKey(destCtx, w, h, key) {
    const imgData = destCtx.getImageData(0, 0, w, h);
    const data = imgData.data;
    const chromaMode = key.mode === 'chroma';
    const tol = key.tolerance;
    const feather = key.feather;
    const tolInner = Math.max(0, tol - feather);
    const tolInner2 = tolInner * tolInner;
    const tol2 = tol * tol;
    const featherRange = tol - tolInner;

    const keyChroma = chromaMode ? toChromaticity(key.r, key.g, key.b) : null;

    // Despill works on whichever channel dominates the key colour: for a green screen
    // that's G, for a blue screen B. Capping it against the other two removes the cast.
    const strength = key.despill;
    const maxChannel = Math.max(key.r, key.g, key.b);
    let spillIdx = -1;
    if (strength > 0) {
        if (maxChannel === key.g && key.g > (key.r + key.b) / 2) spillIdx = 1;
        else if (maxChannel === key.b && key.b > (key.r + key.g) / 2) spillIdx = 2;
        else if (maxChannel === key.r && key.r > (key.g + key.b) / 2) spillIdx = 0;
    }

    for (let j = 0; j < data.length; j += 4) {
        const r = data[j], g = data[j+1], b = data[j+2];
        let d2;
        const c = chromaMode && keyChroma ? toChromaticity(r, g, b) : null;
        if (c) {
            const dr = c.r - keyChroma.r;
            const dg = c.g - keyChroma.g;
            d2 = dr * dr + dg * dg;
        } else {
            // Plain RGB, and also the fallback for near-black pixels in chroma mode,
            // where the hue ratio is pure noise.
            const dr = r - key.r, dg = g - key.g, db = b - key.b;
            d2 = dr * dr + dg * dg + db * db;
        }

        if (d2 < tolInner2) { data[j+3] = 0; continue; }
        if (d2 < tol2 && featherRange > 0) {
            data[j+3] = Math.round(((Math.sqrt(d2) - tolInner) / featherRange) * data[j+3]);
        }

        if (spillIdx >= 0 && data[j+3] > 0) {
            const a = spillIdx === 0 ? g : r;
            const bb = spillIdx === 2 ? g : b;
            const limit = (a + bb) / 2;
            const v = data[j + spillIdx];
            if (v > limit) data[j + spillIdx] = Math.round(v - (v - limit) * strength);
        }
    }
    destCtx.putImageData(imgData, 0, 0);
}

// ============ Preview playback + scrubbing ============
function showFrame(index) {
    if (frames.length === 0) return;
    currentFrameIndex = Math.max(0, Math.min(index, frames.length - 1));
    const f = frames[currentFrameIndex];
    if (f && f.url) previewImg.src = f.url;
    frameScrub.value = currentFrameIndex;
    frameCounter.innerText = `${currentFrameIndex + 1} / ${frames.length}`;
}

function syncScrubber() {
    const has = frames.length > 0;
    frameScrub.disabled = !has;
    frameScrub.max = has ? frames.length - 1 : 0;
    frameScrub.value = has ? currentFrameIndex : 0;
    frameCounter.innerText = has ? `${currentFrameIndex + 1} / ${frames.length}` : '— / —';
}

function stopPlayback() {
    clearInterval(playInterval);
    isPlaying = false;
    playBtn.innerText = 'Play Preview';
}

// Dragging the scrubber pauses playback — otherwise the two fight over the same image.
frameScrub.addEventListener('input', () => {
    if (isPlaying) stopPlayback();
    showFrame(parseInt(frameScrub.value) || 0);
});

playBtn.addEventListener('click', () => {
    if (frames.length === 0) { console.warn('No frames to preview'); return; }
    isPlaying = !isPlaying;
    playBtn.innerText = isPlaying ? "Pause Preview" : "Play Preview";
    if (isPlaying) {
        const fps = parseInt(previewFpsInput.value) || 12;
        playInterval = window.setInterval(() => {
            if (frames.length === 0) { stopPlayback(); return; }
            showFrame((currentFrameIndex + 1) % frames.length);
        }, 1000 / fps);
    } else {
        clearInterval(playInterval);
    }
});

// ============ Messages ============
const messageBox = $('messageBox');
/** Reports outcomes in the page rather than in a modal that interrupts the run. */
function notify(text, kind = 'info') {
    const div = document.createElement('div');
    div.className = kind === 'error' ? 'warn-box' : 'info-box';
    div.innerText = text;
    messageBox.appendChild(div);
}
function clearMessages() { messageBox.innerHTML = ''; }

// ============ Frame cache ============
/** Frees every frame blob URL exactly once, even where loop modes share one. */
function releaseFrames() {
    const seen = new Set();
    frames.forEach(f => {
        if (f && f.url && !seen.has(f.url)) { seen.add(f.url); URL.revokeObjectURL(f.url); }
    });
    frames = [];
    currentFrameIndex = 0;
    lastExport = null;
}

// ============ Download helper ============
function addDownloadButton(text, urlOrBlob, filename, kind) {
    const url = urlOrBlob instanceof Blob ? URL.createObjectURL(urlOrBlob) : urlOrBlob;
    const a = document.createElement('a');
    a.href = url; a.download = filename;
    a.className = 'download-btn'; a.innerText = text;
    // `kind` lets Rebuild find and replace its own outputs without matching label text.
    if (kind) a.dataset.kind = kind;
    downloadContainer.appendChild(a);
    activeUrls.push(url);
}

// ============ Hand-off to the Sprite Editor page ============
// Stores the current sheet (+ JSON, if made) in IndexedDB, then opens /editor.html,
// which picks it up. Nothing leaves the device.
function addEditorHandoff() {
    downloadContainer.querySelectorAll('[data-kind="editor"]').forEach(n => n.remove());
    const sheetLink = downloadContainer.querySelector('a.download-btn[data-kind="sprite"]');
    if (!sheetLink || !window.indexedDB) return;
    const btn = document.createElement('button');
    btn.type = 'button'; btn.dataset.kind = 'editor';
    btn.className = 'editor-handoff';
    btn.innerText = '✏️ Open in Sprite Editor: preview, delete & reorder frames';
    btn.addEventListener('click', async () => {
        btn.disabled = true; btn.innerText = 'Opening editor...';
        try {
            const sheet = await (await fetch(sheetLink.href)).blob();
            const jsonLink = downloadContainer.querySelector('a.download-btn[download$=".json"]');
            const json = jsonLink ? await (await fetch(jsonLink.href)).text() : null;
            await new Promise((resolve, reject) => {
                const req = indexedDB.open('vts-handoff', 1);
                req.onupgradeneeded = () => req.result.createObjectStore('h');
                req.onerror = () => reject(req.error);
                req.onsuccess = () => {
                    const tx = req.result.transaction('h', 'readwrite');
                    tx.objectStore('h').put({ sheet, json, name: sheetLink.getAttribute('download') }, 'latest');
                    tx.oncomplete = resolve; tx.onerror = () => reject(tx.error);
                };
            });
            location.href = '/studios/animation/editor.html?from=converter';
        } catch (err) {
            console.error(err);
            btn.disabled = false;
            btn.innerText = '✏️ Open in Sprite Editor';
            notify('Could not hand the sheet to the editor (private browsing can block this). Download it and load it in the editor instead.', 'error');
        }
    });
    downloadContainer.appendChild(btn);
}

// ============ Canvas -> Blob helper ============
function canvasToBlob(cnv, type, quality) {
    return new Promise((resolve, reject) => {
        cnv.toBlob(b => b ? resolve(b) : reject(new Error('toBlob failed')), type, quality);
    });
}

// ============ Scratch canvas ============
// One canvas reused for every frame instead of allocating a fresh one each time.
const scratchCanvas = document.createElement('canvas');
const scratchCtx = scratchCanvas.getContext('2d', { willReadFrequently: true });

/** Expands `box` to cover every pixel in `data` with alpha above the threshold. */
function growBounds(box, data, w, h, threshold = 8) {
    for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
            if (data[(y * w + x) * 4 + 3] > threshold) {
                if (x < box.x0) box.x0 = x;
                if (x > box.x1) box.x1 = x;
                if (y < box.y0) box.y0 = y;
                if (y > box.y1) box.y1 = y;
            }
        }
    }
}

// ============ Process one frame -> Blob ============
async function processFrameData(sourceElement, srcW, srcH, destW, destH, options) {
    const { w, h } = drawWithTransform(scratchCtx, sourceElement, srcW, srcH, destW, destH);
    if (options.aiBg) {
        generateBtn.innerText = `AI removing background: frame ${options.frameNum + 1} of ${options.totalFrames}`;
        await GP_AI.cutOut(scratchCtx, w, h, options.aiEdge);
    }
    if (options.removeBg) {
        applyChromaKey(scratchCtx, w, h, options.key);
    }
    if (options.trim) {
        growBounds(trimBox, scratchCtx.getImageData(0, 0, w, h).data, w, h);
    }
    if (options.addBg) {
        scratchCtx.globalCompositeOperation = 'destination-over';
        scratchCtx.fillStyle = options.addBgColorHex;
        scratchCtx.fillRect(0, 0, w, h);
        scratchCtx.globalCompositeOperation = 'source-over';
    }
    untrimmedSize = { w, h };
    const blob = await canvasToBlob(scratchCanvas, options.format, options.quality);
    frames.push({ blob, url: URL.createObjectURL(blob) });
}

// ============ Sprite sheet builder (from Blobs) ============
let spritePreviewUrl = null; // track the sprite preview blob URL so we can revoke it
let extractionScale = 1;     // the scale at which the cached frames were extracted
/** What the last Process run packed into the sheet; used by Rebuild. */
let lastExport = null;

function nextPowerOfTwo(n) {
    let p = 1;
    while (p < n) p *= 2;
    return p;
}

/** Throws a readable error if a sheet of this size is beyond what browsers will allocate. */
function assertCanvasFits(w, h) {
    if (w > MAX_CANVAS_SIDE || h > MAX_CANVAS_SIDE) {
        throw new Error(
            `The sheet would be ${w}×${h}px and browsers cap a canvas at ${MAX_CANVAS_SIDE}px per side. ` +
            `Raise the Sprite Columns value to make it squarer, lower the Output Scale, or capture fewer frames.`
        );
    }
    if (w * h > MAX_CANVAS_AREA) {
        throw new Error(
            `The sheet would be ${w}×${h}px, about ${(w*h/1e6).toFixed(0)} megapixels, which is past the browser limit. ` +
            `Lower the Output Scale or capture fewer frames.`
        );
    }
}

async function buildSpriteSheet(frameList, isImage, colsOverride, relativeScale = 1) {
    progressBar.max = 100;
    progressBar.value = 0;
    const fmt = outFormat(), ext = outExt(), q = outQuality();
    const first = await createImageBitmap(frameList[0].blob);
    // relativeScale downsamples each cached frame further at composition time
    const w = Math.max(1, Math.floor(first.width * relativeScale));
    const h = Math.max(1, Math.floor(first.height * relativeScale));
    if (isImage) {
        if (relativeScale === 1) {
            addDownloadButton(`Download processed image (${ext.toUpperCase()})`, frameList[0].blob, `processed_image.${ext}`, 'sprite');
            if (spritePreviewUrl) URL.revokeObjectURL(spritePreviewUrl);
            spritePreviewUrl = URL.createObjectURL(frameList[0].blob);
            spritePreviewImg.src = spritePreviewUrl;
            spriteDims.innerText = `${w} × ${h} px (single image, ${(frameList[0].blob.size/1024).toFixed(1)} KB)`;
        } else {
            assertCanvasFits(w, h);
            canvas.width = w; canvas.height = h;
            ctx.clearRect(0, 0, w, h);
            ctx.drawImage(first, 0, 0, w, h);
            const blob = await canvasToBlob(canvas, fmt, q);
            addDownloadButton(`Download processed image (${ext.toUpperCase()})`, blob, `processed_image.${ext}`, 'sprite');
            if (spritePreviewUrl) URL.revokeObjectURL(spritePreviewUrl);
            spritePreviewUrl = URL.createObjectURL(blob);
            spritePreviewImg.src = spritePreviewUrl;
            spriteDims.innerText = `${w} × ${h} px (single image, ${(blob.size/1024).toFixed(1)} KB)`;
        }
        first.close();
        return { w, h, cols: 1, rows: 1, sheetW: w, sheetH: h };
    }
    const cols = colsOverride > 0 ? Math.min(colsOverride, frameList.length) : Math.ceil(Math.sqrt(frameList.length));
    const rows = Math.ceil(frameList.length / cols);
    let sheetW = w * cols, sheetH = h * rows;
    if (potPad.checked) { sheetW = nextPowerOfTwo(sheetW); sheetH = nextPowerOfTwo(sheetH); }
    try {
        assertCanvasFits(sheetW, sheetH);
    } catch (e) {
        first.close();
        throw e;
    }
    canvas.width = sheetW;
    canvas.height = sheetH;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(first, 0, 0, w, h);
    first.close();
    for (let i = 1; i < frameList.length; i++) {
        if (isCancelled) throw new Error('Cancelled by user');
        generateBtn.innerText = `Building sprite sheet... (${i + 1}/${frameList.length})`;
        progressBar.value = (i / frameList.length) * 100;
        const bmp = await createImageBitmap(frameList[i].blob);
        const x = (i % cols) * w;
        const y = Math.floor(i / cols) * h;
        ctx.drawImage(bmp, x, y, w, h);
        bmp.close();
        if (i % 8 === 0) await new Promise(r => setTimeout(r, 0));
    }
    const blob = await canvasToBlob(canvas, fmt, q);
    addDownloadButton(`Download sprite sheet (${ext.toUpperCase()})`, blob, `spritesheet.${ext}`, 'sprite');
    if (spritePreviewUrl) URL.revokeObjectURL(spritePreviewUrl);
    spritePreviewUrl = URL.createObjectURL(blob);
    spritePreviewImg.src = spritePreviewUrl;
    const potNote = potPad.checked ? `, padded to power-of-two` : '';
    spriteDims.innerText = `${canvas.width} × ${canvas.height} px (${cols} cols × ${rows} rows${potNote}, ${(blob.size/1024).toFixed(1)} KB)`;
    return { w, h, cols, rows, sheetW, sheetH };
}

// ============ ZIP builder ============
async function createZipArchive(frameList, ext) {
    generateBtn.innerText = `Packing ${ext.toUpperCase()} ZIP...`;
    // The builders report 0-100 percentages, but extraction left max at the frame count.
    progressBar.max = 100;
    progressBar.value = 0;
    const zip = new JSZip();
    const pad = String(frameList.length - 1).length;
    for (let i = 0; i < frameList.length; i++) {
        zip.file(`frame_${i.toString().padStart(Math.max(3, pad), '0')}.${ext}`, frameList[i].blob);
    }
    const content = await zip.generateAsync({type: "blob"}, (metadata) => {
        generateBtn.innerText = `Packing ${ext.toUpperCase()} ZIP... ${metadata.percent.toFixed(0)}%`;
        progressBar.value = metadata.percent;
    });
    if (isCancelled) throw new Error('Cancelled by user');
    addDownloadButton(`Download ${ext.toUpperCase()} ZIP Folder`, content, `frames_${ext}.zip`);
}

// ============ Animated GIF builder ============
/**
 * GIF has one transparent palette entry, so transparency is done by keying out a
 * colour. Picking a fixed green destroys any genuinely green pixel in the source, so
 * find a candidate that doesn't appear in the artwork instead.
 */
async function pickGifKeyColour(frameList) {
    const candidates = [0xFF00FF, 0x00FF00, 0x00FFFF, 0xFE0136, 0x7F00FF, 0xFF7F00];
    const used = new Set();
    const step = Math.max(1, Math.floor(frameList.length / 8));
    const probe = document.createElement('canvas');
    const pctx = probe.getContext('2d', { willReadFrequently: true });
    for (let i = 0; i < frameList.length; i += step) {
        const bmp = await createImageBitmap(frameList[i].blob);
        probe.width = bmp.width; probe.height = bmp.height;
        pctx.clearRect(0, 0, probe.width, probe.height);
        pctx.drawImage(bmp, 0, 0);
        bmp.close();
        const d = pctx.getImageData(0, 0, probe.width, probe.height).data;
        for (let j = 0; j < d.length; j += 4) {
            if (d[j+3] < 128) continue;
            used.add((d[j] << 16) | (d[j+1] << 8) | d[j+2]);
        }
    }
    return candidates.find(c => !used.has(c)) ?? 0xFF00FF;
}

async function buildAnimatedGif(frameList, fps) {
    generateBtn.innerText = 'Encoding animated GIF...';
    progressBar.max = 100;
    progressBar.value = 0;
    const first = await createImageBitmap(frameList[0].blob);
    const w = first.width, h = first.height;
    first.close();

    const keyInt = await pickGifKeyColour(frameList);
    const keyHex = rgbToHex((keyInt >> 16) & 255, (keyInt >> 8) & 255, keyInt & 255);

    const workerScript = '/studios/animation/vendor/gif.worker.js';
    const gif = new GIF({
        workers: 2, quality: 10, width: w, height: h,
        workerScript, transparent: keyInt
    });
    activeGif = gif;

    const tmp = document.createElement('canvas');
    tmp.width = w; tmp.height = h;
    const tctx = tmp.getContext('2d', { willReadFrequently: true });
    // GIF delays are stored in hundredths of a second, so round to that grid up front.
    const delay = Math.max(20, Math.round(1000 / fps / 10) * 10);

    for (let i = 0; i < frameList.length; i++) {
        if (isCancelled) throw new Error('Cancelled by user');
        const bmp = await createImageBitmap(frameList[i].blob);
        tctx.clearRect(0, 0, w, h);
        tctx.drawImage(bmp, 0, 0);
        bmp.close();
        // GIF alpha is all-or-nothing. Snap partly transparent pixels one way or the
        // other before compositing, otherwise every feathered edge blends into the key
        // colour and comes out as a coloured halo.
        const img = tctx.getImageData(0, 0, w, h);
        const d = img.data;
        for (let j = 0; j < d.length; j += 4) {
            if (d[j+3] < 128) { d[j+3] = 0; } else { d[j+3] = 255; }
        }
        tctx.putImageData(img, 0, 0);
        tctx.globalCompositeOperation = 'destination-over';
        tctx.fillStyle = keyHex;
        tctx.fillRect(0, 0, w, h);
        tctx.globalCompositeOperation = 'source-over';
        gif.addFrame(tctx, { delay, copy: true });
        if (i % 8 === 0) await new Promise(r => setTimeout(r, 0));
    }

    try {
        await new Promise((resolve, reject) => {
            // If the CDN worker is blocked the encoder never reports anything, so give up
            // rather than leaving the UI stuck on "Encoding GIF...".
            let sawProgress = false;
            const watchdog = setTimeout(() => {
                if (!sawProgress) {
                    try { gif.abort(); } catch (e) { /* nothing to abort */ }
                    reject(new Error('The GIF encoder never started. Its worker script is loaded from a CDN — check your connection or any content blockers.'));
                }
            }, 15000);
            gif.on('progress', (p) => {
                sawProgress = true;
                progressBar.value = p * 100;
                generateBtn.innerText = `Encoding GIF... ${(p*100).toFixed(0)}%`;
            });
            gif.on('finished', (blob) => {
                clearTimeout(watchdog);
                addDownloadButton('Download animated GIF', blob, 'animation.gif');
                resolve();
            });
            gif.on('abort', () => {
                clearTimeout(watchdog);
                reject(new Error(isCancelled ? 'Cancelled by user' : 'GIF encoding was aborted'));
            });
            gif.render();
        });
    } finally {
        activeGif = null;
    }
}

// ============ Seeking ============
/**
 * Seeks a video and waits for it to land. Setting currentTime to a value the video is
 * already at may not fire `seeked` at all, and a damaged keyframe can swallow the seek
 * outright — either way the old code awaited a promise that never settled and the whole
 * tool hung with no way out. The timeout turns that into an error you can act on.
 */
function seekTo(video, time, timeoutMs = 8000) {
    return new Promise((resolve, reject) => {
        if (Math.abs(video.currentTime - time) < 0.0005 && video.readyState >= 2) {
            resolve();
            return;
        }
        let done = false;
        const timer = setTimeout(() => {
            if (done) return;
            done = true;
            video.removeEventListener('seeked', onSeeked);
            reject(new Error(`Seeking to ${time.toFixed(3)}s timed out. The file may be damaged, or this browser may not be able to seek this codec accurately.`));
        }, timeoutMs);
        const onSeeked = () => {
            if (done) return;
            done = true;
            clearTimeout(timer);
            // Some browsers report 'seeked' before the new picture can be drawn.
            if (video.readyState >= 2) return resolve();
            const ready = () => { clearTimeout(fallback); resolve(); };
            const fallback = setTimeout(() => { video.removeEventListener('loadeddata', ready); video.removeEventListener('canplay', ready); resolve(); }, 1500);
            video.addEventListener('loadeddata', ready, { once: true });
            video.addEventListener('canplay', ready, { once: true });
        };
        video.addEventListener('seeked', onSeeked, { once: true });
        video.currentTime = time;
    });
}

// ============ Loop modes ============
function applyLoopMode() {
    const mode = loopMode.value;
    if (frames.length < 2) return;
    if (mode === 'hold') {
        // A distinct entry sharing the same blob, so the cleanup pass doesn't try to
        // revoke one object URL twice.
        frames.push({ blob: frames[0].blob, url: frames[0].url, shared: true });
    } else if (mode === 'pingpong') {
        // Walk back down the middle of the sequence; the two end frames are already
        // on screen for one beat each, so repeating them would stutter.
        for (let i = frames.length - 2; i >= 1; i--) {
            frames.push({ blob: frames[i].blob, url: frames[i].url, shared: true });
        }
    }
}

// ============ Video decode loop ============
async function processVideoFile(file, scale, options) {
    const video = document.createElement('video');
    const vurl = URL.createObjectURL(file);
    video.preload = 'auto';
    video.muted = true;
    video.src = vurl;
    try {
        // Wait for the first decoded picture, not just the metadata: capturing at 0s
        // before then draws an empty canvas, which used to make frame 1 blank.
        await new Promise((resolve, reject) => {
            if (video.readyState >= 2) return resolve();
            const t = setTimeout(() => (video.readyState >= 1 ? resolve() : reject(new Error('Video failed to load'))), 10000);
            video.addEventListener('loadeddata', () => { clearTimeout(t); resolve(); }, { once: true });
            video.onerror = () => { clearTimeout(t); reject(new Error('Video failed to load')); };
        });

        const startSec = inputsToSeconds(startInputs);
        let endSec = inputsToSeconds(endInputs);
        const endIsSentinel = endInputs.every(i => (parseInt(i.value)||0) === 0);
        if (endIsSentinel || endSec > video.duration) endSec = video.duration;

        if (startSec >= endSec || startSec >= video.duration) {
            notify('Start time must come before end time, and start must fall inside the clip.', 'error');
            throw new Error('Invalid timestamps');
        }

        const fps = parseInt(fpsInput.value) || 12;
        const captureDuration = endSec - startSec;
        const totalVideoFrames = Math.max(1, Math.floor(captureDuration * fps));
        const w = Math.max(1, Math.floor(video.videoWidth * scale));
        const h = Math.max(1, Math.floor(video.videoHeight * scale));
        options.totalFrames = totalVideoFrames;
        progressBar.max = totalVideoFrames;

        if (totalVideoFrames > FRAME_WARN_THRESHOLD) {
            const go = confirm(
                `This will extract ${totalVideoFrames} frames and hold them all in memory. ` +
                `That can take a while and may exhaust the tab on a long clip.\n\n` +
                `OK to continue, or Cancel to go back and shorten the clip or lower the capture FPS.`
            );
            if (!go) throw new Error('Cancelled by user');
        }

        for (let i = 0; i < totalVideoFrames; i++) {
            if (isCancelled) throw new Error('Cancelled by user');
            generateBtn.innerText = `Extracting frame ${i + 1} of ${totalVideoFrames}`;
            progressBar.value = i + 1;
            const time = startSec + Math.min((i / fps), captureDuration - 0.01);
            await seekTo(video, time);
            options.frameNum = i;
            await processFrameData(video, video.videoWidth, video.videoHeight, w, h, options);
            if (i % 4 === 0) await new Promise(r => setTimeout(r, 0)); // keep UI responsive
        }
        // Loop frames are appended after trimming, in the main handler.
    } finally {
        URL.revokeObjectURL(vurl);
    }
}

// ============ Auto-trim ============
/**
 * Re-encodes every cached frame cropped to one bounding box shared by the whole
 * sequence. A shared box is what keeps the sprite grid uniform; per-frame boxes would
 * pack tighter but every cell would be a different size.
 * Returns the trim descriptor for the metadata, or null if nothing was trimmed.
 */
async function applyTrim() {
    if (!trimBox || trimBox.x1 < trimBox.x0 || !untrimmedSize) return null;
    const x = trimBox.x0, y = trimBox.y0;
    const tw = trimBox.x1 - trimBox.x0 + 1;
    const th = trimBox.y1 - trimBox.y0 + 1;
    if (tw >= untrimmedSize.w && th >= untrimmedSize.h) return null; // nothing to gain

    generateBtn.innerText = 'Trimming transparent padding...';
    progressBar.max = 100;
    const fmt = outFormat(), q = outQuality();
    scratchCanvas.width = tw;
    scratchCanvas.height = th;
    for (let i = 0; i < frames.length; i++) {
        if (isCancelled) throw new Error('Cancelled by user');
        progressBar.value = (i / frames.length) * 100;
        const bmp = await createImageBitmap(frames[i].blob);
        scratchCtx.clearRect(0, 0, tw, th);
        scratchCtx.drawImage(bmp, -x, -y);
        bmp.close();
        const blob = await canvasToBlob(scratchCanvas, fmt, q);
        URL.revokeObjectURL(frames[i].url);
        frames[i] = { blob, url: URL.createObjectURL(blob) };
        if (i % 8 === 0) await new Promise(r => setTimeout(r, 0));
    }
    return { x, y, w: tw, h: th, sourceW: untrimmedSize.w, sourceH: untrimmedSize.h };
}

async function processImageFile(file, scale, options) {
    generateBtn.innerText = 'Processing Image...';
    const img = new Image();
    const iurl = URL.createObjectURL(file);
    img.src = iurl;
    try {
        await new Promise((resolve, reject) => { img.onload = resolve; img.onerror = () => reject(new Error('Image failed to load')); });
        const w = Math.max(1, Math.floor(img.width * scale));
        const h = Math.max(1, Math.floor(img.height * scale));
        await processFrameData(img, img.width, img.height, w, h, options);
        fpsInput.value = '1';
    } finally {
        URL.revokeObjectURL(iurl);
    }
}

// ============ Atlas metadata ============
/**
 * TexturePacker "JSON Hash" layout, which Phaser, Pixi and most 2D engines load as-is,
 * with the old grid fields kept alongside for anything reading the v5/v6 format.
 * When trimming ran, spriteSourceSize/sourceSize tell the engine where the cropped art
 * sat in the original frame so nothing shifts on screen.
 */
function buildAtlasJson(spriteInfo, trimInfo, fps, ext, bakeLoop = false, count = frames.length) {
    const cols = spriteInfo ? spriteInfo.cols : (parseInt(spriteCols.value) > 0 ? Math.min(parseInt(spriteCols.value), count) : Math.ceil(Math.sqrt(count)));
    const rows = spriteInfo ? spriteInfo.rows : Math.ceil(count / cols);
    const fw = spriteInfo ? spriteInfo.w : (trimInfo ? trimInfo.w : (untrimmedSize ? untrimmedSize.w : 0));
    const fh = spriteInfo ? spriteInfo.h : (trimInfo ? trimInfo.h : (untrimmedSize ? untrimmedSize.h : 0));
    const sourceW = trimInfo ? trimInfo.sourceW : fw;
    const sourceH = trimInfo ? trimInfo.sourceH : fh;

    const framesHash = {};
    const pad = Math.max(3, String(count - 1).length);
    for (let i = 0; i < count; i++) {
        framesHash[`frame_${String(i).padStart(pad, '0')}.${ext}`] = {
            frame: { x: (i % cols) * fw, y: Math.floor(i / cols) * fh, w: fw, h: fh },
            rotated: false,
            trimmed: !!trimInfo,
            spriteSourceSize: { x: trimInfo ? trimInfo.x : 0, y: trimInfo ? trimInfo.y : 0, w: fw, h: fh },
            sourceSize: { w: sourceW, h: sourceH },
            duration: Math.round(1000 / fps)
        };
    }

    return {
        frames: framesHash,
        meta: {
            app: 'Golden Paw Animation Creation Tool',
            image: spriteInfo ? `spritesheet.${ext}` : null,
            format: 'RGBA8888',
            size: { w: spriteInfo ? spriteInfo.sheetW : cols * fw, h: spriteInfo ? spriteInfo.sheetH : rows * fh },
            scale: '1',
            fps: fps,
            // When the loop is baked into the frames the sequence already plays straight
            // through, so the hint is 'forward'; otherwise it tells the engine to bounce.
            frameTags: [{ name: 'all', from: 0, to: Math.max(0, count - 1), direction: (!bakeLoop && loopMode.value === 'pingpong') ? 'pingpong' : 'forward' }]
        },
        // Grid description, kept for compatibility with earlier versions of this tool.
        frameWidth: fw,
        frameHeight: fh,
        cols, rows,
        count,
        fps,
        trimmed: trimInfo || null,
        transform: { rotate: transform.rotate, flipH: transform.flipH, flipV: transform.flipV }
    };
}

// ============ Main entry ============
generateBtn.addEventListener('click', async () => {
    const files = videoUpload.files;
    if (!files || !files[0]) { clearMessages(); notify('Upload a video or image first.', 'error'); return; }
    const anyOutput = outSpriteWebp.checked || outZipWebp.checked || outAnimGif.checked || outMetaJson.checked;
    if (!anyOutput) { clearMessages(); notify('Tick at least one output format in section 2.', 'error'); return; }

    isCancelled = false;
    generateBtn.innerText = 'Processing...';
    generateBtn.disabled = true;
    cancelBtn.style.display = 'block';
    cancelBtn.disabled = false;
    cancelBtn.innerText = 'Cancel';
    downloadContainer.innerHTML = '';
    clearMessages();
    progressBar.style.display = 'block';
    progressBar.value = 0; progressBar.max = 100;

    try {
        stopPlayback();

        // Drop the old preview before revoking, or the img is left pointing at a dead URL.
        previewImg.removeAttribute('src');
        releaseFrames();
        activeUrls.forEach(u => URL.revokeObjectURL(u));
        activeUrls = [];
        // buildSpriteSheet only frees this when it runs again; free it here too so an
        // unticked sprite box on the next run doesn't strand the previous preview blob.
        if (spritePreviewUrl) { URL.revokeObjectURL(spritePreviewUrl); spritePreviewUrl = null; }
        spritePreviewImg.removeAttribute('src');
        syncScrubber();
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        const file = files[0];
        const isImage = file.type.startsWith('image/');

        // Trimming needs somewhere to trim to: transparency from the chroma key, and no
        // solid fill painted back over it.
        const useAi = aiEnabled();
        const wantTrim = autoTrim.checked && (removeBgToggle.checked || useAi) && !addBgToggle.checked;
        trimBox = wantTrim ? { x0: Infinity, y0: Infinity, x1: -Infinity, y1: -Infinity } : null;
        untrimmedSize = null;

        const options = {
            removeBg: removeBgToggle.checked,
            aiBg: useAi,
            aiEdge: aiEdge.value,
            addBg: addBgToggle.checked,
            addBgColorHex: addBgColor.value,
            key: currentKeyOptions(),
            trim: wantTrim,
            format: outFormat(),
            quality: outQuality(),
            frameNum: 0,
            totalFrames: 1
        };

        if (useAi) await loadAi();

        const scale = parseInt(webpScale.value) / 100;
        extractionScale = scale; // remember for future rebuilds

        if (isImage) {
            await processImageFile(file, scale, options);
        } else {
            await processVideoFile(file, scale, options);
        }

        const trimInfo = wantTrim ? await applyTrim() : null;

        if (frames.length > 0) {
            previewFpsInput.value = isImage ? '1' : fpsInput.value;
        }

        const ext = outExt();
        const fps = parseInt(fpsInput.value) || 12;
        let spriteInfo = null;

        // Loop modes are normally a playback concern: the sprite sheet, the frame ZIP
        // and the metadata describe the frames exactly as captured, and the metadata
        // carries a `direction` hint for engines that honour it. Tick "Bake loop frames"
        // to instead write the reversed/held frames into the sheet and ZIP as real
        // cells. Either way the in-page preview and the GIF always play the full loop.
        const bakeLoop = !isImage && loopMode.value !== 'none' && bakeLoopFrames.checked;
        if (bakeLoop) applyLoopMode();

        if (outZipWebp.checked) await createZipArchive(frames, ext);
        if (outSpriteWebp.checked) spriteInfo = await buildSpriteSheet(frames, isImage, parseInt(spriteCols.value));
        // Remember exactly which frames the sheet and JSON describe, before the
        // preview-only loop expansion below, so Rebuild can repack the same set.
        lastExport = { sheetFrames: frames.slice(), trimInfo, fps, bakeLoop, isImage };

        if (outMetaJson.checked && frames.length > 0) {
            const meta = buildAtlasJson(spriteInfo, trimInfo, fps, ext, bakeLoop);
            const jsonBlob = new Blob([JSON.stringify(meta, null, 2)], { type: 'application/json' });
            addDownloadButton('Download atlas metadata (.json)', jsonBlob, 'spritesheet.json');
            if (!spriteInfo) {
                notify('Metadata describes the grid your frames would form. Tick "Sprite sheet" as well if you need the image it refers to.');
            }
        }

        // If the loop wasn't baked above, expand it now for the preview + GIF only.
        if (!isImage && !bakeLoop) applyLoopMode();

        if (outAnimGif.checked && !isImage) {
            await buildAnimatedGif(frames, fps);
        } else if (outAnimGif.checked && isImage) {
            notify('Animated GIF skipped — a single image has nothing to animate.');
        }

        if (trimInfo) {
            notify(`Trimmed to ${trimInfo.w}×${trimInfo.h} from ${trimInfo.sourceW}×${trimInfo.sourceH}. The offset is recorded in the metadata.`, 'info');
        }
        addEditorHandoff();

        // Set the preview LAST, after all builders are done, so nothing can interfere
        // with the img element loading the same blob URL.
        if (frames.length > 0) {
            previewImg.onerror = () => console.error('Preview image failed to load frame 0');
            // Defer to next tick so the browser registers the src change
            await new Promise(r => setTimeout(r, 0));
            currentFrameIndex = 0;
            syncScrubber();
            showFrame(0);
            // Enable the rebuild button now that we have cached frames
            rebuildBtn.disabled = false;
            rebuildBtn.title = `Rebuild sprite sheet from ${frames.length} cached frames`;
            // Auto-start playback if we have more than one frame
            if (frames.length > 1 && !isPlaying) {
                setTimeout(() => playBtn.click(), 100);
            }
        }

    } catch (err) {
        if (err.message === 'Cancelled by user') {
            generateBtn.innerText = 'Process cancelled';
            setTimeout(() => { if (!generateBtn.disabled) generateBtn.innerText = 'Process File'; }, 2000);
        } else if (err.message === 'Invalid timestamps') {
            // Already reported next to the time fields.
        } else {
            console.error(err);
            notify(err.message, 'error');
        }
    } finally {
        generateBtn.disabled = false;
        if (generateBtn.innerText !== 'Process cancelled') generateBtn.innerText = 'Process File';
        cancelBtn.style.display = 'none';
        cancelBtn.disabled = false;
        cancelBtn.innerText = 'Cancel';
        activeGif = null;
        progressBar.style.display = 'none';
        // Lets batch mode (pro-tools.js) know this run has finished.
        document.dispatchEvent(new CustomEvent('gp:processed'));
    }
});
// ============ Rebuild sprite sheet from cached frames (no re-decode) ============
rebuildBtn.addEventListener('click', async () => {
    if (frames.length === 0) return;
    const currentScale = parseInt(webpScale.value) / 100;
    const relative = currentScale / extractionScale;
    if (relative > 1.001) {
        const proceed = confirm(
            `You're asking for ${(currentScale*100).toFixed(0)}% scale but the cached frames were extracted at ${(extractionScale*100).toFixed(0)}%. ` +
            `Rebuild can only downsample, not upscale. ` +
            `Click Cancel and use "Process File" to re-extract at the higher scale, or OK to rebuild at ${(extractionScale*100).toFixed(0)}% anyway.`
        );
        if (!proceed) return;
    }
    const effectiveRelative = Math.min(1, relative);
    const originalText = rebuildBtn.innerText;
    rebuildBtn.disabled = true;
    rebuildBtn.innerText = 'Rebuilding...';
    rebuildStatus.innerText = '';
    clearMessages();
    // Remove existing sprite / processed image download links so we don't accumulate stale ones
    downloadContainer.querySelectorAll('a.download-btn[data-kind="sprite"]').forEach(a => {
        URL.revokeObjectURL(a.href);
        const idx = activeUrls.indexOf(a.href);
        if (idx >= 0) activeUrls.splice(idx, 1);
        a.remove();
    });
    try {
        const src = lastExport ? lastExport.sheetFrames : frames;
        const isImage = lastExport ? lastExport.isImage : frames.length === 1;
        const t0 = performance.now();
        const spriteInfo = await buildSpriteSheet(src, isImage, parseInt(spriteCols.value), effectiveRelative);

        // Regenerate the atlas so it matches the rebuilt sheet (size, columns, trim offsets).
        downloadContainer.querySelectorAll('a.download-btn[download="spritesheet.json"]').forEach(a => {
            URL.revokeObjectURL(a.href);
            const i = activeUrls.indexOf(a.href);
            if (i >= 0) activeUrls.splice(i, 1);
            a.remove();
        });
        if (outMetaJson.checked && lastExport && !isImage) {
            const t = lastExport.trimInfo;
            const k = t ? spriteInfo.w / t.w : 1;
            const scaledTrim = t ? { ...t, x: Math.round(t.x * k), y: Math.round(t.y * k), w: spriteInfo.w, h: spriteInfo.h,
                                     sourceW: Math.round(t.sourceW * k), sourceH: Math.round(t.sourceH * k) } : null;
            const meta = buildAtlasJson(spriteInfo, scaledTrim, lastExport.fps, outExt(), lastExport.bakeLoop, src.length);
            addDownloadButton('Download atlas metadata (.json)', new Blob([JSON.stringify(meta, null, 2)], { type: 'application/json' }), 'spritesheet.json');
        }
        const dt = ((performance.now() - t0) / 1000).toFixed(2);
        const qualityNote = outFormat() === 'image/png' ? 'PNG (lossless)' : `quality ${webpQuality.value}%`;
        addEditorHandoff();
        rebuildStatus.innerText = `✓ Rebuilt in ${dt}s at ${(effectiveRelative*extractionScale*100).toFixed(0)}% scale, ${qualityNote}`;
    } catch (err) {
        console.error(err);
        rebuildStatus.innerText = '✗ Rebuild failed';
        notify(err.message, 'error');
    } finally {
        rebuildBtn.disabled = false;
        rebuildBtn.innerText = originalText;
    }
});
