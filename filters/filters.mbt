// Port of the CPU filters of p5.js src/image/filters.js. All filters work
// in place on RGBA bytes laid out row by row, `width` pixels per row.

///|
/// Converts to a byte like a `Uint8ClampedArray` store: clamp, then round
/// half to even.
pub fn clamp_byte(v : Double) -> Byte {
  if v.is_nan() || v <= 0 {
    return 0
  }
  if v >= 255 {
    return 255
  }
  let f = v.floor()
  let diff = v - f
  let r = if diff > 0.5 {
    f + 1
  } else if diff < 0.5 {
    f
  } else if f.to_int() % 2 == 0 {
    f
  } else {
    f + 1
  }
  r.to_int().to_byte()
}

///|
fn luma(p : FixedArray[Byte], i : Int32) -> Double {
  0.2126 * p[i].to_double() +
  0.7152 * p[i + 1].to_double() +
  0.0722 * p[i + 2].to_double()
}

///|
/// Pixels brighter than `level` (0-1) become white, others black.
///
/// ```mbt check
/// test {
///   let px : FixedArray[Byte] = [200, 200, 200, 255, 20, 30, 40, 128]
///   @filters.threshold(px)
///   debug_inspect(
///     [
///       for b in px => b.to_int()
///     ],
///     content="[255, 255, 255, 255, 0, 0, 0, 128]",
///   )
/// }
/// ```
pub fn threshold(pixels : FixedArray[Byte], level~ : Double = 0.5) -> Unit {
  let thresh = (level * 255).floor()
  for i = 0; i + 3 < pixels.length(); i = i + 4 {
    let v : Byte = if luma(pixels, i) >= thresh { 255 } else { 0 }
    pixels[i] = v
    pixels[i + 1] = v
    pixels[i + 2] = v
  }
}

///|
/// Converts to grayscale (Rec. 709 luma).
pub fn gray(pixels : FixedArray[Byte]) -> Unit {
  for i = 0; i + 3 < pixels.length(); i = i + 4 {
    let v = clamp_byte(luma(pixels, i))
    pixels[i] = v
    pixels[i + 1] = v
    pixels[i + 2] = v
  }
}

///|
/// Sets every alpha to 255.
pub fn make_opaque(pixels : FixedArray[Byte]) -> Unit {
  for i = 0; i + 3 < pixels.length(); i = i + 4 {
    pixels[i + 3] = 255
  }
}

///|
/// Inverts the color channels.
pub fn invert(pixels : FixedArray[Byte]) -> Unit {
  for i = 0; i + 3 < pixels.length(); i = i + 4 {
    pixels[i] = 255 - pixels[i]
    pixels[i + 1] = 255 - pixels[i + 1]
    pixels[i + 2] = 255 - pixels[i + 2]
  }
}

///|
/// Limits each channel to `levels` values (2 to 255).
pub fn posterize(pixels : FixedArray[Byte], levels~ : Int32 = 4) -> Unit {
  let levels = levels.max(2).min(255)
  let levels1 = (levels - 1).to_double()
  let f = (v : Byte) => {
    clamp_byte(((v.to_int() * levels) >> 8).to_double() * 255 / levels1)
  }
  for i = 0; i + 3 < pixels.length(); i = i + 4 {
    pixels[i] = f(pixels[i])
    pixels[i + 1] = f(pixels[i + 1])
    pixels[i + 2] = f(pixels[i + 2])
  }
}

///|
fn lum_at(p : FixedArray[Byte], idx : Int32) -> Int32 {
  let i = idx * 4
  77 * p[i].to_int() + 151 * p[i + 1].to_int() + 28 * p[i + 2].to_int()
}

