///|
let noise_gen : @p5.Noise = @p5.Noise::new(1843)

///|
fn n3(x : Double, y : Double, z : Double) -> Double {
  noise_gen.noise(x, y~, z~)
}

///|
fn intro(p : @p5.P5, s : Double, _d : Double) -> Unit {
  // a slow rain of bits
  p.text_font(mono)
  p.text_size(22)
  p.text_align(HCenter, vertical=VCenter)
  p.no_stroke()
  for col in 0..<64 {
    let x = 15.0 + col.to_double() * 30
    let speed = 40.0 + n3(col.to_double() * 0.7, 0, 0) * 90
    for k in 0..<24 {
      let y = @p5.js_rem(
          k.to_double() * 52 + s * speed + col.to_double() * 37,
          h + 52,
        ) -
        26
      let bit = if n3(col.to_double(), k.to_double(), 3) > 0.5 {
        "1"
      } else {
        "0"
      }
      let a = 20.0 + 60 * n3(col.to_double() * 0.3, y * 0.004, s * 0.3)
      p.fill(rgba(cyan, a))
      p.text(bit, x, y)
    }
  }
  p.fill(rgba(bg, 170))
  p.rect(0, 380, w, 300)
  p.text_font(serif)
  p.text_size(92)
  p.fill(rgba(cream, 255 * smooth((s - 0.4) / 1.2)))
  p.text("A Short History of Computation", w / 2, 500)
  p.text_font(mono)
  p.text_size(28)
  p.fill(rgba(amber, 255 * smooth((s - 1.6) / 1.0)))
  p.text(typed("drawn frame by frame with p5.mbt", (s - 1.6) / 1.6), w / 2, 590)
}

///|
/// A gear with `teeth` teeth of module `m` (pitch radius = teeth * m / 2).
fn gear(
  p : @p5.P5,
  x : Double,
  y : Double,
  teeth : Int32,
  m : Double,
  angle : Double,
  col : (Int32, Int32, Int32),
) -> Unit {
  let r = teeth.to_double() * m / 2
  let outer = r + m * 0.9
  let inner = r - m * 1.1
  let step = @p5.TWO_PI / teeth.to_double()
  p.push()
  p.translate(x, y)
  p.rotate(angle)
  p.fill(col)
  p.stroke(rgba(bg, 255))
  p.stroke_weight(2)
  p.begin_shape()
  for i in 0..<teeth {
    let a = i.to_double() * step
    for (f, rr) in [(0.0, inner), (0.2, outer), (0.5, outer), (0.7, inner)] {
      p.vertex(rr * p.cos(a + f * step), rr * p.sin(a + f * step))
    }
  }
  // a cut-out ring of spokes, as a contour
  p.begin_contour()
  let hole = r * 0.72
  for i in 0..<=48 {
    let a = -i.to_double() * @p5.TWO_PI / 48
    p.vertex(hole * p.cos(a), hole * p.sin(a))
  }
  p.end_contour(mode=Close)
  p.end_shape(mode=Close)
  // spokes and hub
  p.stroke(col)
  p.stroke_weight(m * 2.2)
  for i in 0..<4 {
    let a = i.to_double() * @p5.HALF_PI
    p.line(0, 0, hole * p.cos(a), hole * p.sin(a))
  }
  p.no_stroke()
  p.fill(col)
  p.circle(0, 0, r * 0.35)
  p.fill(rgba(bg, 255))
  p.circle(0, 0, r * 0.1)
  p.pop()
}

///|
/// Angle of a gear meshing with gear 1 at contact direction `theta`.
fn mesh_angle(a1 : Double, t1 : Int32, t2 : Int32, theta : Double) -> Double {
  let s1 = @p5.TWO_PI / t1.to_double()
  let s2 = @p5.TWO_PI / t2.to_double()
  let c1 = 0.35 * s1
  let c2 = 0.35 * s2
  theta +
  @p5.PI -
  c2 -
  s2 / 2 -
  t1.to_double() / t2.to_double() * (a1 - (theta - c1))
}

