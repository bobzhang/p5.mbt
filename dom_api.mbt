// Port of a subset of p5.js src/dom/{dom,p5.Element}.js: creating and
// controlling HTML elements next to the sketch.

///|
/// An HTML element created by one of the `create_*` functions.
pub struct Element {
  elt : @dom.Element
}

///|
/// The underlying DOM element.
pub fn Element::elt(self : Element) -> @dom.Element {
  self.elt
}

///|
fn P5::make_element(self : P5, tag : String, html : String) -> Element {
  { elt: @dom.create_element(tag, html, self.container), }
}

///|
/// Selects the first element matching a CSS selector.
pub fn select(selector : String) -> Element? {
  let e = @dom.query_selector(selector)
  if @dom.element_exists(e) {
    Some({ elt: e, })
  } else {
    None
  }
}

///|
/// Creates a `<div>`.
pub fn P5::create_div(self : P5, html~ : String = "") -> Element {
  self.make_element("div", html)
}

///|
/// Creates a `<p>` paragraph.
pub fn P5::create_p(self : P5, html~ : String = "") -> Element {
  self.make_element("p", html)
}

///|
/// Creates a `<span>`.
pub fn P5::create_span(self : P5, html~ : String = "") -> Element {
  self.make_element("span", html)
}

///|
/// Creates a link.
pub fn P5::create_a(
  self : P5,
  href : String,
  html : String,
  target? : String,
) -> Element {
  let e = self.make_element("a", html)
  @dom.set_attribute(e.elt, "href", href)
  if target is Some(t) {
    @dom.set_attribute(e.elt, "target", t)
  }
  e
}

///|
/// Creates an `<img>` element.
pub fn P5::create_img(self : P5, src : String, alt~ : String = "") -> Element {
  let e = self.make_element("img", "")
  @dom.set_attribute(e.elt, "src", src)
  @dom.set_attribute(e.elt, "alt", alt)
  e
}

///|
/// Creates a button.
pub fn P5::create_button(self : P5, label : String) -> Element {
  self.make_element("button", label)
}

///|
/// Creates a range slider.
pub fn P5::create_slider(
  self : P5,
  min : Double,
  max : Double,
  value? : Double,
  step? : Double,
) -> Element {
  let e = self.make_element("input", "")
  @dom.set_attribute(e.elt, "type", "range")
  @dom.set_attribute(e.elt, "min", @dom.number_to_string(min))
  @dom.set_attribute(e.elt, "max", @dom.number_to_string(max))
  @dom.set_attribute(
    e.elt,
    "step",
    match step {
      Some(0.0) => "any"
      Some(s) => @dom.number_to_string(s)
      None => "any"
    },
  )
  @dom.set_value(e.elt, @dom.number_to_string(value.unwrap_or(min)))
  e
}

///|
/// Creates a checkbox with a label.
pub fn P5::create_checkbox(
  self : P5,
  label~ : String = "",
  checked~ : Bool = false,
) -> Element {
  let wrapper = self.make_element("label", "")
  let input = @dom.create_element("input", "", "")
  @dom.set_attribute(input, "type", "checkbox")
  @dom.set_checked(input, checked)
  @dom.remove_element(input)
  set_inner_checkbox(wrapper.elt, input, label)
  { elt: input, }
}

///|
extern "js" fn set_inner_checkbox(
  wrapper : @dom.Element,
  input : @dom.Element,
  label : String,
) -> Unit = "(w, i, l) => { w.appendChild(i); if (l) w.appendChild(document.createTextNode(' ' + l)); }"

///|
/// Creates a drop-down menu; add entries with `option`.
pub fn P5::create_select(self : P5) -> Element {
  self.make_element("select", "")
}

///|
/// Creates a text input (or any `<input>` type such as `"number"`,
/// `"password"`).
pub fn P5::create_input(
  self : P5,
  value~ : String = "",
  kind~ : String = "text",
) -> Element {
  let e = self.make_element("input", "")
  @dom.set_attribute(e.elt, "type", kind)
  @dom.set_value(e.elt, value)
  e
}

///|
/// Creates a color picker.
pub fn P5::create_color_picker(
  self : P5,
  value~ : String = "#000000",
) -> Element {
  let e = self.make_element("input", "")
  @dom.set_attribute(e.elt, "type", "color")
  @dom.set_value(e.elt, value)
  e
}

