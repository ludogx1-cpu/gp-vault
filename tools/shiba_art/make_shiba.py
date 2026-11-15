"""Golden Paw Shiba life-stage sprites, drawn from ONE parametric design.

Every stage shares the same palette, face markings, pose (3/4 view facing
right) and pixel size; only proportions change with age. Because the art is
generated, the exact eye/cheek/collar/tail positions are known, and the script
prints the matching PetStageRig values for lib/widgets/pet/pet_collar_painter.dart.

Usage:  python3 tools/shiba_art/make_shiba.py OUT_DIR
"""
import json
import math
import os
import sys

from PIL import Image

G = 64          # logical pixel grid
SCALE = 16      # 64 * 16 = 1024 px output
GROUND = 60

PAL = {
    'O': (74, 38, 22, 255),     # outline
    'C': (232, 138, 58, 255),   # coat
    'D': (196, 102, 38, 255),   # coat shade
    'L': (246, 170, 92, 255),   # coat highlight
    'U': (255, 240, 220, 255),  # cream (urajiro)
    'V': (236, 214, 188, 255),  # cream shade
    'E': (34, 24, 22, 255),     # eye / nose
    'W': (255, 255, 255, 255),  # eye highlight
    'P': (240, 140, 150, 255),  # pink (inner ear, tongue)
    'B': (247, 160, 150, 255),  # blush
    'G': (196, 196, 200, 255),  # senior grey
    'H': (226, 226, 230, 255),  # senior grey light
}

# Proportions per stage (grid units). Size growth is handled by the app
# (stageScaleFor), so every sprite is designed to fill the canvas similarly.
STAGES = {
    #            head  bodyW bodyH leg legW  tail  ear  blush senior
    'baby':        (12.5, 11.0, 8.5,  4.0, 4.5, 3.0, 6.0, True,  False),
    'toddler':     (12.0, 12.5, 8.5,  5.5, 4.5, 3.8, 6.5, True,  False),
    'puppy':       (11.5, 13.5, 9.0,  7.0, 4.5, 4.6, 7.0, True,  False),
    'child':       (11.0, 14.5, 9.0,  8.5, 4.5, 5.2, 7.5, False, False),
    'young_adult': (10.5, 15.5, 9.0, 10.0, 4.5, 5.8, 8.0, False, False),
    'adult':       (10.2, 16.0, 9.5, 11.0, 4.5, 6.2, 8.0, False, False),
    'old_dog':     (10.2, 16.0, 9.5, 10.5, 4.5, 5.8, 7.6, False, True),
}