///|
fn antikythera(p : @p5.P5, s : Double, _d : Double) -> Unit {
  let bronze = (196, 150, 86)
  let bronze2 = (160, 116, 62)
  let m = 7.0
  let a1 = s * 0.25
  let (x1, y1) = (620.0, 540.0)
  let (t1, t2, t3) = (64, 24, 40)
  let r1 = t1.to_double() * m / 2
  let r2 = t2.to_double() * m / 2
  let r3 = t3.to_double() * m / 2
  let th2 = -0.45
  let x2 = x1 + (r1 + r2) * p.cos(th2)
  let y2 = y1 + (r1 + r2) * p.sin(th2)
  let a2 = mesh_angle(a1, t1, t2, th2)
  let th3 = 0.75
  let x3 = x2 + (r2 + r3) * p.cos(th3)
  let y3 = y2 + (r2 + r3) * p.sin(th3)
  let a3 = mesh_angle(a2, t2, t3, th3)
  gear(p, x1, y1, t1, m, a1, bronze)
  gear(p, x2, y2, t2, m, a2, bronze2)
  gear(p, x3, y3, t3, m, a3, bronze)
  // the sky dial driven by the gears
  let (cx, cy) = (1440.0, 520.0)
  p.no_fill()
  p.stroke(rgba(cream, 120))
  p.stroke_weight(2)
  p.circle(cx, cy, 340)
  p.circle(cx, cy, 250)
  for i in 0..<12 {
    let a = i.to_double() * @p5.TWO_PI / 12
    p.line(
      cx + 125 * p.cos(a),
      cy + 125 * p.sin(a),
      cx + 170 * p.cos(a),
      cy + 170 * p.sin(a),
    )
  }
  let sun = -a1 * 0.5 - @p5.HALF_PI
  let moon = -a1 * 0.5 * 13.37 - @p5.HALF_PI
  p.stroke(rgba(amber, 230))
  p.stroke_weight(4)
  p.line(cx, cy, cx + 150 * p.cos(sun), cy + 150 * p.sin(sun))
  p.no_stroke()
  p.fill(amber)
  p.circle(cx + 150 * p.cos(sun), cy + 150 * p.sin(sun), 26)
  p.stroke(rgba(cream, 200))
  p.stroke_weight(3)
  p.line(cx, cy, cx + 105 * p.cos(moon), cy + 105 * p.sin(moon))
  p.no_stroke()
  p.fill(cream)
  p.circle(cx + 105 * p.cos(moon), cy + 105 * p.sin(moon), 20)
  p.fill(rgba(bg, 255))
  p.circle(cx + 105 * p.cos(moon) + 6, cy + 105 * p.sin(moon) - 3, 16)
  p.fill(rgba(dim, 220))
  p.text_font(mono)
  p.text_size(18)
  p.text_align(HCenter, vertical=Top)
  p.text("sun and moon pointers", cx, cy + 190)
}

///|
fn pascaline(p : @p5.P5, s : Double, d : Double) -> Unit {
  let digits = 6
  let v = @cmath.pow(10, 4.6 * @cmath.pow(clamp01((s - 0.8) / (d - 1.6)), 1.5)) -
    1
  let cell = 150.0
  let ww = 120.0
  let gap = 22.0
  let total = digits.to_double() * (ww + gap) - gap
  let x0 = (w - total) / 2
  let y0 = 380.0
  // brass housing
  p.no_stroke()
  p.fill((70, 56, 40))
  p.rect(x0 - 40, y0 - 50, total + 80, cell + 150, tl=18)
  for i in 0..<digits {
    let place = digits - 1 - i
    let unit = @cmath.pow(10, place.to_double())
    let q = (v / unit).floor()
    let digit = @p5.js_rem(q, 10)
    let r = v - q * unit
    let frac = clamp01(r - (unit - 1.0))
    let x = x0 + i.to_double() * (ww + gap)
    p.fill((236, 226, 200))
    p.rect(x, y0, ww, cell, tl=10)
    p.push()
    p.clip(() => p.rect(x, y0, ww, cell, tl=10))
    p.fill((30, 26, 22))
    p.text_font(serif)
    p.text_size(112)
    p.text_align(HCenter, vertical=VCenter)
    let yy = y0 + cell / 2 - frac * cell
    p.text("\{digit.to_int()}", x + ww / 2, yy)
    p.text("\{@p5.js_rem(digit + 1, 10).to_int()}", x + ww / 2, yy + cell)
    p.pop()
    // the carry: a wheel that is rolling over lights up
    if frac > 0.02 && place > 0 {
      p.no_fill()
      p.stroke(rgba(amber, 255 * (1.0 - (frac - 0.5).abs() * 2)))
      p.stroke_weight(5)
      p.rect(x - 4, y0 - 4, ww + 8, cell + 8, tl=12)
      p.no_stroke()
    }
    // driving wheel below, turning with the digit
    let angle = (q + frac) * @p5.TWO_PI / 10
    p.push()
    p.translate(x + ww / 2, y0 + cell + 62)
    p.rotate(angle)
    p.no_fill()
    p.stroke((196, 150, 86))
    p.stroke_weight(4)
    p.circle(0, 0, 76)
    for k in 0..<10 {
      let a = k.to_double() * @p5.TWO_PI / 10
      p.line(24 * p.cos(a), 24 * p.sin(a), 38 * p.cos(a), 38 * p.sin(a))
    }
    p.pop()
    p.no_stroke()
  }
  p.fill(rgba(dim, 220))
  p.text_font(mono)
  p.text_size(20)
  p.text_align(HCenter, vertical=Top)
  p.text(
    "each turn of a wheel past 9 nudges its left neighbour by one",
    w / 2,
    y0 + cell + 120,
  )
}

