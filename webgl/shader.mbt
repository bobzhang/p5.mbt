// p5.Shader for the WEBGL renderer: sources plus hook implementations,
// assembled like p5's populateGLSLHooks and compiled on first use.

///|
/// A shader program: vertex and fragment sources with hooks.
pub struct Shader {
  mut vert : String
  mut frag : String
  /// `(\"type name\", body)` pairs filling `HOOK_name` in the vertex shader.
  vertex_hooks : Array[(String, String)]
  fragment_hooks : Array[(String, String)]
  /// Hook keys replaced by `modify` (they get `AUGMENTED_HOOK_` defines).
  modified : Array[String]
  /// GLSL added before the hooks of both stages (uniforms, helpers).
  declarations : String
  /// GLSL added before the vertex hooks only.
  vertex_declarations : String
  /// GLSL added before the fragment hooks only.
  fragment_declarations : String
  priv mut program : @gl.Program?
  priv mut kind : String
  priv raw : Bool
  priv uniforms : Map[String, UniformValue]
}

///|
/// A uniform value set with `set_uniform`.
pub(all) enum UniformValue {
  /// Numbers (a scalar, vector, matrix or array; booleans as 0/1).
  Floats(FixedArray[Double])
  /// A texture from an image source.
  Tex(TexSource)
}

///|
/// Sets a uniform; it is uploaded when the shader is next used.
pub fn Shader::set_uniform(
  self : Shader,
  name : String,
  value : UniformValue,
) -> Unit {
  self.uniforms[name] = value
}

///|
/// Replaces the sources (the program is rebuilt on next use); used when a
/// shader's files finish loading.
pub fn Shader::set_sources(self : Shader, vert : String, frag : String) -> Unit {
  self.vert = vert
  self.frag = frag
  self.program = None
}

///|
/// A copy with the same sources, hooks and uniforms that compiles its own
/// program, e.g. for use on another WebGL context (`copyToContext`).
pub fn Shader::copy(self : Shader) -> Shader {
  {
    ..self,
    program: None,
    uniforms: Map::from_array(self.uniforms.to_array()),
  }
}

///|
/// A description of the hooks this shader has, with their current bodies
/// (`inspectHooks` prints the same information).
pub fn Shader::inspect_hooks(self : Shader) -> String {
  let sb = StringBuilder()
  sb.write_string("==== Vertex shader hooks: ====\n")
  for h in self.vertex_hooks {
    sb.write_string(h.0 + h.1 + "\n")
  }
  sb.write_string("\n==== Fragment shader hooks: ====\n")
  for h in self.fragment_hooks {
    sb.write_string(h.0 + h.1 + "\n")
  }
  sb.to_string()
}

///|
/// p5's default vertex shader for filter shaders (`createFilterShader`),
/// GLSL ES 3.00 when the fragment shader is.
pub fn filter_vertex_source(frag : String) -> String {
  if frag.contains("#version 300 es") {
    (
      #|#version 300 es
      #|uniform mat4 uModelViewMatrix;
      #|uniform mat4 uProjectionMatrix;
      #|in vec3 aPosition;
      #|in vec2 aTexCoord;
      #|out vec2 vTexCoord;
      #|void main() {
      #|  vTexCoord = aTexCoord;
      #|  vec4 positionVec4 = vec4(aPosition, 1.0);
      #|  gl_Position = uProjectionMatrix * uModelViewMatrix * positionVec4;
      #|}
    )
  } else {
    (
      #|uniform mat4 uModelViewMatrix;
      #|uniform mat4 uProjectionMatrix;
      #|attribute vec3 aPosition;
      #|attribute vec2 aTexCoord;
      #|varying vec2 vTexCoord;
      #|void main() {
      #|  vTexCoord = aTexCoord;
      #|  vec4 positionVec4 = vec4(aPosition, 1.0);
      #|  gl_Position = uProjectionMatrix * uModelViewMatrix * positionVec4;
      #|}
    )
  }
}

///|
/// A filter shader from a fragment shader that reads `tex0` at `vTexCoord`
/// (`createFilterShader`). It also receives `texelSize` and `canvasSize`.
pub fn Shader::filter(frag : String) -> Shader {
  Shader::new(filter_vertex_source(frag), frag)
}

///|
/// A shader from GLSL sources (no hooks).
pub fn Shader::new(vert : String, frag : String) -> Shader {
  {
    vert,
    frag,
    vertex_hooks: [],
    fragment_hooks: [],
    modified: [],
    declarations: "",
    vertex_declarations: "",
    fragment_declarations: "",
    program: None,
    kind: "",
    uniforms: Map([]),
    raw: false,
  }
}

