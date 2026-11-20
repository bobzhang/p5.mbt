// More of p5's WEBGL API: instancing, stroke mode, debug mode, camera roll
// and renderer information.

///|
/// Draws everything `f` draws `count` times in one call each, for shaders
/// that place copies using `gl_InstanceID` (`instances(count).sphere()` in
/// p5.js). Needs WebGL 2.
pub fn P5::instances(self : P5, count : Int32, f : () -> Unit) -> Unit {
  guard self.gl_renderer("instances") is Some(r) else { return }
  let count = if count < 1 { 1 } else { count }
  let prev = r.instance_count
  r.set_instance_count(count)
  f()
  r.set_instance_count(prev)
}

///|
/// How WEBGL strokes are drawn: `Full` (default) with caps and joins, or
/// `Simple`, faster plain lines.
#derive(Eq, Debug)
pub(all) enum StrokeMode {
  Simple
  Full
}

///|
/// Sets how strokes are drawn in WEBGL.
pub fn P5::stroke_mode(self : P5, mode : StrokeMode) -> Unit {
  guard self.gl_renderer("strokeMode") is Some(r) else { return }
  r.set_simple_lines(mode is Simple)
}

///|
/// The current stroke mode.
pub fn P5::get_stroke_mode(self : P5) -> StrokeMode {
  match self.gl {
    Some(r) if r.simple_lines => Simple
    _ => Full
  }
}

///|
/// `"webgl2"` or `"webgl"` for a WEBGL canvas, `"p2d"` otherwise (p5's
/// `webglVersion`).
pub fn P5::webgl_version(self : P5) -> String {
  match self.gl {
    Some(r) => if @gl.version(r.gl) == 2 { "webgl2" } else { "webgl" }
    None => "p2d"
  }
}

///|
/// Rotates the active camera about its viewing direction (the current
/// angle mode applies).
pub fn P5::roll(self : P5, angle : Double) -> Unit {
  guard self.gl_renderer("roll") is Some(r) else { return }
  let cam = r.current_camera()
  cam.roll(self.to_radians(angle))
  r.sync_camera()
}

///|
/// What `debug_mode` shows.
#derive(Eq, Debug)
pub(all) enum DebugMode {
  /// A grid on the ground plane.
  Grid
  /// An icon of the x (red), y (green) and z (blue) axes.
  Axes
  /// Both.
  GridAndAxes
}

///|
/// Draws a ground grid and/or an axes icon after every frame, to help find
/// your way in 3D. Defaults follow p5: a grid of `width / 2` with a
/// division every ~30 units, and an axes icon of `max(width / 20, 40)` at
/// `-width / 4` on all axes.
pub fn P5::debug_mode(
  self : P5,
  mode~ : DebugMode = GridAndAxes,
  grid_size? : Double,
  grid_divisions? : Int32,
  grid_offset~ : (Double, Double, Double) = (0, 0, 0),
  axes_size? : Double,
  axes_offset? : (Double, Double, Double),
) -> Unit {
  guard self.gl_renderer("debugMode") is Some(_) else { return }
  self.extras.debug_grid = None
  self.extras.debug_axes = None
  if mode is (Grid | GridAndAxes) {
    let size = grid_size.unwrap_or(self.width / 2)
    let divs = match grid_divisions {
      Some(d) => d
      None => {
        let d = (size / 30 + 0.5).floor().to_int()
        if d < 4 {
          4
        } else {
          d
        }
      }
    }
    let (x, y, z) = grid_offset
    self.extras.debug_grid = Some((size, divs, x, y, z))
  }
  if mode is (Axes | GridAndAxes) {
    let size = axes_size.unwrap_or(
      if self.width / 20 > 40 {
        self.width / 20
      } else {
        40
      },
    )
    let (x, y, z) = match axes_offset {
      Some(o) => o
      None => (-self.width / 4, -self.width / 4, -self.width / 4)
    }
    self.extras.debug_axes = Some((size, x, y, z))
  }
}

///|
/// Turns `debug_mode` off.
pub fn P5::no_debug_mode(self : P5) -> Unit {
  self.extras.debug_grid = None
  self.extras.debug_axes = None
}

///|
fn P5::debug_line(
  self : P5,
  x1 : Double,
  y1 : Double,
  z1 : Double,
  x2 : Double,
  y2 : Double,
  z2 : Double,
) -> Unit {
  self.begin_shape(kind=Lines)
  self.vertex(x1, y1, z=z1)
  self.vertex(x2, y2, z=z2)
  self.end_shape()
}

///|
/// Draws the `debug_mode` helpers (p5's post-draw `_grid` and `_axesIcon`).
fn P5::draw_debug_mode(self : P5) -> Unit {
  guard self.gl is Some(r) else { return }
  if self.extras.debug_grid is Some((size, divs, x, y, z)) {
    let stroke = match self.state.stroke {
      Some(c) => c
      None => Color::rgb(0, 0, 0)
    }
    self.push()
    self.stroke(stroke)
    r.set_model_matrix(@math.Matrix::new(4))
    let spacing = size / divs.to_double()
    let half = size / 2
    for q in 0..<=divs {
      let d = q.to_double() * spacing - half
      self.debug_line(-half + x, y, d + z, half + x, y, d + z)
    }
    for i in 0..<=divs {
      let d = i.to_double() * spacing - half
      self.debug_line(d + x, y, -half + z, d + x, y, half + z)
    }
    self.pop()
  }
  if self.extras.debug_axes is Some((size, x, y, z)) {
    self.push()
    r.set_model_matrix(@math.Matrix::new(4))
    self.stroke_weight(2)
    self.stroke((255, 0, 0))
    self.debug_line(x, y, z, x + size, y, z)
    self.stroke((0, 255, 0))
    self.debug_line(x, y, z, x, y + size, z)
    self.stroke((0, 0, 255))
    self.debug_line(x, y, z, x, y, z + size)
    self.pop()
  }
}