///|
/// Row `k` of the woven pattern: rule 90 grown from one thread.
fn rule90(width : Int32, rows : Int32) -> Array[Array[Bool]] {
  let out : Array[Array[Bool]] = []
  let mut row = Array::make(width, false)
  row[width / 2] = true
  for _ in 0..<rows {
    out.push(row)
    let next = Array::make(width, false)
    for i in 0..<width {
      let l = if i > 0 { row[i - 1] } else { false }
      let r = if i + 1 < width { row[i + 1] } else { false }
      next[i] = l != r
    }
    row = next
  }
  out
}

///|
let woven : Array[Array[Bool]] = rule90(63, 40)

///|
fn jacquard(p : @p5.P5, s : Double, d : Double) -> Unit {
  let rows = woven.length()
  let shown = (clamp01((s - 0.5) / (d - 1.5)) * rows.to_double())
    .floor()
    .to_int()
  let cell = 13.0
  let fx = 840.0
  let fy = 275.0
  // fabric
  p.no_stroke()
  p.fill((24, 30, 58))
  p.rect(fx - 10, fy - 10, 63.0 * cell + 20, rows.to_double() * cell + 20, tl=6)
  for r in 0..<shown {
    for c, on in woven[r] {
      let x = fx + c.to_double() * cell
      let y = fy + r.to_double() * cell
      if on {
        p.fill(amber)
        p.rect(x + 1, y + 2, cell - 2, cell - 4, tl=3)
      } else {
        p.fill(if (r + c) % 2 == 0 { (44, 58, 104) } else { (36, 48, 90) })
        p.rect(x + 2, y + 1, cell - 4, cell - 2, tl=3)
      }
    }
  }
  // the shuttle on the row being woven
  if shown < rows {
    let y = fy + shown.to_double() * cell + cell / 2
    let sx = fx + (0.5 + 0.5 * p.sin(s * 9)) * 63 * cell
    p.stroke(rgba(cream, 160))
    p.stroke_weight(2)
    p.line(fx, y, sx, y)
    p.no_stroke()
    p.fill(cream)
    p.ellipse(sx, y, 34, h=12)
  }
  // the chain of punched cards, one card per row
  let cx = 250.0
  let cw = 470.0
  let ch = 46.0
  p.text_font(mono)
  p.text_size(16)
  for k in 0..<9 {
    let r = shown + k - 4
    let y = 285.0 + k.to_double() * (ch + 9)
    if r < 0 || r >= rows {
      continue
    }
    let current = r == shown.min(rows - 1)
    p.no_stroke()
    p.fill(if current { (250, 238, 205) } else { (205, 196, 172) })
    p.rect(cx, y, cw, ch, tl=4)
    // holes: every third thread of the row
    for i in 0..<21 {
      if woven[r][i * 3] {
        p.fill((20, 18, 16))
        p.circle(cx + 22 + i.to_double() * 21.5, y + ch / 2, 12)
      }
    }
  }
  p.fill(rgba(dim, 220))
  p.text_align(HCenter, vertical=Top)
  p.text("one card per row: a hole lifts a thread", cx + cw / 2, 790)
}

