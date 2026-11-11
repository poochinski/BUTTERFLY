"""A Blender twin of the game's GunBuilder.Kit.

It takes exactly the same arguments as the GDScript kit and works in
*Godot* gun space (forward = -Z as "f", up = +Y, right = +X), so the
modelled guns line up with every hand position, sight height, muzzle and
magazine the game already uses. Each primitive becomes real geometry with
bevelled edges and smooth shading, converted to Blender space on the way
in (Godot (x, y, z) -> Blender (x, -z, y)).
"""

import math

import bpy  # noqa: F401  (must load before bmesh)
import bmesh
from mathutils import Matrix, Vector

import bkit

PI = math.pi
TAU = math.tau

# Godot -> Blender basis change, and back.
C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
CI = C.transposed()


def tg(pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1)):
    """A Godot transform: translation, Euler YXZ (radians), scale."""
    r = Matrix.Rotation(rot[1], 4, "Y") @ Matrix.Rotation(rot[0], 4, "X") @ Matrix.Rotation(rot[2], 4, "Z")
    return Matrix.Translation(Vector(pos)) @ r @ Matrix.Diagonal((scl[0], scl[1], scl[2], 1.0))


def _obj_from_bm(bm, bevel=0.0, segments=2, angle=35.0):
    me = bpy.data.meshes.new("_g")
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new("_g", me)
    bpy.context.scene.collection.objects.link(obj)
    if bevel > 0.0:
        m = obj.modifiers.new("Bevel", "BEVEL")
        m.width = bevel
        m.segments = segments
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(angle)
        m.harden_normals = False
    return obj


class V2:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def lerp(self, o, t):
        return V2(self.x + (o.x - self.x) * t, self.y + (o.y - self.y) * t)


