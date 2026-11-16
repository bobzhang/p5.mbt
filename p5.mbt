// The sketch object: port of p5.js src/core/main.js and the parts of
// p5.Renderer / p5.Renderer2D that hold state.

///|
/// Which mouse buttons are currently held down.
#derive(Eq, Debug)
pub(all) struct MouseButtons {
  mut left : Bool
  mut center : Bool
  mut right : Bool
}

///|
/// An active touch point.
#derive(Eq, Debug)
pub(all) struct Touch {
  x : Double
  y : Double
  win_x : Double
  win_y : Double
  id : Int32
}

///|
/// Callbacks of a sketch. Every callback receives the sketch.
priv struct Callbacks {
  mut setup : (P5) -> Unit
  mut draw : ((P5) -> Unit)?
  mut mouse_pressed : (P5) -> Unit
  mut mouse_released : (P5) -> Unit
  mut mouse_clicked : (P5) -> Unit
  mut double_clicked : (P5) -> Unit
  mut mouse_moved : (P5) -> Unit
  mut mouse_dragged : (P5) -> Unit
  mut mouse_wheel : (P5, Double) -> Unit
  mut key_pressed : (P5) -> Unit
  mut key_released : (P5) -> Unit
  mut key_typed : (P5) -> Unit
  mut touch_started : (P5) -> Unit
  mut touch_moved : (P5) -> Unit
  mut touch_ended : (P5) -> Unit
  mut window_resized : (P5) -> Unit
}

///|
fn nop(_ : P5) -> Unit {

}

///|
/// A p5 sketch (or an off-screen graphics buffer created with
/// `create_graphics`). All drawing functions are methods of this type.
pub struct P5 {
  /// Width of the canvas in CSS pixels.
  mut width : Double
  /// Height of the canvas in CSS pixels.
  mut height : Double
  /// Number of frames drawn since the sketch started.
  mut frame_count : Int32
  /// Milliseconds between the previous frame and the current one.
  mut delta_time : Double
  /// Horizontal mouse position relative to the canvas.
  mut mouse_x : Double
  /// Vertical mouse position relative to the canvas.
  mut mouse_y : Double
  /// `mouse_x` in the previous frame.
  mut pmouse_x : Double
  /// `mouse_y` in the previous frame.
  mut pmouse_y : Double
  /// Horizontal mouse position relative to the window.
  mut win_mouse_x : Double
  /// Vertical mouse position relative to the window.
  mut win_mouse_y : Double
  /// `win_mouse_x` in the previous frame.
  mut pwin_mouse_x : Double
  /// `win_mouse_y` in the previous frame.
  mut pwin_mouse_y : Double
  /// Horizontal movement of the mouse since the last event.
  mut moved_x : Double
  /// Vertical movement of the mouse since the last event.
  mut moved_y : Double
  /// Buttons currently held.
  mouse_button : MouseButtons
  /// `true` while a mouse button is held down.
  mut mouse_is_pressed : Bool
  /// The last key typed (e.g. `"a"`, `"Enter"`, `"ArrowLeft"`).
  mut key : String
  /// The physical key code of the last key (e.g. `"KeyA"`).
  mut code : String
  /// The legacy numeric key code of the last key (e.g. 13 for Enter).
  mut key_code : Int32
  /// `true` while any key is held down.
  mut key_is_pressed : Bool
  /// Active touch points.
  mut touches : Array[Touch]
  /// `true` when the window has focus.
  mut focused : Bool
  /// Inner width of the browser window.
  mut window_width : Double
  /// Inner height of the browser window.
  mut window_height : Double
  /// Pixel data filled by `load_pixels()` (RGBA, row-major, device pixels).
  mut pixels : FixedArray[Byte]
  priv mut surface : &Surface
  priv mut canvas : @dom.Canvas?
  priv mut density : Double
  priv mut state : State
  priv stack : Array[State]
  priv shape : Shape
  priv rng : Random
  priv mut noise_gen : Noise?
  priv callbacks : Callbacks
  priv mut looping : Bool
  priv mut target_frame_rate : Double
  priv mut frame_rate_value : Double
  priv mut millis_start : Double
  priv mut last_target_frame_time : Double
  priv mut last_real_frame_time : Double
  priv mut setup_done : Bool
  priv mut in_draw : Bool
  priv mut draw_scheduled : Bool
  priv mut has_mouse_interacted : Bool
  priv keys_down : Map[String, Bool]
  priv mut clip_depth : Int32
  priv mut clipping : Bool
  priv mut clip_invert : Bool
  priv clip_path : @shape.Path
  priv mut pending_loads : Int32
  priv mut on_loads_done : () -> Unit
  priv mut is_main : Bool
  priv mut erase_strength : (Double, Double)
  priv mut font_counter : Int32
  priv mut container : String
}

