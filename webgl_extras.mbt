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

///|
/// Sets a custom per-vertex value for the vertices added after it in the
/// current shape (`vertexProperty`). Shaders read it as an attribute named
/// `name` with as many components as `data` has. Call it before the
/// shape's first vertex so every vertex gets a value.
pub fn P5::vertex_property(
  self : P5,
  name : String,
  data : ArrayView[Double],
) -> Unit {
  let value = FixedArray::from_array(data.to_array())
  match self.extras.vertex_props.search_by(vp => vp.0 == name) {
    Some(i) => self.extras.vertex_props[i] = (name, value)
    None => self.extras.vertex_props.push((name, value))
  }
}

///|
/// Creates a filter shader from a fragment shader alone
/// (`createFilterShader`): it reads the canvas from `tex0` at `vTexCoord`
/// and also gets `texelSize` and `canvasSize`. Apply it with
/// `filter_shader`.
pub fn P5::create_filter_shader(self : P5, frag : String) -> @webgl.Shader {
  ignore(self)
  @webgl.Shader::filter(frag)
}

///|
/// Runs a filter shader over the canvas (`filter(shader)`), in 2D or WEBGL.
pub fn P5::filter_shader(self : P5, s : @webgl.Shader) -> Unit {
  if self.gl is Some(r) {
    r.filter("", None, self.gl_style(), Some(s))
    return
  }
  if self.canvas is Some(c) {
    self.filter_webgl_2d(c, "", None, user=s)
  }
}

///|
/// Loads a vertex and a fragment shader file (`loadShader`). The shader is
/// returned right away and gets its sources when the files arrive; in
/// `preload`, `setup` waits for them.
pub fn P5::load_shader(
  self : P5,
  vert_url : String,
  frag_url : String,
  on_load? : (@webgl.Shader) -> Unit,
) -> @webgl.Shader {
  let s = @webgl.Shader::new("", "")
  let vert = Ref(None)
  let frag = Ref(None)
  let finish = () => {
    if vert.val is Some(v) && frag.val is Some(f) {
      s.set_sources(v, f)
      if on_load is Some(cb) {
        cb(s)
      }
    }
  }
  self.load_text(vert_url, on_load=t => {
    vert.val = Some(t)
    finish()
  })
  self.load_text(frag_url, on_load=t => {
    frag.val = Some(t)
    finish()
  })
  s
}

///|
/// Loads a filter shader's fragment source (`loadFilterShader` with GLSL).
pub fn P5::load_filter_shader(
  self : P5,
  frag_url : String,
  on_load? : (@webgl.Shader) -> Unit,
) -> @webgl.Shader {
  let s = @webgl.Shader::new("", "")
  self.load_text(frag_url, on_load=t => {
    s.set_sources(@webgl.filter_vertex_source(t), t)
    if on_load is Some(cb) {
      cb(s)
    }
  })
  s
}

///|
/// How a texture is sampled (p5's `NEAREST` and `LINEAR`).
#derive(Eq, Debug)
pub(all) enum TextureFilter {
  Nearest
  Linear
}

///|
/// Sets how an image is sampled as a texture when drawn smaller
/// (`downscale`) and larger (`upscale`): `Nearest` keeps pixels crisp,
/// `Linear` (default) smooths them (p5.Texture's `setInterpolation`).
pub fn[I : ImageSource] P5::texture_interpolation(
  self : P5,
  img : I,
  downscale : TextureFilter,
  upscale? : TextureFilter,
) -> Unit {
  guard self.gl_renderer("setInterpolation") is Some(r) else { return }
  guard tex_source(img) is Some(src) else { return }
  let name = (f : TextureFilter) => {
    if f is Nearest {
      "nearest"
    } else {
      "linear"
    }
  }
  r.texture_filter(src, name(downscale), name(upscale.unwrap_or(downscale)))
}

// ---- image lighting and texture maps ----

///|
/// Lights the scene with an image of its surroundings (`imageLight`); an
/// equirectangular 360° photo works best. Shiny materials reflect it. Like
/// other lights, call it every frame.
pub fn[I : ImageSource] P5::image_light(self : P5, img : I) -> Unit {
  guard self.gl_renderer("imageLight") is Some(r) else { return }
  guard tex_source(img) is Some(src) else { return }
  r.image_light(src)
}

///|
/// Draws a 360° equirectangular image as the background, as seen through
/// the camera (`panorama`). Call it at the start of `draw`.
pub fn[I : ImageSource] P5::panorama(self : P5, img : I) -> Unit {
  guard self.gl_renderer("panorama") is Some(r) else { return }
  guard tex_source(img) is Some(src) else { return }
  r.panorama(src, self.gl_style())
}

