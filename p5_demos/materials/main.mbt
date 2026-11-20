// MTL materials: `load_model` reads the OBJ's `mtllib` file and its
// texture maps. The model is split into one part per material — brick
// walls with a color texture and a normal map, a glossy roof, a door and
// grass — and `model()` draws each with its own material.

///|
fn main {
  let house : Ref[@p5.Geometry?] = Ref(None)
  @p5.run(
    preload=p => house.val = Some(p.load_model("../assets/models/house.obj")),
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      p.camera(eye=(220, -200, 320), center=(0, -40, 0), up=(0, 1, 0))
    },
    draw=p => {
      guard house.val is Some(h) else { return }
      let t = p.millis() / 1000
      p.background((170, 205, 235))
      p.orbit_control()
      p.ambient_light((150, 150, 160))
      p.directional_light((255, 245, 225), -0.5, 0.6, -0.6)
      p.point_light((255, 200, 140), p.cos(t) * 160, -120, p.sin(t) * 160)
      p.no_stroke()
      p.fill(255)
      p.rotate_y(t * 0.25)
      p.model(h)
    },
  )
}
