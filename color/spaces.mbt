// Conversions between the supported color spaces and sRGB.
// sRGB coordinates are gamma-encoded and nominally in [0, 1].

///|
fn srgb_to_linear(c : Double) -> Double {
  let abs = c.abs()
  if abs <= 0.04045 {
    c / 12.92
  } else {
    c.signum() * @cmath.pow((abs + 0.055) / 1.055, 2.4)
  }
}

///|
fn linear_to_srgb(c : Double) -> Double {
  let abs = c.abs()
  if abs > 0.0031308 {
    c.signum() * (1.055 * @cmath.pow(abs, 1.0 / 2.4) - 0.055)
  } else {
    12.92 * c
  }
}

///|
fn mat3(
  m : FixedArray[Double],
  x : Double,
  y : Double,
  z : Double,
) -> (Double, Double, Double) {
  (
    m[0] * x + m[1] * y + m[2] * z,
    m[3] * x + m[4] * y + m[5] * z,
    m[6] * x + m[7] * y + m[8] * z,
  )
}

///|
let lin_srgb_to_xyz65 : FixedArray[Double] = [
  0.41239079926595934, 0.357584339383878, 0.1804807884018343, 0.21263900587151027,
  0.715168678767756, 0.07219231536073371, 0.01933081871559182, 0.11919477979462598,
  0.9505321522496607,
]

///|
let xyz65_to_lin_srgb : FixedArray[Double] = [
  3.2409699419045226, -1.537383177570094, -0.4986107602930034, -0.9692436362808796,
  1.8759675015077202, 0.04155505740717559, 0.05563007969699366, -0.20397695888897652,
  1.0569715142428786,
]

///|
let d65_to_d50 : FixedArray[Double] = [
  1.0479298208405488, 0.022946793341019088, -0.05019222954313557, 0.029627815688159344,
  0.990434484573249, -0.01707382502938514, -0.009243058152591178, 0.015055144896577895,
  0.7518742899580008,
]

///|
let d50_to_d65 : FixedArray[Double] = [
  0.9554734527042182, -0.023098536874261423, 0.0632593086610217, -0.028369706963208136,
  1.0099954580058226, 0.021041398966943008, 0.012314001688319899, -0.020507696433477912,
  1.3303659366080753,
]

///|
let d50_white : (Double, Double, Double) = (
  0.3457 / 0.3585,
  1.0,
  (1.0 - 0.3457 - 0.3585) / 0.3585,
)

///|
fn hsb_from_srgb(
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  let v = r.max(g).max(b)
  let chroma = v - r.min(g).min(b)
  if chroma == 0 {
    return (0, 0, v * 100)
  }
  let sat = chroma / v
  let mut hue = if r == v {
    (g - b) / chroma
  } else if g == v {
    2 + (b - r) / chroma
  } else {
    4 + (r - g) / chroma
  }
  if hue < 0 {
    hue += 6
  } else if hue >= 6 {
    hue -= 6
  }
  (hue / 6 * 360, sat * 100, v * 100)
}

///|
fn hsb_to_srgb(h : Double, s : Double, v : Double) -> (Double, Double, Double) {
  let hue = h / 360 * 6
  let sat = s / 100
  let val = v / 100
  if sat == 0 {
    return (val, val, val)
  }
  let sector = hue.floor()
  let tint1 = val * (1 - sat)
  let tint2 = val * (1 - sat * (hue - sector))
  let tint3 = val * (1 - sat * (1 + sector - hue))
  match sector.to_int() {
    1 => (tint2, val, tint1)
    2 => (tint1, val, tint3)
    3 => (tint1, tint2, val)
    4 => (tint3, tint1, val)
    5 => (val, tint1, tint2)
    _ => (val, tint3, tint1)
  }
}

///|
fn hsl_from_srgb(
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  let max = r.max(g).max(b)
  let min = r.min(g).min(b)
  let l = (min + max) / 2
  let d = max - min
  let mut h = 0.0
  let mut s = 0.0
  if d != 0 {
    s = if l == 0 || l == 1 { 0 } else { (max - l) / l.min(1 - l) }
    h = if max == r {
      (g - b) / d + (if g < b { 6 } else { 0 })
    } else if max == g {
      (b - r) / d + 2
    } else {
      (r - g) / d + 4
    }
    h = h * 60
  }
  if s < 0 {
    h += 180
    s = s.abs()
  }
  if h >= 360 {
    h -= 360
  }
  (h, s * 100, l * 100)
}

///|
fn hsl_to_srgb(h : Double, s : Double, l : Double) -> (Double, Double, Double) {
  let h = @math.js_rem(h, 360)
  let h = if h < 0 { h + 360 } else { h }
  let s = s / 100
  let l = l / 100
  let f = (n : Double) => {
    let k = @math.js_rem(n + h / 30, 12)
    let a = s * l.min(1 - l)
    l - a * (-1.0).max((k - 3).min(9 - k).min(1))
  }
  (f(0), f(8), f(4))
}

///|
fn hwb_to_srgb(h : Double, w : Double, bl : Double) -> (Double, Double, Double) {
  let w = w / 100
  let bl = bl / 100
  if w + bl >= 1 {
    let gray = w / (w + bl)
    return (gray, gray, gray)
  }
  let (r, g, b) = hsl_to_srgb(h, 100, 50)
  let k = 1.0 - w - bl
  (r * k + w, g * k + w, b * k + w)
}

