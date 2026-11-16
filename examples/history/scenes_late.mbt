///|
fn moore(p : @p5.P5, s : Double, d : Double) -> Unit {
  // a die subdividing into ever smaller transistors
  let (cx, cy, size) = (520.0, 540.0, 400.0)
  let level = (clamp01((s - 0.5) / (d - 2.5)) * 6.99).floor().to_int()
  p.no_stroke()
  p.fill((40, 42, 52))
  p.rect(cx - size / 2 - 30, cy - size / 2 - 30, size + 60, size + 60, tl=10)
  p.stroke(rgba(dim, 200))
  p.stroke_weight(6)
  for i in 0..<10 {
    let o = -size / 2 + 20 + i.to_double() * (size - 40) / 9
    p.line(cx + o, cy - size / 2 - 30, cx + o, cy - size / 2 - 50)
    p.line(cx + o, cy + size / 2 + 30, cx + o, cy + size / 2 + 50)
    p.line(cx - size / 2 - 30, cy + o, cx - size / 2 - 50, cy + o)
    p.line(cx + size / 2 + 30, cy + o, cx + size / 2 + 50, cy + o)
  }
  p.no_stroke()
  p.fill((70, 90, 140))
  p.rect(cx - size / 2, cy - size / 2, size, size)
  let n = 1 << (level + 1)
  let cell = size / n.to_double()
  p.stroke(rgba(cyan, 200 - level.to_double() * 18))
  p.stroke_weight(if level < 4 { 2 } else { 1 })
  for i in 0..<=n {
    let o = -size / 2 + i.to_double() * cell
    p.line(cx + o, cy - size / 2, cx + o, cy + size / 2)
    p.line(cx - size / 2, cy + o, cx + size / 2, cy + o)
  }
  // transistor counts on a log scale
  let data = [
    (1971.0, 2300.0, "Intel 4004"),
    (1978.0, 29000.0, "Intel 8086"),
    (1989.0, 1.2e6, "Intel 486"),
    (2000.0, 4.2e7, "Pentium 4"),
    (2020.0, 1.6e10, "Apple M1"),
  ]
  let (gx0, gx1, gy0, gy1) = (930.0, 1760.0, 780.0, 300.0)
  let px = (year : Double) => @p5.map(year, 1968, 2024, gx0, gx1)
  let py = (count : Double) => @p5.map(@cmath.log10(count), 3, 11, gy0, gy1)
  p.stroke(rgba(dim, 150))
  p.stroke_weight(2)
  p.line(gx0, gy0, gx1, gy0)
  p.line(gx0, gy0, gx0, gy1)
  p.no_stroke()
  p.fill(dim)
  p.text_font(mono)
  p.text_size(18)
  p.text_align(Right, vertical=VCenter)
  for e in [3, 5, 7, 9, 11] {
    let v = @cmath.pow(10, e.to_double())
    p.text(@p5.nfc(v), gx0 - 12, py(v))
  }
  p.text_align(HCenter, vertical=Top)
  for y in [1970, 1980, 1990, 2000, 2010, 2020] {
    p.text(y.to_string(), px(y.to_double()), gy0 + 12)
  }
  // the doubling trend, drawn progressively
  let progress = clamp01((s - 0.8) / (d - 2.0))
  let end_year = 1971.0 + progress * 49
  p.no_fill()
  p.stroke(rgba(amber, 140))
  p.stroke_weight(3)
  p.begin_shape()
  let mut yr = 1971.0
  while yr <= end_year {
    p.vertex(px(yr), py(2300.0 * @cmath.pow(2, (yr - 1971) / 2)))
    yr += 0.5
  }
  p.end_shape()
  for (year, count, name) in data {
    if year <= end_year {
      p.no_stroke()
      p.fill(cream)
      p.circle(px(year), py(count), 16)
      p.text_align(Left, vertical=VCenter)
      p.text_size(19)
      p.text("\{name}  \{@p5.nfc(count)}", px(year) + 16, py(count) + 26)
    }
  }
  p.text_align(Left, vertical=Top)
  p.fill(dim)
  p.text("transistors per chip", gx0 + 10, gy1 - 30)
}

