// The camera: where it looks at each moment, and the ten ways it moves
// from one language to the next.

///|
fn node_view(i : Int32) -> View {
  let (x, y) = positions[i]
  if i == @story.moon_node {
    // MoonBit's editor on the left, the agent's orbit on the right
    { x: x + 420, y: y - 20, zoom: 0.84, rot: 0, }
  } else {
    { x, y: y - 10, zoom: 0.85, rot: 0, }
  }
}

///|
let overview_view : View = { x: 5900, y: 500, zoom: 0.135, rot: 0, }

///|
/// The camera resting on node `i`, creeping slowly forward.
fn hold_view(i : Int32, t : Double) -> View {
  let v = node_view(i)
  let creep = 1.0 + 0.01 * (t - arrival(i)).max(0)
  { ..v, zoom: v.zoom * creep, }
}

///|
/// Moves from `a` to `b`: position by `e`, zoom geometrically.
fn mix_view(a : View, b : View, e : Double) -> View {
  {
    x: lerp(a.x, b.x, e),
    y: lerp(a.y, b.y, e),
    zoom: @cmath.exp(lerp(@cmath.ln(a.zoom), @cmath.ln(b.zoom), e)),
    rot: lerp(a.rot, b.rot, e),
  }
}

///|
/// Flies from `a` to `b`, rising to `dip` (fraction of zoom lost) half way.
fn fly(a : View, b : View, e : Double, dip : Double, rot : Double) -> View {
  let m = mix_view(a, b, ease_in_out(e))
  // high enough at the top of the arc to see where we left and where we land
  let dx = (b.x - a.x).abs().max(1)
  let dy = (b.y - a.y).abs().max(1)
  let fit = (1500.0 / dx).min(700.0 / dy)
  let top = (m.zoom * (1 - dip)).min(fit)
  let arc = @cmath.sin(3.14159265 * e)
  let zoom = @cmath.exp(lerp(@cmath.ln(m.zoom), @cmath.ln(top), arc))
  { ..m, zoom, rot, }
}

///|
fn camera_and_world(p : @p5.P5, t : Double) -> Unit {
  if t >= @story.overview_start {
    draw_view(p, late_view(t), t, 1)
    return
  }
  let mut k = 0
  for i, s in all_shots {
    if s.start <= t {
      k = i
    }
  }
  let shot = all_shots[k]
  if t < shot.arrive() {
    let e = clamp01((t - shot.start) / shot.trans)
    let b = node_view(shot.node)
    let a = if k == 0 {
      let (nx, ny) = positions[0]
      { x: nx, y: ny - 40, zoom: 2.6, rot: 0, }
    } else {
      hold_view(k - 1, shot.start)
    }
    transition(p, shot.style, a, b, e, t)
  } else {
    draw_view(p, hold_view(k, t), t, 1)
  }
}

///|
/// From the end of the montage: pull back, hover over the map, dive into
/// MoonBit and stay there.
fn late_view(t : Double) -> View {
  let leave = hold_view(all_shots.length() - 1, @story.overview_start)
  let drifted = {
    ..overview_view,
    zoom: overview_view.zoom *
    (1 + 0.05 * (t.min(@story.moon_born) - @story.overview_end).max(0) / 6),
  }
  if t < @story.overview_end {
    let e = ease_in_out(
      (t - @story.overview_start) /
      (@story.overview_end - @story.overview_start),
    )
    mix_view(leave, overview_view, e)
  } else if t < @story.moon_born {
    drifted
  } else if t < @story.moon_arrive {
    let e = ease_in_out(
      (t - @story.moon_born) / (@story.moon_arrive - @story.moon_born),
    )
    mix_view(drifted, node_view(@story.moon_node), e)
  } else {
    hold_view(@story.moon_node, t)
  }
}

