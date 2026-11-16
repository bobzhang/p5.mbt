///|
pub extern "js" fn path_new() -> Path2D = "() => new Path2D()"

///|
pub extern "js" fn path_move_to(p : Path2D, x : Double, y : Double) -> Unit = "(p, x, y) => p.moveTo(x, y)"

///|
pub extern "js" fn path_line_to(p : Path2D, x : Double, y : Double) -> Unit = "(p, x, y) => p.lineTo(x, y)"

///|
pub extern "js" fn path_quadratic_curve_to(
  p : Path2D,
  cx : Double,
  cy : Double,
  x : Double,
  y : Double,
) -> Unit = "(p, a, b, c, d) => p.quadraticCurveTo(a, b, c, d)"

///|
pub extern "js" fn path_bezier_curve_to(
  p : Path2D,
  c1x : Double,
  c1y : Double,
  c2x : Double,
  c2y : Double,
  x : Double,
  y : Double,
) -> Unit = "(p, a, b, c, d, e, f) => p.bezierCurveTo(a, b, c, d, e, f)"

///|
pub extern "js" fn path_ellipse(
  p : Path2D,
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  rotation : Double,
  start : Double,
  end : Double,
) -> Unit = "(p, x, y, rx, ry, r, s, e) => p.ellipse(x, y, Math.abs(rx), Math.abs(ry), r, s, e)"

///|
pub extern "js" fn path_rect(
  p : Path2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit = "(p, x, y, w, h) => p.rect(x, y, w, h)"

///|
pub extern "js" fn path_round_rect(
  p : Path2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  tl : Double,
  tr : Double,
  br : Double,
  bl : Double,
) -> Unit =
  #|(p, x, y, w, h, tl, tr, br, bl) => {
  #|  if (p.roundRect) { p.roundRect(x, y, w, h, [tl, tr, br, bl]); return; }
  #|  p.moveTo(x + tl, y); p.arcTo(x + w, y, x + w, y + h, tr); p.arcTo(x + w, y + h, x, y + h, br);
  #|  p.arcTo(x, y + h, x, y, bl); p.arcTo(x, y, x + w, y, tl); p.closePath();
  #|}

///|
pub extern "js" fn path_close(p : Path2D) -> Unit = "(p) => p.closePath()"