///|
fn arpanet(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let nodes = [
    ("SRI", @p5.Vector(640, 360)),
    ("UCSB", @p5.Vector(430, 560)),
    ("UCLA", @p5.Vector(640, 720)),
    ("UTAH", @p5.Vector(1060, 420)),
  ]
  let links = [(0, 2), (1, 2), (0, 1), (0, 3)]
  p.stroke(rgba(dim, 160))
  p.stroke_weight(4)
  for (a, b) in links {
    let pa = nodes[a].1
    let pb = nodes[b].1
    p.line(pa.x, pa.y, pb.x, pb.y)
  }
  let ucla = nodes[2].1
  let sri = nodes[0].1
  // packets: "L", "O", then "G" never arrives
  let sends = [('L', 1.0), ('O', 2.4), ('G', 3.8)]
  let mut received = ""
  let mut crashed = false
  p.text_font(mono)
  for (ch, at) in sends {
    let f = (s - at) / 0.9
    if f >= 1 && ch != 'G' {
      received = received + ch.to_string()
    }
    let f = if ch == 'G' { f.min(0.55) } else { f }
    if f > 0 && f < 1 {
      let pos = ucla.copy()
      pos.lerp(sri, f)
      let lost = ch == 'G' && s > at + 0.5
      crashed = crashed || (ch == 'G' && s > at + 0.6)
      p.no_stroke()
      p.fill(if lost { (230, 70, 60) } else { amber })
      p.rect(pos.x - 24, pos.y - 24, 48, 48, tl=8)
      p.fill(bg)
      p.text_size(30)
      p.text_align(HCenter, vertical=VCenter)
      p.text(ch.to_string(), pos.x, pos.y)
    }
  }
  for i, (name, pos) in nodes {
    let pulse = if i == 0 && received.length() > 0 { 1.0 } else { 0.0 }
    p.no_stroke()
    p.fill(
      if crashed && i == 0 {
        (230, 70, 60)
      } else if pulse > 0 {
        amber
      } else {
        cyan
      },
    )
    p.circle(pos.x, pos.y, 38)
    p.fill(cream)
    p.text_font(sans)
    p.text_size(28)
    p.text_align(Left, vertical=VCenter)
    p.text(name, pos.x + 32, pos.y)
  }
  // SRI's terminal
  let (tx, ty) = (1260.0, 520.0)
  p.fill((18, 22, 20))
  p.stroke(rgba(dim, 160))
  p.stroke_weight(2)
  p.rect(tx, ty, 520, 220, tl=10)
  p.no_stroke()
  p.text_font(mono)
  p.text_size(30)
  p.text_align(Left, vertical=Top)
  p.fill((120, 230, 140))
  p.text("SRI SDS-940", tx + 28, ty + 24)
  p.text(
    "> " + received + (if (s * 2).floor().to_int() % 2 == 0 { "_" } else { "" }),
    tx + 28,
    ty + 80,
  )
  if crashed {
    p.fill((230, 70, 60))
    p.text("*** SYSTEM CRASH ***", tx + 28, ty + 140)
  }
}

///|
priv struct WebNode {
  pos : @p5.Vector
  vel : @p5.Vector
  parent : Int32
}

///|
priv struct WebSim {
  nodes : Array[WebNode]
  mut frame : Int32
  rng : @p5.Random
}

///|
fn WebSim::new() -> WebSim {
  {
    nodes: [{ pos: @p5.Vector(0, 0), vel: @p5.Vector(0, 0), parent: -1, }],
    frame: 0,
    rng: @p5.Random::new(1989),
  }
}

///|
fn WebSim::step(self : WebSim) -> Unit {
  self.frame += 1
  let t = self.frame.to_double() / FPS
  let target = @cmath.pow(2, (t - 0.6) * 1.15).floor().to_int().min(170).max(1)
  while self.nodes.length() < target {
    // link to the parent of a random node or the node itself: rich get richer
    let pick = (self.rng.next() * self.nodes.length().to_double())
      .floor()
      .to_int()
    let parent = if self.rng.next() < 0.5 && self.nodes[pick].parent >= 0 {
      self.nodes[pick].parent
    } else {
      pick
    }
    let dir = Vector::from_angle(self.rng.next() * @p5.TWO_PI, length=30)
    self.nodes.push({
      pos: self.nodes[parent].pos + dir,
      vel: @p5.Vector(0, 0),
      parent,
    })
  }
  let n = self.nodes.length()
  for i in 0..<n {
    let a = self.nodes[i]
    for j in (i + 1)..<n {
      let b = self.nodes[j]
      let delta = a.pos - b.pos
      let d2 = delta.mag_sq().max(25)
      let f = delta.scaled(1600.0 / d2 / d2.sqrt())
      a.vel.add(f)
      b.vel.sub(f)
    }
    if a.parent >= 0 {
      let b = self.nodes[a.parent]
      let delta = b.pos - a.pos
      let stretch = delta.mag() - 60
      let f = delta.normalized().scaled(stretch * 0.04)
      a.vel.add(f)
      b.vel.sub(f)
    }
    a.vel.sub(a.pos.scaled(0.004))
  }
  for node in self.nodes {
    node.vel.mult(0.82)
    node.vel.limit(12)
    node.pos.add(node.vel)
  }
  self.nodes[0].pos.set(0, 0)
}

///|
using @p5 {type Vector}

///|
let web_sim : Ref[WebSim] = Ref(WebSim::new())

