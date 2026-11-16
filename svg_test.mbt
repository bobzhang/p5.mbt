///|
test "svg path data: every command, absolute and relative" {
  debug_inspect(
    @p5.parse_svg_path("M10 20 h5 v5 H0 V0 l1-1 z"),
    content=(
      #|[
      #|  MoveTo(10, 20),
      #|  LineTo(15, 20),
      #|  LineTo(15, 25),
      #|  LineTo(0, 25),
      #|  LineTo(0, 0),
      #|  LineTo(1, -1),
      #|  ClosePath,
      #|]
    ),
  )
  debug_inspect(
    @p5.parse_svg_path("M0 0C1 2 3 4 5 6S9 10 11 12"),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  BezierCurveTo(1, 2, 3, 4, 5, 6),
      #|  BezierCurveTo(7, 8, 9, 10, 11, 12),
      #|]
    ),
  )
  debug_inspect(
    @p5.parse_svg_path("M0 0Q5 10 10 0T20 0"),
    content=(
      #|[
      #|  MoveTo(0, 0),
      #|  QuadraticCurveTo(5, 10, 10, 0),
      #|  QuadraticCurveTo(15, -10, 20, 0),
      #|]
    ),
  )
  // implicit line-tos after a move, compact numbers, and arc flags
  inspect(@p5.parse_svg_path("M0,0 10,0-5.5.5").length(), content="3")
  inspect(@p5.parse_svg_path("M0 0a5 5 0 1010 0").length(), content="3")
}

///|
test "build_shape records drawing and get_svg exports it" {
  let rec = @p5.Recorder::new()
  let p = @p5.P5::headless(rec, 100, 50)
  let coll = p.build_shape(() => {
    p.background(255)
    p.fill((255, 0, 0))
    p.rect(10, 10, 20, 10)
    p.no_stroke()
    p.circle(60, 25, 20)
  })
  ignore(rec.take())
  inspect(
    p.get_svg(coll),
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100" height="50" viewBox="0 0 100 50"><g><g><rect x="0" y="0" width="100" height="50" fill="#ffffff"/></g><rect x="10" y="10" width="20" height="10" fill="#ff0000" stroke="#000000" stroke-width="1" stroke-linecap="round"/><ellipse cx="60" cy="25" rx="10" ry="10" fill="#ff0000" stroke="none"/></g></svg>
    ),
  )
  // replaying the recording draws the same calls
  p.shape(coll, x=5)
  let log = rec.take()
  inspect(log.filter(l => l.has_prefix("fill ")).length(), content="2")
}

///|
test "create_svg imports shapes with styles and transforms" {
  let coll = @p5.create_svg(
    "<svg width=\"50\" height=\"40\" viewBox=\"0 0 100 80\"><g fill=\"blue\" transform=\"translate(10 5)\"><rect width=\"20\" height=\"10\"/><circle cx=\"5\" cy=\"5\" r=\"2\" stroke=\"red\" fill-opacity=\"0.5\"/></g></svg>",
  )
  debug_inspect(coll.bounds, content="(0, 0, 50, 40)")
  inspect(
    coll.ops.length(),
    content=(
      #|3
    ),
  )
  let rec = @p5.Recorder::new()
  let p = @p5.P5::headless(rec, 100, 100)
  ignore(rec.take())
  p.shape(coll)
  inspect(
    rec.take().join("\n"),
    content=(
      #|save
      #|transform 0.5 0 0 0.5 5 2.5
      #|fill #0000ff R0,0,20,10
      #|transform 0.5 0 0 0.5 5 2.5
      #|fill #0000ff7f M7,5 E5,5,2,2,0,6.283
      #|transform 0.5 0 0 0.5 5 2.5
      #|stroke #ff0000 w=1 butt/miter M7,5 E5,5,2,2,0,6.283
      #|restore
      #|blend source-over
      #|smoothing true
    ),
  )
}
