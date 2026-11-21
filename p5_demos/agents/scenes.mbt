// Title cards, what MoonBit inherited, the age of agents, the crescent made
// of code, and the film look (letterbox, grain, subtitles).

///|
let zh_font : String = "\"PingFang SC\", \"Hiragino Sans GB\", \"Microsoft YaHei\", sans-serif"

///|
/// Height of the letterbox bars (a 2.39:1 picture).
let bar : Double = 138

///|
fn crescent_icon(
  p : @p5.P5,
  x : Double,
  y : Double,
  r : Double,
  a : Double,
) -> Unit {
  p.push()
  p.no_stroke()
  p.fill(rgba((236, 230, 255), 255 * a))
  p.clip(() => p.circle(x, y, r * 2))
  p.circle(x, y, r * 2)
  p.fill(rgba((24, 20, 48), 255 * a))
  p.circle(x + r * 0.45, y - r * 0.25, r * 1.8)
  p.pop()
}

///|
fn spaced(s : String) -> String {
  s.to_array().map(c => c.to_string()).join(" ")
}

// ---------------------------------------------------------------- opening

///|
fn opening(p : @p5.P5, t : Double) -> Unit {
  let first = all_shots[0].start
  if t >= first + 0.2 {
    return
  }
  let v = { x: t * 40, y: t * 12, zoom: 1, rot: 0, }
  sky(p, v)
  // "A MoonBit film"
  let a1 = smooth((t - 0.6) / 0.8).min(smooth((3.3 - t) / 0.5))
  if a1 > 0 {
    p.no_stroke()
    p.text_font(sans)
    p.text_size(26)
    p.text_align(HCenter, vertical=VCenter)
    p.fill(rgba(dim, 255 * a1))
    p.text(spaced("A MOONBIT FILM"), w / 2, h / 2)
  }
  // the title, with a light sweeping across it
  let a2 = smooth((t - @story.title_start) / 0.9).min(
    smooth((first - 0.2 - t) / 0.5),
  )
  if a2 > 0 {
    p.push()
    p.translate(0, 14 * (1 - a2))
    p.no_stroke()
    p.text_font(serif)
    p.text_size(84)
    p.text_align(HCenter, vertical=Baseline)
    p.fill(rgba(cream, 255 * a2))
    p.text("From Punched Cards to AI Agents", w / 2, 530)
    p.text_font(zh_font)
    p.text_size(38)
    p.fill(rgba(amber, 230 * a2))
    p.text("从穿孔卡片到 AI 智能体", w / 2, 600)
    p.pop()
    let sweep = (t - @story.title_start - 0.4) / 2.2
    if sweep > 0 && sweep < 1 {
      p.push()
      p.blend_mode(Add)
      p.no_stroke()
      let x = lerp(300, 1620, sweep)
      for i in 0..<12 {
        p.fill(rgba((255, 220, 170), 7 * a2))
        p.ellipse(x, 510, 40 + i.to_double() * 26, h=260 + i.to_double() * 10)
      }
      p.pop()
    }
  }
}

// ---------------------------------------------------------- the inheritance

///|
/// When the "In MoonBit" panel appears beside language `i`.
fn link_time(i : Int32) -> Double {
  arrival(i) + 2.6
}

///|
/// Beside each language, what MoonBit took from it: no frame, just the code
/// in MoonBit's colours, floating in the night. World coordinates.
fn link_panel(p : @p5.P5, i : Int32, t : Double) -> Unit {
  let s = t - link_time(i)
  let fade = plate_alpha()
  if s <= 0 || fade < 0.05 {
    return
  }
  let link = link_of(langs[i].name)
  let (nx, ny) = positions[i]
  let x0 = nx + 620
  let y0 = ny - 300
  let a = smooth(s / 0.8) * fade
  // a thread of light from the screen
  p.no_fill()
  p.stroke(rgba(moon_purple, 160 * a))
  p.stroke_weight(2)
  let (lx0, ly0) = (nx + 505, ny + 40)
  let (lx1, ly1) = (x0 - 20, y0 + 20)
  let u = clamp01(s / 0.5)
  p.bezier(
    lx0,
    ly0,
    lx0 + 40,
    ly0,
    lx1 - 40,
    ly1,
    lerp(lx0, lx1, u),
    lerp(ly0, ly1, u),
  )
  // a soft glow behind the code
  p.no_stroke()
  for k in 0..<8 {
    p.fill(rgba((90, 60, 180), 7 * a))
    p.ellipse(
      x0 + 360,
      y0 + 180,
      820 - k.to_double() * 70,
      h=520 - k.to_double() * 45,
    )
  }
  crescent_icon(p, x0 + 14, y0 + 18, 14, a)
  p.no_stroke()
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(30)
  p.text_align(Left, vertical=VCenter)
  p.fill(rgba(moon_purple, 255 * a))
  p.text("MoonBit", x0 + 42, y0 + 18)
  p.text_style(Normal)
  let shown = (clamp01((s - 0.3) / 1.8) * char_count(link.code).to_double())
    .floor()
    .to_int()
  if link.terminal {
    let ink = (_ : Tok) => (200, 225, 215)
    draw_code(p, link.code, shown, x0, y0 + 90, 25, 38, mono, plain_tokens, ink)
    |> ignore
  } else {
    let colorize = (line : String) => {
      tokenize(
        line,
        [
          "fn", "let", "mut", "for", "in", "match", "enum", "return", "if", "test",
        ],
        "//",
        "\"",
      )
    }
    draw_code(
      p,
      link.code,
      shown,
      x0,
      y0 + 90,
      25,
      38,
      mono,
      colorize,
      palette(Moon),
    )
    |> ignore
  }
}

