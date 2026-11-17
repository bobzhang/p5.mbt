// The WEBGL renderer: p5.Renderer3D + p5.RendererGL drawing geometry with
// p5's default shaders, uniforms, buffers and blending.

///|
/// Fill/stroke style passed in from the sketch for each draw.
pub(all) struct Style {
  /// Fill RGBA in [0, 1], or `None` for `no_fill()`.
  fill : FixedArray[Double]?
  /// Stroke RGBA in [0, 1], or `None` for `no_stroke()`.
  stroke : FixedArray[Double]?
  stroke_weight : Double
  /// 0 round, 1 project, 2 square.
  stroke_cap : Int32
  /// 0 round, 1 miter, 2 bevel.
  stroke_join : Int32
  /// p5 blend mode name ("blend", "add", ...).
  blend_mode : String
  erasing : Bool
}

///|
/// Renderer state saved by `push()`/`pop()` (p5's `states`).
pub struct GLState {
  mut model : @math.Matrix
  mut view : @math.Matrix
  mut proj : @math.Matrix
  mut camera : Camera
  mut normal_material : Bool
  mut enable_lighting : Bool
  mut ambient_light_colors : Array[Double]
  mut specular_colors : Array[Double]
  mut directional_directions : Array[Double]
  mut directional_diffuse : Array[Double]
  mut directional_specular : Array[Double]
  mut point_positions : Array[Double]
  mut point_diffuse : Array[Double]
  mut point_specular : Array[Double]
  mut spot_positions : Array[Double]
  mut spot_directions : Array[Double]
  mut spot_diffuse : Array[Double]
  mut spot_specular : Array[Double]
  mut spot_angle : Array[Double]
  mut spot_conc : Array[Double]
  mut constant_attenuation : Double
  mut linear_attenuation : Double
  mut quadratic_attenuation : Double
  mut ambient_color : FixedArray[Double]
  mut specular_color : FixedArray[Double]
  mut emissive_color : FixedArray[Double]
  mut has_set_ambient : Bool
  mut use_specular : Bool
  mut use_emissive : Bool
  mut shininess : Double
  mut metalness : Double
  mut tint : FixedArray[Double]
  mut fill_shader : Shader?
  mut stroke_shader : Shader?
  mut tex : TexSource?
  mut image_shader : Shader?
  mut texture_mode_normal : Bool
  mut wrap_x : String
  mut wrap_y : String
}

///|
fn GLState::copy(self : GLState) -> GLState {
  { ..self, }
}

///|
priv struct GeomBuffers {
  geometry : Geometry
  index : @gl.Buffer?
  wide : Bool
  buffers : Map[String, @gl.Buffer]
  uploaded : Map[String, Bool]
}

///|
/// The WEBGL renderer of a sketch.
pub struct Renderer3D {
  gl : @gl.GL
  mut width : Double
  mut height : Double
  mut density : Double
  mut state : GLState
  priv stack : Array[GLState]
  priv shaders : Map[String, Shader]
  priv cache : Map[String, GeomBuffers]
  priv mut empty : @gl.Texture?
  priv mut blending : Bool
  priv mut cached_blend : String
  main_camera : Camera
  priv immediate : Geometry
  priv mut drawing_image : Bool
  priv active_fbs : Array[Framebuffer]
  priv mut builder : GeometryBuilder?
  priv font_infos : Map[String, FontInfo]
  priv filter_shaders : Map[String, Shader]
  priv mut filter_layer : Framebuffer?
  priv mut filter_layer_temp : Framebuffer?
  priv mut drawing_filter : Bool
  /// The canvas element (for using the canvas as a texture).
  canvas : @dom.ImageElement
  /// Whether the context is antialiased (framebuffer default).
  antialias : Bool
  priv mut user_sampler : Bool
  /// Points per unit length when sampling curves (`curveDetail`, 1/4).
  mut curve_detail : Double
  simple_lines : Bool
}

///|
fn default_state(cam : Camera) -> GLState {
  {
    model: @math.Matrix::new(4),
    view: cam.camera_matrix.copy(),
    proj: cam.proj_matrix.copy(),
    camera: cam,
    normal_material: false,
    enable_lighting: false,
    ambient_light_colors: [],
    specular_colors: [1, 1, 1],
    directional_directions: [],
    directional_diffuse: [],
    directional_specular: [],
    point_positions: [],
    point_diffuse: [],
    point_specular: [],
    spot_positions: [],
    spot_directions: [],
    spot_diffuse: [],
    spot_specular: [],
    spot_angle: [],
    spot_conc: [],
    constant_attenuation: 1,
    linear_attenuation: 0,
    quadratic_attenuation: 0,
    ambient_color: [1, 1, 1, 1],
    specular_color: [0, 0, 0, 0],
    emissive_color: [0, 0, 0, 0],
    has_set_ambient: false,
    use_specular: false,
    use_emissive: false,
    shininess: 1,
    metalness: 0,
    tint: [255, 255, 255, 255],
    fill_shader: None,
    stroke_shader: None,
    tex: None,
    image_shader: None,
    texture_mode_normal: false,
    wrap_x: "clamp",
    wrap_y: "clamp",
  }
}

