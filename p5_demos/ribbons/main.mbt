// Custom vertex properties: every vertex of these ribbons carries
// `aProgress`, how far along its ribbon it is, set with `vertex_property`.
// Hooks added to p5's color shader pass it to the fragment shader, which
// paints stripes flowing along each ribbon.

///|
let vertex_decls : String =
  #|IN float aProgress;
  #|OUT float vProgress;

///|
let fragment_decls : String =
  #|IN float vProgress;
  #|uniform float uTime;

///|
let object_inputs : String =
  #|(Vertex inputs) {
  #|  vProgress = aProgress;
  #|  return inputs;
  #|}

///|
let final_color : String =
  #|(vec4 color, vec2 texCoord) {
  #|  float s = fract(vProgress * 14.0 - uTime * 0.8);
  #|  float stripe = smoothstep(0.0, 0.08, s) * (1.0 - smoothstep(0.45, 0.53, s));
  #|  vec3 c = mix(color.rgb * 0.25, color.rgb, stripe);
  #|  float fade = smoothstep(0.0, 0.08, vProgress) * (1.0 - smoothstep(0.92, 1.0, vProgress));
  #|  return vec4(c * fade, color.a * fade);
  #|}

///|
fn main {
  let shader : Ref[@p5.Shader?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      if p.base_color_shader() is Some(base) {
        shader.val = Some(
          base.modify(
            vertex=[("Vertex getObjectInputs", object_inputs)],
            fragment=[("vec4 getFinalColor", final_color)],
            vertex_declarations=vertex_decls,
            fragment_declarations=fragment_decls,
          ),
        )
      }
    },
    draw=p => {
      guard shader.val is Some(sh) else { return }
      let t = p.millis() / 1000
      p.background((10, 8, 20))
      p.orbit_control()
      p.rotate_y(t * 0.2)
      p.set_uniform(sh, "uTime", [t])
      p.shader(sh)
      p.no_stroke()
      let colors = [
        (255, 90, 120),
        (90, 200, 255),
        (255, 210, 80),
        (150, 255, 160),
      ]
      for k, c in colors {
        let kf = k.to_double()
        p.fill(c)
        p.begin_shape(kind=TriangleStrip)
        let n = 240
        let at = (u : Double) => {
          let a = u * @p5.TWO_PI * 2
          // a 3D Lissajous curve, different per ribbon
          (
            230.0 * p.sin(a + kf * 0.8),
            150.0 * p.sin(a * 1.5 + kf * 1.3 + t * 0.3),
            230.0 * p.cos(a + kf * 0.8),
          )
        }
        for i in 0..<=n {
          let u = i.to_double() / n.to_double()
          let (x, y, z) = at(u)
          // widen the ribbon across its direction of travel and its radius
          let (x2, y2, z2) = at(u + 0.001)
          let (tx, ty, tz) = (x2 - x, y2 - y, z2 - z)
          let (bx, by, bz) = (ty * z - tz * y, tz * x - tx * z, tx * y - ty * x)
          let len = (bx * bx + by * by + bz * bz).sqrt().max(1.0e-9)
          let w = 10.0 + 6 * p.sin(u * @p5.TWO_PI * 6 + t)
          let (ox, oy, oz) = (bx / len * w, by / len * w, bz / len * w)
          p.vertex_property("aProgress", [u])
          p.vertex(x - ox, y - oy, z=z - oz)
          p.vertex_property("aProgress", [u])
          p.vertex(x + ox, y + oy, z=z + oz)
        }
        p.end_shape()
      }
    },
  )
}
