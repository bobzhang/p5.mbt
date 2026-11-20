// The Lorenz attractor: three coupled equations whose solution never
// settles and never repeats. The trace grows as a 3D line whose color
// follows its speed; drag to orbit.

///|
fn main {
  let pts : Array[(Double, Double, Double, Double)] = []
  let mut x = -8.0
  let mut y = 8.0
  let mut z = 27.0
  fn step(n : Int32) {
    let (sigma, rho, beta, dt) = (10.0, 28.0, 8.0 / 3.0, 0.006)
    for _ in 0..<n {
      let dx = sigma * (y - x)
      let dy = x * (rho - z) - y
      let dz = x * y - beta * z
      x += dx * dt
      y += dy * dt
      z += dz * dt
      if pts.length() < 9000 {
        pts.push((x, y, z, (dx * dx + dy * dy + dz * dz).sqrt()))
      }
    }
  }
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      p.camera(eye=(0, 0, 520), center=(0, 0, 0), up=(0, 1, 0))
      step(1500) // start with a visible trace
    },
    draw=p => {
      p.background((8, 8, 16))
      p.orbit_control()
      step(20)
      p.rotate_y(p.frame_count.to_double() * 0.004)
      p.scale(5.2)
      p.translate(0, 0, z=-25)
      p.no_fill()
      p.stroke_weight(1.5)
      p.color_mode(HSB)
      p.begin_shape()
      for q in pts {
        let (px, py, pz, speed) = q
        p.stroke((180.0 + (speed * 1.2).min(150), 80.0, 100.0))
        p.vertex(px, py, z=pz)
      }
      p.end_shape()
      p.color_mode(RGB)
      // the moving head
      p.no_stroke()
      p.fill(255)
      p.translate(x, y, z~)
      p.sphere(r=0.6, detail_x=8, detail_y=6)
    },
  )
}
