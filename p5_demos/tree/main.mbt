// A recursive fractal tree. Each branch splits in two; Perlin noise bends
// the branches like wind, and blossoms open at the tips.

///|
fn branch(p : @p5.P5, len : Double, depth : Int32, wind : Double) -> Unit {
  p.stroke_weight((depth.to_double() * 1.2).max(1))
  p.stroke((70 + (10 - depth) * 12, 50 + (10 - depth) * 8, 40))
  p.line(0, 0, 0, -len)
  p.translate(0, -len)
  if depth == 0 {
    p.no_stroke()
    p.fill((255, 180, 200, 210))
    p.circle(0, 0, 9)
    return
  }
  let sway = (p.noise(depth.to_double() * 0.7, y=wind) - 0.5) * 0.5
  for side in [-1.0, 1.0] {
    p.push()
    p.rotate(side * (0.38 + depth.to_double() * 0.012) + sway)
    branch(p, len * 0.74, depth - 1, wind + side * 0.3)
    p.pop()
  }
}

///|
fn main {
  @p5.run(setup=p => p.create_canvas(820, 600), draw=p => {
    p.background((238, 232, 218))
    p.no_stroke()
    p.fill((210, 200, 180))
    p.ellipse(p.width / 2, p.height - 20, 520, h=60)
    p.translate(p.width / 2, p.height - 30)
    branch(p, 120, 10, p.frame_count.to_double() * 0.01)
  })
}
