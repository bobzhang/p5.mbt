// Port of `PrimitiveToPath2DConverter` from src/shape/custom_shapes.js.

///|
priv struct Converter {
  path : Path
  mut fill_path : Path?
  mut stroke_path : Path?
  has_fill : Bool
  has_stroke : Bool
}

///|
/// Converts the shape into canvas path commands.
///
/// ```mbt check
/// test {
///   let s = @shape.Shape::new()
///   s.begin_shape()
///   s.vertex(0, 0)
///   s.vertex(10, 0)
///   s.vertex(10, 10)
///   s.end_shape(mode=Close)
///   debug_inspect(
///     s.to_paths().path,
///     content="[MoveTo(0, 0), LineTo(10, 0), LineTo(10, 10), ClosePath]",
///   )
/// }
/// ```
pub fn Shape::to_paths(
  self : Shape,
  has_fill~ : Bool = true,
  has_stroke~ : Bool = true,
) -> ShapePaths {
  let c : Converter = {
    path: [],
    fill_path: None,
    stroke_path: None,
    has_fill,
    has_stroke,
  }
  for contour in self.contours {
    for i, prim in contour.primitives {
      c.visit(self, contour, i, prim)
    }
  }
  { path: c.path, fill: c.fill_path, stroke: c.stroke_path, }
}

///|
fn Converter::emit(self : Converter, cmd : PathCmd) -> Unit {
  self.path.push(cmd)
}

///|
fn Converter::visit(
  self : Converter,
  shape : Shape,
  contour : Contour,
  index : Int32,
  prim : Primitive,
) -> Unit {
  let v = prim.vertices
  match prim.kind {
    Anchor => {
      let p = v[v.length() - 1]
      self.emit(MoveTo(p.x, p.y))
    }
    LineSegment =>
      if prim.closing {
        self.emit(ClosePath)
      } else {
        for p in v {
          self.emit(LineTo(p.x, p.y))
        }
      }
    BezierSegment(order) =>
      match (order, v) {
        (2, [c1, p, ..]) => self.emit(QuadraticCurveTo(c1.x, c1.y, p.x, p.y))
        (3, [c1, c2, p, ..]) =>
          self.emit(BezierCurveTo(c1.x, c1.y, c2.x, c2.y, p.x, p.y))
        _ => ()
      }
    SplineSegment => self.visit_spline(shape, contour, index, prim)
    PointP =>
      for p in v {
        self.emit(MoveTo(p.x, p.y))
        // Draw a tiny line so that the stroke shows up as a dot.
        self.emit(LineTo(p.x + (p.x.abs() * 1.0e-6).max(0.00001), p.y))
      }
    LineP =>
      for i = 0; i + 1 < v.length(); i = i + 2 {
        self.emit(MoveTo(v[i].x, v[i].y))
        self.emit(LineTo(v[i + 1].x, v[i + 1].y))
      }
    TriangleP =>
      for i = 0; i + 2 < v.length(); i = i + 3 {
        self.polygon([v[i], v[i + 1], v[i + 2]])
      }
    QuadP =>
      for i = 0; i + 3 < v.length(); i = i + 4 {
        self.polygon([v[i], v[i + 1], v[i + 2], v[i + 3]])
      }
    TriangleFanP =>
      for i in 1..<(v.length() - 1) {
        self.polygon([v[0], v[i], v[i + 1]])
      }
    TriangleStripP =>
      for i in 0..<(v.length() - 2) {
        self.polygon([v[i], v[i + 1], v[i + 2]])
      }
    QuadStripP =>
      for i = 0; i + 3 < v.length(); i = i + 2 {
        // Intentionally out of order to go around the quad.
        self.polygon([v[i], v[i + 1], v[i + 3], v[i + 2]])
      }
    ArcP(x, y, w, h, start, stop, mode) =>
      self.visit_arc(x, y, w, h, start, stop, mode)
    EllipseP(x, y, w, h) => {
      let cx = x + w / 2
      let cy = y + h / 2
      self.emit(MoveTo(cx + w / 2, cy))
      self.emit(Ellipse(cx, cy, w / 2, h / 2, 0, 0, @math.TWO_PI))
    }
    RectP(x, y, w, h, radii) => self.visit_rect(x, y, w, h, radii)
  }
}

