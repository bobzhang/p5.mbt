///|
/// Images: loading, filters, tint, pixels and off-screen graphics.
fn main {
  let img : Ref[@p5.Image?] = Ref::new(None)
  @p5.run(
    preload=p => img.val = Some(p.load_image("../assets/landscape.svg")),
    setup=p => {
      p.create_canvas(640, 420)
      @p5.set_title("p5.mbt — images")
      p.no_loop()
    },
    draw=p => {
      guard img.val is Some(src) else { return }
      p.background(250)
      p.text_size(13)
      p.text_align(HCenter)
      let labels = [
        "original", "Gray", "Invert", "Threshold", "Posterize(3)", "Blur(3)", "Erode",
        "tint",
      ]
      let filters : Array[@p5.Filter?] = [
        None,
        Some(Gray),
        Some(Invert),
        Some(Threshold(0.5)),
        Some(Posterize(3)),
        Some(Blur(3)),
        Some(Erode),
        None,
      ]
      for i, label in labels {
        let x = 10.0 + (i % 4).to_double() * 157
        let y = 10.0 + (i / 4).to_double() * 170
        let copy = src.copy()
        if filters[i] is Some(f) {
          copy.filter(f)
        }
        if label == "tint" {
          p.tint((255, 120, 200, 200))
        }
        p.image(copy, x, y, w=147, h=147)
        p.no_tint()
        p.fill(30)
        p.no_stroke()
        p.text(label, x + 73, y + 162)
      }
      // A gradient built pixel by pixel.
      let grad = p.create_image(147, 40)
      for yy in 0..<40 {
        for xx in 0..<147 {
          let c = @p5.Color::rgb(
            xx.to_double() * 255 / 146,
            80,
            255 - yy.to_double() * 6,
          )
          grad.set(xx.to_double(), yy.to_double(), c)
        }
      }
      grad.update_pixels()
      p.image(grad, 10, 350)
      // An off-screen graphics buffer.
      let g = p.create_graphics(147, 40)
      g.background((20, 20, 40))
      g.fill("white")
      g.text_size(16)
      g.text_align(HCenter, vertical=VCenter)
      g.text("graphics buffer", 73, 20)
      p.image(g, 167, 350)
      // Read back a pixel from the canvas.
      let c = p.get(20, 20)
      p.fill(c)
      p.stroke(0)
      p.rect(324, 350, 40, 40)
      p.no_stroke()
      p.fill(30)
      p.text_align(Left)
      p.text("get(20, 20) = \{c}", 372, 375)
    },
  )
}