class Canvas:
    def __init__(self):
        self.px = [[None] * G for _ in range(G)]

    def part(self, mask, colour_fn, outline=True):
        """Draw a shape: interior filled via colour_fn(x, y), boundary outlined."""
        for y in range(G):
            for x in range(G):
                if not mask(x, y):
                    continue
                edge = outline and any(
                    not mask(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                self.px[y][x] = 'O' if edge else colour_fn(x, y)

    def dot(self, x, y, c):
        if 0 <= x < G and 0 <= y < G:
            self.px[y][x] = c

    def image(self):
        im = Image.new('RGBA', (G, G), (0, 0, 0, 0))
        for y in range(G):
            for x in range(G):
                if self.px[y][x]:
                    im.putpixel((x, y), PAL[self.px[y][x]])
        return im.resize((G * SCALE, G * SCALE), Image.NEAREST)


def ell(cx, cy, rx, ry):
    return lambda x, y: ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1


def rect(x0, y0, x1, y1):
    return lambda x, y: x0 <= x + .5 <= x1 and y0 <= y + .5 <= y1


def tri(a, b, c):
    def inside(x, y):
        px, py = x + .5, y + .5
        d1 = (px - b[0]) * (a[1] - b[1]) - (a[0] - b[0]) * (py - b[1])
        d2 = (px - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (py - c[1])
        d3 = (px - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (py - a[1])
        neg = d1 < 0 or d2 < 0 or d3 < 0
        pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (neg and pos)
    return inside


def union(*ms):
    return lambda x, y: any(m(x, y) for m in ms)


def draw_shiba(stage):
    hr, brx, bry, leg, lw, tr, eh, blush, senior = STAGES[stage]
    k = 1.25  # overall size on the canvas
    hr, brx, bry, leg, tr, eh, lw = hr * k, brx * k, bry * k, leg * k, tr * k, eh * k, lw * 1.2
    cv = Canvas()

    # --- layout -----------------------------------------------------------
    total_w = brx * 2 + hr * 1.1
    bx = (G - total_w) / 2 + brx + 1.5
    by = GROUND - leg - bry * 0.55
    hx = bx + brx * 0.72
    hy = by - bry * 0.55 - hr * 0.55

    def shade(top, mid, bottom, y0, y1):
        def f(x, y):
            t = (y + .5 - y0) / max(1e-6, (y1 - y0))
            return top if t < 0.22 else (bottom if t > 0.72 else mid)
        return f

    # --- far legs (behind body, darker) -----------------------------------
    for lx in (bx + brx * 0.45 - 2.5, bx - brx * 0.62 - 2.5):
        m = rect(lx - lw / 2, by, lx + lw / 2, GROUND)
        cv.part(m, lambda x, y: 'V' if y >= GROUND - 2 else 'D')

    # --- body ------------------------------------------------------------
    body = ell(bx, by, brx, bry)
    belly = ell(bx + brx * 0.25, by + bry * 0.75, brx * 0.75, bry * 0.55)

    def body_col(x, y):
        if belly(x, y):
            return 'U' if y + .5 < by + bry * 0.85 else 'V'
        return shade('L', 'C', 'D', by - bry, by + bry)(x, y)
    cv.part(body, body_col)

    # --- near legs with white socks ----------------------------------------
    for lx in (bx + brx * 0.55, bx - brx * 0.52):
        m = rect(lx - lw / 2, by + bry * 0.2, lx + lw / 2, GROUND)
        sock = GROUND - max(2, leg * 0.35)
        cv.part(m, lambda x, y, s=sock: 'U' if y + .5 >= s else ('C' if x + .5 < lx else 'D'))
        cv.dot(int(lx - lw / 2) + 1, GROUND - 1, 'V')

    # --- curled tail over the back ----------------------------------------
    tx, ty = bx - brx * 0.78, by - bry * 0.75
    th = max(2.0, tr * 0.55)
    ring = lambda x, y: (tr - th) ** 2 <= (x + .5 - tx) ** 2 + (y + .5 - ty) ** 2 <= tr ** 2
    tail = union(ring, ell(tx + tr * 0.35, ty + tr * 0.55, th * 0.8, th * 0.8))
    tail = union(ell(tx, ty, tr, tr), ell(tx + tr * 0.35, ty + tr * 0.55, th * 0.8, th * 0.8))
    curl = lambda x, y: abs(math.hypot(x + .5 - tx, y + .5 - ty) - tr * 0.45) < 0.75 and (y + .5) > ty - tr * 0.2
    cv.part(tail, lambda x, y: 'D' if curl(x, y) else ('U' if ell(tx + tr * 0.1, ty + tr * 0.15, tr * 0.38, tr * 0.32)(x, y)
            else ('L' if y + .5 < ty - tr * 0.45 else 'C')))

    # --- ears --------------------------------------------------------------
    ears = []
    for ex, lean in ((hx - hr * 0.50, -1), (hx + hr * 0.45, 1)):
        a = (ex - hr * 0.42, hy - hr * 0.62)
        b = (ex + hr * 0.42, hy - hr * 0.62)
        tip = (ex + lean * hr * 0.12, hy - hr * 0.90 - eh * 0.80)
        ears.append((a, b, tip))
        cv.part(tri(a, b, tip), lambda x, y: 'C')
        inner = tri((a[0] + 2.4, a[1]), (b[0] - 2.4, b[1]), (tip[0], tip[1] + 3.0))
        cv.part(inner, lambda x, y: 'P', outline=False)

    # --- head --------------------------------------------------------------
    head = ell(hx, hy, hr * 1.08, hr * 0.95)
    muzzle = ell(hx + hr * 0.52, hy + hr * 0.42, hr * 0.55, hr * 0.38)
    cheeks = ell(hx + hr * 0.05, hy + hr * 0.55, hr * 0.95, hr * 0.45)
    grey = ell(hx + hr * 0.48, hy + hr * 0.40, hr * 0.66, hr * 0.48)

    def head_col(x, y):
        if senior and grey(x, y):
            return 'H' if y + .5 < hy + hr * 0.5 else 'G'
        if muzzle(x, y) or cheeks(x, y):
            return 'U'
        return 'L' if y + .5 < hy - hr * 0.55 else 'C'
    cv.part(head, head_col)

    # --- face --------------------------------------------------------------
    eye_y = round(hy - hr * 0.05)
    eyes = (round(hx - hr * 0.30), round(hx + hr * 0.38))
    es = 2 if hr >= 11 else 2
    for ex in eyes:
        for dx in range(es):
            for dy in range(es + 1):
                cv.dot(ex + dx, eye_y + dy, 'E')
        cv.dot(ex, eye_y, 'W')
        # iconic Shiba cream eyebrow dots
        cv.dot(ex, eye_y - 3, 'H' if senior else 'U')
        cv.dot(ex + 1, eye_y - 3, 'H' if senior else 'U')
    nose_x, nose_y = round(hx + hr * 0.66), round(hy + hr * 0.26)
    for dx in range(3):
        cv.dot(nose_x + dx, nose_y, 'E')
    cv.dot(nose_x + 1, nose_y + 1, 'E')
    mouth_y = nose_y + 2
    cv.dot(nose_x + 1, mouth_y - 1, 'O')
    for dx in (-1, 0, 2, 3):
        cv.dot(nose_x + dx, mouth_y if dx in (0, 2) else mouth_y - 1, 'O')
    cv.dot(nose_x + 1, mouth_y + 1, 'P')   # little tongue
    cheek_l, cheek_r = (eyes[0] - 1, eye_y + 3), (eyes[1] + 2, eye_y + 3)
    if blush:
        for cx, cy in (cheek_l, cheek_r):
            cv.dot(cx, cy, 'B')
            cv.dot(cx + 1, cy, 'B')

    # --- rig for the app (normalised 0..1) ---------------------------------
    n = lambda v: round(v / G, 3)
    neck_y = hy + hr * 0.78
    rig = {
        'collarStart': (n(hx - hr * 0.62), n(neck_y - 0.5)),
        'collarControl': (n(hx + hr * 0.05), n(neck_y + hr * 0.42)),
        'collarEnd': (n(hx + hr * 0.78), n(neck_y)),
        'collarThickness': 0.042,
        'tagAnchor': (n(hx + hr * 0.08), n(neck_y + hr * 0.30)),
        'leftEye': (n(eyes[0] + 1), n(eye_y + 1.5)),
        'rightEye': (n(eyes[1] + 1), n(eye_y + 1.5)),
        'eyeRadius': round(1.6 / G, 3),
        'eyelidFurColor': '0xFF%02X%02X%02X' % PAL['C'][:3],
        'leftCheek': (n(cheek_l[0] + 1), n(cheek_l[1] + .5)),
        'rightCheek': (n(cheek_r[0] + 1), n(cheek_r[1] + .5)),
        'tailAnchor': (n(tx), n(ty)),
    }
    return cv.image(), rig


def draw_egg():
    cv = Canvas()
    cx, cy, rx, ry = 32, 36, 15, 20
    egg = lambda x, y: ell(cx, cy, rx, ry)(x, y) and not (y + .5 < cy and ((x + .5 - cx) / (rx * (0.75 + 0.25 * (y + .5 - (cy - ry)) / ry))) ** 2 + ((y + .5 - cy) / ry) ** 2 > 1)
    spots = union(ell(25, 28, 3, 2.5), ell(39, 40, 3.5, 3), ell(28, 47, 2.5, 2), ell(40, 25, 2, 1.8))
    cv.part(egg, lambda x, y: 'C' if spots(x, y) else ('W' if (x < cx - 6 and y < cy - 8) else ('V' if y > cy + ry * 0.55 else 'U')))
    # paw print on the shell
    for px_, py_ in ((31, 36), (32, 36), (33, 36), (31, 37), (32, 37), (33, 37), (30, 34), (32, 33), (34, 34)):
        cv.dot(px_, py_, 'D')
    return cv.image()


def main(out):
    os.makedirs(out, exist_ok=True)
    draw_egg().save(os.path.join(out, 'shiba_egg.png'))
    rigs = {}
    for stage in STAGES:
        im, rig = draw_shiba(stage)
        im.save(os.path.join(out, f'shiba_{stage}.png' if stage != 'old_dog' else 'old_dog.png'))
        rigs[stage] = rig
    with open(os.path.join(out, 'rigs.json'), 'w') as f:
        json.dump(rigs, f, indent=1)
    print(json.dumps(rigs, indent=1))


if __name__ == '__main__':
    main(sys.argv[1])
