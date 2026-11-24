/*
 * Converter extras: presets (built-in for everyone, your own with Pro) and
 * batch processing (Pro). Loaded after converter.js and reuses its functions,
 * so batch runs go through exactly the same pipeline as a single clip.
 */
(function () {
    const $ = id => document.getElementById(id);
    const isPro = () => !!(window.GP_PRO && GP_PRO.isPro());

    // ---------------- Presets ----------------
    // Every setting a preset remembers (by element id).
    const FIELDS = ['fps', 'loopMode', 'bakeLoopFrames', 'removeBgToggle', 'bgColor', 'bgTolerance', 'bgFeather',
        'matchMode', 'despill', 'addBgToggle', 'addBgColor', 'aiBgToggle', 'aiEdge', 'outSpriteWebp', 'outZipWebp',
        'outAnimGif', 'outMetaJson', 'imageFormat', 'autoTrim', 'potPad', 'webpScale', 'webpQuality', 'spriteCols'];

    const BUILT_IN = {
        'Phaser / PixiJS: WebP, trimmed': { fps: '12', outSpriteWebp: true, outMetaJson: true, outZipWebp: false, outAnimGif: false, imageFormat: 'image/webp', autoTrim: true, potPad: false, webpScale: '100', webpQuality: '85', spriteCols: '0' },
        'Godot / Unity: PNG grid': { fps: '12', outSpriteWebp: true, outMetaJson: true, outZipWebp: false, outAnimGif: false, imageFormat: 'image/png', autoTrim: false, potPad: false, webpScale: '100', spriteCols: '0' },
        'Pixel art: crisp PNG': { imageFormat: 'image/png', bgFeather: '0', despill: '0', aiEdge: 'crisp', autoTrim: true, outSpriteWebp: true, outMetaJson: true },
        'Mobile game: small, power-of-two': { imageFormat: 'image/webp', webpScale: '50', webpQuality: '80', autoTrim: true, potPad: true, outSpriteWebp: true, outMetaJson: true },
        'Social / Discord GIF': { fps: '15', outAnimGif: true, outSpriteWebp: false, outMetaJson: false, outZipWebp: false, webpScale: '50' }
    };
    const STORE = 'gp-presets';
    const readMine = () => { try { return JSON.parse(localStorage.getItem(STORE) || '{}'); } catch (e) { return {}; } };
    const writeMine = (v) => { try { localStorage.setItem(STORE, JSON.stringify(v)); } catch (e) {} };

    const select = $('presetSelect'), saveBtn = $('presetSave'), delBtn = $('presetDelete'), presetMsg = $('presetMsg');

    function capture() {
        const o = {};
        for (const id of FIELDS) { const el = $(id); if (el) o[id] = el.type === 'checkbox' ? el.checked : el.value; }
        return o;
    }
    function apply(values) {
        for (const [id, v] of Object.entries(values)) {
            const el = $(id);
            if (!el) continue;
            if (el.type === 'checkbox') { if (el.checked !== v) { el.checked = v; el.dispatchEvent(new Event('change', { bubbles: true })); } }
            else { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true })); }
        }
    }
    function fill() {
        const mine = readMine();
        const cur = select.value;
        select.innerHTML = '<option value="">Choose a preset…</option>';
        const g1 = document.createElement('optgroup'); g1.label = 'Ready-made';
        for (const n of Object.keys(BUILT_IN)) g1.appendChild(new Option(n, 'b:' + n));
        select.appendChild(g1);
        const names = Object.keys(mine);
        if (names.length) {
            const g2 = document.createElement('optgroup'); g2.label = 'Your presets';
            for (const n of names) g2.appendChild(new Option(n, 'm:' + n));
            select.appendChild(g2);
        }
        select.value = [...select.options].some(o => o.value === cur) ? cur : '';
        delBtn.disabled = !select.value.startsWith('m:');
    }
    function proOnly(msgEl, what) {
        msgEl.innerHTML = `⭐ ${what} is part of <a href="/studios/animation/pro.html">Pro</a>: one payment of ${window.GP_PRO ? GP_PRO.price : '£11.99'}, no subscription.`;
    }

    if (select) {
        fill();
        select.addEventListener('change', () => {
            delBtn.disabled = !select.value.startsWith('m:');
            presetMsg.textContent = '';
            if (!select.value) return;
            const [kind, name] = [select.value.slice(0, 1), select.value.slice(2)];
            const values = kind === 'b' ? BUILT_IN[name] : readMine()[name];
            if (values) { apply(values); presetMsg.textContent = `Loaded "${name}".`; }
        });
        saveBtn.addEventListener('click', () => {
            if (!isPro()) return proOnly(presetMsg, 'Saving your own presets');
            const name = ($('presetName').value || '').trim().slice(0, 40);
            if (!name) { presetMsg.textContent = 'Type a name for the preset first.'; $('presetName').focus(); return; }
            const mine = readMine(); mine[name] = capture(); writeMine(mine);
            fill(); select.value = 'm:' + name; delBtn.disabled = false;
            $('presetName').value = '';
            presetMsg.textContent = `Saved "${name}" on this device.`;
        });
        delBtn.addEventListener('click', () => {
            if (!select.value.startsWith('m:')) return;
            const name = select.value.slice(2);
            const mine = readMine(); delete mine[name]; writeMine(mine);
            fill(); presetMsg.textContent = `Deleted "${name}".`;
        });
    }

    // ---------------- Batch processing (Pro) ----------------
    const batchInput = $('batchUpload'), batchBtn = $('batchBtn'), batchStatus = $('batchStatus');
    let batchRunning = false, batchStop = false;

    function videoReady(file) {
        if (!file.type.startsWith('video/')) return Promise.resolve();
        return new Promise((resolve, reject) => {
            const v = sourceVideoPlayer;
            if (v.readyState >= 2 && v.src) return resolve();
            const t = setTimeout(() => reject(new Error('the video did not load')), 20000);
            v.addEventListener('loadeddata', () => { clearTimeout(t); resolve(); }, { once: true });
            v.addEventListener('error', () => { clearTimeout(t); reject(new Error('the browser could not play it')); }, { once: true });
        });
    }
    async function grab(sel) {
        const a = downloadContainer.querySelector(sel);
        if (!a) return null;
        return { blob: await (await fetch(a.href)).blob(), name: a.getAttribute('download') };
    }
    const safeName = n => n.replace(/\.[^.]+$/, '').replace(/[^\w\- ]+/g, '_').trim() || 'clip';

    if (batchInput) {
        batchInput.addEventListener('change', () => {
            const n = batchInput.files.length;
            batchBtn.disabled = n === 0;
            batchStatus.textContent = n ? `${n} clip${n === 1 ? '' : 's'} chosen.` : '';
        });
        cancelBtn.addEventListener('click', () => { if (batchRunning) batchStop = true; });

        batchBtn.addEventListener('click', async () => {
            if (!isPro()) return proOnly(batchStatus, 'Batch processing');
            const files = [...batchInput.files];
            if (!files.length || batchRunning) return;
            if (!(outSpriteWebp.checked || outZipWebp.checked || outAnimGif.checked || outMetaJson.checked)) {
                batchStatus.textContent = 'Tick at least one output format in section 2 first.';
                return;
            }
            batchRunning = true; batchStop = false; batchBtn.disabled = true;
            const zip = new JSZip();
            const used = new Set(), failed = [];
            let ok = 0;
            for (let i = 0; i < files.length; i++) {
                if (batchStop) break;
                const f = files[i];
                batchStatus.textContent = `Clip ${i + 1} of ${files.length}: ${f.name}`;
                try {
                    loadFile(f);
                    // Batch uses each whole clip.
                    [...startInputs, ...endInputs].forEach(inp => { inp.value = 0; });
                    validateTimes();
                    await videoReady(f);
                    const finished = new Promise(r => document.addEventListener('gp:processed', r, { once: true }));
                    generateBtn.click();
                    await finished;
                    const parts = (await Promise.all([
                        grab('a.download-btn[data-kind="sprite"]'),
                        grab('a.download-btn[download="spritesheet.json"]'),
                        grab('a.download-btn[download="animation.gif"]'),
                        grab('a.download-btn[download$=".zip"]')
                    ])).filter(Boolean);
                    if (!parts.length) throw new Error('nothing was produced');
                    let folder = safeName(f.name), k = 2;
                    while (used.has(folder)) folder = safeName(f.name) + ' (' + (k++) + ')';
                    used.add(folder);
                    for (const p of parts) zip.file(folder + '/studios/animation/' + p.name, p.blob);
                    ok++;
                } catch (e) {
                    failed.push(`${f.name} (${e.message})`);
                }
            }
            batchRunning = false; batchBtn.disabled = batchInput.files.length === 0;
            if (!ok) { batchStatus.textContent = batchStop ? 'Batch cancelled.' : 'No clips could be processed: ' + failed.join('; '); return; }
            batchStatus.textContent = `Packing ${ok} clip${ok === 1 ? '' : 's'} into one ZIP…`;
            const blob = await zip.generateAsync({ type: 'blob' });
            addDownloadButton(`📦 Download batch ZIP (${ok} clip${ok === 1 ? '' : 's'})`, blob, 'golden-paw-batch.zip', 'batch');
            batchStatus.textContent = `Done: ${ok} of ${files.length} clips in one ZIP.` +
                (batchStop ? ' Stopped early.' : '') + (failed.length ? ' Skipped: ' + failed.join('; ') : '');
            downloadContainer.querySelector('a[data-kind="batch"]').scrollIntoView({ block: 'center', behavior: 'smooth' });
        });
    }
})();