///|
/// A renderer drawing into `gl` for a `width × height` canvas.
pub fn Renderer3D::new(
  gl : @gl.GL,
  canvas : @dom.ImageElement,
  antialias : Bool,
  width : Double,
  height : Double,
  density : Double,
) -> Renderer3D {
  let cam = Camera::new(width, height)
  {
    gl,
    width,
    height,
    density,
    state: default_state(cam),
    stack: [],
    shaders: Map([]),
    cache: Map([]),
    empty: None,
    blending: false,
    cached_blend: "",
    main_camera: cam,
    immediate: { ..Geometry::new(), gid: "__IMMEDIATE_MODE_GEOMETRY__", },
    drawing_image: false,
    active_fbs: [],
    builder: None,
    font_infos: Map([]),
    filter_shaders: Map([]),
    filter_layer: None,
    filter_layer_temp: None,
    drawing_filter: false,
    canvas,
    antialias,
    user_sampler: false,
    curve_detail: 0.25,
    simple_lines: false,
  }
}

///|
/// Saves the renderer state (`push()`).
pub fn Renderer3D::push(self : Renderer3D) -> Unit {
  self.stack.push(self.state.copy())
}

///|
/// Restores the renderer state (`pop()`).
pub fn Renderer3D::pop(self : Renderer3D) -> Unit {
  if self.stack.pop() is Some(s) {
    self.state = s
  }
}

///|
/// Per-frame reset before `draw()` (p5's `_update`).
pub fn Renderer3D::update(self : Renderer3D) -> Unit {
  let s = self.state
  s.model = @math.Matrix::new(4)
  s.view = s.camera.camera_matrix.copy()
  s.ambient_light_colors = []
  s.specular_colors = [1, 1, 1]
  s.directional_directions = []
  s.directional_diffuse = []
  s.directional_specular = []
  s.point_positions = []
  s.point_diffuse = []
  s.point_specular = []
  s.spot_positions = []
  s.spot_directions = []
  s.spot_diffuse = []
  s.spot_specular = []
  s.spot_angle = []
  s.spot_conc = []
  s.enable_lighting = false
  s.tint = [255, 255, 255, 255]
  @gl.reset_depth_stencil(self.gl)
}

///|
/// Clears to a color with components in [0, 1] (`clear(r, g, b, a)`).
pub fn Renderer3D::clear(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  let a = match self.active_fbs.last() {
    Some(fb) if !fb.antialias && a == 0 => 1.0e-10
    _ => a
  }
  @gl.clear(self.gl, r * a, g * a, b * a, a)
}

///|
/// Clears the depth buffer.
pub fn Renderer3D::clear_depth(self : Renderer3D, depth~ : Double = 1) -> Unit {
  @gl.clear_depth(self.gl, depth)
}

///|
/// Resizes the drawing buffer's viewport and the default camera.
pub fn Renderer3D::resize(
  self : Renderer3D,
  w : Double,
  h : Double,
  density : Double,
) -> Unit {
  self.width = w
  self.height = h
  self.density = density
  @gl.viewport(
    self.gl,
    0,
    0,
    @gl.drawing_buffer_width(self.gl),
    @gl.drawing_buffer_height(self.gl),
  )
  self.main_camera.resize(w, h)
  if !physical_equal(self.state.camera, self.main_camera) {
    self.state.camera.resize(w, h)
  }
  self.state.proj = self.state.camera.proj_matrix.copy()
}

// ---- transforms ----

///|
fn GLState::own_model(self : GLState) -> @math.Matrix {
  self.model = self.model.copy()
  self.model
}

///|
pub fn Renderer3D::translate(
  self : Renderer3D,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  ignore(self.state.own_model().translate(x, y, z))
}

///|
pub fn Renderer3D::scale(
  self : Renderer3D,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  ignore(self.state.own_model().scale(x, y, z))
}

///|
/// Rotates by `angle` radians about `(x, y, z)`.
pub fn Renderer3D::rotate(
  self : Renderer3D,
  angle : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  ignore(self.state.own_model().rotate(angle, x, y, z))
}

///|
/// Multiplies the model matrix by 16 column-major entries (`applyMatrix`).
pub fn Renderer3D::apply_matrix(
  self : Renderer3D,
  m : ArrayView[Double],
) -> Unit {
  ignore(self.state.own_model().apply(m))
}

