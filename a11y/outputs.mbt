// p5.js src/accessibility/{outputs,textOutput,gridOutput}.js: the shapes a
// sketch draws, collected each frame and described as text or as a grid.

///|
/// One shape as the accessible outputs describe it.
#derive(Eq, Debug)
pub(all) struct Entry {
  /// Color name (fill, or stroke for lines and points).
  color : String
  /// Position on the canvas: "top left", "middle", "from A to B", ...
  pos : String
  /// Column (0-9) of the shape's middle in a 10 × 10 grid.
  loc_x : Int32
  /// Row (0-9) of the shape's middle.
  loc_y : Int32
  /// Percentage of the canvas covered (not for lines and points).
  area : Int32?
  /// Length in pixels (lines only).
  length : Int32?
}

///|
/// The collected shapes and colors of a frame (p5's `ingredients`).
pub struct Ingredients {
  /// Shapes by kind ("rectangle", "circle", ...) in the order first drawn.
  mut shapes : Map[String, Array[Entry]]
  mut background : String
  mut fill : String
  mut stroke : String
  priv mut background_rgba : FixedArray[Double]?
  priv mut fill_rgba : FixedArray[Double]?
  priv mut stroke_rgba : FixedArray[Double]?
  priv mut prev_shapes : String
  priv mut prev_background : String
}

///|
pub fn Ingredients::new() -> Ingredients {
  {
    shapes: Map([]),
    background: "white",
    fill: "white",
    stroke: "black",
    background_rgba: None,
    fill_rgba: None,
    stroke_rgba: None,
    prev_shapes: "",
    prev_background: "",
  }
}

///|
fn same_rgba(a : FixedArray[Double]?, b : FixedArray[Double]) -> Bool {
  match a {
    Some(a) => {
      if a.length() != b.length() {
        return false
      }
      for i in 0..<a.length() {
        if a[i] != b[i] {
          return false
        }
      }
      true
    }
    None => false
  }
}

///|
fn shapes_key(shapes : Map[String, Array[Entry]]) -> String {
  let sb = StringBuilder()
  for k, v in shapes {
    sb.write_string(k)
    sb.write_string("\{Repr(v)}")
  }
  sb.to_string()
}

///|
/// A new background (`_accsBackground`): the frame's shapes are cleared.
pub fn Ingredients::background(
  self : Ingredients,
  rgba : FixedArray[Double],
) -> Unit {
  self.prev_shapes = shapes_key(self.shapes)
  self.prev_background = self.background
  self.shapes = Map([])
  if !same_rgba(self.background_rgba, rgba) {
    self.background_rgba = Some(rgba)
    self.background = color_name(rgba)
  }
}

///|
/// A new fill color (`_accsCanvasColors('fill', ...)`).
pub fn Ingredients::fill_color(
  self : Ingredients,
  rgba : FixedArray[Double],
) -> Unit {
  if !same_rgba(self.fill_rgba, rgba) {
    self.fill_rgba = Some(rgba)
    self.fill = color_name(rgba)
  }
}

///|
/// A new stroke color.
pub fn Ingredients::stroke_color(
  self : Ingredients,
  rgba : FixedArray[Double],
) -> Unit {
  if !same_rgba(self.stroke_rgba, rgba) {
    self.stroke_rgba = Some(rgba)
    self.stroke = color_name(rgba)
  }
}

///|
/// Records a shape unless an identical one was already recorded.
pub fn Ingredients::add(self : Ingredients, kind : String, e : Entry) -> Unit {
  match self.shapes.get(kind) {
    None => self.shapes[kind] = [e]
    Some(list) => if !list.contains(e) { list.push(e) }
  }
}

///|
/// Whether anything changed since the outputs were last written
/// (`_updateAccsOutput`); remembers the current state.
pub fn Ingredients::changed(self : Ingredients) -> Bool {
  let key = shapes_key(self.shapes)
  if key != self.prev_shapes || self.background != self.prev_background {
    self.prev_shapes = key
    true
  } else {
    false
  }
}

///|
/// The middle of a shape from its arguments (p5's `_getMiddle`).
pub fn middle(kind : String, args : Array[Double]) -> (Double, Double) {
  match kind {
    "rectangle" | "ellipse" | "arc" | "circle" | "square" =>
      (js_round(args[0] + args[2] / 2), js_round(args[1] + args[3] / 2))
    "triangle" =>
      ((args[0] + args[2] + args[4]) / 3, (args[1] + args[3] + args[5]) / 3)
    "quadrilateral" =>
      (
        (args[0] + args[2] + args[4] + args[6]) / 4,
        (args[1] + args[3] + args[5] + args[7]) / 4,
      )
    "line" => ((args[0] + args[2]) / 2, (args[1] + args[3]) / 2)
    _ => (args[0], args[1])
  }
}

