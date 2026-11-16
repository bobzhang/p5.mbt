// Geometry of p5's 3D primitives (src/webgl/3d_primitives.js), in unit
// size; the renderer scales them with the model matrix.

///|
let pi : Double = 3.141592653589793

///|
/// `plane|dx|dy`: a unit square in the XY plane.
pub fn plane_geometry(detail_x : Int32, detail_y : Int32) -> Geometry {
  let g = Geometry::new(detail_x~, detail_y~)
  for i in 0..<=detail_y {
    let v = i.to_double() / detail_y.to_double()
    for j in 0..<=detail_x {
      let u = j.to_double() / detail_x.to_double()
      g.vertices.push(Vec3::new(u - 0.5, v - 0.5, 0))
      g.uvs.push(u)
      g.uvs.push(v)
    }
  }
  ignore(g.compute_faces().compute_normals())
  if detail_x <= 1 && detail_y <= 1 {
    ignore(g.make_triangle_edges().edges_to_vertices())
  }
  g.gid = "plane|\{detail_x}|\{detail_y}"
  g
}

///|
/// `box|dx|dy`: a unit cube.
pub fn box_geometry(detail_x : Int32, detail_y : Int32) -> Geometry {
  let g = Geometry::new(detail_x~, detail_y~)
  let cube = [
    [0, 4, 2, 6],
    [1, 3, 5, 7],
    [0, 1, 4, 5],
    [2, 6, 3, 7],
    [0, 2, 1, 3],
    [4, 5, 6, 7],
  ]
  for
    e in [
      (0, 1),
      (1, 3),
      (3, 2),
      (6, 7),
      (8, 9),
      (9, 11),
      (14, 15),
      (16, 17),
      (17, 19),
      (18, 19),
      (20, 21),
      (22, 23),
    ] {
    g.edges.push(e)
  }
  for i, idx in cube {
    let v = i * 4
    for j in 0..<4 {
      let d = idx[j]
      g.vertices.push(
        Vec3::new(
          ((d & 1) * 2 - 1).to_double() / 2,
          ((d & 2) - 1).to_double() / 2,
          ((d & 4) / 2 - 1).to_double() / 2,
        ),
      )
      g.uvs.push((j & 1).to_double())
      g.uvs.push((j & 2).to_double() / 2)
    }
    g.faces.push((v, v + 1, v + 2))
    g.faces.push((v + 2, v + 1, v + 3))
  }
  ignore(g.compute_normals())
  if detail_x <= 4 && detail_y <= 4 {
    ignore(g.edges_to_vertices())
  }
  g.gid = "box|\{detail_x}|\{detail_y}"
  g
}

///|
/// `ellipsoid|dx|dy`: a unit sphere.
pub fn ellipsoid_geometry(detail_x : Int32, detail_y : Int32) -> Geometry {
  let g = Geometry::new(detail_x~, detail_y~)
  for i in 0..<=detail_y {
    let v = i.to_double() / detail_y.to_double()
    let phi = pi * v - pi / 2
    let cos_phi = js_cos(phi)
    let sin_phi = js_sin(phi)
    for j in 0..<=detail_x {
      let u = j.to_double() / detail_x.to_double()
      let theta = 2.0 * pi * u
      let p = Vec3::new(
        cos_phi * js_sin(theta),
        sin_phi,
        cos_phi * js_cos(theta),
      )
      g.vertices.push(p)
      g.vertex_normals.push(p)
      g.uvs.push(u)
      g.uvs.push(v)
    }
  }
  ignore(g.compute_faces())
  if detail_x <= 24 && detail_y <= 24 {
    ignore(g.make_triangle_edges().edges_to_vertices())
  }
  g.gid = "ellipsoid|\{detail_x}|\{detail_y}"
  g
}

