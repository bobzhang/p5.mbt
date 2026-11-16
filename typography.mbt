// Port of p5.js src/type/textCore.js for the 2D renderer (system and web
// fonts through the canvas text API).

///|
/// A font loaded with `load_font`; use it with `text_font`.
pub struct Font {
  /// The CSS font family name to draw with.
  family : String
  /// Whether the font finished loading.
  mut loaded : Bool
}

///|
fn quote_family(family : String) -> String {
  if family.contains(",") ||
    family.has_prefix("\"") ||
    family.has_prefix("'") ||
    !family.contains(" ") {
    family
  } else {
    "\"\{family}\""
  }
}

///|
fn P5::font_string(self : P5) -> String {
  let s = self.state
  let (style, weight) = match s.text_style {
    Normal => ("normal", "normal")
    Italic => ("italic", "normal")
    Bold => ("normal", "bold")
    BoldItalic => ("italic", "bold")
  }
  "\{style} \{weight} \{s.text_size}px \{quote_family(s.text_font)}"
}

///|
fn P5::apply_text_style(self : P5, align : HAlign, baseline : VAlign) -> Unit {
  self.surface.set_text_style(self.font_string(), align, baseline)
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
/// Sets the font family (any CSS family such as `"Georgia"` or
/// `"monospace"`), optionally with a size.
pub fn P5::text_font(self : P5, family : String, size? : Double) -> Unit {
  self.state.text_font = family
  if size is Some(s) {
    self.text_size(s)
  }
}

///|
/// Uses a font returned by `load_font`.
pub fn P5::text_font_face(self : P5, font : Font, size? : Double) -> Unit {
  self.text_font(font.family, size?)
}

///|
/// Sets normal, italic, bold or bold-italic text.
pub fn P5::text_style(self : P5, style : TextStyle) -> Unit {
  self.state.text_style = style
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
/// Width of a line of text in the current font (the widest line for
/// multi-line strings).
pub fn P5::text_width(self : P5, s : String) -> Double {
  self.apply_text_style(Left, Baseline)
  let mut w = 0.0
  for line in split_lines(s) {
    w = w.max(self.surface.text_width(line))
  }
  w
}

///|
/// Ascent of the current font.
pub fn P5::text_ascent(self : P5) -> Double {
  self.apply_text_style(Left, Baseline)
  self.surface.text_ascent()
}

///|
/// Descent of the current font.
pub fn P5::text_descent(self : P5) -> Double {
  self.apply_text_style(Left, Baseline)
  self.surface.text_descent()
}

///|
fn split_lines(s : String) -> Array[String] {
  let s = s.replace_all(old="\t", new="  ").replace_all(old="\r\n", new="\n")
  [
    for line in s.split("\n") => line.to_owned()
  ]
}

///|
fn P5::wrap_lines(
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
      if current.length() > 0 && self.surface.text_width(candidate) > max_width {
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
/// Draws text at `(x, y)`. Newlines start new lines, `text_leading()` apart.
///
/// With `max_width` the text is wrapped inside a box whose position follows
/// `rect_mode()`; with `max_height` lines that don't fit are dropped. Text
/// uses the fill color (black unless `fill` was called) and is only
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
  let lines0 = split_lines(s)
  let (x, y, box_w, box_h) = match max_width {
    None => (x, y, None, None)
    Some(w) => {
      let h = max_height.unwrap_or(0)
      let (bx, by, bw, bh) = @shape.mode_adjust(x, y, w, h, st.rect_mode)
      (bx, by, Some(bw), max_height.map(_ => bh))
    }
  }
  // Vertical alignment inside a box uses 'top' instead of 'alphabetic'.
  let baseline = if box_w is Some(_) && st.text_baseline is Baseline {
    VAlign::Top
  } else {
    st.text_baseline
  }
  self.apply_text_style(st.text_align, baseline)
  let mut lines = match box_w {
    Some(w) => self.wrap_lines(lines0, w)
    None => lines0
  }
  if box_w is Some(_) && box_h is Some(h) {
    let kept = []
    for i, line in lines {
      if st.text_leading * (i + 1).to_double() > h {
        break
      }
      kept.push(line)
    }
    lines = kept
  }
  let leading = st.text_leading
  let n = lines.length().to_double()
  let x = match (box_w, st.text_align) {
    (Some(w), HCenter) => x + w / 2
    (Some(w), Right) => x + w
    _ => x
  }
  let height = box_h.unwrap_or(0)
  let y_off = match baseline {
    Top | Baseline => 0.0
    VCenter => (height - leading * (n - 1)) / 2
    Bottom => height - leading * (n - 1)
  }
  let y_off = if box_w is None {
    // Without a box, center/bottom alignment applies to the whole block.
    match baseline {
      VCenter => -leading * (n - 1) / 2
      Bottom => -leading * (n - 1)
      _ => 0
    }
  } else {
    y_off
  }
  self.sync_transform()
  let fill = match self.fill_css() {
    Some(css) => if st.fill_set { Some(css) } else { Some("#000000") }
    None => None
  }
  let stroke = if st.stroke_set { self.stroke_css() } else { None }
  for i, line in lines {
    let ly = y + y_off + i.to_double() * leading
    if stroke is Some(css) {
      self.surface.stroke_text(
        line,
        x,
        ly,
        css,
        st.stroke_weight,
        st.stroke_join,
      )
    }
    if fill is Some(css) && !self.clipping {
      self.surface.fill_text(line, x, ly, css)
    }
  }
}

///|
/// Loads a font file (`.ttf`, `.otf`, `.woff`, `.woff2`). In `preload`,
/// `setup` waits for it. `on_load` is called when it is ready.
pub fn P5::load_font(
  self : P5,
  url : String,
  family? : String,
  on_load? : (Font) -> Unit,
) -> Font {
  let family = match family {
    Some(f) => f
    None => "p5mbt-font-\{self.font_counter}"
  }
  self.font_counter += 1
  let font = { family, loaded: false, }
  self.begin_load()
  @dom.load_font(
    url,
    family,
    _ => {
      font.loaded = true
      if on_load is Some(f) {
        f(font)
      }
      self.end_load()
    },
    msg => {
      warn(msg)
      self.end_load()
    },
  )
  font
}
