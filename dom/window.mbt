///|
/// `performance.now()` in milliseconds.
pub extern "js" fn now() -> Double = "() => performance.now()"

///|
/// `Math.random()`.
pub extern "js" fn math_random() -> Double = "() => Math.random()"

///|
/// Schedules `f(timestamp)` before the next repaint.
pub extern "js" fn request_animation_frame(f : (Double) -> Unit) -> Unit = "(f) => requestAnimationFrame(f)"

///|
/// Calls `f` after `ms` milliseconds.
pub extern "js" fn set_timeout(f : () -> Unit, ms : Double) -> Unit = "(f, ms) => setTimeout(f, ms)"

///|
/// Calls `f` once the document has loaded.
pub extern "js" fn on_ready(f : () -> Unit) -> Unit =
  #|(f) => {
  #|  if (document.readyState === 'loading') window.addEventListener('DOMContentLoaded', () => f());
  #|  else f();
  #|}

///|
pub extern "js" fn window_width() -> Double = "() => window.innerWidth"

///|
pub extern "js" fn window_height() -> Double = "() => window.innerHeight"

///|
pub extern "js" fn display_width() -> Double = "() => screen.width"

///|
pub extern "js" fn display_height() -> Double = "() => screen.height"

///|
pub extern "js" fn device_pixel_ratio() -> Double = "() => window.devicePixelRatio || 1"

///|
pub extern "js" fn document_has_focus() -> Bool = "() => document.hasFocus()"

///|
pub extern "js" fn on_window_resize(f : () -> Unit) -> Unit = "(f) => window.addEventListener('resize', () => f())"

///|
pub extern "js" fn on_focus_change(f : (Bool) -> Unit) -> Unit =
  #|(f) => { window.addEventListener('focus', () => f(true)); window.addEventListener('blur', () => f(false)); }

///|
pub extern "js" fn console_log(s : String) -> Unit = "(s) => console.log(s)"

///|
pub extern "js" fn console_warn(s : String) -> Unit = "(s) => console.warn(s)"

///|
/// `console.error`.
pub extern "js" fn console_error(s : String) -> Unit = "(s) => console.error(s)"

///|
/// Sets `document.title`.
pub extern "js" fn set_title(s : String) -> Unit = "(s) => { document.title = s; }"

///|
/// The current date/time components: year, month (1-12), day, hour, minute,
/// second.
pub extern "js" fn date_part(which : Int32) -> Int32 =
  #|(w) => { const d = new Date();
  #|  return [d.getFullYear(), d.getMonth() + 1, d.getDate(), d.getHours(), d.getMinutes(), d.getSeconds()][w]; }

///|
/// Reads a value from `localStorage` (empty string when missing).
pub extern "js" fn storage_get(key : String) -> String = "(k) => { try { return localStorage.getItem(k) ?? ''; } catch { return ''; } }"

///|
/// Writes a value to `localStorage`.
pub extern "js" fn storage_set(key : String, value : String) -> Unit = "(k, v) => { try { localStorage.setItem(k, v); } catch {} }"

///|
/// Removes a key from `localStorage`.
pub extern "js" fn storage_remove(key : String) -> Unit = "(k) => { try { localStorage.removeItem(k); } catch {} }"

///|
/// Clears `localStorage`.
pub extern "js" fn storage_clear() -> Unit = "() => { try { localStorage.clear(); } catch {} }"

///|
/// Requests or exits fullscreen for the canvas.
pub extern "js" fn set_fullscreen(c : Canvas, on : Bool) -> Unit =
  #|(c, on) => {
  #|  if (on) { (c.requestFullscreen || c.webkitRequestFullscreen)?.call(c); }
  #|  else if (document.fullscreenElement) { document.exitFullscreen(); }
  #|}

///|
pub extern "js" fn is_fullscreen() -> Bool = "() => !!document.fullscreenElement"

///|
/// JavaScript `String(n)`.
pub extern "js" fn number_to_string(n : Double) -> String = "(n) => String(n)"

///|
/// JavaScript `n.toFixed(digits)`.
pub extern "js" fn number_to_fixed(n : Double, digits : Int32) -> String = "(n, d) => n.toFixed(Math.max(0, Math.min(100, d)))"

///|
/// `location.href`.
pub extern "js" fn location_href() -> String = "() => location.href"

///|
/// `location.pathname`.
pub extern "js" fn location_pathname() -> String = "() => location.pathname"

///|
/// `location.search`.
pub extern "js" fn location_search() -> String = "() => location.search"

///|
/// Removes an element from its parent, if it has one.
pub extern "js" fn detach_node(e : Element) -> Unit = "(e) => { if (e && e.parentNode) e.parentNode.removeChild(e); }"
