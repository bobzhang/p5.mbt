// A thin WebGL binding for the WEBGL renderer. Programs carry their
// uniform and attribute tables (p5's getWebGLUniformMetadata /
// getWebGLShaderAttributes) and set uniforms like setWebGLUniformValue.

///|
/// A WebGL rendering context.
#external
pub type GL

///|
/// A linked shader program with its uniform and attribute tables.
#external
pub type Program

///|
#external
pub type Buffer

///|
#external
pub type Texture

///|
#external
pub type Framebuffer

///|
/// Creates a context for `canvas` with p5's default attributes
/// (WebGL 2 when available).
pub extern "js" fn create_context(
  canvas : @dom.Canvas,
  alpha : Bool,
  depth : Bool,
  stencil : Bool,
  antialias : Bool,
  premultiplied_alpha : Bool,
  preserve_drawing_buffer : Bool,
) -> GL =
  #|(canvas, alpha, depth, stencil, antialias, premultipliedAlpha, preserveDrawingBuffer) => {
  #|  const attrs = { alpha, depth, stencil, antialias, premultipliedAlpha, preserveDrawingBuffer };
  #|  let gl = canvas.getContext('webgl2', attrs);
  #|  if (gl) gl.__p5mbtVersion = 2;
  #|  else { gl = canvas.getContext('webgl', attrs); if (gl) gl.__p5mbtVersion = 1; }
  #|  if (!gl) throw new Error('Error creating webgl context');
  #|  gl.enable(gl.DEPTH_TEST);
  #|  gl.depthFunc(gl.LEQUAL);
  #|  gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
  #|  gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  #|  gl.__p5mbtEnabled = new Set();
  #|  gl.__p5mbtCur = null;
  #|  return gl;
  #|}

///|
/// p5's antialias default: on when the user agent mentions Safari.
pub extern "js" fn default_antialias() -> Bool =
  #|() => navigator.userAgent.toLowerCase().includes('safari')

///|
/// 2 for WebGL 2, 1 for WebGL 1.
pub extern "js" fn version(gl : GL) -> Int32 = "(gl) => gl.__p5mbtVersion"

///|
pub extern "js" fn drawing_buffer_width(gl : GL) -> Int32 = "(gl) => gl.drawingBufferWidth"

///|
pub extern "js" fn drawing_buffer_height(gl : GL) -> Int32 = "(gl) => gl.drawingBufferHeight"

///|
pub extern "js" fn max_texture_size(gl : GL) -> Int32 = "(gl) => gl.getParameter(gl.MAX_TEXTURE_SIZE)"

