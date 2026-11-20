// Port of p5.js src/color/p5.Color.js.
//
// p5.js 2.x delegates to color.js; this port keeps the same model: a color
// stores its coordinates in the native range of the space it was created in
// (sRGB in [0, 1], HSB/HSL/HWB in [0, 360] x [0, 100] x [0, 100], ...) plus
// an alpha in [0, 1].

///|
/// A color, stored in the space it was created in.
pub struct Color {
  priv mode : ColorMode
  priv coords : FixedArray[Double]
  priv mut alpha : Double
  priv mut default_string : String?
}

///|
/// Creates a color from native coordinates of `mode` (no range mapping).
/// For RGB the coordinates are in `[0, 1]`.
pub fn Color::from_native(
  mode : ColorMode,
  c0 : Double,
  c1 : Double,
  c2 : Double,
  alpha~ : Double = 1,
) -> Color {
  { mode, coords: [c0, c1, c2], alpha, default_string: None, }
}

///|
/// Creates an sRGB color from components in `[0, 255]`.
///
/// ```mbt check
/// test {
///   inspect(@color.Color::rgb(255, 128, 0).to_css(), content="#ff8000")
///   inspect(@color.Color::rgb(255, 0, 0, alpha=128).to_css(), content="#ff000080")
/// }
/// ```
pub fn Color::rgb(
  r : Double,
  g : Double,
  b : Double,
  alpha~ : Double = 255,
) -> Color {
  Color::new([r, g, b, alpha], RGB, default_maxes(RGB))
}

///|
/// Creates a color from user values the way p5's `color(...)` does.
///
/// `values` holds 1 (gray), 2 (gray, alpha), 3 (channels) or 4
/// (channels, alpha) numbers in the ranges given by `maxes`.
/// Values are clamped to the ranges unless `clamp=false`.
///
/// # Panics
/// Panics if `values` is empty or holds more than 4 numbers.
pub fn Color::new(
  values : ArrayView[Double],
  mode : ColorMode,
  maxes : ColorMaxes,
  clamp~ : Bool = true,
) -> Color {
  let native = native_ranges(mode)
  let map_channel = (v : Double, i : Int32) => {
    let (lo, hi) = maxes[i]
    let (nlo, nhi) = native[i]
    map_range(v, lo, hi, nlo, nhi, clamp)
  }
  let gray = fn(v : Double) -> FixedArray[Double] {
    match mode {
      RGB | RGBP3 => {
        let (lo, hi) = maxes[2]
        let g = map_range(v, lo, hi, 0, 1, clamp)
        [g, g, g]
      }
      HSB | HSL => {
        let (lo, hi) = maxes[2]
        [0, 0, map_range(v, lo, hi, 0, 100, clamp)]
      }
      HWB => {
        let wb_max = (maxes[1].0 - maxes[1].1).abs() / 2 +
          (maxes[2].0 - maxes[2].1).abs() / 2
        let n = map_range(v, 0, wb_max, 0, 100, false)
        if n < 50 {
          [0, 100 - n, n]
        } else {
          [0, n, 100 - n]
        }
      }
      LAB | LCH | OKLAB | OKLCH => {
        let (lo, hi) = maxes[0]
        let l = map_range(v, lo, hi, 0, 100, clamp)
        // Lightness of OKLab/OKLCH is natively in [0, 1].
        let l = if mode is (OKLAB | OKLCH) { l / 100 } else { l }
        [l, 0, 0]
      }
    }
  }
  let (coords, alpha) : (FixedArray[Double], Double) = match values {
    [g] => (gray(g), 1)
    [g, a] => (gray(g), map_channel(a, 3))
    [c0, c1, c2] =>
      ([map_channel(c0, 0), map_channel(c1, 1), map_channel(c2, 2)], 1)
    [c0, c1, c2, a] =>
      (
        [map_channel(c0, 0), map_channel(c1, 1), map_channel(c2, 2)],
        map_channel(a, 3),
      )
    _ => abort("Color::new expects 1 to 4 values")
  }
  let default_string = if mode is RGB {
    Some(hex_string(coords[0], coords[1], coords[2], alpha))
  } else {
    None
  }
  { mode, coords, alpha, default_string, }
}

///|
fn hex_component(v : Double) -> String {
  // `~~(v * 255)` in JavaScript: truncate towards zero.
  let i = (v * 255).trunc().to_int()
  let i = if i < 0 { 0 } else if i > 255 { 255 } else { i }
  let digits = "0123456789abcdef"
  let s = StringBuilder()
  s.write_char(digits.get_char(i / 16).unwrap())
  s.write_char(digits.get_char(i % 16).unwrap())
  s.to_string()
}

