// Port of the p5.js 2.x SVG module (src/shape/svg): recording drawings into
// shape collections, replaying them with shape(), and exporting SVG.

///|
/// Recorded drawing commands (p5.ShapeCollection): replay them with
/// `shape()`, or export them with `get_svg()` / `save_svg()`.
pub struct ShapeCollection {
  ops : Array[DrawOp]
  /// Coordinate bounds `(x, y, width, height)` used for alignment: the
  /// viewBox of an imported SVG, or the canvas of a recording.
  bounds : (Double, Double, Double, Double)
  /// While recording with `begin`: the sketch and the surface it drew on.
  priv mut recording : (P5, &Surface, DisplayList)?
}

///|
/// How `shape()` aligns a collection with `(x, y)`.
#derive(Eq, Debug)
pub(all) enum ShapeAlign {
  /// The top-left of the coordinate bounds goes to `(x, y)` (default).
  AlignCorner
  /// The center of the coordinate bounds goes to `(x, y)`.
  AlignCenter
  /// The raw coordinates are kept; their origin goes to `(x, y)`.
  AlignViewBox
}

///|
/// Records the drawing done in `body` into a shape collection, like p5's
/// `buildShape()`. With `draw`, it is also drawn on the canvas.
pub fn P5::build_shape(
  self : P5,
  body : () -> Unit,
  draw~ : Bool = false,
) -> ShapeCollection {
  let real = self.surface
  let rec = DisplayList::new(
    self.density,
    real,
    forward?=if draw { Some(real) } else { None },
  )
  self.surface = rec
  self.push()
  body()
  self.pop()
  self.surface = real
  { ops: rec.ops, bounds: (0, 0, self.width, self.height), recording: None, }
}

///|
/// An empty shape collection to record into with `begin` / `end`
/// (`createShape`).
pub fn P5::create_shape(self : P5) -> ShapeCollection {
  { ops: [], bounds: (0, 0, self.width, self.height), recording: None, }
}

///|
/// Starts recording what the sketch `p` draws into this collection; with
/// `draw` it is drawn on the canvas too. Stop with `end`.
pub fn ShapeCollection::begin(
  self : ShapeCollection,
  p : P5,
  draw~ : Bool = false,
) -> Unit {
  if self.recording is Some(_) {
    return
  }
  let real = p.surface
  let rec = DisplayList::new(
    p.density,
    real,
    forward?=if draw { Some(real) } else { None },
  )
  p.surface = rec
  p.push()
  self.recording = Some((p, real, rec))
}

///|
/// Stops recording (see `begin`); the commands are added to the collection.
pub fn ShapeCollection::end(self : ShapeCollection) -> Unit {
  guard self.recording is Some((p, real, rec)) else {
    @dom.console_warn("end() called without a matching begin().")
    return
  }
  p.pop()
  p.surface = real
  self.ops.append(rec.ops)
  self.recording = None
}

///|
/// Draws a shape collection at `(x, y)`, optionally scaled, aligned by
/// `align` (like p5's `shape(record, x, y, { align, scale })`).
pub fn P5::shape(
  self : P5,
  coll : ShapeCollection,
  x~ : Double = 0,
  y~ : Double = 0,
  scale? : Double,
  scale_x? : Double,
  scale_y? : Double,
  align~ : ShapeAlign = AlignCorner,
) -> Unit {
  self.push()
  if x != 0 || y != 0 {
    self.translate(x, y)
  }
  let sx = scale_x.unwrap_or(scale.unwrap_or(1))
  let sy = scale_y.unwrap_or(scale.unwrap_or(1))
  if sx != 1 || sy != 1 {
    self.scale(sx, y=sy)
  }
  let (bx, by, bw, bh) = coll.bounds
  let (ox, oy) = match align {
    AlignCorner => (-bx, -by)
    AlignCenter => (-(bx + bw / 2), -(by + bh / 2))
    AlignViewBox => (0.0, 0.0)
  }
  if ox != 0 || oy != 0 {
    self.translate(ox, oy)
  }
  let base = self.device_matrix()
  let s = self.surface
  for op in coll.ops {
    match op {
      FillPath(path, style, m) => {
        s.set_transform(base.multiply(m))
        s.fill_path(path, style)
      }
      StrokePath(path, style, w, cap, join, m) => {
        s.set_transform(base.multiply(m))
        s.stroke_path(path, style, w, cap, join)
      }
      FillRect(rx, ry, rw, rh, style, m) => {
        s.set_transform(base.multiply(m))
        s.fill_rect(rx, ry, rw, rh, style)
      }
      FillText(t, tx, ty, style, font, al, bl, m) => {
        s.set_transform(base.multiply(m))
        s.set_text_style(font, al, bl, "inherit")
        s.fill_text(t, tx, ty, style)
      }
      StrokeText(t, tx, ty, style, w, font, al, bl, m) => {
        s.set_transform(base.multiply(m))
        s.set_text_style(font, al, bl, "inherit")
        s.stroke_text(t, tx, ty, style, w, Miter)
      }
      DrawImage(img, iw, ih, tint, src, dst, m) => {
        s.set_transform(base.multiply(m))
        s.draw_image(
          img,
          iw,
          ih,
          tint,
          src.0,
          src.1,
          src.2,
          src.3,
          dst.0,
          dst.1,
          dst.2,
          dst.3,
        )
      }
      Clip(cbase, parts) => s.clip(base.multiply(cbase), parts)
      Save => s.save()
      Restore => s.restore()
      SetBlend(mode) => s.set_blend_mode(mode)
    }
  }
  self.pop()
}

