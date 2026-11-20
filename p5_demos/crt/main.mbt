// A filter shader on a 2D sketch: an arcade-style scene is drawn normally,
// then `filter_shader` runs a CRT effect over the whole canvas — screen
// curvature, scanlines, RGB fringing and a vignette.

///|
let crt_frag : String =
  #|precision highp float;
  #|varying vec2 vTexCoord;
  #|uniform sampler2D tex0;
  #|uniform vec2 canvasSize;
  #|uniform float uTime;
  #|void main() {
  #|  vec2 uv = vTexCoord * 2.0 - 1.0;
  #|  uv *= 1.0 + 0.08 * dot(uv.yx, uv.yx);
  #|  vec2 t = uv * 0.5 + 0.5;
  #|  if (t.x < 0.0 || t.x > 1.0 || t.y < 0.0 || t.y > 1.0) {
  #|    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  #|    return;
  #|  }
  #|  float shift = 1.5 / canvasSize.x;
  #|  vec3 col = vec3(
  #|    texture2D(tex0, t + vec2(shift, 0.0)).r,
  #|    texture2D(tex0, t).g,
  #|    texture2D(tex0, t - vec2(shift, 0.0)).b
  #|  );
  #|  float scan = 0.82 + 0.18 * sin(t.y * canvasSize.y * 3.14159 + uTime * 6.0);
  #|  float vignette = smoothstep(1.35, 0.4, length(uv));
  #|  gl_FragColor = vec4(col * scan * vignette * 1.15, 1.0);
  #|}

///|
fn main {
  let crt : Ref[@p5.Shader?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(720, 480)
      crt.val = Some(p.create_filter_shader(crt_frag))
      p.text_font("monospace")
    },
    draw=p => {
      let t = p.millis() / 1000
      p.background((10, 12, 30))
      // a starfield
      p.no_stroke()
      for i in 0..<80 {
        let x = (i.to_double() * 97.0 + t * (20.0 + (i % 5).to_double() * 25)) %
          720
        let y = i.to_double() * 53.0 % 480
        p.fill((200, 210, 255, 90.0 + (i % 3).to_double() * 60))
        p.circle(x, y, 2)
      }
      // a sunset sun with stripes
      p.fill((255, 120, 80))
      p.circle(360, 300, 220)
      p.fill((10, 12, 30))
      for k in 0..<6 {
        p.rect(
          240,
          300.0 + k.to_double() * 18 + t * 10 % 18,
          240,
          4.0 + k.to_double(),
        )
      }
      // a grid floor in perspective
      p.stroke((255, 60, 200))
      p.stroke_weight(2)
      for k in 0..<12 {
        let z = (k.to_double() + t * 2) % 12 / 12
        let y = 330.0 + z * z * 160
        p.line(0, y, 720, y)
      }
      for k in -10..<=10 {
        p.line(360 + k.to_double() * 20, 330, 360 + k.to_double() * 120, 480)
      }
      // title
      p.no_stroke()
      p.fill((255, 240, 120))
      p.text_align(HCenter)
      p.text_size(44)
      p.text("P5.MBT", 360, 120)
      p.text_size(16)
      p.fill((140, 255, 220))
      if (t * 2).floor().to_int() % 2 == 0 {
        p.text("INSERT COIN", 360, 160)
      }
      guard crt.val is Some(s) else { return }
      p.set_uniform(s, "uTime", [t])
      p.filter_shader(s)
    },
  )
}
