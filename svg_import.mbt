// SVG import (p5's createSVG()/loadSVG()): parses SVG markup into a shape
// collection that shape() can draw.

///|
priv struct SvgStyle {
  fill : String
  stroke : String
  stroke_width : Double
  opacity : Double
  fill_opacity : Double
  stroke_opacity : Double
  cap : StrokeCap
  join : StrokeJoin
  color : String
  visible : Bool
}

///|
fn default_svg_style() -> SvgStyle {
  {
    fill: "black",
    stroke: "none",
    stroke_width: 1,
    opacity: 1,
    fill_opacity: 1,
    stroke_opacity: 1,
    cap: Square,
    join: Miter,
    color: "black",
    visible: true,
  }
}

///|
/// Reads a property from the `style` attribute or the presentation
/// attribute of the same name.
fn svg_prop(el : Xml, name : String) -> String? {
  if el.get_string("style") is Some(style) {
    for decl in style.split(";") {
      let parts = [ for p in decl.split(":") => p.trim().to_owned() ]
      if parts.length() >= 2 && parts[0] == name {
        return Some(parts[1:].to_owned().join(":"))
      }
    }
  }
  el.get_string(name)
}

///|
fn svg_len(s : String?, default : Double) -> Double {
  match s {
    None => default
    Some(v) => {
      let n = @io.parse_float(v)
      if n.is_nan() {
        default
      } else {
        n
      }
    }
  }
}

///|
fn opacity_value(s : String?) -> Double? {
  match s {
    None => None
    Some(v) => {
      let n = if v.has_suffix("%") {
        @io.parse_float(v) / 100
      } else {
        @io.parse_float(v)
      }
      if n.is_nan() {
        None
      } else {
        Some(n.max(0).min(1))
      }
    }
  }
}

///|
fn SvgStyle::derive_from(self : SvgStyle, el : Xml) -> SvgStyle {
  let color = svg_prop(el, "color").unwrap_or(self.color)
  let opacity = self.opacity *
    opacity_value(svg_prop(el, "opacity")).unwrap_or(1)
  {
    fill: svg_prop(el, "fill").unwrap_or(self.fill),
    stroke: svg_prop(el, "stroke").unwrap_or(self.stroke),
    stroke_width: svg_len(svg_prop(el, "stroke-width"), self.stroke_width),
    opacity,
    fill_opacity: opacity_value(svg_prop(el, "fill-opacity")).unwrap_or(
      self.fill_opacity,
    ),
    stroke_opacity: opacity_value(svg_prop(el, "stroke-opacity")).unwrap_or(
      self.stroke_opacity,
    ),
    cap: match svg_prop(el, "stroke-linecap") {
      Some("round") => Round
      Some("square") => Project
      Some("butt") => Square
      _ => self.cap
    },
    // like p5's importer, the line join is not imported
    join: self.join,
    color,
    visible: (match svg_prop(el, "visibility") {
      Some("hidden" | "collapse") => false
      Some("visible") => true
      _ => self.visible
    }) &&
    svg_prop(el, "display") != Some("none"),
  }
}

///|
/// A paint (`fill`/`stroke`) as CSS with opacity applied, or `None`.
fn svg_paint(paint : String, opacity : Double, current : String) -> String? {
  let p = paint.trim().to_owned()
  if p == "none" || p.has_prefix("url(") {
    return None
  }
  let p = if p.to_lower() == "currentcolor" { current } else { p }
  match Color::parse(p) {
    Some(c) => {
      let (r, g, b, a) = c.to_srgb()
      Some(Color::from_native(RGB, r, g, b, alpha=a * opacity).to_css())
    }
    None => None
  }
}

///|
/// Numbers in an attribute list such as `points` or `transform(...)`.
fn svg_numbers(s : String) -> Array[Double] {
  let out : Array[Double] = []
  let chars = s.to_array()
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c.is_ascii_digit() || c == '-' || c == '+' || c == '.' {
      let b = i
      i += 1
      let mut dot = c == '.'
      while i < n {
        let d = chars[i]
        if d.is_ascii_digit() {
          i += 1
        } else if d == '.' && !dot {
          dot = true
          i += 1
        } else if (d == 'e' || d == 'E') && i + 1 < n {
          i += 1
          if chars[i] == '-' || chars[i] == '+' {
            i += 1
          }
        } else {
          break
        }
      }
      out.push(@io.parse_float(String::from_array(chars[b:i])))
    } else {
      i += 1
    }
  }
  out
}

