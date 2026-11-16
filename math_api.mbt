// Sketch-level math functions: p5.js src/math/{random,noise,trigonometry,
// calculation,p5.Vector}.js. Pure helpers are re-exported from @math.

///|
pub using @math {
  constrain,
  dist,
  dist3,
  lerp,
  mag,
  map,
  norm,
  sq,
  fract,
  round,
  degrees,
  radians,
  max_of,
  min_of,
  js_rem,
}

///|
/// Sets the seed of `random()` and `random_gaussian()`.
pub fn P5::random_seed(self : P5, seed : Double) -> Unit {
  self.rng.set_seed(seed)
}

///|
/// A random number in `[0, 1)`.
pub fn P5::random(self : P5) -> Double {
  self.rng.next()
}

///|
/// A random number in `[0, max)`.
pub fn P5::random_max(self : P5, max : Double) -> Double {
  self.rng.below(max)
}

///|
/// A random number in `[min, max)`.
pub fn P5::random_range(self : P5, min : Double, max : Double) -> Double {
  self.rng.range(min, max)
}

///|
/// A random element of `choices`.
pub fn[T] P5::random_choice(self : P5, choices : ArrayView[T]) -> T {
  self.rng.choice(choices)
}

///|
/// A random number from a normal distribution.
pub fn P5::random_gaussian(
  self : P5,
  mean~ : Double = 0,
  sd~ : Double = 1,
) -> Double {
  self.rng.gaussian(mean~, sd~)
}

///|
fn P5::noise_generator(self : P5) -> Noise {
  match self.noise_gen {
    Some(n) => n
    None => {
      let n = Noise::from_random(Random::new(self.rng.next() * 4294967296.0))
      self.noise_gen = Some(n)
      n
    }
  }
}

///|
/// Perlin noise in `[0, 1)` at `(x, y, z)`.
pub fn P5::noise(
  self : P5,
  x : Double,
  y~ : Double = 0,
  z~ : Double = 0,
) -> Double {
  self.noise_generator().noise(x, y~, z~)
}

///|
/// Adjusts the character of `noise()`: number of octaves and falloff.
pub fn P5::noise_detail(
  self : P5,
  lod : Int32,
  falloff~ : Double = 0.5,
) -> Unit {
  self.noise_generator().detail(lod, falloff~)
}

///|
/// Sets the seed of `noise()`.
pub fn P5::noise_seed(self : P5, seed : Double) -> Unit {
  match self.noise_gen {
    Some(n) => n.set_seed(seed)
    None => self.noise_gen = Some(Noise::new(seed))
  }
}

///|
/// Sine of an angle in the current angle mode.
pub fn P5::sin(self : P5, angle : Double) -> Double {
  @cmath.sin(self.to_radians(angle))
}

///|
/// Cosine of an angle in the current angle mode.
pub fn P5::cos(self : P5, angle : Double) -> Double {
  @cmath.cos(self.to_radians(angle))
}

///|
/// Tangent of an angle in the current angle mode.
pub fn P5::tan(self : P5, angle : Double) -> Double {
  @cmath.tan(self.to_radians(angle))
}

///|
/// Arc sine, in the current angle mode.
pub fn P5::asin(self : P5, v : Double) -> Double {
  self.from_radians(@cmath.asin(v))
}

///|
/// Arc cosine, in the current angle mode.
pub fn P5::acos(self : P5, v : Double) -> Double {
  self.from_radians(@cmath.acos(v))
}

///|
/// Arc tangent, in the current angle mode.
pub fn P5::atan(self : P5, v : Double) -> Double {
  self.from_radians(@cmath.atan(v))
}

///|
/// Angle of the point `(x, y)` from the positive x-axis, in the current
/// angle mode.
pub fn P5::atan2(self : P5, y : Double, x : Double) -> Double {
  self.from_radians(@cmath.atan2(y, x))
}

///|
/// Creates a vector, like p5's `createVector(x, y, z)`.
pub fn P5::create_vector(
  self : P5,
  x : Double,
  y : Double,
  z~ : Double = 0,
) -> Vector {
  Vector::with_angle_mode(x, y, z~, degrees=self.degrees)
}

///|
/// A random 2D unit vector using the sketch's random generator.
pub fn P5::random2d(self : P5) -> Vector {
  Vector::random2d(self.rng)
}

///|
/// A random 3D unit vector using the sketch's random generator.
pub fn P5::random3d(self : P5) -> Vector {
  Vector::random3d(self.rng)
}
