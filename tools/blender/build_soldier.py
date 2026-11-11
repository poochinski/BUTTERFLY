"""Soldier figure: a jointed 1/6-scale action figure in felt and card.

Every part is modelled around its joint (the pivot the game animates), so
the figure keeps all of SoldierModel's procedural animation. Blender
space: +X right, +Y forward (the way the soldier faces), +Z up.

Joints (Godot metres, relative to their parent joint):
    hips  (0, 0.95, 0) from the feet
    torso (0, 0.08, 0) from hips        head  (0, 0.47, 0) from torso
    shoulder (+-0.19, 0.42, 0) from torso, elbow (0, -0.29, 0) below it
    hip joint (+-0.095, -0.06, 0) from hips, knee (0, -0.43, 0) below it

Material slots: uniform, uniform_dark, pants, gear, webbing, black, mag,
metal, skin, skin_dark, eye, iris, hair, glove, boot, sole, lace, patch,
knit, shemagh, lens.
"""

import math
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkit  # noqa: E402
from bkit import Model, box, cyl, sphere, skin, shell, torus, tube_path  # noqa: E402
from mathutils import Vector  # noqa: E402


def pelvis():
    m = Model("pelvis")
    # Seat of the trousers: a soft moulded block with the tops of both legs.
    skin(m, "pants", [
        ((0, 0, 0.07), (0.148, 0.104)),
        ((0, 0, -0.01), (0.152, 0.108)),
        ((-0.092, 0.0, -0.075), (0.082, 0.086)),
        ((0.092, 0.0, -0.075), (0.082, 0.086)),
    ], [(0, 1), (1, 2), (1, 3)], subsurf=2)
    # Fly seam and back pockets.
    box(m, "uniform_dark", (0.006, 0.012, 0.09), loc=(0, 0.112, 0.0), bevel=0.002)
    for sx in (-1, 1):
        box(m, "pants", (0.07, 0.012, 0.075), loc=(sx * 0.07, -0.108, -0.01), bevel=0.006)
    # Rigger's belt with a cobra buckle and a few loops.
    torus(m, "webbing", 0.152, 0.016, loc=(0, 0, 0.07), scale=(1.0, 0.71, 1.6), segs=40)
    box(m, "metal", (0.05, 0.012, 0.038), loc=(0, 0.118, 0.07), bevel=0.004)
    box(m, "black", (0.03, 0.01, 0.02), loc=(0, 0.124, 0.07), bevel=0.003)
    return m.finish()


def belt_gear():
    m = Model("belt_gear")
    # Drop-leg holster on the right with the pistol grip showing, and a
    # dump pouch on the left hip.
    box(m, "gear", (0.06, 0.11, 0.17), loc=(0.175, 0.0, -0.1), bevel=0.012, segments=3)
    box(m, "webbing", (0.065, 0.03, 0.02), loc=(0.175, 0.0, -0.03), bevel=0.004)
    box(m, "black", (0.035, 0.05, 0.07), loc=(0.175, -0.01, 0.0), rot=(-15, 0, 0), bevel=0.006)
    tube_path(m, "webbing", [(0.15, 0.06, -0.16), (0.17, 0.07, -0.2), (0.19, 0.06, -0.24)], 0.008)
    box(m, "gear", (0.07, 0.09, 0.12), loc=(-0.17, -0.04, -0.03), bevel=0.02, segments=3)
    box(m, "webbing", (0.075, 0.095, 0.015), loc=(-0.17, -0.04, 0.035), bevel=0.003)
    return m.finish()


def torso():
    m = Model("torso")
    # Chest and belly in a combat shirt, with the shoulder caps.
    skin(m, "uniform", [
        ((0, 0, 0.0), (0.148, 0.105)),
        ((0, 0.005, 0.12), (0.158, 0.112)),
        ((0, 0.012, 0.27), (0.188, 0.125)),
        ((0, 0.0, 0.37), (0.172, 0.118)),
        ((0, 0, 0.46), (0.062, 0.062)),
        ((-0.17, 0, 0.39), (0.07, 0.07)),
        ((0.17, 0, 0.39), (0.07, 0.07)),
    ], [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5), (3, 6)], subsurf=2)
    # Mandarin collar and a zip down the chest.
    torus(m, "uniform_dark", 0.064, 0.016, loc=(0, 0, 0.445), scale=(1.0, 0.95, 1.4), segs=28)
    box(m, "uniform_dark", (0.008, 0.01, 0.16), loc=(0, 0.125, 0.33), bevel=0.002)
    return m.finish()


