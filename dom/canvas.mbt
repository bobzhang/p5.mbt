///|
/// Creates a canvas of `w`×`h` CSS pixels with the given pixel density and
/// appends it to the element with id `parent` (or to `<main>`, created on
/// demand, when `parent` is empty). Hidden canvases are not attached.
pub extern "js" fn create_canvas(
  w : Double,
  h : Double,
  density : Double,
  parent : String,
  visible : Bool,
) -> Canvas =
  #|(w, h, d, parent, visible) => {
  #|  const c = document.createElement('canvas');
  #|  c.width = Math.round(w * d); c.height = Math.round(h * d);
  #|  c.style.width = w + 'px'; c.style.height = h + 'px';
  #|  c.classList.add('p5Canvas');
  #|  if (!visible) { c.style.display = 'none'; return c; }
  #|  let host = parent ? document.getElementById(parent) : null;
  #|  if (!host) {
  #|    host = document.getElementsByTagName('main')[0];
  #|    if (!host) { host = document.createElement('main'); document.body.appendChild(host); }
  #|  }
  #|  host.appendChild(c);
  #|  return c;
  #|}

///|
/// Resizes a canvas (contents are cleared).
pub extern "js" fn resize_canvas(
  c : Canvas,
  w : Double,
  h : Double,
  density : Double,
) -> Unit =
  #|(c, w, h, d) => {
  #|  c.width = Math.round(w * d); c.height = Math.round(h * d);
  #|  c.style.width = w + 'px'; c.style.height = h + 'px';
  #|}

///|
/// Removes a canvas from the document.
pub extern "js" fn remove_canvas(c : Canvas) -> Unit = "(c) => c.remove()"

///|
/// The 2D context of a canvas.
pub extern "js" fn get_context(c : Canvas) -> Context2D =
  #|(c) => c.getContext('2d', { willReadFrequently: false })

///|
/// Sets the `id` attribute of a canvas.
pub extern "js" fn set_canvas_id(c : Canvas, id : String) -> Unit = "(c, id) => { c.id = id; }"

///|
/// The canvas as an image source.
pub extern "js" fn canvas_as_image(c : Canvas) -> ImageElement = "(c) => c"

///|
/// Device-pixel width of a canvas.
pub extern "js" fn canvas_width(c : Canvas) -> Int32 = "(c) => c.width"

///|
/// Device-pixel height of a canvas.
pub extern "js" fn canvas_height(c : Canvas) -> Int32 = "(c) => c.height"

///|
/// Sets the CSS cursor of the canvas.
pub extern "js" fn set_cursor(c : Canvas, cursor : String) -> Unit = "(c, s) => { c.style.cursor = s; }"

///|
/// Encodes the canvas as a data URL (e.g. `image/png`).
pub extern "js" fn to_data_url(c : Canvas, mime : String) -> String = "(c, m) => c.toDataURL(m)"

///|
/// Triggers a browser download of `url` named `filename`.
pub extern "js" fn download_url(url : String, filename : String) -> Unit =
  #|(url, name) => {
  #|  const a = document.createElement('a');
  #|  a.href = url; a.download = name; document.body.appendChild(a); a.click(); a.remove();
  #|}

///|
/// Creates a new canvas in place of `old` (which is hidden and kept for
/// text measurement), like p5 replacing the canvas for a WEBGL context.
pub extern "js" fn replace_canvas(
  old : Canvas,
  w : Double,
  h : Double,
  density : Double,
) -> Canvas =
  #|(old, w, h, d) => {
  #|  const c = document.createElement('canvas');
  #|  c.width = w * d; c.height = h * d;
  #|  c.style.width = w + 'px'; c.style.height = h + 'px';
  #|  c.id = old.id; old.id = '';
  #|  c.classList.add('p5Canvas');
  #|  if (old.parentNode) old.parentNode.insertBefore(c, old);
  #|  old.style.display = 'none';
  #|  return c;
  #|}
