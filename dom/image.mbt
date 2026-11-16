///|
/// Loads an image; calls `done(img, width, height)` or `failed(message)`.
pub extern "js" fn load_image(
  url : String,
  done : (ImageElement, Int32, Int32) -> Unit,
  failed : (String) -> Unit,
) -> Unit =
  #|(url, done, failed) => {
  #|  const img = new Image(); img.crossOrigin = 'anonymous';
  #|  img.onload = () => done(img, img.naturalWidth, img.naturalHeight);
  #|  img.onerror = () => failed('Could not load image: ' + url);
  #|  img.src = url;
  #|}

///|
pub extern "js" fn draw_image(
  ctx : Context2D,
  img : ImageElement,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit = "(c, i, sx, sy, sw, sh, dx, dy, dw, dh) => c.drawImage(i, sx, sy, sw, sh, dx, dy, dw, dh)"

///|
/// Draws `img` tinted by an RGBA color (components 0-255), using a scratch
/// canvas (same approach as p5's `_getTintedImageCanvas`).
pub extern "js" fn draw_tinted_image(
  ctx : Context2D,
  img : ImageElement,
  iw : Int32,
  ih : Int32,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit =
  #|(ctx, img, iw, ih, r, g, b, a, sx, sy, sw, sh, dx, dy, dw, dh) => {
  #|  const t = globalThis.__p5mbtTint || (globalThis.__p5mbtTint = document.createElement('canvas'));
  #|  if (t.width !== iw) t.width = iw; if (t.height !== ih) t.height = ih;
  #|  const tc = t.getContext('2d');
  #|  tc.save(); tc.clearRect(0, 0, iw, ih);
  #|  if (r < 255 || g < 255 || b < 255) {
  #|    tc.drawImage(img, 0, 0);
  #|    tc.globalCompositeOperation = 'luminosity'; tc.drawImage(img, 0, 0);
  #|    tc.globalCompositeOperation = 'color'; tc.drawImage(img, 0, 0);
  #|    tc.globalCompositeOperation = 'multiply';
  #|    tc.fillStyle = `rgb(${r}, ${g}, ${b})`; tc.fillRect(0, 0, iw, ih);
  #|    tc.globalCompositeOperation = 'destination-in'; tc.globalAlpha = a / 255; tc.drawImage(img, 0, 0);
  #|  } else { tc.globalAlpha = a / 255; tc.drawImage(img, 0, 0); }
  #|  tc.restore();
  #|  ctx.drawImage(t, sx, sy, sw, sh, dx, dy, dw, dh);
  #|}

///|
pub extern "js" fn get_image_data(
  ctx : Context2D,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> ImageData = "(c, x, y, w, h) => c.getImageData(x, y, w, h)"

///|
pub extern "js" fn put_image_data(
  ctx : Context2D,
  data : ImageData,
  x : Int32,
  y : Int32,
) -> Unit = "(c, d, x, y) => c.putImageData(d, x, y)"

///|
/// Number of bytes in the image data.
pub extern "js" fn image_data_length(d : ImageData) -> Int32 = "(d) => d.data.length"

///|
pub extern "js" fn image_data_get(d : ImageData, i : Int32) -> Int32 = "(d, i) => d.data[i]"

///|
pub extern "js" fn image_data_set(d : ImageData, i : Int32, v : Int32) -> Unit = "(d, i, v) => { d.data[i] = v; }"

///|
/// Copies a MoonBit byte array into image data.
pub extern "js" fn image_data_copy_from(
  d : ImageData,
  src : FixedArray[Byte],
) -> Unit = "(d, s) => { d.data.set(s); }"

///|
/// Copies image data into a MoonBit byte array.
pub extern "js" fn image_data_copy_to(
  d : ImageData,
  dst : FixedArray[Byte],
) -> Unit = "(d, s) => { s.set(d.data); }"

///|
/// Draws an image source into a canvas at `(0, 0)` with the given size
/// (identity transform), replacing its contents.
pub extern "js" fn blit(
  dst : Canvas,
  src : ImageElement,
  w : Double,
  h : Double,
) -> Unit =
  #|(dst, src, w, h) => {
  #|  const c = dst.getContext('2d'); c.save(); c.setTransform(1, 0, 0, 1, 0, 0);
  #|  c.clearRect(0, 0, dst.width, dst.height); c.drawImage(src, 0, 0, w, h); c.restore();
  #|}

///|
/// Copies a region of `src` into `dst` (both in device pixels).
pub extern "js" fn copy_region(
  dst : Canvas,
  src : ImageElement,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit =
  #|(dst, src, sx, sy, sw, sh, dx, dy, dw, dh) => {
  #|  const c = dst.getContext('2d'); c.save(); c.setTransform(1, 0, 0, 1, 0, 0);
  #|  c.drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh); c.restore();
  #|}

///|
/// Masks `dst` with the alpha channel of `mask` (scaled to fit).
pub extern "js" fn apply_mask(dst : Canvas, mask : ImageElement) -> Unit =
  #|(dst, mask) => {
  #|  const c = dst.getContext('2d'); c.save(); c.setTransform(1, 0, 0, 1, 0, 0);
  #|  c.globalCompositeOperation = 'destination-in'; c.drawImage(mask, 0, 0, dst.width, dst.height); c.restore();
  #|}

///|
/// An image source as a PNG data URL (drawn through a scratch canvas).
pub extern "js" fn image_to_data_url(
  img : ImageElement,
  w : Int32,
  h : Int32,
) -> String =
  #|(img, w, h) => {
  #|  if (img instanceof HTMLImageElement && img.src && img.src.startsWith('data:')) return img.src;
  #|  const c = document.createElement('canvas'); c.width = Math.max(1, w); c.height = Math.max(1, h);
  #|  try { c.getContext('2d').drawImage(img, 0, 0, w, h); } catch {}
  #|  return c.toDataURL('image/png');
  #|}
