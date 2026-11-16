///|
/// A drawing backend. The sketch computes transforms and styles itself and
/// asks the surface to paint paths, text and pixels with them.
///
/// `CanvasSurface` paints on an HTML canvas; `Recorder` records the calls,
/// which is handy for tests and headless use.
pub(open) trait Surface {
  fn set_transform(Self, Matrix2D) -> Unit
  fn save(Self) -> Unit
  fn restore(Self) -> Unit
  fn fill_path(Self, @shape.Path, String) -> Unit
  fn stroke_path(Self, @shape.Path, String, Double, StrokeCap, StrokeJoin) -> Unit
  fn clip(Self, @shape.Path) -> Unit
  fn fill_rect(Self, Double, Double, Double, Double, String) -> Unit
  fn clear_rect(Self, Double, Double, Double, Double) -> Unit
  fn set_blend_mode(Self, BlendMode) -> Unit
  fn set_text_style(Self, String, HAlign, VAlign) -> Unit
  fn fill_text(Self, String, Double, Double, String) -> Unit
  fn stroke_text(Self, String, Double, Double, String, Double, StrokeJoin) -> Unit
  fn text_width(Self, String) -> Double
  fn text_ascent(Self) -> Double
  fn text_descent(Self) -> Double
  fn draw_image(
    Self,
    @dom.ImageElement,
    Int32,
    Int32,
    (Double, Double, Double, Double)?,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
  ) -> Unit
  fn read_pixels(Self, Int32, Int32, Int32, Int32) -> FixedArray[Byte]
  fn write_pixels(Self, FixedArray[Byte], Int32, Int32, Int32, Int32) -> Unit
  fn resize(Self, Double, Double, Double) -> Unit
  fn set_smoothing(Self, Bool) -> Unit
  fn set_css_filter(Self, String) -> Unit
}

///|
fn css_align(a : HAlign) -> String {
  match a {
    Left => "left"
    HCenter => "center"
    Right => "right"
  }
}

///|
fn css_baseline(a : VAlign) -> String {
  match a {
    Top => "top"
    VCenter => "middle"
    Bottom => "bottom"
    Baseline => "alphabetic"
  }
}

///|
/// A surface backed by an HTML canvas.
pub struct CanvasSurface {
  canvas : @dom.Canvas
  ctx : @dom.Context2D
}

///|
/// Wraps a canvas element.
pub fn CanvasSurface::new(canvas : @dom.Canvas) -> CanvasSurface {
  { canvas, ctx: @dom.get_context(canvas), }
}

///|
fn to_path2d(path : @shape.Path) -> @dom.Path2D {
  let p = @dom.path_new()
  for cmd in path {
    match cmd {
      MoveTo(x, y) => @dom.path_move_to(p, x, y)
      LineTo(x, y) => @dom.path_line_to(p, x, y)
      QuadraticCurveTo(a, b, c, d) =>
        @dom.path_quadratic_curve_to(p, a, b, c, d)
      BezierCurveTo(a, b, c, d, e, f) =>
        @dom.path_bezier_curve_to(p, a, b, c, d, e, f)
      Ellipse(x, y, rx, ry, r, s, e) =>
        @dom.path_ellipse(p, x, y, rx, ry, r, s, e)
      Rect(x, y, w, h) => @dom.path_rect(p, x, y, w, h)
      RoundRect(x, y, w, h, a, b, c, d) =>
        @dom.path_round_rect(p, x, y, w, h, a, b, c, d)
      ClosePath => @dom.path_close(p)
    }
  }
  p
}

///|
pub impl Surface for CanvasSurface with fn set_transform(self, m) {
  @dom.set_transform(self.ctx, m.a, m.b, m.c, m.d, m.e, m.f)
}

///|
pub impl Surface for CanvasSurface with fn save(self) {
  @dom.save(self.ctx)
}

///|
pub impl Surface for CanvasSurface with fn restore(self) {
  @dom.restore(self.ctx)
}

///|
pub impl Surface for CanvasSurface with fn fill_path(self, path, style) {
  @dom.fill_path(self.ctx, to_path2d(path), style)
}

///|
pub impl Surface for CanvasSurface with fn stroke_path(
  self,
  path,
  style,
  w,
  cap,
  join,
) {
  @dom.stroke_path(self.ctx, to_path2d(path), style, w, cap.css(), join.css())
}

///|
pub impl Surface for CanvasSurface with fn clip(self, path) {
  @dom.clip_path(self.ctx, to_path2d(path))
}

///|
pub impl Surface for CanvasSurface with fn fill_rect(self, x, y, w, h, style) {
  @dom.fill_rect(self.ctx, x, y, w, h, style)
}

///|
pub impl Surface for CanvasSurface with fn clear_rect(self, x, y, w, h) {
  @dom.clear_rect(self.ctx, x, y, w, h)
}

///|
pub impl Surface for CanvasSurface with fn set_blend_mode(self, mode) {
  @dom.set_composite(self.ctx, mode.css())
}

///|
pub impl Surface for CanvasSurface with fn set_text_style(
  self,
  font,
  align,
  baseline,
) {
  @dom.set_text_style(self.ctx, font, css_align(align), css_baseline(baseline))
}

///|
pub impl Surface for CanvasSurface with fn fill_text(self, s, x, y, style) {
  @dom.fill_text(self.ctx, s, x, y, style)
}

///|
pub impl Surface for CanvasSurface with fn stroke_text(
  self,
  s,
  x,
  y,
  style,
  w,
  join,
) {
  @dom.stroke_text(self.ctx, s, x, y, style, w, join.css())
}

///|
pub impl Surface for CanvasSurface with fn text_width(self, s) {
  @dom.measure_width(self.ctx, s)
}

///|
pub impl Surface for CanvasSurface with fn text_ascent(self) {
  @dom.measure_ascent(self.ctx)
}

///|
pub impl Surface for CanvasSurface with fn text_descent(self) {
  @dom.measure_descent(self.ctx)
}

///|
pub impl Surface for CanvasSurface with fn draw_image(
  self,
  img,
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
  match tint {
    None => @dom.draw_image(self.ctx, img, sx, sy, sw, sh, dx, dy, dw, dh)
    Some((r, g, b, a)) =>
      @dom.draw_tinted_image(
        self.ctx,
        img,
        iw,
        ih,
        r,
        g,
        b,
        a,
        sx,
        sy,
        sw,
        sh,
        dx,
        dy,
        dw,
        dh,
      )
  }
}

///|
pub impl Surface for CanvasSurface with fn read_pixels(self, x, y, w, h) {
  let data = @dom.get_image_data(self.ctx, x, y, w, h)
  let out = FixedArray::make(w * h * 4, (0 : Byte))
  @dom.image_data_copy_to(data, out)
  out
}

///|
pub impl Surface for CanvasSurface with fn write_pixels(self, bytes, x, y, w, h) {
  let data = @dom.get_image_data(self.ctx, x, y, w, h)
  @dom.image_data_copy_from(data, bytes)
  @dom.save(self.ctx)
  @dom.set_transform(self.ctx, 1, 0, 0, 1, 0, 0)
  @dom.put_image_data(self.ctx, data, x, y)
  @dom.restore(self.ctx)
}

///|
pub impl Surface for CanvasSurface with fn resize(self, w, h, density) {
  @dom.resize_canvas(self.canvas, w, h, density)
}

///|
pub impl Surface for CanvasSurface with fn set_smoothing(self, on) {
  @dom.set_image_smoothing(self.ctx, on)
}

///|
pub impl Surface for CanvasSurface with fn set_css_filter(self, f) {
  @dom.set_filter(self.ctx, f)
}
