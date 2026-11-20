// Port of p5.js src/type/textCore.js together with the text parts of
// src/core/p5.Renderer2D.js (_renderText, _positionLines, _yAlignOffset).

///|
/// A font loaded with `load_font`; use it with `text_font_face`.
pub struct Font {
  /// The CSS font family name to draw with.
  family : String
  /// Whether the font finished loading.
  mut loaded : Bool
  /// The parsed font file, when it could be read (TTF, OTF, WOFF): needed
  /// for `text_to_points` and friends.
  mut data : @font.FontData?
  priv sketch : P5
}

///|
/// A text bounding box.
#derive(Eq, Debug)
pub(all) struct Bounds {
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
/// Splits on `/,\s+/` like p5's `CommaDelimRe` (a comma must be followed
/// by whitespace).
fn split_family_list(family : String) -> Array[String] {
  let chars = family.to_array()
  let parts : Array[String] = []
  let cur = StringBuilder()
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == ',' && i + 1 < chars.length() && chars[i + 1].is_ascii_whitespace() {
      parts.push(cur.to_string())
      cur.reset()
      i += 1
      while i < chars.length() && chars[i].is_ascii_whitespace() {
        i += 1
      }
    } else {
      cur.write_char(c)
      i += 1
    }
  }
  parts.push(cur.to_string())
  parts
}

///|
/// Quotes family names that contain spaces or non-ASCII characters, like
/// p5's `_parseFontFamily`.
fn parse_font_family(family : String) -> String {
  split_family_list(family)
  .map(part => {
    let part = part.trim().to_owned()
    let quoted = part.length() >= 2 &&
      part.has_prefix("\"") &&
      part.has_suffix("\"")
    let special = part.contains(" ") || part.to_array().any(c => !c.is_ascii())
    if special && !quoted {
      "\"\{part}\""
    } else {
      part
    }
  })
  .join(", ")
}

///|
fn TextStyle::css(self : TextStyle) -> String {
  match self {
    Normal => "normal"
    Italic => "italic"
    Bold => "bold"
    BoldItalic => "bold italic"
  }
}

///|
/// The CSS font string, built exactly like p5's `_applyFontString`.
fn P5::font_string(self : P5) -> String {
  let s = self.state
  let style = if s.text_style is Normal { "" } else { s.text_style.css() + " " }
  let variant = if s.font_variant == "normal" {
    ""
  } else {
    s.font_variant + " "
  }
  let weight = if s.font_weight == "normal" { "" } else { s.font_weight + " " }
  "\{style}\{variant}\{weight}\{@dom.number_to_string(s.text_size)}px \{parse_font_family(s.text_font)}"
  .trim()
  .to_owned()
}

///|
fn P5::apply_text_style(self : P5, baseline? : VAlign) -> Unit {
  self.surface.set_text_style(
    self.font_string(),
    self.state.text_align,
    baseline.unwrap_or(self.state.text_baseline),
    self.state.text_direction,
  )
  self.apply_text_props()
}

///|
/// Sets the font size in pixels. Unless `text_leading` was set, the leading
/// becomes `1.275 × size`.
pub fn P5::text_size(self : P5, size : Double) -> Unit {
  if size != self.state.text_size {
    self.state.text_size = size
    if !self.state.leading_set {
      self.state.text_leading = size * 1.275
    }
  }
}

///|
/// The current font size.
pub fn P5::get_text_size(self : P5) -> Double {
  self.state.text_size
}

///|
/// Sets the spacing between lines of text, in pixels.
pub fn P5::text_leading(self : P5, leading : Double) -> Unit {
  self.state.text_leading = leading
  self.state.leading_set = true
}

///|
/// The current leading.
pub fn P5::get_text_leading(self : P5) -> Double {
  self.state.text_leading
}

///|
/// Sets the font family (any CSS family list such as `"Georgia, serif"`),
/// optionally with a size.
pub fn P5::text_font(self : P5, family : String, size? : Double) -> Unit {
  self.state.text_font = family
  self.state.font_obj = None
  if size is Some(s) {
    self.text_size(s)
  }
}

///|
/// Uses a font returned by `load_font`.
pub fn P5::text_font_face(self : P5, font : Font, size? : Double) -> Unit {
  self.text_font(font.family, size?)
  self.state.font_obj = Some(font)
}

///|
/// Sets normal, italic, bold or bold-italic text.
pub fn P5::text_style(self : P5, style : TextStyle) -> Unit {
  self.state.text_style = style
}

///|
/// Sets the numeric font weight (100-900; 400 is normal, 700 bold).
pub fn P5::text_weight(self : P5, weight : Double) -> Unit {
  self.state.font_weight = @dom.number_to_string(weight)
}

///|
/// The font weight (`"normal"` or a number).
pub fn P5::get_text_weight(self : P5) -> String {
  self.state.font_weight
}

