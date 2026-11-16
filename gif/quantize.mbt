// Port of gifenc's pnnquant2.js (MIT, Matt DesLauriers), itself modified
// from PnnQuant.js (Mark Tyler, Dmitry Groshev, Miller Cy Chan): pairwise
// nearest-neighbour colour quantization. p5.js uses it for saveGif().

///|
/// How colors are binned before quantization.
#derive(Eq, Debug)
pub(all) enum ColorFormat {
  Rgb565
  Rgb444
  Rgba4444
}

///|
priv struct Bin {
  mut ac : Double
  mut rc : Double
  mut gc : Double
  mut bc : Double
  mut cnt : Double
  mut nn : Int32
  mut fw : Int32
  mut bk : Int32
  mut tm : Int32
  mut mtm : Int32
  mut err : Double
}

///|
fn Bin::new() -> Bin {
  {
    ac: 0,
    rc: 0,
    gc: 0,
    bc: 0,
    cnt: 0,
    nn: 0,
    fw: 0,
    bk: 0,
    tm: 0,
    mtm: 0,
    err: 0,
  }
}

///|
pub fn rgb888_to_rgb565(r : Int32, g : Int32, b : Int32) -> Int32 {
  ((r << 8) & 0xf800) | ((g << 2) & 0x03e0) | (b >> 3)
}

///|
pub fn rgba8888_to_rgba4444(
  r : Int32,
  g : Int32,
  b : Int32,
  a : Int32,
) -> Int32 {
  (r >> 4) | (g & 0xf0) | ((b & 0xf0) << 4) | ((a & 0xf0) << 8)
}

///|
pub fn rgb888_to_rgb444(r : Int32, g : Int32, b : Int32) -> Int32 {
  (r >> 4 << 8) | (g & 0xf0) | (b >> 4)
}

///|
fn sqr(v : Double) -> Double {
  v * v
}

///|
fn find_nn(bins : Array[Bin], idx : Int32, has_alpha : Bool) -> Unit {
  let mut nn = 0
  let mut err = 1.0e100
  let bin1 = bins[idx]
  let n1 = bin1.cnt
  let wa = bin1.ac
  let wr = bin1.rc
  let wg = bin1.gc
  let wb = bin1.bc
  let mut i = bin1.fw
  while i != 0 {
    let bin = bins[i]
    let next = bin.fw
    let n2 = bin.cnt
    let nerr2 = n1 * n2 / (n1 + n2)
    if nerr2 < err {
      let mut nerr = 0.0
      let mut ok = true
      if has_alpha {
        nerr += nerr2 * sqr(bin.ac - wa)
        ok = nerr < err
      }
      if ok {
        nerr += nerr2 * sqr(bin.rc - wr)
        ok = nerr < err
      }
      if ok {
        nerr += nerr2 * sqr(bin.gc - wg)
        ok = nerr < err
      }
      if ok {
        nerr += nerr2 * sqr(bin.bc - wb)
        ok = nerr < err
      }
      if ok {
        err = nerr
        nn = i
      }
    }
    i = next
  }
  bin1.err = err
  bin1.nn = nn
}

///|
/// JavaScript `Math.round`.
fn js_round(v : Double) -> Double {
  (v + 0.5).floor()
}

///|
fn clamp_byte(v : Double) -> Int32 {
  js_round(v).max(0).min(255).to_int()
}

