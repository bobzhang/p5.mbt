// WEBGL mode: createCanvas(w, h, WEBGL), 3D primitives, cameras, lights and
// materials (p5.js src/webgl). Drawing goes to a `@webgl.Renderer3D`.

///|
/// The renderer of the main canvas.
pub(all) enum RendererKind {
  /// The 2D canvas renderer.
  P2D
  /// The WebGL renderer (3D).
  WebGL
}

///|
/// A camera created with `create_camera`.
pub type Camera = @webgl.Camera

///|
/// A mesh (p5.Geometry).
pub type Geometry = @webgl.Geometry

///|
fn P5::gl_renderer(self : P5, what : String) -> @webgl.Renderer3D? {
  match self.gl {
    Some(r) => Some(r)
    None => {
      warn(
        "\{what}() is only supported in WEBGL mode. Use create_canvas(w, h, renderer=WebGL).",
      )
      None
    }
  }
}

///|
/// Whether the sketch draws with WebGL.
pub fn P5::is_webgl(self : P5) -> Bool {
  self.gl is Some(_)
}

///|
/// Switches the main canvas to a WebGL context of `w × h` (the 2D canvas
/// is kept hidden for measuring text, like p5's text canvas).
fn P5::create_webgl_canvas(self : P5, w : Double, h : Double) -> Unit {
  guard self.canvas is Some(old) else {
    warn("WEBGL mode needs a browser canvas")
    return
  }
  let c = @dom.replace_canvas(old, w, h, self.density)
  self.init_gl_context(c, w, h)
}

///|
fn P5::init_gl_context(self : P5, c : @dom.Canvas, w : Double, h : Double) -> Unit {
  let a = self.extras.gl_attrs
  let gl = @gl.create_context(
    c,
    a.alpha,
    a.depth,
    a.stencil,
    a.antialias,
    a.premultiplied_alpha,
    a.preserve_drawing_buffer,
    version=a.version,
  )
  self.gl = Some(
    @webgl.Renderer3D::new(
      gl,
      @dom.canvas_as_image(c),
      a.antialias,
      w,
      h,
      self.density,
    ),
  )
  self.gl_canvas = Some(c)
  if self.is_main {
    self.install_canvas_events(c)
  }
}

///|
fn rgba01(c : Color) -> FixedArray[Double] {
  let (r, g, b, a) = c.to_srgb()
  [r, g, b, a]
}

///|
fn P5::gl_style(self : P5) -> @webgl.Style {
  self.gl_sync_tint()
  let st = self.state
  let erasing = st.erasing
  let fill : FixedArray[Double]? = match st.fill {
    Some(_) if self.gl_fill_override is Some(o) && !erasing => Some(o)
    Some(c) =>
      Some(
        if erasing {
          ([1.0, 1, 1, self.erase_strength.0 / 255] : FixedArray[Double])
        } else {
          rgba01(c)
        },
      )
    None => None
  }
  let stroke : FixedArray[Double]? = match st.stroke {
    Some(c) =>
      Some(
        if erasing {
          ([1.0, 1, 1, self.erase_strength.1 / 255] : FixedArray[Double])
        } else {
          rgba01(c)
        },
      )
    None => None
  }
  let blend = match st.blend_mode {
    Blend => "blend"
    Remove => "remove"
    Add => "add"
    Darkest => "darkest"
    Lightest => "lightest"
    Exclusion => "exclusion"
    Multiply => "multiply"
    Screen => "screen"
    Replace => "replace"
    _ => "blend"
  }
  {
    fill,
    stroke,
    stroke_weight: st.stroke_weight,
    stroke_cap: self.gl_cap,
    stroke_join: self.gl_join,
    blend_mode: blend,
    erasing,
  }
}

// ---- 3D primitives ----

///|
fn P5::draw_unit(
  self : P5,
  gid : String,
  make : () -> @webgl.Geometry,
  sx : Double,
  sy : Double,
  sz : Double,
  what : String,
) -> Unit {
  guard self.gl_renderer(what) is Some(r) else { return }
  let g = r.cached_geometry(gid, make)
  r.draw_scaled(g, sx, sy, sz, self.gl_style())
}

///|
/// A plane of `w × h` (default 50 × `w`) centered at the origin.
pub fn P5::plane(
  self : P5,
  w~ : Double = 50,
  h? : Double,
  detail_x~ : Int32 = 1,
  detail_y~ : Int32 = 1,
) -> Unit {
  let h = h.unwrap_or(w)
  self.draw_unit(
    "plane|\{detail_x}|\{detail_y}",
    () => @webgl.plane_geometry(detail_x, detail_y),
    w,
    h,
    1,
    "plane",
  )
}