///|
fn Converter::polygon(self : Converter, pts : Array[Pt]) -> Unit {
  self.emit(MoveTo(pts[0].x, pts[0].y))
  for i in 1..<pts.length() {
    self.emit(LineTo(pts[i].x, pts[i].y))
  }
  self.emit(ClosePath)
}

///|
fn Converter::visit_spline(
  self : Converter,
  _shape : Shape,
  contour : Contour,
  index : Int32,
  prim : Primitive,
) -> Unit {
  let v = prim.vertices
  let after_segment = comes_after_segment(contour, index)
  let start = start_vertex(contour, index)
  if prim.spline_ends is Exclude && !after_segment {
    let first = if after_segment { v[1] } else { v[0] }
    self.emit(MoveTo(first.x, first.y))
  }
  // Control points, as in SplineSegment.getControlPoints()
  let points : Array[Pt] = []
  if after_segment {
    points.push(start)
  }
  points.push(start)
  points.append(v)
  match prim.spline_ends {
    Include => {
      points.insert(0, start)
      points.push(v[v.length() - 1])
    }
    Join => {
      points.insert(0, v[v.length() - 1])
      points.push(start)
      points.push(v[0])
    }
    Exclude => ()
  }
  // catmullRomToBezier
  let s = 1.0 - prim.spline_tightness
  for i = 0; i + 3 < points.length(); i = i + 1 {
    let a = points[i]
    let b = points[i + 1]
    let c = points[i + 2]
    let d = points[i + 3]
    let bx = b.x + (c.x - a.x) * s / 6
    let by = b.y + (c.y - a.y) * s / 6
    let cx = c.x + (b.x - d.x) * s / 6
    let cy = c.y + (b.y - d.y) * s / 6
    self.emit(BezierCurveTo(bx, by, cx, cy, c.x, c.y))
  }
}

///|
fn Converter::visit_arc(
  self : Converter,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  start : Double,
  stop : Double,
  mode : ArcMode?,
) -> Unit {
  let cx = x + w / 2
  let cy = y + h / 2
  let rx = w / 2
  let ry = h / 2
  let sx = cx + rx * @cmath.cos(start)
  let sy = cy + ry * @cmath.sin(start)
  let delta = stop - start
  let full = @math.js_rem(delta, 2 * @math.PI).abs() < 0.00001 &&
    delta.abs() > 0.00001
  let pie_slice = !(mode is Some(Chord | Open) || full)
  if self.has_fill {
    let fp = self.fill_path.unwrap_or(self.path.copy())
    fp.push(MoveTo(sx, sy))
    fp.push(Ellipse(cx, cy, rx, ry, 0, start, stop))
    if pie_slice {
      fp.push(LineTo(cx, cy))
    }
    fp.push(ClosePath)
    self.fill_path = Some(fp)
  }
  if self.has_stroke {
    let sp = self.stroke_path.unwrap_or(self.path.copy())
    sp.push(MoveTo(sx, sy))
    sp.push(Ellipse(cx, cy, rx, ry, 0, start, stop))
    if mode is Some(Pie) && pie_slice {
      sp.push(LineTo(cx, cy))
    }
    if mode is Some(Pie | Chord) {
      sp.push(ClosePath)
    }
    self.stroke_path = Some(sp)
  }
  self.emit(MoveTo(sx, sy))
  self.emit(Ellipse(cx, cy, rx, ry, 0, start, stop))
}

///|
fn Converter::visit_rect(
  self : Converter,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  radii : (Double, Double, Double, Double)?,
) -> Unit {
  match radii {
    None => self.emit(Rect(x, y, w, h))
    Some((tl, tr, br, bl)) => {
      let abs_w = w.abs()
      let abs_h = h.abs()
      let fit = (r : Double) => {
        let mut r = r
        if abs_w < 2 * r {
          r = abs_w / 2
        }
        if abs_h < 2 * r {
          r = abs_h / 2
        }
        r
      }
      self.emit(RoundRect(x, y, w, h, fit(tl), fit(tr), fit(br), fit(bl)))
    }
  }
}