///|
pub fn Renderer3D::reset_matrix(self : Renderer3D) -> Unit {
  self.state.model = @math.Matrix::new(4)
  self.state.view = self.state.camera.camera_matrix.copy()
}

///|
/// The current model matrix.
pub fn Renderer3D::model_matrix(self : Renderer3D) -> @math.Matrix {
  self.state.model
}

// ---- cameras ----

///|
fn Renderer3D::own_camera(self : Renderer3D) -> Camera {
  let c = self.state.camera.copy()
  self.state.camera = c
  c
}

///|
pub fn Renderer3D::perspective(
  self : Renderer3D,
  fovy? : Double,
  aspect? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  let c = self.own_camera()
  c.perspective(fovy?, aspect?, near?, far?)
  self.state.proj = c.proj_matrix.copy()
}

///|
pub fn Renderer3D::ortho(
  self : Renderer3D,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  let c = self.own_camera()
  c.ortho(left?, right?, bottom?, top?, near?, far?)
  self.state.proj = c.proj_matrix.copy()
}

///|
pub fn Renderer3D::frustum(
  self : Renderer3D,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  let c = self.own_camera()
  c.frustum(left?, right?, bottom?, top?, near?, far?)
  self.state.proj = c.proj_matrix.copy()
}

///|
pub fn Renderer3D::camera(
  self : Renderer3D,
  eye? : (Double, Double, Double),
  center? : (Double, Double, Double),
  up? : (Double, Double, Double),
) -> Unit {
  let c = self.own_camera()
  c.camera(eye?, center?, up?)
  self.state.view = c.camera_matrix.copy()
}

///|
/// Turns line perspective (strokes thinning with distance) on or off.
pub fn Renderer3D::line_perspective(self : Renderer3D, on : Bool) -> Unit {
  self.own_camera().use_line_perspective = on
}

///|
/// A new camera with the default settings (`createCamera`).
pub fn Renderer3D::create_camera(self : Renderer3D) -> Camera {
  Camera::new(self.width, self.height)
}

///|
/// Makes `cam` the active camera (`setCamera`).
pub fn Renderer3D::set_camera(self : Renderer3D, cam : Camera) -> Unit {
  self.state.camera = cam
  self.state.proj = cam.proj_matrix.copy()
  self.state.view = cam.camera_matrix.copy()
}

///|
/// The active camera.
pub fn Renderer3D::current_camera(self : Renderer3D) -> Camera {
  self.state.camera
}

///|
/// After changing the active camera in place, re-reads its matrices.
pub fn Renderer3D::sync_camera(self : Renderer3D) -> Unit {
  self.state.proj = self.state.camera.proj_matrix.copy()
  self.state.view = self.state.camera.camera_matrix.copy()
}

// ---- materials ----

///|
/// An image source used as a texture: the element and its logical size.
pub(all) struct TexSource {
  /// The image, canvas or video element (`None` for a framebuffer).
  elt : @dom.ImageElement?
  /// The framebuffer, when texturing with one.
  fb : Framebuffer?
  width : Double
  height : Double
}

///|
/// Called by the sketch's `fill()`: back to a plain fill color.
pub fn Renderer3D::on_fill(self : Renderer3D) -> Unit {
  self.state.normal_material = false
  self.state.tex = None
}

///|
/// Textures subsequent shapes (`texture()`).
pub fn Renderer3D::texture(self : Renderer3D, src : TexSource) -> Unit {
  self.state.normal_material = false
  self.state.tex = Some(src)
}

///|
/// Texture coordinates in pixels (`IMAGE`, false) or in [0, 1] (`NORMAL`).
pub fn Renderer3D::texture_mode(self : Renderer3D, normal : Bool) -> Unit {
  self.state.texture_mode_normal = normal
}

///|
/// Wrap modes: "clamp", "repeat" or "mirror".
pub fn Renderer3D::texture_wrap(
  self : Renderer3D,
  x : String,
  y : String,
) -> Unit {
  self.state.wrap_x = x
  self.state.wrap_y = y
  @gl.set_all_wrap(self.gl, x, y)
}

///|
fn Renderer3D::gl_texture(self : Renderer3D, src : TexSource) -> @gl.Texture {
  match (src.fb, src.elt) {
    (Some(fb), _) =>
      // sampling the framebuffer being drawn into reads nothing (p5 binds
      // the empty texture) unless it is antialiased
      if !fb.antialias &&
        self.active_fbs.last() is Some(a) &&
        physical_equal(a, fb) {
        self.empty_texture()
      } else {
        fb.resolve(false)
        @gl.fbo_texture(fb.fbo, false)
      }
    (None, Some(elt)) =>
      @gl.texture_for(
        self.gl,
        elt,
        self.state.wrap_x,
        self.state.wrap_y,
        "linear",
      )
    (None, None) => self.empty_texture()
  }
}

