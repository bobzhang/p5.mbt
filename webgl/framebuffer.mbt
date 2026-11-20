// p5.Framebuffer (src/webgl/p5.Framebuffer.js): an offscreen surface with
// color and depth textures, drawn into between begin() and end().

///|
/// An offscreen drawing surface that can be used as a texture.
pub struct Framebuffer {
  priv r : Renderer3D
  priv mut fbo : @gl.FBO
  /// Width in pixels (logical).
  mut width : Double
  /// Height in pixels (logical).
  mut height : Double
  mut density : Double
  priv mut auto_sized : Bool
  antialias : Bool
  priv samples : Int32
  priv use_depth : Bool
  priv use_stencil : Bool
  priv depth_float : Bool
  priv alpha : Bool
  priv linear : Bool
  /// The camera used while drawing into the framebuffer.
  default_camera : Camera
  priv mut prev : Framebuffer?
  priv mut clipped : Bool
}

///|
/// Options for `create_framebuffer`.
pub(all) struct FramebufferOptions {
  width : Double?
  height : Double?
  density : Double?
  /// Multisample count; `None` uses the canvas setting (2 when antialiased).
  antialias : Int32?
  depth : Bool
  stencil : Bool
  /// Float (true, p5's default) or unsigned-int depth.
  depth_float : Bool
  alpha : Bool?
  /// Linear (true) or nearest texture filtering.
  linear : Bool
}

///|
/// p5's defaults.
pub fn FramebufferOptions::default() -> FramebufferOptions {
  {
    width: None,
    height: None,
    density: None,
    antialias: None,
    depth: true,
    stencil: true,
    depth_float: true,
    alpha: None,
    linear: true,
  }
}

///|
fn fb_camera(w : Double, h : Double) -> Camera {
  let c = Camera::new(w, h)
  let c = { ..c, y_scale: -1.0, }
  c.perspective()
  c.camera()
  c.camera_type_default = true
  c
}

///|
fn Framebuffer::make_fbo(self : Framebuffer) -> @gl.FBO {
  @gl.create_fbo(
    self.r.gl,
    (self.width * self.density).to_int(),
    (self.height * self.density).to_int(),
    self.samples,
    self.use_depth,
    self.use_stencil,
    self.depth_float,
    self.alpha,
    self.linear,
    self.r.state.wrap_x,
    self.r.state.wrap_y,
  )
}

///|
/// Creates a framebuffer (`createFramebuffer`).
pub fn Renderer3D::create_framebuffer(
  self : Renderer3D,
  options : FramebufferOptions,
  default_antialias : Bool,
) -> Framebuffer {
  let samples = match options.antialias {
    Some(n) => n
    None => if default_antialias { 2 } else { 0 }
  }
  let samples = if @gl.version(self.gl) == 2 { samples } else { 0 }
  let (width, height, auto_sized) = match (options.width, options.height) {
    (Some(w), Some(h)) => (w, h, false)
    _ => (self.width, self.height, true)
  }
  let density = options.density.unwrap_or(self.density)
  let fb : Framebuffer = {
    r: self,
    fbo: @gl.create_fbo(
      self.gl,
      1,
      1,
      0,
      false,
      false,
      false,
      true,
      true,
      "clamp",
      "clamp",
    ),
    width,
    height,
    density,
    auto_sized,
    antialias: samples > 0,
    samples,
    use_depth: options.depth,
    use_stencil: options.depth && options.stencil,
    depth_float: options.depth_float,
    alpha: options.alpha.unwrap_or(true),
    linear: options.linear,
    default_camera: fb_camera(width, height),
    prev: None,
    clipped: false,
  }
  @gl.delete_fbo(fb.fbo)
  fb.fbo = fb.make_fbo()
  fb.draw(() => self.clear(0, 0, 0, 0))
  fb
}

///|
fn Framebuffer::resolve(self : Framebuffer, depth : Bool) -> Unit {
  @gl.fbo_resolve(
    self.fbo,
    depth,
    self.linear,
    self.r.active_fbs.last().map(f => f.fbo),
  )
}

