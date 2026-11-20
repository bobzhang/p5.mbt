///|
fn boole(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let ops = ["A AND B", "A OR B", "A XOR B", "NOT A"]
  let k = ((s - 0.6) / 1.55).floor().to_int().max(0).min(3)
  let since = s - 0.6 - k.to_double() * 1.55
  let (ax, bx, cy, r) = (700.0, 940.0, 520.0, 360.0)
  let shade = rgba(amber, 210 * smooth(since / 0.4))
  let in_a = () => p.circle(ax, cy, r)
  let in_b = () => p.circle(bx, cy, r)
  p.no_stroke()
  p.fill(shade)
  match k {
    0 =>
      p.with_push(() => {
        p.clip(in_a)
        in_b()
      })
    1 => {
      in_a()
      in_b()
    }
    2 => {
      p.with_push(() => {
        p.clip(in_b, invert=true)
        in_a()
      })
      p.with_push(() => {
        p.clip(in_a, invert=true)
        in_b()
      })
    }
    _ =>
      p.with_push(() => {
        p.clip(in_a, invert=true)
        p.rect(420, 290, 800, 460, tl=24)
      })
  }
  p.no_fill()
  p.stroke(cream)
  p.stroke_weight(3)
  p.rect(420, 290, 800, 460, tl=24)
  in_a()
  in_b()
  p.no_stroke()
  p.fill(cream)
  p.text_font(serif)
  p.text_size(48)
  p.text_align(HCenter, vertical=VCenter)
  p.text("A", ax - 90, cy)
  p.text("B", bx + 90, cy)
  // the truth table of the current operation
  let f = (a : Bool, b : Bool) => {
    match k {
      0 => a && b
      1 => a || b
      2 => a != b
      _ => !a
    }
  }
  let tx = 1360.0
  p.text_font(mono)
  p.text_size(34)
  p.fill(amber)
  p.text_align(Left, vertical=Baseline)
  p.text(ops[k], tx, 340)
  p.text_size(30)
  p.fill(dim)
  p.text("A  B  out", tx, 410)
  for i, (a, b) in [(false, false), (false, true), (true, false), (true, true)] {
    let out = f(a, b)
    let y = 470.0 + i.to_double() * 62
    if out {
      p.fill(rgba(amber, 60))
      p.rect(tx - 14, y - 40, 300, 54, tl=8)
    }
    let bit = (v : Bool) => if v { "1" } else { "0" }
    p.fill(if out { cream } else { dim })
    p.text("\{bit(a)}  \{bit(b)}   \{bit(out)}", tx, y)
  }
}

///|
/// Tape, head position and state of the binary-increment Turing machine
/// after `steps` steps, and the rule used by the last step.
fn run_turing(steps : Int32) -> (Map[Int32, Char], Int32, String, Int32) {
  let tape : Map[Int32, Char] = Map([])
  for i, c in "1011".to_array() {
    tape[i] = c
  }
  let mut head = 3
  let mut state = "inc"
  let mut rule = -1
  for _ in 0..<steps {
    let sym = tape.get(head).unwrap_or('_')
    match (state, sym) {
      ("inc", '1') => {
        tape[head] = '0'
        head -= 1
        rule = 0
      }
      ("inc", _) => {
        tape[head] = '1'
        head += 1
        state = "right"
        rule = 1
      }
      ("right", '0' | '1') => {
        head += 1
        rule = 2
      }
      _ => {
        head -= 1
        state = "inc"
        rule = 3
      }
    }
  }
  (tape, head, state, rule)
}

///|
fn tape_value(tape : Map[Int32, Char]) -> (String, Int32) {
  let mut lo = 0
  let mut hi = -1
  for i, c in tape {
    if c != '_' {
      lo = lo.min(i)
      hi = hi.max(i)
    }
  }
  let sb = StringBuilder()
  let mut v = 0
  for i in lo..<=hi {
    let c = tape.get(i).unwrap_or('0')
    sb.write_char(c)
    v = v * 2 + (if c == '1' { 1 } else { 0 })
  }
  (sb.to_string(), v)
}

