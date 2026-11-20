// p5.Geometry (src/webgl/p5.Geometry.js): vertices, faces, normals and the
// stroke geometry built from edges.

///|
/// How `compute_normals` shares normals between faces.
pub(all) enum NormalMode {
  /// Average over faces sharing a vertex index (p5's default).
  KeepConnections
  /// Average over faces sharing a vertex position.
  Smooth
}

///|
/// A mesh: p5.Geometry.
pub struct Geometry {
  /// Cache key for GPU buffers.
  mut gid : String
  detail_x : Int32
  detail_y : Int32
  vertices : Array[Vec3]
  vertex_normals : Array[Vec3]
  /// Flattened (u, v) pairs.
  uvs : Array[Double]
  faces : Array[(Int32, Int32, Int32)]
  edges : Array[(Int32, Int32)]
  /// Flattened RGBA per vertex (0-1); empty when the fill color is used.
  vertex_colors : Array[Double]
  vertex_stroke_colors : Array[Double]
  line_vertices : Array[Double]
  line_tangents_in : Array[Double]
  line_tangents_out : Array[Double]
  line_sides : Array[Double]
  line_vertex_colors : Array[Double]
  /// Per-vertex surface tangents for normal maps: `(x, y, z, handedness)`
  /// per vertex (see `compute_tangents`).
  vertex_tangents : Array[Double]
  /// Custom per-vertex attributes, uploaded under their names
  /// (`vertex_property`).
  user_props : Array[VertexProperty]
  /// Sub-meshes with their own materials (OBJ models with several MTL
  /// materials); empty when the geometry is drawn as a whole.
  parts : Array[Geometry]
  /// The material of this geometry or part, from its MTL file.
  mut part_state : PartState?
  priv mut dirty : Bool
}

///|
/// A custom per-vertex attribute: `size` numbers per vertex in `data`.
pub struct VertexProperty {
  name : String
  size : Int32
  data : Array[Double]
}

///|
let next_geometry_id : Ref[Int32] = Ref(0)

///|
pub fn Geometry::new(detail_x~ : Int32 = 1, detail_y~ : Int32 = 1) -> Geometry {
  let id = next_geometry_id.val
  next_geometry_id.val += 1
  {
    gid: "_p5_Geometry_\{id}",
    detail_x,
    detail_y,
    vertices: [],
    vertex_normals: [],
    uvs: [],
    faces: [],
    edges: [],
    vertex_colors: [],
    vertex_stroke_colors: [],
    line_vertices: [],
    line_tangents_in: [],
    line_tangents_out: [],
    line_sides: [],
    line_vertex_colors: [],
    vertex_tangents: [],
    user_props: [],
    parts: [],
    part_state: None,
    dirty: true,
  }
}

///|
/// Marks the GPU copy as stale after editing the arrays.
pub fn Geometry::mark_dirty(self : Geometry) -> Unit {
  self.dirty = true
}

///|
/// Grid faces for a `(detail_x + 1) × (detail_y + 1)` vertex grid.
pub fn Geometry::compute_faces(self : Geometry) -> Geometry {
  self.faces.clear()
  let slice = self.detail_x + 1
  for i in 0..<self.detail_y {
    for j in 0..<self.detail_x {
      let a = i * slice + j
      let b = i * slice + j + 1
      let c = (i + 1) * slice + j + 1
      let d = (i + 1) * slice + j
      self.faces.push((a, b, d))
      self.faces.push((d, b, c))
    }
  }
  self
}

///|
fn Geometry::face_normal(self : Geometry, f : Int32) -> Vec3 {
  let (i0, i1, i2) = self.faces[f]
  let va = self.vertices[i0]
  let vb = self.vertices[i1]
  let vc = self.vertices[i2]
  let ab = vb.copy().sub_(va)
  let ac = vc.copy().sub_(va)
  let n = ab.cross(ac)
  let ln = n.mag()
  let mut sin_alpha = ln / (ab.mag() * ac.mag())
  if sin_alpha == 0 || sin_alpha.is_nan() {
    return n
  }
  if sin_alpha > 1 {
    sin_alpha = 1
  }
  n.mult_(js_asin(sin_alpha) / ln)
}

