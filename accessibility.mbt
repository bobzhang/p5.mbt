// p5.js src/accessibility: canvas descriptions for screen readers
// (`describe`, `describe_element`) and generated descriptions of what the
// sketch draws (`text_output`, `grid_output`).

///|
/// Where an accessible description goes: only into the canvas's fallback
/// content (read by screen readers), or also as a visible label next to
/// the canvas (p5's `FALLBACK` and `LABEL`).
#derive(Eq, Debug)
pub(all) enum DescriptionDisplay {
  Fallback
  Label
}

///|
fn P5::main_canvas(self : P5) -> @dom.Canvas? {
  match self.gl_canvas {
    Some(c) => Some(c)
    None => self.canvas
  }
}

///|
/// Describes the canvas for screen readers. With `display=Label` the
/// description is also shown below the canvas. `lang` sets its language.
pub fn P5::describe(
  self : P5,
  text : String,
  display? : DescriptionDisplay,
  lang? : String,
) -> Unit {
  guard self.main_canvas() is Some(c) else { return }
  let text = @a11y.description_text(text)
  @dom.describe_html(c, "fallback", text)
  if display is Some(Label) {
    @dom.describe_html(c, "label", text)
  }
  @dom.set_description_lang(c, lang.unwrap_or(""))
}

///|
/// Describes one element of the canvas: `name` and `text` become a row of
/// a table in the canvas's description.
pub fn P5::describe_element(
  self : P5,
  name : String,
  text : String,
  display? : DescriptionDisplay,
  lang? : String,
) -> Unit {
  guard self.main_canvas() is Some(c) else { return }
  let text = @a11y.description_text(text)
  let element_name = @a11y.element_name(name)
  let id = @a11y.element_id(name)
  let lang_attr = match lang {
    Some(l) => " lang=\"\{l}\""
    None => ""
  }
  let inner = "<th scope=\"row\"\{lang_attr}>\{element_name}</th><td\{lang_attr}>\{text}</td>"
  @dom.describe_element_html(c, "fallback", id, inner)
  if display is Some(Label) {
    @dom.describe_element_html(c, "label", id, inner)
  }
  @dom.set_description_lang(c, lang.unwrap_or(""))
}

///|
fn P5::ingredients(self : P5) -> @a11y.Ingredients {
  match self.extras.outputs {
    Some(i) => i
    None => {
      let i = @a11y.Ingredients::new()
      self.extras.outputs = Some(i)
      i
    }
  }
}

///|
/// Describes the shapes on the canvas as a list, updated every frame: their
/// kind, color, position and size. With `display=Label` the output is also
/// shown next to the canvas. 2D only, as in p5.
pub fn P5::text_output(self : P5, display? : DescriptionDisplay) -> Unit {
  guard self.main_canvas() is Some(c) else { return }
  ignore(self.ingredients())
  self.extras.text_output = true
  @dom.create_output(c, "textOutput", "Fallback")
  if display is Some(Label) {
    self.extras.text_label = true
    @dom.create_output(c, "textOutput", "Label")
  }
}

///|
/// Describes the shapes on the canvas as a 10 × 10 grid, updated every
/// frame. With `display=Label` the output is also shown next to the
/// canvas. 2D only, as in p5.
pub fn P5::grid_output(self : P5, display? : DescriptionDisplay) -> Unit {
  guard self.main_canvas() is Some(c) else { return }
  ignore(self.ingredients())
  self.extras.grid_output = true
  @dom.create_output(c, "gridOutput", "Fallback")
  if display is Some(Label) {
    self.extras.grid_label = true
    @dom.create_output(c, "gridOutput", "Label")
  }
}

///|
fn P5::outputs_on(self : P5) -> Bool {
  self.extras.text_output || self.extras.grid_output
}

///|
fn rgba255(c : Color) -> FixedArray[Double] {
  let (r, g, b, a) = c.to_srgb()
  [r * 255, g * 255, b * 255, a * 255]
}

///|
/// Records a color change for the outputs (`_accsCanvasColors` and
/// `_accsBackground`).
fn P5::accs_color(self : P5, which : String, c : Color) -> Unit {
  guard self.outputs_on() && self.extras.outputs is Some(ing) else { return }
  match which {
    "fill" => ing.fill_color(rgba255(c))
    "stroke" => ing.stroke_color(rgba255(c))
    _ => ing.background(rgba255(c))
  }
}