///|
pub extern "js" fn viewport(
  gl : GL,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> Unit = "(gl, x, y, w, h) => gl.viewport(x, y, w, h)"

///|
/// Clears color (premultiplied by p5's `clear`) and depth.
pub extern "js" fn clear(
  gl : GL,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit =
  #|(gl, r, g, b, a) => { gl.clearColor(r, g, b, a); gl.clearDepth(1); gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT); }

///|
pub extern "js" fn clear_depth(gl : GL, depth : Double) -> Unit =
  #|(gl, d) => { gl.clearDepth(d); gl.clear(gl.DEPTH_BUFFER_BIT); }

///|
/// p5's `_resetBuffersBeforeDraw`: clears depth and stencil.
pub extern "js" fn reset_depth_stencil(gl : GL) -> Unit =
  #|(gl) => { gl.clearStencil(0); gl.clear(gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT); gl.disable(gl.STENCIL_TEST); }

///|
/// Compiles and links a program; raises the compile/link log on failure.
pub extern "js" fn compile_program_js(
  gl : GL,
  vert : String,
  frag : String,
  ok : (Program) -> Unit,
  err : (String) -> Unit,
) -> Unit =
  #|(gl, vsrc, fsrc, ok, err) => {
  #|  const vs = gl.createShader(gl.VERTEX_SHADER);
  #|  gl.shaderSource(vs, vsrc); gl.compileShader(vs);
  #|  if (!gl.getShaderParameter(vs, gl.COMPILE_STATUS)) { err('Yikes! An error occurred compiling the vertex shader: ' + gl.getShaderInfoLog(vs) + ' in:\n\n' + vsrc); return; }
  #|  const fs = gl.createShader(gl.FRAGMENT_SHADER);
  #|  gl.shaderSource(fs, fsrc); gl.compileShader(fs);
  #|  if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) { err('Darn! An error occurred compiling the fragment shader: ' + gl.getShaderInfoLog(fs) + ' in:\n\n' + fsrc); return; }
  #|  const program = gl.createProgram();
  #|  gl.attachShader(program, vs); gl.attachShader(program, fs); gl.linkProgram(program);
  #|  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) { err('Snap! Error linking shader program: ' + gl.getProgramInfoLog(program)); return; }
  #|  const attributes = {};
  #|  const na = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
  #|  for (let i = 0; i < na; i++) {
  #|    const info = gl.getActiveAttrib(program, i);
  #|    attributes[info.name] = { name: info.name, location: gl.getAttribLocation(program, info.name) };
  #|  }
  #|  const uniforms = {}, samplers = [];
  #|  const nu = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
  #|  let samplerIndex = 0;
  #|  for (let i = 0; i < nu; i++) {
  #|    const info = gl.getActiveUniform(program, i);
  #|    let name = info.name;
  #|    if (info.size > 1) name = name.substring(0, name.indexOf('[0]'));
  #|    const u = { name, location: gl.getUniformLocation(program, info.name), size: info.size, type: info.type, cached: undefined };
  #|    if (u.type === gl.SAMPLER_2D) { u.isSampler = true; u.samplerIndex = samplerIndex++; samplers.push(u); }
  #|    u.isArray = info.size > 1 || [gl.FLOAT_MAT2, gl.FLOAT_MAT3, gl.FLOAT_MAT4, gl.FLOAT_VEC2, gl.FLOAT_VEC3, gl.FLOAT_VEC4, gl.INT_VEC2, gl.INT_VEC3, gl.INT_VEC4].includes(u.type);
  #|    uniforms[name] = u;
  #|  }
  #|  ok({ gl, program, attributes, uniforms, samplers });
  #|}

///|
/// Compiles and links a program.
pub fn compile_program(
  gl : GL,
  vert : String,
  frag : String,
) -> Result[Program, String] {
  let mut out : Result[Program, String] = Err("shader did not compile")
  compile_program_js(gl, vert, frag, p => out = Ok(p), e => out = Err(e))
  out
}

///|
/// Makes `p` the current program (skipped when it already is).
pub extern "js" fn use_program(p : Program) -> Unit =
  #|(p) => { if (p.gl.__p5mbtCur !== p) { p.gl.useProgram(p.program); p.gl.__p5mbtCur = p; } }

///|
pub extern "js" fn has_uniform(p : Program, name : String) -> Bool = "(p, n) => !!p.uniforms[n]"

///|
pub extern "js" fn has_attribute(p : Program, name : String) -> Bool = "(p, n) => !!p.attributes[n]"

///|
/// The location of an active attribute, or -1.
pub extern "js" fn attribute_location(p : Program, name : String) -> Int32 =
  #|(p, n) => p.attributes[n] ? p.attributes[n].location : -1

///|
/// Sets a uniform from numbers (booleans as 0/1), skipping unchanged
/// values, with p5's per-type dispatch.
pub extern "js" fn set_uniform(
  p : Program,
  name : String,
  data : FixedArray[Double],
) -> Unit =
  #|(p, name, data) => {
  #|  const u = p.uniforms[name]; if (!u || u.isSampler) return;
  #|  const gl = p.gl;
  #|  if (u.cached && u.cached.length === data.length && u.cached.every((v, i) => v === data[i])) return;
  #|  u.cached = data.slice(0);
  #|  if (gl.__p5mbtCur !== p) { gl.useProgram(p.program); gl.__p5mbtCur = p; }
  #|  const loc = u.location, many = u.size > 1;
  #|  switch (u.type) {
  #|    case gl.BOOL: gl.uniform1i(loc, data[0] === 1 ? 1 : 0); break;
  #|    case gl.INT: if (many) { data.length && gl.uniform1iv(loc, data); } else gl.uniform1i(loc, data[0]); break;
  #|    case gl.FLOAT: if (many) { data.length && gl.uniform1fv(loc, data); } else gl.uniform1f(loc, data[0]); break;
  #|    case gl.FLOAT_MAT2: gl.uniformMatrix2fv(loc, false, data); break;
  #|    case gl.FLOAT_MAT3: gl.uniformMatrix3fv(loc, false, data); break;
  #|    case gl.FLOAT_MAT4: gl.uniformMatrix4fv(loc, false, data); break;
  #|    case gl.FLOAT_VEC2: if (many) { data.length && gl.uniform2fv(loc, data); } else gl.uniform2f(loc, data[0], data[1]); break;
  #|    case gl.FLOAT_VEC3: if (many) { data.length && gl.uniform3fv(loc, data); } else gl.uniform3f(loc, data[0], data[1], data[2]); break;
  #|    case gl.FLOAT_VEC4: if (many) { data.length && gl.uniform4fv(loc, data); } else gl.uniform4f(loc, data[0], data[1], data[2], data[3]); break;
  #|    case gl.INT_VEC2: if (many) { data.length && gl.uniform2iv(loc, data); } else gl.uniform2i(loc, data[0], data[1]); break;
  #|    case gl.INT_VEC3: if (many) { data.length && gl.uniform3iv(loc, data); } else gl.uniform3i(loc, data[0], data[1], data[2]); break;
  #|    case gl.INT_VEC4: if (many) { data.length && gl.uniform4iv(loc, data); } else gl.uniform4i(loc, data[0], data[1], data[2], data[3]); break;
  #|  }
  #|}

///|
/// Sets a matrix uniform from 32-bit float entries.
pub extern "js" fn set_uniform_floats(
  p : Program,
  name : String,
  data : FixedArray[Float],
) -> Unit =
  #|(p, name, data) => {
  #|  const u = p.uniforms[name]; if (!u) return;
  #|  const gl = p.gl;
  #|  if (u.cached && u.cached.length === data.length && u.cached.every((v, i) => v === data[i])) return;
  #|  u.cached = data.slice(0);
  #|  if (gl.__p5mbtCur !== p) { gl.useProgram(p.program); gl.__p5mbtCur = p; }
  #|  if (u.type === gl.FLOAT_MAT4) gl.uniformMatrix4fv(u.location, false, data);
  #|  else if (u.type === gl.FLOAT_MAT3) gl.uniformMatrix3fv(u.location, false, data);
  #|  else if (u.type === gl.FLOAT_MAT2) gl.uniformMatrix2fv(u.location, false, data);
  #|  else if (u.type === gl.FLOAT_VEC4) gl.uniform4fv(u.location, data);
  #|  else if (u.type === gl.FLOAT_VEC3) gl.uniform3fv(u.location, data);
  #|  else if (u.type === gl.FLOAT_VEC2) gl.uniform2fv(u.location, data);
  #|}

///|
/// Assigns a texture to a sampler uniform (bound by `bind_textures`).
pub extern "js" fn set_uniform_texture(
  p : Program,
  name : String,
  tex : Texture,
) -> Unit =
  #|(p, name, tex) => {
  #|  const u = p.uniforms[name]; if (!u || !u.isSampler) return;
  #|  const gl = p.gl;
  #|  if (gl.__p5mbtCur !== p) { gl.useProgram(p.program); gl.__p5mbtCur = p; }
  #|  gl.activeTexture(gl.TEXTURE0 + u.samplerIndex);
  #|  u.texture = tex;
  #|  gl.uniform1i(u.location, u.samplerIndex);
  #|}

///|
/// Binds every sampler's texture to its unit (`bindTextures`), using
/// `empty` for samplers without one.
pub extern "js" fn bind_textures(p : Program, empty : Texture) -> Unit =
  #|(p, empty) => {
  #|  const gl = p.gl;
  #|  for (const u of p.samplers) {
  #|    if (!u.texture) u.texture = empty;
  #|    gl.activeTexture(gl.TEXTURE0 + u.samplerIndex);
  #|    gl.bindTexture(gl.TEXTURE_2D, u.texture);
  #|    gl.uniform1i(u.location, u.samplerIndex);
  #|  }
  #|}

///|
pub extern "js" fn create_buffer(gl : GL) -> Buffer = "(gl) => gl.createBuffer()"

///|
pub extern "js" fn delete_buffer(gl : GL, b : Buffer) -> Unit = "(gl, b) => gl.deleteBuffer(b)"

///|
/// Uploads float data to an ARRAY_BUFFER.
pub extern "js" fn array_buffer_data(
  gl : GL,
  b : Buffer,
  data : FixedArray[Double],
) -> Unit =
  #|(gl, b, data) => { gl.bindBuffer(gl.ARRAY_BUFFER, b); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW); }

///|
/// Uploads indices to an ELEMENT_ARRAY_BUFFER (32-bit when `wide`).
pub extern "js" fn index_buffer_data(
  gl : GL,
  b : Buffer,
  data : FixedArray[Int32],
  wide : Bool,
) -> Unit =
  #|(gl, b, data, wide) => { gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, b); gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, wide ? new Uint32Array(data) : new Uint16Array(data), gl.STATIC_DRAW); }

///|
/// Binds `b` as the source of attribute `loc` with `size` floats per vertex.
pub extern "js" fn attrib_pointer(
  gl : GL,
  b : Buffer,
  loc : Int32,
  size : Int32,
) -> Unit =
  #|(gl, b, loc, size) => {
  #|  gl.bindBuffer(gl.ARRAY_BUFFER, b);
  #|  if (!gl.__p5mbtEnabled.has(loc)) { gl.enableVertexAttribArray(loc); gl.__p5mbtEnabled.add(loc); }
  #|  gl.vertexAttribPointer(loc, size, gl.FLOAT, false, 0, 0);
  #|}

///|
/// Disables attribute arrays that `p` does not use (`_disableRemainingAttributes`),
/// and `loc` when given (>= 0).
pub extern "js" fn disable_other_attribs(p : Program) -> Unit =
  #|(p) => {
  #|  const gl = p.gl, used = new Set(Object.values(p.attributes).map(a => a.location));
  #|  for (const loc of [...gl.__p5mbtEnabled]) if (!used.has(loc)) { gl.disableVertexAttribArray(loc); gl.__p5mbtEnabled.delete(loc); }
  #|}

///|
pub extern "js" fn disable_attrib(gl : GL, loc : Int32) -> Unit =
  #|(gl, loc) => { if (loc >= 0 && gl.__p5mbtEnabled.has(loc)) { gl.disableVertexAttribArray(loc); gl.__p5mbtEnabled.delete(loc); } }

///|
/// Draws `count` vertices: mode 0 triangles, 1 triangle strip, 2 triangle fan.
pub extern "js" fn draw_arrays(
  gl : GL,
  mode : Int32,
  count : Int32,
  instances : Int32,
) -> Unit =
  #|(gl, mode, count, n) => {
  #|  const m = mode === 0 ? gl.TRIANGLES : mode === 1 ? gl.TRIANGLE_STRIP : mode === 2 ? gl.TRIANGLE_FAN : mode === 3 ? gl.LINES : gl.POINTS;
  #|  if (n === 1) gl.drawArrays(m, 0, count); else gl.drawArraysInstanced(m, 0, count, n);
  #|}

///|
pub extern "js" fn draw_elements(
  gl : GL,
  b : Buffer,
  count : Int32,
  wide : Bool,
  instances : Int32,
) -> Unit =
  #|(gl, b, count, wide, n) => {
  #|  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, b);
  #|  const t = wide ? gl.UNSIGNED_INT : gl.UNSIGNED_SHORT;
  #|  if (n === 1) gl.drawElements(gl.TRIANGLES, count, t, 0); else gl.drawElementsInstanced(gl.TRIANGLES, count, t, 0, n);
  #|}

///|
/// Enables or disables blending (`_applyColorBlend`'s toggle).
pub extern "js" fn set_blending(gl : GL, on : Bool) -> Unit =
  #|(gl, on) => { if (on) gl.enable(gl.BLEND); else gl.disable(gl.BLEND); gl.depthMask(true); }

///|
/// Applies a p5 blend mode by name (`_applyBlendMode`).
pub extern "js" fn apply_blend_mode(gl : GL, mode : String) -> Unit =
  #|(gl, mode) => {
  #|  const ext = gl.__p5mbtVersion === 2 ? gl : gl.getExtension('EXT_blend_minmax');
  #|  switch (mode) {
  #|    case 'blend': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA); break;
  #|    case 'add': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.ONE, gl.ONE); break;
  #|    case 'remove': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_ALPHA); break;
  #|    case 'multiply': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA); break;
  #|    case 'screen': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_COLOR); break;
  #|    case 'exclusion': gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD); gl.blendFuncSeparate(gl.ONE_MINUS_DST_COLOR, gl.ONE_MINUS_SRC_COLOR, gl.ONE, gl.ONE); break;
  #|    case 'replace': gl.blendEquation(gl.FUNC_ADD); gl.blendFunc(gl.ONE, gl.ZERO); break;
  #|    case 'subtract': gl.blendEquationSeparate(gl.FUNC_REVERSE_SUBTRACT, gl.FUNC_ADD); gl.blendFuncSeparate(gl.ONE, gl.ONE, gl.ONE, gl.ONE_MINUS_SRC_ALPHA); break;
  #|    case 'darkest': if (ext) { gl.blendEquationSeparate(ext.MIN || ext.MIN_EXT, gl.FUNC_ADD); gl.blendFuncSeparate(gl.ONE, gl.ONE, gl.ONE, gl.ONE); } break;
  #|    case 'lightest': if (ext) { gl.blendEquationSeparate(ext.MAX || ext.MAX_EXT, gl.FUNC_ADD); gl.blendFuncSeparate(gl.ONE, gl.ONE, gl.ONE, gl.ONE); } break;
  #|  }
  #|}

///|
/// A 1x1 texture holding opaque white... p5's empty texture is an image
/// with pixel (0,0) set to 255 gray: (255, 255, 255, 255).
pub extern "js" fn create_white_texture(gl : GL) -> Texture =
  #|(gl) => {
  #|  const t = gl.createTexture();
  #|  gl.bindTexture(gl.TEXTURE_2D, t);
  #|  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([255, 255, 255, 255]));
  #|  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  #|  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  #|  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  #|  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  #|  gl.bindTexture(gl.TEXTURE_2D, null);
  #|  return t;
  #|}

///|
/// Reads RGBA pixels of the drawing buffer, top row first.
pub extern "js" fn read_pixels(
  gl : GL,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> FixedArray[Byte] =
  #|(gl, x, y, w, h) => {
  #|  const H = gl.drawingBufferHeight;
  #|  const buf = new Uint8Array(w * h * 4);
  #|  gl.readPixels(x, H - y - h, w, h, gl.RGBA, gl.UNSIGNED_BYTE, buf);
  #|  const out = new Uint8Array(w * h * 4), row = w * 4;
  #|  for (let i = 0; i < h; i++) out.set(buf.subarray((h - 1 - i) * row, (h - i) * row), i * row);
  #|  return out;
  #|}

///|
/// The texture for an image source (canvas, image, video), created on first
/// use and re-uploaded on each use (sources may change between frames).
/// `wrap_s`/`wrap_t` ("clamp", "repeat" or "mirror") and `filter`
/// ("linear" or "nearest") apply when the texture is created.
pub extern "js" fn texture_for(
  gl : GL,
  source : @dom.ImageElement,
  wrap_s : String,
  wrap_t : String,
  filter : String,
) -> Texture =
  #|(gl, src, ws, wt, filter) => {
  #|  if (!gl.__p5mbtTextures) gl.__p5mbtTextures = new Map();
  #|  let t = gl.__p5mbtTextures.get(src);
  #|  const prev = gl.getParameter(gl.TEXTURE_BINDING_2D);
  #|  const fresh = !t;
  #|  if (fresh) { t = gl.createTexture(); gl.__p5mbtTextures.set(src, t); }
  #|  gl.bindTexture(gl.TEXTURE_2D, t);
  #|  const isVideo = typeof HTMLVideoElement !== 'undefined' && src instanceof HTMLVideoElement;
  #|  const w = isVideo ? src.videoWidth : src.width, h = isVideo ? src.videoHeight : src.height;
  #|  if (w > 0 && h > 0) {
  #|    if (!(isVideo && !fresh && t.__time === src.currentTime)) {
  #|      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, src);
  #|      t.__time = isVideo ? src.currentTime : undefined;
  #|    }
  #|  } else if (fresh) {
  #|    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(4));
  #|  }
  #|  if (fresh) {
  #|    const wrap = m => m === 'repeat' ? gl.REPEAT : m === 'mirror' ? gl.MIRRORED_REPEAT : gl.CLAMP_TO_EDGE;
  #|    const f = filter === 'nearest' ? gl.NEAREST : gl.LINEAR;
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, f);
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, f);
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap(ws));
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap(wt));
  #|  }
  #|  gl.bindTexture(gl.TEXTURE_2D, prev);
  #|  return t;
  #|}