///|
/// Sets a user fill shader (`shader()`), or `None` (`resetShader()`).
pub fn Renderer3D::set_fill_shader(self : Renderer3D, s : Shader?) -> Unit {
  self.state.fill_shader = s
}

///|
pub fn Renderer3D::set_stroke_shader(self : Renderer3D, s : Shader?) -> Unit {
  self.state.stroke_shader = s
}

// ---- drawing ----

///|
fn Renderer3D::shader(self : Renderer3D, kind : String) -> Shader {
  match self.shaders.get(kind) {
    Some(s) => s
    None => {
      let s = default_shader(@gl.version(self.gl) == 2, kind)
      self.shaders[kind] = s
      s
    }
  }
}

///|
fn Renderer3D::empty_texture(self : Renderer3D) -> @gl.Texture {
  match self.empty {
    Some(t) => t
    None => {
      let t = @gl.create_white_texture(self.gl)
      self.empty = Some(t)
      t
    }
  }
}

///|
fn Renderer3D::cached(self : Renderer3D, g : Geometry) -> GeomBuffers {
  match self.cache.get(g.gid) {
    Some(b) if physical_equal(b.geometry, g) => b
    old => {
      if old is Some(b) {
        self.free(b)
      }
      let (index, wide) = if g.faces.is_empty() {
        (None, false)
      } else {
        let flat = FixedArray::make(g.faces.length() * 3, 0)
        let mut wide = false
        for i, f in g.faces {
          flat[i * 3] = f.0
          flat[i * 3 + 1] = f.1
          flat[i * 3 + 2] = f.2
          if f.0 > 65535 || f.1 > 65535 || f.2 > 65535 {
            wide = true
          }
        }
        let b = @gl.create_buffer(self.gl)
        @gl.index_buffer_data(self.gl, b, flat, wide)
        (Some(b), wide)
      }
      let b = { geometry: g, index, wide, buffers: Map([]), uploaded: Map([]), }
      self.cache[g.gid] = b
      g.dirty = false
      b
    }
  }
}

///|
fn Renderer3D::free(self : Renderer3D, b : GeomBuffers) -> Unit {
  if b.index is Some(i) {
    @gl.delete_buffer(self.gl, i)
  }
  for _, buf in b.buffers {
    @gl.delete_buffer(self.gl, buf)
  }
}

///|
/// Releases the GPU buffers of a geometry (`freeGeometry`).
pub fn Renderer3D::free_geometry(self : Renderer3D, g : Geometry) -> Unit {
  if self.cache.get(g.gid) is Some(b) {
    self.free(b)
    self.cache.remove(g.gid)
  }
}

///|
/// Whether a geometry with this id is cached (`geometryInHash`).
pub fn Renderer3D::has_geometry(self : Renderer3D, gid : String) -> Bool {
  self.cache.contains(gid)
}

///|
/// The cached geometry with this id.
pub fn Renderer3D::geometry(self : Renderer3D, gid : String) -> Geometry? {
  self.cache.get(gid).map(b => b.geometry)
}

///|
fn flat3(vs : Array[Vec3]) -> FixedArray[Double] {
  let out = FixedArray::make(vs.length() * 3, 0.0)
  for i, v in vs {
    out[i * 3] = v.x
    out[i * 3 + 1] = v.y
    out[i * 3 + 2] = v.z
  }
  out
}

///|
fn Renderer3D::prepare(
  self : Renderer3D,
  b : GeomBuffers,
  p : @gl.Program,
  attr : String,
  key : String,
  size : Int32,
  data : () -> FixedArray[Double],
  len : Int32,
  dirty : Bool,
) -> Unit {
  let loc = @gl.attribute_location(p, attr)
  if loc < 0 {
    return
  }
  if len > 0 {
    let buf = match b.buffers.get(key) {
      Some(buf) => buf
      None => {
        let buf = @gl.create_buffer(self.gl)
        b.buffers[key] = buf
        buf
      }
    }
    if dirty || !b.uploaded.contains(key) {
      @gl.array_buffer_data(self.gl, buf, data())
      b.uploaded[key] = true
    }
    @gl.attrib_pointer(self.gl, buf, loc, size)
  } else {
    @gl.disable_attrib(self.gl, loc)
  }
}

///|
fn floats(a : Array[Double]) -> FixedArray[Double] {
  FixedArray::from_array(a)
}

