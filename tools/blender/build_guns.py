"""Build every gun and sight as bevelled Blender geometry -> guns.glb.

Objects exported (Godot gun space; see gunkit.py):
    <model>_body    the static gun (receiver, stock, barrel, sights...)
    <model>_mag     the magazine (or revolver cylinder), in gun space
    <model>_charge  charging handle, in gun space
    <model>_slide   pistol slide, in gun space
    <model>_bolt    sniper bolt, relative to its pivot (0, 0.072, 0)
    <model>_pump    shotgun fore-end, in gun space
    opt_reddot, opt_holo, opt_acog   optics with their mount at the origin
    irons_rear, irons_front          flip-up iron sights at the origin
    ak_mount, shotgun_rail           optic mounts, in gun space
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkit  # noqa: E402
import build_guns_parts as parts  # noqa: E402
from gunkit import Kit  # noqa: E402

GUNS = [
    ("rifle", parts.m4, "mag"),
    ("ak", parts.ak, "mag"),
    ("smg", parts.smg, "mag"),
    ("sniper", parts.sniper, "mag"),
    ("shotgun", parts.shotgun, "pump"),
    ("pistol", parts.pistol, "mag"),
    ("lmg", parts.lmg, "mag"),
    ("dmr", parts.dmr, "mag"),
    ("revolver", parts.revolver, "mag"),
]


def finish_nonempty(model, out):
    if len(model.bm.verts) == 0:
        model.bm.free()
        return
    out.append(model.finish(smooth_angle=30.0))


def main():
    bkit.reset()
    objs = []
    k = Kit()
    for name, fn, second in GUNS:
        body = bkit.Model(name + "_body")
        mag = bkit.Model(name + "_" + second)
        parts.P.clear()
        for extra in ("charge", "slide", "bolt"):
            parts.P[extra] = bkit.Model(name + "_" + extra)
        fn(body, mag, k)
        finish_nonempty(body, objs)
        finish_nonempty(mag, objs)
        for extra in ("charge", "slide", "bolt"):
            finish_nonempty(parts.P[extra], objs)
    for name, fn in (("opt_reddot", k.red_dot), ("opt_holo", k.holo), ("opt_acog", k.acog)):
        m = bkit.Model(name)
        fn(m)
        objs.append(m.finish(smooth_angle=30.0))
    for name, fn in (("irons_rear", k.irons_rear), ("irons_front", k.irons_front)):
        m = bkit.Model(name)
        fn(m)
        objs.append(m.finish(smooth_angle=30.0))
    m = bkit.Model("ak_mount")
    k.box(m, 0.07, 0.07, (0.008, 0.04, 0.09), "black", -0.03)
    k.box(m, 0.07, 0.092, (0.05, 0.008, 0.09), "black", -0.008)
    objs.append(m.finish(smooth_angle=30.0))
    m = bkit.Model("shotgun_rail")
    k.rail(m, 0.0, 0.16, 0.079, 0.022)
    objs.append(m.finish(smooth_angle=30.0))
    bkit.export("guns.glb", objs)


main()
