///|
fn cmds(s : @shape.Shape) -> String {
  to_repr(s.to_paths().path).to_string()
}

///|
test "primitives" {
  let s = @shape.Shape::new()
  s.begin_shape()
  s.line(0, 0, 10, 10)
  s.end_shape()
  debug_inspect(s.to_paths().path, content="[MoveTo(0, 0), LineTo(10, 10)]")
  s.reset()
  s.begin_shape()
  s.ellipse(0, 0, 20, 10)
  s.end_shape()
  debug_inspect(
    s.to_paths().path,
    content="[MoveTo(20, 5), Ellipse(10, 5, 10, 5, 0, 0, 6.283185307179586)]",
  )
  s.reset()
  s.begin_shape()
  s.rect(0, 0, 10, 30, radii=(20, 2, 3, 4))
  s.end_shape()
  debug_inspect(
    s.to_paths().path,
    content="[RoundRect(0, 0, 10, 30, 5, 2, 3, 4)]",
  )
}

///|
test "polyline batching and closing" {
  let s = @shape.Shape::new()
  s.begin_shape()
  s.vertex(0, 0)
  s.vertex(1, 0)
  s.vertex(1, 1)
  s.vertex(0, 1)
  s.end_shape(mode=Close)
  inspect(
    cmds(s),
    content="[MoveTo(0, 0), LineTo(1, 0), LineTo(1, 1), LineTo(0, 1), ClosePath]",
  )
}

///|
test "bezier vertices" {
  let s = @shape.Shape::new()
  s.begin_shape()
  s.bezier_vertex(0, 0)
  s.bezier_vertex(10, 0)
  s.bezier_vertex(20, 10)
  s.bezier_vertex(20, 20)
  s.bezier_vertex(20, 30)
  s.bezier_vertex(10, 40)
  s.bezier_vertex(0, 40)
  s.end_shape()
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  BezierCurveTo(10, 0, 20, 10, 20, 20),
      #|  BezierCurveTo(20, 30, 10, 40, 0, 40),
      #|]
    ),
  )
  s.reset()
  s.set_bezier_order(2)
  s.begin_shape()
  s.vertex(0, 0)
  s.bezier_vertex(5, 10)
  s.bezier_vertex(10, 0)
  s.end_shape()
  inspect(cmds(s), content="[MoveTo(0, 0), QuadraticCurveTo(5, 10, 10, 0)]")
}

///|
test "spline vertices" {
  let s = @shape.Shape::new()
  s.begin_shape()
  s.spline_vertex(0, 0)
  s.spline_vertex(6, 6)
  s.spline_vertex(12, 0)
  s.end_shape()
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  BezierCurveTo(1, 1, 4, 6, 6, 6),
      #|  BezierCurveTo(8, 6, 11, 1, 12, 0),
      #|]
    ),
  )
  // Closing a lone spline turns it into a loop.
  s.reset()
  s.begin_shape()
  s.spline_vertex(0, 0)
  s.spline_vertex(6, 6)
  s.spline_vertex(12, 0)
  s.end_shape(mode=Close)
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  BezierCurveTo(-1, 1, 4, 6, 6, 6),
      #|  BezierCurveTo(8, 6, 13, 1, 12, 0),
      #|  BezierCurveTo(11, -1, 1, -1, 0, 0),
      #|]
    ),
  )
  // Excluded ends: the first and last vertex are control points only.
  s.reset()
  s.set_spline_ends(Exclude)
  s.begin_shape()
  s.spline_vertex(0, 0)
  s.spline_vertex(6, 6)
  s.spline_vertex(12, 0)
  s.spline_vertex(18, 6)
  s.end_shape()
  inspect(
    cmds(s),
    content="[MoveTo(0, 0), MoveTo(6, 6), BezierCurveTo(8, 6, 10, 0, 12, 0)]",
  )
}