///|
priv struct Frac {
  num : @bigint.BigInt
  den : @bigint.BigInt
}

///|
fn gcd(a : @bigint.BigInt, b : @bigint.BigInt) -> @bigint.BigInt {
  let zero = @bigint.BigInt::from_int(0)
  let mut x = if a < zero { -a } else { a }
  let mut y = if b < zero { -b } else { b }
  while !y.is_zero() {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
fn Frac::make(num : @bigint.BigInt, den : @bigint.BigInt) -> Frac {
  let g = gcd(num, den)
  let (n, d) = if g.is_zero() { (num, den) } else { (num / g, den / g) }
  if d < @bigint.BigInt::from_int(0) {
    { num: -n, den: -d, }
  } else {
    { num: n, den: d, }
  }
}

///|
fn Frac::sub(self : Frac, o : Frac) -> Frac {
  Frac::make(self.num * o.den - o.num * self.den, self.den * o.den)
}

///|
fn Frac::scale(self : Frac, k : Int32) -> Frac {
  Frac::make(self.num * @bigint.BigInt::from_int(k), self.den)
}

///|
fn Frac::to_string(self : Frac) -> String {
  if self.den == @bigint.BigInt::from_int(1) {
    self.num.to_string()
  } else {
    "\{self.num}/\{self.den}"
  }
}

///|
/// Bernoulli numbers B0..Bn by the Akiyama–Tanigawa algorithm, exactly.
fn bernoulli(n : Int32) -> Array[Frac] {
  let a : Array[Frac] = []
  let out : Array[Frac] = []
  for m in 0..<=n {
    a.push(
      Frac::make(@bigint.BigInt::from_int(1), @bigint.BigInt::from_int(m + 1)),
    )
    for j = m; j >= 1; j = j - 1 {
      a[j - 1] = a[j - 1].sub(a[j]).scale(j)
    }
    out.push(a[0])
  }
  out
}

///|
let bernoulli_numbers : Array[Frac] = bernoulli(20)

///|
fn subscript(n : Int32) -> String {
  let digits = [
    "₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉",
  ]
  let s = n.to_string()
  s.to_array().map(c => digits[c.to_int() - '0'.to_int()]).join("")
}

///|
fn lovelace(p : @p5.P5, s : Double, _d : Double) -> Unit {
  // Babbage's engine: columns of figure wheels
  let x0 = 260.0
  for col in 0..<4 {
    let x = x0 + col.to_double() * 120
    p.stroke(rgba((196, 150, 86), 200))
    p.stroke_weight(6)
    p.line(x, 290, x, 790)
    for k in 0..<8 {
      let y = 320.0 + k.to_double() * 62
      p.no_stroke()
      p.fill((150, 112, 62))
      p.ellipse(x, y + 8, 88, h=26)
      p.fill((206, 164, 98))
      p.ellipse(x, y, 88, h=26)
      let digit = (n3(col.to_double() * 3, k.to_double(), s * 0.9) * 30)
        .floor()
        .to_int() %
        10
      p.fill((40, 30, 18))
      p.text_font(serif)
      p.text_size(22)
      p.text_align(HCenter, vertical=VCenter)
      p.text(digit.to_string(), x, y + 1)
    }
  }
  p.fill(rgba(dim, 220))
  p.text_font(mono)
  p.text_size(18)
  p.text_align(HCenter, vertical=Top)
  p.text("the Store: columns of figure wheels", x0 + 180, 800)
  // the numbers, computed exactly in MoonBit
  p.text_align(Left, vertical=Baseline)
  p.text_font(serif)
  p.text_size(40)
  let xs = 900.0
  let mut line = 0
  for i, b in bernoulli_numbers {
    if i != 0 && (i % 2 == 1 || b.num.is_zero()) {
      continue
    }
    let appear = 0.7 + line.to_double() * 0.55
    if s > appear {
      let col = line / 6
      let row = line % 6
      let txt = "B\{subscript(i)} = \{b}"
      p.fill(
        rgba(
          if i == 0 {
            cream
          } else {
            amber
          },
          255 * smooth((s - appear) / 0.4),
        ),
      )
      p.text(
        typed(txt, (s - appear) / 0.5),
        xs + col.to_double() * 480,
        340 + row.to_double() * 76,
      )
    }
    line += 1
  }
}
