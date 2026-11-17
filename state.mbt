///|
/// Rendering state saved by `push()` and restored by `pop()`.
priv struct State {
  mut fill : Color?
  mut fill_set : Bool
  mut stroke : Color?
  mut stroke_set : Bool
  mut stroke_weight : Double
  mut stroke_cap : StrokeCap
  mut stroke_join : StrokeJoin
  mut rect_mode : ShapeMode
  mut ellipse_mode : ShapeMode
  mut image_mode : ShapeMode
  mut color_mode : ColorMode
  color_maxes : Map[ColorMode, @color.ColorMaxes]
  mut matrix : Matrix2D
  mut tint : Color?
  mut blend_mode : BlendMode
  mut text_size : Double
  mut text_leading : Double
  mut leading_set : Bool
  mut text_font : String
  /// The loaded font set with `text_font_face`, if any.
  mut font_obj : Font?
  mut text_style : TextStyle
  mut text_align : HAlign
  mut text_baseline : VAlign
  mut text_wrap : TextWrap
  mut font_weight : String
  mut font_variant : String
  mut text_direction : String
  mut bezier_order : Int32
  mut spline_ends : SplineEnds
  mut spline_tightness : Double
  mut erasing : Bool
  mut smooth : Bool
}

///|
fn default_maxes_map() -> Map[ColorMode, @color.ColorMaxes] {
  let m = Map([])
  for mode in [ColorMode::RGB, HSB, HSL, HWB, LAB, LCH, OKLAB, OKLCH] {
    m[mode] = @color.default_maxes(mode)
  }
  m
}

///|
fn State::new() -> State {
  {
    fill: Some(Color::rgb(255, 255, 255)),
    fill_set: false,
    stroke: Some(Color::rgb(0, 0, 0)),
    stroke_set: false,
    stroke_weight: 1,
    stroke_cap: Round,
    stroke_join: Miter,
    rect_mode: Corner,
    ellipse_mode: Center,
    image_mode: Corner,
    color_mode: RGB,
    color_maxes: default_maxes_map(),
    matrix: @math.identity,
    tint: None,
    blend_mode: Blend,
    text_size: 12,
    text_leading: 15,
    leading_set: false,
    text_font: "sans-serif",
    font_obj: None,
    text_style: Normal,
    text_align: Left,
    text_baseline: Baseline,
    text_wrap: Word,
    font_weight: "normal",
    font_variant: "normal",
    text_direction: "inherit",
    bezier_order: 3,
    spline_ends: Include,
    spline_tightness: 0,
    erasing: false,
    smooth: true,
  }
}

///|
fn State::copy(self : State) -> State {
  let maxes = Map([])
  for k, v in self.color_maxes {
    maxes[k] = v.copy()
  }
  { ..self, color_maxes: maxes, }
}
