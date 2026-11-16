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