///|
/// A box of `w × h × d` (default 50; `h` defaults to `w`, `d` to `h`).
pub fn P5::box(
  self : P5,
  w~ : Double = 50,
  h? : Double,
  d? : Double,
  detail_x~ : Int32 = 4,
  detail_y~ : Int32 = 4,
) -> Unit {
  let h = h.unwrap_or(w)
  let d = d.unwrap_or(h)
  self.draw_unit(
    "box|\{detail_x}|\{detail_y}",
    () => @webgl.box_geometry(detail_x, detail_y),
    w,
    h,
    d,
    "box",
  )
}

///|
/// A sphere of radius `r` (default 50).
pub fn P5::sphere(
  self : P5,
  r~ : Double = 50,
  detail_x~ : Int32 = 24,
  detail_y~ : Int32 = 16,
) -> Unit {
  self.ellipsoid(rx=r, ry=r, rz=r, detail_x~, detail_y~)
}

///|
/// An ellipsoid with radii `rx`, `ry`, `rz` (`ry` and `rz` default to `rx`).
pub fn P5::ellipsoid(
  self : P5,
  rx~ : Double = 50,
  ry? : Double,
  rz? : Double,
  detail_x~ : Int32 = 24,
  detail_y~ : Int32 = 16,
) -> Unit {
  let ry = ry.unwrap_or(rx)
  let rz = rz.unwrap_or(rx)
  self.draw_unit(
    "ellipsoid|\{detail_x}|\{detail_y}",
    () => @webgl.ellipsoid_geometry(detail_x, detail_y),
    rx,
    ry,
    rz,
    "ellipsoid",
  )
}

///|
/// A cylinder of radius `r` and height `h` (defaults 50 and `r`).
pub fn P5::cylinder(
  self : P5,
  r~ : Double = 50,
  h? : Double,
  detail_x~ : Int32 = 24,
  detail_y~ : Int32 = 1,
  bottom_cap~ : Bool = true,
  top_cap~ : Bool = true,
) -> Unit {
  let h = h.unwrap_or(r)
  self.draw_unit(
    "cylinder|\{detail_x}|\{detail_y}|\{bottom_cap}|\{top_cap}",
    () => @webgl.cylinder_geometry(detail_x, detail_y, bottom_cap, top_cap),
    r,
    h,
    r,
    "cylinder",
  )
}

///|
/// A cone of base radius `r` and height `h` (defaults 50 and `r`).
pub fn P5::cone(
  self : P5,
  r~ : Double = 50,
  h? : Double,
  detail_x~ : Int32 = 24,
  detail_y~ : Int32 = 1,
  cap~ : Bool = true,
) -> Unit {
  let h = h.unwrap_or(r)
  self.draw_unit(
    "cone|\{detail_x}|\{detail_y}|\{cap}",
    () => @webgl.cone_geometry(detail_x, detail_y, cap),
    r,
    h,
    r,
    "cone",
  )
}

///|
/// A torus of ring radius `r` (default 50) and tube radius `tube` (10).
pub fn P5::torus(
  self : P5,
  r~ : Double = 50,
  tube~ : Double = 10,
  detail_x~ : Int32 = 24,
  detail_y~ : Int32 = 16,
) -> Unit {
  if r == 0 || tube == 0 {
    return
  }
  let g = @webgl.torus_geometry(tube / r, detail_x, detail_y)
  guard self.gl_renderer("torus") is Some(rd) else { return }
  let g = rd.cached_geometry(g.gid, () => g)
  rd.draw_scaled(g, r, r, r, self.gl_style())
}

///|
/// Draws a geometry (`model()`).
pub fn P5::model(self : P5, g : @webgl.Geometry, count? : Int32) -> Unit {
  guard self.gl_renderer("model") is Some(r) else { return }
  let count = count.unwrap_or(r.instance_count)
  if g.vertices.length() > 0 {
    if !r.has_geometry(g.gid) {
      ignore(g.edges_to_vertices(simple_lines=r.simple_lines))
    }
    r.draw_geometry(g, self.gl_style(), count~)
  }
}

///|
/// Frees the GPU buffers of a geometry.
pub fn P5::free_geometry(self : P5, g : @webgl.Geometry) -> Unit {
  if self.gl is Some(r) {
    r.free_geometry(g)
  }
}

// ---- transforms in 3D ----

///|
/// Rotates about the x-axis (WEBGL).
pub fn P5::rotate_x(self : P5, angle : Double) -> Unit {
  if self.gl_renderer("rotate_x") is Some(r) {
    r.rotate(self.to_radians(angle), 1, 0, 0)
  }
}

///|
/// Rotates about the y-axis (WEBGL).
pub fn P5::rotate_y(self : P5, angle : Double) -> Unit {
  if self.gl_renderer("rotate_y") is Some(r) {
    r.rotate(self.to_radians(angle), 0, 1, 0)
  }
}

///|
/// Rotates about the z-axis.
pub fn P5::rotate_z(self : P5, angle : Double) -> Unit {
  match self.gl {
    Some(r) => r.rotate(self.to_radians(angle), 0, 0, 1)
    None => self.rotate(angle)
  }
}

