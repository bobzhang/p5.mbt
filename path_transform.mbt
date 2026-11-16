// Transforming paths into device space, used to build clip paths that are
// independent from the transform active when each shape was drawn.

///|
fn ellipse_to_beziers(
  out : @shape.Path,
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  start : Double,
  stop : Double,
  m : Matrix2D,
) -> Unit {
  let total = stop - start
  let n = (total.abs() / HALF_PI).ceil().max(1).to_int()
  let step = total / n.to_double()
  let k = 4.0 / 3.0 * @cmath.tan(step / 4)
  let (sx, sy) = m.apply(
    cx + rx * @cmath.cos(start),
    cy + ry * @cmath.sin(start),
  )
  out.push(LineTo(sx, sy))
  for i in 0..<n {
    let a0 = start + step * i.to_double()
    let a1 = a0 + step
    let (c0, s0) = (@cmath.cos(a0), @cmath.sin(a0))
    let (c1, s1) = (@cmath.cos(a1), @cmath.sin(a1))
    let (p1x, p1y) = m.apply(cx + rx * (c0 - k * s0), cy + ry * (s0 + k * c0))
    let (p2x, p2y) = m.apply(cx + rx * (c1 + k * s1), cy + ry * (s1 - k * c1))
    let (ex, ey) = m.apply(cx + rx * c1, cy + ry * s1)
    out.push(BezierCurveTo(p1x, p1y, p2x, p2y, ex, ey))
  }
}

///|
/// Returns `path` with every point mapped through `m`. Ellipses and
/// rectangles are converted to curves and lines.
fn transform_path(path : @shape.Path, m : Matrix2D) -> @shape.Path {
  let out : @shape.Path = []
  let pt = (x : Double, y : Double) => m.apply(x, y)
  let poly = (pts : Array[(Double, Double)]) => {
    let (x0, y0) = pt(pts[0].0, pts[0].1)
    out.push(MoveTo(x0, y0))
    for i in 1..<pts.length() {
      let (x, y) = pt(pts[i].0, pts[i].1)
      out.push(LineTo(x, y))
    }
    out.push(ClosePath)
  }
  for cmd in path {
    match cmd {
      MoveTo(x, y) => {
        let (a, b) = pt(x, y)
        out.push(MoveTo(a, b))
      }
      LineTo(x, y) => {
        let (a, b) = pt(x, y)
        out.push(LineTo(a, b))
      }
      QuadraticCurveTo(cx, cy, x, y) => {
        let (a, b) = pt(cx, cy)
        let (c, d) = pt(x, y)
        out.push(QuadraticCurveTo(a, b, c, d))
      }
      BezierCurveTo(x1, y1, x2, y2, x, y) => {
        let (a, b) = pt(x1, y1)
        let (c, d) = pt(x2, y2)
        let (e, f) = pt(x, y)
        out.push(BezierCurveTo(a, b, c, d, e, f))
      }
      Ellipse(cx, cy, rx, ry, _, start, stop) =>
        ellipse_to_beziers(out, cx, cy, rx, ry, start, stop, m)
      Rect(x, y, w, h) => poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])
      RoundRect(x, y, w, h, tl, tr, br, bl) => {
        let (sx, sy) = pt(x + tl, y)
        out.push(MoveTo(sx, sy))
        ellipse_to_beziers(out, x + w - tr, y + tr, tr, tr, -HALF_PI, 0, m)
        ellipse_to_beziers(out, x + w - br, y + h - br, br, br, 0, HALF_PI, m)
        ellipse_to_beziers(out, x + bl, y + h - bl, bl, bl, HALF_PI, PI, m)
        ellipse_to_beziers(out, x + tl, y + tl, tl, tl, PI, 3 * HALF_PI, m)
        out.push(ClosePath)
      }
      ClosePath => out.push(ClosePath)
    }
  }
  out
}
