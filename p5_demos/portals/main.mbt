// Clipping in WEBGL: a rotating star-shaped mask, drawn into the stencil
// buffer with `begin_clip` / `end_clip`, shows a warm scene inside and —
// with `invert=true` — a cool one outside.

///|
fn star(p : @p5.P5, r : Double, t : Double) -> Unit {
  p.begin_shape()
  for i in 0..<10 {
    let a = i.to_double() / 10 * @p5.TWO_PI + t
    let rr = if i % 2 == 0 { r } else { r * 0.45 }
    p.vertex(p.cos(a) * rr, p.sin(a) * rr)
  }
  p.end_shape(mode=Close)
}

///|
fn scene(p : @p5.P5, t : Double, warm : Bool) -> Unit {
  p.no_stroke()
  for i in 0..<12 {
    let a = i.to_double() / 12 * @p5.TWO_PI +
      t * (if warm { 0.4 } else { -0.3 })
    p.push()
    p.translate(p.cos(a) * 230, p.sin(a * 2) * 60, z=p.sin(a) * 230)
    p.rotate_x(t + i.to_double())
    p.rotate_y(t * 0.7)
    if warm {
      p.fill((255, 150.0 + i.to_double() * 8, 60))
      p.torus(r=34, tube=12)
    } else {
      p.fill((80, 140.0 + i.to_double() * 8, 255))
      p.box(w=56)
    }
    p.pop()
  }
  p.fill(if warm { (255, 230, 160) } else { (200, 230, 255) })
  p.sphere(r=if warm { 70 } else { 50 })
}

///|
fn main {
  @p5.run(setup=p => p.create_canvas(820, 560, renderer=WebGL), draw=p => {
    let t = p.millis() / 1000
    p.background((12, 12, 20))
    p.orbit_control()
    p.ambient_light((60, 60, 70))
    p.directional_light((255, 255, 255), 0.4, 0.6, -1)
    // inside the star
    p.push()
    p.begin_clip()
    star(p, 230, t * 0.3)
    p.end_clip()
    // a backdrop (background() clears the whole canvas, ignoring the clip)
    p.push()
    p.translate(0, 0, z=-600)
    p.no_lights()
    p.no_stroke()
    p.fill((70, 28, 20))
    p.plane(w=4000)
    p.pop()
    scene(p, t, true)
    p.pop()
    // outside the star
    p.push()
    p.begin_clip(invert=true)
    star(p, 230, t * 0.3)
    p.end_clip()
    scene(p, t, false)
    p.pop()
  })
}
