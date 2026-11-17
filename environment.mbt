// Port of p5.js src/core/{environment,rendering}.js.

///|
/// Resizes the canvas to `w`×`h` and resets the drawing state. Call it in
/// `setup`.
pub fn P5::create_canvas(
  self : P5,
  w : Double,
  h : Double,
  renderer~ : RendererKind = P2D,
) -> Unit {
  self.width = w
  self.height = h
  self.surface.resize(w, h, self.density)
  self.apply_defaults()
  if renderer is WebGL && self.gl is None {
    self.create_webgl_canvas(w, h)
  }
}

///|
/// Resizes the canvas, keeping the drawing state (the contents are cleared).
pub fn P5::resize_canvas(self : P5, w : Double, h : Double) -> Unit {
  self.width = w
  self.height = h
  self.surface.resize(w, h, self.density)
  if self.gl is Some(r) && self.gl_canvas is Some(c) {
    @dom.resize_canvas(c, w, h, self.density)
    r.resize(w, h, self.density)
    for fb in self.framebuffers {
      fb.canvas_resized()
    }
  }
  self.surface.set_blend_mode(self.state.blend_mode)
  self.surface.set_smoothing(self.state.smooth)
  if self.is_main && self.setup_done && !self.looping {
    self.redraw()
  }
}

///|
/// Sets the pixel density (device pixels per CSS pixel); this resizes and
/// clears the canvas.
pub fn P5::pixel_density(self : P5, d : Double) -> Unit {
  self.density = d
  self.surface.resize(self.width, self.height, d)
  self.surface.set_blend_mode(self.state.blend_mode)
  self.surface.set_smoothing(self.state.smooth)
}

///|
/// The current pixel density.
pub fn P5::get_pixel_density(self : P5) -> Double {
  self.density
}

///|
/// The display's pixel density.
pub fn P5::display_density(_self : P5) -> Double {
  @dom.device_pixel_ratio()
}

///|
/// Sets the target frame rate (frames per second).
pub fn P5::frame_rate(self : P5, fps : Double) -> Unit {
  if fps > 0 {
    self.target_frame_rate = fps
  }
}

///|
/// The measured frame rate of the last frame.
pub fn P5::get_frame_rate(self : P5) -> Double {
  self.frame_rate_value
}

///|
/// The target frame rate.
pub fn P5::get_target_frame_rate(self : P5) -> Double {
  self.target_frame_rate
}

///|
/// Milliseconds since the sketch started drawing.
pub fn P5::millis(self : P5) -> Double {
  if self.recording is Some(r) {
    (self.frame_count - 1).max(0).to_double() * 1000.0 / r.fps
  } else if self.is_main {
    @dom.now() - self.millis_start
  } else {
    0
  }
}

///|
/// Sets the cursor shown over the canvas (any CSS cursor, e.g. `"pointer"`,
/// `"crosshair"`, `"grab"`, or `"url(...)"`).
pub fn P5::cursor(self : P5, kind~ : String = "default") -> Unit {
  if self.canvas is Some(c) {
    @dom.set_cursor(c, kind)
  }
}

///|
/// Hides the cursor over the canvas.
pub fn P5::no_cursor(self : P5) -> Unit {
  self.cursor(kind="none")
}

///|
/// Enters or leaves full-screen mode (must be triggered by a user gesture).
pub fn P5::fullscreen(self : P5, on : Bool) -> Unit {
  if self.canvas is Some(c) {
    @dom.set_fullscreen(c, on)
  }
}

///|
/// Whether the page is in full-screen mode.
pub fn P5::is_fullscreen(_self : P5) -> Bool {
  @dom.is_fullscreen()
}

///|
/// Width of the screen.
pub fn P5::display_width(_self : P5) -> Double {
  @dom.display_width()
}

///|
/// Height of the screen.
pub fn P5::display_height(_self : P5) -> Double {
  @dom.display_height()
}

///|
/// Sets the angle unit used by `rotate`, `arc`, `sin`, `atan2`, etc.
pub fn P5::angle_mode(self : P5, mode : AngleMode) -> Unit {
  // Like p5.js, the angle mode belongs to the sketch: push()/pop() don't
  // save it. Switching converts the previous device rotations.
  let to_degrees = mode is Degrees
  if to_degrees != self.degrees.val {
    let k = if to_degrees { RAD_TO_DEG } else { DEG_TO_RAD }
    self.p_rotation_x *= k
    self.p_rotation_y *= k
    self.p_rotation_z *= k
  }
  self.degrees.val = to_degrees
}

///|
/// The current angle mode.
pub fn P5::get_angle_mode(self : P5) -> AngleMode {
  if self.degrees.val {
    Degrees
  } else {
    Radians
  }
}

///|
/// Prints a message to the browser console.
pub fn print(msg : String) -> Unit {
  @dom.console_log(msg)
}

///|
/// Sets the document title.
pub fn set_title(title : String) -> Unit {
  @dom.set_title(title)
}

///|
/// Saves the canvas as an image file (`png` by default, or `jpg`/`webp`).
pub fn P5::save_canvas(
  self : P5,
  filename~ : String = "untitled",
  ext~ : String = "png",
) -> Unit {
  guard self.canvas is Some(c) else { return }
  let mime = match ext {
    "jpg" | "jpeg" => "image/jpeg"
    "webp" => "image/webp"
    _ => "image/png"
  }
  @dom.download_url(@dom.to_data_url(c, mime), "\{filename}.\{ext}")
}