///|
/// Sets the font variant (`"normal"` or `"small-caps"`).
pub fn P5::text_variant(self : P5, variant : String) -> Unit {
  self.state.font_variant = variant
}

///|
/// Sets the text direction (`"ltr"`, `"rtl"` or `"inherit"`).
pub fn P5::text_direction(self : P5, direction : String) -> Unit {
  self.state.text_direction = direction
}

///|
/// Sets horizontal and (optionally) vertical alignment.
pub fn P5::text_align(
  self : P5,
  horizontal : HAlign,
  vertical? : VAlign,
) -> Unit {
  self.state.text_align = horizontal
  if vertical is Some(v) {
    self.state.text_baseline = v
  }
}

///|
/// Sets how text wraps inside a box: at word or character boundaries.
pub fn P5::text_wrap(self : P5, wrap : TextWrap) -> Unit {
  self.state.text_wrap = wrap
}

///|
fn split_lines(s : String) -> Array[String] {
  if s.is_empty() {
    return [""]
  }
  let s = s.replace_all(old="\t", new="  ").replace_all(old="\r\n", new="\n")
  [
    for line in s.split("\n") => line.to_owned()
  ]
}

///|
/// Tight width of one line (`actualBoundingBoxLeft + actualBoundingBoxRight`).
fn P5::text_width_single(self : P5, s : String) -> Double {
  let m = self.surface.measure_text(s)
  m.actual_right + m.actual_left
}

///|
/// p5's `_lineate`: greedy wrapping, measuring candidate lines (with their
/// trailing separator) by their tight width.
fn P5::lineate(
  self : P5,
  lines : Array[String],
  max_width : Double,
) -> Array[String] {
  let sep = match self.state.text_wrap {
    Word => " "
    Char => ""
  }
  let out : Array[String] = []
  for line in lines {
    let words : Array[String] = if sep == "" {
      [
        for c in line => c.to_string()
      ]
    } else {
      [
        for w in line.split(sep) => w.to_owned()
      ]
    }
    let mut current = ""
    for word in words {
      let candidate = current + word + sep
      if current.length() > 0 && self.text_width_single(candidate) > max_width {
        out.push(current.trim().to_owned())
        current = word + sep
      } else {
        current = candidate
      }
    }
    out.push(current.trim().to_owned())
  }
  out
}

///|
/// p5's `_processLines`: split, wrap to `width`, truncate to `height`.
fn P5::process_lines(
  self : P5,
  s : String,
  width : Double?,
  height : Double?,
) -> Array[String] {
  let mut lines = split_lines(s)
  guard width is Some(w) else { return lines }
  let exceeds = lines.any(l => self.text_width_single(l) > w)
  if lines.length() > 1 || exceeds {
    lines = self.lineate(lines, w)
  }
  if height is Some(h) {
    let leading = self.state.text_leading
    for i in 0..<lines.length() {
      if leading * (i + 1).to_double() > h {
        lines = lines[:i].to_owned()
        break
      }
    }
  }
  lines
}

///|
/// p5's `_handleRectMode` for text boxes.
fn P5::text_rect_mode(
  self : P5,
  x : Double,
  y : Double,
  width : Double?,
  height : Double?,
) -> (Double, Double, Double?, Double?) {
  guard width is Some(w) else { return (x, y, width, height) }
  match self.state.rect_mode {
    Radius => {
      let w = w * 2
      let h = height.map(h => h * 2)
      (x - w / 2, y - h.map(h => h / 2).unwrap_or(0), Some(w), h)
    }
    Center =>
      (x - w / 2, y - height.map(h => h / 2).unwrap_or(0), Some(w), height)
    Corners => (x, y, Some(w - x), height.map(h => h - y))
    Corner => (x, y, width, height)
  }
}

///|
fn x_align_offset(align : HAlign, width : Double) -> Double {
  match align {
    HCenter => width / 2
    Right | End => width
    Left | Start => 0
  }
}

///|
/// p5's `_middleAlignOffset`, measured with the current text style.
fn P5::middle_align_offset(self : P5) -> Double {
  let m = self.surface.measure_text("X")
  // p5 uses the font's OS/2 cap height when it has the font data
  let cap = match self.state.font_obj {
    Some({ data: Some(d), .. }) if d.cap_height is Some(c) && c != 0 =>
      c.to_double() *
      self.state.text_size /
      (if d.units_per_em == 0 { 1000 } else { d.units_per_em }).to_double()
    _ => m.font_ascent
  }
  m.alphabetic_baseline + cap / 2
}

///|
/// p5's `_yAlignOffset`: the vertical shift for a block of `n` lines in a
/// box of the given height.
fn P5::y_align_offset(self : P5, n : Int32, height : Double) -> Double {
  let ydiff = height - self.state.text_leading * (n - 1).to_double()
  match self.state.text_baseline {
    VCenter => ydiff / 2 + self.middle_align_offset()
    Bottom => ydiff
    _ => 0
  }
}