///|
fn hwb_from_srgb(
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (h, _, _) = hsl_from_srgb(r, g, b)
  let w = r.min(g).min(b)
  let bl = 1.0 - r.max(g).max(b)
  (h, w * 100, bl * 100)
}

///|
fn lab_from_srgb(
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  let (x65, y65, z65) = mat3(
    lin_srgb_to_xyz65,
    srgb_to_linear(r),
    srgb_to_linear(g),
    srgb_to_linear(b),
  )
  let (x, y, z) = mat3(d65_to_d50, x65, y65, z65)
  let (wx, wy, wz) = d50_white
  let eps = 216.0 / 24389.0
  let kappa = 24389.0 / 27.0
  let f = (v : Double) => {
    if v > eps {
      @cmath.cbrt(v)
    } else {
      (kappa * v + 16) / 116
    }
  }
  let fx = f(x / wx)
  let fy = f(y / wy)
  let fz = f(z / wz)
  (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
}

///|
fn lab_to_srgb(l : Double, a : Double, b : Double) -> (Double, Double, Double) {
  let eps3 = 6.0 / 29.0
  let kappa = 24389.0 / 27.0
  let fy = (l + 16) / 116
  let fx = a / 500 + fy
  let fz = fy - b / 200
  let x = if fx > eps3 { fx * fx * fx } else { (116 * fx - 16) / kappa }
  let y = if l > kappa * (216.0 / 24389.0) {
    @cmath.pow((l + 16) / 116, 3)
  } else {
    l / kappa
  }
  let z = if fz > eps3 { fz * fz * fz } else { (116 * fz - 16) / kappa }
  let (wx, wy, wz) = d50_white
  let (x65, y65, z65) = mat3(d50_to_d65, x * wx, y * wy, z * wz)
  let (lr, lg, lb) = mat3(xyz65_to_lin_srgb, x65, y65, z65)
  (linear_to_srgb(lr), linear_to_srgb(lg), linear_to_srgb(lb))
}

///|
fn oklab_from_srgb(
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  let r = srgb_to_linear(r)
  let g = srgb_to_linear(g)
  let b = srgb_to_linear(b)
  let l = @cmath.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  let m = @cmath.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  let s = @cmath.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  )
}

///|
fn oklab_to_srgb(
  ll : Double,
  a : Double,
  b : Double,
) -> (Double, Double, Double) {
  let l = ll + 0.3963377774 * a + 0.2158037573 * b
  let m = ll - 0.1055613458 * a - 0.0638541728 * b
  let s = ll - 0.0894841775 * a - 1.2914855480 * b
  let l = l * l * l
  let m = m * m * m
  let s = s * s * s
  (
    linear_to_srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    linear_to_srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    linear_to_srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  )
}

///|
fn lch_from_lab(l : Double, a : Double, b : Double) -> (Double, Double, Double) {
  let c = (a * a + b * b).sqrt()
  let mut h = @cmath.atan2(b, a) * @math.RAD_TO_DEG
  if h < 0 {
    h += 360
  }
  (l, c, h)
}

///|
fn lch_to_lab(l : Double, c : Double, h : Double) -> (Double, Double, Double) {
  let rad = h * @math.DEG_TO_RAD
  (l, c * @cmath.cos(rad), c * @cmath.sin(rad))
}

///|
/// Converts native coordinates of `mode` to gamma-encoded sRGB.
fn to_srgb(
  mode : ColorMode,
  c : FixedArray[Double],
) -> (Double, Double, Double) {
  match mode {
    RGB => (c[0], c[1], c[2])
    HSB => hsb_to_srgb(c[0], c[1], c[2])
    HSL => hsl_to_srgb(c[0], c[1], c[2])
    HWB => hwb_to_srgb(c[0], c[1], c[2])
    LAB => lab_to_srgb(c[0], c[1], c[2])
    LCH => {
      let (l, a, b) = lch_to_lab(c[0], c[1], c[2])
      lab_to_srgb(l, a, b)
    }
    OKLAB => oklab_to_srgb(c[0], c[1], c[2])
    OKLCH => {
      let (l, a, b) = lch_to_lab(c[0], c[1], c[2])
      oklab_to_srgb(l, a, b)
    }
  }
}

///|
/// Converts gamma-encoded sRGB to native coordinates of `mode`.
fn from_srgb(
  mode : ColorMode,
  r : Double,
  g : Double,
  b : Double,
) -> (Double, Double, Double) {
  match mode {
    RGB => (r, g, b)
    HSB => hsb_from_srgb(r, g, b)
    HSL => hsl_from_srgb(r, g, b)
    HWB => hwb_from_srgb(r, g, b)
    LAB => lab_from_srgb(r, g, b)
    LCH => {
      let (l, a, bb) = lab_from_srgb(r, g, b)
      lch_from_lab(l, a, bb)
    }
    OKLAB => oklab_from_srgb(r, g, b)
    OKLCH => {
      let (l, a, bb) = oklab_from_srgb(r, g, b)
      lch_from_lab(l, a, bb)
    }
  }
}