def carrier():
    m = Model("carrier")
    # Front and back plate bags, cummerbund, padded shoulder straps.
    for y, h in ((0.155, 0.33), (-0.15, 0.35)):
        box(m, "gear", (0.3, 0.06, h), loc=(0, y, 0.27), bevel=0.016, segments=3)
    for sx in (-1, 1):
        box(m, "gear", (0.05, 0.25, 0.15), loc=(sx * 0.168, 0.0, 0.18), bevel=0.012, segments=2)
        box(m, "gear", (0.065, 0.31, 0.035), loc=(sx * 0.11, 0.0, 0.44), bevel=0.012, segments=2)
        box(m, "webbing", (0.04, 0.33, 0.012), loc=(sx * 0.11, 0.0, 0.46), bevel=0.003)
    # MOLLE rows: front below the pouches and all across the back.
    for k in range(4):
        box(m, "webbing", (0.28, 0.008, 0.012), loc=(0, -0.18, 0.15 + k * 0.05), bevel=0.002)
    # Three rifle-mag pouches with shock-cord retainers and mags showing.
    for x in (-0.09, 0.0, 0.09):
        box(m, "gear", (0.08, 0.055, 0.13), loc=(x, 0.205, 0.17), bevel=0.01, segments=2)
        box(m, "mag", (0.05, 0.026, 0.05), loc=(x, 0.205, 0.255), rot=(8, 0, 0), bevel=0.005)
        box(m, "black", (0.006, 0.058, 0.09), loc=(x, 0.206, 0.2), bevel=0.002)
        box(m, "black", (0.03, 0.012, 0.012), loc=(x, 0.234, 0.13), bevel=0.003)
    # Admin pouch with a flag patch; radio with its antenna; drag handle.
    box(m, "gear", (0.19, 0.035, 0.085), loc=(0, 0.2, 0.355), bevel=0.01)
    box(m, "patch", (0.09, 0.006, 0.055), loc=(0, 0.219, 0.36), bevel=0.002)
    box(m, "gear", (0.07, 0.06, 0.14), loc=(-0.13, -0.19, 0.36), bevel=0.012)
    box(m, "black", (0.05, 0.04, 0.11), loc=(-0.13, -0.19, 0.4), bevel=0.008)
    cyl(m, "black", 0.0055, 0.32, loc=(-0.135, -0.2, 0.6), rot=(-6, 4, 0), segs=8)
    torus(m, "webbing", 0.035, 0.008, loc=(0, -0.185, 0.47), rot=(90, 0, 0), scale=(1.4, 1, 1))
    # Hydration carrier on the back.
    box(m, "gear", (0.24, 0.07, 0.3), loc=(0, -0.215, 0.25), bevel=0.025, segments=3)
    tube_path(m, "black", [(0.08, -0.2, 0.4), (0.13, -0.05, 0.47), (0.14, 0.12, 0.42), (0.12, 0.19, 0.33)], 0.007)
    return m.finish()


def rig():
    m = Model("rig")
    # Militia chest rig: a pouch panel on X-harness straps.
    box(m, "gear", (0.36, 0.06, 0.13), loc=(0, 0.155, 0.17), bevel=0.012, segments=2)
    for x in (-0.135, -0.045, 0.045, 0.135):
        box(m, "gear", (0.078, 0.04, 0.13), loc=(x, 0.19, 0.17), bevel=0.01)
        box(m, "mag", (0.05, 0.03, 0.05), loc=(x, 0.18, 0.25), rot=(14, 0, 0), bevel=0.005)
        box(m, "gear", (0.08, 0.045, 0.02), loc=(x, 0.19, 0.235), bevel=0.004)
    for sx in (-1, 1):
        tube_path(m, "webbing", [(sx * 0.13, 0.15, 0.23), (sx * 0.12, 0.1, 0.43), (sx * 0.08, -0.06, 0.46), (-sx * 0.08, -0.13, 0.3), (-sx * 0.15, -0.08, 0.17)], 0.012)
    torus(m, "webbing", 0.162, 0.014, loc=(0, 0, 0.16), scale=(1.0, 0.75, 0.6), segs=36)
    return m.finish()


