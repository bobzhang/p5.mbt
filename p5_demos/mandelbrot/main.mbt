// A Mandelbrot zoom computed per pixel in a fragment shader: the sketch
// draws one plane covering the canvas, and the shader colors each pixel by
// how fast its point escapes.

///|
let vert : String =
  #|precision highp float;
  #|attribute vec3 aPosition;
  #|attribute vec2 aTexCoord;
  #|uniform mat4 uModelViewMatrix;
  #|uniform mat4 uProjectionMatrix;
  #|varying vec2 vUv;
  #|void main() {
  #|  vUv = aTexCoord;
  #|  gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0);
  #|}

///|
let frag : String =
  #|precision highp float;
  #|varying vec2 vUv;
  #|uniform vec2 uCenter;
  #|uniform float uScale;
  #|uniform float uAspect;
  #|uniform float uTime;
  #|vec3 palette(float t) {
  #|  return 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.10, 0.20) + t + vec3(0.6, 0.4, 0.3) * uTime * 0.05));
  #|}
  #|void main() {
  #|  vec2 c = uCenter + (vUv - 0.5) * vec2(uAspect, 1.0) * uScale;
  #|  vec2 z = vec2(0.0);
  #|  float n = 0.0;
  #|  for (int i = 0; i < 400; i++) {
  #|    z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
  #|    if (dot(z, z) > 256.0) break;
  #|    n += 1.0;
  #|  }
  #|  if (n >= 400.0) { gl_FragColor = vec4(0.02, 0.02, 0.05, 1.0); return; }
  #|  // smooth iteration count
  #|  float sn = n - log2(log2(dot(z, z))) + 4.0;
  #|  gl_FragColor = vec4(palette(sn * 0.02), 1.0);
  #|}

///|
fn main {
  let shader : Ref[@p5.Shader?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      shader.val = Some(p.create_shader(vert, frag))
    },
    draw=p => {
      guard shader.val is Some(sh) else { return }
      let t = p.millis() / 1000.0
      // zoom in towards the seahorse valley, then start over
      let cycle = t % 24.0
      let scale = 3.0 * @p5.exp(-cycle * 0.42)
      p.shader(sh)
      p.set_uniform(sh, "uCenter", [-0.743643887, 0.131825904])
      p.set_uniform(sh, "uScale", [scale])
      p.set_uniform(sh, "uAspect", [p.width / p.height])
      p.set_uniform(sh, "uTime", [t])
      p.no_stroke()
      p.plane(w=p.width, h=p.height)
    },
  )
}
