// Port of p5.js src/color/{creating_reading,setting}.js.

///|
/// Values accepted wherever p5.js accepts color arguments: a gray level
/// (`Int`/`Double`), a `(gray, alpha)` pair, a 3- or 4-tuple of channels, a
/// CSS string or a `Color`. Numbers are interpreted with the current
/// `color_mode()` and its maxes.
///
/// ```mbt nocheck
/// p.fill(200)                 // gray
/// p.fill((255, 0, 0))         // red
/// p.fill((0, 0, 255, 128))    // translucent blue
/// p.fill("#ff8800")           // CSS
/// p.fill(p.color((120, 80, 90)))
/// ```
pub(open) trait ColorArg {
  fn to_color(Self, P5) -> Color
}

///|
fn P5::make_color(self : P5, values : ArrayView[Double]) -> Color {
  let mode = self.state.color_mode
  Color::new(values, mode, self.state.color_maxes[mode])
}

///|
pub impl ColorArg for Color with fn to_color(self, _) {
  self
}

///|
pub impl ColorArg for Int32 with fn to_color(self, p) {
  p.make_color([self.to_double()])
}

///|
pub impl ColorArg for Double with fn to_color(self, p) {
  p.make_color([self])
}

///|
/// Numbers accepted inside color tuples (`Int` or `Double`).
pub(open) trait Num {
  fn to_num(Self) -> Double
}

///|
pub impl Num for Int32 with fn to_num(self) {
  self.to_double()
}

///|
pub impl Num for Double with fn to_num(self) {
  self
}

///|
/// `(gray, alpha)`
pub impl[A : Num, B : Num] ColorArg for (A, B) with fn to_color(self, p) {
  p.make_color([self.0.to_num(), self.1.to_num()])
}

///|
/// `(c0, c1, c2)`
pub impl[A : Num, B : Num, C : Num] ColorArg for (A, B, C) with fn to_color(
  self,
  p,
) {
  p.make_color([self.0.to_num(), self.1.to_num(), self.2.to_num()])
}

///|
/// `(c0, c1, c2, alpha)`
pub impl[A : Num, B : Num, C : Num, D : Num] ColorArg for (A, B, C, D) with fn to_color(
  self,
  p,
) {
  p.make_color([
    self.0.to_num(),
    self.1.to_num(),
    self.2.to_num(),
    self.3.to_num(),
  ])
}

///|
/// CSS color strings. Invalid strings produce black and a console warning.
pub impl ColorArg for String with fn to_color(self, _) {
  match Color::parse(self) {
    Some(c) => c
    None => {
      warn("Invalid color string: \{self}")
      Color::rgb(0, 0, 0)
    }
  }
}

///|
/// `[v]`, `[gray, alpha]`, `[c0, c1, c2]` or `[c0, c1, c2, alpha]`.
pub impl ColorArg for Array[Double] with fn to_color(self, p) {
  p.make_color(self)
}

///|
fn warn(msg : String) -> Unit {
  @dom.console_warn("🌸 p5.mbt says: " + msg)
}

///|
/// Creates a color using the current color mode, like p5's `color()`.
pub fn[C : ColorArg] P5::color(self : P5, c : C) -> Color {
  c.to_color(self)
}

///|
/// Sets how color numbers are interpreted (`colorMode(mode)`).
pub fn P5::color_mode(self : P5, mode : ColorMode) -> Unit {
  self.state.color_mode = mode
}

///|
/// Sets the color mode and the maximum of every channel, like
/// `colorMode(mode, max)`.
pub fn P5::color_mode_max(self : P5, mode : ColorMode, max : Double) -> Unit {
  self.state.color_mode = mode
  self.state.color_maxes[mode] = @color.maxes(max, max, max, max)
}

///|
/// Sets the color mode and per-channel maxima, like
/// `colorMode(mode, max1, max2, max3, maxA)`.
pub fn P5::color_mode_maxes(
  self : P5,
  mode : ColorMode,
  max1 : Double,
  max2 : Double,
  max3 : Double,
  max_alpha? : Double,
) -> Unit {
  self.state.color_mode = mode
  let alpha = match max_alpha {
    Some(a) => a
    None => self.state.color_maxes[mode][3].1
  }
  self.state.color_maxes[mode] = @color.maxes(max1, max2, max3, alpha)
}

///|
/// The current color mode.
pub fn P5::get_color_mode(self : P5) -> ColorMode {
  self.state.color_mode
}

///|
/// Red component of a color, in the current RGB range.
pub fn[C : ColorArg] P5::red(self : P5, c : C) -> Double {
  c.to_color(self).red(max=self.state.color_maxes[RGB][0].1)
}

///|
/// Green component of a color, in the current RGB range.
pub fn[C : ColorArg] P5::green(self : P5, c : C) -> Double {
  c.to_color(self).green(max=self.state.color_maxes[RGB][1].1)
}