///|
/// Reduces RGBA pixels to at most `max_colors` colors. Each palette entry is
/// `[r, g, b]`, or `[r, g, b, a]` for `Rgba4444`. With `one_bit_alpha`,
/// alpha becomes 0 or 255 around that threshold.
pub fn quantize(
  rgba : FixedArray[Byte],
  max_colors : Int32,
  format~ : ColorFormat = Rgb565,
  one_bit_alpha? : Int32,
  clear_alpha~ : Bool = true,
  clear_alpha_color~ : Int32 = 0,
  clear_alpha_threshold~ : Int32 = 0,
  use_sqrt~ : Bool = true,
) -> Array[Array[Int32]] {
  let has_alpha = format is Rgba4444
  let bincount = if format is Rgb444 { 4096 } else { 65536 }
  let sparse : Array[Bin?] = Array::make(bincount, None)
  let size = rgba.length() / 4
  for k in 0..<size {
    let r = rgba[k * 4].to_int()
    let g = rgba[k * 4 + 1].to_int()
    let b = rgba[k * 4 + 2].to_int()
    let a = rgba[k * 4 + 3].to_int()
    let index = match format {
      Rgba4444 => rgba8888_to_rgba4444(r, g, b, a)
      Rgb444 => rgb888_to_rgb444(r, g, b)
      Rgb565 => rgb888_to_rgb565(r, g, b)
    }
    let bin = match sparse[index] {
      Some(bin) => bin
      None => {
        let bin = Bin::new()
        sparse[index] = Some(bin)
        bin
      }
    }
    bin.rc += r.to_double()
    bin.gc += g.to_double()
    bin.bc += b.to_double()
    if has_alpha {
      bin.ac += a.to_double()
    }
    bin.cnt += 1
  }
  // Cluster nonempty bins at one end of the array.
  let bins : Array[Bin] = []
  for slot in sparse {
    if slot is Some(bin) {
      let d = 1.0 / bin.cnt
      if has_alpha {
        bin.ac *= d
      }
      bin.rc *= d
      bin.gc *= d
      bin.bc *= d
      bins.push(bin)
    }
  }
  let maxbins = bins.length()
  if maxbins == 0 {
    return []
  }
  let mut use_sqrt = use_sqrt
  if sqr(max_colors.to_double()) / maxbins.to_double() < 0.022 {
    use_sqrt = false
  }
  for i in 0..<(maxbins - 1) {
    bins[i].fw = i + 1
    bins[i + 1].bk = i
    if use_sqrt {
      bins[i].cnt = bins[i].cnt.sqrt()
    }
  }
  if use_sqrt {
    bins[maxbins - 1].cnt = bins[maxbins - 1].cnt.sqrt()
  }
  let deleted = bincount - 1
  let heap = FixedArray::make(bincount + 1, 0)
  // Initialize nearest neighbours and build a heap of them.
  for i in 0..<maxbins {
    find_nn(bins, i, false)
    let err = bins[i].err
    heap[0] += 1
    let mut l = heap[0]
    while l > 1 {
      let l2 = l >> 1
      let h = heap[l2]
      if bins[h].err <= err {
        break
      }
      heap[l] = h
      l = l2
    }
    heap[l] = i
  }
  // Merge the bins which increase the error the least.
  let extbins = maxbins - max_colors
  let mut i = 0
  while i < extbins {
    let mut tb = bins[0]
    for ;; {
      let mut b1 = heap[1]
      tb = bins[b1]
      if tb.tm >= tb.mtm && bins[tb.nn].mtm <= tb.tm {
        break
      }
      if tb.mtm == deleted {
        b1 = heap[heap[0]]
        heap[1] = b1
        heap[0] -= 1
      } else {
        find_nn(bins, b1, false)
        tb.tm = i
      }
      let err = bins[b1].err
      let mut l = 1
      while l + l <= heap[0] {
        let mut l2 = l + l
        if l2 < heap[0] && bins[heap[l2]].err > bins[heap[l2 + 1]].err {
          l2 += 1
        }
        let h = heap[l2]
        if err <= bins[h].err {
          break
        }
        heap[l] = h
        l = l2
      }
      heap[l] = b1
    }
    let nb = bins[tb.nn]
    let n1 = tb.cnt
    let n2 = nb.cnt
    let d = 1.0 / (n1 + n2)
    if has_alpha {
      tb.ac = d * (n1 * tb.ac + n2 * nb.ac)
    }
    tb.rc = d * (n1 * tb.rc + n2 * nb.rc)
    tb.gc = d * (n1 * tb.gc + n2 * nb.gc)
    tb.bc = d * (n1 * tb.bc + n2 * nb.bc)
    tb.cnt += nb.cnt
    i += 1
    tb.mtm = i
    bins[nb.bk].fw = nb.fw
    bins[nb.fw].bk = nb.bk
    nb.mtm = deleted
  }
  // Fill the palette.
  let palette : Array[Array[Int32]] = []
  let mut k = 0
  for ;; {
    let bin = bins[k]
    let mut r = clamp_byte(bin.rc)
    let mut g = clamp_byte(bin.gc)
    let mut b = clamp_byte(bin.bc)
    let mut a = 255
    if has_alpha {
      a = clamp_byte(bin.ac)
      if one_bit_alpha is Some(threshold) {
        a = if a <= threshold { 0 } else { 255 }
      }
      if clear_alpha && a <= clear_alpha_threshold {
        r = clear_alpha_color
        g = clear_alpha_color
        b = clear_alpha_color
        a = 0
      }
    }
    let color = if has_alpha { [r, g, b, a] } else { [r, g, b] }
    if !palette.any(p => p == color) {
      palette.push(color)
    }
    k = bin.fw
    if k == 0 {
      break
    }
  }
  palette
}

