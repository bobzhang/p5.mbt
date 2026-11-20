// Accessibility: p5 can describe a canvas for people using screen readers.
// `describe` and `describe_element` add written descriptions; `text_output`
// and `grid_output` generate a description of the shapes on the canvas
// every frame. With `Label` they are also shown under the canvas.

///|
fn main {
  @p5.run(
    setup=p => {
      p.create_canvas(480, 320)
      p.describe(
        "A small house under a sky. The sun moves across the sky as time passes",
        display=Label,
      )
      p.describe_element("Sun", "Yellow circle crossing the sky", display=Label)
      p.describe_element("House", "Red square with a brown roof", display=Label)
      p.text_output(display=Label)
      p.grid_output(display=Label)
      p.frame_rate(4)
    },
    draw=p => {
      let t = p.frame_count.to_double() * 0.05
      p.background((135, 206, 235))
      // ground
      p.no_stroke()
      p.fill((60, 160, 70))
      p.rect(0, 240, 480, 80)
      // the sun travels in an arc
      let sx = 240.0 + 200 * p.cos(@p5.PI + t % @p5.PI)
      let sy = 220.0 - 170 * p.sin(t % @p5.PI)
      p.fill((255, 220, 0))
      p.circle(sx, sy, 50)
      // the house
      p.fill((200, 40, 40))
      p.square(180, 150, 100)
      p.fill((120, 70, 30))
      p.triangle(170, 150, 230, 95, 290, 150)
      // a path to the door
      p.stroke((90, 60, 40))
      p.stroke_weight(4)
      p.line(230, 250, 210, 315)
    },
  )
}