///|
fn svg_num(v : Double) -> String {
  // full precision, like p5's exporter (rounding shifts anti-aliasing)
  @dom.number_to_string(v)
}

///|
fn svg_matrix(m : Matrix2D) -> String {
  if m == @math.identity {
    ""
  } else {
    " transform=\"matrix(\{svg_num(m.a)} \{svg_num(m.b)} \{svg_num(m.c)} \{svg_num(m.d)} \{svg_num(m.e)} \{svg_num(m.f)})\""
  }
}

///|
fn xml_escape(s : String) -> String {
  s
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
}

///|
/// Appends SVG arc commands following the canvas `ellipse()` from `start`
/// to `stop` (clockwise), preceded by a line to its first point.
fn svg_ellipse(
  out : StringBuilder,
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  rot : Double,
  start : Double,
  stop : Double,
  has_point : Bool,
) -> Unit {
  let rx = rx.abs()
  let ry = ry.abs()
  let pt = (a : Double) => {
    let x = rx * @cmath.cos(a)
    let y = ry * @cmath.sin(a)
    (
      cx + x * @cmath.cos(rot) - y * @cmath.sin(rot),
      cy + x * @cmath.sin(rot) + y * @cmath.cos(rot),
    )
  }
  let mut sweep = stop - start
  if sweep >= TWO_PI {
    sweep = TWO_PI
  }
  let (sx, sy) = pt(start)
  out.write_string(
    (if has_point { "L" } else { "M" }) + "\{svg_num(sx)} \{svg_num(sy)}",
  )
  let pieces = (sweep.abs() / PI).ceil().max(1).to_int()
  let step = sweep / pieces.to_double()
  let deg = rot * RAD_TO_DEG
  for i in 1..<=pieces {
    let (x, y) = pt(start + step * i.to_double())
    let sweep_flag = if step >= 0 { 1 } else { 0 }
    out.write_string(
      "A\{svg_num(rx)} \{svg_num(ry)} \{svg_num(deg)} 0 \{sweep_flag} \{svg_num(x)} \{svg_num(y)}",
    )
  }
}

///|
/// SVG path data for canvas path commands.
fn svg_path_data(path : @shape.Path) -> String {
  let out = StringBuilder()
  let mut has_point = false
  for cmd in path {
    match cmd {
      MoveTo(x, y) => {
        out.write_string("M\{svg_num(x)} \{svg_num(y)}")
        has_point = true
      }
      LineTo(x, y) => {
        out.write_string(
          (if has_point { "L" } else { "M" }) + "\{svg_num(x)} \{svg_num(y)}",
        )
        has_point = true
      }
      QuadraticCurveTo(a, b, x, y) =>
        out.write_string(
          "Q\{svg_num(a)} \{svg_num(b)} \{svg_num(x)} \{svg_num(y)}",
        )
      BezierCurveTo(a, b, c, d, x, y) =>
        out.write_string(
          "C\{svg_num(a)} \{svg_num(b)} \{svg_num(c)} \{svg_num(d)} \{svg_num(x)} \{svg_num(y)}",
        )
      Ellipse(cx, cy, rx, ry, rot, s, e) => {
        svg_ellipse(out, cx, cy, rx, ry, rot, s, e, has_point)
        has_point = true
      }
      Rect(x, y, w, h) => {
        out.write_string(
          "M\{svg_num(x)} \{svg_num(y)}h\{svg_num(w)}v\{svg_num(h)}h\{svg_num(-w)}Z",
        )
        has_point = true
      }
      RoundRect(x, y, w, h, tl, tr, br, bl) => {
        let a = (r : Double, ex : Double, ey : Double) => {
          if r > 0 {
            "A\{svg_num(r)} \{svg_num(r)} 0 0 1 \{svg_num(ex)} \{svg_num(ey)}"
          } else {
            "L\{svg_num(ex)} \{svg_num(ey)}"
          }
        }
        out.write_string("M\{svg_num(x + tl)} \{svg_num(y)}")
        out.write_string("L\{svg_num(x + w - tr)} \{svg_num(y)}")
        out.write_string(a(tr, x + w, y + tr))
        out.write_string("L\{svg_num(x + w)} \{svg_num(y + h - br)}")
        out.write_string(a(br, x + w - br, y + h))
        out.write_string("L\{svg_num(x + bl)} \{svg_num(y + h)}")
        out.write_string(a(bl, x, y + h - bl))
        out.write_string("L\{svg_num(x)} \{svg_num(y + tl)}")
        out.write_string(a(tl, x + tl, y))
        out.write_string("Z")
        has_point = true
      }
      ClosePath => out.write_string("Z")
    }
  }
  out.to_string()
}