///|
/// Adds an option to a select element.
pub fn Element::option(self : Element, label : String, value? : String) -> Unit {
  @dom.add_option(self.elt, label, value.unwrap_or(label))
}

///|
/// Selects an option of a select element (or sets an input's value).
pub fn Element::selected(self : Element, value : String) -> Unit {
  @dom.set_value(self.elt, value)
}

///|
/// The value of an input, slider, select or color picker, as a string.
pub fn Element::value(self : Element) -> String {
  @dom.get_value(self.elt)
}

///|
/// The value parsed as a number (0 when it isn't one).
pub fn Element::value_number(self : Element) -> Double {
  @string.parse_double(@dom.get_value(self.elt)) catch {
    _ => 0
  }
}

///|
/// Sets the value of an input element.
pub fn Element::set_value(self : Element, v : String) -> Unit {
  @dom.set_value(self.elt, v)
}

///|
/// Whether a checkbox is checked.
pub fn Element::checked(self : Element) -> Bool {
  @dom.get_checked(self.elt)
}

///|
/// Checks or unchecks a checkbox.
pub fn Element::set_checked(self : Element, v : Bool) -> Unit {
  @dom.set_checked(self.elt, v)
}

///|
/// The color of a color picker.
pub fn Element::color(self : Element) -> Color {
  Color::parse(@dom.get_value(self.elt)).unwrap_or(Color::rgb(0, 0, 0))
}

///|
/// Sets the inner HTML.
pub fn Element::html(self : Element, html : String) -> Unit {
  @dom.set_html(self.elt, html)
}

///|
/// Positions the element absolutely at `(x, y)` on the page.
pub fn Element::position(self : Element, x : Double, y : Double) -> Unit {
  @dom.set_position(self.elt, x, y)
}

///|
/// Sets the element's CSS size in pixels.
pub fn Element::size(self : Element, w : Double, h : Double) -> Unit {
  @dom.set_style(self.elt, "width", "\{@dom.number_to_string(w)}px")
  @dom.set_style(self.elt, "height", "\{@dom.number_to_string(h)}px")
}

///|
/// Sets a CSS property.
pub fn Element::style(self : Element, prop : String, value : String) -> Unit {
  @dom.set_style(self.elt, prop, value)
}

///|
/// Sets an attribute.
pub fn Element::attribute(
  self : Element,
  name : String,
  value : String,
) -> Unit {
  @dom.set_attribute(self.elt, name, value)
}

///|
/// Adds a CSS class.
pub fn Element::add_class(self : Element, c : String) -> Unit {
  @dom.add_class(self.elt, c)
}

///|
/// Removes a CSS class.
pub fn Element::remove_class(self : Element, c : String) -> Unit {
  @dom.remove_class(self.elt, c)
}

///|
/// Sets the element's id.
pub fn Element::id(self : Element, id : String) -> Unit {
  @dom.set_attribute(self.elt, "id", id)
}

///|
/// Moves the element inside the element with the given id.
pub fn Element::parent(self : Element, id : String) -> Unit {
  @dom.set_parent(self.elt, id)
}

///|
/// Shows the element.
pub fn Element::show(self : Element) -> Unit {
  @dom.set_style(self.elt, "display", "")
}

///|
/// Hides the element.
pub fn Element::hide(self : Element) -> Unit {
  @dom.set_style(self.elt, "display", "none")
}

///|
/// Removes the element from the page.
pub fn Element::remove(self : Element) -> Unit {
  @dom.remove_element(self.elt)
}

///|
/// Disables the element.
pub fn Element::disable(self : Element) -> Unit {
  @dom.set_attribute(self.elt, "disabled", "")
}

///|
/// Enables the element.
pub fn Element::enable(self : Element) -> Unit {
  @dom.remove_attribute(self.elt, "disabled")
}

///|
/// Calls `f` when the element is clicked.
pub fn Element::mouse_pressed(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "click", f)
}

///|
/// Calls `f` when the element's value is committed (`change` event).
pub fn Element::changed(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "change", f)
}

///|
/// Calls `f` whenever the element's value changes (`input` event).
pub fn Element::input(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "input", f)
}

///|
/// Calls `f` for any DOM event name (e.g. `"mouseover"`).
pub fn Element::on(self : Element, event : String, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, event, f)
}
