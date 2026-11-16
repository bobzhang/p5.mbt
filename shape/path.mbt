///|
/// A canvas path command, mirroring the `Path2D` API.
#derive(Eq, Debug)
pub(all) enum PathCmd {
  MoveTo(Double, Double)
  LineTo(Double, Double)
  QuadraticCurveTo(Double, Double, Double, Double)
  BezierCurveTo(Double, Double, Double, Double, Double, Double)
  /// `ellipse(cx, cy, rx, ry, rotation, start, end)` (always clockwise)
  Ellipse(Double, Double, Double, Double, Double, Double, Double)
  Rect(Double, Double, Double, Double)
  /// `roundRect(x, y, w, h, [tl, tr, br, bl])`
  RoundRect(Double, Double, Double, Double, Double, Double, Double, Double)
  ClosePath
}

///|
/// A sequence of path commands.
pub type Path = Array[PathCmd]

///|
/// The result of converting a shape for the 2D renderer: the base `path`,
/// plus specialised `fill` / `stroke` paths when they differ (arcs).
pub struct ShapePaths {
  path : Path
  fill : Path?
  stroke : Path?
}

///|
/// The path to fill.
pub fn ShapePaths::fill_path(self : ShapePaths) -> Path {
  self.fill.unwrap_or(self.path)
}

///|
/// The path to stroke.
pub fn ShapePaths::stroke_path(self : ShapePaths) -> Path {
  self.stroke.unwrap_or(self.path)
}