///|
/// An SVG element for a path: `<rect>` and `<ellipse>` for the shapes p5
/// exports that way, `<path>` otherwise.
fn svg_shape_element(path : @shape.Path) -> String {
  match path {
    [Rect(x, y, w, h)] =>
      "<rect x=\"\{svg_num(x)}\" y=\"\{svg_num(y)}\" width=\"\{svg_num(w)}\" height=\"\{svg_num(h)}\""
    [RoundRect(x, y, w, h, a, b, c, d)] if a == b && b == c && c == d =>
      "<rect x=\"\{svg_num(x)}\" y=\"\{svg_num(y)}\" width=\"\{svg_num(w)}\" height=\"\{svg_num(h)}\" rx=\"\{svg_num(a)}\" ry=\"\{svg_num(a)}\""
    [MoveTo(_, _), Ellipse(cx, cy, rx, ry, 0, 0, e)] if (e - TWO_PI).abs() <
      1.0e-9 =>
      "<ellipse cx=\"\{svg_num(cx)}\" cy=\"\{svg_num(cy)}\" rx=\"\{svg_num(rx.abs())}\" ry=\"\{svg_num(ry.abs())}\""
    _ => "<path d=\"\{svg_path_data(path)}\""
  }
}

///|
fn svg_stroke_attrs(
  style : String,
  sw : Double,
  cap : StrokeCap,
  join : StrokeJoin,
) -> String {
  let join_attr = if join is Miter {
    ""
  } else {
    " stroke-linejoin=\"\{join.css()}\""
  }
  " stroke=\"\{style}\" stroke-width=\"\{svg_num(sw)}\" stroke-linecap=\"\{cap.css()}\"\{join_attr}"
}

///|
fn svg_blend(mode : BlendMode) -> String {
  match mode {
    Blend | Remove | Replace => ""
    Add => "plus-lighter"
    Darkest => "darken"
    Lightest => "lighten"
    other => other.css()
  }
}

///|
fn svg_anchor(a : HAlign) -> String {
  match a {
    Left | Start => "start"
    HCenter => "middle"
    Right | End => "end"
  }
}

///|
fn svg_baseline(b : VAlign) -> String {
  match b {
    Top => "text-before-edge"
    VCenter => "middle"
    Bottom => "text-after-edge"
    Baseline => "alphabetic"
    Hanging => "hanging"
    Ideographic => "ideographic"
  }
}

