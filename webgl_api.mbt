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
  let gl = @gl.create_context(
    c,
    true,
    true,
    true,
    @gl.default_antialias(),
    true,
    true,
  )
  self.gl = Some(@webgl.Renderer3D::new(gl, w, h, self.density))
  self.gl_canvas = Some(c)
}

///|
fn rgba01(c : Color) -> FixedArray[Double] {
  let (r, g, b, a) = c.to_srgb()
  [r, g, b, a]
}

///|
fn P5::gl_style(self : P5) -> @webgl.Style {
  let st = self.state
  let erasing = st.erasing
  let fill : FixedArray[Double]? = match st.fill {
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
pub fn P5::model(self : P5, g : @webgl.Geometry, count~ : Int32 = 1) -> Unit {
  guard self.gl_renderer("model") is Some(r) else { return }
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
  let extra = FixedArray::make(@webgl.extra_size, 0.0)
  extra[@webgl.extra_u] = u
  extra[@webgl.extra_u + 1] = v
  let (nx, ny, nz) = self.gl_normal
  extra[@webgl.extra_normal] = nx
  extra[@webgl.extra_normal + 1] = ny
  extra[@webgl.extra_normal + 2] = nz
  if self.state.fill is Some(c) {
    let a = rgba01(c)
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
