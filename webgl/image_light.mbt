// Image-based lighting (p5's `imageLight`, src/webgl/light.js and
// p5.Renderer3D's makeDiffusedTexture / makeSpecularTexture), material
// texture maps (`ambientTexture`, `specularTexture`, `shininessTexture`,
// `normalTexture`, `bumpTexture`) and `panorama`.

///|
fn same_source(a : TexSource, b : TexSource) -> Bool {
  match (a.elt, b.elt, a.fb, b.fb) {
    (Some(x), Some(y), _, _) => physical_equal(x, y)
    (_, _, Some(x), Some(y)) => physical_equal(x, y)
    _ => false
  }
}

///|
fn image_light_style() -> Style {
  {
    fill: Some([1, 1, 1, 1]),
    stroke: None,
    stroke_weight: 1,
    stroke_cap: 0,
    stroke_join: 0,
    blend_mode: "blend",
    erasing: false,
  }
}

///|
fn Renderer3D::image_light_shaders(self : Renderer3D) -> (Shader, Shader) {
  match self.image_light_shaders {
    Some(s) => s
    None => {
      let webgl2 = @gl.version(self.gl) == 2
      let c = glsl_webgl2compatibility_glsl
      let v = compat_prefix(webgl2, true) + c + glsl_imagelight_vert
      let f = compat_prefix(webgl2, false) + c
      let s = (
        Shader::raw(v, f + glsl_imagelightdiffused_frag),
        Shader::raw(v, f + glsl_imagelightspecular_frag),
      )
      self.image_light_shaders = Some(s)
      s
    }
  }
}

///|
/// Draws a `w × h` plane through `sh` into the active framebuffer.
fn Renderer3D::draw_light_plane(
  self : Renderer3D,
  sh : Shader,
  w : Double,
  h : Double,
) -> Unit {
  self.push()
  self.set_fill_shader(Some(sh))
  self.no_lights()
  let g = self.cached_geometry("plane|1|1", () => plane_geometry(1, 1))
  self.draw_scaled(g, w, h, 1, image_light_style())
  self.pop()
}

///|
/// The blurred light coming from each direction of an environment image
/// (p5's `makeDiffusedTexture`), cached per image.
fn Renderer3D::diffused_light(self : Renderer3D, input : TexSource) -> Framebuffer {
  for e in self.diffused_lights {
    if same_source(e.0, input) {
      return e.1
    }
  }
  let width = 200.0
  let height = (width * (input.height / input.width)).floor()
  let fb = self.create_framebuffer(
    {
      ..FramebufferOptions::default(),
      width: Some(width),
      height: Some(height),
      density: Some(1),
    },
    self.antialias,
  )
  let (diffused, _) = self.image_light_shaders()
  diffused.set_uniform("environmentMap", Tex(input))
  fb.draw(() => self.draw_light_plane(diffused, width, height))
  self.diffused_lights.push((input, fb))
  fb
}

///|
/// Reflections of an environment image at increasing roughness, one mip
/// level each (p5's `makeSpecularTexture`), cached per image.
fn Renderer3D::specular_light(self : Renderer3D, input : TexSource) -> @gl.Texture {
  for e in self.specular_lights {
    if same_source(e.0, input) {
      return e.1
    }
  }
  let size = 512
  let count = 10 // floor(log2(512)) + 1
  let (_, specular) = self.image_light_shaders()
  let fb = self.create_framebuffer(
    {
      ..FramebufferOptions::default(),
      width: Some(size.to_double()),
      height: Some(size.to_double()),
      density: Some(1),
    },
    self.antialias,
  )
  let levels : Array[FixedArray[Byte]] = []
  let sizes : Array[Int] = []
  let mut w = size
  while w >= 1 {
    let wd = w.to_double()
    fb.resize(wd, wd)
    let roughness = 1.0 - @cmath.ln(wd) / @cmath.ln(2) / count.to_double()
    specular.set_uniform("environmentMap", Tex(input))
    specular.set_uniform("roughness", Floats([roughness]))
    fb.draw(() => {
      self.clear(0, 0, 0, 0)
      self.draw_light_plane(specular, wd, wd)
    })
    levels.push(fb.read_pixels())
    sizes.push(w)
    w = w / 2
  }
  fb.remove()
  let tex = @gl.mipmap_texture(
    self.gl,
    FixedArray::from_array(levels),
    FixedArray::from_array(sizes),
  )
  self.specular_lights.push((input, tex))
  tex
}