///|
/// Rotates about an arbitrary axis (WEBGL).
pub fn P5::rotate_axis(
  self : P5,
  angle : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  if self.gl_renderer("rotate_axis") is Some(r) {
    r.rotate(self.to_radians(angle), x, y, z)
  }
}

///|
/// Applies a 4x4 matrix given as 16 column-major entries (WEBGL).
pub fn P5::apply_matrix4(self : P5, m : ArrayView[Double]) -> Unit {
  if self.gl_renderer("apply_matrix4") is Some(r) && m.length() == 16 {
    r.apply_matrix(m)
  }
}

// ---- cameras ----

///|
/// Sets a perspective projection (`fovy` in the current angle mode).
pub fn P5::perspective(
  self : P5,
  fovy? : Double,
  aspect? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  if self.gl_renderer("perspective") is Some(r) {
    let fovy = fovy.map(a => self.to_radians(a))
    r.perspective(fovy?, aspect?, near?, far?)
  }
}

///|
/// Sets an orthographic projection.
pub fn P5::ortho(
  self : P5,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  if self.gl_renderer("ortho") is Some(r) {
    r.ortho(left?, right?, bottom?, top?, near?, far?)
  }
}

///|
/// Sets a frustum projection.
pub fn P5::frustum(
  self : P5,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  if self.gl_renderer("frustum") is Some(r) {
    r.frustum(left?, right?, bottom?, top?, near?, far?)
  }
}

///|
/// Positions the camera: eye, center (look-at point) and up vector. With
/// no arguments, the default camera.
pub fn P5::camera(
  self : P5,
  eye? : (Double, Double, Double),
  center? : (Double, Double, Double),
  up? : (Double, Double, Double),
) -> Unit {
  if self.gl_renderer("camera") is Some(r) {
    r.camera(eye?, center?, up?)
  }
}

///|
/// Whether strokes get thinner with distance (perspective lines).
pub fn P5::line_perspective(self : P5, on : Bool) -> Unit {
  if self.gl_renderer("line_perspective") is Some(r) {
    r.line_perspective(on)
  }
}

///|
/// A new camera with the default settings.
pub fn P5::create_camera(self : P5) -> @webgl.Camera? {
  self.gl_renderer("create_camera").map(r => r.create_camera())
}

///|
/// Makes `cam` the active camera.
pub fn P5::set_camera(self : P5, cam : @webgl.Camera) -> Unit {
  if self.gl_renderer("set_camera") is Some(r) {
    r.set_camera(cam)
  }
}

// ---- lights ----

///|
/// Adds ambient light.
pub fn[C : ColorArg] P5::ambient_light(self : P5, c : C) -> Unit {
  if self.gl_renderer("ambient_light") is Some(r) {
    let c = rgba01(c.to_color(self))
    r.ambient_light(c[0], c[1], c[2])
  }
}

///|
/// Sets the specular color of lights created afterwards.
pub fn[C : ColorArg] P5::specular_color(self : P5, c : C) -> Unit {
  if self.gl_renderer("specular_color") is Some(r) {
    let c = rgba01(c.to_color(self))
    r.specular_color(c[0], c[1], c[2])
  }
}

///|
/// Adds a directional light shining along `(x, y, z)`.
pub fn[C : ColorArg] P5::directional_light(
  self : P5,
  c : C,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  if self.gl_renderer("directional_light") is Some(r) {
    let c = rgba01(c.to_color(self))
    r.directional_light(c[0], c[1], c[2], x, y, z)
  }
}

///|
/// Adds a point light at `(x, y, z)`.
pub fn[C : ColorArg] P5::point_light(
  self : P5,
  c : C,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  if self.gl_renderer("point_light") is Some(r) {
    let c = rgba01(c.to_color(self))
    r.point_light(c[0], c[1], c[2], x, y, z)
  }
}

///|
/// Adds a spot light at `position` pointing along `direction`; `angle` in
/// the current angle mode (default π/3 radians).
pub fn[C : ColorArg] P5::spot_light(
  self : P5,
  c : C,
  position : (Double, Double, Double),
  direction : (Double, Double, Double),
  angle? : Double,
  concentration? : Double,
) -> Unit {
  if self.gl_renderer("spot_light") is Some(r) {
    let c = rgba01(c.to_color(self))
    let angle = match angle {
      Some(a) => self.to_radians(a)
      None => self.to_radians(self.from_radians(@math.PI / 3))
    }
    r.spot_light(c[0], c[1], c[2], position, direction, angle~, concentration?)
  }
}

///|
/// Default lighting: gray ambient plus a gray light from the front.
pub fn P5::lights(self : P5) -> Unit {
  if self.gl_renderer("lights") is Some(r) {
    r.lights()
  }
}

///|
/// Removes all lights.
pub fn P5::no_lights(self : P5) -> Unit {
  if self.gl_renderer("no_lights") is Some(r) {
    r.no_lights()
  }
}

