"""Builds brand/logo-pack/ from assets/Goldenpawicon_gold.png.
Run from the repo root: python3 brand/make_logo_pack.py"""
from PIL import Image, ImageDraw, ImageFont

FONT = 'assets/fonts/Outfit-Variable.ttf'
DARK = (20, 25, 38, 255)
WHITE = (255, 255, 255, 255)
GOLD = (201, 162, 39, 255)
OUT = 'brand/logo-pack/'

src = Image.open('assets/Goldenpawicon_gold.png').convert('RGBA')
r, g, b, a = src.split()
# Crisp edges: drop the faint halo and make the paw fully solid.
a = a.point(lambda v: 0 if v < 110 else 255 if v > 170 else int((v - 110) * 255 / 60))
src = Image.merge('RGBA', (r, g, b, a))
paw = src.crop(src.getbbox())


def font(px, weight):
    f = ImageFont.truetype(FONT, px)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def place(size, bg, scale):
    w, h = size
    c = Image.new('RGBA', size, bg)
    s = int(min(w, h) * scale)
    p = paw.copy()
    p.thumbnail((s, s), Image.LANCZOS)
    c.alpha_composite(p, ((w - p.width) // 2, (h - p.height) // 2))
    return c


def banner(size, name, title_px, sub=None):
    w, h = size
    c = Image.new('RGBA', size, DARK)
    d = ImageDraw.Draw(c)
    f = font(title_px, 700)
    text, sp = 'Golden Paw', int(title_px * 0.08)
    tw = sum(d.textlength(ch, font=f) for ch in text) + sp * (len(text) - 1)
    p = paw.copy()
    p.thumbnail((int(title_px * 1.15),) * 2, Image.LANCZOS)
    gap = int(title_px * 0.45)
    x = (w - (p.width + gap + tw)) / 2
    yc = h / 2 - (title_px * 0.35 if sub else 0)
    c.alpha_composite(p, (int(x), int(yc - p.height / 2)))
    tx = x + p.width + gap
    for ch in text:
        d.text((tx, yc), ch, font=f, fill=GOLD, anchor='lm')
        tx += d.textlength(ch, font=f) + sp
    if sub:
        d.text((w / 2, yc + title_px * 0.95), sub, font=font(int(title_px * 0.34), 400),
               fill=(225, 225, 225, 255), anchor='mm')
    c.convert('RGB').save(OUT + name)


for n in (1024, 512, 256, 128, 64):
    place((n, n), (0, 0, 0, 0), 0.92).save(f'{OUT}paw-transparent-{n}.png')
for n in (32, 16):
    place((n, n), (0, 0, 0, 0), 1.0).save(f'{OUT}paw-transparent-{n}.png')
place((512, 512), DARK, 0.66).convert('RGB').save(OUT + 'app-icon-512-dark.png')
place((1024, 1024), DARK, 0.66).convert('RGB').save(OUT + 'app-icon-1024-dark.png')
place((400, 400), DARK, 0.58).convert('RGB').save(OUT + 'profile-400-dark.png')
place((400, 400), WHITE, 0.58).convert('RGB').save(OUT + 'profile-400-white.png')
place((800, 800), DARK, 0.58).convert('RGB').save(OUT + 'profile-800-dark.png')
place((180, 180), DARK, 0.7).convert('RGB').save(OUT + 'apple-touch-icon-180.png')
place((32, 32), (0, 0, 0, 0), 1.0).save(OUT + 'favicon-32.png')
place((48, 48), (0, 0, 0, 0), 1.0).save(OUT + 'favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)])
banner((1200, 630), 'share-image-1200x630.png', 120, 'Dogs, games and good company · goldenpaw.dog')
banner((1500, 500), 'header-x-twitter-1500x500.png', 110, 'goldenpaw.dog')
banner((1640, 624), 'cover-facebook-1640x624.png', 120, 'goldenpaw.dog')
banner((2048, 1152), 'banner-youtube-2048x1152.png', 150, 'goldenpaw.dog')
banner((1000, 300), 'wordmark-1000x300.png', 120)
print('logo pack built')