class Kit:
    def __init__(self):
        self.att = ""

    # -- raw primitives in Godot space -------------------------------
    def _native(self, model, bm, mat, m_godot, bevel=0.0, segments=2):
        """bm holds a Blender-native primitive standing for a Godot one."""
        obj = _obj_from_bm(bm, bevel, segments)
        model.add_object(obj, mat, C @ m_godot @ CI)

    def _godot_verts(self, model, bm, mat, m_godot, bevel=0.0, segments=2):
        """bm holds vertices already in Godot-local coordinates."""
        obj = _obj_from_bm(bm, bevel, segments)
        model.add_object(obj, mat, C @ m_godot)

    def cylinder(self, model, top, bottom, h, mat, pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1), segs=16, bevel=None):
        """Godot CylinderMesh (along Y, top radius at +Y)."""
        bm = bmesh.new()
        segs = max(segs, 12)
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=bottom, radius2=top, depth=h)
        if bevel is None:
            bevel = min(0.0015, max(min(top, bottom), 0.001) * 0.15, h * 0.2)
        self._native(model, bm, mat, tg(pos, rot, scl), bevel=bevel)

    def sphere(self, model, r, mat, pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1), segs=16):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=max(segs, 12), v_segments=max(segs // 2, 8), radius=r)
        self._native(model, bm, mat, tg(pos, rot, scl))

    def torus_ring(self, model, radius, thick, mat, pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1)):
        """Godot TorusMesh(inner = radius - thick, outer = radius) round Y."""
        rmaj = radius - thick * 0.5
        rmin = thick * 0.5
        bm = bmesh.new()
        segs, msegs = 28, 8
        verts = []
        for i in range(segs):
            a = TAU * i / segs
            for j in range(msegs):
                b = TAU * j / msegs
                verts.append(bm.verts.new(((rmaj + rmin * math.cos(b)) * math.cos(a), (rmaj + rmin * math.cos(b)) * math.sin(a), rmin * math.sin(b))))
        for i in range(segs):
            for j in range(msegs):
                a = i * msegs + j
                b2 = ((i + 1) % segs) * msegs + j
                c = ((i + 1) % segs) * msegs + (j + 1) % msegs
                d = i * msegs + (j + 1) % msegs
                bm.faces.new((verts[a], verts[b2], verts[c], verts[d]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        self._native(model, bm, mat, tg(pos, rot, scl))

    def open_tube(self, model, radius, length, mat, pos=(0, 0, 0), rot=(0, 0, 0), inward=False, segs=24):
        """Godot Craft.tube: an open-ended tube along local +X."""
        bm = bmesh.new()
        ring0, ring1 = [], []
        for i in range(segs):
            a = TAU * i / segs
            y, z = math.cos(a) * radius, math.sin(a) * radius
            ring0.append(bm.verts.new((-length * 0.5, y, z)))
            ring1.append(bm.verts.new((length * 0.5, y, z)))
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new((ring0[i], ring0[j], ring1[j], ring1[i]))
            if not inward:
                f.normal_flip()
        bm.normal_update()
        self._godot_verts(model, bm, mat, tg(pos, rot))

    def cutout(self, model, pts, depth, mat, pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1), bevel=0.0):
        """Godot Craft.cutout: polygon in XY, extruded along Z, centred."""
        bm = bmesh.new()
        poly = list(pts)
        area = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))
        if area < 0:
            poly.reverse()
        vs = [bm.verts.new((p[0], p[1], -depth * 0.5)) for p in poly]
        face = bm.faces.new(vs)
        ext = bmesh.ops.extrude_face_region(bm, geom=[face])
        moved = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, vec=(0, 0, depth), verts=moved)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        self._godot_verts(model, bm, mat, tg(pos, rot, scl), bevel=bevel)

    # -- the GunBuilder.Kit API ----------------------------------------
    def prof(self, model, pts, thick, skin, core=None, x=0.0):
        """A part cut from a side profile (forward, up), laminated: painted
        skins over a kraft core. Matches Kit.prof exactly."""
        holder = Matrix.Translation(Vector((x, 0, 0))) @ Matrix.Rotation(PI * 0.5, 4, "Y")
        bev = min(0.0018, thick * 0.08)
        if core:
            self._cut_into(model, pts, thick * 0.9, core, holder @ Matrix.Diagonal((0.995, 0.995, 1.0, 1.0)), 0.0)
            self._cut_into(model, pts, thick * 0.2, skin, holder @ Matrix.Translation(Vector((0, 0, thick * 0.4))), bev)
            self._cut_into(model, pts, thick * 0.2, skin, holder @ Matrix.Translation(Vector((0, 0, -thick * 0.4))), bev)
        else:
            self._cut_into(model, pts, thick, skin, holder, bev)

    def _cut_into(self, model, pts, depth, mat, m_godot, bevel):
        bm = bmesh.new()
        poly = list(pts)
        area = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))
        if area < 0:
            poly.reverse()
        vs = [bm.verts.new((p[0], p[1], -depth * 0.5)) for p in poly]
        face = bm.faces.new(vs)
        ext = bmesh.ops.extrude_face_region(bm, geom=[face])
        moved = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, vec=(0, 0, depth), verts=moved)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        self._godot_verts(model, bm, mat, m_godot, bevel=bevel)

    def box(self, model, f, y, size, mat, x=0.0, rot=(0, 0, 0)):
        gx, gy, gz = size
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        for v in bm.verts:
            v.co.x *= gx
            v.co.y *= gz
            v.co.z *= gy
        bev = min(0.0016, min(gx, gy, gz) * 0.22)
        self._native(model, bm, mat, tg((x, y, -f), rot), bevel=bev if bev > 0.0003 else 0.0)

    def tube(self, model, f0, f1, y, r, mat, x=0.0, segs=14):
        self.cylinder(model, r, r, f1 - f0, mat, (x, y, -(f0 + f1) * 0.5), (PI * 0.5, 0, 0), segs=max(segs, 20))

    def cone(self, model, f0, f1, y, r0, r1, mat, x=0.0, segs=16):
        self.cylinder(model, r0, r1, f1 - f0, mat, (x, y, -(f0 + f1) * 0.5), (PI * 0.5, 0, 0), segs=max(segs, 20))

    def rivet(self, model, f, y, x, r, mat):
        self.cylinder(model, r, r, r * 0.7, mat, (x, y, -f), (0, 0, PI * 0.5), segs=12)

    def pin(self, model, f, y, half_w, r=0.0045):
        self.rivet(model, f, y, half_w, r, "pin")
        self.rivet(model, f, y, -half_w, r, "pin")

    def rail(self, model, f0, f1, y, width, x=0.0, up=True):
        length = f1 - f0
        if up:
            self.box(model, (f0 + f1) * 0.5, y, (width, 0.008, length), "black", x)
        else:
            self.box(model, (f0 + f1) * 0.5, y, (0.008, width, length), "black", x)
        n = int(length / 0.012)
        for i in range(n):
            f = f0 + (i + 0.5) * length / n
            if up:
                self.box(model, f, y + 0.007, (width * 1.05, 0.006, 0.006), "black", x)
            else:
                sgn = 1.0 if x > 0 else (-1.0 if x < 0 else 0.0)
                self.box(model, f, y, (0.006, width * 1.05, 0.006), "black", x + sgn * 0.007)

    def slots(self, model, f0, f1, y, n, size, half_w):
        for i in range(n):
            f = f0 + (i + 0.5) * (f1 - f0) / n
            for side in (-1.0, 1.0):
                self.box(model, f, y, (0.002, size[1], size[0]), "rubber", side * half_w)

    def wrap(self, model, f, y, size, mat="tape", width=0.018):
        self.box(model, f, y, (size[0] + 0.004, size[1] + 0.004, width), mat)

    def sling(self, *args, **kwargs):
        """Slings stay procedural in Godot (they hang from the swivels)."""
        return None

    # -- sights, as standalone models at the mount point ----------------
    def red_dot(self, model, f=0.0, base_y=0.0):
        cy = base_y + 0.032
        self.box(model, f, base_y + 0.008, (0.03, 0.016, 0.05), "black")
        self.box(model, f, base_y + 0.018, (0.012, 0.012, 0.03), "black")
        self.box(model, f + 0.01, base_y + 0.008, (0.004, 0.01, 0.026), "black", 0.019, (0, 0.25, 0))
        hold = (0, cy, -f)
        self.open_tube(model, 0.021, 0.085, "black", hold, (0, PI * 0.5, 0))
        self.open_tube(model, 0.0195, 0.085, "rubber", hold, (0, PI * 0.5, 0), inward=True)
        for side in (-1.0, 1.0):
            # The holder's local X runs along the gun, so the end bells sit
            # fore and aft of the body.
            ox = side * 0.043
            hp = (0, cy, -f - ox)
            self.open_tube(model, 0.024, 0.012, "black", hp, (0, PI * 0.5, 0))
            self.open_tube(model, 0.0195, 0.012, "rubber", hp, (0, PI * 0.5, 0), inward=True)
            self.torus_ring(model, 0.0245, 0.003, "black", (0, cy, -f - side * 0.049), (PI * 0.5, 0, 0))
        self.cylinder(model, 0.009, 0.009, 0.012, "black", (0, cy + 0.026, -f))
        self.cylinder(model, 0.011, 0.011, 0.012, "black", (0.026, cy, -f), (0, 0, PI * 0.5))
        self.cylinder(model, 0.0195, 0.0195, 0.002, "lens_clear", (0, cy, -(f + 0.04)), (PI * 0.5, 0, 0), bevel=0.0)
        self.sphere(model, 0.0022, "glow_red", (0, cy, -(f + 0.035)))
        return cy

    def holo(self, model, f=0.0, base_y=0.0):
        cy = base_y + 0.03
        self.box(model, f, base_y + 0.006, (0.036, 0.012, 0.075), "black")
        self.box(model, f + 0.02, base_y + 0.014, (0.03, 0.01, 0.03), "black")
        self.cylinder(model, 0.008, 0.008, 0.01, "black", (0.021, base_y + 0.008, -(f - 0.02)), (0, 0, PI * 0.5))
        for i in range(2):
            self.box(model, f - 0.03 + i * 0.012, base_y + 0.014, (0.008, 0.004, 0.006), "rubber")
        for side in (-1.0, 1.0):
            self.box(model, f, cy, (0.005, 0.044, 0.07), "black", side * 0.02)
        self.box(model, f, cy + 0.024, (0.045, 0.006, 0.07), "black")
        self.box(model, f + 0.03, cy, (0.036, 0.04, 0.002), "glass")
        for i in range(20):
            a = TAU * i / 20.0
            self.sphere(model, 0.0011, "glow_red", (math.cos(a) * 0.0085, cy + math.sin(a) * 0.0085, -(f + 0.028)), segs=12)
        self.sphere(model, 0.0016, "glow_red", (0, cy, -(f + 0.028)), segs=12)
        return cy

    def acog(self, model, f=0.0, base_y=0.0):
        cy = base_y + 0.042
        self.box(model, f, base_y + 0.01, (0.03, 0.02, 0.07), "black")
        self.box(model, f, cy - 0.024, (0.026, 0.016, 0.05), "black")
        hold = (0, cy, -f)
        self.open_tube(model, 0.02, 0.09, "black", (0, cy, -f - 0.005), (0, PI * 0.5, 0))
        self.open_tube(model, 0.0185, 0.09, "rubber", (0, cy, -f - 0.005), (0, PI * 0.5, 0), inward=True)
        self.open_tube(model, 0.026, 0.035, "black", (0, cy, -f - 0.065), (0, PI * 0.5, 0))
        self.open_tube(model, 0.0245, 0.035, "rubber", (0, cy, -f - 0.065), (0, PI * 0.5, 0), inward=True)
        self.open_tube(model, 0.023, 0.02, "rubber", (0, cy, -f + 0.05), (0, PI * 0.5, 0))
        self.box(model, f - 0.01, cy + 0.024, (0.012, 0.006, 0.05), "glow_red")
        self.rivet(model, f - 0.015, cy, 0.022, 0.008, "black")
        self.cylinder(model, 0.008, 0.008, 0.01, "black", (0, cy + 0.024, -(f + 0.005)))
        chev = [(-0.0035, -0.0025), (0, 0.0015), (0.0035, -0.0025), (0.0035, -0.0038), (0, 0.0002), (-0.0035, -0.0038)]
        self.cutout(model, chev, 0.0005, "glow_red", (0, cy, -(f + 0.02)))
        self.box(model, f + 0.02, cy - 0.011, (0.0012, 0.014, 0.0012), "black")
        self.cylinder(model, 0.024, 0.024, 0.002, "lens", (0, cy, -(f + 0.08)), (PI * 0.5, 0, 0), bevel=0.0)
        return cy

    def irons_rear(self, model):
        base_y = 0.0
        cy = base_y + 0.032
        self.box(model, 0, base_y + 0.012, (0.026, 0.024, 0.02), "black")
        self.box(model, 0, cy - 0.013, (0.02, 0.012, 0.01), "black")
        self.torus_ring(model, 0.008, 0.003, "black", (0, cy, 0), (PI * 0.5, 0, 0))

    def irons_front(self, model):
        base_y = 0.0
        cy = base_y + 0.032
        self.box(model, 0, base_y + 0.012, (0.022, 0.024, 0.024), "black")
        self.box(model, 0, cy - 0.004, (0.003, 0.018, 0.003), "black")
        for side in (-1.0, 1.0):
            self.box(model, 0, cy, (0.003, 0.022, 0.014), "black", side * 0.01)


def new_model(name):
    return bkit.Model(name)
