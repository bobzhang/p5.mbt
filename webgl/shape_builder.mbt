// p5's ShapeBuilder (src/webgl/ShapeBuilder.js): vertex lists from a shape
// become an immediate-mode geometry; PATH shapes are tessellated.

///|
/// How the vertices of an immediate geometry are drawn.
pub(all) enum ShapeMode {
  PathMode
  PointsMode
  LinesMode
  TrianglesMode
  TriangleFanMode
  TriangleStripMode
  QuadsMode
  QuadStripMode
}

///|
fn shape_mode(kind : @shape.ShapeKind) -> ShapeMode {
  match kind {
    Path => PathMode
    Points => PointsMode
    Lines => LinesMode
    Triangles => TrianglesMode
    TriangleFan => TriangleFanMode
    TriangleStrip => TriangleStripMode
    Quads => QuadsMode
    QuadStrip => QuadStripMode
  }
}

///|
/// Layout of `Pt.extra` for WEBGL vertices.
pub let extra_u : Int32 = 0

///|
pub let extra_normal : Int32 = 2

///|
pub let extra_fill : Int32 = 5

///|
pub let extra_stroke : Int32 = 9

///|
/// The number of extra values per WEBGL vertex.
pub let extra_size : Int32 = 13

///|
fn ex(p : @shape.Pt, i : Int32) -> Double {
  p.extra.get(i).unwrap_or(0)
}

///|
fn calculate_edges(
  mode : ShapeMode,
  verts : Array[Vec3],
  contour_indices : Array[Int32],
) -> Array[(Int32, Int32)] {
  let res : Array[(Int32, Int32)] = []
  let n = verts.length()
  match mode {
    TriangleStripMode => {
      let mut i = 0
      while i < n - 2 {
        res.push((i, i + 1))
        res.push((i, i + 2))
        i += 1
      }
      res.push((i, i + 1))
    }
    TriangleFanMode => {
      let mut i = 1
      while i < n - 1 {
        res.push((0, i))
        res.push((i, i + 1))
        i += 1
      }
      res.push((0, n - 1))
    }
    TrianglesMode => {
      let mut i = 0
      while i < n - 2 {
        res.push((i, i + 1))
        res.push((i + 1, i + 2))
        res.push((i + 2, i))
        i += 3
      }
    }
    LinesMode => {
      let mut i = 0
      while i < n - 1 {
        res.push((i, i + 1))
        i += 2
      }
    }
    QuadsMode => {
      let mut i = 0
      while i < n - 5 {
        res.push((i, i + 1))
        res.push((i + 1, i + 2))
        res.push((i + 2, i + 5))
        res.push((i + 5, i))
        i += 6
      }
    }
    QuadStripMode => {
      let mut i = 0
      while i < n - 2 {
        res.push((i, i + 1))
        res.push((i + 1, i + 3))
        res.push((i, i + 2))
        i += 2
      }
      res.push((i, i + 1))
    }
    PathMode | PointsMode => {
      let starts = contour_indices.copy()
      let mut start = -1
      for i in 0..<n {
        if starts.length() > 0 && i == starts[0] {
          start = starts.remove(0)
        } else if start >= 0 &&
          start < n &&
          verts[i].x == verts[start].x &&
          verts[i].y == verts[start].y &&
          verts[i].z == verts[start].z {
          res.push((i - 1, start))
        } else {
          res.push((i - 1, i))
        }
      }
    }
  }
  res
}

///|
/// Builds the immediate geometry for `contours` (`constructFromContours`).
/// Returns the draw mode after tessellation/conversion.
pub fn build_immediate(
  g : Geometry,
  kind : @shape.ShapeKind,
  contours : Array[Array[@shape.Pt]],
  has_fill : Bool,
  has_stroke : Bool,
  simple_lines : Bool,
  building~ : Bool = false,
  user_layout~ : Array[(String, Int32)] = [],
) -> ShapeMode {
  g.user_props.clear()
  for l in user_layout {
    g.user_props.push({ name: l.0, size: l.1, data: [], })
  }
  g.vertices.clear()
  g.vertex_normals.clear()
  g.uvs.clear()
  g.faces.clear()
  g.edges.clear()
  g.vertex_colors.clear()
  g.vertex_stroke_colors.clear()
  g.line_vertex_colors.clear()
  g.dirty = true
  let mut mode = shape_mode(kind)
  let contour_indices : Array[Int32] = []
  for contour in contours {
    contour_indices.push(g.vertices.length())
    for p in contour {
      if mode is QuadsMode && g.vertices.length() % 6 == 3 {
        let n = g.vertices.length()
        g.vertices.push(g.vertices[n - 3])
        g.vertices.push(g.vertices[n - 1])
        g.vertex_normals.push(g.vertex_normals[n - 3])
        g.vertex_normals.push(g.vertex_normals[n - 1])
        for
          (arr, stride) in [
            (g.vertex_colors, 4),
            (g.vertex_stroke_colors, 4),
            (g.uvs, 2),
          ] +
          g.user_props.map(u => (u.data, u.size)) {
          let len = arr.length()
          let a = arr[len - 3 * stride:len - 2 * stride].to_owned()
          let b = arr[len - stride:len].to_owned()
          arr.append(a)
          arr.append(b)
        }
      }
      g.vertices.push(Vec3::new(p.x, p.y, p.z))
      g.vertex_normals.push(
        Vec3::new(
          ex(p, extra_normal),
          ex(p, extra_normal + 1),
          ex(p, extra_normal + 2),
        ),
      )
      g.uvs.push(ex(p, extra_u))
      g.uvs.push(ex(p, extra_u + 1))
      let mut off = extra_size
      for u in g.user_props {
        for k in 0..<u.size {
          u.data.push(ex(p, off + k))
        }
        off += u.size
      }
      for k in 0..<4 {
        g.vertex_colors.push(if has_fill { ex(p, extra_fill + k) } else { 0 })
      }
      for k in 0..<4 {
        g.vertex_stroke_colors.push(
          if has_stroke {
            ex(p, extra_stroke + k)
          } else {
            0
          },
        )
      }
    }
  }
  if has_stroke {
    for e in calculate_edges(mode, g.vertices, contour_indices) {
      g.edges.push(e)
    }
    if !building {
      ignore(g.edges_to_vertices(simple_lines~))
    }
  }
  match mode {
    PathMode =>
      if tessellate_into(g, contour_indices, building) {
        mode = TrianglesMode
      }
    QuadStripMode => mode = TriangleStripMode
    QuadsMode => mode = TrianglesMode
    _ => ()
  }
  mode
}