///|
/// Sets how point and spot lights fade with distance.
pub fn P5::light_falloff(
  self : P5,
  constant : Double,
  linear : Double,
  quadratic : Double,
) -> Unit {
  if self.gl_renderer("light_falloff") is Some(r) {
    r.light_falloff(constant, linear, quadratic)
  }
}

// ---- materials ----

///|
/// Colors surfaces by their normals (x, y, z → red, green, blue).
pub fn P5::normal_material(self : P5) -> Unit {
  if self.gl_renderer("normal_material") is Some(r) {
    r.use_normal_material()
    self.state.fill = Some(Color::rgb(255, 255, 255))
    self.state.stroke = None
  }
}

///|
/// The color reflected from ambient light (also turns lighting on).
pub fn[C : ColorArg] P5::ambient_material(self : P5, c : C) -> Unit {
  if self.gl_renderer("ambient_material") is Some(r) {
    r.ambient_material(rgba01(c.to_color(self)))
    if self.state.fill is None {
      self.state.fill = Some(Color::rgb(255, 255, 255))
    }
  }
}

///|
/// A color the surface emits regardless of lights.
pub fn[C : ColorArg] P5::emissive_material(self : P5, c : C) -> Unit {
  if self.gl_renderer("emissive_material") is Some(r) {
    r.emissive_material(rgba01(c.to_color(self)))
  }
}

///|
/// The color of specular highlights.
pub fn[C : ColorArg] P5::specular_material(self : P5, c : C) -> Unit {
  if self.gl_renderer("specular_material") is Some(r) {
    r.specular_material(rgba01(c.to_color(self)))
  }
}

///|
/// How glossy specular highlights are (at least 1).
pub fn P5::shininess(self : P5, shine : Double) -> Unit {
  if self.gl_renderer("shininess") is Some(r) {
    r.shininess(shine)
  }
}

///|
/// How metallic the material looks.
pub fn P5::metalness(self : P5, metallic : Double) -> Unit {
  if self.gl_renderer("metalness") is Some(r) {
    r.metalness(metallic)
  }
}

// ---- 2D primitives and custom shapes in WEBGL ----

///|
/// A WEBGL shape vertex carrying the current normal, fill and stroke.
fn P5::gl_pt(
  self : P5,
  x : Double,
  y : Double,
  z : Double,
  u : Double,
  v : Double,
) -> @shape.Pt {
  let mut user = 0
  for vp in self.extras.vertex_props {
    user += vp.1.length()
  }
  let extra = FixedArray::make(@webgl.extra_size + user, 0.0)
  let mut off = @webgl.extra_size
  for vp in self.extras.vertex_props {
    for k in 0..<vp.1.length() {
      extra[off + k] = vp.1[k]
    }
    off += vp.1.length()
  }
  extra[@webgl.extra_u] = u
  extra[@webgl.extra_u + 1] = v
  let (nx, ny, nz) = self.gl_normal
  extra[@webgl.extra_normal] = nx
  extra[@webgl.extra_normal + 1] = ny
  extra[@webgl.extra_normal + 2] = nz
  if self.state.fill is Some(c) {
    let a = match self.gl_fill_override {
      Some(o) => o
      None => rgba01(c)
    }
    for k in 0..<4 {
      extra[@webgl.extra_fill + k] = a[k]
    }
  }
  if self.state.stroke is Some(c) {
    let a = rgba01(c)
    for k in 0..<4 {
      extra[@webgl.extra_stroke + k] = a[k]
    }
  }
  { x, y, z, extra, }
}

///|
/// Sets the normal of vertices added afterwards (WEBGL).
pub fn P5::normal(self : P5, x : Double, y : Double, z : Double) -> Unit {
  self.gl_normal = (x, y, z)
}

///|
/// Sets how finely curves are sampled in WEBGL (points per pixel of
/// length, default 1/4).
pub fn P5::curve_detail(self : P5, d : Double) -> Unit {
  if self.gl is Some(r) {
    r.set_curve_detail(d)
  }
}

///|
fn P5::gl_model_at(
  self : P5,
  g : @webgl.Geometry,
  m : (@math.Matrix) -> @math.Matrix,
) -> Unit {
  guard self.gl is Some(r) else { return }
  let saved = r.model_matrix()
  r.set_model_matrix(m(saved.copy()))
  r.draw_geometry(g, self.gl_style())
  r.set_model_matrix(saved)
}

///|
fn P5::gl_arc(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  start : Double,
  stop : Double,
  mode : String,
  detail : Int32,
) -> Unit {
  guard self.gl is Some(r) else { return }
  let gid = if (stop - start).abs() >= @math.TWO_PI {
    "ellipse|\{detail}|"
  } else {
    "arc|\{@webgl.js_string(start)}|\{@webgl.js_string(stop)}|\{mode}|\{detail}|"
  }
  let g = r.cached_geometry(gid, () => {
    @webgl.arc_geometry(start, stop, mode, detail)
  })
  self.gl_model_at(g, m => m.translate(x, y, 0).scale(w, h, 1))
}