///|
/// Whether `p` has a sampler uniform named `name`.
pub extern "js" fn has_sampler(p : Program, name : String) -> Bool =
  #|(p, n) => !!(p.uniforms[n] && p.uniforms[n].isSampler)

///|
/// Clears the texture assigned to a sampler uniform.
pub extern "js" fn clear_sampler(p : Program, name : String) -> Unit =
  #|(p, n) => { const u = p.uniforms[n]; if (u) u.texture = undefined; }

///|
/// Sets the wrap mode of every texture created so far (p5's `textureWrap`
/// updates all existing textures).
pub extern "js" fn set_all_wrap(
  gl : GL,
  wrap_s : String,
  wrap_t : String,
) -> Unit =
  #|(gl, ws, wt) => {
  #|  if (!gl.__p5mbtTextures) return;
  #|  const wrap = m => m === 'repeat' ? gl.REPEAT : m === 'mirror' ? gl.MIRRORED_REPEAT : gl.CLAMP_TO_EDGE;
  #|  const prev = gl.getParameter(gl.TEXTURE_BINDING_2D);
  #|  for (const t of gl.__p5mbtTextures.values()) {
  #|    gl.bindTexture(gl.TEXTURE_2D, t);
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap(ws));
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap(wt));
  #|  }
  #|  gl.bindTexture(gl.TEXTURE_2D, prev);
  #|}