///|
/// Code pours along every line of influence, then gathers where MoonBit
/// appears. Drawn in world coordinates.
fn ai_swarm(p : @p5.P5, v : View, t : Double) -> Unit {
  if t < @story.ai_start - 0.2 || t > @story.moon_arrive {
    return
  }
  let (mx, my) = positions[@story.moon_node]
  let paths : Array[(Int32, Int32)] = edges.filter(e => e.1 != @story.moon_node)
  p.no_stroke()
  let z = v.zoom.max(0.05)
  for k in 0..<560 {
    let (a, b) = paths[k % paths.length()]
    let speed = 0.25 + hash01(k) * 0.55
    let u = (hash01(k + 1) + (t - @story.ai_start) * speed) % 1.0
    let (px, py) = edge_point(a, b, u)
    let gather = ease_in_out(
      (t - @story.ai_converge - hash01(k + 2) * 0.5) / 0.8,
    )
    let x = lerp(px, mx, gather)
    let y = lerp(py, my + 40, gather)
    let appear = smooth((t - @story.ai_start - hash01(k + 3) * 1.2) / 0.3)
    let c = if hash01(k + 4) < 0.6 { (120, 220, 255) } else { (230, 240, 255) }
    p.fill(rgba(c, 230 * appear * (1 - smooth((t - @story.moon_born) / 0.2))))
    p.circle(x, y, (6 + 7 * hash01(k + 5)) / z)
  }
  let since = t - @story.moon_born
  if since > -0.3 && since < 0.5 {
    let r = (since + 0.3) * 6000
    for i in 0..<8 {
      p.fill(rgba(moon_purple, 45 * (1 - (since + 0.3) / 0.8)))
      p.circle(mx, my + 40, r * (0.3 + i.to_double() * 0.1))
    }
    p.fill(rgba((255, 255, 255), 255 * clamp01(1 - since.abs() * 3)))
    p.circle(mx, my + 40, 260 / z * clamp01(1 - since.abs() * 2))
  }
}

///|
fn ai_titles(p : @p5.P5, t : Double) -> Unit {
  let a = smooth((t - @story.ai_start + 0.3) / 0.8).min(
    smooth((@story.moon_born - t) / 0.5),
  )
  if a <= 0 {
    return
  }
  p.no_stroke()
  p.text_align(Right, vertical=Baseline)
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(64)
  p.fill(rgba((150, 215, 255), 255 * a))
  p.text("2020s", 1820, 262)
  p.text_style(Normal)
}

///|
let moonbit_code : Array[String] = [
  "///|", "fn fib(n : Int32) -> Int32 {", "  match n {", "    0 | 1 => n", "    _ => fib(n - 1) + fib(n - 2)",
  "  }", "}", "", "///|", "test \"fib\" {", "  inspect(fib(10), content=\"55\")",
  "}",
]