///|
/// Records a shape for the outputs (`_accsOutput`). `args` are the shape's
/// arguments after mode adjustment, as in p5.
fn P5::accs_output(
  self : P5,
  kind : String,
  args : Array[Double],
  arc_mode~ : String = "",
) -> Unit {
  guard self.outputs_on() && self.extras.outputs is Some(ing) else { return }
  let kind = if kind == "ellipse" && args[2] == args[3] {
    "circle"
  } else if kind == "rectangle" && args[2] == args[3] {
    "square"
  } else {
    kind
  }
  let (mx, my) = @a11y.middle(kind, args)
  let w = self.width
  let h = self.height
  let pos_of = (x : Double, y : Double) => {
    let (sx, sy) = self.world_to_screen(x, y)
    @a11y.position_name(sx, sy, w, h)
  }
  let (loc_x, loc_y) = @a11y.grid_cell(mx, my, w, h)
  let entry : @a11y.Entry = if kind == "line" {
    let p1 = pos_of(args[0], 1)
    let p2 = pos_of(args[2], 3)
    {
      color: ing.stroke,
      pos: if p1 == p2 {
        "at \{p1}"
      } else {
        "from \{p1} to \{p2}"
      },
      loc_x,
      loc_y,
      area: None,
      length: Some(
        @a11y.round_int(
          ((args[2] - args[0]) * (args[2] - args[0]) +
          (args[3] - args[1]) * (args[3] - args[1])).sqrt(),
        ),
      ),
    }
  } else if kind == "point" {
    {
      color: ing.stroke,
      pos: pos_of(mx, my),
      loc_x,
      loc_y,
      area: None,
      length: None,
    }
  } else {
    {
      color: ing.fill,
      pos: pos_of(mx, my),
      loc_x,
      loc_y,
      area: Some(self.accs_area(kind, args, arc_mode)),
      length: None,
    }
  }
  ing.add(kind, entry)
}

///|
/// The second half of p5's `_getArea`: the shape's area as a percentage of
/// the canvas mapped back through the current transform.
fn P5::accs_area(
  self : P5,
  kind : String,
  args : Array[Double],
  arc_mode : String,
) -> Int32 {
  let area = @a11y.shape_area(kind, args, arc_mode~)
  let cw = self.width * self.density
  let ch = self.height * self.density
  let inv = self.device_matrix().invert().unwrap_or(@math.identity)
  let tc = [(0.0, 0.0), (cw, 0.0), (cw, ch), (0.0, ch)].map(p => {
    inv.apply(p.0, p.1)
  })
  let canvas_area = ((tc[3].0 + tc[0].0) * (tc[3].1 - tc[0].1) +
    (tc[0].0 + tc[1].0) * (tc[0].1 - tc[1].1) +
    (tc[1].0 + tc[2].0) * (tc[1].1 - tc[2].1) +
    (tc[2].0 + tc[3].0) * (tc[2].1 - tc[3].1)).abs() /
    2
  @a11y.round_int(area * 100 / canvas_area)
}

///|
/// Writes the outputs when the drawing changed (`_updateAccsOutput`).
fn P5::update_accs_outputs(self : P5) -> Unit {
  guard self.outputs_on() && self.extras.outputs is Some(ing) else { return }
  guard self.main_canvas() is Some(c) else { return }
  if self.gl is Some(_) {
    if !self.extras.warned_webgl_outputs {
      self.extras.warned_webgl_outputs = true
      @dom.console_error(
        "textOutput() and gridOutput() do not yet work in WebGL mode.",
      )
    }
    return
  }
  if !ing.changed() {
    return
  }
  let w = @dom.number_to_string(self.width)
  let h = @dom.number_to_string(self.height)
  let cid = @dom.canvas_id(c)
  let text = (id : String) => {
    @dom.set_output_part(c, id, "summary", ing.text_summary(w, h))
    @dom.set_output_part(c, id, "list", ing.text_list(cid + id))
    @dom.set_output_part(c, id, "shapeDetails", ing.text_details(cid + id))
  }
  let grid = (id : String) => {
    let (summary, details) = ing.grid_summary_and_details(cid + id, w, h)
    @dom.set_output_part(c, id, "summary", summary)
    @dom.set_output_part(c, id, "map", ing.grid_map(cid + id))
    @dom.set_output_part(c, id, "shapeDetails", details)
  }
  if self.extras.text_output {
    text("textOutput")
  }
  if self.extras.grid_output {
    grid("gridOutput")
  }
  if self.extras.text_label {
    text("textOutputLabel")
  }
  if self.extras.grid_label {
    grid("gridOutputLabel")
  }
}
