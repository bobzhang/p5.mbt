// Flying over Perlin-noise terrain in WEBGL. The mesh is rebuilt every
// frame from triangle strips with per-vertex colors; distance fog is added
// to p5's material shader through a `getFinalColor` hook.

///|
let cols : Int32 = 60

///|
let rows : Int32 = 46

///|
let cell : Double = 22

///|
fn height_color(h : Double) -> (Double, Double, Double) {
  if h < -40 {
    (40, 90, 160)
  } else if h < -20 {
    (210, 200, 150)
  } else if h < 40 {
    (60 + h, 140 + h * 0.5, 70)
  } else {
    (235, 235, 240)
  }
}

///|
fn main {
  let fog : Ref[@p5.Shader?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(720, 420, renderer=WebGL)
      // p5's lit material shader with fog mixed in at the end
      fog.val = p
        .base_material_shader()
        .map(s => {
          s.modify(fragment=[
            (
              "vec4 getFinalColor", "(vec4 color, vec2 texCoord) { float d = gl_FragCoord.z / gl_FragCoord.w; float f = smoothstep(350.0, 1100.0, d); color.rgb = mix(color.rgb, vec3(0.72, 0.82, 0.95) * color.a, f); return color; }",
            ),
          ])
        })
    },
    draw=p => {
      p.background((184, 209, 242))
      let fly = p.frame_count.to_double() * 0.02
      p.camera(eye=(0, -170, 260), center=(0, -40, -200), up=(0, 1, 0))
      p.ambient_light(110)
      p.directional_light((255, 245, 225), -0.4, 0.8, -0.5)
      if fog.val is Some(s) {
        p.shader(s)
      }
      p.no_stroke()
      p.push()
      p.rotate_x(@p5.HALF_PI)
      p.translate(-cols.to_double() * cell / 2, -rows.to_double() * cell + 120)
      let h = (x : Int32, y : Int32) => {
        let n = p.noise(
          x.to_double() * 0.09,
          y=(y.to_double() - fly * 10) * 0.09,
        )
        (n - 0.45) * 260
      }
      for y in 0..<(rows - 1) {
        p.begin_shape(kind=TriangleStrip)
        for x in 0..<cols {
          for dy in 0..<2 {
            let z = h(x, y + dy).max(-40)
            let (r, g, b) = height_color(z)
            p.fill((r, g, b))
            p.vertex(x.to_double() * cell, (y + dy).to_double() * cell, z~)
          }
        }
        p.end_shape()
      }
      p.pop()
    },
  )
}
