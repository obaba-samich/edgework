# Renders the 1024px app icon with numpy SDFs. Run with any python that has numpy.
import sys, zlib, struct
import numpy as np

N = 1024
SS = 3
S = N * SS
y, x = np.mgrid[0:S, 0:S].astype(np.float32) / SS + 0.5 / SS

def hexc(h):
    return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255], np.float32) / 255

def seg(px, py, ax, ay, bx, by, r):
    pax, pay = px - ax, py - ay
    bax, bay = bx - ax, by - ay
    h = np.clip((pax * bax + pay * bay) / (bax * bax + bay * bay), 0, 1)
    return np.hypot(pax - bax * h, pay - bay * h) - r

def blend(img, color, alpha):
    a = alpha[..., None]
    return img * (1 - a) + color * a

# Background: deep rink navy gradient with a cold glow up top.
t = (y / N)[..., None]
img = hexc(0x14254A) * (1 - t) + hexc(0x060A14) * t
glow = np.exp(-(((x - 560) ** 2 + (y - 260) ** 2) / (2 * 330.0 ** 2)))
img = blend(img, hexc(0x7CD4FF), glow * 0.22)

# Faceoff circle and hash marks.
ring = np.abs(np.hypot(x - 512, y - 512) - 392) - 9
img = blend(img, hexc(0xFF4D5E), np.clip(0.5 - ring, 0, 1) * 0.55)
for sx in (-1, 1):
    for dy in (-46, 46):
        d = seg(x, y, 512 + sx * 400, 512 + dy, 512 + sx * 470, 512 + dy, 8)
        img = blend(img, hexc(0xFF4D5E), np.clip(0.5 - d, 0, 1) * 0.55)

# Italic E built from capsules.
k = 0.2
R = 58
bars = [(392, 300, 392, 724), (392, 300, 690, 300), (392, 512, 630, 512), (392, 724, 690, 724)]

def e_sdf(ox, oy):
    qx = (x - ox) - k * (512 - (y - oy))
    qy = y - oy
    d = None
    for (ax, ay, bx, by) in bars:
        s = seg(qx, qy, ax, ay, bx, by, R)
        d = s if d is None else np.minimum(d, s)
    return d

shadow = e_sdf(14, 20)
img = blend(img, hexc(0x000000), np.clip(0.5 - shadow / 26, 0, 1) * 0.45)

# Motion streaks trailing each bar.
for i, by in enumerate((300, 512, 724)):
    qx = x - k * (512 - y)
    d = seg(qx, y, 130 + i * 30, by, 268, by, 11)
    fade = np.clip((qx - 120) / 160, 0, 1)
    img = blend(img, hexc(0x7CD4FF), np.clip(0.5 - d, 0, 1) * 0.7 * fade)

d = e_sdf(0, 0)
fill = hexc(0xFFFFFF) * (1 - np.clip((y - 260) / 520, 0, 1))[..., None] + hexc(0x8FDCFF) * np.clip((y - 260) / 520, 0, 1)[..., None]
a = np.clip(0.5 - d, 0, 1)[..., None]
img = img * (1 - a) + fill * a

# Downsample and write PNG.
img = img.reshape(N, SS, N, SS, 3).mean(axis=(1, 3))
px = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
raw = b"".join(b"\x00" + px[r].tobytes() for r in range(N))

def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
open(sys.argv[1], "wb").write(png)
