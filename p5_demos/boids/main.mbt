// Flocking (Craig Reynolds' boids): each bird steers to keep its distance,
// match its neighbours' heading and stay with the flock. The mouse pulls.

///|
struct Boid {
  pos : @p5.Vector
  vel : @p5.Vector
}

///|
fn limit(v : @p5.Vector, max : Double) -> Unit {
  if v.mag() > max {
    v.set_mag(max)
  }
}

///|
fn main {
  let flock : Array[Boid] = []
  @p5.run(
    setup=p => {
      p.create_canvas(900, 560)
      for _ in 0..<220 {
        let v = p.random2d()
        v.mult(p.random_range(1, 3))
        flock.push({
          pos: p.create_vector(p.random_max(p.width), p.random_max(p.height)),
          vel: v,
        })
      }
      p.background((10, 14, 30))
    },
    draw=p => {
      // translucent background for motion trails
      p.no_stroke()
      p.fill((10, 14, 30, 60))
      p.rect(0, 0, p.width, p.height)
      let mouse = p.create_vector(p.mouse_x, p.mouse_y)
      for b in flock {
        let sep = p.create_vector(0, 0)
        let ali = p.create_vector(0, 0)
        let coh = p.create_vector(0, 0)
        let mut n = 0
        for o in flock {
          let d = b.pos.dist(o.pos)
          if !physical_equal(o, b) && d < 50 {
            if d < 22 {
              let away = b.pos - o.pos
              away.div(d * d + 0.01)
              sep.add(away)
            }
            ali.add(o.vel)
            coh.add(o.pos)
            n += 1
          }
        }
        let acc = p.create_vector(0, 0)
        if n > 0 {
          ali.div(n.to_double())
          ali.set_mag(3)
          let steer_a = ali - b.vel
          limit(steer_a, 0.06)
          coh.div(n.to_double())
          let to_center = coh - b.pos
          to_center.set_mag(3)
          let steer_c = to_center - b.vel
          limit(steer_c, 0.04)
          acc.add(steer_a)
          acc.add(steer_c)
        }
        if sep.mag() > 0 {
          sep.set_mag(3)
          let steer_s = sep - b.vel
          limit(steer_s, 0.1)
          acc.add(steer_s)
        }
        if p.mouse_x > 0 && p.mouse_y > 0 {
          let pull = mouse - b.pos
          if pull.mag() < 250 {
            pull.set_mag(0.05)
            acc.add(pull)
          }
        }
        b.vel.add(acc)
        limit(b.vel, 3.2)
        b.pos.add(b.vel)
        // wrap around the edges
        let wx = if b.pos.x < 0 {
          b.pos.x + p.width
        } else if b.pos.x > p.width {
          b.pos.x - p.width
        } else {
          b.pos.x
        }
        let wy = if b.pos.y < 0 {
          b.pos.y + p.height
        } else if b.pos.y > p.height {
          b.pos.y - p.height
        } else {
          b.pos.y
        }
        b.pos.set(wx, wy)
      }
      p.color_mode(HSB)
      for b in flock {
        let heading = b.vel.heading()
        p.push()
        p.translate(b.pos.x, b.pos.y)
        p.rotate(heading)
        p.fill(((heading + @p5.PI) / @p5.TWO_PI * 360, 70, 100))
        p.triangle(8, 0, -6, 4, -6, -4)
        p.pop()
      }
      p.color_mode(RGB)
    },
  )
}