///|
/// Computes vertex normals from the faces.
pub fn Geometry::compute_normals(
  self : Geometry,
  mode~ : NormalMode = KeepConnections,
  round_to_precision~ : Int32 = 3,
) -> Geometry {
  match mode {
    KeepConnections => {
      self.vertex_normals.clear()
      for _ in self.vertices {
        self.vertex_normals.push(Vec3::new(0, 0, 0))
      }
      for f, face in self.faces {
        let n = self.face_normal(f)
        let (a, b, c) = face
        ignore(self.vertex_normals[a].add_(n))
        ignore(self.vertex_normals[b].add_(n))
        ignore(self.vertex_normals[c].add_(n))
      }
      for n in self.vertex_normals {
        ignore(n.normalize_())
      }
    }
    Smooth => {
      let power = @cmath.pow(10, round_to_precision.to_double())
      let key = (v : Vec3) => {
        let r = (x : Double) => js_round(x * power) / power
        "\{js_num(r(v.x))},\{js_num(r(v.y))},\{js_num(r(v.z))}"
      }
      let index : Map[String, Int32] = Map([])
      let unique : Array[Int32] = []
      let to_unique : Array[Int32] = []
      for v in self.vertices {
        let k = key(v)
        match index.get(k) {
          Some(i) => to_unique.push(i)
          None => {
            index[k] = unique.length()
            to_unique.push(unique.length())
            unique.push(0)
          }
        }
      }
      let smooth = unique.map(_ => Vec3::new(0, 0, 0))
      for f, face in self.faces {
        let n = self.face_normal(f)
        let (a, b, c) = face
        for v in [a, b, c] {
          ignore(smooth[to_unique[v]].add_(n))
        }
      }
      for n in smooth {
        ignore(n.normalize_())
      }
      self.vertex_normals.clear()
      for u in to_unique {
        self.vertex_normals.push(smooth[u].copy())
      }
    }
  }
  self.dirty = true
  self
}

///|
/// Edges around every triangle (`_makeTriangleEdges`).
pub fn Geometry::make_triangle_edges(self : Geometry) -> Geometry {
  self.edges.clear()
  for face in self.faces {
    let (a, b, c) = face
    self.edges.push((a, b))
    self.edges.push((b, c))
    self.edges.push((c, a))
  }
  self
}

///|
priv struct Cap {
  point : Vec3
  dir : Vec3
  color : Array[Double]
}

///|
fn Geometry::stroke_color(self : Geometry, i : Int32) -> Array[Double] {
  if self.vertex_stroke_colors.length() > 0 {
    [
      for k in 0..<4 => self.vertex_stroke_colors.get(i * 4 + k).unwrap_or(0)
    ]
  } else {
    [0, 0, 0, 0]
  }
}

///|
/// Builds the stroke triangles' attributes from `edges` (`_edgesToVertices`):
/// a quad per segment plus caps and joins unless `simple_lines`.
pub fn Geometry::edges_to_vertices(
  self : Geometry,
  simple_lines~ : Bool = false,
) -> Geometry {
  self.line_vertices.clear()
  self.line_tangents_in.clear()
  self.line_tangents_out.clear()
  self.line_sides.clear()
  // p5 does not clear lineVertexColors here
  let caps : Map[Int32, Cap] = Map([])
  let cap_order : Array[Int32] = []
  let set_cap = (k : Int32, c : Cap) => {
    if !caps.contains(k) {
      cap_order.push(k)
    }
    caps[k] = c
  }
  let del_cap = (k : Int32) => {
    caps.remove(k)
    match cap_order.search(k) {
      Some(i) => ignore(cap_order.remove(i))
      None => ()
    }
  }
  let connected : Map[Int32, Unit] = Map([])
  let mut last_dir : Vec3? = None
  for i, curr in self.edges {
    let prev = if i > 0 { Some(self.edges[i - 1]) } else { None }
    let is_point = curr.0 == curr.1
    let begin = self.vertices[curr.0]
    let end = self.vertices[curr.1]
    let prev_color = match prev {
      Some(p) if self.vertex_stroke_colors.length() > 0 =>
        self.stroke_color(p.1)
      _ => [0.0, 0, 0, 0]
    }
    let from_color = self.stroke_color(curr.0)
    let to_color = self.stroke_color(curr.1)
    let dir = if is_point {
      Vec3::new(0, 1, 0)
    } else {
      end.copy().sub_(begin).normalize_()
    }
    let dir_ok = dir.mag_sq() > 0
    if dir_ok {
      self.add_segment(begin, end, from_color, to_color, dir, simple_lines)
    }
    if !simple_lines {
      if prev is Some(p) && p.1 == curr.0 {
        if !connected.contains(curr.0) {
          connected[curr.0] = ()
          del_cap(curr.0)
          if last_dir is Some(ld) && dir_ok && dir.dot(ld) < 1 - 1.0e-8 {
            self.add_join(begin, ld, dir, from_color)
          }
        }
      } else if is_point {
        self.add_cap(begin, dir.copy().mult_(-1), from_color)
        self.add_cap(begin, dir, from_color)
      } else {
        if dir_ok && !connected.contains(curr.0) {
          match caps.get(curr.0) {
            Some(cap) => {
              self.add_join(begin, cap.dir, dir, from_color)
              del_cap(curr.0)
              connected[curr.0] = ()
            }
            None =>
              set_cap(curr.0, {
                point: begin,
                dir: dir.copy().mult_(-1),
                color: from_color,
              })
          }
        }
        if !is_point &&
          last_dir is Some(ld) &&
          prev is Some(p) &&
          !connected.contains(p.1) {
          match caps.get(p.1) {
            Some(cap) => {
              self.add_join(
                self.vertices[p.1],
                ld,
                cap.dir.copy().mult_(-1),
                prev_color,
              )
              del_cap(p.1)
              connected[p.1] = ()
            }
            None =>
              set_cap(p.1, {
                point: self.vertices[p.1],
                dir: ld,
                color: prev_color,
              })
          }
          last_dir = None
        }
      }
      if i == self.edges.length() - 1 && !connected.contains(curr.1) {
        match caps.get(curr.1) {
          Some(cap) => {
            self.add_join(end, dir, cap.dir.copy().mult_(-1), to_color)
            del_cap(curr.1)
            connected[curr.1] = ()
          }
          None => set_cap(curr.1, { point: end, dir, color: to_color, })
        }
      }
      if dir_ok {
        last_dir = Some(dir)
      }
    }
  }
  // JS Maps iterate in insertion order
  for k in cap_order {
    if caps.get(k) is Some(cap) {
      self.add_cap(cap.point, cap.dir, cap.color)
    }
  }
  self.dirty = true
  self
}