///|
fn turing(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let rate = 7.0
  let t = ((s - 0.8) * rate).max(0)
  let steps = t.floor().to_int()
  let frac = smooth((t - t.floor()) * 1.6)
  let (tape, head, state, rule) = run_turing(steps)
  let (_, next_head, _, next_rule) = run_turing(steps + 1)
  let cell = 74.0
  let cx = w / 2 - 1.5 * cell
  let ty = 420.0
  let head_x = cx +
    @p5.lerp(head.to_double(), next_head.to_double(), frac) * cell
  // tape
  p.text_font(mono)
  p.text_size(40)
  p.text_align(HCenter, vertical=VCenter)
  for i in -10..<=12 {
    let x = cx + i.to_double() * cell
    let c = tape.get(i).unwrap_or('_')
    p.stroke(rgba(cream, 110))
    p.stroke_weight(2)
    p.fill(if i == head { (40, 46, 84) } else { (22, 26, 48) })
    p.rect(x - cell / 2, ty, cell, cell)
    p.no_stroke()
    p.fill(if c == '_' { rgba(dim, 120) } else { rgba(cream, 255) })
    p.text(if c == '_' { "·" } else { c.to_string() }, x, ty + cell / 2)
  }
  // head
  p.fill(amber)
  p.no_stroke()
  p.triangle(head_x - 22, ty - 70, head_x + 22, ty - 70, head_x, ty - 22)
  p.rect(head_x - 70, ty - 128, 140, 54, tl=12)
  p.fill(bg)
  p.text_size(28)
  p.text(state, head_x, ty - 101)
  // rule table
  let rules = [
    "inc,   1 → write 0, move L, inc", "inc,   0 → write 1, move R, right", "right, 0/1 → move R, right",
    "right, · → move L, inc",
  ]
  let used = if frac < 0.5 { rule } else { next_rule }
  p.text_align(Left, vertical=Baseline)
  p.text_size(26)
  for i, r in rules {
    let y = 620.0 + i.to_double() * 44
    if i == used {
      p.fill(rgba(amber, 50))
      p.rect(240, y - 32, 610, 42, tl=6)
      p.fill(cream)
    } else {
      p.fill(dim)
    }
    p.text(r, 256, y)
  }
  let (bits, value) = tape_value(tape)
  p.text_align(Right)
  p.text_size(40)
  p.fill(cream)
  p.text("\{bits}₂ = \{value}", w - 240, 680)
  p.text_size(22)
  p.fill(dim)
  p.text("a machine that counts in binary", w - 240, 730)
}

///|
fn eniac(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let panels = 5
  let (cols, rows) = (9, 12)
  let pw = 300.0
  let gap = 36.0
  let x0 = (w - (panels.to_double() * pw + (panels - 1).to_double() * gap)) / 2
  let y0 = 280.0
  for k in 0..<panels {
    let px = x0 + k.to_double() * (pw + gap)
    p.no_stroke()
    p.fill((32, 34, 44))
    p.rect(px, y0, pw, 520, tl=6)
    p.blend_mode(Add)
    for i in 0..<cols {
      for j in 0..<rows {
        let x = px + 24 + i.to_double() * 31.5
        let y = y0 + 26 + j.to_double() * 41
        let v = n3(
          k.to_double() * 10 + i.to_double() * 0.45,
          j.to_double() * 0.45,
          s * 1.8,
        )
        let on = smooth((v - 0.45) * 8)
        p.fill(rgba((255, 120, 40), 40 + 140 * on))
        p.circle(x, y, 26)
        p.fill(rgba((255, 200, 120), 60 + 195 * on))
        p.rect(x - 5, y - 12, 10, 24, tl=5)
      }
    }
    p.blend_mode(Blend)
  }
  // patch cables between panels
  p.no_fill()
  p.stroke_weight(5)
  for c in 0..<9 {
    let k1 = c % (panels - 1)
    let a = x0 + k1.to_double() * (pw + gap) + pw - 30
    let b = a + gap + 60 + (c % 3).to_double() * 70
    let y1 = y0 + 60 + (c * 53 % 400).to_double()
    let y2 = y0 + 80 + (c * 97 % 380).to_double()
    let sag = 120.0 + 25 * p.sin(s * 1.3 + c.to_double())
    p.stroke(if c % 2 == 0 { (200, 60, 50) } else { (230, 220, 200) })
    p.bezier(a, y1, a + 20, y1 + sag, b - 20, y2 + sag, b, y2)
  }
}