///|
fn morph(pixels : FixedArray[Byte], width : Int32, dilate : Bool) -> Unit {
  let count = pixels.length() / 4
  if width <= 0 || count == 0 {
    return
  }
  let out = FixedArray::make(count, 0)
  for idx in 0..<count {
    let row_start = idx / width * width
    let row_end = row_start + width
    let left = if idx - 1 < row_start { idx } else { idx - 1 }
    let right = if idx + 1 >= row_end { idx } else { idx + 1 }
    let up = if idx - width < 0 { 0 } else { idx - width }
    let down = if idx + width >= count { idx } else { idx + width }
    let mut best = idx
    let mut best_lum = lum_at(pixels, idx)
    for n in [left, right, up, down] {
      let l = lum_at(pixels, n)
      if (dilate && l > best_lum) || (!dilate && l < best_lum) {
        best = n
        best_lum = l
      }
    }
    out[idx] = best
  }
  let src = pixels.copy()
  for idx in 0..<count {
    let s = out[idx] * 4
    let d = idx * 4
    pixels[d] = src[s]
    pixels[d + 1] = src[s + 1]
    pixels[d + 2] = src[s + 2]
    pixels[d + 3] = src[s + 3]
  }
}

///|
/// Grows light areas (each pixel takes its brightest 4-neighbour).
pub fn dilate(pixels : FixedArray[Byte], width : Int32) -> Unit {
  morph(pixels, width, true)
}

///|
/// Grows dark areas (each pixel takes its darkest 4-neighbour).
pub fn erode(pixels : FixedArray[Byte], width : Int32) -> Unit {
  morph(pixels, width, false)
}

///|
/// Box blur with the given radius (in pixels), three passes to approximate
/// a Gaussian. Alpha-weighted so transparent pixels don't darken edges.
pub fn blur(pixels : FixedArray[Byte], width : Int32, radius : Double) -> Unit {
  let r = radius.round().to_int()
  if r < 1 || width <= 0 {
    return
  }
  let height = pixels.length() / 4 / width
  let buf = FixedArray::make(pixels.length(), 0.0)
  for i in 0..<(pixels.length() / 4) {
    let a = pixels[i * 4 + 3].to_double() / 255
    buf[i * 4] = pixels[i * 4].to_double() * a
    buf[i * 4 + 1] = pixels[i * 4 + 1].to_double() * a
    buf[i * 4 + 2] = pixels[i * 4 + 2].to_double() * a
    buf[i * 4 + 3] = a
  }
  let tmp = FixedArray::make(pixels.length(), 0.0)
  let pass = (
    src : FixedArray[Double],
    dst : FixedArray[Double],
    horizontal : Bool,
  ) => {
    let (outer, inner) = if horizontal {
      (height, width)
    } else {
      (width, height)
    }
    for o in 0..<outer {
      let idx = (k : Int32) => {
        if horizontal {
          (o * width + k) * 4
        } else {
          (k * width + o) * 4
        }
      }
      for c in 0..<4 {
        let mut sum = 0.0
        let mut n = 0
        for k in 0..<=r.min(inner - 1) {
          sum += src[idx(k) + c]
          n += 1
        }
        for k in 0..<inner {
          dst[idx(k) + c] = sum / n.to_double()
          let add = k + r + 1
          let sub = k - r
          if add < inner {
            sum += src[idx(add) + c]
            n += 1
          }
          if sub >= 0 {
            sum -= src[idx(sub) + c]
            n -= 1
          }
        }
      }
    }
  }
  for _ in 0..<3 {
    pass(buf, tmp, true)
    pass(tmp, buf, false)
  }
  for i in 0..<(pixels.length() / 4) {
    let a = buf[i * 4 + 3]
    let inv = if a > 0 { 1.0 / a } else { 0 }
    pixels[i * 4] = clamp_byte(buf[i * 4] * inv)
    pixels[i * 4 + 1] = clamp_byte(buf[i * 4 + 1] * inv)
    pixels[i * 4 + 2] = clamp_byte(buf[i * 4 + 2] * inv)
    pixels[i * 4 + 3] = clamp_byte(a * 255)
  }
}