///|
fn Renderer3D::set_global_uniforms(self : Renderer3D, p : @gl.Program) -> Unit {
  let s = self.state
  let mv = s.model.copy().mult(s.view)
  @gl.set_uniform(p, "uPerspective", [
    if s.camera.use_line_perspective {
      1
    } else {
      0
    },
  ])
  @gl.set_uniform_floats(p, "uViewMatrix", s.view.floats())
  @gl.set_uniform_floats(p, "uProjectionMatrix", s.proj.floats())
  @gl.set_uniform_floats(p, "uModelMatrix", s.model.floats())
  @gl.set_uniform_floats(p, "uModelViewMatrix", mv.floats())
  if @gl.has_uniform(p, "uModelViewProjectionMatrix") {
    @gl.set_uniform_floats(
      p,
      "uModelViewProjectionMatrix",
      mv.copy().mult(s.proj).floats(),
    )
  }
  let m3 = @math.Matrix::new(3)
  if @gl.has_uniform(p, "uNormalMatrix") {
    @gl.set_uniform_floats(
      p,
      "uNormalMatrix",
      m3.inverse_transpose4x4(mv).floats(),
    )
  }
  if @gl.has_uniform(p, "uModelNormalMatrix") {
    @gl.set_uniform_floats(
      p,
      "uModelNormalMatrix",
      m3.inverse_transpose4x4(s.model).floats(),
    )
  }
  if @gl.has_uniform(p, "uCameraNormalMatrix") {
    @gl.set_uniform_floats(
      p,
      "uCameraNormalMatrix",
      m3.inverse_transpose4x4(s.view).floats(),
    )
  }
  @gl.set_uniform(p, "uViewport", [
    0,
    0,
    @gl.drawing_buffer_width(self.gl).to_double(),
    @gl.drawing_buffer_height(self.gl).to_double(),
  ])
}

///|
fn bool_u(b : Bool) -> FixedArray[Double] {
  [if b { 1 } else { 0 }]
}

///|
fn Renderer3D::set_fill_uniforms(
  self : Renderer3D,
  p : @gl.Program,
  fill : FixedArray[Double],
  use_vertex_color : Bool,
) -> Unit {
  let s = self.state
  let specular = if s.metalness > 0 {
    FixedArray::makei(4, i => {
      fill[i] * s.metalness + s.specular_color[i] * (1 - s.metalness)
    })
  } else {
    s.specular_color.copy()
  }
  let empty = self.empty_texture()
  @gl.set_uniform(p, "uUseVertexColor", bool_u(use_vertex_color))
  @gl.set_uniform(p, "uMaterialColor", fill)
  @gl.set_uniform(p, "isTexture", bool_u(s.tex is Some(_)))
  match s.tex {
    Some(t) => @gl.set_uniform_texture(p, "uSampler", self.gl_texture(t))
    None =>
      if !self.user_sampler {
        @gl.set_uniform_texture(p, "uSampler", empty)
      }
  }
  @gl.set_uniform(p, "uTint", s.tint)
  @gl.set_uniform(p, "uHasSetAmbient", bool_u(s.has_set_ambient))
  @gl.set_uniform(p, "uAmbientMatColor", s.ambient_color)
  @gl.set_uniform(p, "uSpecularMatColor", specular)
  @gl.set_uniform(p, "uEmissiveMatColor", s.emissive_color)
  @gl.set_uniform(p, "uSpecular", bool_u(s.use_specular))
  @gl.set_uniform(p, "uEmissive", bool_u(s.use_emissive))
  @gl.set_uniform(p, "uShininess", [s.shininess])
  @gl.set_uniform(p, "uMetallic", [s.metalness])
  @gl.set_uniform(p, "uUseImageLight", bool_u(false))
  @gl.set_uniform_texture(p, "environmentMapDiffused", empty)
  @gl.set_uniform_texture(p, "environmentMapSpecular", empty)
  @gl.set_uniform(p, "uUseLighting", bool_u(s.enable_lighting))
  @gl.set_uniform(p, "uPointLightCount", [
    s.point_diffuse.length().to_double() / 3,
  ])
  @gl.set_uniform(p, "uPointLightLocation", floats(s.point_positions))
  @gl.set_uniform(p, "uPointLightDiffuseColors", floats(s.point_diffuse))
  @gl.set_uniform(p, "uPointLightSpecularColors", floats(s.point_specular))
  @gl.set_uniform(p, "uDirectionalLightCount", [
    s.directional_diffuse.length().to_double() / 3,
  ])
  @gl.set_uniform(p, "uLightingDirection", floats(s.directional_directions))
  @gl.set_uniform(p, "uDirectionalDiffuseColors", floats(s.directional_diffuse))
  @gl.set_uniform(
    p,
    "uDirectionalSpecularColors",
    floats(s.directional_specular),
  )
  let mixed : FixedArray[Double] = [0, 0, 0]
  for i = 0; i < s.ambient_light_colors.length(); i = i + 3 {
    for off in 0..<3 {
      if s.metalness > 0 {
        mixed[off] += (s.ambient_light_colors[i + off] - s.metalness).max(0)
      } else {
        mixed[off] += s.ambient_light_colors[i + off]
      }
    }
  }
  @gl.set_uniform(p, "uAmbientColor", mixed)
  @gl.set_uniform(p, "uSpotLightCount", [
    s.spot_diffuse.length().to_double() / 3,
  ])
  @gl.set_uniform(p, "uSpotLightAngle", floats(s.spot_angle))
  @gl.set_uniform(p, "uSpotLightConc", floats(s.spot_conc))
  @gl.set_uniform(p, "uSpotLightDiffuseColors", floats(s.spot_diffuse))
  @gl.set_uniform(p, "uSpotLightSpecularColors", floats(s.spot_specular))
  @gl.set_uniform(p, "uSpotLightLocation", floats(s.spot_positions))
  @gl.set_uniform(p, "uSpotLightDirection", floats(s.spot_directions))
  @gl.set_uniform(p, "uConstantAttenuation", [s.constant_attenuation])
  @gl.set_uniform(p, "uLinearAttenuation", [s.linear_attenuation])
  @gl.set_uniform(p, "uQuadraticAttenuation", [s.quadratic_attenuation])
}