///|
/// Lights the scene with an image of its surroundings from every direction
/// (`imageLight`): an equirectangular (360°) image works best. Shiny
/// materials (`specular_material`, `shininess`, `metalness`) reflect it.
pub fn Renderer3D::image_light(self : Renderer3D, src : TexSource) -> Unit {
  if src.width <= 0 || src.height <= 0 {
    return
  }
  self.state.image_light = Some(src)
  self.state.enable_lighting = true
  ignore(self.diffused_light(src))
  ignore(self.specular_light(src))
}

///|
fn Renderer3D::set_image_light_uniforms(
  self : Renderer3D,
  p : @gl.Program,
  empty : @gl.Texture,
) -> Unit {
  match self.state.image_light {
    Some(src) => {
      @gl.set_uniform(p, "uUseImageLight", bool_u(true))
      let fb = self.diffused_light(src)
      fb.resolve(false)
      @gl.set_uniform_texture(
        p,
        "environmentMapDiffused",
        @gl.fbo_texture(fb.fbo, false),
      )
      @gl.set_uniform_texture(
        p,
        "environmentMapSpecular",
        self.specular_light(src),
      )
    }
    None => {
      @gl.set_uniform(p, "uUseImageLight", bool_u(false))
      @gl.set_uniform_texture(p, "environmentMapDiffused", empty)
      @gl.set_uniform_texture(p, "environmentMapSpecular", empty)
    }
  }
}

// ---- texture maps ----

///|
fn GLState::has_texture_map(self : GLState) -> Bool {
  self.specular_tex is Some(_) ||
  self.ambient_tex is Some(_) ||
  self.shininess_tex is Some(_) ||
  self.normal_tex is Some(_)
}

///|
/// Which material map a texture is used as.
pub(all) enum TextureMap {
  /// Scales the specular color (MTL `map_Ks`).
  SpecularMap
  /// Replaces the ambient color (`map_Ka`).
  AmbientMap
  /// Scales shininess by the red channel (`map_Ns`).
  ShininessMap
  /// Tilts normals: a tangent-space normal map (`map_Bump`).
  NormalMap
  /// Tilts normals from heights in the red channel (a bump map).
  BumpMap
}

///|
/// Sets (or with `None` clears) a texture map of the material. Normal and
/// bump maps need geometry with uvs and tangents (`compute_tangents`).
pub fn Renderer3D::texture_map(
  self : Renderer3D,
  which : TextureMap,
  src : TexSource?,
  scale~ : Double = 1,
) -> Unit {
  let s = self.state
  match which {
    SpecularMap => s.specular_tex = src
    AmbientMap => s.ambient_tex = src
    ShininessMap => s.shininess_tex = src
    NormalMap => {
      s.normal_tex = src
      s.normal_scale = scale
      s.normal_map_mode = 0
    }
    BumpMap => {
      s.normal_tex = src
      s.normal_scale = scale
      s.normal_map_mode = 1
    }
  }
}

