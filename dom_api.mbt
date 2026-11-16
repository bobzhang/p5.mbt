// Port of a subset of p5.js src/dom/{dom,p5.Element}.js: creating and
// controlling HTML elements next to the sketch.

///|
/// An HTML element created by one of the `create_*` functions.
pub struct Element {
  elt : @dom.Element
  priv radio_name : String?
}

///|
/// The underlying DOM element.
pub fn Element::elt(self : Element) -> @dom.Element {
  self.elt
}

///|
fn P5::make_element(self : P5, tag : String, html : String) -> Element {
  let e = wrap(@dom.create_element(tag, html, self.container))
  self.elements.push(e)
  e
}

///|
fn wrap(elt : @dom.Element) -> Element {
  { elt, radio_name: None, }
}

///|
/// Selects the first element matching a CSS selector.
pub fn select(selector : String) -> Element? {
  let e = @dom.query_selector(selector)
  if @dom.element_exists(e) {
    Some(wrap(e))
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
  wrap(input)
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
  match self.radio_name {
    // for radio groups the first argument is the value, as in p5
    Some(name) =>
      ignore(@dom.radio_option(self.elt, name, label, value.unwrap_or(label)))
    None => @dom.add_option(self.elt, label, value.unwrap_or(label))
  }
}

///|
/// Selects an option of a select element (or sets an input's value).
pub fn Element::selected(self : Element, value : String) -> Unit {
  if self.radio_name is Some(_) {
    for opt in @dom.radio_options(self.elt) {
      @dom.set_checked(opt, false)
      @dom.remove_attribute(opt, "checked")
    }
    for opt in @dom.radio_options(self.elt) {
      if @dom.get_value(opt) == value {
        @dom.set_attribute(opt, "checked", "true")
        @dom.set_checked(opt, true)
      }
    }
  } else {
    @dom.set_value(self.elt, value)
  }
}

///|
/// The value of an input, slider, select or color picker, as a string.
pub fn Element::value(self : Element) -> String {
  if self.radio_name is Some(_) {
    for opt in @dom.radio_options(self.elt) {
      if @dom.get_checked(opt) {
        return @dom.get_value(opt)
      }
    }
    return ""
  }
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
/// Removes the option with `value` from a radio group.
pub fn Element::remove_option(self : Element, value : String) -> Unit {
  for opt in @dom.radio_options(self.elt) {
    if @dom.get_value(opt) == value {
      @dom.remove_radio_option(opt)
      return
    }
  }
}

///|
/// Disables the element.
pub fn Element::disable(self : Element) -> Unit {
  if self.radio_name is Some(_) {
    for opt in @dom.radio_options(self.elt) {
      @dom.set_attribute(opt, "disabled", "true")
    }
  } else {
    @dom.set_attribute(self.elt, "disabled", "")
  }
}

///|
/// Enables the element.
pub fn Element::enable(self : Element) -> Unit {
  @dom.remove_attribute(self.elt, "disabled")
}

///|
/// Calls `f` when the element is clicked.
pub fn Element::mouse_pressed(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "pointerdown", f)
}

///|
/// Calls `f` when a button is released over the element.
pub fn Element::mouse_released(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "pointerup", f)
}

///|
/// Calls `f` when the element is clicked.
pub fn Element::mouse_clicked(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "click", f)
}

///|
/// Calls `f` when the element is double-clicked.
pub fn Element::double_clicked(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "dblclick", f)
}

///|
/// Calls `f` when the pointer moves over the element.
pub fn Element::mouse_moved(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "pointermove", f)
}

///|
/// Calls `f` when the pointer enters the element.
pub fn Element::mouse_over(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "pointerover", f)
}

///|
/// Calls `f` when the pointer leaves the element.
pub fn Element::mouse_out(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "pointerout", f)
}

///|
/// Calls `f(delta_y)` when the wheel turns over the element.
pub fn Element::mouse_wheel(self : Element, f : (Double) -> Unit) -> Unit {
  @dom.on_wheel(self.elt, f)
}

///|
/// Calls `f` when something is dragged over the element.
pub fn Element::drag_over(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "dragover", f)
}

///|
/// Calls `f` when something dragged over the element leaves it.
pub fn Element::drag_leave(self : Element, f : () -> Unit) -> Unit {
  @dom.on_event(self.elt, "dragleave", f)
}

///|
/// Stops calling the handler of a DOM event (e.g. `"pointerdown"`).
pub fn Element::off(self : Element, event : String) -> Unit {
  @dom.off_event(self.elt, event)
}

///|
/// Accepts files dropped on the element: `on_file` is called for each one
/// (after `on_drop`, if given), like p5's `drop()`.
pub fn Element::drop(
  self : Element,
  on_file : (File) -> Unit,
  on_drop? : () -> Unit,
) -> Unit {
  @dom.on_drop(
    self.elt,
    f => File::load(f, on_file),
    on_drop.unwrap_or(() => ()),
  )
}

///|
/// Lets the user drag the element around (or drag `target` by this
/// element).
pub fn Element::draggable(self : Element, target? : Element) -> Unit {
  @dom.make_draggable(self.elt, target.map(t => t.elt).unwrap_or(self.elt))
}

///|
/// Centers the element in its parent: `"both"` (default), `"horizontal"`
/// or `"vertical"`.
pub fn Element::center(self : Element, align~ : String = "both") -> Unit {
  @dom.center_element(self.elt, align)
}