///|
fn Renderer3D::apply_color_blend(
  self : Renderer3D,
  style : Style,
  alpha : Double,
  transparency : Bool,
) -> Unit {
  let s = self.state
  let do_blend = transparency ||
    s.tex is Some(_) ||
    s.fill_shader is Some(_) ||
    s.stroke_shader is Some(_) ||
    style.blend_mode != "blend" ||
    alpha < 1.0 ||
    style.erasing
  if do_blend != self.blending {
    @gl.set_blending(
      self.gl,
      do_blend || (style.blend_mode != "blend" && style.blend_mode != "add"),
    )
    self.blending = do_blend
  }
  let mode = if style.erasing { "remove" } else { style.blend_mode }
  if mode != self.cached_blend {
    @gl.apply_blend_mode(self.gl, mode)
    self.cached_blend = mode
  }
}

///|
fn Renderer3D::fill_shader_for(self : Renderer3D) -> Shader {
  let s = self.state
  if self.drawing_image {
    return match s.image_shader {
      Some(sh) => sh
      None => self.shader("light")
    }
  }
  match s.fill_shader {
    Some(sh) => sh
    None =>
      if s.normal_material {
        self.shader("normal")
      } else if s.enable_lighting || s.tex is Some(_) {
        self.shader("light")
      } else {
        self.shader("color")
      }
  }
}

///|
/// Draw modes for geometry without faces.
pub(all) enum DrawMode {
  Triangles
  TriangleStrip
  TriangleFan
}

///|
/// Draws a geometry with the current state (`_drawGeometry`).
pub fn Renderer3D::draw_geometry(
  self : Renderer3D,
  g : Geometry,
  style : Style,
  mode~ : DrawMode = Triangles,
  count~ : Int32 = 1,
  skip_fill~ : Bool = false,
) -> Unit {
  if self.builder is Some(_) {
    self.builder_add(g, g.faces, style)
    return
  }
  let b = self.cached(g)
  let dirty = g.dirty
  g.dirty = false
  if style.fill is Some(fill) && g.vertices.length() >= 3 && !skip_fill {
    self.draw_fills(b, fill, style, mode, count, dirty)
  }
  if style.stroke is Some(stroke) && g.line_vertices.length() >= 1 {
    self.draw_strokes(b, stroke, style, count, dirty)
  }
}

