// Port of p5.js src/shape/{2d_primitives,attributes,curves,vertex,custom_shapes}.js
// for the 2D renderer.

///|
fn P5::fill_css(self : P5) -> String? {
  match self.state.fill {
    None => None
    Some(c) =>
      if self.state.erasing {
        Some(Color::rgb(255, 255, 255, alpha=self.erase_strength.0).to_css())
      } else {
        Some(c.to_css())
      }
  }
}

///|
fn P5::stroke_css(self : P5) -> String? {
  match self.state.stroke {
    None => None
    Some(c) =>
      if self.state.erasing {
        Some(Color::rgb(255, 255, 255, alpha=self.erase_strength.1).to_css())
      } else {
        Some(c.to_css())
      }
  }
}

///|
/// Paints (or adds to the clip path) a finished shape.
fn P5::draw_shape(self : P5, shape : Shape, fill~ : Bool = true) -> Unit {
  if self.clipping {
    let paths = shape.to_paths(has_fill=false, has_stroke=false)
    let relative = match self.clip_base.invert() {
      Some(inv) => inv.multiply(self.device_matrix())
      None => self.device_matrix()
    }
    self.clip_parts.push((paths.path, relative))
    return
  }
  let fill_css = if fill { self.fill_css() } else { None }
  let stroke_css = self.stroke_css()
  if fill_css is None && stroke_css is None {
    return
  }
  let paths = shape.to_paths(
    has_fill=fill_css is Some(_),
    has_stroke=stroke_css is Some(_),
  )
  self.sync_transform()
  if fill_css is Some(css) {
    self.surface.fill_path(paths.fill_path(), css)
  }
  if stroke_css is Some(css) {
    self.surface.stroke_path(
      paths.stroke_path(),
      css,
      self.state.stroke_weight,
      self.state.stroke_cap,
      self.state.stroke_join,
    )
  }
}

///|
fn P5::fresh_shape(self : P5) -> Shape {
  let s = self.shape
  s.reset()
  s.begin_shape()
  s
}

///|
fn P5::to_radians(self : P5, a : Double) -> Double {
  if self.degrees.val {
    a * DEG_TO_RAD
  } else {
    a
  }
}

///|
fn P5::from_radians(self : P5, a : Double) -> Double {
  if self.degrees.val {
    a * RAD_TO_DEG
  } else {
    a
  }
}

///|
/// Draws a point. Its size is the stroke weight; it uses the stroke color.
pub fn P5::point(self : P5, x : Double, y : Double) -> Unit {
  if self.state.stroke is None && !self.clipping {
    return
  }
  let s = self.fresh_shape()
  s.point(x, y)
  s.end_shape()
  self.draw_shape(s, fill=false)
}

///|
/// Draws a point at a vector's position.
pub fn P5::point_vec(self : P5, v : Vector) -> Unit {
  self.point(v.x, v.y)
}

