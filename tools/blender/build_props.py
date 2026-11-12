"""Map props -> props.glb.

Blender space (+X right, +Y forward = Godot -Z, +Z up), origin on the
ground under the prop unless noted. Sizes match the collision boxes the
map code already places, so a prop drops into its old footprint.

Objects:
    box_closed, box_open     1 m shipping carton (scaled per crate)
    uld                      airline cargo container
    baggage_cart             open baggage cart with canopy
    suitcase_hard, suitcase_soft, duffel
                             0.6 x 0.5 x 0.32 m luggage, origin at centre
    cone                     traffic cone
    barrier                  3 m of water-filled barrier (two sections)
    gate_seat, gate_leg      beam-seating seat and T-leg; gate_beam is 1 m
    gate_beam
    planter                  concrete planter
    drum                     fuel drum, 0.36 m radius, 1 m tall
    bin                      litter bin, 0.32 m radius
    engine                   airliner engine on its pylon, origin at centre
    gear                     main landing gear leg with two wheels
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bkit  # noqa: E402
from bkit import box, cyl, sphere, torus, lathe, loft, carve, prism, tube_path  # noqa: E402
from build_vehicles import make_wheel, put_wheel  # noqa: E402
from mathutils import Matrix  # noqa: E402


def arrow(m, slot, x, y, z, s, face="y"):
    """A printed 'this way up' arrow on a face."""
    pts = [(-0.06, -0.12), (0.06, -0.12), (0.06, 0.02), (0.12, 0.02), (0.0, 0.14), (-0.12, 0.02), (-0.06, 0.02)]
    pts = [(px * s + x, pz * s + z) for px, pz in pts]
    prism(m, slot, pts, "y", y - 0.002, y + 0.002)


# ----------------------------------------------------------------- cartons

def _carton_walls(m, inside):
    t = 0.012
    box(m, "card", (1.0, 1.0, t), loc=(0, 0, t * 0.5), bevel=0.003)
    for sx in (-1, 1):
        box(m, "card", (t, 1.0, 1.0), loc=(sx * (0.5 - t * 0.5), 0, 0.5), bevel=0.003)
        box(m, inside, (0.002, 0.97, 0.97), loc=(sx * (0.5 - t - 0.001), 0, 0.5))
    for sy in (-1, 1):
        box(m, "card", (1.0, t, 1.0), loc=(0, sy * (0.5 - t * 0.5), 0.5), bevel=0.003)
        box(m, inside, (0.97, 0.002, 0.97), loc=(0, sy * (0.5 - t - 0.001), 0.5))
    # Hand holes and a printed arrow, a shipping label.
    for sx in (-1, 1):
        box(m, "ink", (0.004, 0.17, 0.05), loc=(sx * 0.501, 0, 0.78), bevel=0.012)
    arrow(m, "ink", 0.28, 0.502, 0.6, 1.0)
    box(m, "label", (0.24, 0.004, 0.16), loc=(-0.22, 0.502, 0.35), bevel=0.002)
    for k in range(4):
        box(m, "ink", (0.16, 0.005, 0.008), loc=(-0.22, 0.503, 0.4 - k * 0.03))
    # Glued manufacturer's joint down one corner.
    box(m, "card_core", (0.05, 0.004, 0.98), loc=(0.47, -0.503, 0.5))


def box_closed():
    m = bkit.Model("box_closed")
    _carton_walls(m, "card_core")
    # Top flaps meet in a seam, crowned slightly, taped across and down.
    for sx in (-1, 1):
        box(m, "card", (0.5, 1.0, 0.012), loc=(sx * 0.25, 0, 1.004), rot=(0, sx * -1.2, 0), bevel=0.003)
    box(m, "tape", (0.18, 1.012, 0.004), loc=(0, 0, 1.013))
    for sy in (-1, 1):
        box(m, "tape", (0.18, 0.004, 0.22), loc=(0, sy * 0.503, 0.9))
    return m.finish(smooth_angle=30.0)


def box_open():
    m = bkit.Model("box_open")
    _carton_walls(m, "card_core")
    a = 28
    ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
    for sx in (-1, 1):
        box(m, "card", (0.5, 0.98, 0.01), loc=(sx * (0.5 + 0.25 * ca), 0, 1.0 - 0.25 * sa), rot=(0, sx * a, 0), bevel=0.003)
    for sy in (-1, 1):
        box(m, "card", (0.96, 0.46, 0.01), loc=(0, sy * (0.5 + 0.23 * ca), 1.0 - 0.23 * sa), rot=(-sy * a, 0, 0), bevel=0.003)
    # Torn tape ends hanging off the flaps.
    for sy in (-1, 1):
        box(m, "tape", (0.18, 0.004, 0.12), loc=(0, sy * 0.503, 0.94))
    return m.finish(smooth_angle=30.0)


# --------------------------------------------------------------- uld can

def uld():
    m = bkit.Model("uld")
    prof = [(-0.775, 0.08), (0.775, 0.08), (0.775, 1.6), (-0.28, 1.6), (-0.775, 1.0)]
    prism(m, "paint", prof, "x", -0.99, 0.99, bevel=0.02)
    box(m, "base", (2.04, 1.6, 0.08), loc=(0, 0, 0.04), bevel=0.01)
    for sx in (-1, 1):
        pts = [(sx * 1.0, y, z) for y, z in prof] + [(sx * 1.0, prof[0][0], prof[0][1])]
        tube_path(m, "frame", pts, 0.025, segs=6)
        # Corrugated side ribs.
        for k in range(5):
            y = -0.55 + k * 0.3
            ztop = 1.6 if y > -0.28 else 1.0 + (y + 0.775) * 1.2
            box(m, "frame", (0.02, 0.04, ztop - 0.2), loc=(sx * 1.0, y, 0.1 + (ztop - 0.2) * 0.5 + 0.02))
    for y, z in ((0.775, 1.6), (-0.28, 1.6), (0.775, 0.08)):
        tube_path(m, "frame", [(-1.0, y, z), (1.0, y, z)], 0.025, segs=6)
    tube_path(m, "frame", [(-1.0, -0.775, 1.0), (1.0, -0.775, 1.0)], 0.025, segs=6)
    # Door curtain with straps on the front face, ID panel and placards.
    box(m, "curtain", (1.84, 0.02, 1.38), loc=(0, 0.785, 0.84), bevel=0.01)
    for k in range(4):
        box(m, "strap", (1.86, 0.03, 0.04), loc=(0, 0.795, 0.3 + k * 0.36), bevel=0.008)
    for x in (-0.6, 0.0, 0.6):
        box(m, "steel", (0.06, 0.04, 0.06), loc=(x, 0.81, 0.12), bevel=0.01)
    box(m, "label", (0.9, 0.012, 0.28), loc=(0, 0.8, 1.22), bevel=0.004)
    for k in range(3):
        box(m, "ink", (0.7 - k * 0.15, 0.014, 0.035), loc=(0, 0.802, 1.29 - k * 0.07))
    box(m, "label", (0.012, 0.6, 0.18), loc=(1.005, 0.2, 1.3), bevel=0.003)
    box(m, "label", (0.012, 0.6, 0.18), loc=(-1.005, 0.2, 1.3), bevel=0.003)
    for sx in (-1, 1):
        box(m, "ink", (0.014, 0.46, 0.05), loc=(sx * 1.006, 0.2, 1.3))
    return m.finish(smooth_angle=30.0)


# ----------------------------------------------------------- baggage cart

def baggage_cart():
    m = bkit.Model("baggage_cart")
    # Chassis frame and a slatted deck.
    for sy in (-1, 1):
        box(m, "frame", (2.6, 0.06, 0.1), loc=(0, sy * 0.72, 0.42), bevel=0.01)
    for x in (-1.2, -0.4, 0.4, 1.2):
        box(m, "frame", (0.06, 1.44, 0.08), loc=(x, 0, 0.42), bevel=0.01)
    for k in range(9):
        box(m, "deck", (2.5, 0.14, 0.02), loc=(0, -0.64 + k * 0.16, 0.48), bevel=0.004)
    # End gates: tube frames with vertical bars, in safety yellow.
    for sx in (-1, 1):
        x = sx * 1.27
        tube_path(m, "paint", [(x, -0.74, 0.47), (x, -0.74, 1.02), (x, 0.74, 1.02), (x, 0.74, 0.47)], 0.025, segs=8)
        for k in range(7):
            tube_path(m, "paint", [(x, -0.54 + k * 0.18, 0.47), (x, -0.54 + k * 0.18, 1.02)], 0.012, segs=6)
        # Canopy posts.
        for sy in (-1, 1):
            tube_path(m, "frame", [(x, sy * 0.74, 1.02), (x, sy * 0.74, 1.52)], 0.022, segs=8)
    # Fabric canopy, curved and hemmed.
    carve(m, "canopy", front=[(-0.84, 1.5), (0.84, 1.5), (0.8, 1.58), (0.5, 1.63), (0.0, 1.65), (-0.5, 1.63), (-0.8, 1.58)],
          plan=[(-1.36, -0.84), (1.36, -0.84), (1.36, 0.84), (-1.36, 0.84)], bevel=0.008)
    for sy in (-1, 1):
        box(m, "canopy", (2.72, 0.01, 0.12), loc=(0, sy * 0.84, 1.45), bevel=0.003)
    # Side rails, drawbar with ring, coupling at the back, castor wheels.
    for sy in (-1, 1):
        tube_path(m, "frame", [(-1.25, sy * 0.76, 0.62), (1.25, sy * 0.76, 0.62)], 0.018, segs=6)
    tube_path(m, "steel", [(-1.25, -0.5, 0.4), (-1.75, 0.0, 0.32), (-2.1, 0.0, 0.3)], 0.03, segs=8)
    tube_path(m, "steel", [(-1.25, 0.5, 0.4), (-1.75, 0.0, 0.32)], 0.03, segs=8)
    torus(m, "steel", 0.07, 0.018, loc=(-2.17, 0, 0.3))
    box(m, "steel", (0.16, 0.12, 0.1), loc=(1.33, 0, 0.38), bevel=0.01)
    w = make_wheel(0.2, 0.12, spokes=4)
    for sx in (-0.95, 0.95):
        for sy in (-1, 1):
            # Axle across the cart, outer face pointing away from it.
            m.merge(w, Matrix.Translation((sx, sy * 0.66, 0.2)) @ Matrix.Rotation(math.radians(-90 * sy), 4, "X"))
            box(m, "frame", (0.05, 0.14, 0.2), loc=(sx, sy * 0.66 - sy * 0.09, 0.32), bevel=0.01)
    for sy in (-1, 1):
        box(m, "tail", (0.03, 0.08, 0.05), loc=(1.3, sy * 0.6, 0.45), bevel=0.01)
    return m.finish(smooth_angle=30.0)


# ---------------------------------------------------------------- luggage

def suitcase_hard():
    m = bkit.Model("suitcase_hard")
    carve(m, "shell", plan=[(-0.3, -0.16), (0.3, -0.16), (0.3, 0.16), (-0.3, 0.16)],
          side=[(-0.16, -0.25), (0.16, -0.25), (0.16, 0.25), (-0.16, 0.25)], bevel=0.05, segments=4)
    # Moulded ribs on both faces, zip seam round the middle.
    for sy in (-1, 1):
        for x in (-0.15, 0.0, 0.15):
            box(m, "shell", (0.05, 0.012, 0.38), loc=(x, sy * 0.163, 0.0), bevel=0.005)
    box(m, "zip", (0.612, 0.02, 0.512), loc=(0, 0.0, 0.0), bevel=0.02)
    # Carry handle, telescopic handle housing, spinner wheels, corner guards.
    tube_path(m, "handle", [(-0.07, 0.0, 0.25), (-0.06, 0.0, 0.29), (0.06, 0.0, 0.29), (0.07, 0.0, 0.25)], 0.012, segs=8)
    for x in (-0.12, 0.12):
        box(m, "trim", (0.03, 0.03, 0.02), loc=(x, -0.13, 0.255), bevel=0.006)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, "trim", (0.05, 0.05, 0.03), loc=(sx * 0.26, sy * 0.12, -0.26), bevel=0.01)
            cyl(m, "wheel", 0.022, 0.018, loc=(sx * 0.26, sy * 0.12, -0.285), rot=(0, 90, 0), segs=10)
    return m.finish(smooth_angle=30.0)


def suitcase_soft():
    m = bkit.Model("suitcase_soft")
    box(m, "shell", (0.6, 0.3, 0.5), bevel=0.06, segments=4)
    # Front pocket, piping, zips with pullers, handle and feet.
    box(m, "shell", (0.5, 0.04, 0.36), loc=(0, 0.16, -0.03), bevel=0.03, segments=3)
    box(m, "zip", (0.46, 0.006, 0.01), loc=(0, 0.181, 0.13))
    box(m, "trim", (0.02, 0.012, 0.05), loc=(0.15, 0.185, 0.11), bevel=0.004)
    for sy in (-1, 1):
        tube_path(m, "trim", [(-0.3, sy * 0.15, 0.25), (0.3, sy * 0.15, 0.25), (0.3, sy * 0.15, -0.25), (-0.3, sy * 0.15, -0.25), (-0.3, sy * 0.15, 0.25)], 0.006, segs=5)
    box(m, "zip", (0.61, 0.01, 0.51), loc=(0, -0.06, 0.0), bevel=0.02)
    tube_path(m, "handle", [(-0.08, 0.0, 0.25), (-0.07, 0.0, 0.29), (0.07, 0.0, 0.29), (0.08, 0.0, 0.25)], 0.014, segs=8)
    for sx in (-1, 1):
        cyl(m, "wheel", 0.03, 0.025, loc=(sx * 0.25, -0.12, -0.26), rot=(0, 90, 0), segs=12)
        box(m, "trim", (0.04, 0.04, 0.03), loc=(sx * 0.25, 0.1, -0.26), bevel=0.01)
    return m.finish(smooth_angle=30.0)


def duffel():
    m = bkit.Model("duffel")
    secs = []
    for x, s in ((-0.3, 0.0), (-0.295, 0.75), (-0.28, 0.95), (-0.24, 1.0), (0.24, 1.0), (0.28, 0.95), (0.295, 0.75), (0.3, 0.0)):
        secs.append((x, 0, -0.02, max(0.16 * s, 0.0005), max(0.23 * s, 0.0005), 2.6))
    loft(m, "shell", secs, segs=24, rot=(0, 0, -90))
    for x in (-0.18, 0.18):
        loft(m, "trim", [(x - 0.02, 0, -0.02, 0.162, 0.232, 2.6), (x - 0.019, 0, -0.02, 0.168, 0.238, 2.6), (x + 0.019, 0, -0.02, 0.168, 0.238, 2.6), (x + 0.02, 0, -0.02, 0.162, 0.232, 2.6)], segs=24, rot=(0, 0, -90))
    box(m, "zip", (0.5, 0.012, 0.01), loc=(0, 0.0, 0.21))
    for x in (-0.18, 0.18):
        tube_path(m, "handle", [(x, -0.06, 0.2), (x, -0.03, 0.3), (x, 0.03, 0.3), (x, 0.06, 0.2)], 0.012, segs=8)
    for sx in (-1, 1):
        lathe(m, "trim", [(0.0005, 0.0), (0.06, 0.0), (0.06, 0.006)], loc=(sx * 0.302, 0, -0.02), rot=(0, 90 * sx, 0), segs=16)
    return m.finish(smooth_angle=35.0)


# ------------------------------------------------------- traffic and road

def cone():
    m = bkit.Model("cone")
    box(m, "base", (0.46, 0.46, 0.035), loc=(0, 0, 0.0175), bevel=0.012)
    lathe(m, "cone", [(0.2, 0.035), (0.19, 0.045), (0.045, 0.68), (0.032, 0.7), (0.0005, 0.7)], segs=24)
    for z0, z1 in ((0.34, 0.43), (0.5, 0.56)):
        r0 = 0.19 - (z0 - 0.045) / 0.635 * 0.145 + 0.003
        r1 = 0.19 - (z1 - 0.045) / 0.635 * 0.145 + 0.003
        lathe(m, "band", [(r0, z0), (r1, z1)], segs=24)
    return m.finish(smooth_angle=40.0)


def barrier():
    m = bkit.Model("barrier")
    prof = [(-0.3, 0.0), (0.3, 0.0), (0.3, 0.1), (0.15, 0.24), (0.12, 0.84), (0.07, 0.9), (-0.07, 0.9), (-0.12, 0.84), (-0.15, 0.24), (-0.3, 0.1)]
    for i, (x0, x1) in enumerate(((-1.49, -0.01), (0.01, 1.49))):
        slot = "plastic_a" if i == 0 else "plastic_b"
        prism(m, slot, prof, "x", x0, x1, bevel=0.03, segments=3)
        xc = (x0 + x1) * 0.5
        # Fill cap, forklift slots, moulded panels and a reflector.
        lathe(m, slot, [(0.06, 0.9), (0.06, 0.93), (0.0005, 0.94)], loc=(xc - 0.4, 0, 0), segs=14)
        for sx in (-0.4, 0.4):
            box(m, "black", (0.3, 0.62, 0.08), loc=(xc + sx, 0, 0.05), bevel=0.01)
        for sy in (-1, 1):
            box(m, slot, (1.1, 0.02, 0.45), loc=(xc, sy * 0.13, 0.55), rot=(sy * -3, 0, 0), bevel=0.02)
            box(m, "reflector", (0.12, 0.012, 0.06), loc=(xc, sy * 0.145, 0.78), bevel=0.004)
    # Interlocking lugs and the pin.
    for z in (0.3, 0.7):
        box(m, "black", (0.12, 0.1, 0.12), loc=(0, 0, z), bevel=0.01)
    cyl(m, "steel", 0.02, 0.9, loc=(0, 0, 0.5), segs=8)
    return m.finish(smooth_angle=30.0)


# ------------------------------------------------------------- furniture

def gate_seat():
    m = bkit.Model("gate_seat")
    # Moulded shell: seat pan flowing into a reclined back.
    side = [(0.25, 0.42), (0.27, 0.36), (-0.2, 0.33), (-0.28, 0.38), (-0.37, 0.95), (-0.31, 0.97), (-0.24, 0.42)]
    carve(m, "shell", side=side, plan=[(-0.27, -0.4), (0.27, -0.4), (0.27, 0.3), (-0.27, 0.3)],
          front=[(-0.27, 0.3), (0.27, 0.3), (0.27, 0.9), (0.2, 1.0), (-0.2, 1.0), (-0.27, 0.9)], bevel=0.025, segments=3)
    # Upholstered pads.
    carve(m, "pad", side=[(0.24, 0.42), (-0.2, 0.39), (-0.2, 0.45), (0.22, 0.47)], plan=[(-0.23, -0.3), (0.23, -0.3), (0.23, 0.28), (-0.23, 0.28)], bevel=0.02, segments=3)
    carve(m, "pad", side=[(-0.27, 0.46), (-0.33, 0.9), (-0.29, 0.91), (-0.22, 0.47)], plan=[(-0.22, -0.4), (0.22, -0.4), (0.22, 0.1), (-0.22, 0.1)], bevel=0.02, segments=3)
    # Bracket to the beam.
    box(m, "steel", (0.08, 0.3, 0.05), loc=(0, -0.05, 0.3), bevel=0.01)
    return m.finish(smooth_angle=30.0)


def gate_arm():
    m = bkit.Model("gate_arm")
    box(m, "shell", (0.05, 0.42, 0.04), loc=(0, 0.0, 0.52), bevel=0.018, segments=3)
    tube_path(m, "steel", [(0, -0.12, 0.3), (0, -0.12, 0.5)], 0.016, segs=8)
    tube_path(m, "steel", [(0, 0.12, 0.3), (0, 0.15, 0.5)], 0.016, segs=8)
    return m.finish(smooth_angle=30.0)


def gate_leg():
    m = bkit.Model("gate_leg")
    box(m, "steel", (0.07, 0.07, 0.24), loc=(0, -0.05, 0.14), bevel=0.01)
    carve(m, "steel", side=[(-0.32, 0.0), (0.28, 0.0), (0.28, 0.02), (0.05, 0.05), (-0.15, 0.05), (-0.32, 0.02)], plan=[(-0.045, -0.4), (0.045, -0.4), (0.045, 0.4), (-0.045, 0.4)], bevel=0.008)
    for y in (-0.3, 0.26):
        cyl(m, "black", 0.03, 0.012, loc=(0, y, 0.006), segs=10)
    return m.finish(smooth_angle=30.0)


def gate_beam():
    m = bkit.Model("gate_beam")
    box(m, "steel", (1.0, 0.09, 0.07), loc=(0, -0.05, 0.27), bevel=0.012)
    return m.finish(smooth_angle=30.0)


def planter():
    m = bkit.Model("planter")
    carve(m, "concrete", front=[(-0.56, 0.04), (0.56, 0.04), (0.6, 0.78), (-0.6, 0.78)], side=[(-0.56, 0.04), (0.56, 0.04), (0.6, 0.78), (-0.6, 0.78)], bevel=0.02)
    box(m, "concrete_dark", (1.26, 1.26, 0.06), loc=(0, 0, 0.8), bevel=0.015)
    box(m, "soil", (1.1, 1.1, 0.04), loc=(0, 0, 0.82), bevel=0.01)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, "concrete_dark", (0.2, 0.2, 0.05), loc=(sx * 0.45, sy * 0.45, 0.025), bevel=0.01)
    # Board-formed lines in the concrete.
    for sx in (-1, 1):
        for k in range(3):
            z = 0.22 + k * 0.2
            r = 0.56 + 0.04 * (z - 0.04) / 0.74
            box(m, "concrete_dark", (0.006, 2 * r, 0.008), loc=(sx * (r + 0.002), 0, z))
            box(m, "concrete_dark", (2 * r, 0.006, 0.008), loc=(0, sx * (r + 0.002), z))
    return m.finish(smooth_angle=30.0)


def drum():
    m = bkit.Model("drum")
    r = 0.36
    prof = [(0.0005, 0.02), (r - 0.02, 0.02), (r - 0.005, 0.0), (r + 0.005, 0.01), (r, 0.04)]
    for zc in (0.33, 0.67):
        prof += [(r, zc - 0.03), (r + 0.015, zc - 0.012), (r + 0.015, zc + 0.012), (r, zc + 0.03)]
    prof += [(r, 0.96), (r + 0.005, 0.99), (r - 0.005, 1.0), (r - 0.02, 0.98), (0.0005, 0.98)]
    lathe(m, "paint", prof, segs=32)
    for x, rr in ((0.18, 0.04), (-0.2, 0.025)):
        cyl(m, "steel", rr, 0.02, loc=(x, 0.05, 0.99), segs=12)
    lathe(m, "label", [(r + 0.002, 0.42), (r + 0.002, 0.58)], segs=32)
    return m.finish(smooth_angle=40.0)


def litter_bin():
    m = bkit.Model("bin")
    lathe(m, "paint", [(0.0005, 0.0), (0.29, 0.0), (0.3, 0.02), (0.32, 0.86), (0.33, 0.88), (0.31, 0.88)], segs=28)
    for k in range(6):
        z = 0.12 + k * 0.13
        lathe(m, "paint_dark", [(0.3 + z * 0.023 + 0.004, z), (0.3 + z * 0.023 + 0.004, z + 0.02)], segs=28)
    lathe(m, "lid", [(0.0005, 0.98), (0.12, 0.97), (0.3, 0.92), (0.34, 0.9), (0.34, 0.87), (0.3, 0.87)], segs=28)
    box(m, "black", (0.22, 0.04, 0.09), loc=(0, 0.3, 0.92), rot=(-25, 0, 0), bevel=0.01)
    return m.finish(smooth_angle=40.0)


# -------------------------------------------------------------- airliner

def engine():
    """Turbofan nacelle along +Y (intake forward), centre at the origin,
    with its pylon rising to the wing."""
    m = bkit.Model("engine")
    lathe(m, "skin", [(0.82, 2.35), (0.96, 2.45), (1.02, 2.3), (1.03, 1.2), (0.98, 0.0), (0.88, -1.4), (0.8, -1.6)], segs=40, rot=(-90, 0, 0))
    lathe(m, "lip", [(0.8, 2.3), (0.84, 2.44), (0.96, 2.47), (1.0, 2.4)], segs=40, rot=(-90, 0, 0))
    # Closed solids behind the fan and in the nozzle, so no face can turn
    # its back to the camera.
    cyl(m, "dark", 0.81, 0.5, loc=(0, 1.64, 0), rot=(90, 0, 0), segs=40)
    # Fan blades and the spinner.
    # Fan: 30 blades, narrow at the root and broad at the tip, pitched.
    for i in range(30):
        a = 360 * i / 30
        mat = Matrix.Translation((0, 1.95, 0)) @ Matrix.Rotation(math.radians(-a), 4, "Y") @ Matrix.Rotation(math.radians(50), 4, "X")
        b = bkit.Model("_blade")
        prism(b, "fan", [(0.2, -0.04), (0.79, -0.11), (0.79, 0.11), (0.2, 0.04)], "z", -0.006, 0.006)
        m.merge(b, mat)
        b.bm.free()
    lathe(m, "spinner", [(0.24, 1.9), (0.22, 2.05), (0.14, 2.2), (0.0005, 2.3)], segs=24, rot=(-90, 0, 0))
    # Core exhaust nozzle and plug.
    lathe(m, "lip", [(0.8, -1.6), (0.62, -1.75), (0.58, -2.05)], segs=32, rot=(-90, 0, 0))
    cyl(m, "dark", 0.57, 0.4, loc=(0, -1.85, 0), rot=(90, 0, 0), segs=32)
    lathe(m, "lip", [(0.38, -2.0), (0.3, -2.4), (0.0005, -2.7)], segs=24, rot=(-90, 0, 0))
    # Pylon up to the wing.
    prism(m, "skin", [(1.7, 0.8), (-2.3, 0.8), (-2.6, 0.95), (-2.4, 1.05), (2.3, 1.05), (2.4, 0.95)], "x", -0.12, 0.12, bevel=0.03)
    box(m, "skin", (0.24, 3.2, 0.14), loc=(0, -0.2, 0.92), bevel=0.04)
    # Fan cowl seam lines.
    for y in (1.2, -0.6):
        lathe(m, "seam", [(1.032 if y > 0 else 0.97, y - 0.008), (1.032 if y > 0 else 0.97, y + 0.008)], segs=40, rot=(-90, 0, 0))
    return m.finish(smooth_angle=35.0)


def gear():
    m = bkit.Model("gear")
    tube_path(m, "steel", [(0, 0, 0.55), (0, 0, 2.0)], 0.12, segs=14)
    tube_path(m, "chrome", [(0, 0, 0.55), (0, 0, 1.1)], 0.08, segs=12)
    tube_path(m, "steel", [(0, 0.0, 1.6), (0, -0.7, 2.2)], 0.05, segs=10)
    box(m, "steel", (0.9, 0.16, 0.14), loc=(0, 0, 0.55), bevel=0.03)
    box(m, "black", (0.2, 0.3, 0.2), loc=(0, 0.1, 0.9), bevel=0.03)
    w = make_wheel(0.55, 0.4)
    for sx in (-1, 1):
        put_wheel(m, w, sx * 0.48, 0, 0.55)
    return m.finish(smooth_angle=35.0)


def main():
    bkit.reset()
    objs = [box_closed(), box_open(), uld(), baggage_cart(), suitcase_hard(), suitcase_soft(), duffel(), cone(), barrier(),
            gate_seat(), gate_arm(), gate_leg(), gate_beam(), planter(), drum(), litter_bin(), engine(), gear()]
    bkit.export("props.glb", objs)


if __name__ == "__main__":
    main()