///|
/// A p5 framebuffer's GL objects: color/depth textures, and multisampled
/// renderbuffers when antialiased.
#external
pub type FBO

///|
/// Creates (or recreates, when `old` is given) a framebuffer's GL objects
/// like p5's `createFramebufferResources` + `recreateFramebufferTextures`.
pub extern "js" fn create_fbo(
  gl : GL,
  w : Int32,
  h : Int32,
  samples : Int32,
  use_depth : Bool,
  use_stencil : Bool,
  depth_float : Bool,
  alpha : Bool,
  linear : Bool,
  wrap_s : String,
  wrap_t : String,
) -> FBO =
  #|(gl, w, h, samples, useDepth, useStencil, depthFloat, alpha, linear, ws, wt) => {
  #|  const fb = { gl, w, h, samples, useDepth, useStencil, dirty: false };
  #|  fb.framebuffer = gl.createFramebuffer();
  #|  if (samples > 0) fb.aaFramebuffer = gl.createFramebuffer();
  #|  const prevTex = gl.getParameter(gl.TEXTURE_BINDING_2D);
  #|  const prevFb = gl.getParameter(gl.FRAMEBUFFER_BINDING);
  #|  const v2 = gl.__p5mbtVersion === 2;
  #|  const format = alpha ? gl.RGBA : gl.RGB;
  #|  const internal = v2 ? (alpha ? gl.RGBA8 : gl.RGB8) : format;
  #|  const wrap = m => m === 'repeat' ? gl.REPEAT : m === 'mirror' ? gl.MIRRORED_REPEAT : gl.CLAMP_TO_EDGE;
  #|  const params = (filter, s, t) => {
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filter);
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter);
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrap(s));
  #|    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrap(t));
  #|  };
  #|  fb.colorTexture = gl.createTexture();
  #|  gl.bindTexture(gl.TEXTURE_2D, fb.colorTexture);
  #|  gl.texImage2D(gl.TEXTURE_2D, 0, internal, w, h, 0, format, gl.UNSIGNED_BYTE, null);
  #|  gl.bindFramebuffer(gl.FRAMEBUFFER, fb.framebuffer);
  #|  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, fb.colorTexture, 0);
  #|  let dInternal, dFormat, dType;
  #|  if (useStencil) {
  #|    dType = depthFloat ? gl.FLOAT_32_UNSIGNED_INT_24_8_REV : gl.UNSIGNED_INT_24_8;
  #|    dFormat = gl.DEPTH_STENCIL;
  #|    dInternal = depthFloat ? gl.DEPTH32F_STENCIL8 : gl.DEPTH24_STENCIL8;
  #|  } else {
  #|    dType = depthFloat ? gl.FLOAT : gl.UNSIGNED_INT;
  #|    dFormat = gl.DEPTH_COMPONENT;
  #|    dInternal = depthFloat ? gl.DEPTH_COMPONENT32F : gl.DEPTH_COMPONENT24;
  #|  }
  #|  if (useDepth) {
  #|    fb.depthTexture = gl.createTexture();
  #|    gl.bindTexture(gl.TEXTURE_2D, fb.depthTexture);
  #|    gl.texImage2D(gl.TEXTURE_2D, 0, dInternal, w, h, 0, dFormat, dType, null);
  #|    gl.framebufferTexture2D(gl.FRAMEBUFFER, useStencil ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, fb.depthTexture, 0);
  #|  }
  #|  if (samples > 0) {
  #|    const n = Math.max(0, Math.min(samples, gl.getParameter(gl.MAX_SAMPLES)));
  #|    fb.colorRenderbuffer = gl.createRenderbuffer();
  #|    gl.bindRenderbuffer(gl.RENDERBUFFER, fb.colorRenderbuffer);
  #|    gl.renderbufferStorageMultisample(gl.RENDERBUFFER, n, internal, w, h);
  #|    if (useDepth) {
  #|      fb.depthRenderbuffer = gl.createRenderbuffer();
  #|      gl.bindRenderbuffer(gl.RENDERBUFFER, fb.depthRenderbuffer);
  #|      gl.renderbufferStorageMultisample(gl.RENDERBUFFER, n, dInternal, w, h);
  #|    }
  #|    gl.bindFramebuffer(gl.FRAMEBUFFER, fb.aaFramebuffer);
  #|    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, fb.colorRenderbuffer);
  #|    if (useDepth) gl.framebufferRenderbuffer(gl.FRAMEBUFFER, useStencil ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, fb.depthRenderbuffer);
  #|  }
  #|  // p5.Texture settings: color linear/nearest with the current wrap, depth nearest
  #|  gl.bindTexture(gl.TEXTURE_2D, fb.colorTexture);
  #|  params(linear ? gl.LINEAR : gl.NEAREST, ws, wt);
  #|  if (useDepth) { gl.bindTexture(gl.TEXTURE_2D, fb.depthTexture); params(gl.NEAREST, ws, wt); }
  #|  gl.bindTexture(gl.TEXTURE_2D, prevTex);
  #|  gl.bindFramebuffer(gl.FRAMEBUFFER, prevFb);
  #|  return fb;
  #|}

