///|
/// A surface that records every drawing call as a line of text. Text is
/// measured as `0.5 * size` per character. Pixel reads return zeros.
pub struct Recorder {
  log : Array[String]
  priv mut font_size : Double
}

///|
/// Creates an empty recorder.
pub fn Recorder::new() -> Recorder {
  { log: [], font_size: 12, }
}

///|
/// Returns the recorded calls and clears the log.
pub fn Recorder::take(self : Recorder) -> Array[String] {
  let out = self.log.copy()
  self.log.clear()
  out
}

///|
fn num(d : Double) -> String {
  let r = @math.round(d, decimals=3)
  if r == 0 {
    "0"
  } else {
    r.to_string()
  }
}

///|
fn path_str(path : @shape.Path) -> String {
  let parts = path.map(cmd => {
    match cmd {
      MoveTo(x, y) => "M\{num(x)},\{num(y)}"
      LineTo(x, y) => "L\{num(x)},\{num(y)}"
      QuadraticCurveTo(a, b, c, d) => "Q\{num(a)},\{num(b)},\{num(c)},\{num(d)}"
      BezierCurveTo(a, b, c, d, e, f) =>
        "C\{num(a)},\{num(b)},\{num(c)},\{num(d)},\{num(e)},\{num(f)}"
      Ellipse(x, y, rx, ry, _, s, e) =>
        "E\{num(x)},\{num(y)},\{num(rx)},\{num(ry)},\{num(s)},\{num(e)}"
      Rect(x, y, w, h) => "R\{num(x)},\{num(y)},\{num(w)},\{num(h)}"
      RoundRect(x, y, w, h, a, b, c, d) =>
        "RR\{num(x)},\{num(y)},\{num(w)},\{num(h)},\{num(a)},\{num(b)},\{num(c)},\{num(d)}"
      ClosePath => "Z"
    }
  })
  parts.join(" ")
}

///|
pub impl Surface for Recorder with fn set_transform(self, m) {
  self.log.push(
    "transform \{num(m.a)} \{num(m.b)} \{num(m.c)} \{num(m.d)} \{num(m.e)} \{num(m.f)}",
  )
}

///|
pub impl Surface for Recorder with fn save(self) {
  self.log.push("save")
}

///|
pub impl Surface for Recorder with fn restore(self) {
  self.log.push("restore")
}

///|
pub impl Surface for Recorder with fn fill_path(self, path, style) {
  self.log.push("fill \{style} \{path_str(path)}")
}

///|
pub impl Surface for Recorder with fn stroke_path(
  self,
  path,
  style,
  w,
  cap,
  join,
) {
  self.log.push(
    "stroke \{style} w=\{num(w)} \{cap.css()}/\{join.css()} \{path_str(path)}",
  )
}

///|
pub impl Surface for Recorder with fn clip(self, base, parts) {
  let ps = parts.map(part => {
    let (path, m) = part
    "[\{num(m.a)} \{num(m.b)} \{num(m.c)} \{num(m.d)} \{num(m.e)} \{num(m.f)}] \{path_str(path)}"
  })
  self.log.push(
    "clip base=\{num(base.a)} \{num(base.b)} \{num(base.c)} \{num(base.d)} \{num(base.e)} \{num(base.f)} \{ps.join(" | ")}",
  )
}

///|
pub impl Surface for Recorder with fn fill_rect(self, x, y, w, h, style) {
  self.log.push("fill_rect \{style} \{num(x)},\{num(y)},\{num(w)},\{num(h)}")
}

///|
pub impl Surface for Recorder with fn clear_rect(self, x, y, w, h) {
  self.log.push("clear_rect \{num(x)},\{num(y)},\{num(w)},\{num(h)}")
}

///|
pub impl Surface for Recorder with fn set_blend_mode(self, mode) {
  self.log.push("blend \{mode.css()}")
}

///|
pub impl Surface for Recorder with fn set_text_style(
  self,
  font,
  align,
  baseline,
  _direction,
) {
  // font strings look like "bold 12px sans-serif"
  for part in font.split(" ") {
    if part is [.. size, 'p', 'x'] {
      self.font_size = @string.parse_double(size) catch { _ => 12 }
    }
  }
  self.log.push("font \{font} \{css_align(align)} \{css_baseline(baseline)}")
}

///|
pub impl Surface for Recorder with fn fill_text(self, s, x, y, style) {
  self.log.push("fill_text \{style} \{repr(s)} \{num(x)},\{num(y)}")
}

///|
pub impl Surface for Recorder with fn stroke_text(self, s, x, y, style, w, _) {
  self.log.push(
    "stroke_text \{style} w=\{num(w)} \{repr(s)} \{num(x)},\{num(y)}",
  )
}

///|
fn repr(s : String) -> String {
  Repr(s).to_string()
}

///|
/// Text is measured as `0.5 × size` per character; the ink ascends
/// `0.7 × size` and descends `0.1 × size`, the font `0.8` and `0.2 × size`.
pub impl Surface for Recorder with fn measure_text(self, s) {
  let w = s.length().to_double() * self.font_size * 0.5
  {
    width: w,
    actual_left: 0,
    actual_right: w,
    actual_ascent: self.font_size * 0.7,
    actual_descent: self.font_size * 0.1,
    font_ascent: self.font_size * 0.8,
    font_descent: self.font_size * 0.2,
    alphabetic_baseline: 0,
  }
}

///|
pub impl Surface for Recorder with fn draw_image(
  self,
  _,
  iw,
  ih,
  tint,
  sx,
  sy,
  sw,
  sh,
  dx,
  dy,
  dw,
  dh,
) {
  let t = match tint {
    None => ""
    Some((r, g, b, a)) => " tint=\{num(r)},\{num(g)},\{num(b)},\{num(a)}"
  }
  self.log.push(
    "image \{iw}x\{ih}\{t} src=\{num(sx)},\{num(sy)},\{num(sw)},\{num(sh)} dst=\{num(dx)},\{num(dy)},\{num(dw)},\{num(dh)}",
  )
}

///|
pub impl Surface for Recorder with fn read_pixels(self, x, y, w, h) {
  self.log.push("read_pixels \{x},\{y},\{w},\{h}")
  FixedArray::make(w * h * 4, (0 : Byte))
}

///|
pub impl Surface for Recorder with fn write_pixels(self, bytes, x, y, w, h) {
  self.log.push("write_pixels \{x},\{y},\{w},\{h} (\{bytes.length()} bytes)")
}

///|
pub impl Surface for Recorder with fn resize(self, w, h, density) {
  self.log.push("resize \{num(w)}x\{num(h)} @\{num(density)}")
}

///|
pub impl Surface for Recorder with fn set_smoothing(self, on) {
  self.log.push("smoothing \{on}")
}

///|
pub impl Surface for Recorder with fn set_css_filter(self, f) {
  self.log.push("filter \{f}")
}