///|
fn hex_string(r : Double, g : Double, b : Double, a : Double) -> String {
  let base = "#\{hex_component(r)}\{hex_component(g)}\{hex_component(b)}"
  if a == 1 {
    base
  } else {
    base + hex_component(a)
  }
}

///|
/// The color mode (space) the color is stored in.
pub fn Color::mode(self : Color) -> ColorMode {
  self.mode
}

///|
/// Raw coordinates in the native range of the color's space.
pub fn Color::coords(self : Color) -> (Double, Double, Double) {
  (self.coords[0], self.coords[1], self.coords[2])
}

///|
/// Gamma-encoded sRGB components and alpha, all in `[0, 1]` (not clamped
/// for out-of-gamut colors).
pub fn Color::to_srgb(self : Color) -> (Double, Double, Double, Double) {
  let (r, g, b) = to_srgb(self.mode, self.coords)
  (r, g, b, self.alpha)
}

///|
/// sRGB components and alpha mapped to `maxes` (like p5's `_getRGBA`).
pub fn Color::rgba(
  self : Color,
  maxes~ : ColorMaxes = default_maxes(RGB),
) -> (Double, Double, Double, Double) {
  let (r, g, b, a) = self.to_srgb()
  (
    map_range(r, 0, 1, maxes[0].0, maxes[0].1, false),
    map_range(g, 0, 1, maxes[1].0, maxes[1].1, false),
    map_range(b, 0, 1, maxes[2].0, maxes[2].1, false),
    map_range(a, 0, 1, maxes[3].0, maxes[3].1, false),
  )
}

///|
/// Converts the color to another space.
pub fn Color::to_mode(self : Color, mode : ColorMode) -> Color {
  if mode == self.mode {
    return {
      mode,
      coords: self.coords.copy(),
      alpha: self.alpha,
      default_string: self.default_string,
    }
  }
  let (r, g, b) = to_srgb(self.mode, self.coords)
  let (c0, c1, c2) = from_srgb(mode, r, g, b)
  { mode, coords: [c0, c1, c2], alpha: self.alpha, default_string: None, }
}

///|
fn clamp01(v : Double) -> Double {
  if v.is_nan() {
    0
  } else {
    v.max(0).min(1)
  }
}

///|
fn percent(v : Double) -> String {
  let r = @math.round(clamp01(v) * 100, decimals=2)
  "\{r}%"
}

///|
/// A CSS color string for the color, as used for `fillStyle`.
///
/// RGB colors created from channel values serialize as `#rrggbb` or
/// `#rrggbbaa` like p5.js; other colors serialize as CSS `rgb()` in percent.
pub fn Color::to_css(self : Color) -> String {
  match self.default_string {
    Some(s) => s
    None => {
      let (r, g, b, a) = self.to_srgb()
      if self.mode is RGB {
        return hex_string(clamp01(r), clamp01(g), clamp01(b), clamp01(a))
      }
      if self.mode is RGBP3 {
        // keep the wide-gamut coordinates (colorjs serializes P3 this way)
        let c = self.coords
        let n = (v : Double) => @math.round(clamp01(v), decimals=5).to_string()
        let base = "color(display-p3 \{n(c[0])} \{n(c[1])} \{n(c[2])}"
        return if a < 1 { base + " / \{clamp01(a)})" } else { base + ")" }
      }
      let base = "rgb(\{percent(r)} \{percent(g)} \{percent(b)}"
      if a < 1 {
        base + " / \{clamp01(a)})"
      } else {
        base + ")"
      }
    }
  }
}

///|
pub impl Show for Color with fn output(self, logger) {
  logger.write_string(self.to_css())
}

///|
/// Red channel mapped to `[0, max]` (sRGB).
pub fn Color::red(self : Color, max~ : Double = 255) -> Double {
  if self.mode is RGBP3 {
    return self.coords[0] * max
  }
  self.to_srgb().0 * max
}

///|
/// Green channel mapped to `[0, max]` (sRGB).
pub fn Color::green(self : Color, max~ : Double = 255) -> Double {
  if self.mode is RGBP3 {
    return self.coords[1] * max
  }
  self.to_srgb().1 * max
}

///|
/// Blue channel mapped to `[0, max]` (sRGB).
pub fn Color::blue(self : Color, max~ : Double = 255) -> Double {
  if self.mode is RGBP3 {
    return self.coords[2] * max
  }
  self.to_srgb().2 * max
}

///|
/// Alpha mapped to `[0, max]`.
pub fn Color::alpha(self : Color, max~ : Double = 255) -> Double {
  self.alpha * max
}