///|
/// Parses an SVG `transform` attribute.
fn svg_transform(s : String) -> Matrix2D {
  let mut m = @math.identity
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() {
    while i < chars.length() && !chars[i].is_ascii_alphabetic() {
      i += 1
    }
    let b = i
    while i < chars.length() && chars[i].is_ascii_alphabetic() {
      i += 1
    }
    let name = String::from_array(chars[b:i])
    while i < chars.length() && chars[i] != '(' {
      i += 1
    }
    let ab = i + 1
    while i < chars.length() && chars[i] != ')' {
      i += 1
    }
    if ab > chars.length() {
      break
    }
    let args = svg_numbers(String::from_array(chars[ab:i.min(chars.length())]))
    i += 1
    let a = (k : Int32, d : Double) => args.get(k).unwrap_or(d)
    m = match name {
      "matrix" if args.length() >= 6 =>
        m.multiply({
          a: args[0],
          b: args[1],
          c: args[2],
          d: args[3],
          e: args[4],
          f: args[5],
        })
      "translate" => m.translate(a(0, 0), a(1, 0))
      "scale" => m.scale(a(0, 1), a(1, a(0, 1)))
      "rotate" => {
        let r = a(0, 0) * DEG_TO_RAD
        if args.length() >= 3 {
          m.translate(args[1], args[2]).rotate(r).translate(-args[1], -args[2])
        } else {
          m.rotate(r)
        }
      }
      "skewX" => m.shear_x(a(0, 0) * DEG_TO_RAD)
      "skewY" => m.shear_y(a(0, 0) * DEG_TO_RAD)
      _ => m
    }
  }
  m
}

///|
/// Converts an SVG elliptical arc to cubic Béziers, exactly like p5's
/// importer (`arcToBezier`).
fn arc_to_beziers(
  out : @shape.Path,
  x1 : Double,
  y1 : Double,
  rx : Double,
  ry : Double,
  phi_deg : Double,
  large : Bool,
  sweep : Bool,
  x2 : Double,
  y2 : Double,
) -> Unit {
  if x1 == x2 && y1 == y2 {
    return
  }
  if rx == 0 || ry == 0 {
    out.push(BezierCurveTo(x1, y1, x2, y2, x2, y2))
    return
  }
  let mut rx = rx.abs()
  let mut ry = ry.abs()
  let phi = phi_deg * PI / 180
  let cos_phi = @cmath.cos(phi)
  let sin_phi = @cmath.sin(phi)
  let dx = (x1 - x2) / 2
  let dy = (y1 - y2) / 2
  let x1p = cos_phi * dx + sin_phi * dy
  let y1p = -sin_phi * dx + cos_phi * dy
  let mut rx_sq = rx * rx
  let mut ry_sq = ry * ry
  let x1p_sq = x1p * x1p
  let y1p_sq = y1p * y1p
  let radii_check = x1p_sq / rx_sq + y1p_sq / ry_sq
  if radii_check > 1 {
    rx *= radii_check.sqrt()
    ry *= radii_check.sqrt()
    rx_sq = rx * rx
    ry_sq = ry * ry
  }
  let sign = if large == sweep { -1.0 } else { 1.0 }
  let sq = (rx_sq * ry_sq - rx_sq * y1p_sq - ry_sq * x1p_sq) /
    (rx_sq * y1p_sq + ry_sq * x1p_sq)
  let coef = sign * sq.max(0).sqrt()
  let cxp = coef * (rx * y1p / ry)
  let cyp = coef * -(ry * x1p / rx)
  let cx = cos_phi * cxp - sin_phi * cyp + (x1 + x2) / 2
  let cy = sin_phi * cxp + cos_phi * cyp + (y1 + y2) / 2
  let sx = (x1p - cxp) / rx
  let sy = (y1p - cyp) / ry
  let tx = (-x1p - cxp) / rx
  let ty = (-y1p - cyp) / ry
  let angle_between = (ux : Double, uy : Double, vx : Double, vy : Double) => {
    let dot = ux * vx + uy * vy
    let len = (ux * ux + uy * uy).sqrt() * (vx * vx + vy * vy).sqrt()
    let a = @cmath.acos((dot / len).min(1).max(-1))
    if ux * vy - uy * vx < 0 {
      -a
    } else {
      a
    }
  }
  let theta1 = angle_between(1, 0, sx, sy)
  let mut delta = angle_between(sx, sy, tx, ty)
  if !sweep && delta > 0 {
    delta -= 2 * PI
  } else if sweep && delta < 0 {
    delta += 2 * PI
  }
  let segments = (delta.abs() / (PI / 2)).ceil().to_int()
  let t_div = delta / segments.to_double()
  let point = (x : Double, y : Double) => {
    let rxx = rx * x
    let ryy = ry * y
    (cos_phi * rxx - sin_phi * ryy + cx, sin_phi * rxx + cos_phi * ryy + cy)
  }
  let mut t_start = theta1
  for _ in 0..<segments {
    let t_end = t_start + t_div
    let half = @cmath.tan(t_div / 2)
    let alpha = @cmath.sin(t_div) * ((4.0 + 3 * half * half).sqrt() - 1) / 3
    let (cs, ss) = (@cmath.cos(t_start), @cmath.sin(t_start))
    let (ce, se) = (@cmath.cos(t_end), @cmath.sin(t_end))
    let (c1x, c1y) = point(cs - alpha * ss, ss + alpha * cs)
    let (c2x, c2y) = point(ce + alpha * se, se - alpha * ce)
    let (ex, ey) = point(ce, se)
    out.push(BezierCurveTo(c1x, c1y, c2x, c2y, ex, ey))
    t_start = t_end
  }
}

