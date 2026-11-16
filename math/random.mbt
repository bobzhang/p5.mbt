// Port of p5.js src/math/random.js
//
// p5.js uses a Linear Congruential Generator (Numerical Recipes constants)
// once `randomSeed()` has been called.  We always use the LCG so that every
// sequence is reproducible; an unseeded sketch is seeded from the host clock.

///|
const LCG_A : UInt32 = 1664525

///|
const LCG_C : UInt32 = 1013904223

///|
const LCG_M : Double = 4294967296.0

///|
/// A seedable pseudo random number generator, compatible with p5.js
/// `randomSeed()` / `random()` / `randomGaussian()`.
pub struct Random {
  priv mut state : UInt32
  priv mut gaussian_previous : Bool
  priv mut y2 : Double
}

///|
/// JavaScript `ToUint32` (the `>>> 0` operator).
pub fn to_uint32(value : Double) -> UInt32 {
  if value.is_nan() || value.is_inf() {
    return 0
  }
  let t = value.trunc()
  let m = t - (t / LCG_M).floor() * LCG_M
  m.to_uint64().to_uint()
}

///|
/// Creates a generator with the given seed.
pub fn Random::new(seed : Double) -> Random {
  { state: to_uint32(seed), gaussian_previous: false, y2: 0, }
}

///|
/// Re-seeds the generator, like p5's `randomSeed(seed)`.
pub fn Random::set_seed(self : Random, seed : Double) -> Unit {
  self.state = to_uint32(seed)
  self.gaussian_previous = false
}

///|
/// Returns a number in `[0, 1)`.
///
/// ```mbt check
/// test {
///   let r = @math.Random::new(99)
///   // Same as `randomSeed(99); random()` in p5.js
///   inspect(
///     r.next(),
///     content=(
///       #|0.27443566313013434
///     ),
///   )
/// }
/// ```
pub fn Random::next(self : Random) -> Double {
  self.state = LCG_A * self.state + LCG_C
  self.state.to_double() / LCG_M
}

///|
/// Returns a number in `[0, max)`.
pub fn Random::below(self : Random, max : Double) -> Double {
  self.next() * max
}

///|
/// Returns a number in `[min, max)`. The bounds are swapped when `min > max`.
pub fn Random::range(self : Random, min : Double, max : Double) -> Double {
  let rand = self.next()
  let (lo, hi) = if min > max { (max, min) } else { (min, max) }
  rand * (hi - lo) + lo
}

///|
/// Returns a uniformly chosen element of `choices`.
///
/// # Panics
/// Panics if `choices` is empty.
pub fn[T] Random::choice(self : Random, choices : ArrayView[T]) -> T {
  let i = (self.next() * choices.length().to_double()).floor().to_int()
  choices[i]
}

///|
/// Returns a number from a normal distribution (Marsaglia polar method,
/// exactly as p5's `randomGaussian(mean, sd)`).
pub fn Random::gaussian(
  self : Random,
  mean~ : Double = 0,
  sd~ : Double = 1,
) -> Double {
  let y1 = if self.gaussian_previous {
    self.gaussian_previous = false
    self.y2
  } else {
    let (x1, x2, w) = for ;; {
      let x1 = self.below(2) - 1
      let x2 = self.below(2) - 1
      let w = x1 * x1 + x2 * x2
      if w < 1 {
        break (x1, x2, w)
      }
    }
    let w = (-2.0 * @cmath.ln(w) / w).sqrt()
    self.y2 = x2 * w
    self.gaussian_previous = true
    x1 * w
  }
  y1 * sd + mean
}