///|
fn web(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let frame = (s * FPS).round().to_int()
  if frame < web_sim.val.frame {
    web_sim.val = WebSim::new()
  }
  while web_sim.val.frame < frame {
    web_sim.val.step()
  }
  let sim = web_sim.val
  p.push()
  p.translate(w / 2, 540)
  p.stroke(rgba(cream, 70))
  p.stroke_weight(1.5)
  for node in sim.nodes {
    if node.parent >= 0 {
      let q = sim.nodes[node.parent].pos
      p.line(node.pos.x, node.pos.y, q.x, q.y)
    }
  }
  p.no_stroke()
  for i, node in sim.nodes {
    if i == 0 {
      continue
    }
    p.fill(rgba(cyan, 220))
    p.circle(node.pos.x, node.pos.y, 9)
  }
  p.fill(amber)
  p.circle(0, 0, 26)
  p.fill(cream)
  p.text_font(mono)
  p.text_size(24)
  p.text_align(Left, vertical=VCenter)
  p.text("info.cern.ch", 22, -22)
  p.pop()
  p.fill(dim)
  p.text_font(mono)
  p.text_size(20)
  p.text_align(Right, vertical=Top)
  p.text("\{sim.nodes.length()} pages", w - 110, 780)
}

///|
priv struct Mover {
  trail : Array[Vector]
  hue : Double
}

///|
priv struct FlowSim {
  movers : Array[Mover]
  mut frame : Int32
  rng : @p5.Random
}

///|
fn FlowSim::new() -> FlowSim {
  let rng = @p5.Random::new(2001)
  let movers = [
    for _ in 0..<700 => {
      {
        trail: [Vector(rng.range(0, w), rng.range(260, 820))],
        hue: rng.range(170, 330),
      }
    }
  ]
  { movers, frame: 0, rng, }
}

///|
fn FlowSim::step(self : FlowSim) -> Unit {
  self.frame += 1
  let t = self.frame.to_double() / FPS
  for m in self.movers {
    let head = m.trail[m.trail.length() - 1]
    let angle = n3(head.x * 0.0016, head.y * 0.0016, t * 0.15) *
      @p5.TWO_PI *
      1.6
    let next = head + Vector::from_angle(angle, length=3.2)
    if next.x < 0 || next.x > w || next.y < 260 || next.y > 820 {
      m.trail.clear()
      m.trail.push(Vector(self.rng.range(0, w), self.rng.range(260, 820)))
    } else {
      m.trail.push(next)
      if m.trail.length() > 22 {
        m.trail.remove(0) |> ignore
      }
    }
  }
}

///|
let flow_sim : Ref[FlowSim] = Ref(FlowSim::new())

///|
fn sketchbook(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let frame = (s * FPS).round().to_int()
  if frame < flow_sim.val.frame {
    flow_sim.val = FlowSim::new()
  }
  while flow_sim.val.frame < frame {
    flow_sim.val.step()
  }
  p.color_mode(HSB)
  p.no_fill()
  p.stroke_weight(2)
  for m in flow_sim.val.movers {
    if m.trail.length() < 2 {
      continue
    }
    p.stroke((m.hue, 70, 100, 0.75))
    p.begin_shape()
    for v in m.trail {
      p.vertex(v.x, v.y)
    }
    p.end_shape()
  }
  p.color_mode(RGB)
  p.no_stroke()
  p.fill(rgba(bg, 200))
  p.rect(1240, 600, 560, 190, tl=12)
  p.fill(cream)
  p.text_font(mono)
  p.text_size(24)
  p.text_align(Left, vertical=Top)
  p.text(
    "// p5.mbt\nlet a = p.noise(x, y=y) * TWO_PI * 1.6\np.vertex(x + cos(a) * 3.2, …)",
    1270, 625,
  )
}

///|
fn outro(p : @p5.P5, s : Double, _d : Double) -> Unit {
  p.no_stroke()
  p.text_align(HCenter, vertical=Baseline)
  p.text_font(serif)
  p.text_size(64)
  p.fill(rgba(cream, 255 * smooth((s - 0.3) / 1.0)))
  p.text("This film was drawn frame by frame", w / 2, 250)
  p.fill(rgba(amber, 255 * smooth((s - 1.0) / 1.0)))
  p.text("with p5.mbt: p5.js, ported to MoonBit", w / 2, 340)
  // the program behind it
  let frames = (total_seconds(scenes()) * FPS).to_int()
  let code = "fn main {\n  @p5.run(\n    setup=p => {\n      p.create_canvas(1920, 1080)\n      p.record(frames=\{frames}) // \{frames / 60} s at 60 fps\n    },\n    draw=p => film(p, scenes(), (p.frame_count - 1).to_double() / 60),\n  )\n}"
  let a = smooth((s - 1.8) / 0.8)
  p.fill(rgba((24, 28, 52), 255 * a))
  p.rect(w / 2 - 640, 420, 1280, 380, tl=16)
  p.text_font(mono)
  p.text_size(28)
  p.text_leading(38)
  p.text_align(Left, vertical=Top)
  p.fill(rgba(cream, 255 * a))
  p.text(typed(code, (s - 2.0) / 3.0), w / 2 - 590, 455)
  p.text_font(sans)
  p.text_size(30)
  p.text_align(HCenter, vertical=Baseline)
  p.fill(rgba(dim, 255 * smooth((s - 5.0) / 1.0)))
  p.text(
    "shapes · color · type · images · noise · vectors · events",
    w / 2,
    880,
  )
}
