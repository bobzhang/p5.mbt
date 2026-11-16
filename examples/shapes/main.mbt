///|
/// Basic shapes, colors, transforms and mouse input.
fn main {
  @p5.run(
    setup=p => {
      p.create_canvas(600, 400)
      @p5.set_title("p5.mbt — shapes")
    },
    draw=p => {
      p.background(240)
      // Primitives
      p.stroke(30)
      p.stroke_weight(2)
      p.fill((237, 34, 93))
      p.rect(30, 30, 100, 70, tl=12)
      p.fill((0, 150, 200, 180))
      p.ellipse(220, 65, 120, h=70)
      p.fill("gold")
      p.triangle(300, 100, 350, 30, 400, 100)
      p.no_fill()
      p.arc(480, 65, 90, 90, 0, @p5.PI + @p5.QUARTER_PI, mode=Pie)
      p.line(30, 130, 570, 130)
      // Bezier and spline curves
      p.stroke((80, 80, 200))
      p.stroke_weight(4)
      p.bezier(30, 250, 90, 150, 170, 350, 230, 250)
      p.stroke((200, 80, 80))
      p.begin_shape()
      p.spline_vertex(260, 250)
      p.spline_vertex(300, 180)
      p.spline_vertex(360, 300)
      p.spline_vertex(420, 200)
      p.end_shape()
      // A star with a hole, using contours
      p.push()
      p.translate(510, 250)
      p.rotate(p.frame_count.to_double() * 0.01)
      p.fill((120, 200, 120))
      p.stroke_weight(1)
      p.begin_shape()
      for i in 0..<10 {
        let r = if i % 2 == 0 { 50.0 } else { 22.0 }
        let a = i.to_double() * @p5.PI / 5
        p.vertex(r * p.cos(a), r * p.sin(a))
      }
      p.begin_contour()
      for i in 0..<5 {
        let a = -i.to_double() * @p5.TWO_PI / 5
        p.vertex(10 * p.cos(a), 10 * p.sin(a))
      }
      p.end_contour(mode=Close)
      p.end_shape(mode=Close)
      p.pop()
      // HSB rainbow strip
      p.push()
      p.color_mode(HSB)
      p.no_stroke()
      for i in 0..<60 {
        p.fill((i * 6, 80, 95))
        p.rect(30 + i.to_double() * 9, 320, 9, 20)
      }
      p.pop()
      // Follow the mouse
      p.no_stroke()
      p.fill(
        if p.mouse_is_pressed {
          (255, 120, 0, 200)
        } else {
          (0, 0, 0, 80)
        },
      )
      p.circle(p.mouse_x, p.mouse_y, 30)
      p.fill(0)
      p.text(
        "frame \{p.frame_count}  mouse \{@p5.round(p.mouse_x)}, \{@p5.round(p.mouse_y)}",
        30,
        380,
      )
    },
  )
}
