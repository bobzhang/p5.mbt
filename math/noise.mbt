// Port of p5.js src/math/noise.js (classic Perlin noise as in Processing)

///|
const PERLIN_YWRAPB : Int32 = 4

///|
const PERLIN_YWRAP : Int32 = 16

///|
const PERLIN_ZWRAPB : Int32 = 8

///|
const PERLIN_ZWRAP : Int32 = 256

///|
const PERLIN_SIZE : Int32 = 4095

///|
/// Perlin noise generator compatible with p5's `noise()`, `noiseDetail()` and
/// `noiseSeed()`.
pub struct Noise {
  priv perlin : FixedArray[Double]
  priv mut octaves : Int32
  priv mut amp_falloff : Double
}

///|
/// Creates a noise generator whose lattice is filled from `rng`.
pub fn Noise::from_random(rng : Random) -> Noise {
  let perlin = FixedArray::make(PERLIN_SIZE + 1, 0.0)
  for i in 0..<=PERLIN_SIZE {
    perlin[i] = rng.next()
  }
  { perlin, octaves: 4, amp_falloff: 0.5, }
}

///|
/// Creates a noise generator seeded like `noiseSeed(seed)`.
pub fn Noise::new(seed : Double) -> Noise {
  Noise::from_random(Random::new(seed))
}

///|
/// Re-seeds the lattice, like p5's `noiseSeed(seed)`.
pub fn Noise::set_seed(self : Noise, seed : Double) -> Unit {
  let rng = Random::new(seed)
  for i in 0..<=PERLIN_SIZE {
    self.perlin[i] = rng.next()
  }
}

///|
/// Adjusts the character of the noise, like p5's `noiseDetail(lod, falloff)`.
pub fn Noise::detail(
  self : Noise,
  lod : Int32,
  falloff~ : Double = 0.5,
) -> Unit {
  if lod > 0 {
    self.octaves = lod
  }
  if falloff > 0 {
    self.amp_falloff = falloff
  }
}

///|
/// Number of octaves used.
pub fn Noise::octaves(self : Noise) -> Int32 {
  self.octaves
}

///|
/// Amplitude falloff per octave.
pub fn Noise::amp_falloff(self : Noise) -> Double {
  self.amp_falloff
}

///|
fn scaled_cosine(i : Double) -> Double {
  0.5 * (1.0 - @cmath.cos(i * PI))
}

///|
/// Returns Perlin noise in `[0, 1)` at the coordinates `(x, y, z)`.
///
/// ```mbt check
/// test {
///   let n = @math.Noise::new(42)
///   let v = n.noise(0.5, y=0.25)
///   assert_true(v >= 0 && v < 1)
/// }
/// ```
pub fn Noise::noise(
  self : Noise,
  x : Double,
  y~ : Double = 0,
  z~ : Double = 0,
) -> Double {
  let perlin = self.perlin
  let x = x.abs()
  let y = y.abs()
  let z = z.abs()
  let mut xi = x.floor().to_int()
  let mut yi = y.floor().to_int()
  let mut zi = z.floor().to_int()
  let mut xf = x - x.floor()
  let mut yf = y - y.floor()
  let mut zf = z - z.floor()
  let mut r = 0.0
  let mut ampl = 0.5
  for _ in 0..<self.octaves {
    let mut of = xi + (yi << PERLIN_YWRAPB) + (zi << PERLIN_ZWRAPB)
    let rxf = scaled_cosine(xf)
    let ryf = scaled_cosine(yf)
    let mut n1 = perlin[of & PERLIN_SIZE]
    n1 += rxf * (perlin[(of + 1) & PERLIN_SIZE] - n1)
    let mut n2 = perlin[(of + PERLIN_YWRAP) & PERLIN_SIZE]
    n2 += rxf * (perlin[(of + PERLIN_YWRAP + 1) & PERLIN_SIZE] - n2)
    n1 += ryf * (n2 - n1)
    of += PERLIN_ZWRAP
    n2 = perlin[of & PERLIN_SIZE]
    n2 += rxf * (perlin[(of + 1) & PERLIN_SIZE] - n2)
    let mut n3 = perlin[(of + PERLIN_YWRAP) & PERLIN_SIZE]
    n3 += rxf * (perlin[(of + PERLIN_YWRAP + 1) & PERLIN_SIZE] - n3)
    n2 += ryf * (n3 - n2)
    n1 += scaled_cosine(zf) * (n2 - n1)
    r += n1 * ampl
    ampl *= self.amp_falloff
    xi = xi << 1
    xf *= 2
    yi = yi << 1
    yf *= 2
    zi = zi << 1
    zf *= 2
    if xf >= 1.0 {
      xi += 1
      xf -= 1
    }
    if yf >= 1.0 {
      yi += 1
      yf -= 1
    }
    if zf >= 1.0 {
      zi += 1
      zf -= 1
    }
  }
  r
}