def _head_shape(variant):
    def shape(v):
        v = Vector(v)
        # Taller cranium, narrower sides, a jaw that tapers to the chin.
        v.z *= 1.12
        v.x *= 0.88
        if v.z < 0:
            t = min(-v.z / 0.12, 1.0)
            v.x *= 1.0 - 0.28 * t
            v.y += 0.012 * t if v.y > 0 else -0.01 * t
            if variant == "b":
                v.x *= 1.06
        # Flatter face plane, rounder back of the head.
        if v.y > 0.05:
            v.y = 0.05 + (v.y - 0.05) * 0.8
        else:
            v.y *= 1.05
        return v
    return shape


def head(variant):
    m = Model("head_" + variant)
    skin(m, "skin", [((0, 0, 0.0), (0.052, 0.05)), ((0, 0.005, 0.08), (0.05, 0.048))], [(0, 1)], subsurf=2)
    sphere(m, "skin", 0.112, loc=(0, 0.012, 0.155), segs=32, rings=20, subsurf=1, shape=_head_shape(variant))
    # Nose bridge and tip, brow ridge, cheekbones, ears.
    nose_w = 0.026 if variant == "a" else 0.03
    box(m, "skin", (nose_w, 0.03, 0.05), loc=(0, 0.112, 0.15), rot=(-12, 0, 0), bevel=0.01, segments=3, taper=(0.6, 0.6))
    sphere(m, "skin", 0.0115, loc=(0, 0.124, 0.13), scale=(1.25, 0.9, 0.85))
    box(m, "skin", (0.1, 0.022, 0.018), loc=(0, 0.1, 0.188), bevel=0.008, segments=3)
    for sx in (-1, 1):
        sphere(m, "skin", 0.017, loc=(sx * 0.05, 0.08, 0.142), scale=(1.2, 0.6, 0.75))
        sphere(m, "skin", 0.024, loc=(sx * 0.1, -0.005, 0.15), scale=(0.35, 0.8, 1.15))
        sphere(m, "skin_dark", 0.012, loc=(sx * 0.104, 0.0, 0.15), scale=(0.3, 0.7, 1.0))
        # Eyes set under the brow, with irises; eyebrows.
        sphere(m, "eye", 0.0155, loc=(sx * 0.037, 0.093, 0.165), segs=16, rings=10)
        sphere(m, "iris", 0.0085, loc=(sx * 0.037, 0.106, 0.165), segs=12, rings=8)
        box(m, "hair", (0.034, 0.008, 0.007), loc=(sx * 0.038, 0.111, 0.186), rot=(0, sx * -8, 0), bevel=0.003)
    # Mouth and a hint of the lower lip.
    box(m, "skin_dark", (0.034, 0.006, 0.004), loc=(0, 0.112, 0.103), bevel=0.0015)
    box(m, "skin", (0.028, 0.008, 0.007), loc=(0, 0.108, 0.096), bevel=0.003)
    # Close-cropped hair at the temples and nape.
    # Hair only on the crown, above the ears and at the nape: never on the
    # face.
    def hair_cut(d):
        if d.y > 0.2:
            return 0.45
        if d.y > -0.35:
            return 0.25
        return -0.35
    shell(m, "hair", 0.117, 0.005, hair_cut, loc=(0, 0.008, 0.16), scale=(0.9, 1.0, 1.08), subsurf=1)
    return m.finish()


def beard():
    m = Model("beard")
    # A short full beard: a shell over the jaw, chin and upper lip.
    shell(m, "hair", 0.11, 0.008, lambda d: 10.0 if d.y < 0.05 or d.z > -0.05 else -2.0,
          loc=(0, 0.02, 0.15), scale=(0.88, 1.02, 1.12), subsurf=1)
    box(m, "hair", (0.04, 0.01, 0.01), loc=(0, 0.118, 0.11), bevel=0.004)
    return m.finish()


