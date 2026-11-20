// More of p5.Geometry: bounding boxes, normal clean-up for generated
// meshes, tangents for normal maps, custom vertex properties and export to
// OBJ and STL.

///|
/// A geometry's axis-aligned bounds (`calculateBoundingBox`).
#derive(Debug)
pub struct BoundingBox {
  min : Vec3
  max : Vec3
  size : Vec3
  /// The center of the box.
  offset : Vec3
}

///|
/// The smallest box containing every vertex. Like p5, the starting maximum
/// is the smallest positive number, so a mesh entirely below zero on an
/// axis reports a maximum of about 5e-324 there.
pub fn Geometry::calculate_bounding_box(self : Geometry) -> BoundingBox {
  let big = 1.7976931348623157e308
  let tiny = 5.0e-324
  let mn = Vec3::new(big, big, big)
  let mx = Vec3::new(tiny, tiny, tiny)
  for v in self.vertices {
    mn.x = mn.x.min(v.x)
    mn.y = mn.y.min(v.y)
    mn.z = mn.z.min(v.z)
    mx.x = mx.x.max(v.x)
    mx.y = mx.y.max(v.y)
    mx.z = mx.z.max(v.z)
  }
  {
    min: mn,
    max: mx,
    size: Vec3::new(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z),
    offset: Vec3::new((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, (mn.z + mx.z) / 2),
  }
}

///|
/// Removes the per-vertex fill colors, so the fill color is used
/// (`clearColors`).
pub fn Geometry::clear_colors(self : Geometry) -> Geometry {
  self.vertex_colors.clear()
  self.dirty = true
  self
}

///|
/// Builds stroke edges from the triangle faces (`makeEdgesFromFaces`).
pub fn Geometry::make_edges_from_faces(self : Geometry) -> Geometry {
  self.make_triangle_edges()
}

///|
/// For grid meshes whose first and last columns meet (like a sphere's
/// seam): averages their normals so no seam shows (`averageNormals`).
pub fn Geometry::average_normals(self : Geometry) -> Geometry {
  let offset = self.detail_x + 1
  for i in 0..<=self.detail_y {
    let a = self.vertex_normals[i * offset]
    let b = self.vertex_normals[i * offset + self.detail_x]
    let t = a.copy().add_(b).div_(2)
    self.vertex_normals[i * offset] = t
    self.vertex_normals[i * offset + self.detail_x] = t
  }
  self.dirty = true
  self
}

///|
/// For grid meshes with poles: averages the normals of the first and last
/// rows (`averagePoleNormals`).
pub fn Geometry::average_pole_normals(self : Geometry) -> Geometry {
  let n = self.vertices.length()
  let dx = self.detail_x
  let sum = Vec3::new(0, 0, 0)
  for i in 0..<dx {
    ignore(sum.add_(self.vertex_normals[i]))
  }
  let top = sum.copy().div_(dx.to_double())
  for i in 0..<dx {
    self.vertex_normals[i] = top
  }
  let sum = Vec3::new(0, 0, 0)
  for i = n - 1; i > n - 1 - dx; i = i - 1 {
    ignore(sum.add_(self.vertex_normals[i]))
  }
  let bottom = sum.copy().div_(dx.to_double())
  for i = n - 1; i > n - 1 - dx; i = i - 1 {
    self.vertex_normals[i] = bottom
  }
  self.dirty = true
  self
}

///|
/// Computes per-vertex surface tangents from the uvs and normals, needed
/// for normal maps (`computeTangents`). Without uvs or normals the
/// tangents are cleared.
pub fn Geometry::compute_tangents(self : Geometry) -> Geometry {
  self.vertex_tangents.clear()
  self.dirty = true
  let n = self.vertices.length()
  if self.uvs.is_empty() || self.vertex_normals.is_empty() {
    return self
  }
  let tan = Array::makei(n, _ => Vec3::new(0, 0, 0))
  let bitan = Array::makei(n, _ => Vec3::new(0, 0, 0))
  let uv = (i : Int32) => {
    (self.uvs.get(i * 2).unwrap_or(0), self.uvs.get(i * 2 + 1).unwrap_or(0))
  }
  for f in self.faces {
    let (i0, i1, i2) = f
    let e1 = self.vertices[i1].copy().sub_(self.vertices[i0])
    let e2 = self.vertices[i2].copy().sub_(self.vertices[i0])
    let (u0, v0) = uv(i0)
    let (u1, v1) = uv(i1)
    let (u2, v2) = uv(i2)
    let du1 = u1 - u0
    let dv1 = v1 - v0
    let du2 = u2 - u0
    let dv2 = v2 - v0
    let denom = du1 * dv2 - du2 * dv1
    let r = if denom == 0 { 0.0 } else { 1 / denom }
    let sdir = e1.copy().mult_(dv2).sub_(e2.copy().mult_(dv1)).mult_(r)
    let tdir = e2.copy().mult_(du1).sub_(e1.copy().mult_(du2)).mult_(r)
    for idx in [i0, i1, i2] {
      ignore(tan[idx].add_(sdir))
      ignore(bitan[idx].add_(tdir))
    }
  }
  for i in 0..<n {
    let nv = self.vertex_normals.get(i).unwrap_or(Vec3::new(0, 0, 1))
    let mut t = tan[i].copy().sub_(nv.copy().mult_(nv.dot(tan[i])))
    if t.mag_sq() == 0 {
      let seed = if nv.x.abs() < 0.9 {
        Vec3::new(1, 0, 0)
      } else {
        Vec3::new(0, 1, 0)
      }
      t = seed.copy().sub_(nv.copy().mult_(nv.dot(seed)))
    }
    ignore(t.normalize_())
    let handedness = if nv.cross(t).dot(bitan[i]) < 0 { -1.0 } else { 1.0 }
    self.vertex_tangents.append([t.x, t.y, t.z, handedness])
  }
  self
}

// ---- custom vertex properties ----

///|
fn Geometry::user_prop(
  self : Geometry,
  name : String,
  size : Int32,
) -> VertexProperty {
  match self.user_props.search_by(p => p.name == name) {
    Some(i) => self.user_props[i]
    None => {
      let p = { name, size, data: [], }
      self.user_props.push(p)
      p
    }
  }
}

///|
/// Adds data for a custom vertex attribute named `name`, read in shaders as
/// `in`/`attribute` of that name (`vertexProperty`). Without `size`, `data`
/// is the value of the next vertex; with `size`, `data` holds values for
/// many vertices, `size` numbers each.
pub fn Geometry::vertex_property(
  self : Geometry,
  name : String,
  data : ArrayView[Double],
  size? : Int32,
) -> Unit {
  let prop = self.user_prop(name, size.unwrap_or(data.length()))
  prop.data.append(data.to_array())
  self.dirty = true
}

///|
/// The data of a custom vertex attribute, if the geometry has it.
pub fn Geometry::get_vertex_property(
  self : Geometry,
  name : String,
) -> VertexProperty? {
  match self.user_props.search_by(p => p.name == name) {
    Some(i) => Some(self.user_props[i])
    None => None
  }
}

// ---- export ----

///|
fn num(x : Double) -> String {
  @dom.number_to_string(x)
}

///|
/// The geometry as a Wavefront OBJ file (vertices, uvs, normals and faces).
pub fn Geometry::to_obj(self : Geometry) -> String {
  let sb = StringBuilder()
  for v in self.vertices {
    sb.write_string("v \{num(v.x)} \{num(v.y)} \{num(v.z)}\n")
  }
  for i = 0; i + 1 < self.uvs.length(); i = i + 2 {
    sb.write_string("vt \{num(self.uvs[i])} \{num(self.uvs[i + 1])}\n")
  }
  for n in self.vertex_normals {
    sb.write_string("vn \{num(n.x)} \{num(n.y)} \{num(n.z)}\n")
  }
  let has_n = self.vertex_normals.length() > 0
  let has_uv = self.uvs.length() > 0
  for f in self.faces {
    sb.write_string("f")
    for index in [f.0, f.1, f.2] {
      sb.write_string(" \{index + 1}")
      if has_n || has_uv {
        sb.write_string("/")
        if has_uv {
          sb.write_string("\{index + 1}")
        }
        sb.write_string("/")
        if has_n {
          sb.write_string("\{index + 1}")
        }
      }
    }
    sb.write_string("\n")
  }
  sb.to_string()
}

///|
fn Geometry::stl_face_normals(self : Geometry) -> Array[Vec3] {
  self.faces.map(f => {
    let a = self.vertices[f.0]
    let u = self.vertices[f.1].copy().sub_(a)
    let v = self.vertices[f.2].copy().sub_(a)
    Vec3::new(
      u.y * v.z - u.z * v.y,
      u.z * v.x - u.x * v.z,
      u.x * v.y - u.y * v.x,
    ).normalize_()
  })
}

///|
/// The geometry as an ASCII STL file; `name` goes on the `solid` line.
pub fn Geometry::to_stl(self : Geometry, name~ : String = "model") -> String {
  let normals = self.stl_face_normals()
  let sb = StringBuilder()
  sb.write_string("solid \{name}\n")
  for i, f in self.faces {
    let n = normals[i]
    sb.write_string(" facet norm \{num(n.x)} \{num(n.y)} \{num(n.z)}\n")
    sb.write_string("  outer loop\n")
    for idx in [f.0, f.1, f.2] {
      let v = self.vertices[idx]
      sb.write_string("   vertex \{num(v.x)} \{num(v.y)} \{num(v.z)}\n")
    }
    sb.write_string("  endloop\n")
    sb.write_string(" endfacet\n")
  }
  sb.write_string("endsolid \{name}\n")
  sb.to_string()
}

///|
/// The geometry as a binary STL file.
pub fn Geometry::to_stl_binary(self : Geometry) -> FixedArray[Byte] {
  let normals = self.stl_face_normals()
  let n = self.faces.length()
  let out = FixedArray::make(80 + 4 + n * 50, b'\x00')
  let put32 = (off : Int32, v : UInt32) => {
    out[off] = (v & 0xFF).to_byte()
    out[off + 1] = ((v >> 8) & 0xFF).to_byte()
    out[off + 2] = ((v >> 16) & 0xFF).to_byte()
    out[off + 3] = ((v >> 24) & 0xFF).to_byte()
  }
  let putf = (off : Int32, x : Double) => {
    put32(off, Float::from_double(x).reinterpret_as_uint())
  }
  put32(80, n.reinterpret_as_uint())
  let mut off = 84
  for i, f in self.faces {
    let nv = normals[i]
    putf(off, nv.x)
    putf(off + 4, nv.y)
    putf(off + 8, nv.z)
    off += 12
    for idx in [f.0, f.1, f.2] {
      let v = self.vertices[idx]
      putf(off, v.x)
      putf(off + 4, v.y)
      putf(off + 8, v.z)
      off += 12
    }
    off += 2
  }
  out
}

///|
/// Downloads the geometry as an OBJ file (`saveObj`).
pub fn Geometry::save_obj(
  self : Geometry,
  filename~ : String = "model.obj",
) -> Unit {
  @dom.download_text(self.to_obj(), filename, "text/plain")
}

///|
/// Downloads the geometry as an STL file, ASCII by default (`saveStl`).
pub fn Geometry::save_stl(
  self : Geometry,
  filename~ : String = "model.stl",
  binary~ : Bool = false,
) -> Unit {
  if binary {
    @dom.download_bytes(self.to_stl_binary(), filename, "text/plain")
  } else {
    let name = match filename.rev_find(".") {
      Some(i) => String::from_array(filename.to_array()[:i])
      None => ""
    }
    @dom.download_text(self.to_stl(name~), filename, "text/plain")
  }
}
