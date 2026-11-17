// Words made of particles: each point of `text_to_points` is a spring that
// pulls its particle home; the mouse pushes particles away. Every few
// seconds the particles re-target the next word.

///|
struct Particle {
  mut x : Double
  mut y : Double
  mut vx : Double
  mut vy : Double
  mut tx : Double
  mut ty : Double
  hue : Double
}

///|
let words : Array[String] = ["p5.mbt", "MoonBit", "faithful", "fonts!"]

///|
fn main {
  let font : Ref[@p5.Font?] = Ref(None)
  let particles : Array[Particle] = []
  let word = Ref(0)
  let retarget = (p : @p5.P5) => {
    guard font.val is Some(f) else { return }
    p.text_size(150)
    p.text_align(HCenter)
    let pts = f.text_to_points(
      words[word.val],
      p.width / 2,
      270,
      sample_factor=0.18,
    )
    // grow or shrink the population, then assign targets in order
    while particles.length() < pts.length() {
      particles.push({
        x: p.random_max(p.width),
        y: p.random_max(p.height),
        vx: 0,
        vy: 0,
        tx: 0,
        ty: 0,
        hue: p.random_range(180, 340),
      })
    }
    while particles.length() > pts.length() {
      ignore(particles.pop())
    }
    for i, q in pts {
      particles[i].tx = q.x
      particles[i].ty = q.y
    }
  }
  @p5.run(
    preload=p => {
      font.val = Some(p.load_font("../assets/SourceSansPro-Regular.otf"))
    },
    setup=p => {
      p.create_canvas(720, 400)
      p.color_mode(HSB)
      retarget(p)
    },
    draw=p => {
      p.background((240, 30, 12))
      if p.frame_count % 240 == 0 {
        word.val = (word.val + 1) % words.length()
        retarget(p)
      }
      p.no_stroke()
      for pt in particles {
        // spring home, push away from the mouse, damping
        let dx = pt.tx - pt.x
        let dy = pt.ty - pt.y
        pt.vx += dx * 0.02
        pt.vy += dy * 0.02
        let mx = pt.x - p.mouse_x
        let my = pt.y - p.mouse_y
        let d2 = mx * mx + my * my
        if d2 < 6400 {
          let push = (6400.0 - d2) / 6400 * 2.5
          let d = d2.sqrt() + 0.001
          pt.vx += mx / d * push
          pt.vy += my / d * push
        }
        pt.vx *= 0.86
        pt.vy *= 0.86
        pt.x += pt.vx
        pt.y += pt.vy
        let speed = (pt.vx * pt.vx + pt.vy * pt.vy).sqrt()
        p.fill((pt.hue, 70, 100, 0.9))
        p.circle(pt.x, pt.y, 3 + speed.min(6))
      }
    },
  )
}
