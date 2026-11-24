/*
 * Showcase: plays the sprite sheets listed in /showcase/showcase.json.
 * Drop a sheet (+ optional JSON atlas) into public/showcase/ and add an entry:
 *
 *   {
 *     "title": "Shiba run cycle",
 *     "caption": "Made from a 2-second clip",
 *     "image": "shiba-run.png",
 *     "atlas": "shiba-run.json",             // optional, TexturePacker JSON from the converter
 *     "cols": 4, "rows": 3,                  // only needed when there is no atlas
 *     "fps": 12                              // optional, the atlas fps is used otherwise
 *   }
 *
 * The section stays hidden while the list is empty.
 */
(function () {
    var root = document.getElementById('showcase');
    if (!root) return;
    var grid = root.querySelector('.showcase-grid');
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function loadImage(src) {
        return new Promise(function (res, rej) {
            var img = new Image();
            img.onload = function () { res(img); };
            img.onerror = function () { rej(new Error('Could not load ' + src)); };
            img.src = src;
        });
    }

    // Returns a list of {sx, sy, sw, sh, dx, dy} plus the full frame size.
    function framesFromAtlas(data) {
        var list = Array.isArray(data.frames) ? data.frames : Object.keys(data.frames).sort(new Intl.Collator(undefined, { numeric: true }).compare).map(function (k) { return data.frames[k]; });
        var w = 0, h = 0;
        list.forEach(function (f) { var s = f.sourceSize || f.frame; w = Math.max(w, s.w); h = Math.max(h, s.h); });
        return {
            w: w, h: h,
            cells: list.map(function (f) { var o = f.spriteSourceSize || { x: 0, y: 0 }; return { sx: f.frame.x, sy: f.frame.y, sw: f.frame.w, sh: f.frame.h, dx: o.x, dy: o.y }; }),
            fps: data.fps || (data.meta && data.meta.fps),
            pingpong: !!(data.meta && data.meta.frameTags && data.meta.frameTags[0] && data.meta.frameTags[0].direction === 'pingpong')
        };
    }
    function framesFromGrid(img, cols, rows) {
        var fw = Math.floor(img.width / cols), fh = Math.floor(img.height / rows), cells = [];
        for (var r = 0; r < rows; r++) for (var c = 0; c < cols; c++) cells.push({ sx: c * fw, sy: r * fh, sw: fw, sh: fh, dx: 0, dy: 0 });
        return { w: fw, h: fh, cells: cells };
    }

    function addCard(item, img, anim) {
        var fig = document.createElement('figure');
        fig.className = 'showcase-card';
        var stage = document.createElement('div');
        stage.className = 'showcase-stage';
        var cv = document.createElement('canvas');
        cv.width = anim.w; cv.height = anim.h;
        cv.setAttribute('role', 'img');
        cv.setAttribute('aria-label', item.title || 'Animation');
        stage.appendChild(cv);
        var cap = document.createElement('figcaption');
        var t = document.createElement('strong'); t.textContent = item.title || '';
        cap.appendChild(t);
        if (item.caption) { var d = document.createElement('span'); d.textContent = item.caption; cap.appendChild(d); }
        var link = document.createElement('a');
        link.href = '/studios/animation/editor.html?sheet=' + encodeURIComponent(item.image) + (item.atlas ? '&atlas=' + encodeURIComponent(item.atlas) : '');
        link.textContent = 'Open in Sprite Editor →';
        cap.appendChild(link);
        fig.append(stage, cap);
        grid.appendChild(fig);

        var ctx = cv.getContext('2d'), i = 0, dir = 1, last = 0, visible = false, playing = !reduceMotion;
        var fps = item.fps || anim.fps || 12, n = anim.cells.length;
        function draw() {
            var c = anim.cells[i];
            ctx.clearRect(0, 0, cv.width, cv.height);
            ctx.drawImage(img, c.sx, c.sy, c.sw, c.sh, c.dx, c.dy, c.sw, c.sh);
        }
        function step(ts) {
            if (visible && playing && ts - last >= 1000 / fps) {
                last = ts;
                if (anim.pingpong && n > 1) { if (i + dir >= n || i + dir < 0) dir = -dir; i += dir; }
                else i = (i + 1) % n;
                draw();
            }
            requestAnimationFrame(step);
        }
        draw();
        // Only animate while on screen; with reduced motion, play on hover/focus.
        if ('IntersectionObserver' in window) new IntersectionObserver(function (e) { visible = e[0].isIntersecting; }).observe(cv);
        else visible = true;
        if (reduceMotion) {
            stage.tabIndex = 0;
            stage.title = 'Hover or focus to play';
            ['mouseenter', 'focus'].forEach(function (ev) { stage.addEventListener(ev, function () { playing = true; }); });
            ['mouseleave', 'blur'].forEach(function (ev) { stage.addEventListener(ev, function () { playing = false; i = 0; draw(); }); });
        }
        requestAnimationFrame(step);
    }

    // Image and atlas paths in showcase.json are relative to that file, e.g. "shiba-run.png".
    // (Older entries written as "/studios/animation/showcase/x.png" still work.)
    const LIST = new URL('/studios/animation/showcase/showcase.json', location.href);
    const resolve = p => new URL(String(p).replace(/^\/showcase\//, ''), LIST).pathname;
    fetch(LIST.href, { cache: 'no-cache' })
        .then(function (r) { return r.ok ? r.json() : []; })
        .then(function (items) {
            if (!Array.isArray(items) || !items.length) return;
            return Promise.all(items.map(function (item) {
                item.image = resolve(item.image);
                if (item.atlas) item.atlas = resolve(item.atlas);
                return Promise.all([
                    loadImage(item.image),
                    item.atlas ? fetch(item.atlas).then(function (r) { return r.json(); }) : null
                ]).then(function (res) {
                    var anim = res[1] ? framesFromAtlas(res[1]) : framesFromGrid(res[0], item.cols || 1, item.rows || 1);
                    if (anim.cells.length) { addCard(item, res[0], anim); root.hidden = false; }
                }).catch(function (e) { console.warn('Showcase:', e.message); });
            }));
        })
        .catch(function () { /* no showcase yet */ });
})();
