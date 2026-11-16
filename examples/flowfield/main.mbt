///|
struct Particle {
  pos : @p5.Vector
  prev : @p5.Vector
  vel : @p5.Vector
}

///|
/// Particles following a Perlin-noise flow field, with DOM controls.
fn main {
  let particles : Array[Particle] = []
  let scale : Ref[@p5.Element?] = Ref(None)
  let speed : Ref[@p5.Element?] = Ref(None)
  let spawn = (p : @p5.P5, n : Int32) => {
    for _ in 0..<n {
      let pos = p.create_vector(p.random_max(p.width), p.random_max(p.height))
      particles.push({ pos, prev: pos.copy(), vel: p.create_vector(0, 0), })
    }
  }
  @p5.run(
    setup=p => {
      p.create_canvas(640, 400)
      @p5.set_title("p5.mbt — flow field")
      p.background(15)
      spawn(p, 800)
      p.create_span(html="noise scale ") |> ignore
      scale.val = Some(p.create_slider(0.001, 0.02, value=0.006, step=0))
      p.create_span(html=" speed ") |> ignore
      speed.val = Some(p.create_slider(0.5, 4, value=1.5, step=0))
      let pause = p.create_button("pause")
      pause.mouse_pressed(() => {
        if p.is_looping() {
          p.no_loop()
          pause.html("play")
        } else {
          p.loop_()
          pause.html("pause")
        }
      })
      let clear = p.create_button("clear")
      clear.mouse_pressed(() => p.background(15))
    },
    draw=p => {
      // Fade the trails slowly.
      p.no_stroke()
      p.fill((15, 15, 15, 12))
      p.rect(0, 0, p.width, p.height)
      let ns = scale.val.map(e => e.value_number()).unwrap_or(0.006)
      let sp = speed.val.map(e => e.value_number()).unwrap_or(1.5)
      let t = p.frame_count.to_double() * 0.002
      p.stroke_weight(1.2)
      p.color_mode(HSB)
      for part in particles {
        let angle = p.noise(part.pos.x * ns, y=part.pos.y * ns, z=t) *
          @p5.TWO_PI *
          2
        let force = @p5.Vector::from_angle(angle, length=0.3)
        part.vel.add(force)
        part.vel.limit(sp)
        part.prev.set_vec(part.pos)
        part.pos.add(part.vel)
        let hue = @p5.map(angle, 0, @p5.TWO_PI * 2, 160, 320)
        p.stroke((hue, 70, 100, 0.6))
        p.line(part.prev.x, part.prev.y, part.pos.x, part.pos.y)
        if part.pos.x < 0 ||
          part.pos.x > p.width ||
          part.pos.y < 0 ||
          part.pos.y > p.height {
          part.pos.set(p.random_max(p.width), p.random_max(p.height))
          part.vel.set(0, 0)
        }
      }
    },
    mouse_dragged=p => {
      for _ in 0..<5 {
        let pos = p.create_vector(
          p.mouse_x + p.random_gaussian(sd=8),
          p.mouse_y + p.random_gaussian(sd=8),
        )
        particles.push({ pos, prev: pos.copy(), vel: p.create_vector(0, 0), })
      }
    },
  )
}
