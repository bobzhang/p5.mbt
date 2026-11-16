///|
pub extern "js" fn save(ctx : Context2D) -> Unit = "(c) => c.save()"

///|
pub extern "js" fn restore(ctx : Context2D) -> Unit = "(c) => c.restore()"

///|
pub extern "js" fn set_transform(
  ctx : Context2D,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> Unit = "(x, a, b, c, d, e, f) => x.setTransform(a, b, c, d, e, f)"

///|
/// Fills `path` with a CSS color.
pub extern "js" fn fill_path(
  ctx : Context2D,
  path : Path2D,
  style : String,
) -> Unit = "(c, p, s) => { c.fillStyle = s; c.fill(p); }"

///|
/// Strokes `path` with a CSS color and line style.
pub extern "js" fn stroke_path(
  ctx : Context2D,
  path : Path2D,
  style : String,
  width : Double,
  cap : String,
  join : String,
) -> Unit =
  #|(c, p, s, w, cap, join) => {
  #|  c.strokeStyle = s; c.lineWidth = w === 0 ? 0.0001 : w;
  #|  c.lineCap = cap; c.lineJoin = join; c.stroke(p);
  #|}

///|
/// Intersects the clipping region with `path`.
pub extern "js" fn clip_path(ctx : Context2D, path : Path2D) -> Unit = "(c, p) => c.clip(p)"

///|
pub extern "js" fn fill_rect(
  ctx : Context2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  style : String,
) -> Unit = "(c, x, y, w, h, s) => { c.fillStyle = s; c.fillRect(x, y, w, h); }"

///|
pub extern "js" fn clear_rect(
  ctx : Context2D,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit = "(c, x, y, w, h) => c.clearRect(x, y, w, h)"

///|
/// Sets `globalCompositeOperation`.
pub extern "js" fn set_composite(ctx : Context2D, op : String) -> Unit = "(c, op) => { c.globalCompositeOperation = op; }"

///|
/// Sets `globalAlpha`.
pub extern "js" fn set_global_alpha(ctx : Context2D, a : Double) -> Unit = "(c, a) => { c.globalAlpha = a; }"

///|
/// Sets `imageSmoothingEnabled`.
pub extern "js" fn set_image_smoothing(ctx : Context2D, on : Bool) -> Unit = "(c, on) => { c.imageSmoothingEnabled = on; }"

///|
/// Sets the canvas `filter` (CSS filter syntax, `"none"` to clear).
pub extern "js" fn set_filter(ctx : Context2D, f : String) -> Unit = "(c, f) => { c.filter = f; }"

///|
/// Applies a shadow (`blur = 0` and transparent color to disable).
pub extern "js" fn set_shadow(
  ctx : Context2D,
  blur : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> Unit = "(c, b, x, y, col) => { c.shadowBlur = b; c.shadowOffsetX = x; c.shadowOffsetY = y; c.shadowColor = col; }"

///|
/// Sets a dash pattern (an empty array for solid lines).
pub extern "js" fn set_line_dash(
  ctx : Context2D,
  segments : FixedArray[Double],
) -> Unit = "(c, s) => c.setLineDash(s)"