///|
/// Deletes a framebuffer's GL objects.
pub extern "js" fn delete_fbo(fb : FBO) -> Unit =
  #|(fb) => {
  #|  const gl = fb.gl;
  #|  gl.deleteTexture(fb.colorTexture); if (fb.depthTexture) gl.deleteTexture(fb.depthTexture);
  #|  if (fb.colorRenderbuffer) gl.deleteRenderbuffer(fb.colorRenderbuffer);
  #|  if (fb.depthRenderbuffer) gl.deleteRenderbuffer(fb.depthRenderbuffer);
  #|  gl.deleteFramebuffer(fb.framebuffer); if (fb.aaFramebuffer) gl.deleteFramebuffer(fb.aaFramebuffer);
  #|}

///|
/// Binds a framebuffer for drawing (its multisampled one when antialiased),
/// or the canvas.
pub fn bind_fbo(gl : GL, fb : FBO?) -> Unit {
  match fb {
    Some(f) => bind_fbo_js(gl, f)
    None => bind_canvas(gl)
  }
}

///|
extern "js" fn bind_fbo_js(gl : GL, fb : FBO) -> Unit =
  #|(gl, fb) => gl.bindFramebuffer(gl.FRAMEBUFFER, fb.aaFramebuffer || fb.framebuffer)