///|
/// A shader from complete sources (hooks already filled in).
fn Shader::raw(vert : String, frag : String) -> Shader {
  { ..Shader::new(vert, frag), raw: true, }
}

///|
fn Shader::with_hooks(
  vert : String,
  frag : String,
  vertex : Array[(String, String)],
  fragment : Array[(String, String)],
) -> Shader {
  { ..Shader::new(vert, frag), vertex_hooks: vertex, fragment_hooks: fragment, }
}

///|
/// A copy whose hooks are replaced by `vertex`/`fragment` entries (keys as
/// `"type name"`), like `shader.modify({...})` with string hooks.
/// `declarations` (both stages), `vertex_declarations` and
/// `fragment_declarations` add GLSL such as uniforms and helper functions
/// before the hooks.
pub fn Shader::modify(
  self : Shader,
  vertex~ : Array[(String, String)] = [],
  fragment~ : Array[(String, String)] = [],
  declarations~ : String = "",
  vertex_declarations~ : String = "",
  fragment_declarations~ : String = "",
) -> Shader {
  let replace = (
    hooks : Array[(String, String)],
    with_ : Array[(String, String)],
  ) => {
    hooks.map(h => {
      match
        with_.search_by(w => w.0 == h.0 || hook_name(w.0) == hook_name(h.0)) {
        Some(i) => (h.0, with_[i].1)
        None => h
      }
    })
  }
  let modified = self.modified.copy()
  for h in vertex {
    modified.push(full_key(self.vertex_hooks, h.0))
  }
  for h in fragment {
    modified.push(full_key(self.fragment_hooks, h.0))
  }
  {
    ..self,
    vertex_hooks: replace(self.vertex_hooks, vertex),
    fragment_hooks: replace(self.fragment_hooks, fragment),
    modified,
    declarations: self.declarations + "\n" + declarations,
    vertex_declarations: if vertex_declarations == "" {
      self.vertex_declarations
    } else {
      self.vertex_declarations + "\n" + vertex_declarations
    },
    fragment_declarations: if fragment_declarations == "" {
      self.fragment_declarations
    } else {
      self.fragment_declarations + "\n" + fragment_declarations
    },
    program: None,
    kind: "",
    uniforms: Map([]),
  }
}

///|
fn hook_name(key : String) -> String {
  let parts = key.split(" ").map(s => s.to_owned()).collect()
  parts.last().unwrap_or(key)
}

///|
fn full_key(hooks : Array[(String, String)], key : String) -> String {
  match hooks.search_by(h => h.0 == key || hook_name(h.0) == hook_name(key)) {
    Some(i) => hooks[i].0
    None => key
  }
}

///|
/// p5's populateGLSLHooks.
fn populate_hooks(
  src : String,
  hooks_list : Array[(String, String)],
  modified : Array[String],
  declarations~ : String = "",
) -> String {
  let main = "void main"
  guard src.find(main) is Some(at) else { return src }
  let chars = src.to_array()
  let pre = String::from_array(chars[:at])
  // `split(main)` keeps only the text up to a second "void main"
  let rest = String::from_array(chars[at + main.length():])
  let post = match rest.find(main) {
    Some(j) => String::from_array(rest.to_array()[:j])
    None => rest
  }
  let hooks = StringBuilder()
  if declarations.trim().length() > 0 {
    hooks.write_string(declarations + "\n")
  }
  let defines = StringBuilder()
  for h in hooks_list {
    let (key, body) = h
    let parts = key.split(" ").map(s => s.to_owned()).collect()
    let typ = parts.get(0).unwrap_or("")
    let name = parts.get(1).unwrap_or("")
    if modified.contains(key) {
      defines.write_string("#define AUGMENTED_HOOK_" + name + "\n")
    }
    hooks.write_string(typ + " HOOK_" + name + body + "\n")
  }
  let mut pre = pre
  let mut defs = defines.to_string()
  if pre.find("#define HOOK_DEFINES") is Some(_) {
    pre = pre.replace(old="#define HOOK_DEFINES", new="\n" + defs + "\n")
    defs = ""
  }
  pre + "\n" + defs + hooks.to_string() + main + post
}

///|
/// The vertex source with hooks filled in.
pub fn Shader::vert_src(self : Shader) -> String {
  if self.raw {
    return self.vert
  }
  populate_hooks(
    self.vert,
    self.vertex_hooks,
    self.modified,
    declarations=self.declarations + "\n" + self.vertex_declarations,
  )
}

///|
/// The fragment source with hooks filled in.
pub fn Shader::frag_src(self : Shader) -> String {
  if self.raw {
    return self.frag
  }
  populate_hooks(
    self.frag,
    self.fragment_hooks,
    self.modified,
    declarations=self.declarations + "\n" + self.fragment_declarations,
  )
}