///|
fn transition(
  p : @p5.P5,
  style : @story.Style,
  a : View,
  b : View,
  e : Double,
  t : Double,
) -> Unit {
  match style {
    Ink => {
      // the next scene seeps through in spreading blots, like ink in water
      draw_view(p, { ..a, zoom: a.zoom * (1 + 0.06 * e), }, t, 1)
      let blots = (r : Double) => {
        for k in 0..<28 {
          let sx = hash01(k * 7 + 1) * w
          let sy = bar + hash01(k * 7 + 2) * (h - 2 * bar)
          let grow = ease_in_out((e - hash01(k * 7 + 3) * 0.45) / 0.55)
          let rr = grow * (260 + 520 * hash01(k * 7 + 4)) + r
          if rr > 0 {
            p.circle(sx, sy, rr * 2)
          }
        }
        let core = ease_in_out((e - 0.25) / 0.75) * 1300
        if core > 0 {
          p.circle(w / 2, h / 2, core * 2)
        }
      }
      // a soft dark rim runs ahead of the bloom
      p.no_stroke()
      p.fill((4, 5, 14, 120))
      blots(24)
      p.push()
      p.clip(() => blots(0))
      draw_view(p, { ..b, zoom: b.zoom * (1.06 - 0.06 * e), }, t, 1)
      p.pop()
    }
    Leak => {
      // a warm light washes over everything; the cut hides inside it
      let drift = 260.0
      let v = if e < 0.5 {
        { ..a, x: a.x + drift * ease_in_out(e * 2), }
      } else {
        { ..b, x: b.x - drift * (1 - ease_in_out((e - 0.5) * 2)), }
      }
      draw_view(p, v, t, 1)
      let bump = @cmath.pow(@cmath.sin(3.14159265 * e), 1.5)
      p.push()
      p.blend_mode(Add)
      p.no_stroke()
      let lx = lerp(-300, w + 300, e)
      for i in 0..<12 {
        p.fill(rgba((255, 140, 60), 26 * bump))
        p.ellipse(
          lx,
          h * 0.45,
          300 + i.to_double() * 130,
          h=500 + i.to_double() * 70,
        )
      }
      p.pop()
      full_rect(p, rgba((255, 214, 170), 228 * @cmath.pow(bump, 3)))
    }
    Ignite => {
      let v = mix_view(a, b, 1 - @cmath.pow(1 - e, 3))
      draw_view(p, v, t, 1)
      // a single spark in the dark
      let s = clamp01(t / 0.9)
      p.no_stroke()
      for r in 0..<10 {
        p.fill(rgba(amber, 40 * (1 - s)))
        p.circle(w / 2, h / 2, 10 + r.to_double() * 26 * (0.3 + s))
      }
    }
    Swoop => draw_view(p, fly(a, b, e, 0.72, 0), t, 1)
    Spin => draw_view(p, fly(a, b, e, 0.7, 6.2831853 * ease_in_out(e)), t, 1)
    Swing =>
      draw_view(p, fly(a, b, e, 0.55, -0.45 * @cmath.sin(3.14159265 * e)), t, 1)
    Whip => {
      let v = fly(a, b, e, 0.12, 0)
      draw_view(p, v, t, 1)
      speed_lines(p, b.x - a.x, b.y - a.y, @cmath.sin(3.14159265 * e))
    }
    Flip => {
      let sx = @cmath.cos(3.14159265 * e)
      if e < 0.5 {
        draw_view(p, a, t, sx.max(0.002))
      } else {
        draw_view(p, b, t, (-sx).max(0.002))
      }
      full_rect(p, rgba((0, 0, 0), 200 * (1 - sx.abs())))
    }
    Dive => {
      let depth = 28.0
      if e < 0.5 {
        let f = @cmath.pow(e * 2, 3)
        let (nx, ny) = positions[all_shots[node_before(t)].node]
        let target = { x: nx, y: ny + 40, zoom: a.zoom * depth, rot: 0, }
        draw_view(p, mix_view(a, target, f), t, 1)
      } else {
        let f = 1.0 - @cmath.pow(1 - (e - 0.5) * 2, 3)
        let (nx, ny) = positions[nearest_node(b)]
        let start = { x: nx, y: ny + 40, zoom: b.zoom * depth, rot: 0, }
        draw_view(p, mix_view(start, b, f), t, 1)
      }
      full_rect(
        p,
        rgba((255, 255, 255), 255 * clamp01(1 - (e - 0.5).abs() * 6)),
      )
    }
    Glitch => {
      let (base, other) = if e < 0.5 { (a, b) } else { (b, a) }
      draw_view(p, base, t, 1)
      let amount = 1.0 - (e - 0.5).abs() * 2
      let tick = (t * 30).floor().to_int()
      let strips = 18
      for k in 0..<strips {
        if hash01(k * 31 + tick * 7) < amount * 0.9 {
          let y = k.to_double() * h / strips.to_double()
          let hh = h / strips.to_double() * (0.4 + hash01(k + tick) * 1.2)
          let dx = (hash01(k * 3 + tick) - 0.5) * 160 * amount
          p.push()
          p.clip(() => p.rect(0, y, w, hh))
          p.translate(dx, 0)
          draw_view(p, other, t, 1)
          p.pop()
        }
      }
      // colour fringes and noise bars
      p.push()
      p.blend_mode(Add)
      p.no_stroke()
      for k in 0..<10 {
        let r = hash01(k * 17 + tick)
        if r < amount {
          let c = if k % 2 == 0 { (255, 0, 120) } else { (0, 200, 255) }
          p.fill(rgba(c, 70 * amount))
          p.rect(0, hash01(k + tick * 3) * h, w, 3 + 18 * hash01(k * 5 + tick))
        }
      }
      p.pop()
    }
    Iris => {
      let grow = { ..a, zoom: a.zoom * (1 + 0.25 * e), }
      draw_view(p, grow, t, 1)
      let r = 1150.0 * ease_in_out(e)
      let inner = { ..b, zoom: b.zoom * (1.2 - 0.2 * e), }
      p.push()
      p.clip(() => p.circle(w / 2, h / 2, r * 2))
      draw_view(p, inner, t, 1)
      p.pop()
      p.no_fill()
      p.stroke(rgba(cream, 220 * (1 - e)))
      p.stroke_weight(6)
      p.circle(w / 2, h / 2, r * 2)
    }
    Dissolve => {
      draw_view(p, a, t, 1)
      let cols = 16
      let rows = 9
      let size = w / cols.to_double()
      p.push()
      p.clip(() => {
        for k in 0..<(cols * rows) {
          let cx = k % cols
          let cy = k / cols
          // tiles flip on in a sweep from the left, with a little noise
          let at = cx.to_double() / cols.to_double() * 0.6 + hash01(k) * 0.4
          if at < e {
            p.rect(
              cx.to_double() * size,
              cy.to_double() * size,
              size + 1,
              size + 1,
            )
          }
        }
      })
      draw_view(p, b, t, 1)
      p.pop()
      // the edges of fresh tiles glow
      p.no_fill()
      p.stroke_weight(2)
      for k in 0..<(cols * rows) {
        let cx = k % cols
        let cy = k / cols
        let at = cx.to_double() / cols.to_double() * 0.6 + hash01(k) * 0.4
        let age = e - at
        if age > 0 && age < 0.15 {
          p.stroke(rgba((150, 210, 255), 255 * (1 - age / 0.15)))
          p.rect(cx.to_double() * size, cy.to_double() * size, size, size)
        }
      }
    }
  }
}