///|
fn P5::make(
  surface : &Surface,
  w : Double,
  h : Double,
  density : Double,
  seed : Double,
) -> P5 {
  {
    width: w,
    height: h,
    frame_count: 0,
    delta_time: 0,
    mouse_x: 0,
    mouse_y: 0,
    pmouse_x: 0,
    pmouse_y: 0,
    win_mouse_x: 0,
    win_mouse_y: 0,
    pwin_mouse_x: 0,
    pwin_mouse_y: 0,
    moved_x: 0,
    moved_y: 0,
    mouse_button: { left: false, center: false, right: false, },
    mouse_is_pressed: false,
    key: "",
    code: "",
    key_code: 0,
    key_is_pressed: false,
    touches: [],
    focused: true,
    window_width: w,
    window_height: h,
    pixels: [],
    surface,
    canvas: None,
    density,
    state: State::new(),
    stack: [],
    shape: Shape::new(),
    rng: Random::new(seed),
    noise_gen: None,
    callbacks: {
      setup: nop,
      draw: None,
      mouse_pressed: nop,
      mouse_released: nop,
      mouse_clicked: nop,
      double_clicked: nop,
      mouse_moved: nop,
      mouse_dragged: nop,
      mouse_wheel: (_, _) => (),
      key_pressed: nop,
      key_released: nop,
      key_typed: nop,
      touch_started: nop,
      touch_moved: nop,
      touch_ended: nop,
      window_resized: nop,
    },
    looping: true,
    target_frame_rate: 60,
    frame_rate_value: 0,
    millis_start: 0,
    last_target_frame_time: 0,
    last_real_frame_time: 0,
    setup_done: false,
    in_draw: false,
    draw_scheduled: false,
    has_mouse_interacted: false,
    keys_down: {},
    clip_depth: 0,
    clipping: false,
    clip_invert: false,
    clip_path: [],
    pending_loads: 0,
    on_loads_done: () => (),
    is_main: false,
    erase_strength: (255, 255),
    font_counter: 0,
    container: "",
  }
}

///|
/// Creates a sketch that draws into `surface` without a browser canvas or
/// animation loop (useful for tests and for recording drawings). Call
/// `setup` / `draw` callbacks yourself, or use `redraw()` after
/// `set_draw`.
///
/// ```mbt check
/// test {
///   let rec = @p5.Recorder::new()
///   let p = @p5.P5::headless(rec, 50, 50)
///   ignore(rec.take()) // drop the initial state setup
///   p.no_stroke()
///   p.fill("red")
///   p.rect(10, 10, 20, 20)
///   inspect(
///     rec.take().join("\n"),
///     content=(
///       #|transform 1 0 0 1 0 0
///       #|fill #ff0000 R10,10,20,20
///     ),
///   )
/// }
/// ```
pub fn P5::headless(
  surface : &Surface,
  width : Double,
  height : Double,
  pixel_density~ : Double = 1,
  seed~ : Double = 0,
) -> P5 {
  let p = P5::make(surface, width, height, pixel_density, seed)
  p.apply_defaults()
  p
}

///|
fn P5::apply_defaults(self : P5) -> Unit {
  self.state = State::new()
  self.stack.clear()
  self.surface.set_blend_mode(Blend)
  self.surface.set_smoothing(true)
}

///|
/// The transform from user space to device pixels.
fn P5::device_matrix(self : P5) -> Matrix2D {
  @math.identity.scale(self.density, self.density).multiply(self.state.matrix)
}

///|
fn P5::sync_transform(self : P5) -> Unit {
  self.surface.set_transform(self.device_matrix())
}

///|
/// The underlying drawing surface.
pub fn P5::surface(self : P5) -> &Surface {
  self.surface
}

///|
/// The underlying canvas element, when the sketch draws on one.
pub fn P5::canvas(self : P5) -> @dom.Canvas? {
  self.canvas
}

///|
/// Random number generator used by `random()`.
pub fn P5::rng(self : P5) -> Random {
  self.rng
}