///|
fn P5::gl_rect(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  radii : (Double, Double, Double, Double)?,
) -> Unit {
  guard self.gl is Some(r) else { return }
  match radii {
    None => {
      let g = r.cached_geometry("rect|1|1", () => @webgl.rect_geometry(1, 1))
      self.gl_model_at(g, m => m.translate(x, y, 0).scale(w, h, 1))
    }
    Some((tl, tr, br, bl)) => {
      let mut a = x
      let mut b = y
      let mut c = w + a
      let mut d = h + b
      if a > c {
        let t = a
        a = c
        c = t
      }
      if b > d {
        let t = b
        b = d
        d = t
      }
      let max_r = ((c - a) / 2).min((d - b) / 2)
      let tl = tl.min(max_r)
      let tr = tr.min(max_r)
      let br = br.min(max_r)
      let bl = bl.min(max_r)
      let (x1, y1, x2, y2) = (a, b, c, d)
      let rr = 0.5523
      let order = self.state.bezier_order
      self.state.bezier_order = 3
      self.begin_shape()
      let vx = (px : Double, py : Double) => {
        self.vertex(px, py, u=(px - x1) / w, v=(py - y1) / h)
      }
      let bv = (px : Double, py : Double) => {
        self.bezier_vertex(px, py, u=(px - x1) / w, v=(py - y1) / h)
      }
      if tr != 0 {
        vx(x2 - tr, y1)
        bv(x2 - tr + tr * rr, y1)
        bv(x2, y1 + tr - tr * rr)
        bv(x2, y1 + tr)
      } else {
        vx(x2, y1)
      }
      if br != 0 {
        vx(x2, y2 - br)
        bv(x2, y2 - br + br * rr)
        bv(x2 - br + rr * br, y2)
        bv(x2 - br, y2)
      } else {
        vx(x2, y2)
      }
      if bl != 0 {
        vx(x1 + bl, y2)
        bv(x1 + bl - bl * rr, y2)
        bv(x1, y2 - bl + bl * rr)
        bv(x1, y2 - bl)
      } else {
        vx(x1, y2)
      }
      if tl != 0 {
        vx(x1, y1 + tl)
        bv(x1, y1 + tl - tl * rr)
        bv(x1 + tl - tl * rr, y1)
        bv(x1 + tl, y1)
      } else {
        vx(x1, y1)
      }
      self.end_shape(mode=Close)
      self.state.bezier_order = order
    }
  }
}

///|
fn P5::gl_triangle(
  self : P5,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x3 : Double,
  y3 : Double,
) -> Unit {
  guard self.gl is Some(r) else { return }
  let g = r.cached_geometry("tri", () => @webgl.triangle_geometry())
  let o = x1 * y2 - x2 * y1 + x2 * y3 - x3 * y2 + x3 * y1 - x1 * y3
  let orientation = if o > 0 { 1.0 } else if o < 0 { -1.0 } else { o }
  self.gl_model_at(g, m => {
    @math.Matrix::from_array([
      x2 - x1,
      y2 - y1,
      0,
      0,
      x3 - x1,
      y3 - y1,
      0,
      0,
      0,
      0,
      orientation,
      0,
      x1,
      y1,
      0,
      1,
    ]).mult(m)
  })
}

///|
fn P5::gl_quad(
  self : P5,
  p1 : (Double, Double, Double),
  p2 : (Double, Double, Double),
  p3 : (Double, Double, Double),
  p4 : (Double, Double, Double),
  detail_x : Int32,
  detail_y : Int32,
) -> Unit {
  guard self.gl is Some(r) else { return }
  let n = (v : Double) => @webgl.js_string(v)
  let gid = "quad|\{n(p1.0)}|\{n(p1.1)}|\{n(p1.2)}|\{n(p2.0)}|\{n(p2.1)}|\{n(p2.2)}|\{n(p3.0)}|\{n(p3.1)}|\{n(p3.2)}|\{n(p4.0)}|\{n(p4.1)}|\{n(p4.2)}|\{detail_x}|\{detail_y}"
  let g = r.cached_geometry(gid, () => {
    @webgl.quad_geometry(p1, p2, p3, p4, detail_x, detail_y)
  })
  r.draw_geometry(g, self.gl_style())
}

// ---- textures and shaders ----

///|
/// How texture coordinates passed to `vertex()` are read.
pub(all) enum TextureMode {
  /// In pixels of the texture (default).
  Image
  /// In [0, 1].
  Normal
}

///|
/// How textures repeat outside [0, 1].
pub(all) enum TextureWrap {
  Clamp
  Repeat
  Mirror
}

///|
/// A shader program (p5.Shader).
pub type Shader = @webgl.Shader

///|
fn[I : ImageSource] tex_source(img : I) -> @webgl.TexSource? {
  img.gl_source()
}