///|
/// Hue in `[0, max]`. Uses the color's own space when it has a hue channel,
/// otherwise HSL.
pub fn Color::hue(self : Color, max~ : Double = 360) -> Double {
  let c = match self.mode {
    HSB | HSL | HWB | LCH | OKLCH => self
    _ => self.to_mode(HSL)
  }
  let i = hue_index(c.mode).unwrap()
  c.coords[i] / 360 * max
}

///|
/// Saturation in `[0, max]` (HSB saturation for HSB colors, HSL otherwise).
pub fn Color::saturation(self : Color, max~ : Double = 100) -> Double {
  let c = if self.mode is HSB { self } else { self.to_mode(HSL) }
  c.coords[1] / 100 * max
}

///|
/// HSB brightness in `[0, max]`.
pub fn Color::brightness(self : Color, max~ : Double = 100) -> Double {
  self.to_mode(HSB).coords[2] / 100 * max
}

///|
/// HSL lightness in `[0, max]`.
pub fn Color::lightness(self : Color, max~ : Double = 100) -> Double {
  self.to_mode(HSL).coords[2] / 100 * max
}

///|
/// Sets the sRGB red channel from a value in `[0, max]`.
pub fn Color::set_red(self : Color, v : Double, max~ : Double = 255) -> Unit {
  self.set_srgb_channel(0, v / max)
}

///|
/// Sets the sRGB green channel from a value in `[0, max]`.
pub fn Color::set_green(self : Color, v : Double, max~ : Double = 255) -> Unit {
  self.set_srgb_channel(1, v / max)
}

///|
/// Sets the sRGB blue channel from a value in `[0, max]`.
pub fn Color::set_blue(self : Color, v : Double, max~ : Double = 255) -> Unit {
  self.set_srgb_channel(2, v / max)
}

///|
/// Sets the alpha from a value in `[0, max]`.
pub fn Color::set_alpha(self : Color, v : Double, max~ : Double = 255) -> Unit {
  self.default_string = None
  self.alpha = v / max
}

///|
fn Color::set_srgb_channel(self : Color, i : Int32, v : Double) -> Unit {
  self.default_string = None
  if self.mode is (RGB | RGBP3) {
    self.coords[i] = v
  } else {
    let (r, g, b) = to_srgb(self.mode, self.coords)
    let rgb : FixedArray[Double] = [r, g, b]
    rgb[i] = v
    let (c0, c1, c2) = from_srgb(self.mode, rgb[0], rgb[1], rgb[2])
    self.coords[0] = c0
    self.coords[1] = c1
    self.coords[2] = c2
  }
}

///|
fn is_achromatic(c : Color) -> Bool {
  match c.mode {
    HSB | HSL => c.coords[1] == 0
    HWB => c.coords[1] + c.coords[2] >= 100
    LCH | OKLCH => c.coords[1] == 0
    _ => false
  }
}

///|
/// Interpolates between two colors, like p5's `lerpColor()`.
///
/// Interpolation happens in `lerp_mode` (the space of `self` by default);
/// hues take the shorter way around the color wheel. The result is
/// expressed in `output_mode` (the space of `self` by default).
///
/// ```mbt check
/// test {
///   let a = @color.Color::rgb(255, 0, 0)
///   let b = @color.Color::rgb(0, 0, 255)
///   inspect(a.lerp(b, 0.5).to_css(), content="#7f007f")
/// }
/// ```
pub fn Color::lerp(
  self : Color,
  other : Color,
  amt : Double,
  lerp_mode? : ColorMode,
  output_mode? : ColorMode,
) -> Color {
  let lerp_mode = lerp_mode.unwrap_or(self.mode)
  let output_mode = output_mode.unwrap_or(self.mode)
  let a = self.to_mode(lerp_mode)
  let b = other.to_mode(lerp_mode)
  let coords = FixedArray::make(3, 0.0)
  for i in 0..<3 {
    coords[i] = a.coords[i] + (b.coords[i] - a.coords[i]) * amt
  }
  if hue_index(lerp_mode) is Some(h) {
    let (ha, hb) = match (is_achromatic(a), is_achromatic(b)) {
      (true, false) => (b.coords[h], b.coords[h])
      (false, true) => (a.coords[h], a.coords[h])
      _ => (a.coords[h], b.coords[h])
    }
    let mut delta = hb - ha
    if delta > 180 {
      delta -= 360
    } else if delta < -180 {
      delta += 360
    }
    let mut hue = ha + delta * amt
    if hue < 0 {
      hue += 360
    } else if hue >= 360 {
      hue -= 360
    }
    coords[h] = hue
  }
  let alpha = self.alpha + (other.alpha - self.alpha) * amt
  let mixed : Color = { mode: lerp_mode, coords, alpha, default_string: None, }
  mixed.to_mode(output_mode)
}