///|
/// The shot whose move is under way at `t`, minus one: where a dive starts.
fn node_before(t : Double) -> Int32 {
  let mut k = 0
  for i, s in all_shots {
    if s.start <= t {
      k = i
    }
  }
  (k - 1).max(0)
}

///|
fn nearest_node(v : View) -> Int32 {
  let mut best = 0
  let mut best_d = 1.0e18
  for i, pos in positions {
    let d = (pos.0 - v.x) * (pos.0 - v.x) + (pos.1 - v.y) * (pos.1 - v.y)
    if d < best_d {
      best = i
      best_d = d
    }
  }
  best
}

///|
fn speed_lines(p : @p5.P5, dx : Double, dy : Double, strength : Double) -> Unit {
  let len = (dx * dx + dy * dy).sqrt().max(1)
  let ux = dx / len
  let uy = dy / len
  p.stroke_cap(Round)
  for k in 0..<34 {
    let off = (hash01(k) - 0.5) * 2400
    let along = (hash01(k + 50) - 0.5) * 1600
    let l = 300.0 + 900 * hash01(k + 99)
    let cx = w / 2 - uy * off + ux * along
    let cy = h / 2 + ux * off + uy * along
    p.stroke(rgba((230, 235, 255), 150 * strength * hash01(k + 7)))
    p.stroke_weight(2 + 5 * hash01(k + 3))
    p.line(cx - ux * l / 2, cy - uy * l / 2, cx + ux * l / 2, cy + uy * l / 2)
  }
}