///|
fn Renderer3D::set_texture_map_uniforms(
  self : Renderer3D,
  p : @gl.Program,
  empty : @gl.Texture,
) -> Unit {
  let s = self.state
  if !s.has_texture_map() {
    return
  }
  let bind = (has : String, sampler : String, t : TexSource?) => {
    @gl.set_uniform(p, has, bool_u(t is Some(_)))
    @gl.set_uniform_texture(p, sampler, match t {
      Some(src) => self.gl_texture(src)
      None => empty
    })
  }
  bind("uHasSpecularTex", "uSpecularSampler", s.specular_tex)
  bind("uHasAmbientTex", "uAmbientSampler", s.ambient_tex)
  bind("uHasShininessTex", "uShininessSampler", s.shininess_tex)
  bind("uHasNormalMap", "uNormalSampler", s.normal_tex)
  @gl.set_uniform(p, "uNormalScale", [s.normal_scale])
  @gl.set_uniform(p, "uNormalMapMode", [s.normal_map_mode.to_double()])
  let (tw, th) = match s.normal_tex {
    Some(t) if t.width > 0 && t.height > 0 => (t.width, t.height)
    _ => (256.0, 256.0)
  }
  @gl.set_uniform(p, "uNormalTexelSize", [1 / tw, 1 / th])
}

// ---- panorama ----

///|
/// The sphere-mapping filter p5 builds with p5.strands in
/// `_getSphereMapping`, written out in GLSL.
let panorama_frag : String =
  #|precision highp float;
  #|varying vec2 vTexCoord;
  #|uniform sampler2D uEnvMap;
  #|uniform float uFovY;
  #|uniform float uAspect;
  #|uniform vec3 uN1;
  #|uniform vec3 uN2;
  #|uniform vec3 uN3;
  #|const float PI = 3.141592653589793;
  #|void main() {
  #|  float uFovX = uFovY * uAspect;
  #|  float angleY = mix(uFovY / 2.0, -uFovY / 2.0, vTexCoord.y);
  #|  float angleX = mix(uFovX / 2.0, -uFovX / 2.0, vTexCoord.x);
  #|  vec3 n = normalize(vec3(angleX, angleY, 1.0));
  #|  vec3 r = vec3(dot(n, uN1), dot(n, uN2), dot(n, uN3));
  #|  float temp = r.z;
  #|  r.z = r.x;
  #|  r.x = -temp;
  #|  vec2 suv = vec2(atan(r.z, r.x) / (2.0 * PI) + 0.5, 0.5 + 0.5 * -r.y);
  #|  gl_FragColor = texture2D(uEnvMap, suv);
  #|}

///|
/// Draws a 360° equirectangular image as the background, seen through the
/// active camera (`panorama`). Call it first in `draw`.
pub fn Renderer3D::panorama(
  self : Renderer3D,
  src : TexSource,
  style : Style,
) -> Unit {
  let sh = match self.shaders.get("panorama") {
    Some(s) => s
    None => {
      let s = Shader::new(filter_vertex_source(panorama_frag), panorama_frag)
      self.shaders["panorama"] = s
      s
    }
  }
  let m3 = @math.Matrix::new(3).inverse_transpose4x4(self.state.view)
  let inv = @math.Matrix::new(3).invert_from(m3).unwrap_or(m3)
  let m = (i : Int) => inv.get(i)
  let cam = self.state.camera
  sh.set_uniform("uFovY", Floats([cam.camera_fov]))
  sh.set_uniform("uAspect", Floats([cam.aspect_ratio]))
  sh.set_uniform("uN1", Floats([m(0), m(3), m(6)]))
  sh.set_uniform("uN2", Floats([m(1), m(4), m(7)]))
  sh.set_uniform("uN3", Floats([m(2), m(5), m(8)]))
  sh.set_uniform("uEnvMap", Tex(src))
  self.filter("", None, style, Some(sh))
}

///|
/// Turns on the specular material term (set by `specular_texture`).
pub fn Renderer3D::use_specular_material(self : Renderer3D) -> Unit {
  self.state.use_specular = true
}

///|
/// Marks the ambient material color as set (by `ambient_texture`).
pub fn Renderer3D::set_has_ambient(self : Renderer3D) -> Unit {
  self.state.has_set_ambient = true
}
