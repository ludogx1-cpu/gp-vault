// Golden Paw Animation Creation Tool: sprite sheet editor & player.
(() => {
    const $ = id => document.getElementById(id);
    const playerCanvas = $('playerCanvas'), ctx = playerCanvas.getContext('2d');
    const gallery = $('gallery'), info = $('info');

    // Each frame is an offscreen canvas at the frame's full (untrimmed) size.
    let frames = [];
    let frameW = 64, frameH = 64;
    let selected = new Set();
    let anchor = null;          // for shift-click ranges
    let current = 0, playing = false, rafId = 0, lastTick = 0, dir = 1;
    let undoStack = [];
    let loadedImage = null, loadedJson = null, loadedName = 'spritesheet';

    // ---------- helpers ----------
    function setInfo(msg, warn) { info.textContent = msg; info.classList.toggle('warn', !!warn); }

    function readFileAsText(f) { return new Promise((res, rej) => { const r = new FileReader(); r.onload = () => res(r.result); r.onerror = rej; r.readAsText(f); }); }
    function loadImageFromBlob(blob) {
        return new Promise((res, rej) => {
            const url = URL.createObjectURL(blob);
            const img = new Image();
            img.onload = () => { URL.revokeObjectURL(url); res(img); };
            img.onerror = () => { URL.revokeObjectURL(url); rej(new Error('Could not read that image.')); };
            img.src = url;
        });
    }
    function newCanvas(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }
    function isEmpty(c) {
        const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
        for (let i = 3; i < d.length; i += 4) if (d[i] !== 0) return false;
        return true;
    }
    function baseName(n) { return (n || 'spritesheet').replace(/\.[^.]+$/, '').replace(/[^\w\-]+/g, '_') || 'spritesheet'; }

    // ---------- slicing ----------
    // Accepts TexturePacker JSON Hash ({frames:{name:{...}}}) and JSON Array ({frames:[{filename,...}]}).
    function sliceFromJson(img, data) {
        let list;
        if (Array.isArray(data.frames)) list = data.frames;
        else if (data.frames && typeof data.frames === 'object') list = Object.keys(data.frames).map(k => ({ filename: k, ...data.frames[k] }));
        else throw new Error('No "frames" found in this JSON.');
        if (!list.length) throw new Error('The JSON lists no frames.');

        // Natural sort so frame_2 comes before frame_10.
        const coll = new Intl.Collator(undefined, { numeric: true });
        if (!Array.isArray(data.frames)) list.sort((a, b) => coll.compare(a.filename, b.filename));

        // Sanity check: a JSON from a different (e.g. rebuilt or rescaled) sheet won't fit.
        const outOfBounds = list.some(f => f.frame && (f.frame.x + (f.rotated ? f.frame.h : f.frame.w) > img.width + 1 || f.frame.y + (f.rotated ? f.frame.w : f.frame.h) > img.height + 1));
        if (outOfBounds) throw new Error(`This JSON describes a bigger sheet than the image (${img.width}×${img.height}). Was the sheet rebuilt or resized after the JSON was saved? Use "Slice by grid" instead.`);

        const out = [];
        let maxW = 0, maxH = 0;
        for (const f of list) {
            const src = f.sourceSize || { w: f.frame.w, h: f.frame.h };
            maxW = Math.max(maxW, src.w); maxH = Math.max(maxH, src.h);
        }
        for (const f of list) {
            const fr = f.frame, sss = f.spriteSourceSize || { x: 0, y: 0 };
            const c = newCanvas(maxW, maxH), cx = c.getContext('2d');
            if (f.rotated) {
                // TexturePacker rotates 90° clockwise in the sheet; undo it.
                cx.save();
                cx.translate(sss.x, sss.y + fr.w);
                cx.rotate(-Math.PI / 2);
                cx.drawImage(img, fr.x, fr.y, fr.h, fr.w, 0, 0, fr.h, fr.w);
                cx.restore();
            } else {
                cx.drawImage(img, fr.x, fr.y, fr.w, fr.h, sss.x, sss.y, fr.w, fr.h);
            }
            out.push(c);
        }
        const fps = data.fps || (data.meta && data.meta.fps) || (list[0].duration ? Math.round(1000 / list[0].duration) : null);
        const tag = data.meta && Array.isArray(data.meta.frameTags) && data.meta.frameTags[0];
        return { frames: out, w: maxW, h: maxH, fps, cols: data.cols, pingpong: tag && tag.direction === 'pingpong' };
    }

    function sliceFromGrid(img, cols, rows, skipEmpty) {
        const fw = Math.floor(img.width / cols), fh = Math.floor(img.height / rows);
        if (fw < 1 || fh < 1) throw new Error('Too many columns or rows for this image.');
        const out = [];
        for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
            const cv = newCanvas(fw, fh);
            cv.getContext('2d').drawImage(img, c * fw, r * fh, fw, fh, 0, 0, fw, fh);
            out.push(cv);
        }
        // Only trailing blanks are dropped, so deliberate empty frames mid-animation survive.
        if (skipEmpty) while (out.length > 1 && isEmpty(out[out.length - 1])) out.pop();
        const uneven = img.width % cols || img.height % rows;
        return { frames: out, w: fw, h: fh, uneven };
    }

    function applyFrames(result, sourceLabel) {
        stop();
        frames = result.frames; frameW = result.w; frameH = result.h;
        selected.clear(); anchor = null; current = 0; undoStack = []; $('downloads').innerHTML = '';
        if (result.fps) $('fps').value = result.fps;
        if (result.pingpong) $('playMode').value = 'pingpong';
        $('expCols').value = result.cols || Math.min(frames.length, Math.ceil(Math.sqrt(frames.length)));
        playerCanvas.width = frameW; playerCanvas.height = frameH;
        applyZoom();
        let msg = `${sourceLabel} · ${frames.length} frames · ${frameW}×${frameH}px each`;
        if (result.uneven) msg += ' · The image doesn\'t divide evenly by this grid, so edge pixels were dropped. Check the column/row counts.';
        setInfo(msg, !!result.uneven);
        refresh();
    }

    async function loadCurrent(preferJson = true) {
        if (!loadedImage) return setInfo('Choose a sheet image first.', true);
        try {
            if (preferJson && loadedJson) {
                const m = loadedJson.meta && loadedJson.meta.size;
                const mismatch = m && (Math.abs(m.w - loadedImage.width) > 1 || Math.abs(m.h - loadedImage.height) > 1);
                let res = null, err = null;
                if (!mismatch) { try { res = sliceFromJson(loadedImage, loadedJson); } catch (e) { err = e; } }
                if (res) return applyFrames(res, 'Sliced from JSON');
                // The JSON was made for a different-sized sheet (e.g. rebuilt at another scale or
                // column count). Fall back to inferring the grid from the frame aspect ratio.
                const g = inferGrid(loadedImage, loadedJson);
                if (!g) throw err || new Error(`This JSON was made for a ${m.w}×${m.h} sheet but the image is ${loadedImage.width}×${loadedImage.height}. Set the columns and rows and use "Slice by grid".`);
                $('cols').value = g.cols; $('rows').value = g.rows;
                const r = sliceFromGrid(loadedImage, g.cols, g.rows, true);
                r.fps = loadedJson.fps || (loadedJson.meta && loadedJson.meta.fps);
                applyFrames(r, `JSON didn't match this image size, so the grid was worked out as ${g.cols}×${g.rows}`);
            } else {
                applyFrames(sliceFromGrid(loadedImage, Math.max(1, +$('cols').value || 1), Math.max(1, +$('rows').value || 1), $('skipEmpty').checked), 'Sliced by grid');
            }
        } catch (e) { setInfo(e.message, true); }
        $('reloadJsonBtn').hidden = !loadedJson;
    }

    async function setImageFile(blob, name) {
        try {
            loadedImage = await loadImageFromBlob(blob);
            loadedName = baseName(name);
            $('expName').value = loadedName;
            if (!loadedJson) guessGrid();
            await loadCurrent(true);
        } catch (e) { setInfo(e.message, true); }
    }
    async function setJsonText(text) {
        try { loadedJson = JSON.parse(text); }
        catch (e) { loadedJson = null; return setInfo('That JSON file could not be parsed: ' + e.message, true); }
        if (loadedImage) await loadCurrent(true);
        else setInfo('JSON loaded. Now choose the sheet image.');
    }

    // Find a cols×rows grid whose cells divide the image exactly and match the JSON's frame
    // aspect ratio, preferring the column count the JSON recorded.
    function inferGrid(img, data) {
        let fw = data.frameWidth, fh = data.frameHeight;
        if (!(fw && fh) && data.frames) {
            const first = Array.isArray(data.frames) ? data.frames[0] : data.frames[Object.keys(data.frames)[0]];
            if (first && first.frame) { fw = first.frame.w; fh = first.frame.h; }
        }
        if (!(fw && fh)) return null;
        const aspect = fw / fh, want = data.cols || 0;
        let best = null;
        for (let c = 1; c <= img.width; c++) {
            if (img.width % c) continue;
            const cw = img.width / c, ch = Math.round(cw / aspect);
            if (ch < 1 || img.height % ch || Math.abs(cw / ch - aspect) > 0.02) continue;
            const cand = { cols: c, rows: img.height / ch, cw };
            // Rebuilds only ever shrink frames, so prefer the largest cell that is no bigger
            // than the JSON's frame; among other candidates, the recorded column count wins.
            const fits = cw <= fw + 0.5, bestFits = best && best.cw <= fw + 0.5;
            if (!best || (fits && !bestFits) || (fits && bestFits && cw > best.cw) ||
                (!fits && !bestFits && Math.abs(c - want) < Math.abs(best.cols - want))) best = cand;
        }
        return best && { cols: best.cols, rows: best.rows };
    }

    // Square-frame guess for grid slicing: rows = 1 for a strip, otherwise assume square cells.
    function guessGrid() {
        const w = loadedImage.width, h = loadedImage.height;
        if (w >= h * 2 && w % h === 0) { $('cols').value = w / h; $('rows').value = 1; }
        else if (h >= w * 2 && h % w === 0) { $('cols').value = 1; $('rows').value = h / w; }
    }

    $('upload').addEventListener('change', e => { const f = e.target.files[0]; if (f) setImageFile(f, f.name); });
    $('jsonUpload').addEventListener('change', async e => { const f = e.target.files[0]; if (f) setJsonText(await readFileAsText(f)); });
    $('extractBtn').addEventListener('click', () => loadCurrent(false));
    $('reloadJsonBtn').addEventListener('click', () => loadCurrent(true));

    // Drag & drop: accepts an image, a JSON, or both at once.
    const dz = $('dropZone'); let dragDepth = 0;
    dz.addEventListener('dragenter', e => { if (e.dataTransfer.types.includes('Files')) { e.preventDefault(); dragDepth++; dz.classList.add('dragging'); } });
    dz.addEventListener('dragover', e => { if (e.dataTransfer.types.includes('Files')) e.preventDefault(); });
    dz.addEventListener('dragleave', () => { if (--dragDepth <= 0) { dragDepth = 0; dz.classList.remove('dragging'); } });
    dz.addEventListener('drop', async e => {
        if (!e.dataTransfer.files.length) return;
        e.preventDefault(); dragDepth = 0; dz.classList.remove('dragging');
        const files = [...e.dataTransfer.files];
        const json = files.find(f => /\.json$/i.test(f.name) || f.type === 'application/json');
        const img = files.find(f => f.type.startsWith('image/'));
        if (json) { loadedJson = null; try { loadedJson = JSON.parse(await readFileAsText(json)); } catch (err) { setInfo('That JSON file could not be parsed: ' + err.message, true); } }
        if (img) await setImageFile(img, img.name);
        else if (json && loadedImage) await loadCurrent(true);
        else if (json) setInfo('JSON loaded. Now drop or choose the sheet image.');
    });

    // ---------- player ----------
    function applyZoom() {
        const z = $('zoom').value;
        let scale;
        if (z === 'fit') {
            const avail = Math.max(100, $('stage').clientWidth - 24);
            scale = Math.min(avail / frameW, 480 / frameH, frameW < 64 ? 8 : 4);
        } else scale = +z;
        playerCanvas.style.width = Math.round(frameW * scale) + 'px';
        playerCanvas.style.height = Math.round(frameH * scale) + 'px';
    }
    $('zoom').addEventListener('change', applyZoom);
    window.addEventListener('resize', () => { if ($('zoom').value === 'fit') applyZoom(); });
    $('pixelated').addEventListener('change', () => {
        playerCanvas.classList.toggle('pixelated', $('pixelated').checked);
        gallery.querySelectorAll('.frame-box').forEach(c => c.classList.toggle('pixelated', $('pixelated').checked));
    });

    function draw(i) {
        ctx.clearRect(0, 0, playerCanvas.width, playerCanvas.height);
        if (!frames.length) { $('frameCounter').textContent = '— / —'; return; }
        current = Math.max(0, Math.min(i, frames.length - 1));
        ctx.drawImage(frames[current], 0, 0);
        $('scrub').value = current;
        $('frameCounter').textContent = `${current + 1} / ${frames.length}`;
        gallery.querySelectorAll('.frame-wrap.current').forEach(n => n.classList.remove('current'));
        const node = gallery.children[current];
        if (node) node.classList.add('current');
    }

    function tick(t) {
        if (!playing) return;
        const fps = Math.max(1, +$('fps').value || 12);
        if (t - lastTick >= 1000 / fps) {
            // Carry the remainder forward so playback speed stays accurate on any refresh rate.
            lastTick = t - ((t - lastTick) % (1000 / fps));
            const mode = $('playMode').value;
            let next = current + dir;
            if (mode === 'pingpong' && frames.length > 1) {
                if (next >= frames.length || next < 0) { dir = -dir; next = current + dir; }
            } else if (next >= frames.length) {
                if (mode === 'once') { pause(); return; }
                next = 0;
            }
            draw(next);
        }
        rafId = requestAnimationFrame(tick);
    }
    function play() {
        if (!frames.length || playing) return;
        if ($('playMode').value === 'once' && current >= frames.length - 1) current = 0;
        if ($('playMode').value !== 'pingpong') dir = 1;
        playing = true; lastTick = performance.now();
        $('playBtn').textContent = '❚❚ Pause';
        rafId = requestAnimationFrame(tick);
    }
    function pause() { playing = false; cancelAnimationFrame(rafId); $('playBtn').textContent = '▶ Play'; }
    function stop() { pause(); dir = 1; draw(0); }
    $('playBtn').addEventListener('click', () => playing ? pause() : play());
    $('stopBtn').addEventListener('click', stop);
    $('prevBtn').addEventListener('click', () => { pause(); draw((current - 1 + frames.length) % frames.length); });
    $('nextBtn').addEventListener('click', () => { pause(); draw((current + 1) % frames.length); });
    $('scrub').addEventListener('input', e => { pause(); draw(+e.target.value); });

    // ---------- gallery ----------
    function thumbSize() { const s = Math.min(1, 96 / Math.max(frameW, frameH)); return [Math.max(16, Math.round(frameW * s)), Math.max(16, Math.round(frameH * s))]; }

    let dragFrom = null;
    function renderGallery() {
        gallery.innerHTML = '';
        const [tw, th] = thumbSize();
        const pix = $('pixelated').checked;
        frames.forEach((fr, i) => {
            const wrap = document.createElement('div');
            wrap.className = 'frame-wrap' + (selected.has(i) ? ' selected' : '') + (i === current ? ' current' : '');
            wrap.draggable = true;
            wrap.tabIndex = 0;
            wrap.setAttribute('role', 'checkbox');
            wrap.setAttribute('aria-checked', selected.has(i) ? 'true' : 'false');
            wrap.setAttribute('aria-label', `Frame ${i + 1}`);
            // Keyboard: Enter/Space selects (Shift for a range), Alt+Enter shows it in the player.
            wrap.addEventListener('keydown', e => {
                if (e.key === 'Enter' && e.altKey) { e.preventDefault(); pause(); draw(i); return; }
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault(); e.stopPropagation();
                    wrap.dispatchEvent(new MouseEvent('click', { shiftKey: e.shiftKey, ctrlKey: e.ctrlKey, metaKey: e.metaKey }));
                }
            });
            const c = newCanvas(tw, th);
            c.className = 'frame-box checker' + (pix ? ' pixelated' : '');
            const cx = c.getContext('2d'); cx.imageSmoothingEnabled = !pix;
            cx.drawImage(fr, 0, 0, tw, th);
            c.title = `Frame ${i + 1}`;
            const num = document.createElement('span'); num.className = 'frame-num'; num.textContent = i + 1;
            wrap.append(c, num);

            wrap.addEventListener('click', e => {
                if (e.shiftKey && anchor !== null) {
                    if (!(e.ctrlKey || e.metaKey)) selected.clear();
                    const [a, b] = [Math.min(anchor, i), Math.max(anchor, i)];
                    for (let k = a; k <= b; k++) selected.add(k);
                } else {
                    selected.has(i) ? selected.delete(i) : selected.add(i);
                    anchor = i;
                }
                refreshSelection();
            });
            wrap.addEventListener('dblclick', () => { pause(); draw(i); });
            wrap.addEventListener('dragstart', e => { dragFrom = i; e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', String(i)); });
            wrap.addEventListener('dragover', e => { if (dragFrom !== null) { e.preventDefault(); wrap.classList.add('drag-over'); } });
            wrap.addEventListener('dragleave', () => wrap.classList.remove('drag-over'));
            wrap.addEventListener('drop', e => {
                e.preventDefault(); e.stopPropagation(); wrap.classList.remove('drag-over');
                if (dragFrom === null || dragFrom === i) return;
                pushUndo();
                const [moved] = frames.splice(dragFrom, 1);
                frames.splice(i, 0, moved);
                selected.clear(); current = i; dragFrom = null;
                refresh();
            });
            wrap.addEventListener('dragend', () => { dragFrom = null; });
            gallery.appendChild(wrap);
        });
    }
    function refreshSelection() {
        [...gallery.children].forEach((n, i) => { n.classList.toggle('selected', selected.has(i)); n.setAttribute('aria-checked', selected.has(i) ? 'true' : 'false'); });
        $('selInfo').textContent = frames.length ? `${selected.size} of ${frames.length} selected` : '';
        $('exportSelectedBtn').disabled = selected.size === 0;
    }
    function refresh() {
        const has = frames.length > 0;
        ['playBtn', 'stopBtn', 'prevBtn', 'nextBtn', 'exportBtn'].forEach(id => $(id).disabled = !has);
        $('scrub').disabled = !has; $('scrub').max = Math.max(0, frames.length - 1);
        $('undoBtn').disabled = undoStack.length === 0;
        if (current >= frames.length) current = Math.max(0, frames.length - 1);
        renderGallery(); refreshSelection(); draw(current);
    }

    // ---------- edit actions ----------
    function pushUndo() { undoStack.push(frames.slice()); if (undoStack.length > 50) undoStack.shift(); }
    const sel = () => [...selected].sort((a, b) => a - b);

    const actions = {
        all() { frames.forEach((_, i) => selected.add(i)); refreshSelection(); },
        none() { selected.clear(); refreshSelection(); },
        invert() { const s = new Set(); frames.forEach((_, i) => { if (!selected.has(i)) s.add(i); }); selected = s; refreshSelection(); },
        delete() {
            if (!selected.size) return setInfo('Select frames to delete first.', true);
            if (selected.size === frames.length && !confirm('Delete every frame?')) return;
            pushUndo(); frames = frames.filter((_, i) => !selected.has(i)); selected.clear(); refresh();
        },
        duplicate() {
            if (!selected.size) return setInfo('Select frames to duplicate first.', true);
            pushUndo();
            const idx = sel(), copies = idx.map(i => frames[i]);
            const at = idx[idx.length - 1] + 1;
            frames.splice(at, 0, ...copies);
            selected = new Set(copies.map((_, k) => at + k)); refresh();
        },
        reverse() {
            if (frames.length < 2) return;
            pushUndo();
            if (selected.size > 1) { const idx = sel(), vals = idx.map(i => frames[i]).reverse(); idx.forEach((i, k) => frames[i] = vals[k]); }
            else frames.reverse();
            refresh();
        },
        earlier() { move(-1); },
        later() { move(1); },
        undo() { if (!undoStack.length) return; frames = undoStack.pop(); selected.clear(); refresh(); }
    };
    function move(d) {
        if (!selected.size) return setInfo('Select frames to move first.', true);
        const idx = sel();
        if ((d < 0 && idx[0] === 0) || (d > 0 && idx[idx.length - 1] === frames.length - 1)) return;
        pushUndo();
        const order = d < 0 ? idx : idx.slice().reverse();
        for (const i of order) { const j = i + d; [frames[i], frames[j]] = [frames[j], frames[i]]; }
        selected = new Set(idx.map(i => i + d)); refresh();
    }
    document.querySelectorAll('[data-act]').forEach(b => b.addEventListener('click', () => actions[b.dataset.act]()));

    document.addEventListener('keydown', e => {
        if (e.target.matches('input, select, textarea') || !frames.length) return;
        if (e.key === ' ') { e.preventDefault(); playing ? pause() : play(); }
        else if (e.key === 'ArrowLeft') { e.preventDefault(); $('prevBtn').click(); }
        else if (e.key === 'ArrowRight') { e.preventDefault(); $('nextBtn').click(); }
        else if (e.key === 'Delete' || e.key === 'Backspace') { if (selected.size) { e.preventDefault(); actions.delete(); } }
        else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'a') { e.preventDefault(); actions.all(); }
        else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') { e.preventDefault(); actions.undo(); }
    });

    // ---------- export ----------
    const downloadUrls = [];
    function addDownload(label, blob, filename) {
        const url = URL.createObjectURL(blob); downloadUrls.push(url);
        const a = document.createElement('a');
        a.className = 'download-btn'; a.href = url; a.download = filename; a.dataset.kind = 'editor';
        a.textContent = label;
        $('downloads').appendChild(a);
    }

    function exportFrames(list) {
        if (!list.length) return;
        downloadUrls.splice(0).forEach(u => URL.revokeObjectURL(u));
        $('downloads').innerHTML = '';

        const type = $('expFormat').value;
        const ext = type === 'image/webp' ? 'webp' : 'png';
        const name = baseName($('expName').value);
        const cols = Math.max(1, Math.min(+$('expCols').value || 1, list.length));
        const rows = Math.ceil(list.length / cols);
        const fps = Math.max(1, +$('fps').value || 12);

        const sheet = newCanvas(frameW * cols, frameH * rows);
        if (sheet.width > 16384 || sheet.height > 16384) return setInfo(`That sheet would be ${sheet.width}×${sheet.height}px, larger than browsers can encode. Use more or fewer columns.`, true);
        const sx = sheet.getContext('2d');
        list.forEach((fr, i) => sx.drawImage(fr, (i % cols) * frameW, Math.floor(i / cols) * frameH));

        const pad = Math.max(3, String(list.length - 1).length);
        const json = {
            frames: {},
            meta: {
                app: 'Golden Paw Animation Creation Tool: Sprite Editor',
                image: `${name}.${ext}`,
                format: 'RGBA8888',
                size: { w: sheet.width, h: sheet.height },
                scale: '1',
                fps,
                frameTags: [{ name: 'all', from: 0, to: list.length - 1, direction: $('playMode').value === 'pingpong' ? 'pingpong' : 'forward' }]
            },
            frameWidth: frameW, frameHeight: frameH, cols, rows, count: list.length, fps
        };
        list.forEach((_, i) => {
            json.frames[`frame_${String(i).padStart(pad, '0')}.${ext}`] = {
                frame: { x: (i % cols) * frameW, y: Math.floor(i / cols) * frameH, w: frameW, h: frameH },
                rotated: false, trimmed: false,
                spriteSourceSize: { x: 0, y: 0, w: frameW, h: frameH },
                sourceSize: { w: frameW, h: frameH },
                duration: Math.round(1000 / fps)
            };
        });

        sheet.toBlob(blob => {
            if (!blob) return setInfo('The browser could not encode that image.', true);
            addDownload(`Download ${name}.${ext} (${sheet.width}×${sheet.height}, ${list.length} frames)`, blob, `${name}.${ext}`);
            addDownload(`Download ${name}.json`, new Blob([JSON.stringify(json, null, 2)], { type: 'application/json' }), `${name}.json`);
            if (window.gtag && window.SITE_CONFIG && window.SITE_CONFIG.ga4) gtag('event', 'editor_export', { frames: list.length });
        }, type, 0.9);
    }
    $('exportBtn').addEventListener('click', () => exportFrames(frames));
    $('exportSelectedBtn').addEventListener('click', () => {
        if (!selected.size) return setInfo('Select frames to export first.', true);
        exportFrames(sel().map(i => frames[i]));
    });

    // ---------- files opened with the installed app ("Open with…") ----------
    if ('launchQueue' in window) {
        window.launchQueue.setConsumer(async params => {
            if (!params.files || !params.files.length) return;
            const files = await Promise.all(params.files.map(h => h.getFile()));
            const json = files.find(f => /\.json$/i.test(f.name));
            const img = files.find(f => f.type.startsWith('image/'));
            if (json) { try { loadedJson = JSON.parse(await readFileAsText(json)); } catch (e) { loadedJson = null; } }
            if (img) await setImageFile(img, img.name);
            else if (json) setInfo('JSON loaded. Now choose the sheet image.');
        });
    }

    // ---------- open a sheet by URL (used by the showcase) ----------
    // Only same-site paths like /showcase/x.png are accepted.
    (function () {
        const q = new URLSearchParams(location.search);
        const safe = v => v && /^\/(?!\/)[\w\-./%]+$/.test(v) ? v : null;
        const sheet = safe(q.get('sheet')), atlas = safe(q.get('atlas'));
        if (!sheet) return;
        (async () => {
            try {
                loadedJson = atlas ? await (await fetch(atlas)).json() : null;
                const blob = await (await fetch(sheet)).blob();
                await setImageFile(blob, sheet.split('/studios/animation/').pop());
            } catch (e) { setInfo('Could not open that sheet: ' + e.message, true); }
        })();
    })();

    // ---------- hand-off from the converter page ----------
    // The converter stores its latest sheet + JSON in IndexedDB and links here with ?from=converter.
    if (new URLSearchParams(location.search).get('from') === 'converter') {
        try {
            const req = indexedDB.open('vts-handoff', 1);
            req.onupgradeneeded = () => req.result.createObjectStore('h');
            req.onsuccess = () => {
                const db = req.result;
                const tx = db.transaction('h', 'readwrite');
                const store = tx.objectStore('h');
                const get = store.get('latest');
                get.onsuccess = async () => {
                    const item = get.result;
                    store.delete('latest');
                    if (!item) return setInfo('Nothing was handed over from the converter. Load a sheet below.', true);
                    loadedJson = null;
                    if (item.json) { try { loadedJson = JSON.parse(item.json); } catch (e) { /* fall back to grid */ } }
                    if (loadedJson && loadedJson.cols && loadedJson.rows) { $('cols').value = loadedJson.cols; $('rows').value = loadedJson.rows; }
                    await setImageFile(item.sheet, item.name || 'spritesheet');
                    history.replaceState(null, '', location.pathname);
                };
            };
        } catch (e) { setInfo('Could not receive the sheet from the converter. Download it there and load it here instead.', true); }
    }
})();
