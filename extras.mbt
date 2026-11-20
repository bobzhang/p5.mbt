// State for features added on top of the core sketch: accessible outputs,
// instancing, WEBGL debug helpers and extra text properties.

///|
priv struct Extras {
  /// Shapes recorded for `text_output` / `grid_output`.
  mut outputs : @a11y.Ingredients?
  mut text_output : Bool
  mut grid_output : Bool
  mut text_label : Bool
  mut grid_label : Bool
  mut warned_webgl_outputs : Bool
  /// Instance count for the next WEBGL primitive (`instances()`).
  mut instances : Int32
  /// `debug_mode` grid: size, divisions and offset.
  mut debug_grid : (Double, Int32, Double, Double, Double)?
  /// `debug_mode` axes: size and offset.
  mut debug_axes : (Double, Double, Double, Double)?
  /// Canvas text properties set with `text_property` (name, CSS value).
  text_props : Map[String, String]
  /// Custom vertex properties of the shape being built: name and the value
  /// the next vertices get (`vertex_property`).
  vertex_props : Array[(String, FixedArray[Double])]
}

///|
fn Extras::new() -> Extras {
  {
    outputs: None,
    text_output: false,
    grid_output: false,
    text_label: false,
    grid_label: false,
    warned_webgl_outputs: false,
    instances: 1,
    debug_grid: None,
    debug_axes: None,
    text_props: Map([]),
    vertex_props: [],
  }
}
