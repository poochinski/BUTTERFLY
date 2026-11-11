"""Shared helpers for PAPERCUT's Blender model scripts.

Every model is built procedurally with bpy so it can be regenerated and
tweaked in code. Conventions:

* Author in Blender space: +X right, +Y forward, +Z up. glTF export turns
  this into Godot space (+Y up, forward = -Z), so a gun barrel modelled
  along +Y points down Godot's -Z.
* A model is a set of named primitives merged into one mesh per output
  object. Each primitive carries a material *slot name* ("felt_uniform",
  "steel", ...). Godot's ModelLib swaps each slot for the matching craft
  shader material, so the models keep the felt-and-card look.
* Modifiers (bevel, subdivision, skin, solidify) are applied per
  primitive before merging, so the exported meshes are final geometry.

Run a build script with the bpy module:
    python tools/blender/build_<thing>.py
"""

import math
import os
import sys

import bpy  # noqa: E402  (bpy must load before bmesh)
import bmesh
from mathutils import Euler, Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name):
    """A material named after its slot. The viewport colour is irrelevant:
    Godot replaces it with the craft shader material for that slot."""
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    return m


def _tmp_object(mesh):
    obj = bpy.data.objects.new("_tmp", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _evaluate(obj):
    """Apply all modifiers of obj and return a new mesh datablock."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    return bpy.data.meshes.new_from_object(ev)


def _cleanup(obj):
    mesh = obj.data
    bpy.data.objects.remove(obj, do_unlink=True)
    if mesh and mesh.users == 0:
        bpy.data.meshes.remove(mesh)


def xform(loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    """A matrix from location, Euler rotation in degrees (XYZ) and scale."""
    r = Euler([math.radians(a) for a in rot], "XYZ").to_matrix().to_4x4()
    s = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    return Matrix.Translation(Vector(loc)) @ r @ s


class Model:
    """Accumulates primitives into one mesh with named material slots."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.slots = []

    def _slot(self, mat_name):
        if mat_name not in self.slots:
            self.slots.append(mat_name)
        return self.slots.index(mat_name)

    def add_mesh(self, mesh, matrix, mat_name):
        """Append mesh data transformed by matrix, all faces in one slot."""
        idx = self._slot(mat_name)
        tmp = bmesh.new()
        tmp.from_mesh(mesh)
        bmesh.ops.transform(tmp, matrix=matrix, verts=tmp.verts)
        if matrix.determinant() < 0:
            bmesh.ops.reverse_faces(tmp, faces=tmp.faces)
        for f in tmp.faces:
            f.material_index = idx
        me = bpy.data.meshes.new("_merge")
        tmp.to_mesh(me)
        tmp.free()
        self.bm.from_mesh(me)
        bpy.data.meshes.remove(me)

    def add_object(self, obj, mat_name, matrix=None):
        """Evaluate obj (with its modifiers) and append it."""
        me = _evaluate(obj)
        m = matrix if matrix is not None else Matrix.Identity(4)
        self.add_mesh(me, m @ obj.matrix_world, mat_name)
        bpy.data.meshes.remove(me)
        _cleanup(obj)

    def finish(self, smooth_angle=40.0):
        mesh = bpy.data.meshes.new(self.name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for s in self.slots:
            mesh.materials.append(material(s))
        mesh.shade_smooth()
        if hasattr(mesh, "set_sharp_from_angle"):
            mesh.set_sharp_from_angle(angle=math.radians(smooth_angle))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


# ------------------------------------------------------------ primitives

def _with_mods(obj, bevel=0.0, bevel_segments=2, subsurf=0, solidify=0.0, bevel_angle=40.0):
    if solidify:
        m = obj.modifiers.new("Solidify", "SOLIDIFY")
        m.thickness = solidify
        m.offset = 0.0
    if bevel:
        m = obj.modifiers.new("Bevel", "BEVEL")
        m.width = bevel
        m.segments = bevel_segments
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(bevel_angle)
    if subsurf:
        m = obj.modifiers.new("Subsurf", "SUBSURF")
        m.levels = subsurf
        m.render_levels = subsurf
    return obj


def box(model, mat, size, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.004, segments=2, subsurf=0, taper=None):
    """A box of size (x, y, z). taper=(sx, sy) scales the top face, for
    wedge-ish shapes."""
    me = bpy.data.meshes.new("_box")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
        if taper and v.co.z > 0:
            v.co.x *= taper[0]
            v.co.y *= taper[1]
    bm.to_mesh(me)
    bm.free()
    obj = _with_mods(_tmp_object(me), bevel=bevel, bevel_segments=segments, subsurf=subsurf)
    obj.matrix_world = xform(loc, rot)
    model.add_object(obj, mat)


def cyl(model, mat, r, depth, loc=(0, 0, 0), rot=(0, 0, 0), segs=24, r2=None, bevel=0.0, subsurf=0, caps=True):
    """A cylinder along local Z (r2 makes a cone/frustum)."""
    me = bpy.data.meshes.new("_cyl")
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segs, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    bm.to_mesh(me)
    bm.free()
    obj = _with_mods(_tmp_object(me), bevel=bevel, subsurf=subsurf)
    obj.matrix_world = xform(loc, rot)
    model.add_object(obj, mat)


def sphere(model, mat, r, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), segs=24, rings=14, subsurf=0, shape=None):
    """A UV sphere; shape(v: Vector) -> Vector may deform each vertex."""
    me = bpy.data.meshes.new("_sph")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=r)
    if shape:
        for v in bm.verts:
            v.co = shape(v.co.copy())
    bm.to_mesh(me)
    bm.free()
    obj = _with_mods(_tmp_object(me), subsurf=subsurf)
    obj.matrix_world = xform(loc, rot, scale)
    model.add_object(obj, mat)


