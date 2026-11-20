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
  debug_inspect(
    g.vertices.map(v => v.x),
    content=(
      #|[0, 1, 2, 3]
    ),
  )
  debug_inspect(
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
  debug_inspect(
    (bb.size.x, bb.size.y, bb.size.z, bb.offset.x, bb.offset.y),
    content=(
      #|(10, 20, 5, 5, 10)
    ),
  )
  debug_inspect(
    g.to_obj(),
    content=(
      #|"v 0 0 0\nv 10 0 0\nv 0 20 -5\nvt 0 0\nvt 1 0\nvt 0 1\nvn 0 0.24253562503633297 0.9701425001453319\nvn 0 0.24253562503633297 0.9701425001453319\nvn 0 0.24253562503633297 0.9701425001453319\nf 1/1/1 2/2/2 3/3/3\n"
    ),
  )
  debug_inspect(
    g.to_stl(name="tri"),
    content=(
      #|"solid tri\n facet norm 0 0.24253562503633294 0.9701425001453318\n  outer loop\n   vertex 0 0 0\n   vertex 10 0 0\n   vertex 0 20 -5\n  endloop\n endfacet\nendsolid tri\n"
    ),
  )
  debug_inspect(
    g.to_stl_binary().length(),
    content=(
      #|134
    ),
  )
  ignore(g.compute_tangents())
  debug_inspect(
    g.vertex_tangents.length(),
    content=(
      #|12
    ),
  )
  g.vertex_property("aId", [1, 2, 3], size=1)
  debug_inspect(
    g.get_vertex_property("aId").map(p => p.data),
    content=(
      #|Some([1, 2, 3])
    ),
  )
}

///|
test "mtl materials split an obj into parts" {
  let mats = parse_mtl(
    (
      #|newmtl red
      #|Kd 1 0 0
      #|Ns 30
      #|newmtl blue
      #|Kd 0 0 1
      #|d 0.5
      #|map_Bump -bm 2 bump.png
    ),
  )
  debug_inspect(
    mats.get("blue").map(m => (m.opacity, m.bump_texture_path, m.bump_scale)),
    content=(
      #|Some((Some(0.5), Some("bump.png"), Some(2)))
    ),
  )
  let g = parse_obj(
    (
      #|v 0 0 0
      #|v 1 0 0
      #|v 0 1 0
      #|v 1 1 0
      #|usemtl red
      #|f 1 2 3
      #|usemtl blue
      #|f 2 4 3
    ),
    materials=mats,
  )
  debug_inspect(
    g.vertices.length(),
    content=(
      #|6
    ),
  )
  debug_inspect(
    g.vertex_colors,
    content=(
      #|[
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  1,
      #|  0,
      #|  0,
      #|  1,
      #|  1,
      #|]
    ),
  )
  debug_inspect(
    g.parts.map(p => {
      (p.vertices.length(), p.faces, p.part_state.map(s => s.fill))
    }),
    content=(
      #|[
      #|  (3, [(0, 1, 2)], Some(Some(<FixedArray: [1, 0, 0, 1]>))),
      #|  (3, [(0, 1, 2)], Some(Some(<FixedArray: [0, 0, 1, 0.5]>))),
      #|]
    ),
  )
}
