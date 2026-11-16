// Port of p5.js src/shape/curves.js (point/tangent evaluation).

///|
/// Evaluates one coordinate of a cubic Bézier curve at `t`.
///
/// ```mbt check
/// test {
///   inspect(@shape.bezier_point(0, 0, 100, 100, 0.5), content="50")
/// }
/// ```
pub fn bezier_point(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
) -> Double {
  let u = 1.0 - t
  u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
}

///|
/// Evaluates the derivative of one coordinate of a cubic Bézier at `t`.
pub fn bezier_tangent(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
) -> Double {
  let u = 1.0 - t
  3 * d * t * t -
  3 * c * t * t +
  6 * c * u * t -
  6 * b * u * t +
  3 * b * u * u -
  3 * a * u * u
}

///|
/// Evaluates one coordinate of a Catmull-Rom spline segment between `b` and
/// `c` at `t`, with the given `tightness` (0 by default).
pub fn spline_point(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
  tightness~ : Double = 0,
) -> Double {
  let s = tightness
  let t3 = t * t * t
  let t2 = t * t
  let f1 : Double = (s - 1) / 2 * t3 + (1 - s) * t2 + (s - 1) / 2 * t
  let f2 : Double = (s + 3) / 2 * t3 + (-5 - s) / 2 * t2 + 1.0
  let f3 : Double = (-3 - s) / 2 * t3 + (s + 2) * t2 + (1 - s) / 2 * t
  let f4 : Double = (1 - s) / 2 * t3 + (s - 1) / 2 * t2
  a * f1 + b * f2 + c * f3 + d * f4
}

///|
/// Evaluates the derivative of one coordinate of a spline segment at `t`.
pub fn spline_tangent(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
  tightness~ : Double = 0,
) -> Double {
  let s = tightness
  let tt3 = t * t * 3
  let t2 = t * 2
  let f1 : Double = (s - 1) / 2 * tt3 + (1 - s) * t2 + (s - 1) / 2
  let f2 : Double = (s + 3) / 2 * tt3 + (-5 - s) / 2 * t2
  let f3 : Double = (-3 - s) / 2 * tt3 + (s + 2) * t2 + (1 - s) / 2
  let f4 : Double = (1 - s) / 2 * tt3 + (s - 1) / 2 * t2
  a * f1 + b * f2 + c * f3 + d * f4
}