def torus(model, mat, r_major, r_minor, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), segs=32, minor_segs=10):
    me = bpy.data.meshes.new("_tor")
    bm = bmesh.new()
    for i in range(segs):
        a = 2 * math.pi * i / segs
        for j in range(minor_segs):
            b = 2 * math.pi * j / minor_segs
            x = (r_major + r_minor * math.cos(b)) * math.cos(a)
            y = (r_major + r_minor * math.cos(b)) * math.sin(a)
            z = r_minor * math.sin(b)
            bm.verts.new((x, y, z))
    bm.verts.ensure_lookup_table()
    for i in range(segs):
        for j in range(minor_segs):
            a = i * minor_segs + j
            b = ((i + 1) % segs) * minor_segs + j
            c = ((i + 1) % segs) * minor_segs + (j + 1) % minor_segs
            d = i * minor_segs + (j + 1) % minor_segs
            bm.faces.new((bm.verts[a], bm.verts[b], bm.verts[c], bm.verts[d]))
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    obj = _tmp_object(me)
    obj.matrix_world = xform(loc, rot, scale)
    model.add_object(obj, mat)


def skin(model, mat, nodes, edges, subsurf=2, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    """An organic shape from a skeleton: nodes are ((x, y, z), (rx, ry))
    and edges are index pairs. Skin + subdivision give smooth limbs and
    bodies with soft joints, like a moulded figure."""
    me = bpy.data.meshes.new("_skin")
    me.from_pydata([n[0] for n in nodes], edges, [])
    obj = _tmp_object(me)
    mod = obj.modifiers.new("Skin", "SKIN")
    mod.use_smooth_shade = True
    sv = me.skin_vertices[0].data
    for i, n in enumerate(nodes):
        sv[i].radius = n[1]
    sv[0].use_root = True
    if subsurf:
        s = obj.modifiers.new("Subsurf", "SUBSURF")
        s.levels = subsurf
        s.render_levels = subsurf
    obj.matrix_world = xform(loc, rot, scale)
    model.add_object(obj, mat)


def shell(model, mat, r, thickness, cut, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), segs=32, rings=16, subsurf=1):
    """A hollow dome: a sphere with everything below cut(direction) -> z
    removed, given wall thickness. Helmets, knee pads, cups."""
    me = bpy.data.meshes.new("_shell")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=r)
    kill = [v for v in bm.verts if v.co.z < cut(v.co.normalized()) * r]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(me)
    bm.free()
    obj = _with_mods(_tmp_object(me), solidify=thickness, subsurf=subsurf)
    obj.matrix_world = xform(loc, rot, scale)
    model.add_object(obj, mat)


def tube_path(model, mat, points, r, segs=10):
    """A cable or strap along a polyline of points."""
    for a, b in zip(points[:-1], points[1:]):
        a = Vector(a)
        b = Vector(b)
        d = b - a
        length = d.length
        if length < 1e-6:
            continue
        q = Vector((0, 0, 1)).rotation_difference(d.normalized())
        m = Matrix.Translation((a + b) * 0.5) @ q.to_matrix().to_4x4()
        me = bpy.data.meshes.new("_seg")
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r, radius2=r, depth=length + r)
        bm.to_mesh(me)
        bm.free()
        model.add_mesh(me, m, mat)
        bpy.data.meshes.remove(me)


def export(path_name, objects):
    """Export the given objects (and nothing else) as a binary glTF."""
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, path_name)
    for o in bpy.context.scene.objects:
        o.select_set(o in objects)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_texcoords=True,
        export_materials="EXPORT",
        export_animations=False,
    )
    tris = 0
    for o in objects:
        o.data.calc_loop_triangles()
        tris += len(o.data.loop_triangles)
    print("exported %s: %d objects, %d triangles" % (path_name, len(objects), tris))
    return path
