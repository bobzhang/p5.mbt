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
/// Blurs with p5's `blurARGB`: a triangular kernel of radius
/// `trunc(radius × 3.5)` (clamped to 1–248), applied horizontally then
/// vertically on the packed ARGB values.
pub fn blur(pixels : FixedArray[Byte], width : Int32, radius : Double) -> Unit {
  if width <= 0 {
    return
  }
  let height = pixels.length() / 4 / width
  let n = width * height
  let mut r = (radius * 3.5).trunc().to_int()
  r = if r < 1 { 1 } else if r < 248 { r } else { 248 }
  let size = (1 + r) << 1
  // kernel and multiplication tables
  let kernel = FixedArray::make(size, 0L)
  let mut radiusi = r - 1
  for i in 1..<r {
    let bki = (radiusi * radiusi).to_int64()
    kernel[r + i] = bki
    kernel[radiusi] = bki
    radiusi -= 1
  }
  kernel[r] = (r * r).to_int64()
  let mult = (k : Int32, v : Int32) => kernel[k] * v.to_int64()
  let a = FixedArray::make(n, 0)
  let rr = FixedArray::make(n, 0)
  let g = FixedArray::make(n, 0)
  let b = FixedArray::make(n, 0)
  for j in 0..<n {
    a[j] = pixels[j * 4 + 3].to_int()
    rr[j] = pixels[j * 4].to_int()
    g[j] = pixels[j * 4 + 1].to_int()
    b[j] = pixels[j * 4 + 2].to_int()
  }
  let a2 = FixedArray::make(n, 0)
  let r2 = FixedArray::make(n, 0)
  let g2 = FixedArray::make(n, 0)
  let b2 = FixedArray::make(n, 0)
  // horizontal pass
  let mut yi = 0
  for _y in 0..<height {
    for x in 0..<width {
      let mut ca = 0L
      let mut cr = 0L
      let mut cg = 0L
      let mut cb = 0L
      let mut sum = 0L
      let mut read = x - r
      let bk0 = if read < 0 {
        let k = -read
        read = 0
        k
      } else {
        0
      }
      for i in bk0..<size {
        if read >= width {
          break
        }
        let c = read + yi
        ca += mult(i, a[c])
        cr += mult(i, rr[c])
        cg += mult(i, g[c])
        cb += mult(i, b[c])
        sum += kernel[i]
        read += 1
      }
      let ri = yi + x
      a2[ri] = (ca / sum).to_int()
      r2[ri] = (cr / sum).to_int()
      g2[ri] = (cg / sum).to_int()
      b2[ri] = (cb / sum).to_int()
    }
    yi += width
  }
  // vertical pass
  yi = 0
  let mut ym = -r
  let mut ymi = ym * width
  for _y in 0..<height {
    for x in 0..<width {
      let mut ca = 0L
      let mut cr = 0L
      let mut cg = 0L
      let mut cb = 0L
      let mut sum = 0L
      let (bk0, ri0, read0) = if ym < 0 {
        (-ym, -ym, x)
      } else {
        (0, ym, x + ymi)
      }
      let mut ri = ri0
      let mut read = read0
      if ym < height {
        for i in bk0..<size {
          if ri >= height {
            break
          }
          ca += mult(i, a2[read])
          cr += mult(i, r2[read])
          cg += mult(i, g2[read])
          cb += mult(i, b2[read])
          sum += kernel[i]
          ri += 1
          read += width
        }
      }
      let o = (x + yi) * 4
      if sum > 0L {
        pixels[o] = (cr / sum).to_int().to_byte()
        pixels[o + 1] = (cg / sum).to_int().to_byte()
        pixels[o + 2] = (cb / sum).to_int().to_byte()
        pixels[o + 3] = (ca / sum).to_int().to_byte()
      }
    }
    yi += width
    ymi += width
    ym += 1
  }
}
