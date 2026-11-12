"""Vehicles, the attack helicopter and the attack dog -> vehicles.glb.

Authored in Blender space (+X right, +Y forward, +Z up) with the origin on
the ground under the vehicle's centre; glTF turns +Y into Godot's -Z, so
every vehicle faces Godot's -Z like the old procedural ones. Moving parts
(rotors, chin gun, dog head, legs and tail) are separate objects built
around their own pivot.

Objects:
    truck_cab, truck_box, truck_tank      airport service truck
    suv                                   road car
    tug, gpu_cart, belt_loader            ramp equipment
    quad                                  quad bike
    heli_body, heli_rotor, heli_tail_rotor, heli_gun
    dog_body, dog_head, dog_leg_front, dog_leg_back, dog_tail
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkit  # noqa: E402
from bkit import box, cyl, sphere, torus, lathe, loft, carve, prism, tube_path  # noqa: E402
from mathutils import Matrix  # noqa: E402


def arch(cy, cz, r, bottom, n=10):
    """A wheel arch cut up into a body's bottom edge at z = bottom: the
    points of the circle (cy, cz, r) above that line, rear to front."""
    a0 = math.degrees(math.asin(max(-1.0, min(1.0, (bottom - cz) / r))))
    return arc(cy, cz, r, 180 - a0, a0, n)


def arc(cy, cz, r, a0, a1, n):
    """Points (y, z) on an arc, angles in degrees."""
    out = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        out.append((cy + r * math.cos(a), cz + r * math.sin(a)))
    return out


# ----------------------------------------------------------------- wheels

def make_wheel(r, w, knobby=False, spokes=6):
    """A tyre and rim around the local +Z axle, outer face toward +Z."""
    m = bkit.Model("_wheel")
    ri = r * 0.6
    lathe(m, "tyre", [
        (ri * 1.02, -w * 0.42), (r * 0.84, -w * 0.5), (r * 0.96, -w * 0.47), (r, -w * 0.36),
        (r, w * 0.36), (r * 0.96, w * 0.47), (r * 0.84, w * 0.5), (ri * 1.02, w * 0.42),
    ], segs=32)
    # Tread blocks in two staggered rows.
    n = 14 if knobby else 22
    for i in range(n):
        for row, off in ((-1, 0.0), (1, 0.5)):
            a = 2 * math.pi * (i + off) / n
            bw = w * (0.3 if knobby else 0.34)
            bh = r * (0.075 if knobby else 0.04)
            bl = r * (0.2 if knobby else 0.12)
            rr = r + bh * 0.35
            box(m, "tyre", (bl, bh, bw), loc=(rr * math.cos(a), rr * math.sin(a), row * w * 0.2),
                rot=(0, 0, math.degrees(a) + 90), bevel=0.0)
    # Dished rim, hub cap and lug nuts.
    lathe(m, "rim", [
        (0.0005, -w * 0.4), (ri * 1.02, -w * 0.4), (ri * 1.02, w * 0.32), (ri * 0.9, w * 0.36),
        (ri * 0.82, w * 0.22), (ri * 0.42, w * 0.2), (ri * 0.36, w * 0.3), (ri * 0.2, w * 0.33), (0.0005, w * 0.34),
    ], segs=28)
    for i in range(spokes):
        a = 2 * math.pi * (i + 0.5) / spokes
        box(m, "black", (ri * 0.26, ri * 0.32, w * 0.02), loc=(ri * 0.6 * math.cos(a), ri * 0.6 * math.sin(a), w * 0.205),
            rot=(0, 0, math.degrees(a)), bevel=0.004, segments=1)
    for i in range(5):
        a = 2 * math.pi * i / 5
        cyl(m, "rim", ri * 0.05, w * 0.06, loc=(ri * 0.28 * math.cos(a), ri * 0.28 * math.sin(a), w * 0.33), segs=6)
    return m


def put_wheel(model, wheel, x, y, z):
    """Axle along X, outer face pointing away from the centre line."""
    rot = Matrix.Rotation(math.radians(90 if x >= 0 else -90), 4, "Y")
    model.merge(wheel, Matrix.Translation((x, y, z)) @ rot)


def lamp(model, slot, size, loc, bezel="trim"):
    box(model, bezel, (size[0] + 0.04, size[1], size[2] + 0.04), loc=(loc[0], loc[1] - 0.01, loc[2]), bevel=0.012)
    box(model, slot, size, loc=loc, bevel=min(size[0], size[2]) * 0.25)


def seat(model, x, y, z, w=0.5):
    box(model, "interior", (w, 0.5, 0.14), loc=(x, y, z), bevel=0.04, segments=3)
    box(model, "interior", (w, 0.14, 0.62), loc=(x, y - 0.24, z + 0.32), rot=(-12, 0, 0), bevel=0.04, segments=3)
    box(model, "interior", (w * 0.55, 0.12, 0.16), loc=(x, y - 0.3, z + 0.72), rot=(-12, 0, 0), bevel=0.04, segments=3)


def steering(model, x, y, z, r=0.19, tilt=-60):
    torus(model, "black", r, 0.02, loc=(x, y, z), rot=(tilt, 0, 0), segs=24, minor_segs=8)
    cyl(model, "black", 0.03, 0.4, loc=(x, y + 0.15, z - 0.1), rot=(tilt + 90, 0, 0), segs=8)


# ------------------------------------------------------------------ truck

def truck_cab():
    m = bkit.Model("truck_cab")
    # Ladder chassis.
    for sx in (-0.45, 0.45):
        box(m, "black", (0.14, 6.1, 0.24), loc=(sx, -0.05, 0.62), bevel=0.01)
    for y in (-2.8, -1.0, 0.8, 2.6):
        box(m, "black", (0.9, 0.12, 0.14), loc=(0, y, 0.62), bevel=0.01)
    # Cab-over cab: side profile with a wheel arch, rounded front corners,
    # and tucked-in upper sides.
    side = [(1.42, 0.62)] + arch(2.2, 0.5, 0.66, 0.62) + [
        (3.22, 0.62), (3.28, 0.9), (3.26, 1.55), (3.12, 2.18), (2.95, 2.3), (1.42, 2.3)]
    plan = [(-1.15, 1.42), (1.15, 1.42), (1.15, 2.95), (1.0, 3.3), (-1.0, 3.3), (-1.15, 2.95)]
    front = [(-1.15, 0.5), (1.15, 0.5), (1.15, 2.05), (1.06, 2.32), (-1.06, 2.32), (-1.15, 2.05)]
    carve(m, "paint", side=side, plan=plan, front=front, bevel=0.05)
    # Windscreen in a rubber surround, leaning back with the cab face.
    box(m, "trim", (1.98, 0.03, 0.62), loc=(0, 3.185, 1.86), rot=(13, 0, 0), bevel=0.02)
    box(m, "glass", (1.86, 0.03, 0.52), loc=(0, 3.2, 1.86), rot=(13, 0, 0), bevel=0.02)
    box(m, "trim", (0.06, 0.04, 0.6), loc=(0, 3.21, 1.86), rot=(13, 0, 0), bevel=0.01)
    for sx in (-1, 1):
        box(m, "black", (0.018, 0.02, 0.48), loc=(sx * 0.45, 3.235, 1.78), rot=(13, 0, sx * 20))
    for sx in (-1, 1):
        x = sx * 1.16
        # Side window, door seams, handle, step and grab handle.
        box(m, "trim", (0.02, 1.0, 0.56), loc=(x, 2.45, 1.8), bevel=0.015)
        box(m, "glass", (0.025, 0.92, 0.48), loc=(x, 2.45, 1.8), bevel=0.015)
        box(m, "black", (0.02, 0.012, 1.5), loc=(x, 1.95, 1.38))
        box(m, "black", (0.02, 0.012, 0.75), loc=(x, 3.0, 1.75))
        box(m, "black", (0.02, 1.05, 0.012), loc=(x, 2.48, 2.12))
        box(m, "steel", (0.03, 0.18, 0.035), loc=(x + sx * 0.01, 2.05, 1.42), bevel=0.01)
        box(m, "steel", (0.3, 0.42, 0.04), loc=(sx * 1.0, 2.0, 0.42), bevel=0.01)
        tube_path(m, "steel", [(x + sx * 0.04, 1.6, 1.0), (x + sx * 0.06, 1.6, 1.15), (x + sx * 0.06, 1.6, 1.85), (x + sx * 0.04, 1.6, 2.0)], 0.018, segs=8)
        # Mirror on a tube arm.
        tube_path(m, "black", [(x, 3.05, 1.7), (sx * 1.38, 3.12, 1.75), (sx * 1.42, 3.1, 1.95)], 0.018, segs=8)
        box(m, "black", (0.08, 0.16, 0.34), loc=(sx * 1.44, 3.08, 1.92), bevel=0.02)
        box(m, "glass", (0.06, 0.02, 0.28), loc=(sx * 1.44, 3.0, 1.92), bevel=0.01)
        # Headlight, indicator, reflective stripe and front fender lip.
        lamp(m, "lamp", (0.36, 0.05, 0.2), (sx * 0.78, 3.28, 0.98))
        lamp(m, "amber", (0.14, 0.05, 0.1), (sx * 1.05, 3.26, 0.98))
        box(m, "stripe", (0.012, 1.7, 0.1), loc=(x + sx * 0.002, 2.32, 0.9))
        tube_path(m, "black", [(x - sx * 0.12, 1.5, 0.62)] + [(x - sx * 0.12, 2.2 + 0.72 * math.cos(math.radians(a)), 0.5 + 0.72 * math.sin(math.radians(a))) for a in (150, 120, 90, 60, 30)], 0.03, segs=8)
    # Grille, bumper, plate and tow eye.
    box(m, "trim", (1.0, 0.04, 0.42), loc=(0, 3.28, 1.0), bevel=0.015)
    for k in range(5):
        box(m, "steel", (0.92, 0.03, 0.025), loc=(0, 3.3, 0.84 + k * 0.08), bevel=0.005)
    box(m, "black", (2.36, 0.22, 0.24), loc=(0, 3.32, 0.6), bevel=0.04, segments=3)
    box(m, "plate", (0.52, 0.02, 0.13), loc=(0, 3.44, 0.6), bevel=0.008)
    torus(m, "steel", 0.05, 0.015, loc=(0.7, 3.45, 0.55), rot=(0, 90, 0))
    # Roof beacon and marker lights, cab interior.
    lathe(m, "black", [(0.14, 0.0), (0.14, 0.05), (0.0005, 0.05)], loc=(0, 2.4, 2.3), segs=16)
    lathe(m, "amber", [(0.11, 0.0), (0.11, 0.08), (0.08, 0.15), (0.0005, 0.17)], loc=(0, 2.4, 2.35), segs=16)
    for x in (-0.6, -0.3, 0.3, 0.6):
        box(m, "amber", (0.1, 0.05, 0.05), loc=(x, 3.0, 2.31), bevel=0.012)
    box(m, "interior", (2.1, 0.4, 0.3), loc=(0, 2.95, 1.42), bevel=0.04)
    seat(m, -0.5, 2.0, 1.15)
    seat(m, 0.5, 2.0, 1.15)
    steering(m, -0.5, 2.6, 1.6)
    # Fuel tank, air tanks, exhaust stack.
    loft(m, "steel", [(0.6, -0.86, 0.75, 0.0005, 0.0005), (0.62, -0.86, 0.75, 0.2, 0.2), (1.3, -0.86, 0.75, 0.2, 0.2), (1.32, -0.86, 0.75, 0.0005, 0.0005)], segs=16)
    for y in (0.75, 1.15):
        box(m, "black", (0.43, 0.04, 0.43), loc=(-0.86, y, 0.75))
    cyl(m, "black", 0.13, 0.7, loc=(0.82, 1.0, 0.75), rot=(90, 0, 0), segs=14)
    tube_path(m, "black", [(1.0, 1.3, 0.7), (1.1, 1.38, 0.9), (1.1, 1.38, 2.5)], 0.06, segs=12)
    # Wheels: singles at the front, duals at the back.
    w = make_wheel(0.5, 0.34)
    for sx in (-1, 1):
        put_wheel(m, w, sx * 1.02, 2.2, 0.5)
        put_wheel(m, w, sx * 1.06, -1.8, 0.5)
        put_wheel(m, w, sx * 0.72, -1.8, 0.5)
        box(m, "rubber", (0.42, 0.02, 0.4), loc=(sx * 0.9, -2.45, 0.4), bevel=0.01)
        box(m, "black", (0.6, 0.04, 0.05), loc=(sx * 0.9, -2.45, 0.62))
    box(m, "black", (0.9, 0.1, 0.1), loc=(0, -1.8, 0.5))
    return m.finish(smooth_angle=35.0)


def truck_box():
    m = bkit.Model("truck_box")
    y0, y1, z0, z1, hw = -3.12, 1.25, 0.78, 2.4, 1.2
    yc, zc = (y0 + y1) * 0.5, (z0 + z1) * 0.5
    box(m, "paint", (hw * 2, y1 - y0, z1 - z0), loc=(0, yc, zc), bevel=0.03)
    # Corner posts, top and bottom rails, vertical ribs.
    for sx in (-1, 1):
        for y in (y0, y1):
            box(m, "steel", (0.08, 0.08, z1 - z0 + 0.02), loc=(sx * hw, y, zc), bevel=0.01)
        for z in (z0, z1):
            box(m, "steel", (0.07, y1 - y0, 0.08), loc=(sx * hw, yc, z), bevel=0.01)
        y = y0 + 0.55
        while y < y1 - 0.3:
            box(m, "paint", (0.04, 0.05, z1 - z0 - 0.1), loc=(sx * (hw + 0.012), y, zc), bevel=0.008)
            y += 0.55
        box(m, "stripe", (0.012, y1 - y0 - 0.2, 0.1), loc=(sx * (hw + 0.035), yc, z0 + 0.22))
        for y in (y0 + 0.4, yc, y1 - 0.4):
            box(m, "amber", (0.03, 0.08, 0.05), loc=(sx * (hw + 0.03), y, z1 - 0.12), bevel=0.01)
        box(m, "tail", (0.24, 0.05, 0.16), loc=(sx * 0.9, y0 - 0.03, z0 + 0.12), bevel=0.02)
        box(m, "black", (0.08, 0.06, 1.3), loc=(sx * 1.0, y0 - 0.04, zc), bevel=0.01)
        for k in range(3):
            box(m, "steel", (0.1, 0.06, 0.12), loc=(sx * 1.08, y0 - 0.05, z0 + 0.3 + k * 0.55), bevel=0.01)
    for z in (z0, z1):
        box(m, "steel", (hw * 2, 0.08, 0.08), loc=(0, y1, z), bevel=0.01)
    # Roll-up rear door with slats and a pull strap.
    box(m, "paint", (hw * 2 - 0.2, 0.03, z1 - z0 - 0.15), loc=(0, y0 - 0.02, zc), bevel=0.01)
    for k in range(9):
        box(m, "trim", (hw * 2 - 0.22, 0.01, 0.012), loc=(0, y0 - 0.04, z0 + 0.15 + k * 0.16))
    box(m, "steel", (0.4, 0.04, 0.04), loc=(0, y0 - 0.05, z0 + 0.15), bevel=0.01)
    box(m, "black", (0.05, 0.02, 0.4), loc=(0, y0 - 0.05, z0 + 0.1))
    # Under-ride bar and a little step.
    box(m, "black", (2.0, 0.1, 0.12), loc=(0, y0 - 0.06, 0.5), bevel=0.02)
    for sx in (-0.7, 0.7):
        box(m, "black", (0.08, 0.08, 0.3), loc=(sx, y0 + 0.02, 0.64))
    box(m, "plate", (0.52, 0.02, 0.13), loc=(0, y0 - 0.12, 0.5), bevel=0.008)
    return m.finish(smooth_angle=35.0)


def truck_tank():
    m = bkit.Model("truck_tank")
    zc = 1.62
    secs = []
    for y, s in ((-3.08, 0.0), (-3.06, 0.6), (-3.0, 0.88), (-2.9, 0.98), (-2.75, 1.0), (1.0, 1.0), (1.15, 0.98), (1.25, 0.88), (1.31, 0.6), (1.33, 0.0)):
        secs.append((y, 0, zc, max(1.0 * s, 0.0005), max(0.9 * s, 0.0005), 2.3))
    loft(m, "tank", secs, segs=36)
    for y in (-2.0, -0.9, 0.2):
        loft(m, "steel", [(y - 0.04, 0, zc, 1.005, 0.905, 2.3), (y - 0.03, 0, zc, 1.02, 0.92, 2.3), (y + 0.03, 0, zc, 1.02, 0.92, 2.3), (y + 0.04, 0, zc, 1.005, 0.905, 2.3)], segs=36)
    # Cradle and side valances in the truck colour.
    for y in (-2.4, -0.4, 0.8):
        prism(m, "paint", [(-0.9, 0.74), (0.9, 0.74), (0.86, 1.05), (-0.86, 1.05)], "y", y - 0.08, y + 0.08, bevel=0.01)
    for sx in (-1, 1):
        box(m, "paint", (0.05, 4.1, 0.34), loc=(sx * 0.98, -0.85, 0.92), bevel=0.015)
        box(m, "stripe", (0.012, 3.9, 0.08), loc=(sx * 1.01, -0.85, 0.92))
        box(m, "tail", (0.22, 0.05, 0.14), loc=(sx * 0.85, -3.08, 0.92), bevel=0.02)
    # Catwalk, hand rails, hatches and the vent.
    box(m, "steel", (0.6, 3.6, 0.04), loc=(0, -0.85, zc + 0.93), bevel=0.008)
    for x in (-0.25, 0.0, 0.25):
        box(m, "black", (0.01, 3.55, 0.012), loc=(x, -0.85, zc + 0.955))
    for sx in (-1, 1):
        tube_path(m, "steel", [(sx * 0.32, -2.6, zc + 0.95), (sx * 0.32, -2.6, zc + 1.35), (sx * 0.32, 0.9, zc + 1.35), (sx * 0.32, 0.9, zc + 0.95)], 0.018, segs=8)
        for y in (-1.45, -0.25):
            tube_path(m, "steel", [(sx * 0.32, y, zc + 0.95), (sx * 0.32, y, zc + 1.35)], 0.015, segs=8)
    for y in (-1.8, 0.1):
        lathe(m, "steel", [(0.26, -0.02), (0.26, 0.06), (0.22, 0.1), (0.0005, 0.12)], loc=(0, y, zc + 0.95), segs=20)
        box(m, "black", (0.08, 0.2, 0.04), loc=(0.12, y, zc + 1.07), bevel=0.01)
    cyl(m, "steel", 0.05, 0.25, loc=(0, -2.4, zc + 1.06), segs=10)
    # Rear ladder, hose cabinet and the delivery hose reel.
    for sx in (-0.2, 0.2):
        tube_path(m, "steel", [(sx, -3.1, 0.7), (sx, -3.15, 2.0), (sx, -2.95, 2.55)], 0.018, segs=8)
    for k in range(6):
        cyl(m, "steel", 0.014, 0.4, loc=(0, -3.11 - 0.008 * k, 0.85 + k * 0.22), rot=(0, 90, 0), segs=6)
    box(m, "paint", (0.9, 0.5, 0.6), loc=(0.55, -2.9, 0.98), bevel=0.02)
    cyl(m, "black", 0.22, 0.3, loc=(0.55, -3.05, 1.0), rot=(0, 90, 0), segs=18)
    torus(m, "rubber", 0.18, 0.04, loc=(0.55, -3.05, 1.0), rot=(0, 90, 0), segs=24)
    box(m, "black", (2.0, 0.1, 0.12), loc=(0, -3.15, 0.5), bevel=0.02)
    box(m, "plate", (0.52, 0.02, 0.13), loc=(0, -3.21, 0.5), bevel=0.008)
    # Hazard diamond placards.
    for sx in (-1, 1):
        box(m, "placard", (0.012, 0.32, 0.32), loc=(sx * 1.0, -2.2, zc), rot=(45, 0, 0), bevel=0.004)
    box(m, "placard", (0.32, 0.012, 0.32), loc=(0, -3.08, zc), rot=(0, 45, 0), bevel=0.004)
    return m.finish(smooth_angle=35.0)


# -------------------------------------------------------------------- suv

def suv():
    m = bkit.Model("suv")
    bottom = 0.42
    side = [(-2.3, bottom)] + arch(-1.5, 0.42, 0.52, bottom, 12) + arch(1.5, 0.42, 0.52, bottom, 12) + [
        (2.28, bottom), (2.36, 0.7), (2.33, 0.98), (2.15, 1.12), (1.05, 1.2), (-2.2, 1.2), (-2.33, 1.05), (-2.34, 0.7)]
    plan = [(-0.95, -2.26), (-0.86, -2.36), (0.86, -2.36), (0.95, -2.26), (0.98, 1.9), (0.88, 2.37), (-0.88, 2.37), (-0.98, 1.9)]
    front = [(-0.98, 0.3), (0.98, 0.3), (0.99, 0.8), (0.95, 1.25), (-0.95, 1.25), (-0.99, 0.8)]
    carve(m, "paint", side=side, plan=plan, front=front, bevel=0.06, segments=3)
    # Greenhouse of glass, roof, and pillars.
    gside = [(1.08, 1.16), (0.48, 1.84), (-1.86, 1.84), (-2.16, 1.16)]
    gfront = [(-0.93, 1.1), (0.93, 1.1), (0.79, 1.86), (-0.79, 1.86)]
    carve(m, "glass", side=gside, plan=plan, front=gfront, bevel=0.03, segments=2)
    rside = [(0.56, 1.8), (0.42, 1.93), (-1.84, 1.93), (-1.94, 1.8)]
    rfront = [(-0.82, 1.78), (0.82, 1.78), (0.78, 1.94), (-0.78, 1.94)]
    carve(m, "paint", side=rside, plan=plan, front=rfront, bevel=0.03, segments=3)
    for sx in (-1, 1):
        tube_path(m, "paint", [(sx * 0.9, 1.06, 1.2), (sx * 0.78, 0.5, 1.84)], 0.045, segs=8)
        tube_path(m, "black", [(sx * 0.93, -0.28, 1.2), (sx * 0.8, -0.28, 1.84)], 0.04, segs=8)
        tube_path(m, "black", [(sx * 0.93, -1.3, 1.2), (sx * 0.8, -1.3, 1.84)], 0.035, segs=8)
        prism(m, "paint", [(-2.18, 1.18), (-1.86, 1.18), (-1.66, 1.86), (-1.9, 1.86)], "x", min(sx * 0.78, sx * 0.94), max(sx * 0.78, sx * 0.94), bevel=0.015)
        box(m, "black", (0.025, 3.25, 0.03), loc=(sx * 0.955, -0.55, 1.2), bevel=0.008)
        # Door seams and handles, sill, arch flares.
        for y, z0, z1 in ((1.0, 0.55, 1.2), (-0.28, 0.5, 1.2), (-1.36, 0.6, 1.2)):
            box(m, "black", (0.012, 0.012, z1 - z0), loc=(sx * 0.99, y, (z0 + z1) * 0.5))
        box(m, "black", (0.012, 2.3, 0.012), loc=(sx * 0.99, -0.18, 0.5))
        for y in (0.6, -0.68):
            box(m, "steel", (0.03, 0.17, 0.035), loc=(sx * 1.0, y, 1.0), bevel=0.012)
        box(m, "trim", (0.06, 1.9, 0.12), loc=(sx * 0.97, 0.0, 0.47), bevel=0.03)
        for yc in (-1.5, 1.5):
            pts = []
            for a in range(180, -1, -15):
                ar = math.radians(a)
                pts.append((sx * 0.985, yc + 0.56 * math.cos(ar), 0.42 + 0.56 * math.sin(ar)))
            tube_path(m, "trim", pts, 0.045, segs=8)
        # Mirror, head and tail lights, roof rail.
        tube_path(m, "black", [(sx * 0.92, 0.95, 1.2), (sx * 1.04, 0.92, 1.26)], 0.025, segs=8)
        box(m, "paint", (0.12, 0.1, 0.16), loc=(sx * 1.1, 0.9, 1.3), bevel=0.035, segments=3)
        box(m, "glass", (0.1, 0.02, 0.12), loc=(sx * 1.1, 0.84, 1.3), bevel=0.01)
        box(m, "trim", (0.42, 0.06, 0.18), loc=(sx * 0.62, 2.33, 0.97), rot=(0, 0, sx * 8), bevel=0.03)
        box(m, "lamp", (0.34, 0.05, 0.12), loc=(sx * 0.62, 2.36, 0.97), rot=(0, 0, sx * 8), bevel=0.025)
        box(m, "amber", (0.1, 0.05, 0.12), loc=(sx * 0.86, 2.3, 0.97), rot=(0, 0, sx * 25), bevel=0.02)
        box(m, "tail", (0.12, 0.06, 0.38), loc=(sx * 0.84, -2.36, 1.0), bevel=0.03)
        box(m, "lamp", (0.08, 0.065, 0.08), loc=(sx * 0.84, -2.36, 0.86), bevel=0.02)
        tube_path(m, "steel", [(sx * 0.68, 0.4, 1.93), (sx * 0.7, 0.32, 2.0), (sx * 0.7, -1.7, 2.0), (sx * 0.68, -1.78, 1.93)], 0.022, segs=8)
    # Grille, bumpers, skid plate, plates, tailgate, spare wheel, exhaust.
    box(m, "trim", (0.84, 0.05, 0.3), loc=(0, 2.37, 0.92), bevel=0.03)
    for k in range(4):
        box(m, "steel", (0.78, 0.03, 0.02), loc=(0, 2.4, 0.82 + k * 0.065), bevel=0.005)
    box(m, "trim", (1.96, 0.24, 0.24), loc=(0, 2.32, 0.55), bevel=0.06, segments=3)
    box(m, "steel", (0.9, 0.08, 0.06), loc=(0, 2.36, 0.4), bevel=0.02)
    box(m, "plate", (0.5, 0.02, 0.12), loc=(0, 2.45, 0.58), bevel=0.008)
    box(m, "trim", (1.96, 0.24, 0.24), loc=(0, -2.33, 0.55), bevel=0.06, segments=3)
    box(m, "plate", (0.5, 0.02, 0.12), loc=(0, -2.42, 0.86), bevel=0.008)
    box(m, "black", (1.4, 0.012, 0.012), loc=(0, -2.38, 1.16))
    box(m, "steel", (0.2, 0.03, 0.04), loc=(0, -2.38, 1.05), bevel=0.01)
    cyl(m, "black", 0.04, 0.2, loc=(0.6, -2.38, 0.42), rot=(90, 0, 0), segs=10)
    spare = make_wheel(0.38, 0.24)
    m.merge(spare, Matrix.Translation((0, -2.47, 1.0)) @ Matrix.Rotation(math.radians(90), 4, "X"))
    # Interior seen through the glass.
    box(m, "interior", (1.8, 0.45, 0.25), loc=(0, 0.95, 1.12), bevel=0.05)
    for x in (-0.42, 0.42):
        seat(m, x, 0.15, 0.82)
    seat(m, 0.0, -0.95, 0.82, w=1.5)
    steering(m, -0.42, 0.7, 1.22, r=0.17)
    # Wheels.
    w = make_wheel(0.42, 0.3)
    for sx in (-1, 1):
        for y in (-1.5, 1.5):
            put_wheel(m, w, sx * 0.86, y, 0.42)
    return m.finish(smooth_angle=35.0)


# --------------------------------------------------------- ramp equipment

def tug():
    m = bkit.Model("tug")
    side = [(-1.3, 0.28)] + arch(-0.85, 0.32, 0.4, 0.28, 8) + arch(0.85, 0.32, 0.4, 0.28, 8) + [
        (1.3, 0.28), (1.34, 0.7), (1.15, 0.98), (-1.3, 0.98)]
    carve(m, "paint", side=side, plan=[(-0.78, -1.3), (0.78, -1.3), (0.78, 1.15), (0.6, 1.35), (-0.6, 1.35), (-0.78, 1.15)], bevel=0.04)
    box(m, "hazard", (1.58, 0.16, 0.2), loc=(0, 1.38, 0.45), bevel=0.03)
    box(m, "rubber", (1.6, 0.2, 0.14), loc=(0, -1.36, 0.45), bevel=0.03)
    box(m, "steel", (0.2, 0.4, 0.06), loc=(0, -1.45, 0.5), bevel=0.01)
    torus(m, "steel", 0.06, 0.018, loc=(0, -1.62, 0.5))
    # Open cab: posts, roof, windscreen, seat and wheel.
    for sx in (-0.66, 0.66):
        for y in (0.15, -1.05):
            tube_path(m, "trim", [(sx, y, 0.98), (sx, y + (0.1 if y > 0 else 0.0), 1.9)], 0.03, segs=8)
    box(m, "trim", (1.46, 1.42, 0.06), loc=(0, -0.42, 1.93), bevel=0.02)
    box(m, "glass", (1.28, 0.02, 0.62), loc=(0, 0.2, 1.55), rot=(-10, 0, 0), bevel=0.01)
    box(m, "interior", (1.3, 0.3, 0.3), loc=(0, 0.1, 1.12), bevel=0.04)
    seat(m, 0.0, -0.55, 1.0, w=0.55)
    steering(m, 0.0, -0.05, 1.42, r=0.15)
    lathe(m, "amber", [(0.09, 0.0), (0.09, 0.07), (0.06, 0.13), (0.0005, 0.15)], loc=(0, -0.42, 1.96), segs=14)
    for sx in (-1, 1):
        lamp(m, "lamp", (0.18, 0.04, 0.12), (sx * 0.5, 1.34, 0.75))
        box(m, "tail", (0.12, 0.04, 0.1), loc=(sx * 0.6, -1.31, 0.8), bevel=0.02)
    w = make_wheel(0.32, 0.26)
    for sx in (-1, 1):
        for y in (-0.85, 0.85):
            put_wheel(m, w, sx * 0.8, y, 0.32)
    return m.finish(smooth_angle=35.0)


def gpu_cart():
    m = bkit.Model("gpu_cart")
    box(m, "paint", (1.36, 2.1, 1.0), loc=(0, 0, 0.78), bevel=0.04, segments=3)
    box(m, "hazard", (1.42, 2.16, 0.08), loc=(0, 0, 1.31), bevel=0.02)
    box(m, "paint", (1.3, 2.04, 0.08), loc=(0, 0, 1.38), bevel=0.02)
    for sx in (-1, 1):
        for k in range(7):
            box(m, "trim", (0.03, 0.9, 0.035), loc=(sx * 0.69, 0.4, 0.55 + k * 0.08), rot=(0, sx * 25, 0), bevel=0.006)
        for y in (-0.7, 0.7):
            box(m, "black", (0.2, 0.55, 0.06), loc=(sx * 0.62, y, 0.36), bevel=0.02)
    # Control panel with gauges and lit switches.
    box(m, "trim", (1.0, 0.04, 0.6), loc=(0, 1.06, 0.85), bevel=0.02)
    for i, x in enumerate((-0.3, 0.0, 0.3)):
        cyl(m, "steel", 0.08, 0.03, loc=(x, 1.09, 0.98), rot=(90, 0, 0), segs=16)
        cyl(m, "screen", 0.065, 0.032, loc=(x, 1.095, 0.98), rot=(90, 0, 0), segs=16)
    for x in (-0.3, -0.15, 0.0, 0.15, 0.3):
        cyl(m, "lamp" if x < 0.1 else "amber", 0.022, 0.03, loc=(x, 1.09, 0.72), rot=(90, 0, 0), segs=8)
    box(m, "black", (0.3, 0.05, 0.08), loc=(0, 1.09, 0.62), bevel=0.01)
    # Cable reel on the side with coiled cable.
    lathe(m, "steel", [(0.3, -0.12), (0.3, -0.1), (0.12, -0.1), (0.12, 0.1), (0.3, 0.1), (0.3, 0.12)], loc=(-0.8, -0.4, 0.85), rot=(0, 90, 0), segs=24)
    for k in range(4):
        torus(m, "cable", 0.15 + k * 0.035, 0.022, loc=(-0.8, -0.4, 0.85), rot=(0, 90, 0), segs=24, minor_segs=6)
    tube_path(m, "cable", [(-0.82, -0.2, 0.62), (-0.85, 0.2, 0.35), (-0.6, 0.9, 0.2), (-0.3, 1.5, 0.05), (0.3, 1.8, 0.05)], 0.025, segs=8)
    # Tow bar, lifting eyes, wheels.
    tube_path(m, "steel", [(-0.4, 1.0, 0.36), (0, 1.75, 0.3)], 0.03, segs=8)
    tube_path(m, "steel", [(0.4, 1.0, 0.36), (0, 1.75, 0.3)], 0.03, segs=8)
    torus(m, "steel", 0.08, 0.02, loc=(0, 1.83, 0.3))
    for x, y in ((-0.5, -0.8), (0.5, -0.8), (-0.5, 0.8), (0.5, 0.8)):
        torus(m, "steel", 0.05, 0.012, loc=(x, y, 1.47), rot=(90, 0, 0))
    w = make_wheel(0.24, 0.16)
    for sx in (-1, 1):
        for y in (-0.7, 0.7):
            put_wheel(m, w, sx * 0.72, y, 0.24)
    return m.finish(smooth_angle=35.0)


def belt_loader():
    m = bkit.Model("belt_loader")
    side = [(-2.0, 0.3)] + arch(-1.4, 0.3, 0.36, 0.3, 8) + arch(1.4, 0.3, 0.36, 0.3, 8) + [
        (2.0, 0.3), (2.02, 0.72), (1.9, 0.85), (-2.0, 0.85)]
    carve(m, "paint", side=side, plan=[(-0.78, -2.0), (0.78, -2.0), (0.78, 2.0), (-0.78, 2.0)], bevel=0.04)
    box(m, "hazard", (1.6, 0.12, 0.16), loc=(0, 2.04, 0.5), bevel=0.02)
    # Inclined conveyor: frame, belt, rollers, guide rails.
    pitch = math.degrees(math.asin(2.0 / 5.5))
    c = (0, 0.4, 2.05)

    def on_belt(y, z=0.0, x=0.0):
        a = math.radians(pitch)
        return (c[0] + x, c[1] + y * math.cos(a) - z * math.sin(a), c[2] + y * math.sin(a) + z * math.cos(a))

    box(m, "belt", (0.86, 5.5, 0.06), loc=on_belt(0, 0.03), rot=(pitch, 0, 0), bevel=0.01)
    for sx in (-1, 1):
        box(m, "steel", (0.08, 5.6, 0.22), loc=on_belt(0, 0.0, sx * 0.48), rot=(pitch, 0, 0), bevel=0.015)
        tube_path(m, "steel", [on_belt(-2.6, 0.12, sx * 0.48), on_belt(-2.5, 0.45, sx * 0.5), on_belt(2.3, 0.45, sx * 0.5), on_belt(2.45, 0.12, sx * 0.48)], 0.018, segs=8)
        for y in (-1.2, 0.0, 1.2):
            tube_path(m, "steel", [on_belt(y, 0.12, sx * 0.49), on_belt(y, 0.45, sx * 0.5)], 0.014, segs=6)
    for y in (-2.72, 2.72):
        cyl(m, "rubber", 0.07, 0.86, loc=on_belt(y, -0.0), rot=(0, 90, 0), segs=14)
    for k in range(10):
        cyl(m, "black", 0.035, 0.84, loc=on_belt(-2.4 + k * 0.53, -0.08), rot=(0, 90, 0), segs=8)
    # Struts: a scissor of hydraulic rams up to the frame.
    for sx in (-0.3, 0.3):
        tube_path(m, "steel", [(sx, -1.4, 0.85), on_belt(-1.6, -0.1, sx)], 0.05, segs=10)
        tube_path(m, "chrome", [(sx, 1.0, 0.85), on_belt(1.0, -0.1, sx)], 0.03, segs=10)
        tube_path(m, "paint", [(sx, 1.0, 0.85), on_belt(0.3, -0.1, sx)], 0.06, segs=10)
    # Driver's seat at the low end, wheel and lights.
    seat(m, 0.45, -1.3, 0.9, w=0.45)
    steering(m, 0.45, -0.85, 1.3, r=0.14)
    for sx in (-1, 1):
        lamp(m, "lamp", (0.16, 0.04, 0.1), (sx * 0.6, 2.02, 0.7))
    lathe(m, "amber", [(0.07, 0.0), (0.07, 0.06), (0.0005, 0.12)], loc=(-0.6, -1.8, 0.85), segs=12)
    w = make_wheel(0.3, 0.2)
    for sx in (-1, 1):
        for y in (-1.4, 1.4):
            put_wheel(m, w, sx * 0.82, y, 0.3)
    return m.finish(smooth_angle=35.0)


def quad():
    m = bkit.Model("quad")
    # Tube frame and skid plate.
    for sx in (-0.18, 0.18):
        tube_path(m, "black", [(sx, -0.75, 0.42), (sx, -0.3, 0.32), (sx, 0.45, 0.32), (sx, 0.75, 0.5), (sx * 0.8, 0.85, 0.75)], 0.022, segs=8)
    box(m, "steel", (0.45, 0.9, 0.03), loc=(0, 0.0, 0.26), bevel=0.01)
    # Moulded fenders front and rear.
    for yc, sgn in ((0.65, 1), (-0.65, -1)):
        # A curved band hugging the tyre.
        side = arc(yc, 0.28, 0.4, 20, 160, 12) + arc(yc, 0.28, 0.33, 160, 20, 12)
        carve(m, "paint", side=side, plan=[(-0.66, yc - 0.45), (0.66, yc - 0.45), (0.66, yc + 0.45), (-0.66, yc + 0.45)], bevel=0.02)
        box(m, "paint", (0.5, 0.86, 0.12), loc=(0, yc, 0.62), bevel=0.04, segments=3)
        # Luggage rack.
        for x in (-0.3, 0.3):
            tube_path(m, "steel", [(x, yc - sgn * 0.3, 0.68), (x, yc + sgn * 0.3, 0.72)], 0.014, segs=6)
        for k in range(4):
            tube_path(m, "steel", [(-0.32, yc - sgn * 0.3 + sgn * k * 0.2, 0.7), (0.32, yc - sgn * 0.3 + sgn * k * 0.2, 0.7)], 0.012, segs=6)
    # Tank, seat, handlebars and the nose with headlights.
    carve(m, "paint", side=[(0.0, 0.5), (0.48, 0.5), (0.42, 0.78), (0.05, 0.82)], plan=[(-0.22, 0.0), (0.22, 0.0), (0.2, 0.5), (-0.2, 0.5)], bevel=0.04)
    carve(m, "seat", side=[(-0.62, 0.62), (0.08, 0.62), (0.05, 0.8), (-0.55, 0.78), (-0.62, 0.72)], plan=[(-0.17, -0.62), (0.17, -0.62), (0.19, 0.08), (-0.19, 0.08)], bevel=0.04, segments=3)
    tube_path(m, "black", [(0, 0.4, 0.8), (0, 0.45, 0.98)], 0.022, segs=8)
    tube_path(m, "black", [(-0.38, 0.38, 1.02), (-0.15, 0.45, 0.98), (0.15, 0.45, 0.98), (0.38, 0.38, 1.02)], 0.016, segs=8)
    for sx in (-1, 1):
        cyl(m, "rubber", 0.022, 0.12, loc=(sx * 0.42, 0.37, 1.025), rot=(0, 90, -15 * sx), segs=10)
        lamp(m, "lamp", (0.1, 0.04, 0.06), (sx * 0.14, 1.12, 0.62))
        box(m, "black", (0.12, 0.28, 0.025), loc=(sx * 0.3, -0.05, 0.36), bevel=0.008)
        box(m, "tail", (0.06, 0.03, 0.04), loc=(sx * 0.12, -1.12, 0.6), bevel=0.01)
    carve(m, "paint", side=[(0.95, 0.42), (1.12, 0.48), (1.1, 0.68), (0.95, 0.72)], plan=[(-0.25, 0.95), (0.25, 0.95), (0.2, 1.13), (-0.2, 1.13)], bevel=0.03)
    tube_path(m, "steel", [(0.22, -0.4, 0.4), (0.26, -0.8, 0.45), (0.26, -1.05, 0.48)], 0.03, segs=10)
    w = make_wheel(0.28, 0.24, knobby=True, spokes=4)
    for sx in (-1, 1):
        for y in (-0.65, 0.65):
            put_wheel(m, w, sx * 0.55, y, 0.28)
    return m.finish(smooth_angle=35.0)


# ------------------------------------------------------------------- heli

def heli():
    objs = []
    b = bkit.Model("heli_body")
    n = 2.6
    loft(b, "paint", [
        (2.62, 0, -0.18, 0.0005, 0.0005, n), (2.58, 0, -0.16, 0.14, 0.12, n), (2.45, 0, -0.12, 0.28, 0.26, n),
        (2.1, 0, -0.06, 0.42, 0.44, n), (1.4, 0, 0.0, 0.52, 0.62, n), (0.4, 0, 0.05, 0.58, 0.76, n),
        (-0.6, 0, 0.1, 0.56, 0.76, n), (-1.5, 0, 0.16, 0.46, 0.58, n), (-2.3, 0, 0.22, 0.28, 0.34, n),
        (-3.0, 0, 0.26, 0.19, 0.22, n), (-5.4, 0, 0.32, 0.13, 0.15, n), (-5.85, 0, 0.36, 0.12, 0.14, n),
        (-6.0, 0, 0.37, 0.0005, 0.0005, n)], segs=32)
    # The team band on the boom.
    loft(b, "team", [(-3.6, 0, 0.28, 0.168, 0.193, n), (-3.58, 0, 0.28, 0.175, 0.2, n), (-3.22, 0, 0.27, 0.185, 0.21, n), (-3.2, 0, 0.27, 0.178, 0.203, n)], segs=32)
    # Stepped tandem canopy with frames.
    loft(b, "glass", [
        (2.25, 0, 0.32, 0.0005, 0.0005, 2.2), (2.1, 0, 0.36, 0.26, 0.2, 2.2), (1.5, 0, 0.45, 0.4, 0.38, 2.2),
        (0.9, 0, 0.55, 0.42, 0.5, 2.2), (0.75, 0, 0.6, 0.42, 0.58, 2.2), (0.0, 0, 0.66, 0.42, 0.66, 2.2),
        (-0.45, 0, 0.66, 0.34, 0.6, 2.2), (-0.7, 0, 0.62, 0.0005, 0.0005, 2.2)], segs=28)
    for y, cz, rx, rz in ((1.5, 0.45, 0.41, 0.39), (0.82, 0.57, 0.43, 0.55), (0.0, 0.66, 0.43, 0.67)):
        pts = []
        for a in range(0, 181, 15):
            ar = math.radians(a)
            c, s = math.cos(ar), math.sin(ar)
            pts.append((rx * math.copysign(abs(c) ** (2 / 2.2), c), y, cz + rz * abs(s) ** (2 / 2.2)))
        tube_path(b, "black", pts, 0.022, segs=6)
    tube_path(b, "black", [(0, 2.12, 0.55), (0, 1.5, 0.85), (0, 0.82, 1.13), (0, 0.0, 1.34), (0, -0.5, 1.25)], 0.022, segs=6)
    # Cockpit seats and instrument coamings under the glass.
    for y, z in ((1.25, 0.15), (0.2, 0.35)):
        box(b, "interior", (0.4, 0.4, 0.1), loc=(0, y, z), bevel=0.03)
        box(b, "interior", (0.4, 0.1, 0.55), loc=(0, y - 0.22, z + 0.28), bevel=0.03)
        box(b, "black", (0.6, 0.2, 0.18), loc=(0, y + 0.5, z + 0.28), bevel=0.03)
    # Engine nacelles with intakes and exhausts, mast fairing.
    for sx in (-1, 1):
        x = sx * 0.5
        loft(b, "paint", [(0.25, x, 0.7, 0.0005, 0.0005), (0.24, x, 0.7, 0.18, 0.2), (0.0, x, 0.72, 0.24, 0.26), (-1.1, x, 0.74, 0.24, 0.26), (-1.5, x, 0.74, 0.17, 0.19)], segs=20)
        lathe(b, "black", [(0.16, 0.0), (0.2, 0.02), (0.2, 0.05), (0.0005, 0.03)], loc=(x, 0.24, 0.7), rot=(-90, 0, 0), segs=20)
        lathe(b, "black", [(0.15, 0.0), (0.16, 0.25), (0.13, 0.27), (0.12, 0.05)], loc=(x, -1.48, 0.74), rot=(90, 0, sx * 25), segs=16)
    loft(b, "paint", [(0.4, 0, 0.9, 0.0005, 0.0005), (0.35, 0, 0.9, 0.2, 0.15), (0.0, 0, 0.95, 0.3, 0.2), (-0.8, 0, 0.95, 0.28, 0.2), (-1.4, 0, 0.88, 0.0005, 0.0005)], segs=20)
    cyl(b, "black", 0.13, 0.4, loc=(0, 0.2, 1.15), r2=0.1, segs=14)
    # Stub wings, pylons, rocket pods and wingtip missiles.
    for sx in (-1, 1):
        prism(b, "paint", [(0.6, -0.02), (0.05, 0.06), (-0.3, 0.02), (-0.3, -0.02), (0.6, -0.06)], "x", sx * 0.45, sx * 1.6, bevel=0.01, rot=(0, sx * 6, 0))
        box(b, "black", (0.08, 0.3, 0.2), loc=(sx * 1.25, 0.15, -0.12), bevel=0.02)
        lathe(b, "pod", [(0.0005, -0.7), (0.17, -0.68), (0.21, -0.55), (0.21, 0.55), (0.17, 0.65), (0.0005, 0.66)], loc=(sx * 1.25, 0.1, -0.38), rot=(-90, 0, 0), segs=20)
        for k in range(7):
            a = 2 * math.pi * k / 7
            cyl(b, "black", 0.035, 0.03, loc=(sx * 1.25 + 0.1 * math.cos(a), 0.77, -0.38 + 0.1 * math.sin(a)), rot=(90, 0, 0), segs=8)
        cyl(b, "black", 0.035, 0.03, loc=(sx * 1.25, 0.77, -0.38), rot=(90, 0, 0), segs=8)
        lathe(b, "missile", [(0.0005, -0.55), (0.06, -0.52), (0.06, 0.4), (0.04, 0.5), (0.0005, 0.56)], loc=(sx * 1.62, 0.15, -0.12), rot=(-90, 0, 0), segs=12)
        for k in range(4):
            box(b, "missile", (0.005, 0.12, 0.2), loc=(sx * 1.62, -0.32, -0.12), rot=(0, k * 45, 0))
        # Skid gear: cross tubes down to the skids, upturned at the front.
        for y in (0.9, -0.9):
            tube_path(b, "black", [(sx * 0.35, y, -0.55), (sx * 0.62, y, -0.95), (sx * 0.66, y, -1.15)], 0.035, segs=8)
        tube_path(b, "black", [(sx * 0.66, -1.6, -1.15), (sx * 0.66, 1.5, -1.15), (sx * 0.66, 1.8, -1.05), (sx * 0.66, 1.9, -0.9)], 0.04, segs=10)
        # Stabiliser.
        prism(b, "paint", [(-5.1, 0.33), (-5.35, 0.37), (-5.65, 0.37), (-5.55, 0.31)], "x", sx * 0.1, sx * 0.85, bevel=0.01)
    # Vertical fin with a tail rotor gearbox, tail skid, antennae.
    prism(b, "paint", [(-5.2, 0.35), (-5.75, 0.35), (-6.15, 1.45), (-5.9, 1.48), (-5.5, 0.75)], "x", -0.05, 0.05, bevel=0.015)
    lathe(b, "black", [(0.0005, 0.0), (0.09, 0.0), (0.09, 0.12), (0.0005, 0.14)], loc=(0.05, -5.6, 0.9), rot=(0, 90, 0), segs=12)
    tube_path(b, "black", [(0, -5.6, 0.25), (0, -5.85, -0.05), (0, -6.1, -0.05)], 0.025, segs=8)
    for x, y in ((0.2, -1.8), (-0.15, -2.6)):
        tube_path(b, "black", [(x, y, 0.42), (x * 1.2, y - 0.25, 0.75)], 0.008, segs=5)
    # Nose sensor turret.
    sphere(b, "black", 0.16, loc=(0, 2.48, -0.22), segs=18, rings=10)
    cyl(b, "glass", 0.08, 0.04, loc=(0, 2.63, -0.22), rot=(90, 0, 0), segs=14)
    objs.append(b.finish(smooth_angle=35.0))

    # Main rotor: hub, swash plate and four blades with yellow tips.
    r = bkit.Model("heli_rotor")
    lathe(r, "black", [(0.0005, -0.12), (0.18, -0.12), (0.2, -0.04), (0.2, 0.04), (0.12, 0.1), (0.0005, 0.12)], segs=16)
    for i in range(4):
        a = i * 90
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        box(r, "black", (0.4, 0.12, 0.06), loc=(0.3 * ca, 0.3 * sa, 0.0), rot=(0, 0, a), bevel=0.015)
        box(r, "blade", (2.7, 0.3, 0.035), loc=(1.75 * ca, 1.75 * sa, 0.01), rot=(4, 0, a), bevel=0.012)
        box(r, "stripe", (0.18, 0.302, 0.037), loc=(3.0 * ca, 3.0 * sa, 0.01), rot=(4, 0, a), bevel=0.01)
    objs.append(r.finish(smooth_angle=35.0))

    t = bkit.Model("heli_tail_rotor")
    lathe(t, "black", [(0.0005, -0.05), (0.07, -0.05), (0.07, 0.05), (0.0005, 0.06)], rot=(0, 90, 0), segs=12)
    for i in range(4):
        a = i * 90
        box(t, "blade", (0.03, 0.12, 0.62), loc=(0.02, 0.33 * math.sin(math.radians(a)), 0.33 * math.cos(math.radians(a))), rot=(-a, 0, 0), bevel=0.01)
    objs.append(t.finish(smooth_angle=35.0))

    g = bkit.Model("heli_gun")
    sphere(g, "black", 0.24, segs=18, rings=12)
    box(g, "black", (0.28, 0.32, 0.22), loc=(0, 0.2, 0.0), bevel=0.04)
    for k in range(3):
        a = 2 * math.pi * k / 3
        cyl(g, "steel", 0.025, 1.0, loc=(0.04 * math.cos(a), 0.75, 0.04 * math.sin(a)), rot=(90, 0, 0), segs=8)
    for y in (0.6, 1.1):
        cyl(g, "black", 0.075, 0.05, loc=(0, y, 0), rot=(90, 0, 0), segs=12)
    objs.append(g.finish(smooth_angle=35.0))
    return objs


# -------------------------------------------------------------------- dog

def dog():
    objs = []
    body = bkit.Model("dog_body")
    # Deep chest, tucked waist, muscular haunches, neck rising to the head.
    secs = [(-0.47, 0, 0.08, 0.02, 0.02), (-0.445, 0, 0.065, 0.08, 0.085), (-0.38, 0, 0.04, 0.115, 0.125), (-0.27, 0, 0.05, 0.108, 0.112),
            (-0.14, 0, 0.06, 0.102, 0.108), (0.04, 0, 0.03, 0.115, 0.14), (0.2, 0, -0.01, 0.13, 0.175), (0.32, 0, 0.0, 0.135, 0.17),
            (0.41, 0, 0.07, 0.11, 0.13), (0.48, 0, 0.14, 0.095, 0.105), (0.54, 0, 0.2, 0.085, 0.09), (0.58, 0, 0.23, 0.02, 0.02)]
    loft(body, "coat", secs, segs=20, subsurf=1)

    def back(c):
        # The black saddle of a shepherd: over the back, fading at the
        # shoulders and haunches.
        return c.z > 0.05 + 0.05 * abs(c.y + 0.05) and -0.38 < c.y < 0.36
    bkit.paint_faces(body, "saddle", back)
    torus(body, "collar", 0.115, 0.02, loc=(0, 0.44, 0.11), rot=(62, 0, 0), segs=24, minor_segs=8)
    cyl(body, "steel", 0.02, 0.006, loc=(0, 0.5, 0.0), rot=(90, 0, 0), segs=10)
    objs.append(body.finish(smooth_angle=60.0))

    head = bkit.Model("dog_head")
    loft(head, "coat", [(-0.14, 0, 0.0, 0.02, 0.02), (-0.12, 0, 0.0, 0.08, 0.085), (-0.05, 0, 0.015, 0.11, 0.105), (0.03, 0, 0.005, 0.105, 0.095),
                        (0.1, 0, -0.025, 0.07, 0.07), (0.17, 0, -0.04, 0.055, 0.055), (0.25, 0, -0.045, 0.045, 0.042), (0.29, 0, -0.045, 0.032, 0.032),
                        (0.3, 0, -0.045, 0.005, 0.005)], segs=18, subsurf=1)
    bkit.paint_faces(head, "saddle", lambda c: c.y > 0.12 or (c.z > 0.06 and c.y < 0.0))
    sphere(head, "nose", 0.03, loc=(0, 0.295, -0.03), scale=(1.2, 0.9, 0.8), segs=12, rings=8)
    for sx in (-1, 1):
        sphere(head, "eye", 0.017, loc=(sx * 0.058, 0.085, 0.035), segs=10, rings=6)
        prism(head, "saddle", [(-0.055, 0.0), (0.055, 0.0), (0.01, 0.17), (-0.008, 0.17)], "y", -0.012, 0.012, bevel=0.008,
              loc=(sx * 0.065, -0.04, 0.07), rot=(-15, sx * -20, 0))
    box(head, "nose", (0.08, 0.14, 0.006), loc=(0, 0.22, -0.08), bevel=0.002)
    objs.append(head.finish(smooth_angle=60.0))

    for name, secs in (
        ("dog_leg_front", [(-0.04, 0, 0.0, 0.055, 0.075), (0.06, 0, 0.0, 0.055, 0.075), (0.16, 0, -0.005, 0.04, 0.05), (0.26, 0, 0.0, 0.032, 0.036),
                           (0.36, 0, 0.005, 0.028, 0.032), (0.42, 0, 0.015, 0.03, 0.034), (0.45, 0, 0.02, 0.005, 0.005)]),
        ("dog_leg_back", [(-0.04, 0, 0.0, 0.065, 0.095), (0.06, 0, -0.02, 0.065, 0.09), (0.16, 0, -0.06, 0.045, 0.06), (0.25, 0, -0.085, 0.034, 0.04),
                          (0.3, 0, -0.08, 0.03, 0.034), (0.4, 0, -0.03, 0.028, 0.031), (0.44, 0, -0.01, 0.03, 0.032), (0.46, 0, -0.005, 0.005, 0.005)])):
        leg = bkit.Model(name)
        loft(leg, "coat", secs, segs=14, subsurf=1, rot=(-90, 0, 0))
        sphere(leg, "paw", 0.04, loc=(0, 0.025, -0.47), scale=(0.95, 1.25, 0.6), segs=12, rings=8)
        objs.append(leg.finish(smooth_angle=60.0))

    tail = bkit.Model("dog_tail")
    # Bushy and carried low, the tip curling back up.
    loft(tail, "saddle", [(0.0, 0, 0, 0.026, 0.026), (0.1, 0, -0.005, 0.034, 0.036), (0.22, 0, -0.02, 0.036, 0.038), (0.32, 0, -0.045, 0.028, 0.03),
                          (0.38, 0, -0.07, 0.015, 0.016), (0.4, 0, -0.08, 0.003, 0.003)], segs=12, subsurf=1, rot=(-140, 0, 0))
    objs.append(tail.finish(smooth_angle=60.0))
    return objs


def main():
    bkit.reset()
    objs = [truck_cab(), truck_box(), truck_tank(), suv(), tug(), gpu_cart(), belt_loader(), quad()]
    objs += heli()
    objs += dog()
    bkit.export("vehicles.glb", objs)


main()