///|
/// The collection as an SVG document of `width`×`height` (the sketch size
/// by default), like p5's `getSVG()`.
pub fn P5::get_svg(
  self : P5,
  coll : ShapeCollection,
  width? : Double,
  height? : Double,
) -> String {
  let w = width.unwrap_or(self.width)
  let h = height.unwrap_or(self.height)
  let out = StringBuilder()
  out.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"\{svg_num(w)}\" height=\"\{svg_num(h)}\" viewBox=\"0 0 \{svg_num(w)} \{svg_num(h)}\">",
  )
  // each save level counts the <g> it opened (for clips and blend modes)
  let open_groups : Array[Int32] = [0]
  let mut blend = ""
  let mut clip_id = 0
  let style_attr = () => {
    if blend.is_empty() {
      ""
    } else {
      " style=\"mix-blend-mode:\{blend}\""
    }
  }
  let ops = coll.ops
  let mut k = 0
  while k < ops.length() {
    let op = ops[k]
    k += 1
    match op {
      Save => {
        out.write_string("<g>")
        open_groups.push(0)
      }
      Restore => {
        let n = open_groups.pop().unwrap_or(0)
        for _ in 0..<n {
          out.write_string("</g>")
        }
        if open_groups.length() == 0 {
          open_groups.push(0)
        } else {
          out.write_string("</g>")
        }
      }
      SetBlend(mode) => blend = svg_blend(mode)
      Clip(base, parts) => {
        let id = "p5mbt-clip-\{clip_id}"
        clip_id += 1
        out.write_string("<clipPath id=\"\{id}\"\{svg_matrix(base)}>")
        for part in parts {
          out.write_string(
            "<path d=\"\{svg_path_data(part.0)}\"\{svg_matrix(part.1)}/>",
          )
        }
        out.write_string("</clipPath><g clip-path=\"url(#\{id})\">")
        let last = open_groups.length() - 1
        open_groups[last] += 1
      }
      FillPath(path, style, m) => {
        // a fill directly followed by the stroke of the same shape becomes
        // one element, as in p5's exporter
        let stroke = match ops.get(k) {
          Some(StrokePath(p2, st, sw, cap, join, m2)) if p2 == path && m2 == m => {
            k += 1
            svg_stroke_attrs(st, sw, cap, join)
          }
          _ => " stroke=\"none\""
        }
        out.write_string(
          "\{svg_shape_element(path)} fill=\"\{style}\"\{stroke}\{svg_matrix(m)}\{style_attr()}/>",
        )
      }
      StrokePath(path, style, sw, cap, join, m) =>
        out.write_string(
          "\{svg_shape_element(path)} fill=\"none\"\{svg_stroke_attrs(style, sw, cap, join)}\{svg_matrix(m)}\{style_attr()}/>",
        )
      FillRect(x, y, rw, rh, style, m) =>
        out.write_string(
          "<rect x=\"\{svg_num(x)}\" y=\"\{svg_num(y)}\" width=\"\{svg_num(rw)}\" height=\"\{svg_num(rh)}\" fill=\"\{style}\"\{svg_matrix(m)}\{style_attr()}/>",
        )
      FillText(t, x, y, style, font, al, bl, m) =>
        out.write_string(
          "<text x=\"\{svg_num(x)}\" y=\"\{svg_num(y)}\" fill=\"\{style}\" text-anchor=\"\{svg_anchor(al)}\" dominant-baseline=\"\{svg_baseline(bl)}\" style=\"font:\{xml_escape(font)};white-space:pre\{if blend.is_empty() { "" } else { ";mix-blend-mode:" + blend }}\"\{svg_matrix(m)}>\{xml_escape(t)}</text>",
        )
      StrokeText(t, x, y, style, sw, font, al, bl, m) =>
        out.write_string(
          "<text x=\"\{svg_num(x)}\" y=\"\{svg_num(y)}\" fill=\"none\" stroke=\"\{style}\" stroke-width=\"\{svg_num(sw)}\" text-anchor=\"\{svg_anchor(al)}\" dominant-baseline=\"\{svg_baseline(bl)}\" style=\"font:\{xml_escape(font)};white-space:pre\"\{svg_matrix(m)}>\{xml_escape(t)}</text>",
        )
      DrawImage(img, iw, ih, _, src, dst, m) => {
        let url = @dom.image_to_data_url(img, iw, ih)
        out.write_string(
          "<svg x=\"\{svg_num(dst.0)}\" y=\"\{svg_num(dst.1)}\" width=\"\{svg_num(dst.2)}\" height=\"\{svg_num(dst.3)}\" viewBox=\"\{svg_num(src.0)} \{svg_num(src.1)} \{svg_num(src.2)} \{svg_num(src.3)}\" preserveAspectRatio=\"none\" overflow=\"hidden\"\{svg_matrix(m)}><image href=\"\{url}\" width=\"\{iw}\" height=\"\{ih}\"/></svg>",
        )
      }
    }
  }
  while open_groups.length() > 0 {
    let n = open_groups.pop().unwrap_or(0)
    for _ in 0..<n {
      out.write_string("</g>")
    }
    if open_groups.length() > 0 {
      out.write_string("</g>")
    }
  }
  out.write_string("</svg>")
  out.to_string()
}

///|
/// Downloads a shape collection as an SVG file, like p5's `saveSVG(record,
/// filename)`.
pub fn P5::save_svg(
  self : P5,
  coll : ShapeCollection,
  filename~ : String = "drawing.svg",
) -> Unit {
  let name = if filename.has_suffix(".svg") {
    filename
  } else {
    filename + ".svg"
  }
  @dom.download_text(self.get_svg(coll), name, "image/svg+xml")
}

///|
/// Records the next frame drawn by `draw` and downloads it as SVG, like
/// p5's `saveSVG(filename)`.
pub fn P5::save_svg_frame(
  self : P5,
  filename~ : String = "drawing.svg",
) -> Unit {
  self.pending_svg = Some(filename)
}
