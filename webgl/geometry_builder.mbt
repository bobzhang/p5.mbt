// p5's GeometryBuilder (src/webgl/GeometryBuilder.js): while building,
// drawn shapes and models are collected into one geometry with the model
// matrix applied. (Per-material parts are not split out yet.)

///|
priv struct GeometryBuilder {
  geometry : Geometry
}

///|
let next_builder_id : Ref[Int32] = Ref(0)

///|
/// Starts collecting drawn shapes into a geometry (`beginGeometry`).
pub fn Renderer3D::begin_geometry(self : Renderer3D) -> Unit {
  self.push()
  self.state.model = @math.Matrix::new(4)
  let g = Geometry::new()
  g.gid = "_p5_GeometryBuilder_\{next_builder_id.val}"
  next_builder_id.val += 1
  self.builder = Some({ geometry: g, })
}

///|
/// Finishes collecting and returns the geometry (`endGeometry`).
pub fn Renderer3D::end_geometry(self : Renderer3D) -> Geometry {
  self.pop()
  match self.builder {
    Some(b) => {
      self.builder = None
      b.geometry
    }
    None => Geometry::new()
  }
}

///|
fn is_identity(m : @math.Matrix) -> Bool {
  let id = @math.Matrix::new(4)
  for i in 0..<16 {
    if m.get(i) != id.get(i) {
      return false
    }
  }
  true
}

///|
fn Renderer3D::builder_add(
  self : Renderer3D,
  input : Geometry,
  faces : Array[(Int32, Int32, Int32)],
  style : Style,
) -> Unit {
  guard self.builder is Some(b) else { return }
  let out = b.geometry
  let model = self.state.model
  let has_transform = !is_identity(model)
  let normal_m = @math.Matrix::new(3)
  if has_transform {
    ignore(normal_m.inverse_transpose4x4(model))
  }
  let start = out.vertices.length()
  for v in input.vertices {
    if has_transform {
      let (x, y, z, _) = model.multiply_vec4(v.x, v.y, v.z, 1)
      out.vertices.push(Vec3::new(x, y, z))
    } else {
      out.vertices.push(v)
    }
  }
  for n in input.vertex_normals {
    if has_transform {
      let m = (i : Int32) => normal_m.get(i)
      out.vertex_normals.push(
        Vec3::new(
          0.0 + m(0) * n.x + m(3) * n.y + m(6) * n.z,
          0.0 + m(1) * n.x + m(4) * n.y + m(7) * n.z,
          0.0 + m(2) * n.x + m(5) * n.y + m(8) * n.z,
        ),
      )
    } else {
      out.vertex_normals.push(n)
    }
  }
  out.uvs.append(input.uvs)
  if style.fill is Some(_) {
    for f in faces {
      out.faces.push((f.0 + start, f.1 + start, f.2 + start))
    }
  }
  if style.stroke is Some(_) {
    for e in input.edges {
      out.edges.push((e.0 + start, e.1 + start))
    }
  }
  let colors = input.vertex_colors.copy()
  let fill = style.fill.unwrap_or([0, 0, 0, 0])
  while colors.length() < input.vertices.length() * 4 {
    for k in 0..<4 {
      colors.push(fill[k])
    }
  }
  out.vertex_colors.append(colors)
  out.dirty = true
}

///|
/// Faces for an immediate shape in the builder (`addImmediate`).
fn immediate_faces(
  g : Geometry,
  mode : ShapeMode,
  has_fill : Bool,
) -> Array[(Int32, Int32, Int32)] {
  let faces : Array[(Int32, Int32, Int32)] = []
  if !has_fill {
    return faces
  }
  let n = g.vertices.length()
  match mode {
    TriangleStripMode | QuadStripMode =>
      for i in 2..<n {
        if i % 2 == 0 {
          faces.push((i, i - 1, i - 2))
        } else {
          faces.push((i, i - 2, i - 1))
        }
      }
    TriangleFanMode =>
      for i in 2..<n {
        faces.push((0, i - 1, i))
      }
    TrianglesMode => {
      let mut i = 0
      while i < n {
        faces.push((i, i + 1, i + 2))
        i += 3
      }
    }
    _ => ()
  }
  faces
}