///|
/// Parses SVG path data into canvas path commands.
pub fn parse_svg_path(d : String) -> @shape.Path {
  let out : @shape.Path = []
  let chars = d.to_array()
  let n = chars.length()
  let mut i = 0
  let skip = () => {
    while i < n && (chars[i].is_ascii_whitespace() || chars[i] == ',') {
      i += 1
    }
  }
  let number = () => {
    skip()
    let b = i
    if i < n && (chars[i] == '-' || chars[i] == '+') {
      i += 1
    }
    let mut dot = false
    while i < n {
      let c = chars[i]
      if c.is_ascii_digit() {
        i += 1
      } else if c == '.' && !dot {
        dot = true
        i += 1
      } else if (c == 'e' || c == 'E') && i > b {
        i += 1
        if i < n && (chars[i] == '-' || chars[i] == '+') {
          i += 1
        }
      } else {
        break
      }
    }
    if i == b {
      None
    } else {
      Some(@io.parse_float(String::from_array(chars[b:i])))
    }
  }
  let flag = () => {
    skip()
    if i < n && (chars[i] == '0' || chars[i] == '1') {
      i += 1
      Some(chars[i - 1] == '1')
    } else {
      None
    }
  }
  let mut x = 0.0
  let mut y = 0.0
  let mut sx = 0.0
  let mut sy = 0.0
  // last control point for S/T
  let mut lcx = 0.0
  let mut lcy = 0.0
  let mut last = ' '
  let mut cmd = ' '
  while i < n {
    skip()
    if i >= n {
      break
    }
    if chars[i].is_ascii_alphabetic() {
      cmd = chars[i]
      i += 1
    } else if cmd == ' ' {
      break
    }
    let rel = cmd.is_ascii_lowercase()
    let ox = if rel { x } else { 0.0 }
    let oy = if rel { y } else { 0.0 }
    match cmd.to_ascii_uppercase() {
      'M' => {
        guard number() is Some(a) && number() is Some(b) else { break }
        x = ox + a
        y = oy + b
        sx = x
        sy = y
        out.push(MoveTo(x, y))
        // further pairs are implicit line-tos
        cmd = if rel { 'l' } else { 'L' }
      }
      'L' => {
        guard number() is Some(a) && number() is Some(b) else { break }
        x = ox + a
        y = oy + b
        out.push(LineTo(x, y))
      }
      'H' => {
        guard number() is Some(a) else { break }
        x = ox + a
        out.push(LineTo(x, y))
      }
      'V' => {
        guard number() is Some(b) else { break }
        y = oy + b
        out.push(LineTo(x, y))
      }
      'C' => {
        guard number() is Some(a) &&
          number() is Some(b) &&
          number() is Some(c) &&
          number() is Some(e) &&
          number() is Some(f) &&
          number() is Some(g) else {
          break
        }
        lcx = ox + c
        lcy = oy + e
        x = ox + f
        y = oy + g
        out.push(BezierCurveTo(ox + a, oy + b, lcx, lcy, x, y))
      }
      'S' => {
        guard number() is Some(c) &&
          number() is Some(e) &&
          number() is Some(f) &&
          number() is Some(g) else {
          break
        }
        let (c1x, c1y) = if last.to_ascii_uppercase() is ('C' | 'S') {
          (2.0 * x - lcx, 2.0 * y - lcy)
        } else {
          (x, y)
        }
        lcx = ox + c
        lcy = oy + e
        x = ox + f
        y = oy + g
        out.push(BezierCurveTo(c1x, c1y, lcx, lcy, x, y))
      }
      'Q' => {
        guard number() is Some(a) &&
          number() is Some(b) &&
          number() is Some(c) &&
          number() is Some(e) else {
          break
        }
        lcx = ox + a
        lcy = oy + b
        x = ox + c
        y = oy + e
        out.push(QuadraticCurveTo(lcx, lcy, x, y))
      }
      'T' => {
        guard number() is Some(c) && number() is Some(e) else { break }
        if last.to_ascii_uppercase() is ('Q' | 'T') {
          lcx = 2.0 * x - lcx
          lcy = 2.0 * y - lcy
        } else {
          lcx = x
          lcy = y
        }
        x = ox + c
        y = oy + e
        out.push(QuadraticCurveTo(lcx, lcy, x, y))
      }
      'A' => {
        guard number() is Some(rx) &&
          number() is Some(ry) &&
          number() is Some(rot) &&
          flag() is Some(large) &&
          flag() is Some(sweep) &&
          number() is Some(a) &&
          number() is Some(b) else {
          break
        }
        let nx = ox + a
        let ny = oy + b
        arc_to_beziers(out, x, y, rx, ry, rot, large, sweep, nx, ny)
        x = nx
        y = ny
      }
      'Z' => {
        out.push(ClosePath)
        x = sx
        y = sy
      }
      _ => break
    }
    last = cmd
  }
  out
}