def helmet():
    m = Model("helmet")
    # Ballistic helmet in a cloth cover: high cut over the ears.
    def cut(d):
        front = max(d.y, 0.0)
        side = abs(d.x)
        return -0.05 - 0.3 * (1.0 - front) - 0.05 * side
    shell(m, "uniform", 0.138, 0.014, cut, loc=(0, 0.004, 0.185), scale=(0.97, 1.08, 0.95), subsurf=1)
    torus(m, "black", 0.13, 0.008, loc=(0, 0.0, 0.205), scale=(0.96, 1.07, 1.0), segs=40)
    for sx in (-1, 1):
        box(m, "black", (0.012, 0.13, 0.022), loc=(sx * 0.13, -0.005, 0.18), rot=(0, sx * 8, 0), bevel=0.003)
        tube_path(m, "black", [(sx * 0.115, 0.02, 0.15), (sx * 0.09, 0.05, 0.08), (sx * 0.04, 0.085, 0.045), (0, 0.09, 0.04)], 0.004)
    box(m, "black", (0.055, 0.025, 0.045), loc=(0, 0.146, 0.235), rot=(20, 0, 0), bevel=0.006)
    box(m, "metal", (0.03, 0.012, 0.02), loc=(0, 0.16, 0.24), rot=(20, 0, 0), bevel=0.003)
    box(m, "black", (0.035, 0.03, 0.025), loc=(0, -0.11, 0.27), rot=(-35, 0, 0), bevel=0.005)
    box(m, "patch", (0.07, 0.005, 0.045), loc=(0, -0.135, 0.22), rot=(-25, 0, 0), bevel=0.002)
    return m.finish()


def headset():
    m = Model("headset")
    for sx in (-1, 1):
        cyl(m, "black", 0.05, 0.04, loc=(sx * 0.118, -0.005, 0.15), rot=(0, 90, 0), segs=24, bevel=0.008)
        cyl(m, "black", 0.032, 0.012, loc=(sx * 0.141, -0.005, 0.15), rot=(0, 90, 0), segs=20, bevel=0.003)
    tube_path(m, "black", [(0.13, 0.02, 0.13), (0.11, 0.07, 0.1), (0.05, 0.11, 0.095), (0.02, 0.12, 0.1)], 0.004)
    sphere(m, "black", 0.01, loc=(0.02, 0.12, 0.1))
    return m.finish()


def beanie():
    m = Model("beanie")
    shell(m, "knit", 0.122, 0.014, lambda d: -0.05, loc=(0, 0.0, 0.2), scale=(0.95, 1.05, 1.0), subsurf=1)
    torus(m, "knit", 0.12, 0.022, loc=(0, 0.0, 0.2), scale=(0.95, 1.05, 1.4), segs=40)
    return m.finish()


def shemagh():
    m = Model("shemagh")
    # Wrapped scarf at the neck and pulled over the nose and mouth.
    torus(m, "shemagh", 0.072, 0.038, loc=(0, 0.0, 0.045), scale=(1.0, 1.0, 1.3), segs=32)
    shell(m, "shemagh", 0.118, 0.01, lambda d: 10.0 if d.y < -0.25 else -0.05,
          loc=(0, 0.02, 0.12), rot=(-90, 0, 0), scale=(0.95, 1.0, 1.05), subsurf=1)
    box(m, "shemagh", (0.08, 0.03, 0.12), loc=(0.03, -0.09, 0.02), rot=(10, 0, 15), bevel=0.012)
    return m.finish()


def upper_arm(patch):
    m = Model("upper_arm" + ("_patch" if patch else ""))
    skin(m, "uniform", [((0, 0, 0.0), (0.064, 0.064)), ((0, 0, -0.14), (0.058, 0.06)), ((0, 0, -0.27), (0.05, 0.052))], [(0, 1), (1, 2)], subsurf=2)
    if patch:
        box(m, "patch", (0.006, 0.06, 0.045), loc=(-0.062, 0.0, -0.08), bevel=0.002)
    return m.finish()