///|
fn P5::gl_sync_tint(self : P5) -> Unit {
  if self.gl is Some(r) {
    r.set_tint(
      match self.state.tint {
        Some(c) => {
          let (red, g, b, a) = c.to_srgb()
          [red * 255, g * 255, b * 255, a * 255]
        }
        None => [255, 255, 255, 255]
      },
    )
  }
}

///|
/// Textures shapes drawn afterwards with an image, video or graphics.
pub fn[I : ImageSource] P5::texture(self : P5, img : I) -> Unit {
  guard self.gl_renderer("texture") is Some(r) else { return }
  img.advance(@dom.now())
  if tex_source(img) is Some(src) {
    r.texture(src)
    self.state.fill = Some(Color::rgb(255, 255, 255))
  }
}

///|
/// Sets how texture coordinates are read: in pixels (`Image`) or [0, 1].
pub fn P5::texture_mode(self : P5, mode : TextureMode) -> Unit {
  if self.gl_renderer("texture_mode") is Some(r) {
    r.texture_mode(mode is Normal)
  }
}

///|
/// Sets how textures wrap horizontally and vertically.
pub fn P5::texture_wrap(self : P5, x : TextureWrap, y? : TextureWrap) -> Unit {
  let name = (w : TextureWrap) => {
    match w {
      Clamp => "clamp"
      Repeat => "repeat"
      Mirror => "mirror"
    }
  }
  if self.gl_renderer("texture_wrap") is Some(r) {
    r.texture_wrap(name(x), name(y.unwrap_or(x)))
  }
}

///|
/// Creates a shader from GLSL vertex and fragment sources.
pub fn P5::create_shader(
  self : P5,
  vert : String,
  frag : String,
) -> @webgl.Shader {
  ignore(self)
  @webgl.Shader::new(vert, frag)
}

///|
/// Uses `s` to fill shapes drawn afterwards (`shader()`).
pub fn P5::shader(self : P5, s : @webgl.Shader) -> Unit {
  if self.gl_renderer("shader") is Some(r) {
    r.set_fill_shader(Some(s))
    r.on_shader()
  }
}

///|
/// Uses `s` to draw strokes (`strokeShader()`).
pub fn P5::stroke_shader(self : P5, s : @webgl.Shader) -> Unit {
  if self.gl_renderer("stroke_shader") is Some(r) {
    r.set_stroke_shader(Some(s))
  }
}

///|
/// Uses `s` to draw images (`imageShader()`).
pub fn P5::image_shader(self : P5, s : @webgl.Shader) -> Unit {
  if self.gl_renderer("image_shader") is Some(r) {
    r.set_image_shader(Some(s))
  }
}

///|
/// Back to the default shaders.
pub fn P5::reset_shader(self : P5) -> Unit {
  if self.gl is Some(r) {
    r.set_fill_shader(None)
    r.set_stroke_shader(None)
    r.set_image_shader(None)
  }
}

///|
/// p5's material shader (with lights), for `modify`.
pub fn P5::base_material_shader(self : P5) -> @webgl.Shader? {
  self.gl_renderer("base_material_shader").map(r => r.base_shader("light"))
}

///|
/// p5's flat color shader, for `modify`.
pub fn P5::base_color_shader(self : P5) -> @webgl.Shader? {
  self.gl_renderer("base_color_shader").map(r => r.base_shader("color"))
}

///|
/// p5's normal-colored shader, for `modify`.
pub fn P5::base_normal_shader(self : P5) -> @webgl.Shader? {
  self.gl_renderer("base_normal_shader").map(r => r.base_shader("normal"))
}

///|
/// p5's stroke shader, for `modify`.
pub fn P5::base_stroke_shader(self : P5) -> @webgl.Shader? {
  self.gl_renderer("base_stroke_shader").map(r => r.base_shader("line"))
}

///|
/// Sets a numeric uniform (scalar, vector, matrix or array).
pub fn P5::set_uniform(
  self : P5,
  s : @webgl.Shader,
  name : String,
  values : ArrayView[Double],
) -> Unit {
  ignore(self)
  s.set_uniform(name, Floats(FixedArray::from_array(values.to_owned())))
}

///|
/// Sets a sampler uniform to an image, video or graphics.
pub fn[I : ImageSource] P5::set_uniform_texture(
  self : P5,
  s : @webgl.Shader,
  name : String,
  img : I,
) -> Unit {
  ignore(self)
  if tex_source(img) is Some(src) {
    s.set_uniform(name, Tex(src))
  }
}

// ---- framebuffers ----

///|
/// An offscreen WEBGL surface (p5.Framebuffer).
pub type Framebuffer = @webgl.Framebuffer

///|
pub impl ImageSource for @webgl.Framebuffer with fn image_source(_self) {
  None
}

///|
pub impl ImageSource for @webgl.Framebuffer with fn gl_source(self) {
  Some(self.source())
}