///|
/// Blue component of a color, in the current RGB range.
pub fn[C : ColorArg] P5::blue(self : P5, c : C) -> Double {
  c.to_color(self).blue(max=self.state.color_maxes[RGB][2].1)
}

///|
/// Alpha of a color, in the current mode's alpha range.
pub fn[C : ColorArg] P5::alpha(self : P5, c : C) -> Double {
  let mode = self.state.color_mode
  c.to_color(self).alpha(max=self.state.color_maxes[mode][3].1)
}

///|
/// Hue of a color (HSB/HSL range when in those modes, HSL otherwise).
pub fn[C : ColorArg] P5::hue(self : P5, c : C) -> Double {
  let (mode, i) = match self.state.color_mode {
    HSB => (ColorMode::HSB, 0)
    LCH => (LCH, 2)
    OKLCH => (OKLCH, 2)
    _ => (HSL, 0)
  }
  c.to_color(self).hue(max=self.state.color_maxes[mode][i].1)
}

///|
/// Saturation of a color.
pub fn[C : ColorArg] P5::saturation(self : P5, c : C) -> Double {
  let mode = if self.state.color_mode is HSB { ColorMode::HSB } else { HSL }
  c.to_color(self).saturation(max=self.state.color_maxes[mode][1].1)
}

///|
/// HSB brightness of a color.
pub fn[C : ColorArg] P5::brightness(self : P5, c : C) -> Double {
  c.to_color(self).brightness(max=self.state.color_maxes[HSB][2].1)
}

///|
/// HSL lightness of a color.
pub fn[C : ColorArg] P5::lightness(self : P5, c : C) -> Double {
  c.to_color(self).lightness(max=self.state.color_maxes[HSL][2].1)
}

///|
/// Blends two colors, interpolating in the current color mode.
pub fn P5::lerp_color(self : P5, c1 : Color, c2 : Color, amt : Double) -> Color {
  let mode = self.state.color_mode
  c1.lerp(c2, amt, lerp_mode=mode, output_mode=mode)
}

///|
/// Sets the fill color.
pub fn[C : ColorArg] P5::fill(self : P5, c : C) -> Unit {
  self.state.fill = Some(c.to_color(self))
  self.state.fill_set = true
  if self.gl is Some(r) {
    r.on_fill()
  }
}

///|
/// Disables filling shapes.
pub fn P5::no_fill(self : P5) -> Unit {
  self.state.fill = None
}

///|
/// Sets the stroke (outline) color.
pub fn[C : ColorArg] P5::stroke(self : P5, c : C) -> Unit {
  self.state.stroke = Some(c.to_color(self))
  self.state.stroke_set = true
}

///|
/// Disables drawing outlines.
pub fn P5::no_stroke(self : P5) -> Unit {
  self.state.stroke = None
}

///|
/// The current fill color, if any.
pub fn P5::get_fill(self : P5) -> Color? {
  self.state.fill
}

///|
/// The current stroke color, if any.
pub fn P5::get_stroke(self : P5) -> Color? {
  self.state.stroke
}

///|
/// Fills the whole canvas with a color (ignores the current transform).
pub fn[C : ColorArg] P5::background(self : P5, c : C) -> Unit {
  let color = c.to_color(self)
  if self.gl is Some(r) {
    let (red, g, b, a) = color.to_srgb()
    r.clear(red, g, b, a)
    return
  }
  self.surface.save()
  self.surface.set_transform(@math.identity.scale(self.density, self.density))
  if self.state.erasing {
    self.surface.set_blend_mode(Blend)
  }
  self.surface.fill_rect(0, 0, self.width, self.height, color.to_css())
  self.surface.restore()
}

///|
/// Makes every pixel of the canvas transparent.
pub fn P5::clear(self : P5) -> Unit {
  if self.gl is Some(r) {
    r.clear(0, 0, 0, 0)
    return
  }
  self.surface.save()
  self.surface.set_transform(@math.identity)
  self.surface.clear_rect(
    0,
    0,
    self.width * self.density,
    self.height * self.density,
  )
  self.surface.restore()
}

///|
/// Starts erasing: subsequent shapes remove pixels instead of painting.
/// `strength_fill` / `strength_stroke` (0-255) control how much is erased.
pub fn P5::erase(
  self : P5,
  strength_fill~ : Double = 255,
  strength_stroke~ : Double = 255,
) -> Unit {
  if !self.state.erasing {
    self.state.erasing = true
    self.erase_strength = (strength_fill, strength_stroke)
    self.surface.set_blend_mode(Remove)
  }
}

///|
/// Stops erasing.
pub fn P5::no_erase(self : P5) -> Unit {
  if self.state.erasing {
    self.state.erasing = false
    self.surface.set_blend_mode(self.state.blend_mode)
  }
}

///|
/// Sets how new pixels are combined with existing ones.
pub fn P5::blend_mode(self : P5, mode : BlendMode) -> Unit {
  self.state.blend_mode = mode
  if !self.state.erasing {
    self.surface.set_blend_mode(mode)
  }
}
