///|
/// Creates an element with the given tag and inner HTML and appends it to
/// the element with id `parent` (or `document.body`).
pub extern "js" fn create_element(
  tag : String,
  html : String,
  parent : String,
) -> Element =
  #|(tag, html, parent) => {
  #|  const e = document.createElement(tag);
  #|  if (html) e.innerHTML = html;
  #|  const host = (parent && document.getElementById(parent)) || document.body;
  #|  host.appendChild(e);
  #|  return e;
  #|}

///|
/// `document.querySelector(selector)`; returns `false` from `found` when no
/// element matches.
pub extern "js" fn query_selector(selector : String) -> Element = "(s) => document.querySelector(s)"

///|
pub extern "js" fn element_exists(e : Element) -> Bool = "(e) => e != null"

///|
pub extern "js" fn set_attribute(
  e : Element,
  name : String,
  value : String,
) -> Unit = "(e, n, v) => e.setAttribute(n, v)"

///|
pub extern "js" fn get_attribute(e : Element, name : String) -> String = "(e, n) => e.getAttribute(n) ?? ''"

///|
pub extern "js" fn remove_attribute(e : Element, name : String) -> Unit = "(e, n) => e.removeAttribute(n)"

///|
pub extern "js" fn set_style(
  e : Element,
  prop : String,
  value : String,
) -> Unit = "(e, p, v) => e.style.setProperty(p, v)"

///|
pub extern "js" fn get_style(e : Element, prop : String) -> String = "(e, p) => getComputedStyle(e).getPropertyValue(p)"

///|
pub extern "js" fn set_html(e : Element, html : String) -> Unit = "(e, h) => { e.innerHTML = h; }"

///|
pub extern "js" fn get_html(e : Element) -> String = "(e) => e.innerHTML"

///|
pub extern "js" fn get_value(e : Element) -> String = "(e) => String(e.value ?? '')"

///|
pub extern "js" fn set_value(e : Element, v : String) -> Unit = "(e, v) => { e.value = v; }"

///|
pub extern "js" fn get_checked(e : Element) -> Bool = "(e) => !!e.checked"

///|
pub extern "js" fn set_checked(e : Element, v : Bool) -> Unit = "(e, v) => { e.checked = v; }"

///|
pub extern "js" fn add_class(e : Element, c : String) -> Unit = "(e, c) => e.classList.add(c)"

///|
pub extern "js" fn remove_class(e : Element, c : String) -> Unit = "(e, c) => e.classList.remove(c)"

///|
pub extern "js" fn remove_element(e : Element) -> Unit = "(e) => e.remove()"

///|
/// Moves `e` to be the last child of the element with id `parent`.
pub extern "js" fn set_parent(e : Element, parent : String) -> Unit = "(e, p) => { const h = document.getElementById(p); if (h) h.appendChild(e); }"

///|
/// Positions `e` absolutely at `(x, y)` (page coordinates).
pub extern "js" fn set_position(e : Element, x : Double, y : Double) -> Unit = "(e, x, y) => { e.style.position = 'absolute'; e.style.left = x + 'px'; e.style.top = y + 'px'; }"

///|
/// Width of an element in CSS pixels.
pub extern "js" fn element_width(e : Element) -> Double = "(e) => e.getBoundingClientRect().width"

///|
/// Height of an element in CSS pixels.
pub extern "js" fn element_height(e : Element) -> Double = "(e) => e.getBoundingClientRect().height"

///|
/// Sets the handler of `event` (replacing a previous one, like p5's
/// `_attachListener`); `f` receives nothing.
pub extern "js" fn on_event(
  e : Element,
  event : String,
  f : () -> Unit,
) -> Unit =
  #|(e, ev, f) => {
  #|  const m = e.__p5mbtEvents || (e.__p5mbtEvents = {});
  #|  if (m[ev]) e.removeEventListener(ev, m[ev]);
  #|  m[ev] = () => f(); e.addEventListener(ev, m[ev]);
  #|}

///|
/// Sets a `wheel` handler receiving `deltaY`.
pub extern "js" fn on_wheel(e : Element, f : (Double) -> Unit) -> Unit =
  #|(e, f) => {
  #|  const m = e.__p5mbtEvents || (e.__p5mbtEvents = {});
  #|  if (m.wheel) e.removeEventListener('wheel', m.wheel);
  #|  m.wheel = ev => f(ev.deltaY); e.addEventListener('wheel', m.wheel);
  #|}