///|
/// Draws text at `(x, y)`. Newlines start new lines, `text_leading()` apart.
///
/// With `max_width` the text is wrapped inside a box (positioned according
/// to `rect_mode()`); with `max_height`, lines that don't fit are dropped.
/// Text uses the fill color (black unless `fill` was called) and is only
/// outlined when `stroke` was called explicitly.
pub fn P5::text(
  self : P5,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
) -> Unit {
  let st = self.state
  let (x, y, width, height) = self.text_rect_mode(x, y, max_width, max_height)
  if self.gl is Some(r) {
    self.gl_text(r, s, x, y, width, height)
    return
  }
  // Inside a box the alphabetic baseline is replaced by 'top'.
  let ctx_baseline = if width is Some(_) && st.text_baseline is Baseline {
    VAlign::Top
  } else {
    st.text_baseline
  }
  self.apply_text_style(baseline=ctx_baseline)
  let lines = self.process_lines(s, width, height)
  let w = width.unwrap_or(0)
  let line_x = x + x_align_offset(st.text_align, w)
  let y_off = self.y_align_offset(lines.length(), height.unwrap_or(0))
  self.sync_transform()
  let fill = match self.fill_css() {
    Some(css) => if st.fill_set { Some(css) } else { Some("#000000") }
    None => None
  }
  let stroke = if st.stroke_set { self.stroke_css() } else { None }
  for i, line in lines {
    let ly = y + i.to_double() * st.text_leading + y_off
    if stroke is Some(css) {
      self.surface.stroke_text(
        line,
        line_x,
        ly,
        css,
        st.stroke_weight,
        st.stroke_join,
      )
    }
    if fill is Some(css) && !self.clipping {
      self.surface.fill_text(line, line_x, ly, css)
    }
  }
}

///|
/// Tight width of a string (the widest line), like p5 2.x `textWidth()`.
pub fn P5::text_width(self : P5, s : String) -> Double {
  self.apply_text_style()
  split_lines(s).fold(init=0.0, (acc, l) => acc.max(self.text_width_single(l)))
}

///|
/// Advance width of a string (the widest line), like p5 2.x `fontWidth()`.
pub fn P5::font_width(self : P5, s : String) -> Double {
  self.apply_text_style()
  split_lines(s).fold(init=0.0, (acc, l) => {
    acc.max(self.surface.measure_text(l).width)
  })
}

///|
/// Ascent of `s` (tight), or of the font when `s` is empty.
pub fn P5::text_ascent(self : P5, s~ : String = "") -> Double {
  if s.is_empty() {
    return self.font_ascent()
  }
  self.apply_text_style()
  self.surface.measure_text(s).actual_ascent
}

///|
/// Descent of `s` (tight), or of the font when `s` is empty.
pub fn P5::text_descent(self : P5, s~ : String = "") -> Double {
  if s.is_empty() {
    return self.font_descent()
  }
  self.apply_text_style()
  self.surface.measure_text(s).actual_descent
}

///|
/// Ascent of the current font.
pub fn P5::font_ascent(self : P5) -> Double {
  self.apply_text_style()
  self.surface.measure_text("_").font_ascent
}

///|
/// Descent of the current font.
pub fn P5::font_descent(self : P5) -> Double {
  self.apply_text_style()
  self.surface.measure_text("_").font_descent
}

///|
fn P5::compute_bounds(
  self : P5,
  tight : Bool,
  s : String,
  x : Double,
  y : Double,
  max_width : Double?,
  max_height : Double?,
) -> Bounds {
  self.compute_bounds_lines(tight, s, x, y, max_width, max_height).0
}

