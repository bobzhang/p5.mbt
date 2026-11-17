// Video-feedback trails with two framebuffers: each frame draws the
// previous one slightly zoomed, rotated and faded, then new shapes on top.

///|
fn main {
  let fbs : Ref[Array[@p5.Framebuffer]] = Ref([])
  @p5.run(
    setup=p => {
      p.create_canvas(600, 600, renderer=WebGL)
      for _ in 0..<2 {
        if p.create_framebuffer() is Some(fb) {
          fbs.val.push(fb)
        }
      }
    },
    draw=p => {
      guard fbs.val is [prev, next] else { return }
      let t = p.frame_count.to_double() * 0.02
      next.draw(() => {
        p.background(0)
        // the previous frame, zoomed and turned a little, fading
        p.push()
        p.rotate_z(0.012)
        p.scale(1.012)
        p.tint((255, 255, 255, 250))
        p.image_mode(Center)
        p.image(prev, 0, 0)
        p.pop()
        // fresh shapes
        p.no_stroke()
        p.color_mode(HSB)
        for i in 0..<3 {
          let a = t * 1.7 + i.to_double() * @p5.TWO_PI / 3
          p.fill(((t * 40 + i.to_double() * 120) % 360, 80, 100))
          p.push()
          p.translate(p.cos(a) * 160, p.sin(a * 1.3) * 160)
          p.rotate_z(a)
          p.rect(-14, -14, 28, 28, tl=6)
          p.pop()
        }
        p.color_mode(RGB)
      })
      p.background(0)
      p.image_mode(Center)
      p.image(next, 0, 0)
      // swap
      fbs.val = [next, prev]
    },
  )
}