///|
fn transistor(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let period = 1.4
  let on_at = (time : Double) => @p5.js_rem(time, period) < period / 2
  let on = on_at(s)
  let (cx, cy) = (960.0, 520.0)
  // oscilloscope traces: base input and collector current
  let trace = (x : Double, label : String, invert : Bool) => {
    p.no_fill()
    p.stroke(rgba(dim, 140))
    p.stroke_weight(2)
    p.rect(x, 400, 380, 240, tl=10)
    p.stroke(if invert { cyan } else { amber })
    p.stroke_weight(4)
    p.begin_shape()
    for i in 0..<=190 {
      let tt = s - (190 - i).to_double() * 0.012
      let high = on_at(tt)
      p.vertex(x + 10 + i.to_double() * 1.89, if high { 460.0 } else { 580.0 })
    }
    p.end_shape()
    p.no_stroke()
    p.fill(dim)
    p.text_font(mono)
    p.text_size(20)
    p.text_align(HCenter, vertical=Top)
    p.text(label, x + 190, 652)
  }
  trace(170, "base signal", false)
  trace(1370, "collector current", true)
  // the symbol
  p.no_fill()
  p.stroke(cream)
  p.stroke_weight(5)
  p.circle(cx, cy, 240)
  p.line(cx - 40, cy - 70, cx - 40, cy + 70)
  p.line(cx - 220, cy, cx - 40, cy)
  p.line(cx - 40, cy - 30, cx + 50, cy - 95)
  p.line(cx + 50, cy - 95, cx + 50, cy - 230)
  p.line(cx - 40, cy + 30, cx + 50, cy + 95)
  p.line(cx + 50, cy + 95, cx + 50, cy + 230)
  p.no_stroke()
  p.fill(cream)
  p.triangle(cx + 50, cy + 95, cx + 18, cy + 92, cx + 36, cy + 66)
  p.fill(if on { amber } else { dim })
  p.circle(cx - 220, cy, 18)
  p.fill(dim)
  p.text_font(mono)
  p.text_size(20)
  p.text_align(Left, vertical=VCenter)
  p.text("collector", cx + 70, cy - 200)
  p.text("emitter", cx + 70, cy + 200)
  p.text_align(HCenter, vertical=Top)
  p.text("base", cx - 220, cy + 22)
  // electrons flow only while the switch is on
  if on {
    let path = [
      @p5.Vector(cx + 50, cy - 230),
      @p5.Vector(cx + 50, cy - 95),
      @p5.Vector(cx - 40, cy - 30),
      @p5.Vector(cx - 40, cy + 30),
      @p5.Vector(cx + 50, cy + 95),
      @p5.Vector(cx + 50, cy + 230),
    ]
    let seg_len = [ for i in 0..<5 => path[i].dist(path[i + 1]) ]
    let total = seg_len.fold(init=0.0, (a, b) => a + b)
    for k in 0..<14 {
      let mut dd = @p5.js_rem(s * 260 + k.to_double() * total / 14, total)
      let mut i = 0
      while i < 4 && dd > seg_len[i] {
        dd -= seg_len[i]
        i += 1
      }
      let a = path[i]
      let b = path[i + 1]
      let f = dd / seg_len[i]
      p.fill(cyan)
      p.circle(@p5.lerp(a.x, b.x, f), @p5.lerp(a.y, b.y, f), 12)
    }
  }
}