///|
/// Picks a color along a list of `(color, stop)` pairs, like p5's
/// `paletteLerp()`. Stops must be increasing.
///
/// # Panics
/// Panics if `stops` is empty.
pub fn palette_lerp(stops : ArrayView[(Color, Double)], amt : Double) -> Color {
  let (first, first_stop) = stops[0]
  if amt < first_stop {
    return first
  }
  for i in 1..<stops.length() {
    let (c, stop) = stops[i]
    if amt < stop {
      let (prev, prev_stop) = stops[i - 1]
      return prev.lerp(c, (amt - prev_stop) / (stop - prev_stop))
    }
  }
  stops[stops.length() - 1].0
}

///|
/// Returns `true` when two colors have the same sRGB components and alpha
/// (within 1e-9).
pub fn Color::same_as(self : Color, other : Color) -> Bool {
  let (r1, g1, b1, a1) = self.to_srgb()
  let (r2, g2, b2, a2) = other.to_srgb()
  let close = (x : Double, y : Double) => (x - y).abs() < 1.0e-9
  close(r1, r2) && close(g1, g2) && close(b1, b2) && close(a1, a2)
}

///|
/// WCAG 2.1 contrast ratio between two colors (1 to 21).
pub fn Color::contrast_ratio(self : Color, other : Color) -> Double {
  let lum = (c : Color) => {
    let (r, g, b, _) = c.to_srgb()
    0.2126 * srgb_to_linear(r) +
    0.7152 * srgb_to_linear(g) +
    0.0722 * srgb_to_linear(b)
  }
  let l1 = lum(self)
  let l2 = lum(other)
  let (hi, lo) = if l1 > l2 { (l1, l2) } else { (l2, l1) }
  (hi + 0.05) / (lo + 0.05)
}

///|
/// APCA lightness contrast (Lc) of text in `other` on a background of this
/// color, as colorjs.io's `contrastAPCA` computes it: positive for dark text
/// on a light background, negative for light text on a dark one.
pub fn Color::contrast_apca(self : Color, other : Color) -> Double {
  let linearize = (v : Double) => {
    let sign = if v < 0 { -1.0 } else { 1.0 }
    sign * @cmath.pow(v.abs(), 2.4)
  }
  let lum = (c : Color) => {
    let (r, g, b, _) = c.to_srgb()
    linearize(r) * 0.2126729 +
    linearize(g) * 0.7151522 +
    linearize(b) * 0.0721750
  }
  let fclamp = (y : Double) => {
    if y >= 0.022 {
      y
    } else {
      y + @cmath.pow(0.022 - y, 1.414)
    }
  }
  let y_txt = fclamp(lum(other))
  let y_bg = fclamp(lum(self))
  let c = if (y_bg - y_txt).abs() < 0.0005 {
    0.0
  } else if y_bg > y_txt {
    (@cmath.pow(y_bg, 0.56) - @cmath.pow(y_txt, 0.57)) * 1.14
  } else {
    (@cmath.pow(y_bg, 0.65) - @cmath.pow(y_txt, 0.62)) * 1.14
  }
  let sapc = if c.abs() < 0.1 {
    0.0
  } else if c > 0 {
    c - 0.027
  } else {
    c + 0.027
  }
  sapc * 100
}

///|
/// A contrast measure for `Color::contrast`.
#derive(Eq, Debug)
pub(all) enum ContrastMethod {
  /// WCAG 2.1 contrast ratio; passes at 4.5 or more.
  Wcag21
  /// APCA lightness contrast; passes at |Lc| of 75 or more.
  Apca
}

///|
/// Whether text in `other` on this color is readable by the given measure
/// (p5's `color.contrast(other, method)`).
pub fn Color::contrast(
  self : Color,
  other : Color,
  method~ : ContrastMethod = Wcag21,
) -> Bool {
  match method {
    Wcag21 => self.contrast_ratio(other) >= 4.5
    Apca => self.contrast_apca(other).abs() >= 75
  }
}

///|
/// Both contrast measures and whether they pass (p5's
/// `color.contrast(other, 'all')`).
#derive(Debug)
pub(all) struct ContrastReport {
  wcag21 : Double
  wcag21_passed_minimum : Bool
  wcag21_passed_aaa : Bool
  apca : Double
  apca_passed_minimum : Bool
}

///|
/// Every contrast measure between this color (background) and `other`.
pub fn Color::contrast_report(self : Color, other : Color) -> ContrastReport {
  let w = self.contrast_ratio(other)
  let a = self.contrast_apca(other)
  {
    wcag21: w,
    wcag21_passed_minimum: w >= 4.5,
    wcag21_passed_aaa: w >= 7,
    apca: a,
    apca_passed_minimum: a.abs() >= 75,
  }
}