///|
fn[I : ImageSource] P5::set_texture_map(
  self : P5,
  which : @webgl.TextureMap,
  img : I?,
  scale~ : Double = 1,
  what : String,
) -> Unit {
  guard self.gl_renderer(what) is Some(r) else { return }
  let src = match img {
    Some(i) => tex_source(i)
    None => None
  }
  r.texture_map(which, src, scale~)
}

///|
/// Uses an image to scale the specular color across the surface
/// (`specularTexture`); also turns on the specular material. `None` clears.
pub fn[I : ImageSource] P5::specular_texture(self : P5, img : I?) -> Unit {
  self.set_texture_map(SpecularMap, img, "specularTexture")
  if img is Some(_) && self.gl is Some(r) {
    r.use_specular_material()
  }
}

///|
/// Uses an image as the ambient color across the surface
/// (`ambientTexture`). `None` clears.
pub fn[I : ImageSource] P5::ambient_texture(self : P5, img : I?) -> Unit {
  self.set_texture_map(AmbientMap, img, "ambientTexture")
  if img is Some(_) && self.gl is Some(r) {
    r.set_has_ambient()
  }
}

///|
/// Scales shininess across the surface by an image's red channel
/// (`shininessTexture`). `None` clears.
pub fn[I : ImageSource] P5::shininess_texture(self : P5, img : I?) -> Unit {
  self.set_texture_map(ShininessMap, img, "shininessTexture")
}

///|
/// Tilts the surface normals with a tangent-space normal map (the bluish
/// kind), `scale` setting its strength (`normalTexture`). `None` clears.
pub fn[I : ImageSource] P5::normal_texture(
  self : P5,
  img : I?,
  scale~ : Double = 1,
) -> Unit {
  self.set_texture_map(NormalMap, img, scale~, "normalTexture")
}

///|
/// Tilts the surface normals using an image's brightness as height
/// (`bumpTexture`). `None` clears.
pub fn[I : ImageSource] P5::bump_texture(
  self : P5,
  img : I?,
  scale~ : Double = 1,
) -> Unit {
  self.set_texture_map(BumpMap, img, scale~, "bumpTexture")
}

// ---- 3D text ----