///|
extern "js" fn bind_canvas(gl : GL) -> Unit =
  #|(gl) => gl.bindFramebuffer(gl.FRAMEBUFFER, null)

///|
/// Marks an antialiased framebuffer's textures as needing a resolve.
pub extern "js" fn fbo_mark_dirty(fb : FBO) -> Unit =
  #|(fb) => { if (fb.aaFramebuffer) { fb.dirty = true; fb.dirtyDepth = true; } }

///|
/// Resolves multisampled contents into the textures (blit) when needed,
/// then rebinds `active` for drawing. `depth` picks the depth texture.
pub fn fbo_resolve(
  fb : FBO,
  depth : Bool,
  linear : Bool,
  active : FBO?,
) -> Unit {
  fbo_resolve_js(fb, depth, linear, active is Some(_), active.unwrap_or(fb))
}

///|
extern "js" fn fbo_resolve_js(
  fb : FBO,
  depth : Bool,
  linear : Bool,
  has_active : Bool,
  active : FBO,
) -> Unit =
  #|(fb, depth, linear, hasActive, active) => {
  #|  if (!fb.aaFramebuffer || !(depth ? fb.dirtyDepth : fb.dirty)) return;
  #|  const gl = fb.gl;
  #|  gl.bindFramebuffer(gl.READ_FRAMEBUFFER, fb.aaFramebuffer);
  #|  gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, fb.framebuffer);
  #|  gl.blitFramebuffer(0, 0, fb.w, fb.h, 0, 0, fb.w, fb.h, depth ? gl.DEPTH_BUFFER_BIT : gl.COLOR_BUFFER_BIT, depth || !linear ? gl.NEAREST : gl.LINEAR);
  #|  if (depth) fb.dirtyDepth = false; else fb.dirty = false;
  #|  gl.bindFramebuffer(gl.FRAMEBUFFER, hasActive ? (active.aaFramebuffer || active.framebuffer) : null);
  #|}