def forearm():
    m = Model("forearm")
    skin(m, "uniform", [((0, 0, 0.0), (0.052, 0.052)), ((0, 0.002, -0.12), (0.05, 0.048)), ((0, 0, -0.205), (0.04, 0.038))], [(0, 1), (1, 2)], subsurf=2)
    torus(m, "uniform_dark", 0.042, 0.01, loc=(0, 0, -0.2), segs=24)
    # Gloved hand closed in a grip: palm, four curled fingers, thumb,
    # knuckle armour.
    hz = -0.27
    box(m, "glove", (0.075, 0.034, 0.075), loc=(0, 0.0, hz), bevel=0.014, segments=3)
    for k in range(4):
        x = -0.027 + k * 0.018
        tube_path(m, "glove", [(x, 0.015, hz - 0.03), (x, 0.03, hz - 0.055), (x, 0.012, hz - 0.075), (x, -0.012, hz - 0.068)], 0.0085, segs=8)
    tube_path(m, "glove", [(-0.035, 0.012, hz + 0.01), (-0.045, 0.03, hz - 0.02), (-0.03, 0.042, hz - 0.045)], 0.0095, segs=8)
    box(m, "black", (0.07, 0.012, 0.022), loc=(0, -0.02, hz - 0.035), bevel=0.005)
    box(m, "black", (0.05, 0.01, 0.03), loc=(0, -0.019, hz + 0.01), bevel=0.004)
    return m.finish()


def thigh(side):
    m = Model("thigh_" + side)
    sx = 1 if side == "R" else -1
    skin(m, "pants", [((0, 0, 0.0), (0.08, 0.084)), ((0, 0.006, -0.16), (0.074, 0.078)), ((0, 0.004, -0.32), (0.061, 0.064)), ((0, 0, -0.43), (0.055, 0.058))], [(0, 1), (1, 2), (2, 3)], subsurf=2)
    # Cargo pocket with its flap and button.
    box(m, "pants", (0.026, 0.11, 0.12), loc=(sx * 0.077, 0.0, -0.2), bevel=0.01, segments=2)
    box(m, "uniform_dark", (0.03, 0.114, 0.032), loc=(sx * 0.082, 0.0, -0.145), bevel=0.007)
    cyl(m, "black", 0.007, 0.006, loc=(sx * 0.098, 0.0, -0.155), rot=(0, 90, 0), segs=10)
    return m.finish()


def shin():
    m = Model("shin")
    skin(m, "pants", [((0, 0, 0.0), (0.056, 0.059)), ((0, -0.006, -0.12), (0.058, 0.062)), ((0, 0, -0.3), (0.05, 0.052))], [(0, 1), (1, 2)], subsurf=2)
    # Combat boot: shaft, foot with a rounded toe, tread sole, heel, laces.
    cyl(m, "boot", 0.058, 0.15, loc=(0, 0.0, -0.33), segs=24, bevel=0.01)
    box(m, "boot", (0.1, 0.2, 0.08), loc=(0, 0.045, -0.39), bevel=0.03, segments=4)
    sphere(m, "boot", 0.05, loc=(0, 0.13, -0.395), scale=(1.0, 1.0, 0.75))
    box(m, "sole", (0.108, 0.27, 0.022), loc=(0, 0.05, -0.432), bevel=0.008)
    for k in range(6):
        box(m, "sole", (0.1, 0.008, 0.008), loc=(0, -0.06 + k * 0.042, -0.444), bevel=0.002)
    box(m, "sole", (0.1, 0.06, 0.03), loc=(0, -0.055, -0.43), bevel=0.006)
    for k in range(5):
        box(m, "lace", (0.045, 0.006, 0.005), loc=(0, 0.06 - k * 0.012, -0.36 + k * 0.022), rot=(-50 + k * 8, 0, 0), bevel=0.001)
    torus(m, "boot", 0.058, 0.008, loc=(0, 0, -0.26), segs=24)
    return m.finish()


def kneepad():
    m = Model("kneepad")
    shell(m, "black", 0.07, 0.012, lambda d: -0.15, loc=(0, 0.055, -0.02), rot=(-90, 0, 0), scale=(1.0, 1.25, 0.6), subsurf=1)
    torus(m, "webbing", 0.068, 0.008, loc=(0, 0, -0.06), scale=(1.0, 1.05, 1.0), segs=24)
    torus(m, "webbing", 0.068, 0.008, loc=(0, 0, 0.03), scale=(1.0, 1.05, 1.0), segs=24)
    return m.finish()


def main():
    bkit.reset()
    objs = [pelvis(), belt_gear(), torso(), carrier(), rig(), head("a"), head("b"), beard(),
            helmet(), headset(), beanie(), shemagh(), upper_arm(False), upper_arm(True),
            forearm(), thigh("L"), thigh("R"), shin(), kneepad()]
    bkit.export("soldier.glb", objs)


main()
