///|
/// Sets the CSS font, alignment and baseline used for text.
pub extern "js" fn set_text_style(
  ctx : Context2D,
  font : String,
  align : String,
  baseline : String,
) -> Unit = "(c, f, a, b) => { c.font = f; c.textAlign = a; c.textBaseline = b; }"

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
/// Advance width of `text` with the current font.
pub extern "js" fn measure_width(ctx : Context2D, text : String) -> Double = "(c, t) => c.measureText(t).width"

///|
/// Tight width (`actualBoundingBoxLeft + actualBoundingBoxRight`).
pub extern "js" fn measure_tight_width(
  ctx : Context2D,
  text : String,
) -> Double =
  #|(c, t) => { const m = c.measureText(t); return m.actualBoundingBoxLeft + m.actualBoundingBoxRight; }

///|
/// Font ascent (`fontBoundingBoxAscent`) for the current font.
pub extern "js" fn measure_ascent(ctx : Context2D) -> Double =
  #|(c) => { const b = c.textBaseline; c.textBaseline = 'alphabetic';
  #|  const m = c.measureText('X'); c.textBaseline = b; return m.fontBoundingBoxAscent ?? m.actualBoundingBoxAscent; }

///|
/// Font descent (`fontBoundingBoxDescent`) for the current font.
pub extern "js" fn measure_descent(ctx : Context2D) -> Double =
  #|(c) => { const b = c.textBaseline; c.textBaseline = 'alphabetic';
  #|  const m = c.measureText('X'); c.textBaseline = b; return m.fontBoundingBoxDescent ?? m.actualBoundingBoxDescent; }

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
