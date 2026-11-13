#!/usr/bin/env python3
"""Render Edgework 3D moves (Edgework/Data/moves.json) to contact sheets, no dependencies.

Same forward kinematics as Motion3D.swift, so what you see here is what the app plays.

    python3 tools/posepreview.py squat lunge ...   # or no args for every move
Writes tools/preview/<n>.png (needs ffmpeg for PPM -> PNG).
"""
import json, math, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "Edgework", "Data", "moves.json")
OUT = os.path.join(ROOT, "tools", "preview")

FIELDS = ["yaw", "bPitch", "bRoll", "bSpin", "pitch", "roll", "twist", "nod", "lift", "fwd", "side",
          "sFL", "sAL", "eFL", "aRL", "sFR", "sAR", "eFR", "aRR",
          "hFL", "hAL", "kFL", "hRL", "toeL", "plantL", "hFR", "hAR", "kFR", "hRR", "toeR", "plantR"]
NEG_ON_MIRROR = {"yaw", "bRoll", "bSpin", "roll", "twist", "side"}

# ---------- math ----------
def qmul(a, b):
    w1, x1, y1, z1 = a; w2, x2, y2, z2 = b
    return (w1*w2 - x1*x2 - y1*y2 - z1*z2, w1*x2 + x1*w2 + y1*z2 - z1*y2,
            w1*y2 - x1*z2 + y1*w2 + z1*x2, w1*z2 + x1*y2 - y1*x2 + z1*w2)
def qaxis(ax, deg):
    h = math.radians(deg) / 2; s = math.sin(h)
    return (math.cos(h), ax[0]*s, ax[1]*s, ax[2]*s)
def qx(d): return qaxis((1, 0, 0), d)
def qy(d): return qaxis((0, 1, 0), d)
def qz(d): return qaxis((0, 0, 1), d)
def rot(q, v):
    p = (0.0,) + tuple(v)
    qc = (q[0], -q[1], -q[2], -q[3])
    r = qmul(qmul(q, p), qc)
    return (r[1], r[2], r[3])