///|
fn push3(arr : Array[Double], v : Vec3) -> Unit {
  arr.push(v.x)
  arr.push(v.y)
  arr.push(v.z)
}

///|
fn Geometry::add_segment(
  self : Geometry,
  a : Vec3,
  b : Vec3,
  from : Array[Double],
  to : Array[Double],
  dir : Vec3,
  simple : Bool,
) -> Unit {
  for s in [1.0, 1, -1, 1, -1, -1] {
    self.line_sides.push(s)
  }
  for _ in 0..<6 {
    push3(self.line_tangents_in, dir)
  }
  for _ in 0..<6 {
    push3(self.line_tangents_out, dir)
  }
  for v in [a, b, a, b, b, a] {
    push3(self.line_vertices, v)
  }
  if !simple {
    for c in [from, to, from, to, to, from] {
      self.line_vertex_colors.append(c)
    }
  }
}

///|
fn Geometry::add_cap(
  self : Geometry,
  p : Vec3,
  tangent : Vec3,
  color : Array[Double],
) -> Unit {
  for _ in 0..<6 {
    push3(self.line_vertices, p)
    push3(self.line_tangents_in, tangent)
    self.line_tangents_out.append([0.0, 0, 0])
    self.line_vertex_colors.append(color)
  }
  for s in [-1.0, 2, -2, 1, 2, -1] {
    self.line_sides.push(s)
  }
}

///|
fn Geometry::add_join(
  self : Geometry,
  p : Vec3,
  from : Vec3,
  to : Vec3,
  color : Array[Double],
) -> Unit {
  for _ in 0..<12 {
    push3(self.line_vertices, p)
    push3(self.line_tangents_in, from)
    push3(self.line_tangents_out, to)
    self.line_vertex_colors.append(color)
  }
  for s in [-1.0, -3, -2, -1, 0, -3, 3, 1, 2, 3, 0, 1] {
    self.line_sides.push(s)
  }
}

///|
/// Whether any vertex color has alpha below 1.
pub fn Geometry::has_fill_transparency(self : Geometry) -> Bool {
  for i = 3; i < self.vertex_colors.length(); i = i + 4 {
    if self.vertex_colors[i] < 1 {
      return true
    }
  }
  false
}

///|
pub fn Geometry::has_stroke_transparency(self : Geometry) -> Bool {
  for i = 3; i < self.line_vertex_colors.length(); i = i + 4 {
    if self.line_vertex_colors[i] < 1 {
      return true
    }
  }
  false
}

///|
/// Sets the cache id of the geometry.
pub fn Geometry::set_gid(self : Geometry, gid : String) -> Unit {
  self.gid = gid
}