///|
/// Index of the palette color closest to `pixel` (squared Euclidean
/// distance over the components both have), like gifenc's
/// `nearestColorIndex`.
pub fn nearest_color_index(
  palette : ArrayView[Array[Int32]],
  pixel : ArrayView[Int32],
) -> Int32 {
  let mut best = -1
  let mut best_dist = @double.infinity
  for j, color in palette {
    let n = pixel.length().min(color.length())
    let mut dist = 0.0
    for c in 0..<n {
      let dx = (pixel[c] - color[c]).to_double()
      dist += dx * dx
    }
    if dist < best_dist {
      best_dist = dist
      best = j
    }
  }
  best
}

///|
fn nearest_rgba(
  r : Int32,
  g : Int32,
  b : Int32,
  a : Int32,
  palette : ArrayView[Array[Int32]],
) -> Int32 {
  let mut k = 0
  let mut mindist = 1.0e100
  for i, px in palette {
    let a2 = if px.length() > 3 { px[3] } else { 255 }
    let mut d = sqr((a2 - a).to_double())
    if d > mindist {
      continue
    }
    d += sqr((px[0] - r).to_double())
    if d > mindist {
      continue
    }
    d += sqr((px[1] - g).to_double())
    if d > mindist {
      continue
    }
    d += sqr((px[2] - b).to_double())
    if d > mindist {
      continue
    }
    mindist = d
    k = i
  }
  k
}

///|
/// Maps every pixel to the index of its nearest palette color, caching by
/// binned color, like gifenc's `applyPalette`.
pub fn apply_palette(
  rgba : FixedArray[Byte],
  palette : ArrayView[Array[Int32]],
  format~ : ColorFormat = Rgb565,
) -> FixedArray[Byte] {
  let n = rgba.length() / 4
  let index = FixedArray::make(n, (0 : Byte))
  let cache : Map[Int32, Int32] = Map([])
  for i in 0..<n {
    let r = rgba[i * 4].to_int()
    let g = rgba[i * 4 + 1].to_int()
    let b = rgba[i * 4 + 2].to_int()
    let a = rgba[i * 4 + 3].to_int()
    let key = match format {
      Rgba4444 => rgba8888_to_rgba4444(r, g, b, a)
      Rgb444 => rgb888_to_rgb444(r, g, b)
      Rgb565 => rgb888_to_rgb565(r, g, b)
    }
    let idx = match cache.get(key) {
      Some(idx) => idx
      None => {
        let idx = if format is Rgba4444 {
          nearest_rgba(r, g, b, a, palette)
        } else {
          nearest_rgba(r, g, b, 255, palette.map(c => [c[0], c[1], c[2], 255]))
        }
        cache[key] = idx
        idx
      }
    }
    index[i] = idx.to_byte()
  }
  index
}