///|
/// Draws a straight line between two points.
pub fn P5::line(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Unit {
  if self.state.stroke is None && !self.clipping {
    return
  }
  let s = self.fresh_shape()
  s.line(x1, y1, x2, y2)
  s.end_shape()
  self.draw_shape(s, fill=false)
}

///|
/// Draws a rectangle. Its meaning depends on `rect_mode()` (corner by
/// default). Optional corner radii round the corners: `tl` alone rounds all
/// corners; `tr`, `br`, `bl` default to the previous radius.
pub fn P5::rect(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  tl? : Double,
  tr? : Double,
  br? : Double,
  bl? : Double,
) -> Unit {
  let (rx, ry, rw, rh) = @shape.mode_adjust(x, y, w, h, self.state.rect_mode)
  let (rw, rh) = if self.state.rect_mode is Corner { (w, h) } else { (rw, rh) }
  let radii = match tl {
    None => None
    Some(tl) => {
      let tr = tr.unwrap_or(tl)
      let br = br.unwrap_or(tr)
      let bl = bl.unwrap_or(br)
      Some((tl, tr, br, bl))
    }
  }
  let s = self.fresh_shape()
  s.rect(rx, ry, rw, rh, radii?)
  s.end_shape()
  self.draw_shape(s)
}

///|
/// Draws a square of side `size`.
pub fn P5::square(
  self : P5,
  x : Double,
  y : Double,
  size : Double,
  tl? : Double,
  tr? : Double,
  br? : Double,
  bl? : Double,
) -> Unit {
  self.rect(x, y, size, size, tl?, tr?, br?, bl?)
}

///|
/// Draws an ellipse. Its meaning depends on `ellipse_mode()` (center by
/// default). `h` defaults to `w`.
pub fn P5::ellipse(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h? : Double,
) -> Unit {
  let h = h.unwrap_or(w)
  let (ex, ey, ew, eh) = @shape.mode_adjust(x, y, w, h, self.state.ellipse_mode)
  let s = self.fresh_shape()
  s.ellipse(ex, ey, ew, eh)
  s.end_shape()
  self.draw_shape(s)
}

///|
/// Draws a circle of diameter `d`.
pub fn P5::circle(self : P5, x : Double, y : Double, d : Double) -> Unit {
  self.ellipse(x, y, d, h=d)
}

///|
/// Draws an arc of the ellipse `x, y, w, h` from `start` to `stop` (in the
/// current angle mode), clockwise.
pub fn P5::arc(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  start : Double,
  stop : Double,
  mode? : ArcMode,
) -> Unit {
  if start == stop {
    return
  }
  let start = self.to_radians(start)
  let stop = self.to_radians(stop)
  let (ax, ay, aw, ah) = @shape.mode_adjust(x, y, w, h, self.state.ellipse_mode)
  let angles = @shape.normalize_arc_angles(start, stop, aw, ah)
  let s = self.fresh_shape()
  if angles.same_point {
    s.ellipse(ax, ay, aw, ah)
    s.end_shape()
  } else {
    s.arc(ax, ay, aw, ah, angles.start, angles.stop, mode)
  }
  self.draw_shape(s)
}

///|
/// Draws a triangle.
pub fn P5::triangle(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
) -> Unit {
  let s = self.fresh_shape()
  s.triangle(x1, y1, x2, y2, x3, y3)
  s.end_shape()
  self.draw_shape(s)
}

///|
/// Draws a quadrilateral.
pub fn P5::quad(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
  x4 : Double,
  y4 : Double,
) -> Unit {
  let s = self.fresh_shape()
  s.quad(x1, y1, x2, y2, x3, y3, x4, y4)
  s.end_shape()
  self.draw_shape(s)
}

///|
/// Draws a cubic Bézier curve from `(x1, y1)` to `(x4, y4)` with control
/// points `(x2, y2)` and `(x3, y3)`.
pub fn P5::bezier(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
  x4 : Double,
  y4 : Double,
) -> Unit {
  let order = self.state.bezier_order
  self.state.bezier_order = 3
  self.begin_shape()
  self.bezier_vertex(x1, y1)
  self.bezier_vertex(x2, y2)
  self.bezier_vertex(x3, y3)
  self.bezier_vertex(x4, y4)
  self.end_shape()
  self.state.bezier_order = order
}

///|
/// Draws a Catmull-Rom spline segment between `(x2, y2)` and `(x3, y3)`;
/// the first and last points are control points.
pub fn P5::spline(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
  x4 : Double,
  y4 : Double,
) -> Unit {
  self.begin_shape()
  self.spline_vertex(x1, y1)
  self.spline_vertex(x2, y2)
  self.spline_vertex(x3, y3)
  self.spline_vertex(x4, y4)
  self.end_shape()
}

///|
/// Alias of `spline` (p5.js 1.x `curve()`), always with excluded ends.
pub fn P5::curve(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
  x4 : Double,
  y4 : Double,
) -> Unit {
  let ends = self.state.spline_ends
  self.state.spline_ends = Exclude
  self.spline(x1, y1, x2, y2, x3, y3, x4, y4)
  self.state.spline_ends = ends
}

///|
/// Starts recording vertices for a custom shape.
pub fn P5::begin_shape(self : P5, kind~ : ShapeKind = Path) -> Unit {
  let s = self.shape
  s.reset()
  s.set_bezier_order(self.state.bezier_order)
  s.set_spline_ends(self.state.spline_ends)
  s.set_spline_tightness(self.state.spline_tightness)
  s.begin_shape(kind~)
}

///|
/// Adds a vertex to the current shape.
pub fn P5::vertex(self : P5, x : Double, y : Double) -> Unit {
  self.shape.vertex(x, y)
}

///|
/// Adds a Bézier vertex. The first one in a path is the anchor; then every
/// `bezier_order()` vertices (3 by default) form one curve.
pub fn P5::bezier_vertex(self : P5, x : Double, y : Double) -> Unit {
  self.shape.bezier_vertex(x, y)
}

///|
/// p5.js 1.x style `bezierVertex(cx1, cy1, cx2, cy2, x, y)`.
pub fn P5::bezier_vertex3(
  self : P5,
  cx1 : Double,
  cy1 : Double,
  cx2 : Double,
  cy2 : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.shape.bezier_vertex(cx1, cy1)
  self.shape.bezier_vertex(cx2, cy2)
  self.shape.bezier_vertex(x, y)
}

///|
/// p5.js 1.x style `quadraticVertex(cx, cy, x, y)`.
pub fn P5::quadratic_vertex(
  self : P5,
  cx : Double,
  cy : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.shape.set_bezier_order(2)
  self.shape.bezier_vertex(cx, cy)
  self.shape.bezier_vertex(x, y)
  self.shape.set_bezier_order(self.state.bezier_order)
}

///|
/// Adds a spline vertex to the current shape.
pub fn P5::spline_vertex(self : P5, x : Double, y : Double) -> Unit {
  self.shape.spline_vertex(x, y)
}

///|
/// Alias of `spline_vertex` (p5.js 1.x `curveVertex`).
pub fn P5::curve_vertex(self : P5, x : Double, y : Double) -> Unit {
  self.spline_vertex(x, y)
}

///|
/// Starts a contour (e.g. a hole) inside the current shape.
pub fn P5::begin_contour(self : P5, kind~ : ShapeKind = Path) -> Unit {
  self.shape.begin_contour(kind~)
}

///|
/// Ends the current contour; `Close` connects it back to its first vertex.
pub fn P5::end_contour(self : P5, mode~ : CloseMode = Open) -> Unit {
  self.shape.end_contour(mode~)
}

///|
/// Finishes the current shape and draws it.
pub fn P5::end_shape(self : P5, mode~ : CloseMode = Open) -> Unit {
  self.shape.end_shape(mode~)
  self.draw_shape(self.shape)
}

///|
/// Sets the order of Bézier curves built with `bezier_vertex` (2 or 3).
pub fn P5::bezier_order(self : P5, order : Int32) -> Unit {
  if order == 2 || order == 3 {
    self.state.bezier_order = order
    self.shape.set_bezier_order(order)
  } else {
    warn("bezier_order() expects an order of 2 or 3, but received \{order}.")
  }
}

///|
/// Sets how splines treat their first and last vertices.
pub fn P5::spline_ends(self : P5, ends : SplineEnds) -> Unit {
  self.state.spline_ends = ends
  self.shape.set_spline_ends(ends)
}

///|
/// Sets spline tightness (0 = Catmull-Rom, 1 = straight lines).
pub fn P5::spline_tightness(self : P5, t : Double) -> Unit {
  self.state.spline_tightness = t
  self.shape.set_spline_tightness(t)
}

///|
/// Alias of `spline_tightness` (p5.js 1.x `curveTightness`).
pub fn P5::curve_tightness(self : P5, t : Double) -> Unit {
  self.spline_tightness(t)
}

///|
/// Evaluates a spline coordinate using the current tightness.
pub fn P5::spline_point(
  self : P5,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
) -> Double {
  @shape.spline_point(a, b, c, d, t, tightness=self.state.spline_tightness)
}

///|
/// Evaluates a spline tangent using the current tightness.
pub fn P5::spline_tangent(
  self : P5,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  t : Double,
) -> Double {
  @shape.spline_tangent(a, b, c, d, t, tightness=self.state.spline_tightness)
}

///|
/// Sets how `rect()` interprets its arguments.
pub fn P5::rect_mode(self : P5, mode : ShapeMode) -> Unit {
  self.state.rect_mode = mode
}

///|
/// Sets how `ellipse()`, `circle()` and `arc()` interpret their arguments.
pub fn P5::ellipse_mode(self : P5, mode : ShapeMode) -> Unit {
  self.state.ellipse_mode = mode
}

///|
/// Sets the width of lines and outlines, in pixels.
pub fn P5::stroke_weight(self : P5, w : Double) -> Unit {
  self.state.stroke_weight = w
}

///|
/// Sets the style of line ends.
pub fn P5::stroke_cap(self : P5, cap : StrokeCap) -> Unit {
  self.gl_cap = match cap {
    Round => 0
    Project => 1
    Square => 2
  }
  self.state.stroke_cap = cap
}

///|
/// Sets the style of line joints.
pub fn P5::stroke_join(self : P5, join : StrokeJoin) -> Unit {
  self.gl_join = match join {
    RoundJoin => 0
    Miter => 1
    Bevel => 2
  }
  self.state.stroke_join = join
}

///|
/// Enables antialiasing of images (default).
pub fn P5::smooth(self : P5) -> Unit {
  self.state.smooth = true
  self.surface.set_smoothing(true)
}

///|
/// Disables antialiasing of images (crisp pixel art scaling).
pub fn P5::no_smooth(self : P5) -> Unit {
  self.state.smooth = false
  self.surface.set_smoothing(false)
}