///|
/// Creates a framebuffer. Without a size it follows the canvas.
pub fn P5::create_framebuffer(
  self : P5,
  width? : Double,
  height? : Double,
  density? : Double,
  antialias? : Int32,
  depth~ : Bool = true,
  stencil~ : Bool = true,
  depth_float~ : Bool = true,
  linear~ : Bool = true,
) -> @webgl.Framebuffer? {
  guard self.gl_renderer("create_framebuffer") is Some(r) else { return None }
  let fb = r.create_framebuffer(
    {
      width,
      height,
      density,
      antialias,
      depth,
      stencil,
      depth_float,
      alpha: None,
      linear,
    },
    @gl.default_antialias(),
  )
  self.framebuffers.push(fb)
  Some(fb)
}

// ---- buildGeometry ----

///|
/// Draws with `f` into a new geometry instead of the canvas
/// (`buildGeometry`): shapes and models drawn inside are merged, with
/// transforms applied. Vertices keep the fill set inside `f`; others use
/// the material color when the geometry is drawn.
pub fn P5::build_geometry(self : P5, f : () -> Unit) -> @webgl.Geometry? {
  guard self.gl_renderer("build_geometry") is Some(r) else { return None }
  let prev_fill = self.state.fill
  self.push()
  r.begin_geometry()
  self.state.fill = Some(Color::rgb(255, 255, 255))
  self.gl_fill_override = Some([-1, -1, -1, -1])
  f()
  self.gl_fill_override = None
  let g = r.end_geometry()
  self.pop()
  self.state.fill = prev_fill
  Some(g)
}

// ---- models ----

///|
/// Loads an OBJ or STL model. The returned geometry fills in when the file
/// has loaded (in `preload`, `setup` waits). `normalize` scales it to fit
/// 200 units around the origin.
pub fn P5::load_model(
  self : P5,
  path : String,
  normalize~ : Bool = false,
  flip_u~ : Bool = false,
  flip_v~ : Bool = false,
  on_load? : (@webgl.Geometry) -> Unit,
) -> @webgl.Geometry {
  let model = @webgl.Geometry::new()
  model.set_gid("\{path}|\{normalize}")
  let lower = path.to_lower()
  let finish = (parsed : @webgl.Geometry) => {
    if normalize {
      ignore(parsed.normalize())
    }
    if flip_u {
      parsed.flip_u()
    }
    if flip_v {
      parsed.flip_v()
    }
    ignore(parsed.make_triangle_edges())
    model.assign(parsed)
    if on_load is Some(f) {
      f(model)
    }
    self.end_load()
  }
  let failed = (msg : String) => {
    warn(msg)
    self.end_load()
  }
  self.begin_load()
  if lower.has_suffix(".stl") {
    @dom.fetch_bytes(path, bytes => finish(@webgl.parse_stl(bytes)), failed)
  } else {
    @dom.fetch_text(path, text => finish(@webgl.parse_obj(text)), failed)
  }
  model
}

///|
/// A model from OBJ text (`createModel`).
pub fn P5::create_model(
  self : P5,
  obj : String,
  normalize~ : Bool = false,
) -> @webgl.Geometry {
  ignore(self)
  let g = @webgl.parse_obj(obj)
  if normalize {
    ignore(g.normalize())
  }
  ignore(g.make_triangle_edges())
  g
}

// ---- orbitControl ----

