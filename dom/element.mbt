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
/// Adds an event listener; `f` receives nothing.
pub extern "js" fn on_event(
  e : Element,
  event : String,
  f : () -> Unit,
) -> Unit = "(e, ev, f) => e.addEventListener(ev, () => f())"

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
