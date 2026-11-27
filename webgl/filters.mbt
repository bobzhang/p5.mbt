// p5's shader filters (src/core/filterShaders.js): the GLSL p5.strands
// generates, run in WEBGL by Renderer3D.filter and for 2D canvases by
// FilterRenderer2D (src/image/filterRenderer2D.js).

///|
/// A built-in filter by p5 name ("gray", "invert", "threshold",
/// "posterize", "blur", "erode", "dilate", "opaque").
fn filter_shader(webgl2 : Bool, op : String) -> Shader? {
  let (v, f) = match op {
    "gray" => (filter_gray_vert, filter_gray_frag)
    "invert" => (filter_invert_vert, filter_invert_frag)
    "threshold" => (filter_threshold_vert, filter_threshold_frag)
    "posterize" => (filter_posterize_vert, filter_posterize_frag)
    "blur" => (filter_blur_vert, filter_blur_frag)
    "erode" => (filter_erode_vert, filter_erode_frag)
    "dilate" => (filter_dilate_vert, filter_dilate_frag)
    "opaque" => (filter_opaque_vert, filter_opaque_frag)
    _ => return None
  }
  Some(
    Shader::raw(
      compat_prefix(webgl2, true) + v,
      compat_prefix(webgl2, false) + f,
    ),
  )
}

///|
/// p5's `filterParamDefaults`.
pub fn filter_default_param(op : String) -> Double? {
  match op {
    "blur" => Some(3)
    "posterize" => Some(4)
    "threshold" => Some(0.5)
    _ => None
  }
}

// ---- WEBGL: Renderer3D.filter ----

///|
fn Renderer3D::filter_target_size(
  self : Renderer3D,
) -> (Double, Double, Double) {
  match self.active_fbs.last() {
    Some(fb) => (fb.width, fb.height, fb.density)
    None => (self.width, self.height, self.density)
  }
}

///|
fn Renderer3D::match_layer(
  self : Renderer3D,
  layer : Framebuffer?,
) -> Framebuffer {
  let (w, h, d) = self.filter_target_size()
  match layer {
    Some(fb) => {
      if fb.width != w || fb.height != h {
        fb.width = w
        fb.height = h
        fb.auto_sized = false
        fb.recreate()
      }
      if fb.density != d {
        fb.pixel_density(d)
      }
      fb
    }
    None => {
      let fb = self.create_framebuffer(
        FramebufferOptions::default(),
        self.antialias,
      )
      if fb.width != w || fb.height != h {
        fb.resize(w, h)
      }
      if fb.density != d {
        fb.pixel_density(d)
      }
      fb
    }
  }
}

///|
/// Applies a built-in filter to the canvas or active framebuffer (`filter()`
/// in WEBGL). `style` is the sketch's current style (its fill decides
/// whether the filter quad is drawn, as in p5).
pub fn Renderer3D::filter(
  self : Renderer3D,
  op : String,
  param : Double?,
  style : Style,
  user : Shader?,
) -> Unit {
  let param = match param {
    Some(p) => Some(p)
    None => filter_default_param(op)
  }
  let sh = match user {
    Some(s) => s
    None =>
      match self.filter_shaders.get(op) {
        Some(s) => s
        None =>
          match filter_shader(@gl.version(self.gl) == 2, op) {
            Some(s) => {
              self.filter_shaders[op] = s
              s
            }
            None => return
          }
      }
  }
  let target_fb = self.active_fbs.last()
  let target : TexSource = match target_fb {
    Some(fb) => fb.source()
    None =>
      {
        elt: Some(self.canvas),
        fb: None,
        width: self.width,
        height: self.height,
      }
  }
  let (tw, th, td) = self.filter_target_size()
  let fbo = self.match_layer(self.filter_layer)
  self.filter_layer = Some(fbo)
  fbo.draw(() => self.clear(0, 0, 0, 0))
  let texel = [1.0 / (tw * td), 1.0 / (th * td)]
  let pass_style = { ..style, stroke: None, blend_mode: "blend", }
  let quad = () => {
    self.no_lights()
    let g = self.cached_geometry("plane|1|1", () => plane_geometry(1, 1))
    self.draw_scaled(g, tw, th, 1, pass_style)
  }
  if op == "blur" && user is None {
    let tmp = self.match_layer(self.filter_layer_temp)
    self.filter_layer_temp = Some(tmp)
    self.push()
    self.set_fill_shader(Some(sh))
    sh.set_uniform("texelSize", Floats(FixedArray::from_array(texel)))
    sh.set_uniform("canvasSize", Floats([tw, th]))
    sh.set_uniform("radius", Floats([param.unwrap_or(3).max(1)]))
    tmp.draw(() => {
      sh.set_uniform("direction", Floats([1, 0]))
      sh.set_uniform("tex0", Tex(target))
      self.clear(0, 0, 0, 0)
      self.set_fill_shader(Some(sh))
      quad()
    })
    fbo.draw(() => {
      sh.set_uniform("direction", Floats([0, 1]))
      sh.set_uniform("tex0", Tex(tmp.source()))
      self.clear(0, 0, 0, 0)
      self.set_fill_shader(Some(sh))
      quad()
    })
    self.pop()
  } else {
    fbo.draw(() => {
      self.set_fill_shader(Some(sh))
      sh.set_uniform("tex0", Tex(target))
      sh.set_uniform("texelSize", Floats(FixedArray::from_array(texel)))
      sh.set_uniform("canvasSize", Floats([tw, th]))
      sh.set_uniform(
        "filterParameter",
        Floats([param.unwrap_or(@double.not_a_number)]),
      )
      quad()
    })
  }
  // draw the result back with the target's filter camera
  self.push()
  self.clear(0, 0, 0, 0)
  self.push()
  let cam = match target_fb {
    Some(fb) => fb_camera(fb.width, fb.height)
    None => Camera::new(self.width, self.height)
  }
  self.set_camera(cam)
  self.reset_matrix()
  self.image(
    fbo.source(),
    0,
    0,
    fbo.width,
    fbo.height,
    -tw / 2,
    -th / 2,
    tw,
    th,
    { ..pass_style, fill: Some([1, 1, 1, 1]), },
  )
  self.clear_depth()
  self.pop()
  self.pop()
}