///|
/// The color (or depth) texture of a framebuffer.
pub extern "js" fn fbo_texture(fb : FBO, depth : Bool) -> Texture =
  #|(fb, depth) => depth ? fb.depthTexture : fb.colorTexture

///|
/// Reads a framebuffer's RGBA pixels, top row first.
pub fn fbo_read_pixels(
  fb : FBO,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  active : FBO?,
) -> FixedArray[Byte] {
  fbo_read_pixels_js(fb, x, y, w, h, active is Some(_), active.unwrap_or(fb))
}

///|
extern "js" fn fbo_read_pixels_js(
  fb : FBO,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
  has_active : Bool,
  active : FBO,
) -> FixedArray[Byte] =
  #|(fb, x, y, w, h, hasActive, active) => {
  #|  const gl = fb.gl;
  #|  gl.bindFramebuffer(gl.FRAMEBUFFER, fb.framebuffer);
  #|  const buf = new Uint8Array(w * h * 4);
  #|  gl.readPixels(x, fb.h - y - h, w, h, gl.RGBA, gl.UNSIGNED_BYTE, buf);
  #|  gl.bindFramebuffer(gl.FRAMEBUFFER, hasActive ? (active.aaFramebuffer || active.framebuffer) : null);
  #|  const out = new Uint8Array(w * h * 4), row = w * 4;
  #|  for (let i = 0; i < h; i++) out.set(buf.subarray((h - 1 - i) * row, (h - i) * row), i * row);
  #|  return out;
  #|}

///|
/// A plain WebGL context with default attributes for a helper canvas
/// (p5's FilterRenderer2D): only premultiplied uploads are set.
pub extern "js" fn create_plain_context(canvas : @dom.Canvas) -> GL =
  #|(canvas) => {
  #|  let gl = canvas.getContext('webgl2');
  #|  if (gl) gl.__p5mbtVersion = 2; else { gl = canvas.getContext('webgl'); gl.__p5mbtVersion = 1; }
  #|  gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  #|  gl.__p5mbtEnabled = new Set(); gl.__p5mbtCur = null;
  #|  return gl;
  #|}

///|
/// The canvas element of a context, as an image source.
pub extern "js" fn context_canvas(gl : GL) -> @dom.ImageElement = "(gl) => gl.canvas"
