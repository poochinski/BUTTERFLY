"""Guns for PAPERCUT, modelled in Blender.

GENERATED from scripts/weapons/gun_builder.gd by a converter, then hand
checked: every gun is the same part list at the same coordinates as the
game's procedural guns, so sights, hands, mags and muzzles line up, but
built as real bevelled geometry. Optics, irons and mounts are separate
models placed by the game.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkit  # noqa: E402
from gunkit import Kit, V2, PI, TAU  # noqa: E402,F401

P = {}

def m4(r, mag, k):
    # Lower receiver, flared magwell and the upper with its flat top.
    k.prof(r, [(-0.07, 0.0), (0.2, 0.0), (0.205, 0.02), (0.2, 0.052), (-0.07, 0.052)], 0.05, "paint", "paint_core")
    k.prof(r, [(0.064, 0.004), (0.16, 0.004), (0.156, -0.04), (0.068, -0.04)], 0.048, "paint", "paint_core")
    k.box(r, 0.112, -0.04, (0.056, 0.008, 0.1), "paint")
    k.prof(r, [(-0.075, 0.052), (0.215, 0.052), (0.215, 0.096), (-0.06, 0.096), (-0.075, 0.084)], 0.046, "paint", "paint_core")
    # Ejection port with the dust cover hanging open, brass deflector,
    # forward assist, bolt catch, mag release and the selector.
    k.box(r, 0.06, 0.074, (0.003, 0.018, 0.058), "rubber", 0.0235)
    k.box(r, 0.06, 0.06, (0.002, 0.01, 0.062), "paint", 0.027, (0.0, 0.0, -0.5))
    k.box(r, 0.0, 0.086, (0.008, 0.014, 0.016), "paint", 0.026)
    k.tube(r, -0.045, -0.005, 0.078, 0.009, "paint", 0.027)
    k.rivet(r, -0.045, 0.078, 0.027, 0.007, "black")
    k.box(r, 0.05, 0.042, (0.003, 0.02, 0.012), "black", -0.026)
    k.rivet(r, 0.07, 0.03, 0.026, 0.0055, "black")
    k.box(r, -0.005, 0.034, (0.003, 0.008, 0.026), "black", -0.026, (0.4, 0, 0))
    k.rivet(r, -0.02, 0.026, -0.026, 0.0025, "white")
    # Takedown and pivot pins.
    k.pin(r, -0.058, 0.044, 0.026)
    k.pin(r, 0.19, 0.044, 0.026)
    k.pin(r, 0.03, 0.03, 0.026, 0.0035)
    # Charging handle (pulled on empty reloads).
    charge = P["charge"]
    charge.name = "Charge"
    k.box(charge, -0.07, 0.09, (0.05, 0.008, 0.016), "black")
    k.box(charge, -0.06, 0.09, (0.012, 0.007, 0.03), "black")
    # Buffer tube, castle nut, collapsible stock, butt pad, sling loop.
    k.tube(r, -0.33, -0.075, 0.068, 0.015, "black")
    k.tube(r, -0.095, -0.075, 0.068, 0.019, "black", 0.0, 10)
    k.prof(r, [(-0.13, 0.098), (-0.13, 0.03), (-0.2, 0.018), (-0.31, 0.004), (-0.325, 0.05), (-0.318, 0.1), (-0.2, 0.102)], 0.044, "furn", "furn_core")
    k.box(r, -0.328, 0.052, (0.046, 0.1, 0.012), "rubber")
    k.box(r, -0.165, 0.022, (0.012, 0.008, 0.04), "black")
    k.wrap(r, -0.25, 0.058, (0.044, 0.05), "team", 0.014)
    # Pistol grip with a finger nub, trigger guard and trigger.
    k.prof(r, [(-0.005, 0.004), (0.045, 0.004), (0.036, -0.03), (0.03, -0.04), (0.02, -0.105), (-0.035, -0.098), (-0.018, -0.04)], 0.034, "furn", "furn_core")
    k.box(r, 0.052, -0.034, (0.012, 0.005, 0.034), "paint")
    k.box(r, 0.068, -0.018, (0.012, 0.034, 0.005), "paint")
    k.box(r, 0.048, -0.016, (0.005, 0.026, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # Free-float handguard with M-LOK slots and a top rail.
    k.prof(r, [(0.215, 0.038), (0.47, 0.038), (0.48, 0.048), (0.48, 0.098), (0.47, 0.106), (0.215, 0.106)], 0.056, "paint", "paint_core")
    k.slots(r, 0.24, 0.46, 0.066, 6, (0.026, 0.009), 0.029)
    k.slots(r, 0.26, 0.44, 0.048, 4, (0.026, 0.009), 0.029)
    k.rail(r, -0.06, 0.212, 0.1, 0.024)
    k.rail(r, 0.22, 0.47, 0.11, 0.024)
    # Folded back-up sights.
    k.box(r, -0.035, 0.112, (0.024, 0.008, 0.022), "black")
    k.prof(r, [(0.44, 0.116), (0.47, 0.116), (0.465, 0.126), (0.445, 0.126)], 0.022, "black")
    # Barrel, gas block, birdcage flash hider.
    k.tube(r, 0.48, 0.66, 0.072, 0.0105, "steel")
    k.box(r, 0.5, 0.074, (0.026, 0.026, 0.022), "black")
    k.tube(r, 0.655, 0.73, 0.072, 0.0135, "black")
    for f in [0.675, 0.695, 0.715]:
        k.box(r, f, 0.072, (0.029, 0.004, 0.007), "rubber")
    # Webbing sling from the handguard to the stock.
    k.sling(r, (-0.026, 0.04, 0.44), (-0.024, 0.01, -0.3), 0.13)
    # Curved STANAG magazine with ribs, a baseplate and a pull tab.
    k.prof(mag, [(0.075, -0.036), (0.15, -0.036), (0.165, -0.12), (0.18, -0.18), (0.105, -0.19), (0.092, -0.12)], 0.032, "black")
    for t in [0.25, 0.5, 0.75]:
        c = V2(0.112, -0.036).lerp(V2(0.142, -0.185), t)
        k.box(mag, c.x, c.y, (0.035, 0.004, 0.05), "black", 0.0, (-0.25, 0, 0))
    k.box(mag, 0.142, -0.19, (0.038, 0.012, 0.085), "black", 0.0, (-0.2, 0, 0))
    k.box(mag, 0.11, -0.2, (0.016, 0.022, 0.006), "web", 0.0, (-0.2, 0, 0))
    k.box(mag, 0.113, -0.034, (0.012, 0.008, 0.05), "brass")
    # Optic on the flat-top rail, or flip-up irons.
    return


# ------------------------------------------------------------------ AK-47

def ak(r, mag, k):
    # Stamped receiver and ribbed dust cover.
    k.prof(r, [(-0.06, 0.0), (0.25, 0.0), (0.25, 0.062), (-0.02, 0.062), (-0.06, 0.05)], 0.05, "paint", "paint_core")
    k.prof(r, [(-0.055, 0.062), (0.18, 0.062), (0.175, 0.08), (-0.035, 0.082), (-0.055, 0.072)], 0.044, "paint")
    for f in [-0.03, -0.012, 0.006]:
        k.box(r, f, 0.081, (0.042, 0.004, 0.005), "paint")
    k.box(r, -0.062, 0.067, (0.016, 0.01, 0.01), "bright")
    # Rear sight block and tangent leaf.
    k.prof(r, [(0.18, 0.062), (0.25, 0.062), (0.25, 0.084), (0.19, 0.09)], 0.04, "paint")
    k.box(r, 0.2, 0.094, (0.02, 0.005, 0.055), "steel", 0.0, (0.06, 0, 0))
    k.box(r, 0.212, 0.09, (0.026, 0.008, 0.008), "steel")
    # Rivets, trunnion pins, the long selector lever and charging handle.
    for f in [-0.04, 0.0, 0.2, 0.23]:
        k.pin(r, f, 0.012, 0.026, 0.0035)
    k.pin(r, 0.02, 0.045, 0.026, 0.004)
    k.box(r, 0.06, 0.054, (0.003, 0.012, 0.13), "steel", 0.027, (0.05, 0, 0))
    k.box(r, 0.0, 0.044, (0.004, 0.018, 0.012), "steel", 0.028)
    k.box(r, 0.1, 0.06, (0.002, 0.008, 0.11), "rubber", 0.0255)
    charge = P["charge"]
    charge.name = "Charge"
    k.box(charge, 0.14, 0.06, (0.022, 0.009, 0.012), "bright", 0.035)
    k.box(r, 0.165, -0.006, (0.012, 0.018, 0.006), "steel")
    # Wooden stock with a steel buttplate.
    k.prof(r, [(-0.06, 0.056), (-0.06, 0.008), (-0.2, -0.028), (-0.345, -0.056), (-0.355, 0.022), (-0.2, 0.046)], 0.042, "furn", "furn_core")
    k.box(r, -0.352, -0.016, (0.044, 0.084, 0.006), "steel", 0.0, (0.2, 0, 0))
    k.wrap(r, -0.27, -0.005, (0.042, 0.05), "team", 0.014)
    # Pistol grip, trigger guard and trigger.
    k.prof(r, [(0.0, 0.004), (0.045, 0.004), (0.022, -0.1), (-0.028, -0.094)], 0.036, "furn", "furn_core")
    k.box(r, 0.075, -0.034, (0.012, 0.005, 0.07), "steel")
    k.box(r, 0.11, -0.017, (0.012, 0.034, 0.005), "steel")
    k.box(r, 0.065, -0.015, (0.005, 0.024, 0.006), "steel", 0.0, (-0.3, 0, 0))
    # Wooden lower handguard with finger grooves and retainer bands.
    k.prof(r, [(0.25, 0.008), (0.42, 0.012), (0.43, 0.025), (0.43, 0.062), (0.25, 0.064)], 0.054, "furn", "furn_core")
    for y in [0.028, 0.044]:
        for side in [-1.0, 1.0]:
            k.box(r, 0.335, y, (0.002, 0.004, 0.12), "groove", side * 0.0275)
    for f in [0.252, 0.43]:
        k.box(r, f, 0.038, (0.058, 0.064, 0.008), "steel")
    # Gas tube with the upper handguard, gas block, barrel, cleaning rod.
    k.tube(r, 0.25, 0.52, 0.084, 0.012, "paint")
    k.prof(r, [(0.27, 0.068), (0.42, 0.068), (0.41, 0.098), (0.28, 0.098)], 0.046, "furn", "furn_core")
    k.box(r, 0.52, 0.068, (0.026, 0.044, 0.026), "paint")
    k.tube(r, 0.43, 0.69, 0.05, 0.0105, "steel")
    k.tube(r, 0.43, 0.665, 0.032, 0.0035, "bright")
    # Front sight post inside its open hood, and a slant brake.
    k.prof(r, [(0.635, 0.04), (0.665, 0.04), (0.66, 0.098), (0.64, 0.098)], 0.022, "paint")
    k.box(r, 0.65, 0.104, (0.003, 0.016, 0.003), "paint")
    for side in [-1.0, 1.0]:
        k.box(r, 0.65, 0.106, (0.003, 0.02, 0.012), "paint", side * 0.009)
    k.tube(r, 0.685, 0.74, 0.05, 0.0135, "paint")
    k.box(r, 0.735, 0.062, (0.03, 0.006, 0.02), "rubber", 0.0, (0.5, 0, 0))
    # Canvas sling from the front sight base to the stock.
    k.sling(r, (-0.012, 0.03, 0.62), (-0.022, -0.03, -0.28), 0.15)
    # Steel magazine with stamped ribs.
    k.prof(mag, [(0.1, 0.0), (0.175, 0.0), (0.2, -0.1), (0.235, -0.19), (0.16, -0.215), (0.13, -0.12), (0.108, -0.045)], 0.034, "paint")
    for t in [0.3, 0.55, 0.8]:
        c = V2(0.14, -0.01).lerp(V2(0.198, -0.2), t)
        k.box(mag, c.x, c.y, (0.037, 0.004, 0.04), "paint", 0.0, (-0.4, 0, 0))
    k.box(mag, 0.198, -0.208, (0.038, 0.01, 0.07), "steel", 0.0, (-0.32, 0, 0))
    k.box(mag, 0.14, 0.002, (0.012, 0.008, 0.04), "brass")
    return


# -------------------------------------------------------------------- SMG

def smg(r, mag, k):
    # Polymer receiver with vents, ejection port and cocking slot.
    k.prof(r, [(-0.06, 0.0), (0.27, 0.0), (0.3, 0.03), (0.3, 0.085), (-0.06, 0.085)], 0.052, "paint", "paint_core")
    k.rail(r, -0.04, 0.24, 0.087, 0.026)
    k.slots(r, 0.18, 0.28, 0.04, 4, (0.018, 0.008), 0.027)
    k.box(r, 0.08, 0.062, (0.003, 0.018, 0.05), "rubber", 0.0265)
    k.box(r, 0.25, 0.068, (0.002, 0.008, 0.09), "rubber", -0.0265)
    charge = P["charge"]
    charge.name = "Charge"
    k.box(charge, 0.28, 0.068, (0.024, 0.008, 0.012), "black", -0.036, (0, 0.3, 0))
    for f in [-0.04, 0.24]:
        k.pin(r, f, 0.02, 0.027)
    # Selector with painted safe/fire dots.
    k.box(r, 0.005, 0.03, (0.003, 0.008, 0.022), "black", -0.027, (0.5, 0, 0))
    k.rivet(r, -0.01, 0.042, -0.027, 0.0025, "white")
    k.rivet(r, 0.02, 0.042, -0.027, 0.0025, "glow_red")
    # Barrel and a slotted muzzle device.
    k.tube(r, 0.3, 0.42, 0.06, 0.0105, "steel")
    k.tube(r, 0.4, 0.46, 0.06, 0.017, "black")
    for f in [0.415, 0.43, 0.445]:
        k.box(r, f, 0.06, (0.036, 0.005, 0.006), "rubber")
    # Folding wire stock with a rubber butt pad.
    k.box(r, -0.065, 0.05, (0.05, 0.03, 0.02), "black")
    for side in [-1.0, 1.0]:
        k.box(r, -0.17, 0.05, (0.008, 0.008, 0.22), "steel", side * 0.02)
    k.box(r, -0.28, 0.035, (0.05, 0.07, 0.014), "black")
    k.box(r, -0.29, 0.035, (0.05, 0.072, 0.006), "rubber")
    # Pistol grip, trigger guard, trigger.
    k.prof(r, [(0.0, 0.004), (0.045, 0.004), (0.022, -0.1), (-0.028, -0.094)], 0.036, "furn", "furn_core")
    k.box(r, 0.075, -0.032, (0.012, 0.005, 0.06), "black")
    k.box(r, 0.104, -0.016, (0.012, 0.032, 0.005), "black")
    k.box(r, 0.065, -0.014, (0.005, 0.024, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # Vertical foregrip on a short bottom rail, with team tape.
    k.rail(r, 0.22, 0.3, -0.002, 0.022)
    k.prof(r, [(0.25, -0.004), (0.29, -0.004), (0.285, -0.09), (0.255, -0.092)], 0.03, "black")
    k.wrap(r, 0.27, -0.06, (0.03, 0.032), "team", 0.014)
    # Sling.
    k.sling(r, (-0.028, 0.03, 0.2), (-0.028, 0.02, -0.27), 0.11)
    # Straight polymer magazine with ribs.
    k.prof(mag, [(0.1, 0.0), (0.15, 0.0), (0.158, -0.17), (0.104, -0.172)], 0.03, "black")
    for y in [-0.06, -0.1, -0.14]:
        k.box(mag, 0.128, y, (0.033, 0.004, 0.05), "black")
    k.box(mag, 0.131, -0.176, (0.036, 0.012, 0.06), "black")
    k.box(mag, 0.124, 0.002, (0.011, 0.008, 0.035), "brass")
    return


# ----------------------------------------------------------------- sniper

def sniper(r, mag, k):
    # Thumbhole stock with a cheek riser and a thick recoil pad.
    k.prof(r, [(-0.38, -0.05), (-0.12, -0.02), (-0.04, -0.1), (0.03, -0.1), (0.05, 0.0), (0.5, 0.0), (0.5, 0.05), (-0.1, 0.06), (-0.38, 0.07)], 0.05, "furn", "furn_core")
    k.box(r, -0.08, -0.035, (0.052, 0.028, 0.045), "rubber")
    k.prof(r, [(-0.3, 0.068), (-0.12, 0.062), (-0.12, 0.08), (-0.3, 0.086)], 0.04, "furn", "furn_core")
    k.box(r, -0.392, 0.01, (0.054, 0.124, 0.022), "rubber")
    k.wrap(r, -0.22, 0.01, (0.05, 0.08), "team", 0.014)
    # Round action, scope rail, bolt shroud.
    k.tube(r, -0.07, 0.22, 0.072, 0.022, "paint")
    k.tube(r, -0.11, -0.07, 0.072, 0.017, "paint")
    k.rail(r, -0.06, 0.2, 0.096, 0.022)
    k.box(r, 0.06, 0.08, (0.003, 0.016, 0.07), "rubber", 0.023)
    # Bolt: body, handle and a tactical knob. Pivots on the barrel axis.
    bolt = P["bolt"]
    bolt.name = "Bolt"
    k.box(bolt, -0.02, 0.0, (0.05, 0.007, 0.008), "steel", 0.042)
    k.sphere(bolt, 0.012, "black", (0.07, 0.0, 0.02), (0, 0, 0), (1, 1, 1), segs=10)
    # Heavy fluted barrel and a big ported muzzle brake.
    k.tube(r, 0.22, 0.96, 0.07, 0.015, "steel")
    for side in [-1.0, 1.0]:
        k.box(r, 0.6, 0.07, (0.002, 0.006, 0.6), "rubber", side * 0.0145)
    k.box(r, 0.6, 0.0845, (0.006, 0.002, 0.6), "rubber")
    k.box(r, 0.99, 0.07, (0.04, 0.034, 0.075), "paint")
    for f in [0.972, 0.99, 1.008]:
        k.box(r, f, 0.07, (0.042, 0.022, 0.008), "rubber")
    # Folded bipod on a rail clamp.
    k.box(r, 0.42, -0.008, (0.03, 0.016, 0.03), "black")
    for side in [-1.0, 1.0]:
        k.box(r, 0.53, -0.012, (0.008, 0.008, 0.2), "steel", side * 0.012, (0.04, 0, 0))
        k.box(r, 0.64, -0.018, (0.012, 0.012, 0.018), "rubber", side * 0.012)
    # Scope: rings, main tube, bells, turrets, eyecup, flip caps, lenses.
    for f in [0.0, 0.17]:
        k.box(r, f, 0.108, (0.034, 0.026, 0.018), "black")
        k.tube(r, f - 0.009, f + 0.009, 0.13, 0.024, "black")
    k.tube(r, -0.06, 0.24, 0.13, 0.019, "black")
    k.cone(r, -0.13, -0.06, 0.13, 0.026, 0.019, "black")
    k.tube(r, -0.15, -0.128, 0.13, 0.028, "rubber")
    k.cone(r, 0.23, 0.3, 0.13, 0.019, 0.032, "black")
    k.tube(r, 0.3, 0.345, 0.13, 0.032, "black")
    k.cylinder(r, 0.013, 0.013, 0.022, "black", (0, 0.158, -0.09), (0, 0, 0), (1, 1, 1), segs=14)
    k.cylinder(r, 0.0135, 0.0135, 0.004, "bright", (0, 0.17, -0.09), (0, 0, 0), (1, 1, 1), segs=14)
    k.rivet(r, 0.09, 0.13, 0.03, 0.012, "black")
    k.rivet(r, 0.09, 0.13, -0.03, 0.01, "black")
    k.cylinder(r, 0.033, 0.033, 0.004, "black", (0, 0.178, -0.352), (PI * 0.5 - 0.3, 0, 0), (1, 1, 1), segs=16)
    k.cylinder(r, 0.03, 0.03, 0.002, "lens", (0, 0.13, -0.343), (PI * 0.5, 0, 0), (1, 1, 1), segs=18)
    k.cylinder(r, 0.024, 0.024, 0.002, "lens", (0, 0.13, 0.148), (PI * 0.5, 0, 0), (1, 1, 1), segs=18)
    # Sling.
    k.sling(r, (-0.026, 0.0, 0.62), (-0.027, -0.04, -0.33), 0.16)
    # Detachable box magazine.
    k.prof(mag, [(0.06, 0.0), (0.14, 0.0), (0.14, -0.055), (0.06, -0.055)], 0.034, "black")
    k.box(mag, 0.1, -0.057, (0.038, 0.008, 0.086), "black")
    return


# ---------------------------------------------------------------- shotgun

def shotgun(r, pump, k):
    # Receiver with ejection and loading ports.
    k.prof(r, [(-0.05, 0.0), (0.22, 0.0), (0.22, 0.075), (-0.03, 0.075), (-0.05, 0.06)], 0.052, "paint", "paint_core")
    k.box(r, 0.1, 0.05, (0.003, 0.026, 0.08), "rubber", 0.027)
    k.box(r, 0.13, 0.0, (0.03, 0.004, 0.08), "rubber")
    k.pin(r, 0.0, 0.012, 0.027)
    k.pin(r, 0.17, 0.012, 0.027)
    k.rivet(r, 0.04, 0.0, 0.027, 0.004, "black")
    # Wooden stock and grip, rubber recoil pad.
    k.prof(r, [(-0.05, 0.07), (-0.05, 0.005), (-0.18, -0.03), (-0.36, -0.06), (-0.37, 0.04), (-0.18, 0.06)], 0.046, "furn", "furn_core")
    k.box(r, -0.375, -0.01, (0.048, 0.104, 0.018), "rubber", 0.0, (0.2, 0, 0))
    k.prof(r, [(0.0, 0.004), (0.045, 0.004), (0.022, -0.1), (-0.028, -0.094)], 0.036, "furn", "furn_core")
    k.wrap(r, -0.25, 0.0, (0.046, 0.08), "team", 0.014)
    # Trigger plate, guard, trigger.
    k.box(r, 0.07, -0.006, (0.03, 0.016, 0.1), "paint")
    k.box(r, 0.075, -0.032, (0.012, 0.005, 0.06), "paint")
    k.box(r, 0.104, -0.018, (0.012, 0.03, 0.005), "paint")
    k.box(r, 0.065, -0.016, (0.005, 0.024, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # Barrel, magazine tube with its cap, barrel clamp, brass bead.
    k.tube(r, 0.22, 0.8, 0.068, 0.016, "steel")
    k.tube(r, 0.22, 0.7, 0.03, 0.014, "paint")
    k.tube(r, 0.69, 0.725, 0.03, 0.0155, "steel")
    k.box(r, 0.7, 0.05, (0.012, 0.05, 0.016), "paint")
    k.sphere(r, 0.005, "brass", (0, 0.088, -0.78), (0, 0, 0), (1, 1, 1), segs=8)
    # Side-saddle shell carrier with red shells and brass heads.
    k.box(r, 0.1, 0.04, (0.008, 0.056, 0.12), "black", -0.03)
    hull = "hull"
    for i in range(4):
        f = 0.06 + i * 0.026
        k.cylinder(r, 0.0095, 0.0095, 0.046, hull, (-0.042, 0.044, -f), (0, 0, 0), (1, 1, 1), segs=10)
        k.cylinder(r, 0.0102, 0.0102, 0.012, "brass", (-0.042, 0.016, -f), (0, 0, 0), (1, 1, 1), segs=10)
    # Sling.
    k.sling(r, (-0.016, 0.02, 0.71), (-0.024, -0.03, -0.3), 0.14)
    # Wooden pump with grooves, riding on two steel action bars.
    k.prof(pump, [(0.32, 0.008), (0.5, 0.008), (0.5, 0.056), (0.32, 0.056)], 0.052, "furn", "furn_core")
    for y in [0.02, 0.032, 0.044]:
        for side in [-1.0, 1.0]:
            k.box(pump, 0.41, y, (0.002, 0.004, 0.16), "groove", side * 0.0265)
    for side in [-1.0, 1.0]:
        k.box(pump, 0.27, 0.03, (0.003, 0.006, 0.1), "steel", side * 0.017)
    return


# ----------------------------------------------------------------- pistol

def pistol(r, mag, k):
    # Slide (recoils on every shot, locks back when empty).
    slide = P["slide"]
    slide.name = "Slide"
    k.prof(slide, [(-0.04, 0.045), (0.19, 0.045), (0.19, 0.078), (0.185, 0.083), (-0.03, 0.083), (-0.04, 0.073)], 0.03, "paint", "paint_core")
    for i in range(6):
        k.box(slide, -0.028 + i * 0.007, 0.064, (0.032, 0.03, 0.002), "rubber")
    k.box(slide, 0.13, 0.083, (0.016, 0.004, 0.08), "steel")
    k.box(slide, 0.07, 0.08, (0.012, 0.006, 0.035), "rubber", 0.006)
    for side in [-1.0, 1.0]:
        k.box(slide, -0.02, 0.07, (0.004, 0.008, 0.016), "black", side * 0.017)
    # Three-dot sights.
    k.box(slide, 0.175, 0.088, (0.005, 0.01, 0.008), "black")
    k.rivet(slide, 0.171, 0.09, 0.0, 0.0018, "white")
    k.box(slide, -0.025, 0.089, (0.022, 0.01, 0.008), "black")
    for side in [-1.0, 1.0]:
        k.cylinder(slide, 0.0018, 0.0018, 0.002, "white", (side * 0.006, 0.09, 0.021), (PI * 0.5, 0, 0), (1, 1, 1), segs=8)
    # Barrel crown at the front of the slide.
    k.tube(r, 0.17, 0.192, 0.068, 0.006, "steel")
    # Frame, dust cover, grip panels with screws, slide stop.
    k.prof(r, [(-0.03, 0.0), (0.17, 0.0), (0.17, 0.045), (-0.03, 0.045)], 0.028, "black")
    k.prof(r, [(-0.03, 0.004), (0.03, 0.004), (0.008, -0.1), (-0.045, -0.094)], 0.032, "black")
    for side in [-1.0, 1.0]:
        k.prof(r, [(-0.024, -0.01), (0.022, -0.01), (0.005, -0.085), (-0.038, -0.08)], 0.004, "furn", None, side * 0.017)
        k.rivet(r, -0.005, -0.02, side * 0.02, 0.003, "pin")
        k.rivet(r, -0.02, -0.075, side * 0.02, 0.003, "pin")
    k.box(r, 0.06, 0.042, (0.003, 0.006, 0.04), "black", -0.0155)
    k.pin(r, 0.12, 0.03, 0.015, 0.003)
    # Trigger guard, trigger, hammer.
    k.box(r, 0.055, -0.026, (0.01, 0.005, 0.065), "black")
    k.box(r, 0.087, -0.012, (0.01, 0.03, 0.006), "black", 0.0, (0.25, 0, 0))
    k.box(r, 0.04, -0.008, (0.005, 0.022, 0.006), "bright", 0.0, (-0.3, 0, 0))
    k.box(r, -0.046, 0.075, (0.01, 0.02, 0.012), "black", 0.0, (0.4, 0, 0))
    # Magazine: the body hides in the grip until a reload pulls it out.
    k.prof(mag, [(-0.032, 0.0), (0.004, 0.0), (-0.016, -0.096), (-0.044, -0.092)], 0.022, "paint")
    k.box(mag, -0.014, -0.002, (0.009, 0.008, 0.024), "brass")
    k.box(mag, -0.02, -0.1, (0.03, 0.012, 0.05), "black", 0.0, (-0.22, 0, 0))
    return


# ------------------------------------------------------------------- M249

def lmg(r, mag, k):
    # Receiver, hinged feed cover with its rail, and the charging handle.
    k.prof(r, [(-0.08, 0.0), (0.24, 0.0), (0.24, 0.1), (-0.06, 0.1), (-0.08, 0.085)], 0.056, "paint", "paint_core")
    k.prof(r, [(-0.02, 0.1), (0.2, 0.1), (0.19, 0.118), (-0.01, 0.118)], 0.05, "paint")
    k.rail(r, 0.0, 0.19, 0.122, 0.024)
    k.box(r, 0.2, 0.108, (0.056, 0.012, 0.012), "black")
    charge = P["charge"]
    charge.name = "Charge"
    k.box(charge, 0.12, 0.06, (0.024, 0.012, 0.014), "black", 0.038)
    k.box(r, 0.1, 0.06, (0.002, 0.01, 0.12), "rubber", 0.0285)
    for f in [-0.05, 0.05, 0.2]:
        k.pin(r, f, 0.025, 0.029)
    # Skeleton stock with a rubber pad.
    k.prof(r, [(-0.08, 0.09), (-0.08, 0.02), (-0.38, 0.0), (-0.4, 0.09), (-0.38, 0.11)], 0.046, "furn", "furn_core")
    k.box(r, -0.405, 0.055, (0.048, 0.11, 0.014), "rubber")
    k.wrap(r, -0.25, 0.06, (0.046, 0.06), "team", 0.014)
    # Grip and trigger guard.
    k.prof(r, [(-0.005, 0.004), (0.045, 0.004), (0.02, -0.105), (-0.032, -0.098)], 0.036, "furn", "furn_core")
    k.box(r, 0.075, -0.032, (0.012, 0.005, 0.06), "black")
    k.box(r, 0.103, -0.016, (0.012, 0.032, 0.005), "black")
    k.box(r, 0.065, -0.014, (0.005, 0.024, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # Handguard, barrel with carry handle, gas tube, flash hider, bipod.
    k.prof(r, [(0.24, 0.022), (0.42, 0.026), (0.42, 0.085), (0.24, 0.09)], 0.06, "furn", "furn_core")
    k.slots(r, 0.26, 0.4, 0.055, 4, (0.024, 0.01), 0.031)
    k.tube(r, 0.42, 0.79, 0.06, 0.012, "steel")
    k.tube(r, 0.42, 0.66, 0.036, 0.009, "paint")
    k.tube(r, 0.77, 0.83, 0.06, 0.016, "black")
    k.box(r, 0.55, 0.1, (0.014, 0.014, 0.13), "black")
    for f in [0.5, 0.6]:
        k.box(r, f, 0.083, (0.012, 0.035, 0.012), "black")
    for side in [-1.0, 1.0]:
        k.box(r, 0.6, 0.03, (0.008, 0.008, 0.22), "steel", side * 0.012, (-0.04, 0, 0))
    k.sling(r, (-0.03, 0.03, 0.4), (-0.026, 0.0, -0.36), 0.15)
    # Soft olive ammo pouch on the left, with a brass belt running in.
    k.prof(mag, [(0.03, -0.0), (0.17, -0.0), (0.175, -0.15), (0.025, -0.155)], 0.085, "web", None, -0.02)
    k.box(mag, 0.1, -0.075, (0.088, 0.03, 0.15), "web", -0.02)
    for i in range(5):
        k.box(mag, 0.07 + i * 0.022, 0.012, (0.02, 0.01, 0.012), "brass", -0.03 + i * 0.002)
    # Front post on the barrel; rear aperture on the feed-cover rail.
    return


# ---------------------------------------------------------------- Mk 14

def dmr(r, mag, k):
    # Aluminium chassis with a long top rail and slotted handguard.
    k.prof(r, [(-0.07, 0.0), (0.3, 0.0), (0.3, 0.09), (-0.05, 0.09), (-0.07, 0.075)], 0.052, "paint", "paint_core")
    k.prof(r, [(0.3, 0.02), (0.5, 0.02), (0.5, 0.09), (0.3, 0.09)], 0.058, "paint", "paint_core")
    k.rail(r, -0.05, 0.49, 0.094, 0.024)
    k.slots(r, 0.32, 0.48, 0.055, 5, (0.022, 0.01), 0.03)
    for side in [-1.0, 1.0]:
        k.rail(r, 0.34, 0.47, 0.055, 0.02, side * 0.03, False)
    k.box(r, 0.1, 0.06, (0.003, 0.018, 0.06), "rubber", 0.0265)
    charge = P["charge"]
    charge.name = "Charge"
    k.box(charge, 0.22, 0.05, (0.02, 0.012, 0.014), "steel", 0.034)
    for f in [-0.04, 0.2]:
        k.pin(r, f, 0.025, 0.027)
    # Adjustable stock with a cheek riser.
    k.tube(r, -0.33, -0.07, 0.065, 0.016, "black")
    k.prof(r, [(-0.14, 0.1), (-0.14, 0.03), (-0.33, 0.004), (-0.345, 0.055), (-0.335, 0.098), (-0.2, 0.104)], 0.044, "furn", "furn_core")
    k.box(r, -0.35, 0.056, (0.046, 0.1, 0.014), "rubber")
    k.wrap(r, -0.25, 0.06, (0.044, 0.06), "team", 0.014)
    k.prof(r, [(-0.005, 0.004), (0.045, 0.004), (0.02, -0.105), (-0.032, -0.098)], 0.036, "furn", "furn_core")
    k.box(r, 0.075, -0.032, (0.012, 0.005, 0.06), "black")
    k.box(r, 0.103, -0.016, (0.012, 0.032, 0.005), "black")
    k.box(r, 0.065, -0.014, (0.005, 0.024, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # Barrel and a ported muzzle brake.
    k.tube(r, 0.5, 0.86, 0.055, 0.011, "steel")
    k.tube(r, 0.84, 0.91, 0.055, 0.016, "black")
    for f in [0.86, 0.88]:
        k.box(r, f, 0.055, (0.034, 0.008, 0.006), "rubber")
    k.sling(r, (-0.03, 0.03, 0.46), (-0.024, 0.0, -0.32), 0.14)
    # Straight 20-round magazine.
    k.prof(mag, [(0.08, 0.0), (0.15, 0.0), (0.158, -0.13), (0.088, -0.135)], 0.03, "black")
    for y in [-0.05, -0.09]:
        k.box(mag, 0.12, y, (0.033, 0.004, 0.055), "black")
    k.box(mag, 0.123, -0.137, (0.036, 0.012, 0.075), "black")
    return


# ------------------------------------------------------------------- .44

def revolver(r, mag, k):
    # Frame, top strap and rear notch, barrel with full underlug and vent
    # rib, front blade, wood grips, hammer, trigger and guard.
    k.prof(r, [(-0.03, 0.035), (0.085, 0.035), (0.085, 0.088), (-0.02, 0.09), (-0.045, 0.07)], 0.03, "paint", "paint_core")
    k.prof(r, [(0.085, 0.042), (0.255, 0.046), (0.255, 0.086), (0.085, 0.088)], 0.022, "paint", "paint_core")
    k.box(r, 0.17, 0.09, (0.01, 0.006, 0.17), "steel")
    k.box(r, 0.245, 0.097, (0.004, 0.014, 0.012), "black")
    k.box(r, -0.015, 0.092, (0.016, 0.006, 0.01), "black")
    k.tube(r, 0.25, 0.258, 0.068, 0.007, "rubber")
    k.prof(r, [(-0.03, 0.04), (0.012, 0.04), (-0.004, -0.065), (-0.056, -0.062), (-0.052, 0.0)], 0.032, "furn", "furn_core")
    k.rivet(r, -0.02, -0.01, 0.017, 0.003, "pin")
    k.box(r, -0.04, 0.088, (0.008, 0.018, 0.014), "black", 0.0, (0.6, 0, 0))
    k.box(r, 0.04, -0.012, (0.01, 0.005, 0.05), "paint")
    k.box(r, 0.064, 0.005, (0.01, 0.034, 0.006), "paint", 0.0, (0.3, 0, 0))
    k.box(r, 0.03, 0.01, (0.005, 0.026, 0.006), "bright", 0.0, (-0.3, 0, 0))
    # The cylinder (it swings out on reloads) with flutes and brass rims.
    k.cylinder(mag, 0.031, 0.031, 0.066, "paint", (0, 0.062, -0.048), (PI * 0.5, 0, 0), (1, 1, 1), segs=18)
    for i in range(6):
        a = TAU * i / 6.0
        k.box(mag, 0.048, 0.062 + math.sin(a) * 0.03, (0.006, 0.006, 0.05), "rubber", math.cos(a) * 0.03)
        k.cylinder(mag, 0.008, 0.008, 0.004, "brass", (math.cos(a + 0.5) * 0.019, 0.062 + math.sin(a + 0.5) * 0.019, -0.014), (PI * 0.5, 0, 0), (1, 1, 1), segs=10)
    return