///|
/// A position in screen coordinates named like p5's `_getPos`.
pub fn position_name(x : Double, y : Double, w : Double, h : Double) -> String {
  let row = if y < 0.4 * h { 0 } else if y > 0.6 * h { 2 } else { 1 }
  if x < 0.4 * w {
    ["top left", "mid left", "bottom left"][row]
  } else if x > 0.6 * w {
    ["top right", "mid right", "bottom right"][row]
  } else {
    ["top middle", "middle", "bottom middle"][row]
  }
}

///|
/// The 10 × 10 grid cell of a point (`_canvasLocator`).
pub fn grid_cell(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> (Int32, Int32) {
  let mut lx = (x / w * 10).floor().to_int()
  let mut ly = (y / h * 10).floor().to_int()
  if lx == 10 {
    lx = 9
  }
  if ly == 10 {
    ly = 9
  }
  (lx, ly)
}

///|
/// The untransformed area of a shape from its arguments (the first half of
/// p5's `_getArea`); `arc_mode` is "open", "chord", "pie" or "".
pub fn shape_area(
  kind : String,
  args : Array[Double],
  arc_mode~ : String = "",
) -> Double {
  match kind {
    "arc" => {
      let tau = @math.PI * 2
      let size = ((args[5] - args[4]) % tau + tau) % tau
      let mut area = size * args[2] * args[3] / 8
      if arc_mode == "open" || arc_mode == "chord" {
        // p5 rounds the cosines with toFixed(2)
        let fixed = (v : Double) => js_round(v * 100) / 100
        let ax = args[0]
        let ay = args[1]
        let bx = args[0] + args[2] / 2 * fixed(@math.cos(args[4]))
        let by = args[1] + args[3] / 2 * fixed(@math.sin(args[4]))
        let cx = args[0] + args[2] / 2 * fixed(@math.cos(args[5]))
        let cy = args[1] + args[3] / 2 * fixed(@math.sin(args[5]))
        let extra = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)).abs() / 2
        area = if size > @math.PI { area + extra } else { area - extra }
      }
      area
    }
    "ellipse" | "circle" => 3.14 * args[2] / 2 * args[3] / 2
    "quadrilateral" =>
      ((args[6] + args[0]) * (args[7] - args[1]) +
      (args[0] + args[2]) * (args[1] - args[3]) +
      (args[2] + args[4]) * (args[3] - args[5]) +
      (args[4] + args[6]) * (args[5] - args[7])).abs() /
      2
    "rectangle" | "square" => args[2] * args[3]
    "triangle" =>
      (args[0] * (args[3] - args[5]) +
      args[2] * (args[5] - args[1]) +
      args[4] * (args[1] - args[3])).abs() /
      2
    _ => 0
  }
}

///|
/// `Math.round` as an Int.
pub fn round_int(x : Double) -> Int32 {
  js_round(x).to_int()
}

// ---- text output ----

///|
/// The text output's summary paragraph.
pub fn Ingredients::text_summary(
  self : Ingredients,
  width : String,
  height : String,
) -> String {
  let n = self.count()
  let text = "Your output is a, \{width} by \{height} pixels, \{self.background} canvas containing the following"
  if n == 1 {
    "\{text} shape:"
  } else {
    "\{text} \{n} shapes:"
  }
}

///|
/// The number of recorded shapes.
pub fn Ingredients::count(self : Ingredients) -> Int32 {
  let mut n = 0
  for _, v in self.shapes {
    n += v.length()
  }
  n
}

///|
/// The text output's list of shapes (`<li>` items).
pub fn Ingredients::text_list(self : Ingredients, id : String) -> String {
  let sb = StringBuilder()
  let mut n = 0
  for kind, list in self.shapes {
    for e in list {
      sb.write_string("<li><a href=\"#\{id}shape\{n}\">\{e.color} \{kind}</a>")
      if kind == "line" {
        sb.write_string(
          ", \{e.pos}, \{e.length.unwrap_or(0)} pixels long.</li>",
        )
      } else {
        sb.write_string(", at \{e.pos}")
        if kind != "point" {
          sb.write_string(", covering \{e.area.unwrap_or(0)}% of the canvas")
        }
        sb.write_string(".</li>")
      }
      n += 1
    }
  }
  sb.to_string()
}

