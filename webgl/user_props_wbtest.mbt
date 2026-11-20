///|
test "user vertex properties follow their vertices" {
  let g = Geometry::new()
  let pts : Array[@shape.Pt] = []
  for i in 0..<4 {
    let extra = FixedArray::make(extra_size + 1, 0.0)
    extra[extra_size] = i.to_double() * 10
    pts.push({ x: i.to_double(), y: (i % 2).to_double(), z: 0, extra, })
  }
  ignore(
    build_immediate(g, TriangleStrip, [pts], true, false, false, user_layout=[
      ("aProgress", 1),
    ]),
  )
  inspect(
    g.vertices.map(v => v.x),
    content=(
      #|[0, 1, 2, 3]
    ),
  )
  inspect(
    g.user_props[0].data,
    content=(
      #|[0, 10, 20, 30]
    ),
  )
}

///|
test "geometry tools" {
  let g = Geometry::new()
  g.vertices.push(Vec3::new(0, 0, 0))
  g.vertices.push(Vec3::new(10, 0, 0))
  g.vertices.push(Vec3::new(0, 20, -5))
  g.faces.push((0, 1, 2))
  g.uvs.append([0, 0, 1, 0, 0, 1])
  ignore(g.compute_normals())
  let bb = g.calculate_bounding_box()
  inspect(
    (bb.size.x, bb.size.y, bb.size.z, bb.offset.x, bb.offset.y),
    content=(
      #|(10, 20, 5, 5, 10)
    ),
  )
  inspect(
    g.to_obj(),
    content=(
      #|v 0 0 0
      #|v 10 0 0
      #|v 0 20 -5
      #|vt 0 0
      #|vt 1 0
      #|vt 0 1
      #|vn 0 0.24253562503633297 0.9701425001453319
      #|vn 0 0.24253562503633297 0.9701425001453319
      #|vn 0 0.24253562503633297 0.9701425001453319
      #|f 1/1/1 2/2/2 3/3/3
      #|
    ),
  )
  inspect(
    g.to_stl(name="tri"),
    content=(
      #|solid tri
      #| facet norm 0 0.24253562503633294 0.9701425001453318
      #|  outer loop
      #|   vertex 0 0 0
      #|   vertex 10 0 0
      #|   vertex 0 20 -5
      #|  endloop
      #| endfacet
      #|endsolid tri
      #|
    ),
  )
  inspect(
    g.to_stl_binary().length(),
    content=(
      #|134
    ),
  )
  ignore(g.compute_tangents())
  inspect(
    g.vertex_tangents.length(),
    content=(
      #|12
    ),
  )
  g.vertex_property("aId", [1, 2, 3], size=1)
  inspect(
    g.get_vertex_property("aId").map(p => p.data),
    content=(
      #|Some([1, 2, 3])
    ),
  )
}