///|
test "contours" {
  let s = @shape.Shape::new()
  s.begin_shape()
  s.vertex(0, 0)
  s.vertex(10, 0)
  s.vertex(10, 10)
  s.begin_contour()
  s.vertex(2, 2)
  s.vertex(4, 2)
  s.vertex(4, 4)
  s.end_contour(mode=Close)
  s.end_shape(mode=Close)
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  LineTo(10, 0),
      #|  LineTo(10, 10),
      #|  ClosePath,
      #|  MoveTo(2, 2),
      #|  LineTo(4, 2),
      #|  LineTo(4, 4),
      #|  ClosePath,
      #|]
    ),
  )
}

///|
test "shape kinds" {
  let s = @shape.Shape::new()
  s.begin_shape(kind=Triangles)
  for p in [(0.0, 0.0), (1, 0), (0, 1), (5, 5), (6, 5), (5, 6)] {
    s.vertex(p.0, p.1)
  }
  s.end_shape()
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  LineTo(1, 0),
      #|  LineTo(0, 1),
      #|  ClosePath,
      #|  MoveTo(5, 5),
      #|  LineTo(6, 5),
      #|  LineTo(5, 6),
      #|  ClosePath,
      #|]
    ),
  )
  s.reset()
  s.begin_shape(kind=QuadStrip)
  for p in [(0.0, 0.0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)] {
    s.vertex(p.0, p.1)
  }
  s.end_shape()
  inspect(
    cmds(s),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  LineTo(0, 1),
      #|  LineTo(1, 1),
      #|  LineTo(1, 0),
      #|  ClosePath,
      #|  MoveTo(1, 0),
      #|  LineTo(1, 1),
      #|  LineTo(2, 1),
      #|  LineTo(2, 0),
      #|  ClosePath,
      #|]
    ),
  )
  s.reset()
  s.begin_shape(kind=Points)
  s.vertex(3, 4)
  s.end_shape()
  inspect(cmds(s), content="[MoveTo(3, 4), LineTo(3.00001, 4)]")
}

///|
test "arc paths" {
  let s = @shape.Shape::new()
  s.arc(0, 0, 20, 20, 0, @math.HALF_PI, Pie)
  let paths = s.to_paths()
  debug_inspect(
    paths.fill_path(),
    content=(
      #|[
      #|  MoveTo(20, 10),
      #|  Ellipse(10, 10, 10, 10, 0, 0, 1.5707963267948966),
      #|  LineTo(10, 10),
      #|  ClosePath,
      #|]
    ),
  )
  debug_inspect(
    paths.stroke_path(),
    content=(
      #|[
      #|  MoveTo(20, 10),
      #|  Ellipse(10, 10, 10, 10, 0, 0, 1.5707963267948966),
      #|  LineTo(10, 10),
      #|  ClosePath,
      #|]
    ),
  )
  s.reset()
  s.arc(0, 0, 20, 20, 0, @math.HALF_PI, Open)
  let paths = s.to_paths()
  debug_inspect(
    paths.stroke_path(),
    content="[MoveTo(20, 10), Ellipse(10, 10, 10, 10, 0, 0, 1.5707963267948966)]",
  )
}

///|
test "arc angle normalization" {
  let a = @shape.normalize_arc_angles(-@math.HALF_PI, @math.HALF_PI, 10, 10)
  inspect(a.start == 3 * @math.HALF_PI, content="true")
  inspect(a.stop == 5 * @math.HALF_PI, content="true")
  let full = @shape.normalize_arc_angles(0, @math.TWO_PI, 10, 10)
  inspect(full.same_point, content="true")
}

///|
test "curve evaluation" {
  inspect(@shape.bezier_tangent(0, 0, 100, 100, 0.5), content="150")
  inspect(@shape.spline_point(0, 10, 20, 30, 0.5), content="15")
  inspect(@shape.spline_tangent(0, 10, 20, 30, 0.5), content="10")
  inspect(@shape.spline_point(0, 10, 20, 30, 0), content="10")
}
