// Port of p5.js src/core/{main,structure}.js: the setup/draw lifecycle.

///|
/// Starts a sketch in the browser, like creating `new p5(sketch)`.
///
/// A 100×100 canvas is created before `setup` runs (call `create_canvas`
/// in `setup` to resize it). `preload` may start asset loads such as
/// `load_image`; `setup` runs once they have all finished. Then `draw` is
/// called once per frame. Every callback is optional.
///
/// `container` is the id of an element to put the canvas in (by default the
/// canvas goes into `<main>`). `seed` seeds `random()` and `noise()`
/// (random by default).
///
/// ```mbt nocheck
/// fn main {
///   @p5.run(setup=p => p.create_canvas(400, 400), draw=p => {
///     p.background(220)
///     p.circle(p.mouse_x, p.mouse_y, 50)
///   })
/// }
/// ```
pub fn run(
  preload? : (P5) -> Unit,
  setup? : (P5) -> Unit,
  draw? : (P5) -> Unit,
  mouse_pressed? : (P5) -> Unit,
  mouse_released? : (P5) -> Unit,
  mouse_clicked? : (P5) -> Unit,
  double_clicked? : (P5) -> Unit,
  mouse_moved? : (P5) -> Unit,
  mouse_dragged? : (P5) -> Unit,
  mouse_wheel? : (P5, Double) -> Unit,
  key_pressed? : (P5) -> Unit,
  key_released? : (P5) -> Unit,
  key_typed? : (P5) -> Unit,
  touch_started? : (P5) -> Unit,
  touch_moved? : (P5) -> Unit,
  touch_ended? : (P5) -> Unit,
  window_resized? : (P5) -> Unit,
  container~ : String = "",
  seed? : Double,
) -> Unit {
  @dom.on_ready(() => {
    let density = @dom.device_pixel_ratio().ceil()
    let canvas = @dom.create_canvas(100, 100, density, container, true)
    let seed = match seed {
      Some(s) => s
      None => (@dom.math_random() * 4294967296.0).floor()
    }
    let p = P5::make(CanvasSurface::new(canvas), 100, 100, density, seed)
    p.canvas = Some(canvas)
    p.is_main = true
    p.container = container
    p.window_width = @dom.window_width()
    p.window_height = @dom.window_height()
    p.focused = @dom.document_has_focus()
    let cb = p.callbacks
    if setup is Some(f) {
      cb.setup = f
    }
    cb.draw = draw
    if mouse_pressed is Some(f) {
      cb.mouse_pressed = f
    }
    if mouse_released is Some(f) {
      cb.mouse_released = f
    }
    if mouse_clicked is Some(f) {
      cb.mouse_clicked = f
    }
    if double_clicked is Some(f) {
      cb.double_clicked = f
    }
    if mouse_moved is Some(f) {
      cb.mouse_moved = f
    }
    if mouse_dragged is Some(f) {
      cb.mouse_dragged = f
    }
    if mouse_wheel is Some(f) {
      cb.mouse_wheel = f
    }
    if key_pressed is Some(f) {
      cb.key_pressed = f
    }
    if key_released is Some(f) {
      cb.key_released = f
    }
    if key_typed is Some(f) {
      cb.key_typed = f
    }
    if touch_started is Some(f) {
      cb.touch_started = f
    }
    if touch_moved is Some(f) {
      cb.touch_moved = f
    }
    if touch_ended is Some(f) {
      cb.touch_ended = f
    }
    if window_resized is Some(f) {
      cb.window_resized = f
    }
    p.apply_defaults()
    p.install_events(canvas)
    if preload is Some(f) {
      f(p)
    }
    p.when_loaded(() => p.start())
  })
}

///|
/// Calls `f` once every pending asset load has finished.
fn P5::when_loaded(self : P5, f : () -> Unit) -> Unit {
  if self.pending_loads == 0 {
    f()
  } else {
    self.on_loads_done = f
  }
}

///|
fn P5::begin_load(self : P5) -> Unit {
  self.pending_loads += 1
}

///|
fn P5::end_load(self : P5) -> Unit {
  self.pending_loads -= 1
  if self.pending_loads == 0 {
    let f = self.on_loads_done
    self.on_loads_done = () => ()
    f()
  }
}

///|
fn P5::start(self : P5) -> Unit {
  self.millis_start = @dom.now()
  (self.callbacks.setup)(self)
  let now = @dom.now()
  self.last_target_frame_time = now
  self.last_real_frame_time = now
  self.setup_done = true
  self.millis_start = now
  self.schedule_frame(immediate=true)
}

///|
fn P5::schedule_frame(self : P5, immediate~ : Bool = false) -> Unit {
  if self.draw_scheduled {
    return
  }
  self.draw_scheduled = true
  if immediate {
    self.frame(@dom.now())
  } else {
    @dom.request_animation_frame(ts => self.frame(ts))
  }
}

///|
fn P5::frame(self : P5, now : Double) -> Unit {
  self.draw_scheduled = false
  let since = now - self.last_target_frame_time
  let target = 1000.0 / self.target_frame_rate
  if !self.looping || since >= target - 5 {
    self.delta_time = now - self.last_real_frame_time
    self.frame_rate_value = if self.delta_time > 0 {
      1000.0 / self.delta_time
    } else {
      0
    }
    self.redraw_once()
    self.last_target_frame_time = (self.last_target_frame_time + target).max(
      now,
    )
    self.last_real_frame_time = now
    self.update_mouse_coords()
    self.moved_x = 0
    self.moved_y = 0
  }
  if self.looping {
    self.schedule_frame()
  }
}

///|
fn P5::redraw_once(self : P5) -> Unit {
  guard self.callbacks.draw is Some(draw) else { return }
  self.reset_matrix()
  self.frame_count += 1
  self.in_draw = true
  // Clipping applied during a frame ends with the frame.
  self.surface.save()
  draw(self)
  self.in_draw = false
  // Undo unbalanced push() calls.
  while !self.stack.is_empty() {
    self.pop()
  }
  self.surface.restore()
  self.surface.set_blend_mode(
    if self.state.erasing {
      Remove
    } else {
      self.state.blend_mode
    },
  )
  self.surface.set_smoothing(self.state.smooth)
}

///|
/// Sets the function called by `redraw()` (for headless sketches).
pub fn P5::set_draw(self : P5, draw : (P5) -> Unit) -> Unit {
  self.callbacks.draw = Some(draw)
  self.setup_done = true
}

///|
/// Runs `draw` `n` times (once by default), e.g. after `no_loop()`.
pub fn P5::redraw(self : P5, n~ : Int32 = 1) -> Unit {
  if self.in_draw || !self.setup_done {
    return
  }
  for _ in 0..<n.max(1) {
    self.redraw_once()
  }
}

///|
/// Stops calling `draw` every frame.
pub fn P5::no_loop(self : P5) -> Unit {
  self.looping = false
}

///|
/// Resumes calling `draw` every frame.
pub fn P5::loop_(self : P5) -> Unit {
  if !self.looping {
    self.looping = true
    if self.setup_done && self.is_main {
      self.schedule_frame()
    }
  }
}

///|
/// Whether `draw` is called every frame.
pub fn P5::is_looping(self : P5) -> Bool {
  self.looping
}