///|
fn Renderer3D::draw_fills(
  self : Renderer3D,
  b : GeomBuffers,
  fill : FixedArray[Double],
  style : Style,
  mode : DrawMode,
  count : Int32,
  dirty : Bool,
) -> Unit {
  let g = b.geometry
  let use_vertex_color = g.vertex_colors.length() > 0
  let sh = self.fill_shader_for()
  sh.kind = "fill"
  guard sh.init(self.gl) is Some(p) else { return }
  @gl.use_program(p)
  self.user_sampler = self.apply_user_uniforms(sh, p)
  self.set_global_uniforms(p)
  self.set_fill_uniforms(p, fill, use_vertex_color)
  @gl.bind_textures(p, self.empty_texture())
  self.prepare(
    b,
    p,
    "aPosition",
    "vertex",
    3,
    () => flat3(g.vertices),
    g.vertices.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aNormal",
    "normal",
    3,
    () => flat3(g.vertex_normals),
    g.vertex_normals.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aVertexColor",
    "color",
    4,
    () => floats(g.vertex_colors),
    g.vertex_colors.length(),
    dirty,
  )
  self.prepare(b, p, "aAmbientColor", "ambient", 3, () => [], 0, dirty)
  self.prepare(
    b,
    p,
    "aTexCoord",
    "uv",
    2,
    () => floats(g.uvs),
    g.uvs.length(),
    dirty,
  )
  self.prepare(b, p, "aTangent", "tangent", 4, () => [], 0, dirty)
  @gl.disable_other_attribs(p)
  self.apply_color_blend(style, fill[3], g.has_fill_transparency())
  match b.index {
    Some(index) =>
      @gl.draw_elements(self.gl, index, g.faces.length() * 3, b.wide, count)
    None =>
      @gl.draw_arrays(
        self.gl,
        match mode {
          Triangles => 0
          TriangleStrip => 1
          TriangleFan => 2
        },
        g.vertices.length(),
        count,
      )
  }
}

///|
fn Renderer3D::draw_strokes(
  self : Renderer3D,
  b : GeomBuffers,
  stroke : FixedArray[Double],
  style : Style,
  count : Int32,
  dirty : Bool,
) -> Unit {
  let g = b.geometry
  let sh = match self.state.stroke_shader {
    Some(s) => s
    None => self.shader("line")
  }
  sh.kind = "stroke"
  guard sh.init(self.gl) is Some(p) else { return }
  @gl.use_program(p)
  ignore(self.apply_user_uniforms(sh, p))
  self.set_global_uniforms(p)
  @gl.set_uniform(p, "uSimpleLines", bool_u(self.simple_lines))
  @gl.set_uniform(
    p,
    "uUseLineColor",
    bool_u(g.vertex_stroke_colors.length() > 0),
  )
  @gl.set_uniform(p, "uMaterialColor", stroke)
  @gl.set_uniform(p, "uStrokeWeight", [style.stroke_weight])
  @gl.set_uniform(p, "uStrokeCap", [style.stroke_cap.to_double()])
  @gl.set_uniform(p, "uStrokeJoin", [style.stroke_join.to_double()])
  @gl.bind_textures(p, self.empty_texture())
  self.prepare(
    b,
    p,
    "aVertexColor",
    "line_color",
    4,
    () => floats(g.line_vertex_colors),
    g.line_vertex_colors.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aPosition",
    "line_vertex",
    3,
    () => floats(g.line_vertices),
    g.line_vertices.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aTangentIn",
    "tangent_in",
    3,
    () => floats(g.line_tangents_in),
    g.line_tangents_in.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aTangentOut",
    "tangent_out",
    3,
    () => floats(g.line_tangents_out),
    g.line_tangents_out.length(),
    dirty,
  )
  self.prepare(
    b,
    p,
    "aSide",
    "side",
    1,
    () => floats(g.line_sides),
    g.line_sides.length(),
    dirty,
  )
  @gl.disable_other_attribs(p)
  self.apply_color_blend(style, stroke[3], g.has_stroke_transparency())
  @gl.draw_arrays(self.gl, 0, g.line_vertices.length() / 3, count)
}

///|
/// Draws a cached unit geometry scaled by `(sx, sy, sz)` (`_drawGeometryScaled`).
pub fn Renderer3D::draw_scaled(
  self : Renderer3D,
  g : Geometry,
  sx : Double,
  sy : Double,
  sz : Double,
  style : Style,
) -> Unit {
  let original = self.state.model
  self.state.model = original.copy().scale(sx, sy, sz)
  self.draw_geometry(g, style)
  self.state.model = original
}

///|
/// The cached geometry `gid`, building it with `make` the first time.
pub fn Renderer3D::cached_geometry(
  self : Renderer3D,
  gid : String,
  make : () -> Geometry,
) -> Geometry {
  match self.geometry(gid) {
    Some(g) => g
    None => {
      let g = make()
      g.gid = gid
      ignore(self.cached(g))
      g
    }
  }
}