///|
/// Removes the handler of `event`.
pub extern "js" fn off_event(e : Element, event : String) -> Unit =
  #|(e, ev) => { const m = e.__p5mbtEvents; if (m && m[ev]) { e.removeEventListener(ev, m[ev]); delete m[ev]; } }

///|
/// `container.querySelectorAll(selector)` (`container` empty: document).
pub extern "js" fn query_selector_all(
  selector : String,
  container : String,
) -> FixedArray[Element] = "(s, c) => Array.from(((c && document.querySelector(c)) || document).querySelectorAll(s))"

///|
pub extern "js" fn has_class(e : Element, c : String) -> Bool = "(e, c) => e.classList.contains(c)"

///|
pub extern "js" fn toggle_class(e : Element, c : String) -> Unit = "(e, c) => e.classList.toggle(c)"

///|
pub extern "js" fn get_class(e : Element) -> String = "(e) => e.className"

///|
/// Appends `child` to `e`.
pub extern "js" fn append_child(e : Element, child : Element) -> Unit = "(e, c) => e.appendChild(c)"

///|
/// Centers `e` in its parent (`"both"`, `"horizontal"` or `"vertical"`),
/// following p5's `center()`.
pub extern "js" fn center_element(e : Element, align : String) -> Unit =
  #|(e, align) => {
  #|  const parent = e.parentElement || document.body;
  #|  const style = e.style.display, hidden = style === 'none', parentHidden = parent.style.display === 'none';
  #|  const pos = { x: e.offsetLeft, y: e.offsetTop };
  #|  if (hidden) e.style.display = ''; if (parentHidden) parent.style.display = '';
  #|  e.style.display = 'block';
  #|  const place = (x, y) => { e.style.position = 'absolute'; e.style.left = x + 'px'; e.style.top = y + 'px'; };
  #|  place(0, 0);
  #|  const w = Math.abs(parent.offsetWidth - e.offsetWidth), h = Math.abs(parent.offsetHeight - e.offsetHeight);
  #|  if (align === 'both') place(w / 2 + parent.offsetLeft, h / 2 + parent.offsetTop);
  #|  else if (align === 'horizontal') place(w / 2 + parent.offsetLeft, pos.y);
  #|  else if (align === 'vertical') place(pos.x, h / 2 + parent.offsetTop);
  #|  e.style.display = style; if (hidden) e.style.display = 'none'; if (parentHidden) parent.style.display = 'none';
  #|}

///|
/// Makes `handle` drag `target` around (p5's `draggable()`).
pub extern "js" fn make_draggable(handle : Element, target : Element) -> Unit =
  #|(handle, target) => {
  #|  const isTouch = 'ontouchstart' in window;
  #|  const down = isTouch ? 'touchstart' : 'mousedown', up = isTouch ? 'touchend' : 'mouseup', move = isTouch ? 'touchmove' : 'mousemove';
  #|  let x = 0, y = 0, px = 0, py = 0;
  #|  const point = e => isTouch ? e.changedTouches[0] : e;
  #|  const drag = e => {
  #|    const p = point(e); x = px - parseInt(p.clientX); y = py - parseInt(p.clientY);
  #|    px = parseInt(p.clientX); py = parseInt(p.clientY);
  #|    target.style.left = (target.offsetLeft - x) + 'px'; target.style.top = (target.offsetTop - y) + 'px';
  #|  };
  #|  const close = () => { document.removeEventListener(up, close, false); document.removeEventListener(move, drag, false); };
  #|  handle.addEventListener(down, e => {
  #|    const p = point(e); px = parseInt(p.clientX); py = parseInt(p.clientY);
  #|    document.addEventListener(up, close, false); document.addEventListener(move, drag, false);
  #|    return false;
  #|  }, false);
  #|  handle.style.cursor = 'move';
  #|  if (getComputedStyle(target).position === 'static') target.style.position = 'absolute';
  #|}