///|
/// p5's `_computeBounds`: the bounds and the wrapped lines.
fn P5::compute_bounds_lines(
  self : P5,
  tight : Bool,
  s : String,
  x : Double,
  y : Double,
  max_width : Double?,
  max_height : Double?,
  ignore_rect_mode~ : Bool = false,
) -> (Bounds, Array[String]) {
  let st = self.state
  // p5's _rectModeAdjust: only the size changes
  let (width, height) = match (max_width, st.rect_mode) {
    (Some(w), Corners) => (Some(w - x), max_height.map(h => h - y))
    (Some(w), Radius) => (Some(w * 2), max_height.map(h => h * 2))
    _ => (max_width, max_height)
  }
  let ctx_baseline = if width is Some(_) && st.text_baseline is Baseline {
    VAlign::Top
  } else {
    st.text_baseline
  }
  self.apply_text_style(baseline=ctx_baseline)
  let lines = self.process_lines(s, width, height)
  let boxes = lines.mapi((i, line) => {
    let ly = y + i.to_double() * st.text_leading
    let m = self.surface.measure_text(line)
    if tight {
      {
        x: x - m.actual_left,
        y: ly - m.actual_ascent,
        w: m.actual_right + m.actual_left,
        h: m.actual_ascent + m.actual_descent,
      }
    } else {
      {
        x: x - x_align_offset(st.text_align, m.width),
        y: ly - m.font_ascent,
        w: m.width,
        h: m.font_ascent + m.font_descent,
      }
    }
  })
  let dx = if lines.length() > 1 && width is Some(w) {
    x_align_offset(st.text_align, w)
  } else {
    0
  }
  let dy = self.y_align_offset(lines.length(), height.unwrap_or(0))
  let boxes = boxes.map(b => { ..b, x: b.x + dx, y: b.y + dy, })
  if boxes.length() <= 1 {
    return (boxes.get(0).unwrap_or({ x, y, w: 0, h: 0, }), lines)
  }
  let min_x = boxes.fold(init=@double.infinity, (a, b) => a.min(b.x))
  let min_y = boxes.fold(init=@double.infinity, (a, b) => a.min(b.y))
  let max_x = boxes.fold(init=@double.neg_infinity, (a, b) => a.max(b.x + b.w))
  let max_y = boxes.fold(init=@double.neg_infinity, (a, b) => a.max(b.y + b.h))
  let bb = { x: min_x, y: min_y, w: max_x - min_x, h: max_y - min_y, }
  if ignore_rect_mode {
    return (bb, lines)
  }
  // p5's _rectModeAlign
  let w = width.unwrap_or(0)
  let h = height.unwrap_or(0)
  let bb = match st.rect_mode {
    Center => { ..bb, x: bb.x - (w - bb.w) / 2, y: bb.y - (h - bb.h) / 2, }
    Corners => { ..bb, w: bb.w + bb.x, h: bb.h + bb.y, }
    Radius =>
      {
        x: bb.x - (w - bb.w) / 2,
        y: bb.y - (h - bb.h) / 2,
        w: bb.w / 2,
        h: bb.h / 2,
      }
    Corner => bb
  }
  (bb, lines)
}

///|
/// The tight bounding box of text drawn with `text(s, x, y, …)`, from the
/// glyphs' actual extents.
pub fn P5::text_bounds(
  self : P5,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
) -> Bounds {
  self.compute_bounds(true, s, x, y, max_width, max_height)
}

///|
/// The loose bounding box of text, from the font's ascent and descent and
/// the advance width.
pub fn P5::font_bounds(
  self : P5,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
) -> Bounds {
  self.compute_bounds(false, s, x, y, max_width, max_height)
}

///|
/// `text()` in WEBGL: p5's WebGL `_positionLines` / `_yAlignOffset`, then
/// each line drawn with the font shader.
fn P5::gl_text(
  self : P5,
  r : @webgl.Renderer3D,
  s : String,
  x : Double,
  y : Double,
  width : Double?,
  height : Double?,
) -> Unit {
  let st = self.state
  guard st.font_obj is Some(font) && font.data is Some(data) else {
    warn(
      "WEBGL: you must load and set a font (load_font + text_font_face) before drawing text",
    )
    return
  }
  guard st.fill is Some(_) else { return }
  self.apply_text_style()
  let lines = self.process_lines(s, width, height)
  let widths = lines.map(l => self.surface.measure_text(l).width)
  let adj_w = match width {
    Some(w) => w
    None => widths.fold(init=0.0, (a, b) => a.max(b))
  }
  let adj_h = height.unwrap_or(0)
  let n = lines.length()
  let size = st.text_size
  let total = size * n.to_double() +
    (st.text_leading - size) * (n - 1).to_double()
  let vertical_align_font = () => {
    let m = self.surface.measure_text("X")
    if m.alphabetic_baseline != 0 {
      -m.alphabetic_baseline
    } else {
      -m.font_ascent + m.font_descent
    }
  }
  let y_off = match st.text_baseline {
    Top => vertical_align_font()
    Baseline => 0.0
    VCenter =>
      (-total + size + adj_h) / 2 +
      vertical_align_font() +
      self.middle_align_offset()
    Bottom => -(total - size) + adj_h
    _ => 0.0
  }
  let fill = if st.fill_set {
    self.gl_style().fill.unwrap_or([0, 0, 0, 1])
  } else {
    [0.0, 0, 0, 1]
  }
  let style = self.gl_style()
  for i, line in lines {
    let w = widths[i]
    let lx = match st.text_align {
      HCenter => x + (adj_w - w) / 2 - adj_w / 2 + width.unwrap_or(0) / 2
      Right => x + adj_w - w - adj_w + width.unwrap_or(0)
      _ => x
    }
    let ly = y + i.to_double() * st.text_leading + y_off
    r.render_text(font.family, data, line, lx, ly, size, fill, style)
  }
}
