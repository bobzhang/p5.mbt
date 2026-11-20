// A spiral galaxy of 12,000 stars, drawn as one point shape with a color
// per vertex: a bright bulge, two arms and a dusting of halo stars.

///|
fn main {
  let stars : Array[(Double, Double, Double, (Double, Double, Double))] = []
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      p.camera(eye=(0, -380, 520), center=(0, 0, 0), up=(0, 1, 0))
      for i in 0..<12000 {
        let arm = (i % 2).to_double() * @p5.PI
        let r = @p5.pow(p.random(), 1.6) * 340
        let a = arm + r * 0.018 + p.random_gaussian(sd=0.35)
        let spread = 8.0 + r * 0.08
        let x = p.cos(a) * r + p.random_gaussian(sd=spread)
        let z = p.sin(a) * r + p.random_gaussian(sd=spread)
        let y = p.random_gaussian(sd=6.0 + 30 * @p5.exp(-r / 60))
        let warm = @p5.exp(-r / 90)
        stars.push(
          (x, y, z, (255.0, 210.0 + 45 * warm, 160.0 + 95 * (1.0 - warm))),
        )
      }
    },
    draw=p => {
      p.background((2, 2, 8))
      p.orbit_control()
      p.rotate_y(p.frame_count.to_double() * 0.0025)
      p.stroke_weight(2)
      p.begin_shape(kind=Points)
      for s in stars {
        let (x, y, z, c) = s
        p.stroke(c)
        p.vertex(x, y, z~)
      }
      p.end_shape()
    },
  )
}
