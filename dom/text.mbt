///|
/// Sets the CSS font, alignment and baseline used for text.
pub extern "js" fn set_text_style(
  ctx : Context2D,
  font : String,
  align : String,
  baseline : String,
  direction : String,
) -> Unit = "(c, f, a, b, d) => { c.font = f; c.textAlign = a; c.textBaseline = b; c.direction = d; }"

///|
pub extern "js" fn fill_text(
  ctx : Context2D,
  text : String,
  x : Double,
  y : Double,
  style : String,
) -> Unit = "(c, t, x, y, s) => { c.fillStyle = s; c.fillText(t, x, y); }"

///|
pub extern "js" fn stroke_text(
  ctx : Context2D,
  text : String,
  x : Double,
  y : Double,
  style : String,
  width : Double,
  join : String,
) -> Unit = "(c, t, x, y, s, w, j) => { c.strokeStyle = s; c.lineWidth = w; c.lineJoin = j; c.strokeText(t, x, y); }"

///|
/// `measureText(text)` as `[width, actualBoundingBoxLeft,
/// actualBoundingBoxRight, actualBoundingBoxAscent, actualBoundingBoxDescent,
/// fontBoundingBoxAscent, fontBoundingBoxDescent, alphabeticBaseline]`.
pub extern "js" fn measure_text(
  ctx : Context2D,
  text : String,
) -> FixedArray[Double] =
  #|(c, t) => { const m = c.measureText(t);
  #|  return [m.width, m.actualBoundingBoxLeft, m.actualBoundingBoxRight, m.actualBoundingBoxAscent,
  #|    m.actualBoundingBoxDescent, m.fontBoundingBoxAscent ?? m.actualBoundingBoxAscent,
  #|    m.fontBoundingBoxDescent ?? m.actualBoundingBoxDescent, m.alphabeticBaseline ?? 0]; }

///|
/// Loads a font file with the `FontFace` API and calls `done(family)` once it
/// is ready (or `failed(message)`).
pub extern "js" fn load_font(
  url : String,
  family : String,
  done : (String) -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(url, family, done, failed) => {
  #|  const f = new FontFace(family, `url(${JSON.stringify(url)})`);
  #|  f.load().then(ff => { document.fonts.add(ff); done(family); }, e => failed(String(e)));
  #|}