///|
fn moon_plate(p : @p5.P5, t : Double) -> Unit {
  let i = @story.moon_node
  let (nx, ny) = positions[i]
  let boot = clamp01((t - born(i)) / 0.5)
  if detail.val {
    plate_label(
      p,
      nx,
      ny,
      "2023",
      "MoonBit",
      "",
      moon_purple,
      smooth(boot * 1.5) * plate_alpha(),
    )
  }
  p.push()
  p.translate(nx - 1305, ny - 470 + 50 * (1 - smooth(boot)))
  let shown = shown_chars(i, moonbit_code, t)
  let pos = editor(
    p,
    "fib.mbt",
    moonbit_code,
    shown,
    800,
    150,
    1010,
    720,
    Moon,
    ["fn", "match", "test"],
    "///",
    "\"",
  )
  if shown < char_count(moonbit_code) {
    cursor(p, pos, 24, (224, 228, 236), t)
  }
  // the agent runs the tests
  let ta = arrival(i) + 2.6
  if t > ta && detail.val {
    p.no_stroke()
    p.fill((16, 14, 28))
    p.rect(830, 700, 950, 140, tl=12, tr=12, br=12, bl=12)
    p.text_font(mono)
    p.text_size(24)
    p.text_align(Left, vertical=Baseline)
    p.fill(moon_purple)
    p.text("$", 860, 750)
    p.fill(cream)
    p.text(typed("moon test", (t - ta) / 0.5), 892, 750)
    p.fill((120, 230, 140, 255.0 * smooth((t - ta - 0.8) / 0.25)))
    p.text("Total tests: 1, passed: 1, failed: 0.", 860, 800)
  }
  p.pop()
  if !detail.val || plate_alpha() < 0.05 {
    return
  }
  orbit(p, nx + 1010, ny + 0, t)
  poem(p, nx + 1010, ny + 405, t)
}

///|
/// An agent's loop as an orbit around the moon: write, check, test, run,
/// and round again, fast. World coordinates, centred on (cx, cy).
fn orbit(p : @p5.P5, cx : Double, cy : Double, t : Double) -> Unit {
  let start = arrival(@story.moon_node) + 0.4
  let a = ease_in_out((t - start) / 0.9)
  if a <= 0 {
    return
  }
  let r = 230.0
  // the moon at the centre
  p.no_stroke()
  for i in 0..<10 {
    p.fill(rgba(moon_purple, 9 * a))
    p.circle(cx, cy, 150 + i.to_double() * 26)
  }
  crescent_icon(p, cx, cy, 70, a)
  // the orbit
  p.no_fill()
  p.stroke(rgba(dim, 90 * a))
  p.stroke_weight(1.5)
  p.circle(cx, cy, r * 2)
  let period = 1.4
  let phase = (t - start) / period
  let ang = phase * 6.2831853 - 1.5707963
  // a comet tail of light chasing round
  p.no_stroke()
  for k in 0..<24 {
    let back = ang - k.to_double() * 0.06
    p.fill(rgba((236, 230, 255), (230 - k.to_double() * 9) * a))
    p.circle(
      cx + r * @cmath.cos(back),
      cy + r * @cmath.sin(back),
      16 - k.to_double() * 0.5,
    )
  }
  let names = ["write", "check", "test", "run"]
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(30)
  for k, name in names {
    let sa = k.to_double() * 1.5707963 - 1.5707963
    let sx = cx + r * @cmath.cos(sa)
    let sy = cy + r * @cmath.sin(sa)
    let d = ((ang - sa) % 6.2831853 + 6.2831853) % 6.2831853
    let lit = clamp01(1 - d / 1.2)
    p.fill(rgba(moon_purple, (120 + 135 * lit) * a))
    p.circle(sx, sy, 12 + 8 * lit)
    let (ox, oy, al) = match k {
      0 => (0.0, -34.0, @p5.HCenter)
      1 => (30.0, 0.0, @p5.Left)
      2 => (0.0, 40.0, @p5.HCenter)
      _ => (-30.0, 0.0, @p5.Right)
    }
    p.fill(rgba(cream, (150 + 105 * lit) * a))
    p.text_align(al, vertical=VCenter)
    p.text(name, sx + ox, sy + oy)
  }
  p.text_style(Normal)
}

///|
/// The four promises, one at a time, as the narrator says them.
fn poem(p : @p5.P5, cx : Double, y : Double, t : Double) -> Unit {
  let words = [
    ("Designed for AI", "Designed for AI."),
    ("Safe", "Safe."),
    ("Verifiable", "Verifiable."),
    ("Fast to compile", "Fast."),
  ]
  p.no_stroke()
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(58)
  p.text_align(HCenter, vertical=Baseline)
  for k, word in words {
    let (phrase, shown) = word
    let at = @story.phrase_time(@story.moon_line, phrase) - 0.15
    let next = if k + 1 < words.length() {
      @story.phrase_time(@story.moon_line, words[k + 1].0) - 0.15
    } else {
      @story.tagline_start
    }
    let a = smooth((t - at) / 0.4).min(smooth((next - t) / 0.3))
    if a > 0 {
      p.fill(rgba(cream, 255 * a))
      p.text(shown, cx, y + 16 * (1 - smooth((t - at) / 0.4)))
    }
  }
  p.text_style(Normal)
}

