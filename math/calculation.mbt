// Port of p5.js src/math/calculation.js

///|
/// Constrains `n` between `low` and `high`.
///
/// ```mbt check
/// test {
///   inspect(@math.constrain(15, 0, 10), content="10")
///   inspect(@math.constrain(-1, 0, 10), content="0")
/// }
/// ```
pub fn constrain(n : Double, low : Double, high : Double) -> Double {
  n.min(high).max(low)
}

///|
/// Distance between two 2D points.
pub fn dist(x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Double {
  @cmath.hypot(x2 - x1, y2 - y1)
}

///|
/// Distance between two 3D points.
pub fn dist3(
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Double {
  hypot3(x2 - x1, y2 - y1, z2 - z1)
}

///|
fn hypot3(x : Double, y : Double, z : Double) -> Double {
  (x * x + y * y + z * z).sqrt()
}

///|
/// Linear interpolation: `amt * (stop - start) + start`.
pub fn lerp(start : Double, stop : Double, amt : Double) -> Double {
  amt * (stop - start) + start
}

///|
/// Length of the 2D vector `(x, y)`.
pub fn mag(x : Double, y : Double) -> Double {
  @cmath.hypot(x, y)
}

///|
/// Re-maps `n` from the range `[start1, stop1]` to `[start2, stop2]`.
/// When `within_bounds` is true the result is constrained to the target range.
///
/// ```mbt check
/// test {
///   inspect(@math.map(5, 0, 10, 0, 100), content="50")
///   inspect(@math.map(20, 0, 10, 0, 100, within_bounds=true), content="100")
/// }
/// ```
pub fn map(
  n : Double,
  start1 : Double,
  stop1 : Double,
  start2 : Double,
  stop2 : Double,
  within_bounds~ : Bool = false,
) -> Double {
  let newval = (n - start1) / (stop1 - start1) * (stop2 - start2) + start2
  if !within_bounds {
    newval
  } else if start2 < stop2 {
    constrain(newval, start2, stop2)
  } else {
    constrain(newval, stop2, start2)
  }
}

///|
/// Normalizes `n` from the range `[start, stop]` to `[0, 1]`.
pub fn norm(n : Double, start : Double, stop : Double) -> Double {
  map(n, start, stop, 0, 1)
}

///|
/// Largest value of an array (`-inf` when empty).
pub fn max_of(values : ArrayView[Double]) -> Double {
  values.fold(init=@double.neg_infinity, (acc, x) => acc.max(x))
}

///|
/// Smallest value of an array (`inf` when empty).
pub fn min_of(values : ArrayView[Double]) -> Double {
  values.fold(init=@double.infinity, (acc, x) => acc.min(x))
}

///|
/// JavaScript-compatible `Math.round`: rounds half-way cases towards +∞.
pub fn js_round(n : Double) -> Double {
  (n + 0.5).floor()
}

///|
/// Rounds `n` to the given number of `decimals` (0 by default), with
/// JavaScript `Math.round` semantics.
///
/// ```mbt check
/// test {
///   inspect(@math.round(2.5), content="3")
///   inspect(@math.round(-2.5), content="-2")
///   inspect(@math.round(3.14159, decimals=2), content="3.14")
/// }
/// ```
pub fn round(n : Double, decimals~ : Int32 = 0) -> Double {
  if decimals == 0 {
    return js_round(n)
  }
  let multiplier = @cmath.pow(10, decimals.to_double())
  js_round(n * multiplier) / multiplier
}

///|
/// Squares a number.
pub fn sq(n : Double) -> Double {
  n * n
}

///|
/// Fractional part of a number: `fract(3.75) == 0.75`, `fract(-1.25) == 0.75`.
pub fn fract(n : Double) -> Double {
  if n.is_nan() || n.is_inf() {
    return n
  }
  n - n.floor()
}

///|
/// Converts an angle from radians to degrees.
pub fn degrees(rad : Double) -> Double {
  rad * RAD_TO_DEG
}

///|
/// Converts an angle from degrees to radians.
pub fn radians(deg : Double) -> Double {
  deg * DEG_TO_RAD
}