///|
/// Sets the `class` attribute.
pub fn Element::class_name(self : Element, c : String) -> Unit {
  @dom.set_attribute(self.elt, "class", c)
}

///|
/// The `class` attribute.
pub fn Element::get_class(self : Element) -> String {
  @dom.get_class(self.elt)
}

///|
/// Whether the element has a CSS class.
pub fn Element::has_class(self : Element, c : String) -> Bool {
  @dom.has_class(self.elt, c)
}

///|
/// Adds or removes a CSS class.
pub fn Element::toggle_class(self : Element, c : String) -> Unit {
  @dom.toggle_class(self.elt, c)
}

///|
/// Appends `child` inside this element.
pub fn Element::child(self : Element, child : Element) -> Unit {
  @dom.append_child(self.elt, child.elt)
}

///|
/// The inner HTML.
pub fn Element::get_html(self : Element) -> String {
  @dom.get_html(self.elt)
}

///|
/// Appends to the inner HTML.
pub fn Element::append_html(self : Element, html : String) -> Unit {
  @dom.set_html(self.elt, @dom.get_html(self.elt) + html)
}

///|
/// Reads an attribute.
pub fn Element::get_attribute(self : Element, name : String) -> String {
  @dom.get_attribute(self.elt, name)
}

///|
/// Removes an attribute.
pub fn Element::remove_attribute(self : Element, name : String) -> Unit {
  @dom.remove_attribute(self.elt, name)
}

///|
/// Reads a computed CSS property.
pub fn Element::get_style(self : Element, prop : String) -> String {
  @dom.get_style(self.elt, prop)
}

///|
/// Rendered width in CSS pixels.
pub fn Element::width(self : Element) -> Double {
  @dom.element_width(self.elt)
}

///|
/// Rendered height in CSS pixels.
pub fn Element::height(self : Element) -> Double {
  @dom.element_height(self.elt)
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

///|
/// Creates an element with any tag (e.g. `"h2"`, `"ul"`), with optional
/// inner HTML.
pub fn P5::create_element(
  self : P5,
  tag : String,
  content~ : String = "",
) -> Element {
  self.make_element(tag, content)
}

///|
/// All elements matching a CSS selector (inside the element matching
/// `container`, if given).
pub fn select_all(
  selector : String,
  container~ : String = "",
) -> Array[Element] {
  [
    for e in @dom.query_selector_all(selector, container) => wrap(e)
  ]
}

///|
/// Removes every element created with the `create_*` functions (the canvas
/// stays).
pub fn P5::remove_elements(self : P5) -> Unit {
  for e in self.elements {
    e.remove()
  }
  self.elements.clear()
}

///|
/// The sketch's canvas as an element (to position it, accept dropped
/// files, etc.).
pub fn P5::canvas_element(self : P5) -> Element? {
  self.canvas.map(c => wrap(@dom.canvas_element(c)))
}

///|
/// Creates a group of radio buttons; add choices with `option(value,
/// label?)` and read the choice with `value()`.
pub fn P5::create_radio(self : P5, name? : String) -> Element {
  let name = match name {
    Some(n) => n
    None => {
      self.radio_counter += 1
      "radioOption_\{self.radio_counter - 1}"
    }
  }
  let e = {
    elt: @dom.create_element("div", "", self.container),
    radio_name: Some(name),
  }
  self.elements.push(e)
  e
}

///|
/// A file chosen in a file input or dropped on an element (p5.File).
pub struct File {
  /// The underlying browser `File`.
  file : @dom.File
  /// MIME type, e.g. `"image"`.
  file_type : String
  /// MIME subtype, e.g. `"png"`.
  subtype : String
  name : String
  /// Size in bytes.
  size : Int32
  /// The contents: text for text/JSON files, a blob URL for audio/video,
  /// a data URL otherwise (usable with `load_image`).
  data : String
  priv mut is_blob_url : Bool
}

///|
fn File::load(f : @dom.File, callback : (File) -> Unit) -> Unit {
  let info = @dom.file_info(f)
  @dom.read_file(f, (data, is_blob_url) => {
    let size = @string.parse_int(info[3]) catch { _ => 0 }
    callback({
      file: f,
      file_type: info[0],
      subtype: info[1],
      name: info[2],
      size,
      data,
      is_blob_url,
    })
  })
}

///|
/// Parses the contents of a JSON file.
pub fn File::json(self : File) -> Json? {
  try @json.parse(self.data) catch {
    _ => None
  } noraise {
    j => Some(j)
  }
}

///|
/// Releases the blob URL of an audio/video file.
pub fn File::revoke(self : File) -> Unit {
  if self.is_blob_url {
    @dom.revoke_url(self.data)
    self.is_blob_url = false
  }
}

///|
/// Creates a file picker; `on_file` is called for each chosen file.
pub fn P5::create_file_input(
  self : P5,
  on_file : (File) -> Unit,
  multiple~ : Bool = false,
) -> Element {
  let e = self.make_element("input", "")
  @dom.set_attribute(e.elt, "type", "file")
  if multiple {
    @dom.set_attribute(e.elt, "multiple", "true")
  }
  @dom.on_files_chosen(e.elt, f => File::load(f, on_file))
  e
}