///|
fn Shader::init(self : Shader, gl : @gl.GL) -> @gl.Program? {
  match self.program {
    Some(p) => Some(p)
    None =>
      match @gl.compile_program(gl, self.vert_src(), self.frag_src()) {
        Ok(p) => {
          self.program = Some(p)
          Some(p)
        }
        Err(msg) => {
          println(
            "Whoops! Something went wrong initializing the shader:\n" + msg,
          )
          None
        }
      }
  }
}

///|
/// p5's `_webGL2CompatibilityPrefix`.
fn compat_prefix(webgl2 : Bool, vertex : Bool) -> String {
  (if webgl2 { "#version 300 es\n#define WEBGL2\n" } else { "" }) +
  (if vertex { "#define VERTEX_SHADER\n" } else { "#define FRAGMENT_SHADER\n" }) +
  "precision highp float;\n"
}

///|
let stroke_defs : String = "#define STROKE_CAP_ROUND 0\n#define STROKE_CAP_PROJECT 1\n#define STROKE_CAP_SQUARE 2\n#define STROKE_JOIN_ROUND 0\n#define STROKE_JOIN_MITER 1\n#define STROKE_JOIN_BEVEL 2\n"

///|
let vertex_hooks_default : Array[(String, String)] = [
  ("void beforeVertex", "() {}"),
  ("Vertex getObjectInputs", "(Vertex inputs) { return inputs; }"),
  ("Vertex getWorldInputs", "(Vertex inputs) { return inputs; }"),
  ("Vertex getCameraInputs", "(Vertex inputs) { return inputs; }"),
  ("void afterVertex", "() {}"),
]

///|
fn default_shader(webgl2 : Bool, kind : String) -> Shader {
  let c = glsl_webgl2compatibility_glsl
  let v = compat_prefix(webgl2, true)
  let f = compat_prefix(webgl2, false)
  let final_color = (
    "vec4 getFinalColor", "(vec4 color, vec2 texCoord) { return color; }",
  )
  match kind {
    "color" =>
      Shader::with_hooks(
        v + c + glsl_normal_vert,
        f + c + glsl_basic_frag,
        vertex_hooks_default,
        [
          ("void beforeFragment", "() {}"),
          final_color,
          ("void afterFragment", "() {}"),
        ],
      )
    "normal" =>
      Shader::with_hooks(
        v + c + glsl_normal_vert,
        f + c + glsl_normal_frag,
        vertex_hooks_default,
        [
          ("void beforeFragment", "() {}"),
          final_color,
          ("void afterFragment", "() {}"),
        ],
      )
    "light" | "light_maps" => {
      let maps = if kind == "light_maps" {
        "#define USE_TEXTURE_MAPS\n"
      } else {
        ""
      }
      Shader::with_hooks(
        v + maps + c + glsl_phong_vert,
        f + maps + c + glsl_lighting_glsl + glsl_phong_frag,
        vertex_hooks_default,
        [
          ("void beforeFragment", "() {}"),
          ("Inputs getPixelInputs", "(Inputs inputs) { return inputs; }"),
          (
            "vec4 combineColors",
            (
              #|(ColorComponents components) {
              #|                vec4 color = vec4(0.);
              #|                color.rgb += components.diffuse * components.baseColor;
              #|                color.rgb += components.ambient * components.ambientColor;
              #|                color.rgb += components.specular * components.specularColor;
              #|                color.rgb += components.emissive;
              #|                color.a = components.opacity;
              #|                return color;
              #|              }
            ),
          ),
          final_color,
          ("void afterFragment", "() {}"),
        ],
      )
    }
    "line" =>
      Shader::with_hooks(
        v + c + stroke_defs + glsl_line_vert,
        f + c + stroke_defs + glsl_line_frag,
        [
          ("void beforeVertex", "() {}"),
          (
            "StrokeVertex getObjectInputs", "(StrokeVertex inputs) { return inputs; }",
          ),
          (
            "StrokeVertex getWorldInputs", "(StrokeVertex inputs) { return inputs; }",
          ),
          (
            "StrokeVertex getCameraInputs", "(StrokeVertex inputs) { return inputs; }",
          ),
          ("void afterVertex", "() {}"),
        ],
        [
          ("void beforeFragment", "() {}"),
          ("Inputs getPixelInputs", "(Inputs inputs) { return inputs; }"),
          final_color,
          ("bool shouldDiscard", "(bool outside) { return outside; }"),
          ("void afterFragment", "() {}"),
        ],
      )
    _ => Shader::new(v + c + glsl_normal_vert, f + c + glsl_basic_frag)
  }
}
