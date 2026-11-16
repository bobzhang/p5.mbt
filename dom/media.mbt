///|
/// Creates a `<video>` or `<audio>` element with `<source>` children,
/// appended to `parent` (or the body). `meta(w, h)` runs on
/// `loadedmetadata`; `ready()` runs once on `canplaythrough`.
pub extern "js" fn create_media(
  kind : String,
  sources : FixedArray[String],
  parent : String,
  meta : (Int32, Int32) -> Unit,
  ready : () -> Unit,
) -> Element =
  #|(kind, sources, parent, meta, ready) => {
  #|  const e = document.createElement(kind); e.crossOrigin = 'anonymous';
  #|  for (const s of sources) { const src = document.createElement('source'); src.setAttribute('src', s); e.appendChild(src); }
  #|  ((parent && document.getElementById(parent)) || document.body).appendChild(e);
  #|  e.addEventListener('loadedmetadata', () => {
  #|    if (e.width === 0 && kind === 'video') e.width = e.videoWidth;
  #|    if (e.height === 0 && kind === 'video') e.height = e.videoHeight;
  #|    meta(e.videoWidth || 0, e.videoHeight || 0);
  #|  });
  #|  const h = () => { ready(); e.removeEventListener('canplaythrough', h); };
  #|  e.addEventListener('canplaythrough', h);
  #|  return e;
  #|}

///|
/// Creates a camera/microphone capture `<video>` (p5's `createCapture`).
pub extern "js" fn create_capture(
  video : Bool,
  audio : Bool,
  flipped : Bool,
  parent : String,
  meta : (Int32, Int32) -> Unit,
  failed : (String) -> Unit,
) -> Element =
  #|(video, audio, flipped, parent, meta, failed) => {
  #|  const e = document.createElement('video'); e.setAttribute('playsinline', '');
  #|  ((parent && document.getElementById(parent)) || document.body).appendChild(e);
  #|  if (!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia)) { failed('getUserMedia not supported in this browser'); return e; }
  #|  navigator.mediaDevices.getUserMedia({ video, audio }).then(stream => { e.srcObject = stream; })
  #|    .catch(err => failed(err.name === 'NotFoundError' ? 'No webcam found on this device'
  #|      : err.name === 'NotAllowedError' ? 'Access to the camera was denied' : String(err)));
  #|  e.addEventListener('loadedmetadata', () => {
  #|    e.play();
  #|    if (!e.width) { e.width = e.videoWidth; e.height = e.videoHeight; }
  #|    if (flipped) e.style.transform = 'scaleX(-1)';
  #|    meta(e.width, e.height);
  #|  });
  #|  return e;
  #|}

///|
/// `play()`, restarting from 0 at the end and loading first if needed.
pub extern "js" fn media_play(e : Element) -> Unit =
  #|(e) => {
  #|  if (e.currentTime === e.duration) e.currentTime = 0;
  #|  if (e.readyState <= 1) e.load();
  #|  const p = e.play();
  #|  if (p && p.catch) p.catch(err => console.warn('🌸 p5.mbt says: media could not play (' + err.name + '), probably because of the autoplay policy.'));
  #|}

///|
pub extern "js" fn media_pause(e : Element) -> Unit = "(e) => e.pause()"

///|
pub extern "js" fn media_stop(e : Element) -> Unit = "(e) => { e.pause(); e.currentTime = 0; }"

///|
pub extern "js" fn media_set_loop(e : Element, on : Bool) -> Unit = "(e, on) => { if (on) e.setAttribute('loop', true); else e.removeAttribute('loop'); }"

///|
pub extern "js" fn media_set_autoplay(e : Element, on : Bool) -> Unit = "(e, on) => { if (on) { e.setAttribute('autoplay', true); e.autoplay = true; } else { e.removeAttribute('autoplay'); e.autoplay = false; } }"

///|
pub extern "js" fn media_get_number(e : Element, prop : String) -> Double = "(e, p) => Number(e[p])"

///|
pub extern "js" fn media_set_number(
  e : Element,
  prop : String,
  v : Double,
) -> Unit = "(e, p, v) => { e[p] = v; }"

///|
pub extern "js" fn media_set_controls(e : Element, on : Bool) -> Unit = "(e, on) => { e.controls = on; }"

///|
/// Sets the `ended` handler.
pub extern "js" fn media_on_ended(e : Element, f : () -> Unit) -> Unit = "(e, f) => { e.onended = () => f(); }"

///|
/// Calls `f(currentTime)` on every `timeupdate`.
pub extern "js" fn media_on_time_update(
  e : Element,
  f : (Double) -> Unit,
) -> Unit = "(e, f) => e.addEventListener('timeupdate', () => f(e.currentTime))"

///|
/// Draws the current frame of a video into `c` (resizing it to the
/// element's size), mirrored when `flipped`, like p5's `_ensureCanvas`.
pub extern "js" fn media_to_canvas(
  e : Element,
  c : Canvas,
  flipped : Bool,
) -> Unit =
  #|(e, c, flipped) => {
  #|  const w = e.width || e.videoWidth || 1, h = e.height || e.videoHeight || 1;
  #|  if (c.width !== w || c.height !== h) { c.width = w; c.height = h; }
  #|  const x = c.getContext('2d'); x.clearRect(0, 0, w, h);
  #|  if (flipped) { x.save(); x.scale(-1, 1); x.translate(-w, 0); }
  #|  try { x.drawImage(e, 0, 0, w, h); } catch {}
  #|  if (flipped) x.restore();
  #|}

///|
/// The element as an image source.
pub extern "js" fn element_as_image(e : Element) -> ImageElement = "(e) => e"

///|
/// The `width`/`height` attributes of an element.
pub extern "js" fn element_attr_size(e : Element) -> FixedArray[Double] = "(e) => [e.width || 0, e.height || 0]"

///|
/// Sets the `width`/`height` of an element (attributes and CSS).
pub extern "js" fn set_element_size(
  e : Element,
  w : Double,
  h : Double,
) -> Unit = "(e, w, h) => { e.style.width = w + 'px'; e.style.height = h + 'px'; e.width = w; e.height = h; }"
