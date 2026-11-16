///|
/// A pointer/mouse event, with coordinates relative to the canvas in CSS
/// pixels (scaled for canvases displayed at a different size).
pub(all) struct PointerEvent {
  kind : String
  x : Double
  y : Double
  win_x : Double
  win_y : Double
  moved_x : Double
  moved_y : Double
  button : Int32
  buttons : Int32
  pointer_id : Int32
  pointer_type : String
  is_primary : Bool
}

///|
fn make_pointer_event(
  kind : String,
  x : Double,
  y : Double,
  win_x : Double,
  win_y : Double,
  moved_x : Double,
  moved_y : Double,
  button : Int32,
  buttons : Int32,
  pointer_id : Int32,
  pointer_type : String,
  is_primary : Bool,
) -> PointerEvent {
  {
    kind,
    x,
    y,
    win_x,
    win_y,
    moved_x,
    moved_y,
    button,
    buttons,
    pointer_id,
    pointer_type,
    is_primary,
  }
}

///|
extern "js" fn listen_pointer_raw(
  c : Canvas,
  logical_w : () -> Double,
  logical_h : () -> Double,
  mk : (
    String,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Int32,
    Int32,
    Int32,
    String,
    Bool,
  ) -> PointerEvent,
  f : (PointerEvent) -> Bool,
) -> Unit =
  #|(c, lw, lh, mk, f) => {
  #|  const send = (kind, e) => {
  #|    const r = c.getBoundingClientRect();
  #|    const sx = r.width ? lw() / r.width : 1, sy = r.height ? lh() / r.height : 1;
  #|    const ev = mk(kind, (e.clientX - r.left) * sx, (e.clientY - r.top) * sy, e.clientX, e.clientY,
  #|      e.movementX || 0, e.movementY || 0, e.button ?? 0, e.buttons ?? 0,
  #|      e.pointerId ?? 1, e.pointerType || 'mouse', e.isPrimary ?? true);
  #|    if (f(ev) === false && e.cancelable) e.preventDefault();
  #|  };
  #|  c.addEventListener('pointerdown', e => {
  #|    try { c.setPointerCapture(e.pointerId); } catch {}
  #|    send('down', e);
  #|  });
  #|  window.addEventListener('pointermove', e => send('move', e));
  #|  window.addEventListener('pointerup', e => send('up', e));
  #|  window.addEventListener('pointercancel', e => send('cancel', e));
  #|  c.addEventListener('click', e => send('click', e));
  #|  c.addEventListener('dblclick', e => send('dblclick', e));
  #|  c.addEventListener('contextmenu', e => { if (f(mk('contextmenu', 0, 0, 0, 0, 0, 0, 2, 0, 0, 'mouse', true)) === false) e.preventDefault(); });
  #|  c.style.touchAction = 'none';
  #|}

///|
/// Listens to pointer events on the canvas. The handler returns `false` to
/// call `preventDefault()`.
pub fn listen_pointer(
  c : Canvas,
  logical_w : () -> Double,
  logical_h : () -> Double,
  f : (PointerEvent) -> Bool,
) -> Unit {
  listen_pointer_raw(c, logical_w, logical_h, make_pointer_event, f)
}

///|
/// Listens to `wheel` events on the canvas: `f(delta_x, delta_y)`.
pub extern "js" fn listen_wheel(
  c : Canvas,
  f : (Double, Double) -> Bool,
) -> Unit =
  #|(c, f) => c.addEventListener('wheel', e => { if (f(e.deltaX, e.deltaY) === false) e.preventDefault(); }, { passive: false })

///|
/// Listens to keyboard events on the window:
/// `f(kind, key, code, key_code)` where kind is `"down"` or `"up"`.
pub extern "js" fn listen_keys(
  f : (String, String, String, Int32) -> Bool,
) -> Unit =
  #|(f) => {
  #|  window.addEventListener('keydown', e => { if (f('down', e.key, e.code, e.keyCode) === false) e.preventDefault(); });
  #|  window.addEventListener('keyup', e => { if (f('up', e.key, e.code, e.keyCode) === false) e.preventDefault(); });
  #|  window.addEventListener('blur', () => f('blur', '', '', 0));
  #|}