///|
priv struct SvgImporter {
  ops : Array[DrawOp]
  ids : Map[String, Xml]
}

///|
fn collect_ids(el : Xml, ids : Map[String, Xml]) -> Unit {
  if el.get_string("id") is Some(id) {
    ids[id] = el
  }
  for c in el.get_children() {
    collect_ids(c, ids)
  }
}

///|
fn SvgImporter::emit(
  self : SvgImporter,
  path : @shape.Path,
  style : SvgStyle,
  m : Matrix2D,
  fill_ok : Bool,
) -> Unit {
  if !style.visible || path.is_empty() {
    return
  }
  if fill_ok &&
    svg_paint(style.fill, style.opacity * style.fill_opacity, style.color)
    is Some(css) {
    self.ops.push(FillPath(path, css, m))
  }
  if svg_paint(style.stroke, style.opacity * style.stroke_opacity, style.color)
    is Some(css) &&
    style.stroke_width > 0 {
    self.ops.push(
      StrokePath(path, css, style.stroke_width, style.cap, style.join, m),
    )
  }
}

///|
fn SvgImporter::visit(
  self : SvgImporter,
  el : Xml,
  parent_style : SvgStyle,
  parent_m : Matrix2D,
  depth : Int32,
) -> Unit {
  if depth > 64 {
    return
  }
  let style = parent_style.derive_from(el)
  let m = match el.get_string("transform") {
    Some(t) => parent_m.multiply(svg_transform(t))
    None => parent_m
  }
  let num = (name : String, d : Double) => svg_len(el.get_string(name), d)
  match el.get_name() {
    "svg" | "g" | "a" | "switch" =>
      for c in el.get_children() {
        self.visit(c, style, m, depth + 1)
      }
    "path" =>
      self.emit(
        parse_svg_path(el.get_string("d").unwrap_or("")),
        style,
        m,
        true,
      )
    "rect" => {
      let (x, y, w, h) = (
        num("x", 0),
        num("y", 0),
        num("width", 0),
        num("height", 0),
      )
      if w > 0 && h > 0 {
        // p5's resolvePairedRadii: a missing radius takes the other one
        let rx0 = el.get_string("rx")
        let ry0 = el.get_string("ry")
        let rx = svg_len(rx0, svg_len(ry0, 0))
        let ry = svg_len(ry0, svg_len(rx0, 0))
        let mut crx = rx.min(w / 2).max(0)
        let mut cry = ry.min(h / 2).max(0)
        if crx == 0 || cry == 0 {
          crx = 0
          cry = 0
        }
        let path : @shape.Path = if crx > 0 && cry > 0 && crx != cry {
          // p5's buildRoundedRect, with k = 0.5523
          let k = 0.5523
          [
            MoveTo(x + crx, y),
            LineTo(x + w - crx, y),
            BezierCurveTo(
              x + w - crx + crx * k,
              y,
              x + w,
              y + cry - cry * k,
              x + w,
              y + cry,
            ),
            LineTo(x + w, y + h - cry),
            BezierCurveTo(
              x + w,
              y + h - cry + cry * k,
              x + w - crx + crx * k,
              y + h,
              x + w - crx,
              y + h,
            ),
            LineTo(x + crx, y + h),
            BezierCurveTo(
              x + crx - crx * k,
              y + h,
              x,
              y + h - cry + cry * k,
              x,
              y + h - cry,
            ),
            LineTo(x, y + cry),
            BezierCurveTo(
              x,
              y + cry - cry * k,
              x + crx - crx * k,
              y,
              x + crx,
              y,
            ),
            ClosePath,
          ]
        } else if crx > 0 {
          // p5's rectPrimitive with equal radii (fitted like rect())
          let r = crx.min(w.abs() / 2).min(h.abs() / 2)
          [RoundRect(x, y, w, h, r, r, r, r)]
        } else {
          [Rect(x, y, w, h)]
        }
        self.emit(path, style, m, true)
      }
    }
    "circle" => {
      let r = num("r", 0)
      if r > 0 {
        let (cx, cy) = (num("cx", 0), num("cy", 0))
        self.emit(
          [MoveTo(cx + r, cy), Ellipse(cx, cy, r, r, 0, 0, TWO_PI)],
          style,
          m,
          true,
        )
      }
    }
    "ellipse" => {
      let (rx, ry) = (num("rx", 0), num("ry", 0))
      if rx > 0 && ry > 0 {
        let (cx, cy) = (num("cx", 0), num("cy", 0))
        self.emit(
          [MoveTo(cx + rx, cy), Ellipse(cx, cy, rx, ry, 0, 0, TWO_PI)],
          style,
          m,
          true,
        )
      }
    }
    "line" =>
      self.emit(
        [MoveTo(num("x1", 0), num("y1", 0)), LineTo(num("x2", 0), num("y2", 0))],
        style,
        m,
        false,
      )
    "polyline" | "polygon" as kind => {
      let pts = svg_numbers(el.get_string("points").unwrap_or(""))
      if pts.length() >= 2 {
        let path : @shape.Path = [MoveTo(pts[0], pts[1])]
        for k = 2; k + 1 < pts.length(); k = k + 2 {
          path.push(LineTo(pts[k], pts[k + 1]))
        }
        if kind == "polygon" {
          path.push(ClosePath)
        }
        self.emit(path, style, m, true)
      }
    }
    "use" => {
      let href : String = match el.get_string("href") {
        Some(h) => h
        None => el.get_string("xlink:href").unwrap_or("")
      }
      if href is ['#', .. id] && self.ids.get(id.to_owned()) is Some(target) {
        let mm = m.translate(num("x", 0), num("y", 0))
        self.visit(target, style, mm, depth + 1)
      }
    }
    _ => ()
  }
}

