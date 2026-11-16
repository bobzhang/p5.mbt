// Port of p5.js src/core/helpers.js and arc-angle normalization.

///|
/// Normalizes the first four arguments of `rect`, `ellipse` and `arc`
/// according to `mode`, returning the top-left corner and a positive size.
///
/// ```mbt check
/// test {
///   debug_inspect(
///     @shape.mode_adjust(50, 50, 20, 10, Center),
///     content="(40, 45, 20, 10)",
///   )
///   debug_inspect(
///     @shape.mode_adjust(30, 40, 10, 20, Corners),
///     content="(10, 20, 20, 20)",
///   )
/// }
/// ```
pub fn mode_adjust(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  mode : ShapeMode,
) -> (Double, Double, Double, Double) {
  match mode {
    Corner => (a, b, c.abs(), d.abs())
    Corners => (a.min(c), b.min(d), (c - a).abs(), (d - b).abs())
    Radius => {
      let c = c.abs()
      let d = d.abs()
      (a - c, b - d, 2 * c, 2 * d)
    }
    Center => {
      let c = c.abs()
      let d = d.abs()
      (a - c * 0.5, b - d * 0.5, c, d)
    }
  }
}

///|
/// Normalized arc angles: `start` in `[0, TWO_PI)`, `stop` in
/// `[start, start + TWO_PI)`, and whether both denote the same point.
pub struct ArcAngles {
  start : Double
  stop : Double
  same_point : Bool
}

///|
fn correct_angle(a : Double, ratio : Double) -> Double {
  if a <= @math.HALF_PI {
    @cmath.atan(ratio * @cmath.tan(a))
  } else if a <= 3 * @math.HALF_PI {
    @cmath.atan(ratio * @cmath.tan(a)) + @math.PI
  } else {
    @cmath.atan(ratio * @cmath.tan(a)) + @math.TWO_PI
  }
}

///|
/// Port of p5's `_normalizeArcAngles`. With `correct_for_scaling`, the
/// angles are adjusted so they are measured on the ellipse of size `w`×`h`.
pub fn normalize_arc_angles(
  start : Double,
  stop : Double,
  w : Double,
  h : Double,
  correct_for_scaling~ : Bool = true,
) -> ArcAngles {
  let epsilon = 0.00001
  let mut start = start - @math.TWO_PI * (start / @math.TWO_PI).floor()
  let mut stop = stop - @math.TWO_PI * (stop / @math.TWO_PI).floor()
  let separation = (start - stop).abs().min(@math.TWO_PI - (start - stop).abs())
  if correct_for_scaling {
    start = correct_angle(start, w / h)
    stop = correct_angle(stop, w / h)
  }
  if start > stop {
    stop += @math.TWO_PI
  }
  { start, stop, same_point: separation < epsilon, }
}
