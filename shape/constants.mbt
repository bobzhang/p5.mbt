///|
/// Kinds of shapes accepted by `begin_shape()` / `begin_contour()`.
#derive(Eq, Debug)
pub(all) enum ShapeKind {
  Path
  Points
  Lines
  Triangles
  Quads
  TriangleFan
  TriangleStrip
  QuadStrip
}

///|
/// How the ends of a spline are treated (`splineProperty('ends', ...)`).
#derive(Eq, Debug)
pub(all) enum SplineEnds {
  /// The curve passes through the first and last vertex (default).
  Include
  /// The first and last vertex are only used as control points.
  Exclude
  /// The spline is closed into a loop.
  Join
}

///|
/// How `arc()` is closed.
#derive(Eq, Debug)
pub(all) enum ArcMode {
  /// Unclosed arc; filled as a chord (default).
  Open
  /// Closed with a straight line between the end points.
  Chord
  /// Closed like a pie slice.
  Pie
}

///|
/// `rectMode()` / `ellipseMode()` / `imageMode()` values.
#derive(Eq, Debug)
pub(all) enum ShapeMode {
  Corner
  Corners
  Center
  Radius
}

///|
/// Whether `end_shape` / `end_contour` closes the path.
#derive(Eq, Debug)
pub(all) enum CloseMode {
  Open
  Close
}