///|
/// Reads RGBA pixels (top row first) from the drawing buffer.
pub fn Renderer3D::read_pixels(
  self : Renderer3D,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> FixedArray[Byte] {
  @gl.read_pixels(self.gl, x, y, w, h)
}

///|
/// Draws a shape given as vertex lists (`drawShape` with the
/// ShapeBuilder): PATH shapes are tessellated; strokes follow the edges.
pub fn Renderer3D::draw_shape(
  self : Renderer3D,
  kind : @shape.ShapeKind,
  contours : Array[Array[@shape.Pt]],
  style : Style,
  count~ : Int32 = 1,
) -> Unit {
  if contours.is_empty() {
    return
  }
  let g = self.immediate
  let building = self.builder is Some(_)
  let mode = build_immediate(
    g,
    kind,
    contours,
    style.fill is Some(_),
    style.stroke is Some(_),
    self.simple_lines,
    building~,
  )
  if building {
    self.builder_add(g, immediate_faces(g, mode, style.fill is Some(_)), style)
    return
  }
  if !self.state.texture_mode_normal &&
    self.state.tex is Some(t) &&
    t.width > 0 &&
    t.height > 0 {
    for i in 0..<g.uvs.length() {
      g.uvs[i] = if i % 2 == 0 {
        g.uvs[i] / t.width
      } else {
        g.uvs[i] / t.height
      }
    }
  }
  let (draw_mode, skip_fill) = match mode {
    TriangleFanMode => (TriangleFan, false)
    TriangleStripMode | PathMode => (TriangleStrip, false)
    LinesMode | PointsMode => (Triangles, true)
    _ => (Triangles, false)
  }
  self.draw_geometry(g, style, mode=draw_mode, count~, skip_fill~)
}

///|
/// Sets how many points per unit length curves are sampled with.
pub fn Renderer3D::set_curve_detail(self : Renderer3D, d : Double) -> Unit {
  self.curve_detail = d
}

///|
/// Replaces the model matrix.
pub fn Renderer3D::set_model_matrix(
  self : Renderer3D,
  m : @math.Matrix,
) -> Unit {
  self.state.model = m
}

///|
fn Renderer3D::apply_user_uniforms(
  self : Renderer3D,
  sh : Shader,
  p : @gl.Program,
) -> Bool {
  let mut sampler = false
  for name, v in sh.uniforms {
    match v {
      Floats(data) => @gl.set_uniform(p, name, data)
      Tex(src) => {
        @gl.set_uniform_texture(p, name, self.gl_texture(src))
        if name == "uSampler" {
          sampler = true
        }
      }
    }
  }
  sampler
}

///|
/// Draws an image source into the rectangle `(dx, dy, dw, dh)` taking the
/// region `(sx, sy, sw, sh)` (`image()` in WEBGL): a textured quad.
pub fn Renderer3D::image(
  self : Renderer3D,
  src : TexSource,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
  style : Style,
) -> Unit {
  self.push()
  self.no_lights()
  self.texture(src)
  self.state.texture_mode_normal = true
  let u0 = if sx <= src.width { sx / src.width } else { 0.0 }
  let u1 = if sx + sw <= src.width { (sx + sw) / src.width } else { 1.0 }
  let v0 = if sy <= src.height { sy / src.height } else { 0.0 }
  let v1 = if sy + sh <= src.height { (sy + sh) / src.height } else { 1.0 }
  self.drawing_image = true
  let shape = @shape.Shape::new()
  shape.begin_shape()
  let white : FixedArray[Double] = [1, 1, 1, 1]
  let pt = (x : Double, y : Double, u : Double, v : Double) => {
    let extra = FixedArray::make(extra_size, 0.0)
    extra[extra_u] = u
    extra[extra_u + 1] = v
    extra[extra_normal + 2] = 1
    for k in 0..<4 {
      extra[extra_fill + k] = white[k]
    }
    ({ x, y, z: 0.0, extra, } : @shape.Pt)
  }
  shape.vertex_pt(pt(dx, dy, u0, v0))
  shape.vertex_pt(pt(dx + dw, dy, u1, v0))
  shape.vertex_pt(pt(dx + dw, dy + dh, u1, v1))
  shape.vertex_pt(pt(dx, dy + dh, u0, v1))
  shape.end_shape(mode=Close)
  let blend = if style.erasing { { ..style, erasing: false, } } else { style }
  self.draw_shape(
    shape.first_contour_kind(),
    shape.to_vertices(curve_detail=self.curve_detail),
    { ..blend, fill: Some(white), stroke: None, },
  )
  self.drawing_image = false
  self.pop()
}

///|
/// Sets a user shader for `image()` (`imageShader`), or `None`.
pub fn Renderer3D::set_image_shader(self : Renderer3D, s : Shader?) -> Unit {
  self.state.image_shader = s
}

///|
/// Called when a user fill shader is set (`shader()` turns off
/// `normalMaterial`).
pub fn Renderer3D::on_shader(self : Renderer3D) -> Unit {
  self.state.normal_material = false
}

///|
/// One of p5's default shaders: "color", "normal", "light" or "line".
pub fn Renderer3D::base_shader(self : Renderer3D, kind : String) -> Shader {
  self.shader(kind)
}