///|
fn tessellate_into(
  g : Geometry,
  contour_indices : Array[Int32],
  building : Bool,
) -> Bool {
  let original = g.vertices.copy()
  let mut stride = 12
  for u in g.user_props {
    stride += u.size
  }
  let contours : Array[Array[FixedArray[Double]]] = []
  let starts = contour_indices.copy()
  for i, v in g.vertices {
    if starts.length() > 0 && starts[0] == i {
      ignore(starts.remove(0))
      contours.push([])
    }
    let n = g.vertex_normals[i]
    let row = FixedArray::make(stride, 0.0)
    let base : FixedArray[Double] = [
      v.x,
      v.y,
      v.z,
      g.uvs[i * 2],
      g.uvs[i * 2 + 1],
      g.vertex_colors[i * 4],
      g.vertex_colors[i * 4 + 1],
      g.vertex_colors[i * 4 + 2],
      g.vertex_colors[i * 4 + 3],
      n.x,
      n.y,
      n.z,
    ]
    for k in 0..<12 {
      row[k] = base[k]
    }
    let mut off = 12
    for u in g.user_props {
      for k in 0..<u.size {
        row[off + k] = u.data[i * u.size + k]
      }
      off += u.size
    }
    contours[contours.length() - 1].push(row)
  }
  // snap nearly identical consecutive coordinates, like p5
  for c in contours {
    for i in 1..<c.length() {
      if (c[i][0] - c[i - 1][0]).abs() < 1.0e-6 {
        c[i][0] = c[i - 1][0]
      }
      if (c[i][1] - c[i - 1][1]).abs() < 1.0e-6 {
        c[i][1] = c[i - 1][1]
      }
    }
  }
  let flat = libtess_triangulate(contours, stride)
  if flat.is_empty() {
    return false
  }
  g.vertices.clear()
  g.vertex_normals.clear()
  g.uvs.clear()
  g.vertex_colors.clear()
  for u in g.user_props {
    u.data.clear()
  }
  for j = 0; j + stride <= flat.length(); j = j + stride {
    let mut off = j + 12
    for u in g.user_props {
      for k in 0..<u.size {
        u.data.push(flat[off + k])
      }
      off += u.size
    }
    for k in 5..<9 {
      g.vertex_colors.push(flat[j + k])
    }
    g.vertex_normals.push(Vec3::new(flat[j + 9], flat[j + 10], flat[j + 11]))
    g.vertices.push(Vec3::new(flat[j], flat[j + 1], flat[j + 2]))
    g.uvs.push(flat[j + 3])
    g.uvs.push(flat[j + 4])
  }
  if building {
    // map edges to the tessellated vertices (exact match, else closest)
    let remap : Map[Int32, Int32] = Map([])
    let find = (orig : Int32) => {
      match remap.get(orig) {
        Some(i) => i
        None => {
          let o = original[orig]
          let mut found = -1
          for i, v in g.vertices {
            if found < 0 && o.x == v.x && o.y == v.y && o.z == v.z {
              found = i
            }
          }
          if found < 0 {
            let mut best = @double.infinity
            found = 0
            for i, v in g.vertices {
              let dx = o.x - v.x
              let dy = o.y - v.y
              let dz = o.z - v.z
              let d = dx * dx + dy * dy + dz * dz
              if d < best {
                best = d
                found = i
              }
            }
          }
          remap[orig] = found
          found
        }
      }
    }
    let edges = g.edges.map(e => (find(e.0), find(e.1)))
    g.edges.clear()
    g.edges.append(edges)
  }
  true
}