///|
fn Framebuffer::recreate(self : Framebuffer) -> Unit {
  @gl.delete_fbo(self.fbo)
  self.fbo = self.make_fbo()
  self.default_camera.resize(self.width, self.height)
}

///|
/// Resizes the framebuffer (contents are cleared).
pub fn Framebuffer::resize(self : Framebuffer, w : Double, h : Double) -> Unit {
  self.auto_sized = false
  self.width = w
  self.height = h
  self.recreate()
}

///|
/// Sets the pixel density.
pub fn Framebuffer::pixel_density(self : Framebuffer, d : Double) -> Unit {
  self.auto_sized = false
  self.density = d
  self.recreate()
}

///|
/// Follows the canvas size when the canvas is resized.
pub fn Framebuffer::canvas_resized(self : Framebuffer) -> Unit {
  if self.auto_sized {
    self.width = self.r.width
    self.height = self.r.height
    self.density = self.r.density
    self.recreate()
  }
}

///|
fn Framebuffer::before_begin(self : Framebuffer) -> Unit {
  @gl.bind_fbo(self.r.gl, Some(self.fbo))
  @gl.viewport(
    self.r.gl,
    0,
    0,
    (self.width * self.density).to_int(),
    (self.height * self.density).to_int(),
  )
}

///|
fn Framebuffer::before_end(self : Framebuffer) -> Unit {
  if self.antialias {
    @gl.fbo_mark_dirty(self.fbo)
  }
}

///|
/// Starts drawing into the framebuffer.
pub fn Framebuffer::begin(self : Framebuffer) -> Unit {
  let r = self.r
  self.prev = r.active_fbs.last()
  if self.prev is Some(p) {
    p.before_end()
  }
  r.active_fbs.push(self)
  self.before_begin()
  r.push()
  r.state.camera = self.default_camera
  r.state.proj = self.default_camera.proj_matrix.copy()
  r.state.view = self.default_camera.camera_matrix.copy()
  r.reset_matrix()
  r.apply_stencil_if_clipping()
}

///|
/// Stops drawing into the framebuffer.
pub fn Framebuffer::end(self : Framebuffer) -> Unit {
  let r = self.r
  r.pop()
  ignore(r.active_fbs.pop())
  self.before_end()
  match self.prev {
    Some(p) => p.before_begin()
    None => {
      @gl.bind_fbo(r.gl, None)
      @gl.viewport(
        r.gl,
        0,
        0,
        @gl.drawing_buffer_width(r.gl),
        @gl.drawing_buffer_height(r.gl),
      )
    }
  }
  r.apply_stencil_if_clipping()
}

///|
/// Draws into the framebuffer with `f` between `begin()` and `end()`.
pub fn Framebuffer::draw(self : Framebuffer, f : () -> Unit) -> Unit {
  self.begin()
  f()
  self.end()
}

///|
/// The framebuffer as a texture source.
pub fn Framebuffer::source(self : Framebuffer) -> TexSource {
  { elt: None, fb: Some(self), width: self.width, height: self.height, }
}

///|
/// Reads the framebuffer's pixels (RGBA, top row first, device pixels).
pub fn Framebuffer::read_pixels(self : Framebuffer) -> FixedArray[Byte] {
  self.resolve(false)
  @gl.fbo_read_pixels(
    self.fbo,
    0,
    0,
    (self.width * self.density).to_int(),
    (self.height * self.density).to_int(),
    self.r.active_fbs.last().map(f => f.fbo),
  )
}

///|
/// Deletes the framebuffer's GL resources.
pub fn Framebuffer::remove(self : Framebuffer) -> Unit {
  @gl.delete_fbo(self.fbo)
}

///|
/// Whether the framebuffer follows the canvas size (`autoSized()`).
pub fn Framebuffer::auto_sized(self : Framebuffer) -> Bool {
  self.auto_sized
}

///|
/// Makes the framebuffer follow the canvas size, or keep its own
/// (`autoSized(bool)`); following resizes it to the canvas right away.
pub fn Framebuffer::set_auto_sized(self : Framebuffer, on : Bool) -> Unit {
  self.auto_sized = on
  self.canvas_resized()
}