///|
/// The outline of `s` as a flat 3D model, or, with `extrude`, a solid one
/// that thick (`font.textToModel`). Needs a WEBGL sketch. Points are
/// sampled like `text_to_contours`.
pub fn Font::text_to_model(
  self : Font,
  s : String,
  x : Double,
  y : Double,
  max_width? : Double,
  max_height? : Double,
  extrude~ : Double = 0,
  sample_factor~ : Double = 0.1,
  simplify_threshold~ : Double = 0,
) -> @webgl.Geometry {
  let p = self.sketch
  let contours = self.text_to_contours(
    s,
    x,
    y,
    max_width?,
    max_height?,
    sample_factor~,
    simplify_threshold~,
  )
  if contours.is_empty() {
    return @webgl.Geometry::new()
  }
  let built = p.build_geometry(() => {
    p.begin_shape()
    for c in contours {
      p.begin_contour()
      for pt in c {
        p.vertex(pt.x, pt.y)
      }
      p.end_contour(mode=Close)
    }
    p.end_shape(mode=Close)
  })
  guard built is Some(geom) else { return @webgl.Geometry::new() }
  if extrude == 0 {
    return geom
  }
  // merge vertices that coincide (to 6 decimals)
  let key = (v : @webgl.Vec3) => {
    let r = (d : Double) => (d * 1000000 + 0.5).floor()
    "\{r(v.x)}-\{r(v.y)}-\{r(v.z)}"
  }
  let index : Map[String, Int32] = Map([])
  let verts : Array[@webgl.Vec3] = []
  let remap : Array[Int32] = []
  for v in geom.vertices {
    let k = key(v)
    match index.get(k) {
      Some(i) => remap.push(i)
      None => {
        index[k] = verts.length()
        remap.push(verts.length())
        verts.push(v.copy())
      }
    }
  }
  let faces = geom.faces.map(f => (remap[f.0], remap[f.1], remap[f.2]))
  // edges used by one face only are the outline
  let seen : Map[String, Array[(Int32, Int32)]] = Map([])
  for f in faces {
    for e in [(f.0, f.1), (f.1, f.2), (f.2, f.0)] {
      let (a, b) = e
      let id = "\{a.min(b)}-\{a.max(b)}"
      match seen.get(id) {
        Some(list) => list.push(e)
        None => seen[id] = [e]
      }
    }
  }
  let out = @webgl.Geometry::new()
  let half = extrude * 0.5
  for _, list in seen {
    guard list.length() == 1 else { continue }
    let (a, b) = list[0]
    let va = verts[a]
    let vb = verts[b]
    let ex = vb.x - va.x
    let ey = vb.y - va.y
    let ez = vb.z - va.z
    // |edge × (0, 0, extrude)|
    let cx = ey * extrude
    let cy = -ex * extrude
    let cross = (cx * cx + cy * cy).sqrt()
    let dist = (ex * ex + ey * ey + ez * ez).sqrt()
    if cross < 0.0001 || dist < 0.0001 {
      continue
    }
    let fa = out.vertices.length()
    out.vertices.push(@webgl.Vec3::new(va.x, va.y, va.z + half))
    let fb = out.vertices.length()
    out.vertices.push(@webgl.Vec3::new(vb.x, vb.y, vb.z + half))
    let ba = out.vertices.length()
    out.vertices.push(@webgl.Vec3::new(va.x, va.y, va.z - half))
    let bb = out.vertices.length()
    out.vertices.push(@webgl.Vec3::new(vb.x, vb.y, vb.z - half))
    out.faces.push((fa, ba, bb))
    out.faces.push((fa, bb, fb))
    out.edges.push((fa, fb))
    out.edges.push((ba, bb))
    out.edges.push((fa, ba))
    out.edges.push((fb, bb))
  }
  let front = out.vertices.length()
  for v in verts {
    out.vertices.push(@webgl.Vec3::new(v.x, v.y, v.z + half))
  }
  for f in faces {
    let m = (f.0 + front, f.1 + front, f.2 + front)
    out.faces.push(m)
    out.edges.push((m.0, m.1))
    out.edges.push((m.1, m.2))
    out.edges.push((m.2, m.0))
  }
  let back = out.vertices.length()
  for v in verts {
    out.vertices.push(@webgl.Vec3::new(v.x, v.y, v.z - half))
  }
  for f in faces {
    let m = (f.2 + back, f.1 + back, f.0 + back)
    out.faces.push(m)
    out.edges.push((m.0, m.1))
    out.edges.push((m.1, m.2))
    out.edges.push((m.2, m.0))
  }
  out.compute_normals()
}

// ---- context attributes ----

///|
/// A WebGL context setting for `set_attributes`.
pub(all) enum GlAttribute {
  /// A transparent canvas background (default on).
  Alpha(Bool)
  /// A depth buffer (default on).
  Depth(Bool)
  /// A stencil buffer (default on).
  Stencil(Bool)
  /// Antialiased edges (default on only in Safari, like p5).
  Antialias(Bool)
  PremultipliedAlpha(Bool)
  /// Keep the canvas between frames (default on).
  PreserveDrawingBuffer(Bool)
  /// Per-pixel lighting (default on).
  PerPixelLighting(Bool)
  /// 2 for WebGL 2 when available (default), 1 for WebGL 1.
  Version(Int32)
}

///|
/// Changes WebGL context attributes (`setAttributes`). Call it in `setup`
/// right after `create_canvas`: the context is recreated, so GPU resources
/// made before are lost.
pub fn P5::set_attributes(self : P5, attrs : ArrayView[GlAttribute]) -> Unit {
  let a = self.extras.gl_attrs
  let mut changed = false
  for attr in attrs {
    match attr {
      Alpha(v) =>
        if a.alpha != v {
          a.alpha = v
          changed = true
        }
      Depth(v) =>
        if a.depth != v {
          a.depth = v
          changed = true
        }
      Stencil(v) =>
        if a.stencil != v {
          a.stencil = v
          changed = true
        }
      Antialias(v) =>
        if a.antialias != v {
          a.antialias = v
          changed = true
        }
      PremultipliedAlpha(v) =>
        if a.premultiplied_alpha != v {
          a.premultiplied_alpha = v
          changed = true
        }
      PreserveDrawingBuffer(v) =>
        if a.preserve_drawing_buffer != v {
          a.preserve_drawing_buffer = v
          changed = true
        }
      PerPixelLighting(v) => a.per_pixel_lighting = v
      Version(v) =>
        if a.version != v {
          a.version = v
          changed = true
        }
    }
  }
  if !changed {
    return
  }
  guard self.gl_canvas is Some(old) else { return }
  let c = @dom.replace_canvas(old, self.width, self.height, self.density)
  @dom.detach_node(@dom.canvas_element(old))
  self.init_gl_context(c, self.width, self.height)
}