///|
/// Parses SVG markup into a shape collection, like p5's `createSVG()`.
pub fn create_svg(markup : String) -> ShapeCollection raise @io.XmlError {
  let root = Xml::parse(markup)
  let ids : Map[String, Xml] = Map([])
  collect_ids(root, ids)
  let imp : SvgImporter = { ops: [], ids, }
  imp.visit(root, default_svg_style(), @math.identity, 0)
  let vb = svg_numbers(root.get_string("viewBox").unwrap_or(""))
  let bounds = if vb.length() == 4 && vb[2] > 0 && vb[3] > 0 {
    (vb[0], vb[1], vb[2], vb[3])
  } else {
    (
      0.0,
      0.0,
      svg_len(root.get_string("width"), 0),
      svg_len(root.get_string("height"), 0),
    )
  }
  // a viewBox maps onto the element's width/height when both are given
  let w = svg_len(root.get_string("width"), bounds.2)
  let h = svg_len(root.get_string("height"), bounds.3)
  if vb.length() == 4 &&
    (w != bounds.2 || h != bounds.3) &&
    bounds.2 > 0 &&
    bounds.3 > 0 {
    let s = @math.identity.scale(w / bounds.2, h / bounds.3)
    let ops = imp.ops.map(op => {
      match op {
        FillPath(p, c, m) => FillPath(p, c, s.multiply(m))
        StrokePath(p, c, sw, cap, join, m) =>
          StrokePath(p, c, sw, cap, join, s.multiply(m))
        other => other
      }
    })
    return {
      ops,
      bounds: (bounds.0 * w / bounds.2, bounds.1 * h / bounds.3, w, h),
    }
  }
  { ops: imp.ops, bounds, }
}

///|
/// Loads an SVG file into a shape collection. In `preload`, `setup` waits
/// for it.
pub fn P5::load_svg(
  self : P5,
  url : String,
  on_load : (ShapeCollection) -> Unit,
) -> Unit {
  self.load_text(url, on_load=text => {
    let coll = create_svg(text) catch {
      @io.XmlError(msg) => {
        warn("Could not parse SVG \{url}: \{msg}")
        return
      }
    }
    on_load(coll)
  })
}