///|
/// The refrain: every age has its own language. Three rows, one for each
/// beat of the narration, the last one MoonBit's.
fn tagline_card(p : @p5.P5, t : Double) -> Unit {
  let a = smooth((t - @story.tagline_start) / 0.6).min(
    smooth((@story.finale_start + 0.2 - t) / 0.5),
  )
  if a <= 0 {
    return
  }
  full_rect(p, rgba((6, 5, 16), 232 * a))
  let rows = [
    ("Unix", "C", "Unix", cream),
    ("GPU", "CUDA", "GPU", cream),
    ("Agents", "MoonBit", "agents", moon_purple),
  ]
  for k, row in rows {
    let (age, lang, phrase, colour) = row
    let at = @story.phrase_time(@story.tagline_line, phrase) - 0.2
    let r = ease_in_out((t - at) / 0.6) * a
    if r <= 0 {
      continue
    }
    let y = 380.0 + k.to_double() * 150
    let last = k == rows.length() - 1
    // earlier rows step back when the last one arrives
    let dimmed = if last {
      1.0
    } else {
      1 -
      0.55 *
      smooth(
        (t - @story.phrase_time(@story.tagline_line, "agents") + 0.2) / 0.6,
      )
    }
    p.no_stroke()
    p.text_font(serif)
    p.text_style(Italic)
    p.text_size(46)
    p.text_align(Right, vertical=Baseline)
    p.fill(rgba(dim, 255 * r * dimmed))
    p.text(age, 890 - 20 * (1 - r), y)
    p.text_style(Normal)
    p.text_size(if last { 104 } else { 88 })
    p.text_align(Left, vertical=Baseline)
    p.fill(rgba(colour, 255 * r * dimmed))
    p.text(lang, 940 + 20 * (1 - r), y + 4)
    p.stroke(rgba(dim, 90 * r * dimmed))
    p.stroke_weight(1)
    p.line(912, y - 46, 912, y + 10)
  }
  let last_at = @story.phrase_time(@story.tagline_line, "MoonBit")
  let g = smooth((t - last_at) / 0.8) * a
  if g > 0 {
    crescent_icon(p, 940 + 470, 680 - 40, 26, g)
  }
}

///|
/// Every character of every program, in order.
let all_glyphs : Array[(Char, Int32)] = {
  let out : Array[(Char, Int32)] = []
  for i, l in langs {
    for line in l.code {
      for c in line {
        if c != ' ' {
          out.push((c, i))
        }
      }
    }
    for line in link_of(l.name).code {
      for c in line {
        if c != ' ' {
          out.push((c, @story.moon_node))
        }
      }
    }
  }
  for line in moonbit_code {
    for c in line {
      if c != ' ' {
        out.push((c, @story.moon_node))
      }
    }
  }
  out
}

///|
/// Grid cells inside a crescent: where the glyphs land.
let crescent : Array[(Double, Double)] = {
  let (cx, cy, r) = (520.0, 530.0, 280.0)
  let out : Array[(Double, Double)] = []
  let mut y = cy - r
  while y <= cy + r {
    let mut x = cx - r
    while x <= cx + r {
      let dx = x - cx
      let dy = y - cy
      let ix = dx - 0.44 * r
      let iy = dy + 0.2 * r
      if dx * dx + dy * dy <= r * r && ix * ix + iy * iy > 0.86 * r * (0.86 * r) {
        out.push((x, y))
      }
      x += 18
    }
    y += 23
  }
  out
}