///|
/// p5's `_truncatedCone`, shared by cylinder and cone.
fn truncated_cone(
  g : Geometry,
  bottom_radius : Double,
  top_radius : Double,
  height : Double,
  detail_x : Int32,
  detail_y : Int32,
  bottom_cap : Bool,
  top_cap : Bool,
) -> Unit {
  let bottom_radius = if bottom_radius <= 0 { 1.0 } else { bottom_radius }
  let top_radius = if top_radius < 0 { 0.0 } else { top_radius }
  let height = if height <= 0 { bottom_radius } else { height }
  let detail_x = if detail_x < 3 { 3 } else { detail_x }
  let detail_y = if detail_y < 1 { 1 } else { detail_y }
  let start = if bottom_cap { -2 } else { 0 }
  let end = detail_y + (if top_cap { 2 } else { 0 })
  let slant = js_atan2(bottom_radius - top_radius, height)
  let sin_slant = js_sin(slant)
  let cos_slant = js_cos(slant)
  for yy in start..<=end {
    let mut v = yy.to_double() / detail_y.to_double()
    let mut y = height * v
    let mut ring : Double = 0
    if yy < 0 {
      y = 0
      v = 0
      ring = bottom_radius
    } else if yy > detail_y {
      y = height
      v = 1
      ring = top_radius
    } else {
      ring = bottom_radius + (top_radius - bottom_radius) * v
    }
    if yy == -2 || yy == detail_y + 2 {
      ring = 0
    }
    y -= height / 2
    for ii in 0..<detail_x {
      let u = ii.to_double() / (detail_x - 1).to_double()
      let ur = 2.0 * pi * u
      let sur = js_sin(ur)
      let cur = js_cos(ur)
      g.vertices.push(Vec3::new(sur * ring, y, cur * ring))
      let n = if yy < 0 {
        Vec3::new(0, -1, 0)
      } else if yy > detail_y && top_radius != 0 {
        Vec3::new(0, 1, 0)
      } else {
        Vec3::new(sur * cos_slant, sin_slant, cur * cos_slant)
      }
      g.vertex_normals.push(n)
      g.uvs.push(u)
      g.uvs.push(v)
    }
  }
  let mut start_index = 0
  if bottom_cap {
    for jj in 0..<detail_x {
      let next = (jj + 1) % detail_x
      g.faces.push(
        (
          start_index + jj,
          start_index + detail_x + next,
          start_index + detail_x + jj,
        ),
      )
    }
    start_index += detail_x * 2
  }
  for _ in 0..<detail_y {
    for ii in 0..<detail_x {
      let next = (ii + 1) % detail_x
      g.faces.push(
        (start_index + ii, start_index + next, start_index + detail_x + next),
      )
      g.faces.push(
        (
          start_index + ii,
          start_index + detail_x + next,
          start_index + detail_x + ii,
        ),
      )
    }
    start_index += detail_x
  }
  if top_cap {
    start_index += detail_x
    for ii in 0..<detail_x {
      g.faces.push(
        (
          start_index + ii,
          start_index + (ii + 1) % detail_x,
          start_index + detail_x,
        ),
      )
    }
  }
}

///|
/// `cylinder|dx|dy|bottom|top`: radius 1, height 1.
pub fn cylinder_geometry(
  detail_x : Int32,
  detail_y : Int32,
  bottom_cap : Bool,
  top_cap : Bool,
) -> Geometry {
  let g = Geometry::new(detail_x~, detail_y~)
  truncated_cone(g, 1, 1, 1, detail_x, detail_y, bottom_cap, top_cap)
  if detail_x <= 24 && detail_y <= 16 {
    ignore(g.make_triangle_edges().edges_to_vertices())
  }
  g.gid = "cylinder|\{detail_x}|\{detail_y}|\{bottom_cap}|\{top_cap}"
  g
}

///|
/// `cone|dx|dy|cap`: radius 1, height 1.
pub fn cone_geometry(
  detail_x : Int32,
  detail_y : Int32,
  cap : Bool,
) -> Geometry {
  let g = Geometry::new(detail_x~, detail_y~)
  truncated_cone(g, 1, 0, 1, detail_x, detail_y, cap, false)
  if detail_x <= 24 && detail_y <= 16 {
    ignore(g.make_triangle_edges().edges_to_vertices())
  }
  g.gid = "cone|\{detail_x}|\{detail_y}|\{cap}"
  g
}

///|
/// `torus|ratio|dx|dy`: ring radius 1, tube radius `tube_ratio` (rounded to
/// 4 significant digits like p5).
pub fn torus_geometry(
  tube_ratio : Double,
  detail_x : Int32,
  detail_y : Int32,
) -> Geometry {
  let ratio = to_precision4(tube_ratio)
  let g = Geometry::new(detail_x~, detail_y~)
  for i in 0..<=detail_y {
    let v = i.to_double() / detail_y.to_double()
    let phi = 2.0 * pi * v
    let cos_phi = js_cos(phi)
    let sin_phi = js_sin(phi)
    let r = 1.0 + ratio * cos_phi
    for j in 0..<=detail_x {
      let u = j.to_double() / detail_x.to_double()
      let theta = 2.0 * pi * u
      let cos_t = js_cos(theta)
      let sin_t = js_sin(theta)
      g.vertices.push(Vec3::new(r * cos_t, r * sin_t, ratio * sin_phi))
      g.vertex_normals.push(
        Vec3::new(cos_phi * cos_t, cos_phi * sin_t, sin_phi),
      )
      g.uvs.push(u)
      g.uvs.push(v)
    }
  }
  ignore(g.compute_faces())
  if detail_x <= 24 && detail_y <= 16 {
    ignore(g.make_triangle_edges().edges_to_vertices())
  }
  g.gid = "torus|\{js_num_precision4(tube_ratio)}|\{detail_x}|\{detail_y}"
  g
}

///|
extern "js" fn js_num_precision4(x : Double) -> String = "(x) => x.toPrecision(4)"
