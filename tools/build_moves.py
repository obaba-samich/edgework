#!/usr/bin/env python3
"""Authoring script for Edgework/Data/moves.json (the app reads only the JSON).

Angles (degrees), all relative to the joint above:
  body:  yaw (+ turns left), bPitch (90 face-down, -90 face-up), bRoll (+ onto right side), bSpin (turn about the body's long axis),
         pitch (torso lean forward), roll (side bend to the right), twist (+ turns shoulders right),
         nod (head down), lift / fwd / side (figure units, ~80 = standing height)
  arms:  sF raise forward (90 level, 180 overhead), sA raise out to the side, eF elbow bend, aR forearm roll
  legs:  hF thigh forward, hA thigh out to the side, kF knee bend, hR shin roll, toe turn-out, plant (90 = on toes)
Suffix L/R = the person's left/right. The figure faces +x.
    python3 tools/build_moves.py && python3 tools/posepreview.py <move> ...
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
poses, moves, exercises = {}, {}, {}

def P(base=None, **kw):
    if isinstance(base, dict):
        d = dict(base)
        d.pop("w", None)
    else:
        d = {"base": base} if base else {}
    for k, v in kw.items():
        d[k.replace("_", "+") if k.startswith("_") else k] = v
    return d

def M(frame):
    """Mirror a frame (left <-> right)."""
    f = dict(frame) if isinstance(frame, dict) else {"base": frame}
    f["mirror"] = not f.get("mirror", False)
    return f

def W(frame, w):
    f = dict(frame) if isinstance(frame, dict) else {"base": frame}
    f["w"] = w
    return f

def pose(name, base=None, **kw):
    poses[name] = P(base, **kw)

def move(name, dur, frames, prop=None, ids=()):
    m = {"dur": dur, "frames": frames}
    if prop: m["prop"] = prop
    moves[name] = m
    for i in ids: exercises[i] = name

def alt(name, dur, side_pose, between=None, prop=None, ids=()):
    """Right side, (neutral), left side, (neutral)."""
    fr = [side_pose] + ([between] if between else []) + [M(side_pose)] + ([between] if between else [])
    move(name, dur, fr, prop, ids)

def hold(name, p, dur=4, ids=(), prop=None, breathe=3):
    """A held stretch or position with a slight breathing sway."""
    b = dict(p) if isinstance(p, dict) else {"base": p}
    b2 = dict(b); b2["+pitch"] = b2.get("+pitch", 0) + breathe
    move(name, dur, [b, b2], prop, ids)

# ---------------------------------------------------------------- base poses
pose("stand", sAL=7, sAR=7, eFL=10, eFR=10, toeL=6, toeR=6)
pose("armsFront", "stand", sFL=90, sFR=90, sAL=0, sAR=0, eFL=0, eFR=0)
pose("ready", "stand", pitch=18, hFL=38, kFL=55, hFR=38, kFR=55, hAL=8, hAR=8, sFL=30, sFR=30, eFL=45, eFR=45)
pose("squatLow", "stand", pitch=38, hFL=100, kFL=118, hFR=100, kFR=118, sFL=95, sFR=95, eFL=0, eFR=0, sAL=0, sAR=0, toeL=14, toeR=14, hAL=6, hAR=6)
pose("squatHalf", "squatLow", pitch=24, hFL=60, kFL=72, hFR=60, kFR=72)
pose("deepSquat", "squatLow", pitch=30, hFL=125, kFL=145, hFR=125, kFR=145, hAL=14, hAR=14, sFL=70, sFR=70, eFL=60, eFR=60, sAL=-20, sAR=-20)
pose("lungeR", "stand", pitch=4, hFR=82, kFR=85, hFL=-18, kFL=98, plantL=50, sFL=0, sFR=0)
pose("stepR", "stand", hFR=22, kFR=8, hFL=-14, kFL=12, plantL=25, sFL=-16, sFR=18, eFR=20)
pose("halfKneelR", "stand", hFR=88, kFR=88, hFL=0, kFL=92, plantL=160)
pose("sideLungeR", "stand", pitch=30, hAR=38, hFR=62, kFR=88, toeR=25, hAL=30, sFL=85, sFR=85, sAL=-15, sAR=-15, eFL=40, eFR=40)
pose("hinge", "stand", pitch=78, hFL=12, kFL=16, hFR=12, kFR=16, sFL=78, sFR=78, sAL=0, sAR=0, eFL=0, eFR=0, nod=-20)
pose("plankHigh", bPitch=76, sFL=76, sFR=76, sAL=8, sAR=8, plantL=70, plantR=70, hAL=3, hAR=3, nod=-10)
pose("plankLow", "plankHigh", bPitch=86, sFL=22, sFR=22, eFL=88, eFR=88, sAL=22, sAR=22)
pose("forearmPlank", bPitch=84, sFL=84, sFR=84, eFL=88, eFR=88, sAL=6, sAR=6, plantL=80, plantR=80, nod=-6)
pose("kneePlank", "plankHigh", bPitch=58, sFL=58, sFR=58, kFL=95, kFR=95, plantL=170, plantR=170)
pose("lieBack", bPitch=-90, hFL=55, kFL=105, hFR=55, kFR=105, sAL=12, sAR=12, plantL=-20, plantR=-20)
pose("lieFlat", bPitch=-90, sAL=10, sAR=10, plantL=-60, plantR=-60)
pose("prone", bPitch=90, sAL=12, sAR=12, plantL=150, plantR=150)
pose("quad", bPitch=90, sFL=90, sFR=90, sAL=4, sAR=4, hFL=90, kFL=90, hFR=90, kFR=90, plantL=170, plantR=170, nod=-15)
pose("seatedLong", bPitch=-8, pitch=0, hFL=95, hFR=95, sFL=20, sFR=20, plantL=-40, plantR=-40)
pose("seatedBent", bPitch=-35, pitch=10, hFL=100, kFL=95, hFR=100, kFR=95, sFL=75, sFR=75, eFL=70, eFR=70, sAL=-30, sAR=-30, plantL=20, plantR=20)
pose("kneelTall", "stand", hFL=0, kFL=90, hFR=0, kFR=90, plantL=170, plantR=170)
pose("hang", "stand", sAL=165, sAR=165, eFL=0, eFR=0, sFL=0, sFR=0, plantL=40, plantR=40, lift=22)
pose("runR", "stand", pitch=10, hFR=62, kFR=85, hFL=-22, kFL=45, plantL=35, sFL=45, eFL=90, sFR=-38, eFR=80, sAL=4, sAR=4, lift=3)
pose("sprintR", "runR", pitch=14, hFR=80, kFR=95, hFL=-30, kFL=55, sFL=70, eFL=90, sFR=-55, eFR=85, lift=6)
pose("jogR", "runR", pitch=6, hFR=40, kFR=70, hFL=-15, kFL=40, sFL=30, sFR=-25, lift=2)
pose("highKneeR", "stand", pitch=2, hFR=95, kFR=95, plantL=40, sFL=60, eFL=90, sFR=-25, eFR=90, lift=3)
pose("stickStance", "ready", pitch=30, hAL=14, hAR=14, toeL=20, toeR=20, sFL=40, eFL=20, sAL=-10, sFR=55, eFR=10, sAR=-25)
pose("shuffleIn", "ready", hAL=10, hAR=10)
pose("shuffleOut", "ready", hAL=24, hAR=24, kFL=48, kFR=48)

# ---------------------------------------------------------------- lower body
move("idle", 3, ["stand", P("stand", _pitch=2)])
move("squat", 2.4, ["stand", W("squatLow", 1.1)], ids=["air-squat", "back-squat", "jump-squat-hold"])
move("gobletSquat", 2.4, [P("stand", sFL=30, eFL=120, sFR=30, eFR=120, sAL=-12, sAR=-12),
                          P("squatLow", sFL=40, eFL=110, sFR=40, eFR=110, sAL=-15, sAR=-15)], prop="kettlebell", ids=["goblet-squat"])
move("dbSquat", 2.4, [P("stand", sFL=0, sFR=0, sAL=4, sAR=4, eFL=0, eFR=0), P("squatLow", sFL=30, sFR=30, sAL=4, sAR=4, eFL=0, eFR=0)], prop="dumbbells", ids=["db-squat"])
move("squatPulse", 0.8, ["squatLow", P("squatLow", hFL=82, kFL=98, hFR=82, kFR=98, pitch=32)], ids=["squat-pulse"])
hold("wallSit", P("squatLow", pitch=0, hFL=90, kFL=90, hFR=90, kFR=90, sFL=0, sFR=0, sAL=8, sAR=8, eFL=10, eFR=10), ids=["wall-sit"])
move("sumo", 2.4, [P("stand", hAL=22, hAR=22, toeL=35, toeR=35, sFL=30, sFR=30, eFL=110, eFR=110, sAL=-15, sAR=-15),
                   P("squatLow", hAL=38, hAR=38, toeL=40, toeR=40, hFL=75, kFL=100, hFR=75, kFR=100, pitch=12, sFL=30, sFR=30, eFL=110, eFR=110, sAL=-15, sAR=-15)],
     ids=["sumo-squat"])
move("lunge", 2.6, ["stand", W("lungeR", 1.1), "stand", W(M("lungeR"), 1.1)], ids=["forward-lunge"])
move("reverseLunge", 2.6, ["stand", P("lungeR", hFL=-30, kFL=100), "stand", M(P("lungeR", hFL=-30, kFL=100))], ids=["reverse-lunge"])
move("walkingLunge", 3, ["lungeR", "stepR", M("lungeR"), M("stepR")], ids=["walking-lunge"])
twist_arms = dict(sFL=80, eFL=70, sAL=-30, sFR=80, eFR=70, sAR=-30)
move("walkingLungeTwist", 4.6, [
    "stand", "lungeR", W(P("lungeR", twist=55, nod=-5, **twist_arms), 0.8), "lungeR",
    "stand", M("lungeR"), W(M(P("lungeR", twist=55, nod=-5, **twist_arms)), 0.8), M("lungeR")], ids=["walking-lunge-twist"])
move("lungeReach", 3.6, ["stand", P("lungeR", sFL=175, sFR=175, eFL=0, eFR=0, pitch=-10, roll=-12), "stand",
                         M(P("lungeR", sFL=175, sFR=175, eFL=0, eFR=0, pitch=-10, roll=-12))], ids=["lunge-reach"])
move("curtsy", 2.8, ["stand", P("lungeR", hFL=-12, hAL=-30, kFL=95, pitch=8, sFL=80, sFR=80, eFL=60, eFR=60, sAL=-20, sAR=-20),
                     "stand", M(P("lungeR", hFL=-12, hAL=-30, kFL=95, pitch=8, sFL=80, sFR=80, eFL=60, eFR=60, sAL=-20, sAR=-20))], ids=["curtsy-lunge"])
move("bulgarian", 2.6, [P("stand", hFR=10, kFR=10, hFL=-30, kFL=95, plantL=170),
                        P("lungeR", hFL=-40, kFL=105, plantL=170, pitch=12)], ids=["bulgarian-split-squat"])
move("sideLunge", 3.6, ["stand", W("sideLungeR", 1.2), "stand", W(M("sideLungeR"), 1.2)], ids=["lateral-lunge"])
move("cossack", 3.6, [P("sideLungeR", hFR=100, kFR=130, hAR=42, hAL=40, toeL=-40, plantL=-30),
                      M(P("sideLungeR", hFR=100, kFR=130, hAR=42, hAL=40, toeL=-40, plantL=-30))], ids=["cossack-squat"])
move("stepUp", 2.6, [P("stand", hFR=75, kFR=85, sFL=20, sFR=-15), P("stand", hFL=90, kFL=95, plantR=0, lift=24, sFR=30, eFR=80, sFL=-20),
                     P("stand", lift=24, hFL=8, kFL=8)], ids=["step-ups"])
move("hinge", 2.4, [P("stand", sFL=0, sFR=0, sAL=4, sAR=4, eFL=0, eFR=0), "hinge"], prop="dumbbells", ids=["romanian-deadlift"])
move("deadlift", 2.4, [P("stand", sFL=0, sFR=0, sAL=10, sAR=10, eFL=0, eFR=0),
                       P("hinge", pitch=60, hFL=45, kFL=60, hFR=45, kFR=60, sFL=60, sFR=60, sAL=10, sAR=10)], prop="dumbbells", ids=["trap-deadlift"])
move("singleLegRdl", 3, [P("stand", sFL=0, sFR=0, eFL=0, eFR=0),
                         P("hinge", pitch=85, hFL=-80, kFL=5, plantL=80, hFR=10, kFR=15, sFL=85, sFR=85)], prop="dumbbells", ids=["single-leg-rdl"])
move("kbSwing", 1.6, [P("hinge", pitch=60, hFL=40, kFL=45, hFR=40, kFR=45, sFL=20, sFR=20, sAL=-12, sAR=-12),
                      P("stand", sFL=95, sFR=95, sAL=-12, sAR=-12, eFL=0, eFR=0, pitch=-4)], prop="kettlebell", ids=["kb-swing"])
move("bridge", 2.2, ["lieBack", P("lieBack", bPitch=-118, hFL=10, kFL=100, hFR=10, kFR=100, plantL=-60, plantR=-60)], ids=["glute-bridge"])
move("singleBridge", 2.2, [P("lieBack", hFL=90, kFL=10), P("lieBack", bPitch=-118, hFR=10, kFR=100, plantR=-60, hFL=30, kFL=5)],
     ids=["single-leg-bridge", "single-leg-hip-thrust"])
move("calfRaise", 1.6, ["stand", P("stand", lift=4, plantL=50, plantR=50)], ids=["calf-raise"])
move("singleCalf", 1.6, [P("stand", hFL=-10, kFL=80, sFR=40), P("stand", hFL=-10, kFL=80, sFR=40, lift=4, plantR=50)], ids=["single-leg-calf-raise"])
move("nordic", 3.4, [P("kneelTall", sFL=20, sFR=20, eFL=100, eFR=100, sAL=-10, sAR=-10),
                     W(P("kneelTall", bPitch=55, sFL=80, sFR=80, eFL=40, eFR=40), 1.4), P("kneelTall", bPitch=78, sFL=85, sFR=85, eFL=10, eFR=10)],
     ids=["nordic-curl"])
move("copenhagen", 3, [P("forearmPlank", yaw=-90, bPitch=0, bRoll=-78, pitch=0, sFL=0, sAL=86, eFL=88, sFR=0, sAR=10, hAR=8, hAL=-6, kFL=90, hFL=0),
                       P("forearmPlank", yaw=-90, bPitch=0, bRoll=-70, pitch=0, sFL=0, sAL=86, eFL=88, sFR=0, sAR=10, hAR=8, hAL=-6, kFL=90, hFL=0, lift=4)],
     ids=["copenhagen-plank"])
move("donkeyKick", 1.6, ["quad", P("quad", hFR=-20, kFR=90)], ids=["donkey-kick"])
move("fireHydrant", 1.6, ["quad", P("quad", hAR=60, hRR=10)], ids=["fire-hydrant"])
move("gluteKickback", 1.6, [P("stand", pitch=20, sFL=30, sFR=30), P("stand", pitch=25, hFR=-40, kFR=10, plantR=40, sFL=30, sFR=30)], ids=["glute-kickback"])
move("lateralWalk", 1.6, [P("ready", hAL=10, hAR=10), P("ready", hAL=28, hAR=8, side=-3), P("ready", hAL=10, hAR=10, side=-6)],
     ids=["banded-lateral-walk"])
move("skaterSquat", 2.6, [P("stand", hFL=-10, kFL=80, sFL=20, sFR=20), P("squatLow", hFL=-25, kFL=100, plantL=170, hFR=85, kFR=100, sFL=80, sFR=80)],
     ids=["skater-squat"])

# ---------------------------------------------------------------- upper body
move("pushup", 2.2, ["plankHigh", W("plankLow", 1.1)], ids=["push-up", "decline-push-up"])
move("widePushup", 2.2, [P("plankHigh", sAL=30, sAR=30), P("plankLow", sAL=45, sAR=45, sFL=40, sFR=40)], ids=["wide-push-up"])
move("diamondPushup", 2.2, [P("plankHigh", sAL=-6, sAR=-6), P("plankLow", sAL=0, sAR=0, sFL=10, sFR=10, eFL=100, eFR=100)], ids=["diamond-push-up"])
move("kneePushup", 2.2, ["kneePlank", P("kneePlank", bPitch=78, sFL=20, sFR=20, eFL=88, eFR=88, sAL=22, sAR=22)], ids=["knee-push-up"])
move("inclinePushup", 2.2, [P("plankHigh", bPitch=55, sFL=55, sFR=55, lift=18), P("plankHigh", bPitch=60, sFL=5, sFR=5, eFL=90, eFR=90, sAL=20, sAR=20, lift=12)],
     ids=["incline-push-up"])
move("plyoPushup", 1.4, ["plankLow", W(P("plankHigh", lift=8, sFL=60, sFR=60), 0.7), "plankHigh"], ids=["plyo-push-up"])
move("pike", 2.2, [P("plankHigh", bPitch=40, pitch=60, sFL=120, sFR=120, hFL=0, hFR=0, plantL=40, plantR=40),
                   P("plankHigh", bPitch=40, pitch=70, sFL=85, sFR=85, eFL=80, eFR=80, sAL=20, sAR=20, plantL=40, plantR=40)], ids=["pike-push-up"])
move("pullup", 2.4, ["hang", P("hang", sAL=110, sAR=110, eFL=115, eFR=115, aRL=-10, aRR=-10, lift=40)], prop="bar", ids=["pull-up", "negative-pull-up"])
move("chinup", 2.4, [P("hang", sAL=0, sAR=0, sFL=170, sFR=170), P("hang", sAL=0, sAR=0, sFL=40, sFR=40, eFL=130, eFR=130, lift=40)], prop="bar", ids=["chin-up"])
move("invertedRow", 2.2, [P("lieFlat", bPitch=-70, sFL=110, sFR=110, sAL=0, sAR=0, plantL=-70, plantR=-70),
                          P("lieFlat", bPitch=-70, sFL=60, sFR=60, eFL=100, eFR=100, sAL=10, sAR=10, plantL=-70, plantR=-70, lift=6)], prop="bar",
     ids=["inverted-row"])
move("dbRow", 2, [P("hinge", pitch=75, hFR=40, kFR=60, hFL=0, kFL=10, sFR=90, eFR=0, sFL=80, eFL=0),
                  P("hinge", pitch=75, hFR=40, kFR=60, hFL=0, kFL=10, sFR=80, eFR=0, sFL=20, eFL=100)], prop="dumbbells", ids=["db-row"])
move("bandRow", 2, [P("stand", pitch=-4, sFL=90, sFR=90, eFL=0, eFR=0, sAL=0, sAR=0), P("stand", pitch=-4, sFL=10, sFR=10, eFL=95, eFR=95, sAL=8, sAR=8)],
     ids=["band-row"])
move("benchPress", 2, [P("lieBack", sFL=90, sFR=90, sAL=0, sAR=0, eFL=0, eFR=0), P("lieBack", sFL=10, sFR=10, sAL=70, sAR=70, eFL=90, eFR=90, aRL=-90, aRR=-90)],
     prop="dumbbells", ids=["db-bench"])
move("chestFly", 2.2, [P("lieBack", sFL=90, sFR=90, sAL=0, sAR=0, eFL=10, eFR=10), P("lieBack", sFL=0, sFR=0, sAL=85, sAR=85, eFL=15, eFR=15)], prop="dumbbells",
     ids=["chest-fly"])
move("press", 2, [P("stand", sAL=90, sAR=90, eFL=95, eFR=95, aRL=-90, aRR=-90), P("stand", sAL=172, sAR=172, eFL=5, eFR=5)], prop="dumbbells", ids=["db-press"])
move("arnold", 2.6, [P("stand", sFL=80, sFR=80, sAL=0, sAR=0, eFL=140, eFR=140), P("stand", sAL=90, sAR=90, eFL=95, eFR=95, aRL=-90, aRR=-90),
                     P("stand", sAL=172, sAR=172, eFL=5, eFR=5)], prop="dumbbells", ids=["arnold-press"])
move("lateralRaise", 2, [P("stand", sAL=8, sAR=8, eFL=10, eFR=10), P("stand", sAL=88, sAR=88, eFL=10, eFR=10)], prop="dumbbells", ids=["lateral-raise"])
move("frontRaise", 2, [P("stand", sFL=0, sFR=0, sAL=4, sAR=4, eFL=5, eFR=5), P("stand", sFL=90, sFR=90, sAL=4, sAR=4, eFL=5, eFR=5)], prop="dumbbells", ids=["front-raise"])
move("reverseFly", 2, [P("hinge", pitch=70, sFL=70, sFR=70, sAL=0, sAR=0, eFL=10, eFR=10), P("hinge", pitch=70, sFL=70, sFR=70, sAL=85, sAR=85, eFL=10, eFR=10)],
     prop="dumbbells", ids=["reverse-fly"])
move("uprightRow", 2, [P("stand", sFL=0, sFR=0, sAL=0, sAR=0, eFL=0, eFR=0), P("stand", sAL=85, sAR=85, eFL=100, eFR=100, aRL=-80, aRR=-80)], prop="dumbbells",
     ids=["upright-row"])
move("curl", 1.8, [P("stand", sFL=0, sFR=0, sAL=5, sAR=5, eFL=0, eFR=0), P("stand", sFL=5, sFR=5, sAL=5, sAR=5, eFL=140, eFR=140)], prop="dumbbells",
     ids=["db-curl", "hammer-curl"])
move("wristCurl", 1.2, [P("stand", sFL=0, sFR=0, eFL=90, eFR=90), P("stand", sFL=0, sFR=0, eFL=100, eFR=100)], prop="dumbbells", ids=["wrist-curl"])
move("tricepExt", 2, [P("stand", sFL=175, sFR=175, sAL=0, sAR=0, eFL=10, eFR=10), P("stand", sFL=170, sFR=170, sAL=0, sAR=0, eFL=140, eFR=140)],
     prop="dumbbells", ids=["overhead-extension"])
move("skullCrusher", 2, [P("lieBack", sFL=90, sFR=90, sAL=0, sAR=0), P("lieBack", sFL=110, sFR=110, sAL=0, sAR=0, eFL=110, eFR=110)], prop="dumbbells",
     ids=["skull-crusher"])
move("dip", 2.2, [P("seatedLong", bPitch=0, hFL=80, kFL=10, hFR=80, kFR=10, sFL=-25, sFR=-25, eFL=25, eFR=25, plantL=-20, plantR=-20),
                  P("seatedLong", bPitch=0, pitch=8, hFL=95, kFL=10, hFR=95, kFR=10, sFL=-95, sFR=-95, eFL=95, eFR=95, plantL=-20, plantR=-20)], ids=["bench-dip"])
move("facePull", 2, [P("stand", sFL=90, sFR=90, eFL=0, eFR=0), P("stand", sAL=85, sAR=85, sFL=0, sFR=0, eFL=100, eFR=100, aRL=-90, aRR=-90)], ids=["face-pull"])
move("pullApart", 1.8, [P("stand", sFL=90, sFR=90, sAL=0, sAR=0, eFL=0, eFR=0), P("stand", sFL=0, sFR=0, sAL=90, sAR=90, eFL=0, eFR=0)], ids=["band-pull-apart"])
alt("carry", 1.4, P("stepR", sFL=0, sFR=0, sAL=8, sAR=8, eFL=0, eFR=0), prop="dumbbells", ids=["farmer-carry"])
alt("suitcaseCarry", 1.4, P("stepR", sFL=0, sFR=0, sAR=6, sAL=25, eFL=20, eFR=0, roll=-5), ids=["suitcase-carry"])
move("renegadeRow", 2.4, ["plankHigh", P("plankHigh", sFR=40, eFR=95, sAR=10, bRoll=-8), "plankHigh", P("plankHigh", sFL=40, eFL=95, sAL=10, bRoll=8)],
     prop="dumbbells", ids=["renegade-row"])
move("superman", 2.2, [P("prone", sFL=170, sFR=170, sAL=10, sAR=10), P("prone", bPitch=84, pitch=-18, nod=-10, sFL=170, sFR=170, sAL=10, sAR=10, hFL=-20, hFR=-20, lift=2)], ids=["superman"])

# ---------------------------------------------------------------- core
hold("plank", "forearmPlank", ids=["plank"])
hold("highPlank", "plankHigh")
side_plank = P("forearmPlank", yaw=-90, bPitch=0, bRoll=-78, sFL=0, sAL=82, eFL=88, sFR=0, sAR=8, eFR=10, plantL=0, plantR=0, hAL=-4, hAR=4)
hold("sidePlank", side_plank, ids=["side-plank"])
move("sidePlankDip", 2, [side_plank, P(side_plank, bRoll=-62)], ids=["side-plank-dip"])
move("deadBug", 2.6, [P("lieBack", sFL=90, sFR=90, sAL=0, sAR=0, hFL=90, kFL=90, hFR=90, kFR=90, eFL=0, eFR=0, plantL=0, plantR=0),
                      P("lieBack", sFL=175, sFR=90, sAL=0, sAR=0, hFL=90, kFL=90, hFR=10, kFR=5, eFL=0, eFR=0, plantL=0, plantR=0),
                      P("lieBack", sFL=90, sFR=90, sAL=0, sAR=0, hFL=90, kFL=90, hFR=90, kFR=90, eFL=0, eFR=0, plantL=0, plantR=0),
                      P("lieBack", sFL=90, sFR=175, sAL=0, sAR=0, hFL=10, kFL=5, hFR=90, kFR=90, eFL=0, eFR=0, plantL=0, plantR=0)], ids=["dead-bug"])
move("birdDog", 2.8, ["quad", P("quad", sFL=180, sAL=0, hFR=0, kFR=0, plantR=90), "quad", P("quad", sFR=180, sAR=0, hFL=0, kFL=0, plantL=90)],
     ids=["bird-dog"])
crunch_up = P("lieBack", pitch=35, nod=10, sFL=30, sFR=30, sAL=-35, sAR=-35, eFL=140, eFR=140)
move("crunch", 1.8, [P(crunch_up, pitch=0), crunch_up], ids=["crunch"])
move("situp", 2.2, [P("lieBack", sFL=170, sFR=170, sAL=0, sAR=0), P("lieBack", pitch=95, sFL=90, sFR=90, sAL=0, sAR=0, eFL=10, eFR=10)], ids=["sit-up"])
move("situpTwist", 2.8, [P("lieBack", sFL=40, sFR=40, eFL=90, eFR=90, sAL=-30, sAR=-30), P("lieBack", pitch=85, twist=40, sFL=60, sFR=60, eFL=90, eFR=90, sAL=-30, sAR=-30),
                         P("lieBack", sFL=40, sFR=40, eFL=90, eFR=90, sAL=-30, sAR=-30), P("lieBack", pitch=85, twist=-40, sFL=60, sFR=60, eFL=90, eFR=90, sAL=-30, sAR=-30)],
     ids=["sit-up-twist"])
bike = P("lieBack", pitch=35, sFL=120, sFR=120, sAL=40, sAR=40, eFL=140, eFR=140, aRL=-60, aRR=-60, hFL=95, kFL=90, plantL=0, plantR=0)
alt("bicycle", 1.6, P(bike, twist=-35, hFL=110, kFL=110, hFR=25, kFR=5), ids=["bicycle-crunch"])
alt("russianTwist", 1.4, P("seatedBent", twist=50, lift=3, plantL=40, plantR=40), prop="ball", ids=["russian-twist"])
move("vup", 2, [P("lieFlat", sFL=175, sFR=175, sAL=0, sAR=0), P("lieFlat", bPitch=-60, pitch=50, sFL=100, sFR=100, sAL=0, sAR=0, hFL=95, hFR=95)], ids=["v-ups"])
move("toeTouchCrunch", 1.8, [P("lieFlat", hFL=90, hFR=90, sFL=90, sFR=90, sAL=0, sAR=0), P("lieFlat", hFL=90, hFR=90, pitch=40, sFL=110, sFR=110, sAL=0, sAR=0)],
     ids=["toe-touch-crunch"])
hold("hollow", P("lieFlat", pitch=22, sFL=165, sFR=165, sAL=0, sAR=0, hFL=25, hFR=25, plantL=-40, plantR=-40), ids=["hollow-hold"])
move("legRaise", 2.2, [P("lieFlat", hFL=8, hFR=8), P("lieFlat", hFL=90, hFR=90)], ids=["leg-raise"])
move("reverseCrunch", 2, [P("lieBack", hFL=70, kFL=90, hFR=70, kFR=90), P("lieBack", bPitch=-110, hFL=115, kFL=100, hFR=115, kFR=100)], ids=["reverse-crunch"])
alt("flutter", 0.7, P("lieFlat", pitch=15, hFR=30, hFL=12), ids=["flutter-kicks"])
alt("scissor", 0.9, P("lieFlat", pitch=15, hFR=30, hFL=30, hAR=-12, hAL=25), ids=["scissor-kicks"])
alt("windshield", 2.4, P("lieFlat", sAL=85, sAR=85, hFL=90, hFR=90, bSpin=50, twist=50, plantL=0, plantR=0), between=P("lieFlat", sAL=85, sAR=85, hFL=90, hFR=90, plantL=0, plantR=0), ids=["windshield-wipers"])
alt("mountainClimber", 0.7, P("plankHigh", hFR=95, kFR=105, plantR=60), ids=["mountain-climbers"])
move("plankJack", 0.9, ["plankHigh", P("plankHigh", hAL=20, hAR=20, lift=2)], ids=["plank-jacks"])
move("shoulderTap", 1.8, ["plankHigh", P("plankHigh", sFR=110, sAR=-55, eFR=60, bRoll=-6), "plankHigh", P("plankHigh", sFL=110, sAL=-55, eFL=60, bRoll=6)],
     ids=["plank-shoulder-taps"])
move("hangingKneeRaise", 2, ["hang", P("hang", hFL=105, kFL=100, hFR=105, kFR=100)], prop="bar", ids=["hanging-knee-raise"])
move("pallof", 2, [P("ready", pitch=5, sFL=10, sFR=10, eFL=110, eFR=110, sAL=-30, sAR=-30), P("ready", pitch=5, sFL=90, sFR=90, sAL=-12, sAR=-12, eFL=0, eFR=0)],
     ids=["pallof-press"])
alt("heelTouch", 1.2, P("lieBack", pitch=25, roll=20, sFL=0, sFR=0, sAL=0, sAR=0, eFL=0, eFR=0), ids=["heel-touches"])
alt("bearCrawl", 0.9, P("quad", lift=5, hFR=110, kFR=110, hFL=75, kFL=90, plantL=80, plantR=80, sFL=110, sFR=75), ids=["bear-crawl"])
move("medBallRotation", 1.4, [P("ready", twist=-60, sFL=60, sFR=60, sAL=-25, sAR=-25, eFL=30, eFR=30),
                              P("ready", twist=55, sFL=80, sFR=80, sAL=-20, sAR=-20, eFL=10, eFR=10, hFL=20, kFL=20)], prop="ball", ids=["med-ball-rotation-throw"])

# ---------------------------------------------------------------- power & plyo
load = P("squatHalf", sFL=-40, sFR=-40, eFL=10, eFR=10, sAL=0, sAR=0, pitch=40)
move("squatJump", 1.4, ["stand", W(load, 0.9), W(P("stand", sFL=170, sFR=170, sAL=0, sAR=0, eFL=0, eFR=0, plantL=60, plantR=60, lift=18), 0.6),
                        W(P("squatHalf", sFL=40, sFR=40, eFL=40, eFR=40), 0.8)], ids=["squat-jump"])
move("tuckJump", 1.3, [W(load, 0.8), W(P("stand", hFL=110, kFL=120, hFR=110, kFR=120, sFL=80, sFR=80, eFL=60, eFR=60, sAL=-10, sAR=-10, pitch=10, lift=26), 0.6),
                       W(P("squatHalf", sFL=40, sFR=40), 0.8), "stand"], ids=["tuck-jump"])
move("broadJump", 1.9, ["stand", W(P(load, sFL=-60, sFR=-60, fwd=-14), 0.9),
                        W(P("stand", pitch=30, sFL=150, sFR=150, sAL=0, sAR=0, eFL=0, eFR=0, hFL=-10, hFR=-10, plantL=70, plantR=70, lift=14, fwd=0), 0.5),
                        W(P("stand", pitch=10, hFL=70, kFL=50, hFR=70, kFR=50, sFL=90, sFR=90, eFL=0, eFR=0, lift=12, fwd=12), 0.4),
                        W(P("squatHalf", sFL=60, sFR=60, fwd=16), 0.8), P("stand", fwd=16)], ids=["broad-jump", "frog-jumps"])
move("boxJump", 1.9, ["stand", W(load, 0.8), W(P("stand", pitch=20, hFL=100, kFL=110, hFR=100, kFR=110, sFL=120, sFR=120, sAL=0, sAR=0, eFL=0, eFR=0, lift=28), 0.6),
                      W(P("squatHalf", sFL=50, sFR=50, lift=18), 0.9), P("stand", lift=18)], ids=["box-jump", "depth-jump"])
move("splitJump", 1.5, ["lungeR", W(P("stand", hFR=30, kFR=30, hFL=-10, kFL=40, lift=16, sFL=60, sFR=-20, eFL=60), 0.6), M("lungeR"),
                        W(P("stand", hFL=30, kFL=30, hFR=-10, kFR=40, lift=16, sFR=60, sFL=-20, eFR=60), 0.6)], ids=["split-jump"])
skate_land = P("stand", pitch=35, hFR=70, kFR=90, hAR=10, hFL=-20, hAL=-25, kFL=70, plantL=60, twist=20, sFL=60, sAL=-20, sFR=-40, eFL=40, side=12)
skate_air = P("stand", pitch=20, hFR=40, kFR=60, hFL=20, kFL=60, lift=12, side=0, sFL=10, sFR=10)
move("skaterBound", 1.8, [skate_land, W(skate_air, 0.6), M(skate_land), W(M(skate_air), 0.6)], ids=["skater-bound", "skater-hops", "slide-board", "lateral-bound-sprint"])
move("lateralHop", 1.4, [P("stand", hFL=40, kFL=80, pitch=15, hFR=30, kFR=40, side=6), W(P("stand", hFL=40, kFL=80, hFR=10, kFR=20, lift=10, side=0), 0.6),
                         P("stand", hFL=40, kFL=80, pitch=15, hFR=30, kFR=40, side=-6), W(P("stand", hFL=40, kFL=80, hFR=10, kFR=20, lift=10, side=0), 0.6)],
     ids=["lateral-hop"])
move("pogo", 0.5, [P("stand", plantL=20, plantR=20, sFL=20, sFR=20, eFL=80, eFR=80), P("stand", plantL=70, plantR=70, lift=7, sFL=20, sFR=20, eFL=80, eFR=80)],
     ids=["pogo-hops"])
move("slam", 1.4, [W(P("stand", pitch=-10, sFL=175, sFR=175, sAL=0, sAR=0, eFL=0, eFR=0, plantL=40, plantR=40, lift=2), 0.8),
                   P("squatHalf", pitch=70, sFL=75, sFR=75, sAL=0, sAR=0, eFL=0, eFR=0)], prop="ball", ids=["med-ball-slam"])
move("heiden", 2, [P("stand", pitch=30, hFR=70, kFR=90, hFL=-10, hAL=-25, kFL=80, plantL=60, sFL=60, side=10),
                   W(P("stand", lift=10, hFR=20, kFR=40, side=0), 0.5),
                   P("stand", pitch=30, hFL=70, kFL=90, hFR=-10, hAR=-25, kFR=80, plantR=60, sFR=60, side=-10), W(P("stand", lift=10, hFL=20, kFL=40, side=0), 0.5)],
     ids=["heiden-hold"])

# ---------------------------------------------------------------- conditioning
crouch = P("squatLow", pitch=60, sFL=60, sFR=60, hFL=120, kFL=130, hFR=120, kFR=130)
move("burpee", 3.2, ["stand", crouch, W("plankHigh", 0.8), "plankLow", "plankHigh", crouch,
                     W(P("stand", sFL=175, sFR=175, sAL=0, sAR=0, eFL=0, eFR=0, plantL=70, plantR=70, lift=14), 0.7)], ids=["burpees"])
move("halfBurpee", 2.2, ["stand", crouch, "plankHigh", crouch], ids=["half-burpee"])
move("sprawl", 2, ["ready", crouch, P("plankHigh", bPitch=82, sFL=82, sFR=82, hFL=-5, hFR=-5), crouch], ids=["sprawls"])
move("squatThrustTuck", 2.8, ["stand", crouch, "plankHigh", crouch, W(P("stand", hFL=110, kFL=120, hFR=110, kFR=120, sFL=80, sFR=80, lift=24), 0.6)],
     ids=["squat-thrust-tuck"])
jack_out = P("stand", sAL=165, sAR=165, eFL=0, eFR=0, hAL=20, hAR=20, plantL=30, plantR=30, lift=3)
move("jack", 1.0, ["stand", jack_out], ids=["jumping-jacks", "side-skips"])
move("starJump", 1.3, [P("squatHalf", sFL=30, sFR=30, sAL=0, sAR=0), W(P("stand", sAL=130, sAR=130, eFL=0, eFR=0, hAL=32, hAR=32, plantL=70, plantR=70, lift=18), 0.6)],
     ids=["star-jumps"])
move("squatJack", 1.4, [P("stand", sFL=30, sFR=30, eFL=110, eFR=110, sAL=-15, sAR=-15),
                        P("squatLow", hAL=32, hAR=32, toeL=30, toeR=30, hFL=80, kFL=100, hFR=80, kFR=100, pitch=15, sFL=30, sFR=30, eFL=110, eFR=110, sAL=-15, sAR=-15)],
     ids=["squat-jacks"])
move("jumpRope", 0.5, [P("stand", sAL=30, sAR=30, eFL=70, eFR=70, sFL=10, sFR=10, plantL=30, plantR=30),
                       P("stand", sAL=30, sAR=30, eFL=70, eFR=70, sFL=10, sFR=10, plantL=70, plantR=70, lift=6)], ids=["jump-rope"])
alt("runInPlace", 0.6, P("jogR", fwd=0), ids=["run-in-place"])
alt("shadowBox", 1.2, P("ready", hFL=20, hFR=20, twist=-35, sFL=90, eFL=5, sAL=0, sFR=70, eFR=120, sAR=-20), ids=["shadow-boxing"])
move("inchworm", 4.6, ["stand", P("hinge", pitch=110, sFL=110, sFR=110, kFL=0, kFR=0, hFL=0, hFR=0), W("plankHigh", 1.4), "plankHigh",
                       P("hinge", pitch=110, sFL=110, sFR=110, kFL=0, kFR=0, hFL=0, hFR=0)], ids=["inchworm"])
move("inchwormPushup", 5, ["stand", P("hinge", pitch=110, sFL=110, sFR=110, kFL=0, kFR=0), "plankHigh", "plankLow", "plankHigh",
                           P("hinge", pitch=110, sFL=110, sFR=110, kFL=0, kFR=0)], ids=["inchworm-push-up"])

# ---------------------------------------------------------------- running & speed
alt("run", 0.66, "runR", ids=["warmup-jog", "easy-run", "easy-jog", "distance-run", "long-run", "tempo-run", "fartlek", "progression-run", "mile-run",
                              "mile-repeats", "rep-800", "repeats-400", "tempo-1k", "jog-sprint", "shift-sprints", "tempo-100", "speed-150",
                              "rep-200", "rep-300", "sprints-200", "hill-repeats"])
alt("jog", 0.8, "jogR", ids=["cooldown-jog"])
alt("sprint", 0.5, "sprintR", ids=["sprint-40", "flying-sprints", "flying-30", "strides", "sprint-60", "accel-30", "line-sprints", "hill-sprints",
                                   "approach-runs", "stair-runs", "crossover-run", "shuttle-run"])
alt("backpedal", 0.7, P("ready", pitch=30, hFR=50, kFR=80, hFL=10, kFL=50, plantL=50, sFL=40, sFR=-20, eFL=90, eFR=90), ids=["backpedal", "backward-run", "backpedal-sprint"])
move("shuffle", 1.2, ["shuffleIn", P("shuffleOut", side=-5), "shuffleIn", P("shuffleOut", side=5)], ids=["lateral-shuffle-warm", "lateral-shuffle", "pro-agility", "t-drill",
                                                                                                    "t-push-shuffle"])
alt("quickFeet", 0.35, P("ready", hFR=55, kFR=75, lift=2), ids=["quick-feet"])
move("sprintStart", 2.2, [P("ready", pitch=45, hFR=60, kFR=70, hFL=-10, kFL=30, plantL=60, sFL=40, sFR=-30, eFL=90, eFR=80),
                          W(P("sprintR", pitch=40, fwd=6), 0.6), W(M(P("sprintR", pitch=35, fwd=12)), 0.6), P("sprintR", pitch=25, fwd=18)], ids=["sprint-starts"])
move("bounding", 1.2, [P("stand", pitch=10, hFR=85, kFR=90, hFL=-35, kFL=20, plantL=60, sFL=80, sFR=-50, eFL=60, lift=14),
                       M(P("stand", pitch=10, hFR=85, kFR=90, hFL=-35, kFL=20, plantL=60, sFL=80, sFR=-50, eFL=60, lift=14))], ids=["bounding", "box-bound"])
move("singleLegBound", 1.4, [P("stand", pitch=12, hFR=85, kFR=95, hFL=-30, kFL=40, plantL=60, sFL=70, sFR=70, sAL=-5, sAR=-5, lift=14),
                             P("stand", pitch=12, hFR=-10, kFR=100, hFL=50, kFL=50, sFL=-40, sFR=-40, lift=2)], ids=["single-leg-bound"])
move("standingTriple", 2.4, [P("squatHalf", sFL=-50, sFR=-50), P("stand", pitch=20, hFR=80, kFR=90, hFL=-30, lift=14, sFL=90, sFR=90),
                             P("stand", pitch=20, hFR=-10, kFR=110, hFL=80, kFL=60, lift=14, sFL=-40, sFR=-40),
                             P("stand", pitch=30, hFL=95, kFL=70, hFR=95, kFR=70, lift=10, sFL=120, sFR=120), P("squatHalf", sFL=80, sFR=80)], ids=["standing-triple"])
move("popUp", 1.4, [P("runR", pitch=15), W(P("stand", hFR=100, kFR=110, hFL=-20, kFL=20, plantL=80, sFL=170, sFR=170, sAL=0, sAR=0, eFL=0, eFR=0, lift=22, pitch=-5), 0.8)],
     ids=["pop-ups"])
move("hjScissor", 1.6, [P("runR", yaw=40), W(P("stand", yaw=60, hFR=95, kFR=10, hFL=20, kFL=10, lift=24, sFL=120, sFR=120, sAL=10, sAR=10), 0.6),
                        W(P("stand", yaw=60, hFL=95, kFL=10, hFR=10, kFR=10, lift=20, sFL=90, sFR=90), 0.6)], ids=["scissor-kicks-hj"])

# ---------------------------------------------------------------- warm-up
alt("highKnees", 0.55, "highKneeR", ids=["high-knees", "a-skips", "walking-knee-drive", "fast-leg"])
alt("buttKick", 0.55, P("stand", pitch=4, hFR=-10, kFR=150, plantR=160, plantL=40, sFL=40, eFL=90, sFR=-30, eFR=90, lift=3), ids=["butt-kicks", "butt-kickers"])
alt("bSkip", 1.0, P("stand", hFR=90, kFR=15, plantR=0, plantL=40, sFL=60, eFL=90, sFR=-30, eFR=90, lift=4), between=P("highKneeR", hFR=60, kFR=90), ids=["b-skips"])
alt("powerSkip", 1.1, P("stand", pitch=-5, hFR=100, kFR=100, hFL=-15, kFL=20, plantL=70, sFL=170, sFR=-30, sAL=0, eFL=10, eFR=60, lift=20), ids=["power-skips"])
move("carioca", 1.6, [P("ready", yaw=90, hFR=20, hAR=-25, twist=30, side=0), P("ready", yaw=90, hAL=25, hAR=20, twist=0, side=-6),
                      P("ready", yaw=90, hFR=-15, hAR=-25, kFR=40, twist=-30, side=-12), P("ready", yaw=90, hAL=25, hAR=20, twist=0, side=-18)],
     ids=["carioca"])
alt("kneeHug", 1.8, P("stand", hFR=125, kFR=125, sFL=60, sFR=60, eFL=110, eFR=110, sAL=-20, sAR=-20, plantL=50, lift=3), between="stand",
    ids=["knee-hugs"])
alt("hipCradle", 2, P("stand", hFR=90, hAR=30, hRR=-60, kFR=100, sFL=60, sFR=45, eFL=110, eFR=110, sAL=-20, sAR=-10, plantL=50, lift=3), between="stand",
    ids=["hip-cradle"])
alt("quadPull", 1.8, P("stand", hFR=-10, kFR=150, plantR=160, sFR=-30, eFR=40, sFL=170, sAL=0, eFL=0, plantL=50, lift=3), between="stand",
    ids=["walking-quad-pull", "quad-stretch"])
alt("frankenstein", 1.6, P("stand", sFL=90, sFR=90, sAL=0, sAR=0, eFL=0, eFR=0, hFR=90, kFR=0, plantR=0), between=P("stand", sFL=90, sFR=90, sAL=0, sAR=0, eFL=0, eFR=0),
    ids=["frankenstein"])
move("legSwingFront", 1.4, [P("stand", sAL=80, eFL=10, hFR=70, kFR=10, plantR=0), P("stand", sAL=80, eFL=10, hFR=-35, kFR=10, plantR=30)], ids=["leg-swings-front"])
move("legSwingSide", 1.4, [P("stand", sFL=80, sFR=80, sAL=0, sAR=0, eFL=10, eFR=10, hAR=45, hFR=8), P("stand", sFL=80, sFR=80, sAL=0, sAR=0, eFL=10, eFR=10, hAR=-25, hFR=15)],
     ids=["leg-swings-lateral", "hurdle-mobility"])
move("armCircles", 1.2, [P("stand", sAL=90, sAR=90, eFL=0, eFR=0, sFL=0, sFR=0), P("stand", sAL=90, sAR=90, eFL=0, eFR=0, sFL=20, sFR=20),
                         P("stand", sAL=110, sAR=110, eFL=0, eFR=0), P("stand", sAL=90, sAR=90, eFL=0, eFR=0, sFL=-20, sFR=-20)], ids=["arm-circles"])
alt("gateOpener", 2, P("stand", hFR=90, kFR=90, hAR=55, hRR=-30, plantL=40, sAL=40, sAR=40, eFL=40, eFR=40, lift=2), between="stand", ids=["gate-openers"])
alt("walk", 1.2, "stepR", ids=["heel-toe-walk"])
alt("crabWalk", 1.2, P("seatedBent", bPitch=-60, lift=10, sFL=-60, sFR=-60, eFL=0, eFR=0, sAL=10, sAR=10, hFR=70, kFR=80, plantL=0, plantR=0),
    ids=["crab-walk"])
alt("duckWalk", 1.2, P("deepSquat", hFR=115, kFR=130, sFL=60, sFR=60, eFL=90, eFR=90, plantL=40, pitch=25), ids=["duck-walk"])
spider = P("lungeR", hFR=110, kFR=120, hAR=20, pitch=60, hFL=-30, kFL=5, plantL=80, sFL=60, sFR=60, eFL=0, eFR=0, sAL=0, sAR=0)
move("spiderman", 3.6, [spider, P(spider, sFR=-20, sAR=60, eFR=10, twist=-10), M(spider), M(P(spider, sFR=-20, sAR=60, eFR=10, twist=-10))],
     ids=["spiderman-lunge"])
move("worldsGreatest", 4.4, [spider, P(spider, twist=-80, sFR=0, sAR=175, eFR=0, pitch=50), spider, M(spider), M(P(spider, twist=-80, sFR=0, sAR=175, eFR=0, pitch=50)), M(spider)],
     ids=["worlds-greatest"])

# ---------------------------------------------------------------- mobility & stretches
hold("toeTouch", P("hinge", pitch=110, hFL=0, kFL=0, hFR=0, kFR=0, sFL=110, sFR=110, nod=30), ids=["toe-touch", "standing-hamstring"])
hold("figure4", P("stand", pitch=35, hFL=60, kFL=70, hFR=75, hAR=40, hRR=-80, kFR=95, sFL=80, sFR=80, eFL=20, eFR=20, sAL=-10, sAR=-10), ids=["figure-4"])
alt("sideReach", 4, P("stand", roll=-28, sAR=175, eFR=10, sAL=20, eFL=40), ids=["side-reach"])
hold("crossBody", P("stand", sFR=90, sAR=-50, eFR=0, sFL=75, sAL=-30, eFL=110), ids=["cross-body-shoulder"])
hold("tricepStretch", P("stand", sFR=175, sAR=-10, eFR=160, sFL=150, sAL=-20, eFL=110), ids=["tricep-stretch"])
hold("doorwayChest", P("lungeR", hFR=30, kFR=30, hFL=-10, kFL=10, plantL=30, sAL=90, sAR=90, eFL=90, eFR=90, aRL=-90, aRR=-90, sFL=-20, sFR=-20, pitch=-5),
     ids=["doorway-chest"])
hold("calfStretch", P("lungeR", hFR=40, kFR=45, hFL=-25, kFL=0, plantL=0, pitch=20, sFL=90, sFR=90, eFL=20, eFR=20, sAL=0, sAR=0), ids=["calf-stretch", "knee-to-wall"])
hold("downDog", P("plankHigh", bPitch=45, pitch=75, sFL=165, sFR=165, plantL=20, plantR=20, nod=10), ids=["downward-dog"])
hold("cobra", P("prone", pitch=-45, sFL=30, sFR=30, eFL=10, eFR=10, sAL=10, sAR=10, nod=-15), ids=["cobra"])
hold("childPose", P("kneelTall", bPitch=95, hFL=120, hFR=120, kFL=150, kFR=150, sFL=175, sFR=175, sAL=0, sAR=0, eFL=0, eFR=0), ids=["childs-pose"])
move("catCow", 3.6, [P("quad", pitch=-14, nod=-20), P("quad", pitch=16, nod=30)], ids=["cat-cow"])
move("rockBack", 3, [P("quad", hAR=55, hRR=90, kFR=0, hFR=0, plantR=0), P("quad", bPitch=60, hAR=55, hRR=90, kFR=0, hFR=0, plantR=0, hFL=130, kFL=140)],
     ids=["adductor-rockback"])
hold("frog", P("quad", sFL=120, sFR=120, eFL=90, eFR=90, hAL=60, hAR=60, hRL=90, hRR=90), ids=["frog-stretch"])
hold("pigeon", P("prone", bPitch=70, pitch=-30, sFL=60, sFR=60, hFR=95, hAR=10, hRR=-95, kFR=90, plantR=0, hFL=-5), ids=["pigeon"])
n9090 = P("seatedLong", bPitch=-5, hFR=90, kFR=90, hAR=10, hRR=-90, hFL=0, hAL=70, kFL=90, hRL=0, sFL=40, sFR=40)
knees_up = P("seatedBent", bPitch=-20, sFL=-30, sFR=-30, eFL=0, eFR=0, sAL=10, sAR=10, hAL=20, hAR=20)
move("hip9090", 4.4, [n9090, knees_up, M(n9090), knees_up], ids=["hip-90-90", "goalie-hip-rotation"])
move("kneelingHipFlexor", 3.6, ["halfKneelR", P("halfKneelR", hFR=100, kFR=100, pitch=-8, sFL=175, eFL=0, sAL=0, roll=10)], ids=["kneeling-hip-flexor"])
hold("couch", P("halfKneelR", hFL=-10, kFL=165, plantL=180, pitch=-5), ids=["couch-stretch"])
move("butterfly", 3, [P("seatedLong", bPitch=-5, hFL=40, hFR=40, hAL=60, hAR=60, hRL=60, hRR=60, kFL=140, kFR=140, sFL=50, sFR=50, eFL=30, eFR=30),
                      P("seatedLong", bPitch=10, hFL=40, hFR=40, hAL=60, hAR=60, hRL=60, hRR=60, kFL=140, kFR=140, sFL=60, sFR=60, eFL=30, eFR=30, pitch=20)],
     ids=["butterfly-stretch"])
hold("lyingHamstring", P("lieFlat", hFR=95, sFL=60, sFR=60, eFL=40, eFR=40, plantR=0), ids=["hamstring-band-stretch"])
alt("spinalTwist", 4, P("lieFlat", sAL=90, sAR=90, hFR=85, kFR=90, hAR=-45, roll=0, bRoll=-15), ids=["spinal-twist"])
move("openBook", 3.6, [P("lieBack", yaw=-90, bRoll=-90, bPitch=0, sFL=90, sFR=90, sAL=0, sAR=0, hFL=80, kFL=90, hFR=80, kFR=90),
                       P("lieBack", yaw=-90, bRoll=-90, bPitch=0, sFL=90, sFR=0, sAL=0, sAR=90, twist=-80, hFL=80, kFL=90, hFR=80, kFR=90)], ids=["open-book"])
alt("hipIR", 3, P("lieBack", hRR=40, hAR=-15), ids=["hip-ir-stretch"])
hold("deepSquatHold", "deepSquat", ids=["deep-squat-hold"])
move("neckRolls", 4, [P("stand", nod=25), P("stand", roll=-12, nod=10), P("stand", nod=-15), P("stand", roll=12, nod=10)], ids=["neck-rolls"])
move("foamRollLegs", 2.4, [P("forearmPlank", lift=6, fwd=-6), P("forearmPlank", lift=6, fwd=6)], ids=["foam-roll-legs"])
move("foamRollBack", 2.4, [P("lieBack", bPitch=-75, lift=8, sFL=40, sFR=40, eFL=130, eFR=130, sAL=-30, sAR=-30, fwd=-4),
                           P("lieBack", bPitch=-75, lift=8, sFL=40, sFR=40, eFL=130, eFR=130, sAL=-30, sAR=-30, fwd=4)], ids=["foam-roll-back"])
hold("groin", P("sideLungeR", pitch=10, sFL=20, sFR=20, eFL=60, eFR=60), ids=["standing-groin"])
hold("balance", P("stand", hFL=40, kFL=60, sAL=80, sAR=80, eFL=10, eFR=10), ids=["eyes-closed-balance"], breathe=2)
move("starReach", 3.4, [P("stand", hFL=30, kFL=50), P("stand", pitch=60, hFR=40, kFR=45, hFL=-50, kFL=5, plantL=70, sFL=100, sFR=100, eFL=0, eFR=0, sAL=0, sAR=0)],
     ids=["star-reach", "single-leg-squat-reach"])
move("hopStick", 1.6, [P("stand", hFL=40, kFL=70, pitch=10, hFR=20, kFR=30), W(P("stand", hFL=40, kFL=70, hFR=0, kFR=10, lift=12, sFL=60, sFR=60, fwd=6), 0.5),
                       W(P("stand", hFL=40, kFL=70, pitch=25, hFR=45, kFR=60, sFL=60, sFR=60, fwd=12), 1.2)], ids=["hop-stick"])

# ---------------------------------------------------------------- track
move("blockStart", 2.6, [W(P("halfKneelR", bPitch=70, pitch=0, hFR=120, kFR=120, hFL=60, kFL=110, plantL=90, plantR=90, sFL=70, sFR=70, sAL=0, sAR=0, eFL=0, eFR=0), 1),
                         P("halfKneelR", bPitch=55, pitch=0, hFR=110, kFR=100, hFL=50, kFL=80, plantL=90, plantR=90, sFL=55, sFR=55, sAL=0, sAR=0, eFL=0, eFR=0, lift=8),
                         W(P("sprintR", pitch=45, fwd=8), 0.6), W(M(P("sprintR", pitch=40, fwd=14)), 0.6)], ids=["block-starts", "three-point-start"])
alt("wallDrive", 0.9, P("stand", bPitch=40, sFL=130, sFR=130, sAL=0, sAR=0, eFL=0, eFR=0, hFR=90, kFR=90, plantL=80, plantR=10), ids=["wall-drive"])
alt("ankling", 0.45, P("stand", hFR=12, kFR=12, plantR=30, plantL=60, sFL=30, eFL=90, sFR=-20, eFR=90, lift=2), ids=["ankling"])
move("batonExchange", 1.6, [P("runR", sFR=-40, eFR=10), P("runR", sFR=-45, sAR=10, eFR=0, sFL=20, eFL=90)], ids=["baton-exchange"])
move("hurdleLead", 1.4, [P("runR"), W(P("stand", pitch=35, hFR=100, kFR=10, plantR=0, hFL=-10, kFL=40, sFL=95, eFL=10, sFR=-30, lift=10), 0.8)], prop="hurdle",
     ids=["lead-leg"])
move("hurdleTrail", 1.6, [P("stand", pitch=30, sFL=80, sFR=80, eFL=10, eFR=10), P("stand", pitch=30, hFR=60, hAR=60, kFR=100, hRR=90, plantR=0, sFL=80, sFR=80)],
     prop="hurdle", ids=["trail-leg"])
move("hurdleWalkover", 2.4, [P("stand", hFR=80, hAR=50, kFR=90, hRR=60, sAL=60, sAR=60), P("stand", hFR=90, kFR=90, sAL=60, sAR=60, lift=2),
                             M(P("stand", hFR=80, hAR=50, kFR=90, hRR=60, sAL=60, sAR=60)), M(P("stand", hFR=90, kFR=90, sAL=60, sAR=60, lift=2))], prop="hurdle",
     ids=["hurdle-walkover"])
move("hurdleHop", 1.2, [P("squatHalf", sFL=-30, sFR=-30), W(P("stand", hFL=100, kFL=110, hFR=100, kFR=110, sFL=90, sFR=90, eFL=40, eFR=40, lift=30), 0.6)], prop="hurdle",
     ids=["hurdle-hops"])
move("threeStep", 1.8, [P("sprintR"), M(P("sprintR")), P("sprintR"),
                        W(P("stand", pitch=35, hFL=100, kFL=10, plantL=0, hFR=60, hAR=60, kFR=100, hRR=90, sFR=95, eFR=10, sFL=-30, lift=14), 0.8)], prop="hurdle",
     ids=["three-step"])
move("shotPut", 2.2, [P("ready", twist=-80, pitch=30, hFR=60, kFR=80, sFR=100, sAR=60, eFR=150, aRR=-60, sFL=90, sAL=20),
                      P("stand", twist=40, pitch=-5, sFR=150, sAR=10, eFR=10, sFL=-20, sAL=40, plantR=70, lift=4)], prop="ball", ids=["shot-stand"])
move("discusTurn", 2.2, [P("ready", yaw=0, twist=-90, sAR=90, sAL=60, eFL=20), P("ready", yaw=-180, twist=-60, sAR=90, sAL=60, lift=4),
                         P("ready", yaw=-360, twist=60, sAR=100, sAL=40)], ids=["discus-turn-drill"])
move("javelinCross", 1.4, [P("runR", yaw=-30, sFR=-60, sAR=20, eFR=0, sFL=80), P(M("runR"), yaw=-30, sFR=-60, sAR=20, eFR=0, sFL=80, lift=6)],
     ids=["javelin-crossovers"])
move("overheadBackToss", 1.8, [P("squatHalf", pitch=60, sFL=60, sFR=60, sAL=0, sAR=0, eFL=0, eFR=0),
                               W(P("stand", pitch=-35, sFL=200, sFR=200, sAL=0, sAR=0, eFL=0, eFR=0, plantL=70, plantR=70, lift=10), 0.7)], prop="ball",
     ids=["overhead-back-toss"])
move("chestPass", 1.4, [P("ready", sFL=20, sFR=20, eFL=120, eFR=120, sAL=-20, sAR=-20), P("lungeR", hFR=40, kFR=40, sFL=95, sFR=95, eFL=0, eFR=0, sAL=0, sAR=0, pitch=15)],
     prop="ball", ids=["chest-pass"])
move("rotationalScoop", 1.6, [P("squatHalf", twist=-60, sFL=30, sFR=30, sAL=-20, sAR=-20, eFL=10, eFR=10),
                              P("stand", twist=60, sFL=130, sFR=130, sAL=-20, sAR=-20, eFL=10, eFR=10, plantR=60)], prop="ball", ids=["rotational-scoop"])

# ---------------------------------------------------------------- hockey
shoot_load = P("stickStance", twist=-55, sFL=60, sAL=-30, eFL=20, sFR=-20, sAR=10, eFR=10, hFR=20, kFR=40, hFL=40, kFL=60)
move("wristShot", 1.4, [shoot_load, W(P("stickStance", twist=40, sFL=90, sAL=-10, eFL=10, sFR=60, sAR=-30, eFR=0, hFR=-10, kFR=10), 0.5),
                        W(P("stickStance", twist=60, sFL=120, sAL=-20, sFR=100, sAR=-40, eFR=0), 0.8)], prop="stick",
     ids=["wrist-shots", "snap-shots", "catch-release", "corner-targets", "middle-release", "quick-release-feet", "rebound-shots",
          "walk-in-shot", "low-glove-blocker", "toe-drag-shot", "around-puck-shot"])
move("slapShot", 1.8, [P("stickStance", twist=-70, sFL=150, sAL=-40, sFR=130, sAR=-30, eFL=10, eFR=20),
                       W(P("stickStance", twist=10, sFL=70, sAL=-30, sFR=40, sAR=-20, hFL=50, kFL=70), 0.5),
                       W(P("stickStance", twist=60, sFL=140, sAL=-30, sFR=120, sAR=-30, plantR=60), 0.9)], prop="stick", ids=["slap-shots", "one-timers"])
move("backhand", 1.4, [P("stickStance", twist=50, sFL=40, sAL=10, sFR=70, sAR=-40), W(P("stickStance", twist=-40, sFL=110, sAL=-20, sFR=120, sAR=0, eFL=10), 0.7)],
     prop="stick", ids=["backhands", "backhand-lift", "deke-backhand", "saucer-pass"])
move("stickhandle", 0.9, [P("stickStance", twist=-15, sFR=45, sAR=-40), P("stickStance", twist=15, sFR=60, sAR=-5)], prop="stick", ids=["stickhandling-session"])

# ---------------------------------------------------------------- goalie
butterfly_down = P("kneelTall", hAL=50, hAR=50, hRL=-60, hRR=-60, kFL=95, kFR=95, plantL=90, plantR=90, sFL=40, sFR=40, sAL=30, sAR=30, eFL=60, eFR=60)
move("butterflyDrop", 1.6, [P("ready", hAL=16, hAR=16, sFL=40, sFR=40, sAL=30, sAR=30, eFL=60, eFR=60), butterfly_down], ids=["butterfly-drops", "goalie-shuffle-drop"])
move("reactionBall", 1.2, [P("ready", sFR=120, sAR=40, eFR=20, sFL=40, eFL=60), P("ready", sFL=130, sAL=40, eFL=20, sFR=40, eFR=60, side=-4)], ids=["reaction-ball"])

# ---------------------------------------------------------------- category fallbacks
categories = {
    "warmup": "jack", "lowerBody": "squat", "upperBody": "pushup", "core": "plank", "power": "squatJump", "speed": "sprint",
    "conditioning": "burpee", "balance": "balance", "mobility": "toeTouch", "stickhandling": "stickhandle", "shooting": "wristShot",
    "goalie": "butterflyDrop", "running": "run", "sprints": "sprint", "hurdles": "highKnees", "jumps": "boxJump", "throwing": "chestPass",
}

if __name__ == "__main__":
    out = {"poses": poses, "moves": moves, "exercises": exercises, "categories": categories}
    with open(os.path.join(ROOT, "Edgework", "Data", "moves.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(f"{len(poses)} poses, {len(moves)} moves, {len(exercises)} exercises mapped")
