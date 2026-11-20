// 3D type: `text_to_model` turns the outline of each letter into a solid,
// extruded model. The letters wave in turn under colored lights.

///|
fn main {
  let font : Ref[@p5.Font?] = Ref(None)
  let letters : Array[(@p5.Geometry, Double)] = []
  @p5.run(
    preload=p => {
      font.val = Some(p.load_font("../assets/SourceSansPro-Regular.otf"))
    },
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      guard font.val is Some(f) else { return }
      p.text_font_face(f, size=150)
      // one model per letter, so each can move on its own
      let word = "p5.mbt"
      let mut x = 0.0
      for ch in word {
        let s = ch.to_string()
        let g = f.text_to_model(s, 0, 0, extrude=36, sample_factor=0.4)
        letters.push((g, x))
        let w = p.text_width(s)
        x += w + 16
      }
      // center the word
      let total = x - 16
      for i, l in letters {
        letters[i] = (l.0, l.1 - total / 2)
      }
    },
    draw=p => {
      p.background((14, 16, 26))
      p.orbit_control()
      let t = p.millis() / 1000
      p.ambient_light((40, 40, 60))
      p.directional_light((255, 230, 200), 0.4, 0.5, -1)
      p.point_light((80, 160, 255), p.cos(t) * 400, -200, 300)
      p.point_light((255, 80, 160), -p.cos(t) * 400, 200, 300)
      p.rotate_y(p.sin(t * 0.4) * 0.35)
      p.rotate_x(-0.15)
      p.no_stroke()
      for i, l in letters {
        let (g, x) = l
        p.push()
        let phase = t * 2.2 - i.to_double() * 0.6
        p.translate(x, 50 - 30 * @p5.pow(p.sin(phase).max(0), 3), z=0)
        p.rotate_x(0.2 * p.sin(phase))
        p.fill((240, 240, 250))
        p.specular_material((255, 255, 255))
        p.shininess(60)
        p.model(g)
        p.pop()
      }
    },
  )
}
