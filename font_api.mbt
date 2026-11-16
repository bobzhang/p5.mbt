// p5.Font in p5.js 2.x: loadFont with glyph data (src/type/p5.Font.js),
// textToPaths, textToContours and textToPoints.

///|
/// Loads a font file (`.ttf`, `.otf`, `.woff`; `.woff2` draws but has no
/// glyph data). The file is parsed for `text_to_points` and registered
/// with the browser for drawing. In `preload`, `setup` waits for it.
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
  let font : Font = { family, loaded: false, data: None, sketch: self, }
  self.begin_load()
  let ready = _ => {
    font.loaded = true
    if on_load is Some(f) {
      f(font)
    }
    self.end_load()
  }
  let failed = msg => {
    warn(msg)
    self.end_load()
  }
  // like p5: without parseable data, retry as a plain FontFace
  let fallback = () => {
    warn("No glyph data for '\{url}', retrying as FontFace")
    @dom.load_font(url, family, ready, failed)
  }
  @dom.fetch_bytes(
    url,
    bytes => {
      let parsed = try @font.FontData::parse(Bytes::from_array(bytes)) catch {
        _ => None
      } noraise {
        d => Some(d)
      }
      match parsed {
        Some(d) => {
          font.data = Some(d)
          @dom.load_font_data(bytes, family, ready, failed)
        }
        None => fallback()
      }
    },
    _ => fallback(),
  )
  font
}

///|
/// A point on a text outline from `text_to_points`, with the path angle in
/// the current angle mode.
#derive(Debug)
pub(all) struct TextPoint {
  x : Double
  y : Double
  angle : Double
}

///|
/// p5's backwards-compatible name for `angle`.
pub fn TextPoint::alpha(self : TextPoint) -> Double {
  self.angle
}

///|
/// p5's `_lineateAndPathify` + `_position` + `_shapeToPaths`: the outline of
/// `s` laid out like `text(s, x, y, max_width?, max_height?)`, in canvas
/// pixels, as glyph-style commands and flattened coordinates.
fn Font::outline(
  self : Font,
  s : String,
  x : Double,
  y : Double,
  max_width : Double?,
  max_height : Double?,
) -> (Array[@font.PathCmd], Array[Double]) {
  let cmds : Array[@font.PathCmd] = []
  let crds : Array[Double] = []
  guard self.data is Some(data) else {
    warn(
      "No font data available for '\{self.family}'; text_to_points needs a TTF, OTF or WOFF file",
    )
    return (cmds, crds)
  }
  let p = self.sketch
  let st = p.state
  let saved_font = st.text_font
  st.text_font = self.family
  let (bounds, lines) = p.compute_bounds_lines(
    false,
    s,
    x,
    y,
    max_width,
    max_height,
    ignore_rect_mode=true,
  )
  // ascent of "X" measured left/alphabetic (p5's _measureTextDefault)
  p.surface.set_text_style(p.font_string(), Left, Baseline, st.text_direction)
  let ascent = p.surface.measure_text("X").font_ascent
  let scale = st.text_size /
    (if data.units_per_em == 0 { 1000 } else { data.units_per_em }).to_double()
  for i, line in lines {
    let mut lx = bounds.x
    let mut ly = bounds.y + i.to_double() * st.text_leading + ascent
    let line_width = p.surface.measure_text(line).width
    match st.text_align {
      HCenter => lx += (bounds.w - line_width) / 2
      Right => lx += bounds.w - line_width
      _ => ()
    }
    if max_width is Some(w) {
      let h = max_height.unwrap_or(0)
      match st.rect_mode {
        Center => {
          lx -= w / 2
          ly -= h / 2
        }
        Radius => {
          lx -= w
          ly -= h
        }
        _ => ()
      }
    }
    let mut gx = 0.0
    for g in data.shape(line) {
      let path = data.glyph_path(g.glyph)
      let mut k = 0
      for cmd in path.cmds {
        cmds.push(cmd)
        let n = match cmd {
          M | L => 2
          Q => 4
          C => 6
          Z => 0
        }
        for j = 0; j < n; j = j + 2 {
          crds.push(lx + (path.crds[k + j] + gx) * scale)
          crds.push(ly + path.crds[k + j + 1] * -scale)
        }
        k += n
      }
      gx += g.advance.to_double()
    }
  }
  st.text_font = saved_font
  (cmds, crds)
}

///|
fn coord_count(cmd : @font.PathCmd) -> Int32 {
  match cmd {
    M | L => 2
    Q => 4
    C => 6
    Z => 0
  }
}

///|
/// The outline of `s` as path commands, laid out as `text(s, x, y, …)`
/// would draw it with this font (p5's `font.textToPaths`).
pub fn Font::text_to_paths(
  self : Font,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
) -> Array[@shape.PathCmd] {
  let (cmds, c) = self.outline(s, x, y, max_width, max_height)
  let out : Array[@shape.PathCmd] = []
  let mut k = 0
  for cmd in cmds {
    out.push(
      match cmd {
        M => MoveTo(c[k], c[k + 1])
        L => LineTo(c[k], c[k + 1])
        Q => QuadraticCurveTo(c[k], c[k + 1], c[k + 2], c[k + 3])
        C =>
          BezierCurveTo(c[k], c[k + 1], c[k + 2], c[k + 3], c[k + 4], c[k + 5])
        Z => ClosePath
      },
    )
    k += coord_count(cmd)
  }
  out
}

///|
/// Points along each contour of the outline of `s` (p5's
/// `font.textToContours`): the letter "O" gives two arrays. `sample_factor`
/// is points per pixel of path length; with `simplify_threshold` (radians)
/// nearly collinear points are dropped.
pub fn Font::text_to_contours(
  self : Font,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
  sample_factor~ : Double = 0.1,
  simplify_threshold~ : Double = 0,
) -> Array[Array[TextPoint]] {
  let (cmds, crds) = self.outline(s, x, y, max_width, max_height)
  let p = self.sketch
  let contours : Array[Array[TextPoint]] = []
  let mut start = 0
  let mut start_crd = 0
  let mut k = 0
  let flush = (end : Int32, end_crd : Int32) => {
    let pts = @font.path_to_points(
      cmds[start:end],
      crds[start_crd:end_crd],
      sample_factor~,
      simplify_threshold~,
    )
    contours.push(
      pts.map(q => { x: q.x, y: q.y, angle: p.from_radians(q.angle), }),
    )
  }
  for i, cmd in cmds {
    if cmd == M && i > 0 {
      flush(i, k)
      start = i
      start_crd = k
    }
    k += coord_count(cmd)
  }
  if cmds.length() > 0 {
    flush(cmds.length(), k)
  }
  contours
}

///|
/// Points outlining `s` (p5's `font.textToPoints`): all contours of
/// `text_to_contours` in one array.
pub fn Font::text_to_points(
  self : Font,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
  sample_factor~ : Double = 0.1,
  simplify_threshold~ : Double = 0,
) -> Array[TextPoint] {
  let out : Array[TextPoint] = []
  for
    c in self.text_to_contours(
      s,
      x,
      y,
      max_width?,
      max_height?,
      sample_factor~,
      simplify_threshold~,
    ) {
    out.append(c)
  }
  out
}