///|
/// Lets the mouse (drag to rotate, right-drag to move, wheel to zoom) or
/// touches (one finger rotates, two pinch and move) control the camera,
/// with p5's damping. Call it in `draw()`.
pub fn P5::orbit_control(
  self : P5,
  sensitivity_x~ : Double = 1,
  sensitivity_y? : Double,
  sensitivity_z~ : Double = 1,
) -> Unit {
  guard self.gl_renderer("orbit_control") is Some(r) else { return }
  let sx = sensitivity_x
  let sy = sensitivity_y.unwrap_or(sx)
  let sz = sensitivity_z
  if self.gl_canvas is Some(c) {
    @dom.disable_canvas_gestures(c)
  }
  let cam = r.current_camera()
  let (zoom_v0, rot_x0, rot_y0, move_x0, move_y0, exec_zoom0, exec_rm0) = self.orbit
  let mut zoom_v = zoom_v0
  let mut rot_x = rot_x0
  let mut rot_y = rot_y0
  let mut move_x = move_x0
  let mut move_y = move_y0
  let mut exec_zoom = exec_zoom0
  let mut exec_rm = exec_rm0
  // touches that were also present last frame
  let moved : Array[(Double, Double, Double, Double)] = []
  for t in self.touches {
    for pt in self.prev_touches {
      if t.id == pt.id {
        moved.push((t.x, t.y, pt.x, pt.y))
      }
    }
  }
  self.prev_touches = self.touches.copy()
  let mut d_radius = 0.0
  let mut d_theta = 0.0
  let mut d_phi = 0.0
  let mut move_dx = 0.0
  let mut move_dy = 0.0
  let damping = 0.85
  let scale = if self.height < self.width { self.height } else { self.width }
  if moved.length() > 0 {
    let (x0, y0, _, _) = moved[0]
    let inside = x0 > 0 && x0 < self.width && y0 > 0 && y0 < self.height
    if moved.length() == 1 {
      let (x, y, px, py) = moved[0]
      d_theta = -sx * (x - px) / scale
      d_phi = sy * (y - py) / scale
    } else {
      let (ax, ay, apx, apy) = moved[0]
      let (bx, by, bpx, bpy) = moved[1]
      let dist = js_hypot2(ax - bx, ay - by)
      let prev = js_hypot2(apx - bpx, apy - bpy)
      d_radius = -(dist - prev) * sz * 0.0004
      move_dx = 0.5 * (ax + bx) - 0.5 * (apx + bpx)
      move_dy = 0.5 * (ay + by) - 0.5 * (apy + bpy)
    }
    if self.touches.length() > 0 {
      if inside {
        exec_rm = true
        exec_zoom = true
      }
    } else {
      exec_rm = false
      exec_zoom = false
    }
  } else {
    let inside = self.mouse_x > 0 &&
      self.mouse_x < self.width &&
      self.mouse_y > 0 &&
      self.mouse_y < self.height
    if self.wheel_delta_y != 0 {
      d_radius = (if self.wheel_delta_y > 0 { 1.0 } else { -1.0 }) * sz * 0.01
      self.wheel_delta_y = 0
      if inside {
        exec_zoom = true
      }
    } else {
      exec_zoom = false
    }
    if self.mouse_is_pressed {
      if self.mouse_button.left {
        d_theta = -sx * self.moved_x / scale
        d_phi = sy * self.moved_y / scale
      } else if self.mouse_button.right {
        move_dx = self.moved_x
        move_dy = self.moved_y * cam.y_scale
      }
      if inside {
        exec_rm = true
      }
    } else {
      exec_rm = false
    }
  }
  if d_radius != 0 && exec_zoom {
    zoom_v += d_radius
  }
  if zoom_v.abs() > 0.001 {
    cam.orbit(0, 0, zoom_v)
    cam.zoom_projection(js_pow10(-zoom_v))
    zoom_v *= damping
  } else {
    zoom_v = 0
  }
  if (d_theta != 0 || d_phi != 0) && exec_rm {
    rot_x += d_theta * 0.6
    rot_y += d_phi * 0.6
  }
  if rot_x * rot_x + rot_y * rot_y > 0.000001 {
    cam.orbit(rot_x, rot_y, 0)
    rot_x *= damping
    rot_y *= damping
  } else {
    rot_x = 0
    rot_y = 0
  }
  r.sync_camera()
  if (move_dx != 0 || move_dy != 0) && exec_rm {
    move_x += move_dx * 2 / self.width * 0.15
    move_y += -move_dy * 2 / self.height * 0.15
  }
  if move_x * move_x + move_y * move_y > 0.000001 {
    let ((lxx, lxy, lxz), (lyx, lyy, lyz), _) = cam.axes()
    let dxe = cam.eye_x - cam.center_x
    let dye = cam.eye_y - cam.center_y
    let dze = cam.eye_z - cam.center_z
    let view_z = (dxe * dxe + dye * dye + dze * dze).sqrt()
    let (cx, cy, cz, _) = cam.camera_matrix.multiply_vec4(
      cam.center_x,
      cam.center_y,
      cam.center_z,
      1,
    )
    let up = cam.proj_matrix
    let (px, py, _, pw) = up.multiply_vec4(cx, cy, cz, 1)
    let nx = px / pw - move_x
    let ny = py / pw - move_y
    let (dx, dy) = if up.get(15) == 0 {
      (
        (up.get(8) + nx) / up.get(0) * view_z,
        (up.get(9) + ny) / up.get(5) * view_z,
      )
    } else {
      ((nx - up.get(12)) / up.get(0), (ny - up.get(13)) / up.get(5))
    }
    cam.set_position(
      cam.eye_x + dx * lxx + dy * lyx,
      cam.eye_y + dx * lxy + dy * lyy,
      cam.eye_z + dx * lxz + dy * lyz,
    )
    r.sync_camera()
    move_x *= damping
    move_y *= damping
  } else {
    move_x = 0
    move_y = 0
  }
  self.orbit = (zoom_v, rot_x, rot_y, move_x, move_y, exec_zoom, exec_rm)
}

///|
extern "js" fn js_hypot2(x : Double, y : Double) -> Double = "Math.hypot"

///|
extern "js" fn js_pow10(x : Double) -> Double = "(x) => Math.pow(10, x)"

///|
/// Clears the depth buffer, so what is drawn next is not hidden by earlier
/// 3D shapes (`clearDepth`).
pub fn P5::clear_depth(self : P5, depth~ : Double = 1) -> Unit {
  if self.gl_renderer("clear_depth") is Some(r) {
    r.clear_depth(depth~)
  }
}
