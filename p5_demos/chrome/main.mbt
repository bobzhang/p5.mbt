// Image-based lighting: a 360° sky is painted into a graphics buffer at
// startup, shown around the scene with `panorama` and used as the light
// with `image_light`, so polished metal reflects it.

///|
/// Paints an equirectangular sky: a gradient, a sun, distant hills and a
/// checkered floor.
fn paint_sky(g : @p5.P5) -> Unit {
  let w = g.width
  let h = g.height
  g.no_stroke()
  for y in 0..<h.to_int() {
    let t = y.to_double() / h
    let c = if t < 0.5 {
      g.lerp_color(
        g.color((40, 90, 190)),
        g.color((250, 190, 140)),
        @p5.pow(t / 0.5, 1.8),
      )
    } else {
      g.lerp_color(g.color((70, 60, 70)), g.color((20, 18, 26)), (t - 0.5) / 0.5)
    }
    g.fill(c)
    g.rect(0, y.to_double(), w, 1)
  }
  // sun with a glow
  for i in 0..<30 {
    let r = 140.0 - i.to_double() * 4.5
    g.fill((255, 240, 200, 10.0 + i.to_double() * 3))
    g.circle(w * 0.3, h * 0.36, r)
  }
  g.fill((255, 252, 235))
  g.circle(w * 0.3, h * 0.36, 26)
  // hills on the horizon
  g.fill((60, 70, 90))
  g.begin_shape()
  g.vertex(0, h * 0.5)
  for i in 0..=64 {
    let x = i.to_double() / 64 * w
    g.vertex(x, h * 0.5 - 18 - 30 * g.noise(i.to_double() * 0.25))
  }
  g.vertex(w, h * 0.5)
  g.end_shape(mode=Close)
  // checkered floor
  for i in 0..<32 {
    for j in 0..<8 {
      if (i + j) % 2 == 0 {
        g.fill((235, 230, 220, 60))
        g.rect(
          i.to_double() * w / 32,
          h * 0.5 + j.to_double() * h / 16,
          w / 32,
          h / 16,
        )
      }
    }
  }
}

///|
fn main {
  let sky : Ref[@p5.P5?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      let g = p.create_graphics(1024, 512)
      paint_sky(g)
      sky.val = Some(g)
      p.camera(eye=(0, -40, 420), center=(0, 0, 0), up=(0, 1, 0))
    },
    draw=p => {
      guard sky.val is Some(g) else { return }
      p.background(0)
      p.orbit_control()
      p.panorama(g)
      p.image_light(g)
      p.no_stroke()
      let t = p.millis() / 1000
      // a ring of spheres from rough to mirror-like
      for i in 0..<6 {
        let a = i.to_double() / 6 * @p5.TWO_PI + t * 0.3
        p.push()
        p.translate(p.cos(a) * 170, 30, z=p.sin(a) * 170)
        p.fill((220, 225, 235))
        p.specular_material((255, 255, 255))
        p.shininess(10.0 + i.to_double() * 60)
        p.metalness(i.to_double() * 20)
        p.sphere(r=38, detail_x=48, detail_y=32)
        p.pop()
      }
      // a gold knot in the middle
      p.push()
      p.rotate_y(t * 0.6)
      p.rotate_x(t * 0.4)
      p.fill((255, 190, 90))
      p.specular_material((255, 220, 160))
      p.shininess(120)
      p.metalness(100)
      p.torus(r=60, tube=22, detail_x=64, detail_y=24)
      p.pop()
    },
  )
}