// ---- 2D: FilterRenderer2D ----

///|
/// Runs p5's filter shaders over a 2D canvas on a helper WebGL canvas.
pub struct Filter2D {
  priv gl : @gl.GL
  priv shaders : Map[String, Shader]
  priv vbuf : @gl.Buffer
  priv tbuf : @gl.Buffer
}

///|
/// A helper of `w × h` pixels (p5 sizes it in CSS pixels).
pub fn Filter2D::new(w : Double, h : Double) -> Filter2D {
  let canvas = @dom.create_canvas(w, h, 1, "", false)
  let gl = @gl.create_plain_context(canvas)
  let vbuf = @gl.create_buffer(gl)
  @gl.array_buffer_data(gl, vbuf, [-1, -1, 1, -1, -1, 1, 1, 1])
  let tbuf = @gl.create_buffer(gl)
  @gl.array_buffer_data(gl, tbuf, [0, 1, 1, 1, 0, 0, 1, 0])
  { gl, shaders: Map([]), vbuf, tbuf, }
}

///|
/// One render pass: the filtered `src` (a `w × h` canvas at `density`)
/// into the helper canvas, which is returned as an image source.
pub fn Filter2D::pass(
  self : Filter2D,
  op : String,
  param : Double?,
  direction : (Double, Double),
  src : @dom.ImageElement,
  w : Double,
  h : Double,
  density : Double,
  user? : Shader,
) -> @dom.ImageElement? {
  let sh = match user {
    Some(s) => s
    None =>
      match self.shaders.get(op) {
        Some(s) => s
        None =>
          match filter_shader(@gl.version(self.gl) == 2, op) {
            Some(s) => {
              self.shaders[op] = s
              s
            }
            None => return None
          }
      }
  }
  guard sh.init(self.gl) is Some(p) else { return None }
  @gl.use_program(p)
  if user is Some(_) {
    for name, v in sh.uniforms {
      match v {
        Floats(data) => @gl.set_uniform(p, name, data)
        Tex(t) =>
          match t.elt {
            Some(e) =>
              @gl.set_uniform_texture(
                p,
                name,
                @gl.texture_for(self.gl, e, "clamp", "clamp", "linear"),
              )
            None => ()
          }
      }
    }
  }
  let param = match param {
    Some(v) => v
    None => filter_default_param(op).unwrap_or(@double.not_a_number)
  }
  let tex = @gl.texture_for(self.gl, src, "clamp", "clamp", "linear")
  @gl.set_uniform_texture(p, "tex0", tex)
  @gl.set_uniform(p, "texelSize", [1.0 / (w * density), 1.0 / (h * density)])
  @gl.set_uniform(p, "canvasSize", [w, h])
  @gl.set_uniform(p, "radius", [param.max(1)])
  @gl.set_uniform(p, "filterParameter", [param])
  @gl.set_uniform(p, "direction", [direction.0, direction.1])
  let identity : FixedArray[Double] = [
    1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1,
  ]
  @gl.set_uniform(p, "uModelViewMatrix", identity)
  @gl.set_uniform(p, "uProjectionMatrix", identity)
  @gl.attrib_pointer(
    self.gl,
    self.vbuf,
    @gl.attribute_location(p, "aPosition"),
    2,
  )
  @gl.attrib_pointer(
    self.gl,
    self.tbuf,
    @gl.attribute_location(p, "aTexCoord"),
    2,
  )
  @gl.bind_textures(p, tex)
  @gl.disable_other_attribs(p)
  @gl.draw_arrays(self.gl, 1, 4, 1)
  Some(@gl.context_canvas(self.gl))
}
