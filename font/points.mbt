// p5.Font's `pathToPoints`: evenly spaced samples along a contour.

///|
/// A sampled outline point with its path angle in radians.
#derive(Debug)
pub(all) struct PathPoint {
  x : Double
  y : Double
  angle : Double
}

///|
fn collinear(
  a : PathPoint,
  b : PathPoint,
  c : PathPoint,
  threshold : Double,
) -> Bool {
  let abx = b.x - a.x
  let aby = b.y - a.y
  let bcx = c.x - b.x
  let bcy = c.y - b.y
  let dot = abx * bcx + aby * bcy
  let mag_a = (abx * abx + aby * aby).sqrt()
  let mag_b = (bcx * bcx + bcy * bcy).sqrt()
  acos(dot / (mag_a * mag_b)) < threshold
}

///|
/// Removes points whose neighbouring edges bend by less than `angle`
/// radians (p5's `simplify`, iterating backwards with wrap-around).
fn simplify(pts : Array[PathPoint], angle : Double) -> Unit {
  let at = (i : Int32) => {
    let s = pts.length()
    pts[if i < 0 { i % s + s } else { i % s }]
  }
  let mut i = pts.length() - 1
  while pts.length() > 3 && i >= 0 {
    if collinear(at(i - 1), at(i), at(i + 1), angle) {
      pts.remove(i % pts.length()) |> ignore
    }
    i -= 1
  }
}

///|
/// Samples a contour like p5's `pathToPoints`: `max(1, ceil(length *
/// sample_factor))` points evenly spaced by arc length, then optionally
/// simplified.
pub fn path_to_points(
  cmds : ArrayView[PathCmd],
  crds : ArrayView[Double],
  sample_factor~ : Double = 0.1,
  simplify_threshold~ : Double = 0,
) -> Array[PathPoint] {
  let path = BezierPath::from_commands(cmds, crds)
  if path.segments.is_empty() {
    // createFromCommands needs at least one segment to sample
    return []
  }
  let total = path.total_length()
  let n = @cmath.ceil(total * sample_factor).to_int().max(1)
  let points : Array[PathPoint] = []
  for i in 0..<n {
    let length = total *
      (if n == 1 { 0.0 } else { i.to_double() / (n - 1).to_double() })
    let p = path.point_at_length(length)
    points.push({ x: p.x, y: p.y, angle: path.angle_at_length(length), })
  }
  if simplify_threshold != 0 {
    simplify(points, simplify_threshold)
  }
  points
}