///|
/// The text output's table rows of shape details.
pub fn Ingredients::text_details(self : Ingredients, id : String) -> String {
  let sb = StringBuilder()
  let mut n = 0
  for kind, list in self.shapes {
    for e in list {
      sb.write_string("<tr id=\"\{id}shape\{n}\"><th>\{e.color} \{kind}</th>")
      if kind == "line" {
        sb.write_string(
          "<td>location = \{e.pos}</td><td>length = \{e.length.unwrap_or(0)} pixels</td></tr>",
        )
      } else {
        sb.write_string("<td>location = \{e.pos}</td>")
        if kind != "point" {
          sb.write_string("<td> area = \{e.area.unwrap_or(0)}%</td>")
        }
        sb.write_string("</tr>")
      }
      n += 1
    }
  }
  sb.to_string()
}

// ---- grid output ----

///|
/// The grid output's table: a 10 × 10 map of where shapes are.
pub fn Ingredients::grid_map(self : Ingredients, id : String) -> String {
  let cells : Array[Array[String?]] = Array::makei(10, _ => {
    Array::make(10, None)
  })
  let mut n = 0
  for kind, list in self.shapes {
    for e in list {
      let fill = if kind != "line" {
        "<a href=\"#\{id}shape\{n}\">\{e.color} \{kind}</a>"
      } else {
        "<a href=\"#\{id}shape\{n}\">\{e.color} \{kind} midpoint</a>"
      }
      if e.loc_y >= 0 && e.loc_y < 10 && e.loc_x >= 0 && e.loc_x < 10 {
        cells[e.loc_y][e.loc_x] = match cells[e.loc_y][e.loc_x] {
          None => Some(fill)
          Some(prev) => Some(prev + "  " + fill)
        }
        n += 1
      }
    }
  }
  let sb = StringBuilder()
  for row in cells {
    sb.write_string("<tr>")
    for c in row {
      sb.write_string("<td>")
      if c is Some(s) {
        sb.write_string(s)
      }
      sb.write_string("</td>")
    }
    sb.write_string("</tr>")
  }
  sb.to_string()
}

///|
/// The grid output's summary and its list of shape details.
pub fn Ingredients::grid_summary_and_details(
  self : Ingredients,
  id : String,
  width : String,
  height : String,
) -> (String, String) {
  let details = StringBuilder()
  let mut shapes = ""
  let mut total = 0
  for kind, list in self.shapes {
    let mut num = 0
    for e in list {
      details.write_string("<li id=\"\{id}shape\{total}\">\{e.color} \{kind},")
      if kind == "line" {
        details.write_string(
          " location = \{e.pos}, length = \{e.length.unwrap_or(0)} pixels",
        )
      } else {
        details.write_string(" location = \{e.pos}")
        if kind != "point" {
          details.write_string(", area = \{e.area.unwrap_or(0)} %")
        }
        details.write_string("</li>")
      }
      num += 1
      total += 1
    }
    shapes = if num > 1 {
      "\{shapes} \{num} \{kind}s"
    } else {
      "\{shapes} \{num} \{kind}"
    }
  }
  let text = "\{self.background} canvas, \{width} by \{height} pixels, contains \{total}"
  let summary = if total == 1 {
    "\{text} shape: \{shapes}"
  } else {
    "\{text} shapes: \{shapes}"
  }
  (summary, details.to_string())
}

// ---- describe ----

///|
/// p5's `_descriptionText`: adds a period unless the text already ends
/// with punctuation.
pub fn description_text(text : String) -> String {
  if text.has_suffix(".") ||
    text.has_suffix(";") ||
    text.has_suffix(",") ||
    text.has_suffix("?") ||
    text.has_suffix("!") {
    text
  } else {
    text + "."
  }
}

///|
/// p5's `_elementName`: the name ends with a colon.
pub fn element_name(name : String) -> String {
  if name.has_suffix(".") || name.has_suffix(";") || name.has_suffix(",") {
    let chars = name.to_array()
    String::from_array(chars[:chars.length() - 1]) + ":"
  } else if !name.has_suffix(":") {
    name + ":"
  } else {
    name
  }
}

///|
/// The name with everything but ASCII letters and digits removed (used in
/// element ids).
pub fn element_id(name : String) -> String {
  let sb = StringBuilder()
  for c in name {
    if (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') {
      sb.write_char(c)
    }
  }
  sb.to_string()
}