def add(a, b): return tuple(x + y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
DOWN, UP = (0, -1, 0), (0, 1, 0)

# ---------- pose data ----------
def load():
    with open(DATA) as f:
        return json.load(f)

def resolve(data, ref, seen=()):
    """A frame is a pose name or {"base": name, field: value, "mirror": bool}. Returns a full field dict."""
    poses = data["poses"]
    if isinstance(ref, str):
        ref = {"base": ref}
    base = ref.get("base")
    out = {k: 0.0 for k in FIELDS}
    if base:
        if base in seen: raise ValueError("pose loop " + base)
        out = resolve(data, poses[base], seen + (base,))
    for k, v in ref.items():
        if k in FIELDS: out[k] = float(v)
        elif k.startswith("+") and k[1:] in FIELDS: out[k[1:]] += float(v)
    if ref.get("mirror"):
        m = dict(out)
        for k in FIELDS:
            if k.endswith("L") and k[:-1] + "R" in out:
                m[k], m[k[:-1] + "R"] = out[k[:-1] + "R"], out[k]
        for k in NEG_ON_MIRROR: m[k] = -out[k]
        out = m
    return out

def joints(p):
    """Same as Motion3D.joints in Swift. Units: figure units (standing height about 80)."""
    Rb = qmul(qmul(qmul(qy(p["yaw"]), qx(p["bRoll"])), qz(-p["bPitch"])), qy(p["bSpin"]))
    qT = qmul(qmul(qmul(Rb, qx(p["roll"])), qz(-p["pitch"])), qy(-p["twist"]))
    j = {}
    pelvis = (0.0, 0.0, 0.0)
    spine = rot(qT, UP)
    j["pelvis"] = pelvis
    j["chest"] = mul(spine, 17)
    j["neck"] = mul(spine, 26)
    qH = qmul(qT, qz(-p["nod"]))
    j["headBase"] = add(j["neck"], rot(qH, mul(UP, 3)))
    j["head"] = add(j["neck"], rot(qH, mul(UP, 9)))
    sb = add(j["neck"], mul(spine, -2.5))
    for side, s in (("L", -1), ("R", 1)):
        sh = add(sb, rot(qT, (0, 0, 7 * s)))
        A = qmul(qmul(qT, qx(-s * p["sA" + side])), qz(p["sF" + side]))
        el = add(sh, mul(rot(A, DOWN), 14))
        fa = qmul(qmul(A, qy(s * p["aR" + side])), qz(p["eF" + side]))
        ha = add(el, mul(rot(fa, DOWN), 13))
        j["sh" + side], j["el" + side], j["ha" + side] = sh, el, ha
        hp = add(pelvis, rot(Rb, (0, 0, 4.5 * s)))
        Q = qmul(qmul(Rb, qx(-s * p["hA" + side])), qz(p["hF" + side]))
        kn = add(hp, mul(rot(Q, DOWN), 19))
        S = qmul(qmul(Q, qy(s * p["hR" + side])), qz(-p["kF" + side]))
        an = add(kn, mul(rot(S, DOWN), 19))
        # Feet stay level with the pelvis unless "plant" points them (so knees can bend with flat feet).
        F = qmul(qmul(qmul(Rb, qx(-s * p["hA" + side])), qy(-s * p["toe" + side])), qz(90 - p["plant" + side]))
        to = add(an, mul(rot(F, DOWN), 6))
        j["hip" + side], j["kn" + side], j["an" + side], j["to" + side] = hp, kn, an, to
    return j

BONES = [("pelvis", "chest", 4.6), ("chest", "neck", 5.2), ("shL", "shR", 3.2), ("hipL", "hipR", 3.8),
         ("neck", "headBase", 1.8),
         ("shL", "elL", 2.2), ("elL", "haL", 1.9), ("hipL", "knL", 3.1), ("knL", "anL", 2.4), ("anL", "toL", 1.6),
         ("shR", "elR", 2.2), ("elR", "haR", 1.9), ("hipR", "knR", 3.1), ("knR", "anR", 2.4), ("anR", "toR", 1.6)]

def placed(p):
    j = joints(p)
    # Ground: lowest joint on the floor (allowing for limb thickness), then lift and travel.
    radius = {"pelvis": 4.6, "chest": 5.2, "neck": 5.2, "head": 6, "headBase": 1.8}
    lo = min(v[1] - radius.get(k, 2.4 if k[:2] in ("to", "an", "kn", "ha", "el") else 3) for k, v in j.items())
    shift = (p["fwd"], -lo + p["lift"], p["side"])
    return {k: add(v, shift) for k, v in j.items()}

# ---------- timing ----------
def frames_of(data, name):
    m = data["moves"][name]
    fr = [resolve(data, f) for f in m["frames"]]
    w = [float(f.get("w", 1)) if isinstance(f, dict) else 1.0 for f in m["frames"]]
    return m, fr, w

def pose_at(fr, w, u):
    if len(fr) == 1: return fr[0]
    total = sum(w); t = (u % 1) * total
    for i in range(len(fr)):
        if t < w[i] or i == len(fr) - 1:
            a, b = fr[i], fr[(i + 1) % len(fr)]
            x = min(1, t / w[i]); x = x * x * (3 - 2 * x)
            return {k: a[k] + (b[k] - a[k]) * x for k in FIELDS}
        t -= w[i]

# ---------- raster ----------
W = H = 150
def draw_frame(j, yaw_deg, img, zb, ox, oy, center):
    cy, sy = math.cos(math.radians(yaw_deg)), math.sin(math.radians(yaw_deg))
    scale = 1.4
    def proj(v):
        x, y, z = v[0] - center[0], v[1], v[2] - center[1]
        # camera orbits around y: yaw 0 looks from +z (side view of a figure facing +x)
        sx = x * cy - z * sy
        depth = x * sy + z * cy
        return (ox + W / 2 + sx * scale, oy + H - 18 - y * scale, depth)
    # floor line
    for xx in range(ox + 10, ox + W - 10):
        put(img, zb, xx, oy + H - 18, -1e9, (60, 60, 70))
    items = []
    for a, b, r in BONES:
        side = "L" if a.endswith("L") or b.endswith("L") else ("R" if a.endswith("R") or b.endswith("R") else "C")
        col = {"L": (90, 150, 210), "R": (130, 200, 255), "C": (120, 180, 240)}[side]
        pa, pb = proj(j[a]), proj(j[b])
        n = max(2, int(math.dist(pa[:2], pb[:2]) / 1.5))
        for i in range(n + 1):
            t = i / n
            items.append((pa[0] + (pb[0] - pa[0]) * t, pa[1] + (pb[1] - pa[1]) * t, pa[2] + (pb[2] - pa[2]) * t, r * scale, col))
    h = proj(j["head"])
    items.append((h[0], h[1], h[2], 6 * scale, (230, 230, 240)))
    for c in ("haL", "haR"):
        q = proj(j[c]); items.append((q[0], q[1], q[2], 2.3 * scale, (200, 220, 255)))
    for x, y, d, r, col in items:
        ri = int(r) + 1
        for yy in range(int(y) - ri, int(y) + ri + 1):
            for xx in range(int(x) - ri, int(x) + ri + 1):
                dd = (xx - x) ** 2 + (yy - y) ** 2
                if dd <= r * r:
                    shade = 0.65 + 0.35 * (1 - dd / (r * r)) ** 0.5
                    put(img, zb, xx, yy, d + (r * r - dd) ** 0.5 / scale, tuple(int(c * shade) for c in col))

def put(img, zb, x, y, d, col):
    if 0 <= x < img["w"] and 0 <= y < img["h"]:
        i = y * img["w"] + x
        if d > zb[i]:
            zb[i] = d
            img["px"][i] = col

COMPACT = os.environ.get("COMPACT") == "1"

def sheet(data, names, path, cols=6):
    views = [40] if COMPACT else [0, 40]
    if COMPACT: cols = 5
    rows = len(names) * len(views)
    img = {"w": W * cols, "h": H * rows, "px": [(18, 18, 24)] * (W * cols * H * rows)}
    zb = [-1e18] * (W * cols * H * rows)
    for ni, name in enumerate(names):
        m, fr, w = frames_of(data, name)
        samples = [pose_at(fr, w, c / cols) for c in range(cols)]
        js = [placed(s) for s in samples]
        xs = [v[0] for j in js for v in j.values()]; zs = [v[2] for j in js for v in j.values()]
        center = ((min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2)
        for vi, yaw in enumerate(views):
            for c, j in enumerate(js):
                draw_frame(j, yaw, img, zb, c * W, (ni * len(views) + vi) * H, center)
    raw = bytearray()
    for (r, g, b) in img["px"]:
        raw += bytes((r, g, b))
    ppm = b"P6 %d %d 255\n" % (img["w"], img["h"]) + bytes(raw)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "image2pipe", "-vcodec", "ppm", "-i", "-", path], input=ppm, check=True)

def main():
    data = load()
    names = sys.argv[1:] or list(data["moves"].keys())
    os.makedirs(OUT, exist_ok=True)
    per = 10 if COMPACT else 5
    for i in range(0, len(names), per):
        chunk = names[i:i + per]
        p = os.path.join(OUT, "_".join(chunk)[:80] + ".png")
        sheet(data, chunk, p)
        print(p)

if __name__ == "__main__":
    main()
