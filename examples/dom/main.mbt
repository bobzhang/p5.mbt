///|
/// DOM elements: radio buttons, file input, dropping files on the canvas,
/// and a video drawn on the canvas as a mosaic.
fn main {
  let video : Ref[@p5.MediaElement?] = Ref(None)
  let shape : Ref[@p5.Element?] = Ref(None)
  let message = Ref("drop an image on the canvas")
  let dropped : Ref[@p5.Image?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(480, 300)
      @p5.set_title("p5.mbt — DOM")
      let v = p.create_video(["../assets/testcard.mp4"], on_load=v => {
        v.volume(0)
        v.loop_()
      })
      v.hide()
      video.val = Some(v)
      let r = p.create_radio(name="shape")
      r.option("circle")
      r.option("square")
      r.option("none", value="no tiles")
      r.selected("circle")
      shape.val = Some(r)
      let _ = p.create_file_input(f => {
        message.val = "picked \{f.name} (\{f.file_type}/\{f.subtype}, \{f.size} bytes)"
        if f.file_type == "image" {
          dropped.val = Some(p.load_image(f.data))
        }
      })
      if p.canvas_element() is Some(c) {
        c.drop(f => {
          message.val = "dropped \{f.name}"
          if f.file_type == "image" {
            dropped.val = Some(p.load_image(f.data))
          }
        })
      }
    },
    draw=p => {
      p.background(30)
      guard video.val is Some(v) else { return }
      // the video, as it is
      p.image(v, 10, 10, w=160, h=120)
      // and as tiles sampled from its pixels
      v.load_pixels()
      let mode = shape.val.map(e => e.value()).unwrap_or("circle")
      let step = 8
      p.no_stroke()
      if v.pixels.length() > 0 && mode != "none" {
        let w = v.width.to_int()
        for y = 0; y < v.height.to_int(); y = y + step {
          for x = 0; x < w; x = x + step {
            let i = (y * w + x) * 4
            p.fill(
              (
                v.pixels[i].to_int(),
                v.pixels[i + 1].to_int(),
                v.pixels[i + 2].to_int(),
              ),
            )
            let px = 190.0 + x.to_double() * 1.7
            let py = 10.0 + y.to_double() * 1.7
            if mode == "circle" {
              p.circle(px + 6, py + 6, 12)
            } else {
              p.square(px, py, 12)
            }
          }
        }
      }
      if dropped.val is Some(img) {
        p.image(img, 10, 150, w=160, h=120)
      }
      p.fill(230)
      p.text_size(14)
      p.text(message.val, 190, 230, max_width=280)
      p.text(
        "t = \{@p5.nf(v.time(), right=2)} s of \{@p5.nf(v.duration(), right=2)}",
        190,
        280,
      )
    },
  )
}
