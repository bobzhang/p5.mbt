// Smaller parts of p5's core API: page URLs, removing the canvas, the raw
// drawing context, text properties, spline properties and media routing.

///|
/// The page's full URL (`getURL`).
pub fn P5::get_url(self : P5) -> String {
  ignore(self)
  @dom.location_href()
}

///|
/// The parts of the URL's path (`getURLPath`), e.g. `["sketches", "a"]`.
pub fn P5::get_url_path(self : P5) -> Array[String] {
  ignore(self)
  @dom.location_pathname()
  .split("/")
  .filter(v => v != "")
  .map(v => v.to_string())
  .collect()
}

///|
/// The query parameters of the URL (`getURLParams`): `?a=1&b=x` gives
/// `{"a": "1", "b": "x"}`. Like p5, parameters without a value are skipped.
pub fn P5::get_url_params(self : P5) -> Map[String, String] {
  ignore(self)
  let out : Map[String, String] = Map([])
  let search = @dom.location_search()
  for part in search.split("&") {
    let part = part.to_string()
    let part = if part.has_prefix("?") {
      String::from_array(part.to_array()[1:])
    } else {
      part
    }
    let kv = part.split("=").map(s => s.to_string()).collect()
    if kv.length() >= 2 && kv[0] != "" && kv[1] != "" {
      out[kv[0]] = kv[1]
    }
  }
  out
}

///|
/// Removes the sketch's canvas from the page; the sketch keeps running
/// (`noCanvas`).
pub fn P5::no_canvas(self : P5) -> Unit {
  if self.main_canvas() is Some(c) {
    @dom.detach_node(@dom.canvas_element(c))
  }
}

///|
/// The 2D drawing context of the canvas, for calling Canvas API features
/// p5 doesn't wrap (`drawingContext`). `None` in WEBGL or headless.
pub fn P5::drawing_context(self : P5) -> @dom.Context2D? {
  if self.gl is Some(_) {
    return None
  }
  self.canvas.map(c => @dom.get_context(c))
}

// ---- text properties ----

///|
fn P5::apply_text_props(self : P5) -> Unit {
  if self.extras.text_props.is_empty() {
    return
  }
  if self.canvas is Some(c) {
    for name, value in self.extras.text_props {
      @dom.set_context_property(c, name, value)
    }
  }
}

///|
/// Sets a text property by its p5 / Canvas API name (`textProperty`):
/// `textSize`, `textLeading`, `textFont`, `textStyle`, `textWeight`,
/// `textAlign`, `textBaseline`, `textWrap`, `textDirection`/`direction`,
/// `fontVariant`, or any text property of the 2D context such as
/// `letterSpacing`, `wordSpacing`, `fontKerning`, `fontStretch`,
/// `fontVariantCaps` and `textRendering`. Values are written as in CSS.
pub fn P5::text_property(self : P5, name : String, value : String) -> Unit {
  let num = @string.parse_double(value) catch { _ => @double.not_a_number }
  match name {
    "textSize" | "fontSize" => if !num.is_nan() { self.text_size(num) }
    "textLeading" => if !num.is_nan() { self.text_leading(num) }
    "textFont" | "fontFamily" => self.text_font(value)
    "textStyle" | "fontStyle" =>
      self.text_style(
        match value {
          "italic" => Italic
          "bold" => Bold
          "bolditalic" | "bold italic" => BoldItalic
          _ => Normal
        },
      )
    "textWeight" | "fontWeight" =>
      if !num.is_nan() {
        self.text_weight(num)
      } else {
        self.state.font_weight = value
      }
    "fontVariant" => self.text_variant(value)
    "textDirection" | "direction" => self.text_direction(value)
    "textAlign" =>
      self.text_align(
        match value {
          "center" => HCenter
          "right" => Right
          "start" => Start
          "end" => End
          _ => Left
        },
      )
    "textBaseline" =>
      self.state.text_baseline = match value {
        "top" => Top
        "middle" | "center" => VCenter
        "bottom" => Bottom
        "hanging" => Hanging
        "ideographic" => Ideographic
        _ => Baseline
      }
    "textWrap" => self.text_wrap(if value == "char" { Char } else { Word })
    _ => {
      self.extras.text_props[name] = value
      self.apply_text_props()
    }
  }
}

///|
/// Sets several text properties at once (`textProperties(obj)`).
pub fn P5::text_properties(
  self : P5,
  props : ArrayView[(String, String)],
) -> Unit {
  for p in props {
    self.text_property(p.0, p.1)
  }
}

///|
/// The current text properties by name, as `textProperties()` returns
/// them.
pub fn P5::get_text_properties(self : P5) -> Map[String, String] {
  let s = self.state
  let out : Map[String, String] = Map([])
  out["textAlign"] = match s.text_align {
    Left => "left"
    HCenter => "center"
    Right => "right"
    Start => "start"
    End => "end"
  }
  out["textBaseline"] = match s.text_baseline {
    Top => "top"
    VCenter => "middle"
    Bottom => "bottom"
    Baseline => "alphabetic"
    Hanging => "hanging"
    Ideographic => "ideographic"
  }
  out["textFont"] = s.text_font
  out["textLeading"] = @dom.number_to_string(s.text_leading)
  out["textSize"] = @dom.number_to_string(s.text_size)
  out["textWrap"] = if s.text_wrap is Char { "char" } else { "word" }
  out["fontWeight"] = s.font_weight
  out["fontVariant"] = s.font_variant
  out["fontStyle"] = s.text_style.css()
  out["direction"] = s.text_direction
  for k, v in self.extras.text_props {
    out[k] = v
  }
  out
}

///|
/// One text property by name (see `text_property`), or `None` if unknown.
pub fn P5::get_text_property(self : P5, name : String) -> String? {
  self.get_text_properties().get(name)
}

// ---- spline properties ----

///|
/// A spline setting for `spline_property`.
pub(all) enum SplineProperty {
  /// Whether the curve reaches its first and last vertices (`ends`).
  Ends(SplineEnds)
  /// How tight the curve is: 0 is Catmull-Rom, 1 straight lines.
  Tightness(Double)
}

///|
/// Sets a spline property (`splineProperty('ends' | 'tightness', value)`).
pub fn P5::spline_property(self : P5, prop : SplineProperty) -> Unit {
  match prop {
    Ends(e) => self.spline_ends(e)
    Tightness(t) => self.spline_tightness(t)
  }
}

///|
/// The current spline ends and tightness (`splineProperties()`).
pub fn P5::spline_properties(self : P5) -> (SplineEnds, Double) {
  (self.state.spline_ends, self.state.spline_tightness)
}

// ---- media ----

///|
/// The URL the media element plays (`src`).
pub fn MediaElement::src(self : MediaElement) -> String {
  @dom.media_src(self.element.elt)
}

///|
/// Replaces what the media element plays.
pub fn MediaElement::set_src(self : MediaElement, src : String) -> Unit {
  @dom.set_media_src(self.element.elt, src)
}

///|
/// Routes the element's audio through Web Audio into `node` (and the
/// speakers); without a node, only to the speakers (`connect`).
pub fn MediaElement::connect(
  self : MediaElement,
  node? : @dom.AudioNode,
) -> Unit {
  if !@dom.media_connect(self.element.elt, node) {
    @dom.console_error(
      "connect() is meant to be used with Web Audio API or p5.sound.js",
    )
  }
}

///|
/// Removes the element's Web Audio routing, including to the speakers.
pub fn MediaElement::disconnect(self : MediaElement) -> Unit {
  if !@dom.media_disconnect(self.element.elt) {
    @dom.console_error("nothing to disconnect")
  }
}
