# Renders the 1024px app icon (flat: white italic E + ice speed streaks on navy) with numpy SDFs. Run with any python that has numpy.
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

# Flat navy background, no gradient or glow.
img = np.ones((S, S, 3), np.float32) * hexc(0x0E1B36)

k = 0.2  # italic slant
R = 58   # bar radius
bars = [(392, 300, 392, 724), (392, 300, 690, 300), (392, 512, 630, 512), (392, 724, 690, 724)]

def slanted(sc):
    """Coordinates scaled around the center, then sheared for the italic."""
    qy = (y - 512) / sc + 512
    qx = (x - 512) / sc + 512 - k * (512 - qy)
    return qx, qy

def e_sdf(sc):
    qx, qy = slanted(sc)
    d = None
    for (ax, ay, bx, by) in bars:
        s = seg(qx, qy, ax, ay, bx, by, R)
        d = s if d is None else np.minimum(d, s)
    return d * sc

# Ice-blue speed streaks trailing the E.
qx, qy = slanted(1.0)
for i, by in enumerate((300, 512, 724)):
    d = seg(qx, qy, 130 + i * 30, by, 268, by, 14)
    img = blend(img, hexc(0x7CD4FF), np.clip(0.5 - d * SS, 0, 1))

# Solid white italic E.
img = blend(img, hexc(0xFFFFFF), np.clip(0.5 - e_sdf(1.08) * SS, 0, 1))

# Downsample and write PNG.
img = img.reshape(N, SS, N, SS, 3).mean(axis=(1, 3))
px = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
raw = b"".join(b"\x00" + px[r].tobytes() for r in range(N))

def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
open(sys.argv[1], "wb").write(png)