///|
fn finale(p : @p5.P5, t : Double) -> Unit {
  let s = t - @story.finale_start
  full_rect(p, rgba(bg, 255 * smooth((s + 0.2) / 0.9)))
  let settle = smooth((s - 1.6) / 1.0)
  sky(p, { x: s * 20, y: 0, zoom: 1, rot: 0, })
  p.no_stroke()
  for i in 0..<14 {
    p.fill(rgba(moon_purple, 6 * settle))
    p.circle(520, 530, 520 + i.to_double() * 36)
  }
  p.text_font(mono)
  p.text_size(19)
  p.text_align(HCenter, vertical=VCenter)
  let n = crescent.length()
  for k in 0..<n {
    let (tx, ty) = crescent[k]
    let (c, src) = all_glyphs[k * 37 % all_glyphs.length()]
    let from_screen = hash01(k + 11) < 0.35
    let (sx, sy) = if from_screen {
      (300.0 + hash01(k + 12) * 1400, 160.0 + hash01(k + 13) * 760)
    } else {
      let ang = hash01(k + 14) * 6.2831853
      (w / 2 + @cmath.cos(ang) * 1300, h / 2 + @cmath.sin(ang) * 900)
    }
    let delay = hash01(k + 15) * 1.0
    let e = ease_in_out((s - 0.1 - delay) / 1.4)
    let bend = @cmath.sin(3.14159265 * e) * 160 * (hash01(k + 16) - 0.5)
    let x = lerp(sx, tx, e) + bend
    let y = lerp(sy, ty, e) - bend * 0.6
    let col = accent_of(src)
    let mixc = 0.55 * e
    let r = lerp(col.0.to_double(), 226, mixc).to_int()
    let g = lerp(col.1.to_double(), 220, mixc).to_int()
    let b = lerp(col.2.to_double(), 255, mixc).to_int()
    let twinkle = 0.8 + 0.2 * @cmath.sin(t * 3 + k.to_double())
    let appear = if from_screen { smooth(s / 0.3) } else { 1.0 }
    p.push()
    p.translate(x, y)
    p.rotate((1 - e) * (hash01(k + 17) - 0.5) * 8)
    p.fill(rgba((r, g, b), 255 * twinkle * appear))
    p.text(c.to_string(), 0, 0)
    p.pop()
  }
  // the title stays up to the very last frame
  let at = @story.phrase_time(@story.finale_line, "made") - 0.3
  let a = ease_in_out((t - at) / 0.8)
  if a > 0 {
    p.push()
    p.translate(0, 24 * (1 - a))
    p.no_stroke()
    p.text_font(serif)
    p.text_size(118)
    p.text_align(Left, vertical=Baseline)
    let part1 = "Made in"
    p.fill(rgba(cream, 255 * a))
    p.text(part1, 880, 560)
    let gap = p.font_width(part1) + 118 * 0.3
    p.text_style(Italic)
    p.fill(rgba(moon_purple, 255 * a))
    p.text("MoonBit", 880 + gap, 560)
    p.text_style(Normal)
    p.text_font(mono)
    p.text_size(24)
    p.fill(rgba(dim, 230 * smooth((t - at - 1.0) / 0.6)))
    p.text("moonbitlang.com", 886, 640)
    p.pop()
  }
}

// --------------------------------------------------------------- the look

///|
/// A quiet chapter mark in the top bar while the six languages pass.
fn year_counter(p : @p5.P5, t : Double) -> Unit {
  let first = all_shots[0].start
  let a = smooth((t - first - 0.6) / 0.6).min(
    smooth((@story.overview_start + 0.6 - t) / 0.5),
  )
  if a <= 0 {
    return
  }
  let mut k = 0
  for i, s in all_shots {
    if s.start <= t {
      k = i
    }
  }
  let numerals = ["I", "II", "III", "IV", "V", "VI"]
  p.no_stroke()
  p.text_align(HCenter, vertical=Baseline)
  p.text_font(serif)
  p.text_size(30)
  p.fill(rgba(cream, 170 * a))
  p.text(numerals[k], w / 2, 92)
}

///|
/// Chinese subtitles, one short line, in the bottom bar.
fn captions(p : @p5.P5, t : Double) -> Unit {
  for l in all_lines {
    let a = smooth((t - l.start + 0.1) / 0.2).min(
      smooth((l.end + 0.3 - t) / 0.2),
    )
    if a <= 0 {
      continue
    }
    p.no_stroke()
    p.text_align(HCenter, vertical=VCenter)
    p.text_font(zh_font)
    p.text_size(38)
    p.fill(rgba(cream, 240 * a))
    p.text(l.zh, w / 2, h - bar / 2)
  }
}

///|
fn film_look(p : @p5.P5, t : Double) -> Unit {
  // vignette
  p.no_fill()
  for i in 0..<16 {
    let d = 2700.0 - i.to_double() * 70
    p.stroke((0, 0, 0, 10))
    p.stroke_weight(90)
    p.ellipse(w / 2, h / 2, d, h=d * 0.6)
  }
  // grain, different every frame
  let frame = (t * FPS).floor().to_int()
  p.no_stroke()
  for k in 0..<1400 {
    let r = hash01(k * 3 + frame * 7919)
    let c = if r < 0.5 { 255 } else { 0 }
    p.fill((c, c, c, 9.0 + 10 * hash01(k + frame * 31)))
    p.rect(hash01(k + frame * 131) * w, hash01(k * 5 + frame * 17) * h, 2, 2)
  }
  // letterbox
  p.fill((0, 0, 0))
  p.rect(0, 0, w, bar)
  p.rect(0, h - bar, w, bar)
}