///|
/// Adds (or updates) an option of a radio group (p5's `createRadio`
/// `option()`), returning the input.
pub extern "js" fn radio_option(
  group : Element,
  name : String,
  value : String,
  label : String,
) -> Element =
  #|(g, name, value, label) => {
  #|  const opts = () => Array.from(g.children).filter(el => (el instanceof HTMLInputElement && el.type === 'radio') ||
  #|    (el instanceof HTMLLabelElement && el.firstElementChild instanceof HTMLInputElement && el.firstElementChild.type === 'radio'))
  #|    .map(el => el instanceof HTMLInputElement ? el : el.firstElementChild);
  #|  let opt = opts().find(o => o.value === value);
  #|  if (!opt) { opt = document.createElement('input'); opt.setAttribute('type', 'radio'); opt.setAttribute('value', value); }
  #|  opt.setAttribute('name', name);
  #|  let lab = opt.parentElement instanceof HTMLLabelElement ? opt.parentElement : null;
  #|  if (!lab) { lab = document.createElement('label'); lab.insertAdjacentElement('afterbegin', opt); }
  #|  let span = lab.lastElementChild instanceof HTMLSpanElement ? lab.lastElementChild : null;
  #|  if (!span) { span = document.createElement('span'); opt.insertAdjacentElement('afterend', span); }
  #|  span.innerHTML = label; g.appendChild(lab);
  #|  return opt;
  #|}

///|
/// The radio inputs of a group.
pub extern "js" fn radio_options(group : Element) -> FixedArray[Element] =
  #|(g) => Array.from(g.children).filter(el => (el instanceof HTMLInputElement && el.type === 'radio') ||
  #|  (el instanceof HTMLLabelElement && el.firstElementChild instanceof HTMLInputElement && el.firstElementChild.type === 'radio'))
  #|  .map(el => el instanceof HTMLInputElement ? el : el.firstElementChild)

///|
/// Removes the label wrapping a radio input (or the input itself).
pub extern "js" fn remove_radio_option(opt : Element) -> Unit = "(o) => { if (o.parentElement instanceof HTMLLabelElement) o.parentElement.remove(); else o.remove(); }"

///|
/// A picked or dropped file.
#external
pub type File

///|
/// `[type, subtype, name, size]` of a file.
pub extern "js" fn file_info(f : File) -> FixedArray[String] = "(f) => { const t = (f.type || '').split('/'); return [t[0] || '', t[1] || '', f.name, String(f.size)]; }"

///|
/// Reads a file like p5's `File._load`: text and JSON as text, video and
/// audio as blob URLs, anything else as a data URL. `done(data, is_blob)`.
pub extern "js" fn read_file(f : File, done : (String, Bool) -> Unit) -> Unit =
  #|(f, done) => {
  #|  if (/^text\//.test(f.type) || f.type === 'application/json') { const r = new FileReader(); r.onload = e => done(e.target.result, false); r.readAsText(f); }
  #|  else if (!/^(video|audio)\//.test(f.type)) { const r = new FileReader(); r.onload = e => done(e.target.result, false); r.readAsDataURL(f); }
  #|  else done(URL.createObjectURL(f), true);
  #|}

///|
/// Revokes a blob URL.
pub extern "js" fn revoke_url(url : String) -> Unit = "(u) => URL.revokeObjectURL(u)"

///|
/// Calls `f` for each file chosen in a file input.
pub extern "js" fn on_files_chosen(input : Element, f : (File) -> Unit) -> Unit = "(i, f) => i.addEventListener('change', e => { for (const file of e.target.files) f(file); })"

///|
/// Makes `e` accept dropped files: `on_drop` first, then `f` for each file.
pub extern "js" fn on_drop(
  e : Element,
  f : (File) -> Unit,
  on_drop : () -> Unit,
) -> Unit =
  #|(e, f, onDrop) => {
  #|  if (!e.__p5mbtDrop) { e.__p5mbtDrop = true; const pd = ev => ev.preventDefault();
  #|    e.addEventListener('dragover', pd); e.addEventListener('dragleave', pd); }
  #|  const m = e.__p5mbtEvents || (e.__p5mbtEvents = {});
  #|  if (m.drop) e.removeEventListener('drop', m.drop);
  #|  m.drop = ev => { ev.preventDefault(); onDrop(); for (const file of ev.dataTransfer.files) f(file); };
  #|  e.addEventListener('drop', m.drop);
  #|}

///|
/// Appends an `<option>` to a `<select>`.
pub extern "js" fn add_option(
  e : Element,
  label : String,
  value : String,
) -> Unit =
  #|(e, l, v) => { const o = document.createElement('option'); o.textContent = l; o.value = v; e.appendChild(o); }

///|
/// The canvas as an element.
pub extern "js" fn canvas_element(c : Canvas) -> Element = "(c) => c"
