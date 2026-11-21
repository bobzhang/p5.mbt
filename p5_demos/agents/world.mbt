// One big map: every language sits at a place in it, laid out by time
// (left to right) and family (lanes), joined by lines of influence.

///|
/// Plate centres in world coordinates; index 13 is MoonBit.
let positions : Array[(Double, Double)] = [
  (0, -1300), // FORTRAN
  (1800, 800), // LISP
  (3600, -1300), // C
  (5400, 800), // ML
  (7200, -1300), // Rust
  (9000, 2500), // WebAssembly
  (11400, 800), // MoonBit
]

///|
/// Who influenced whom. The last six are what MoonBit inherited.
let edges : Array[(Int32, Int32)] = [
  (0, 2),
  (1, 3),
  (2, 4),
  (3, 4),
  (2, 5),
  (4, 5),
  (0, 6),
  (1, 6),
  (2, 6),
  (3, 6),
  (4, 6),
  (5, 6),
]

///|
let lanes : Array[(Double, String)] = [
  (-1300, "SYSTEMS"),
  (800, "FUNCTIONAL"),
  (2500, "WEB & RUNTIMES"),
]

///|
struct View {
  x : Double
  y : Double
  zoom : Double
  rot : Double
}

///|
/// When the camera has fully arrived at node `i`.
fn arrival(i : Int32) -> Double {
  if i == @story.moon_node {
    @story.moon_arrive
  } else {
    all_shots[i].arrive()
  }
}

///|
/// When node `i` appears on the map.
fn born(i : Int32) -> Double {
  if i == @story.moon_node {
    @story.moon_born
  } else {
    all_shots[i].start + 0.02
  }
}

///|
/// When the camera leaves node `i`.
fn hold_end(i : Int32) -> Double {
  if i == @story.moon_node {
    @story.finale_start
  } else if i + 1 < all_shots.length() {
    all_shots[i + 1].start
  } else {
    @story.overview_start
  }
}

///|
fn accent_of(i : Int32) -> (Int32, Int32, Int32) {
  if i == @story.moon_node {
    moon_purple
  } else {
    era_accent(langs[i].era)
  }
}

///|
/// A point on the influence curve from `a` to `b`, `u` in [0, 1].
fn edge_point(a : Int32, b : Int32, u : Double) -> (Double, Double) {
  let (ax, ay) = positions[a]
  let (bx, by) = positions[b]
  let x0 = ax + 505
  let y0 = ay + 40
  let x1 = bx - 505
  let y1 = by + 40
  let mx = (x0 + x1) / 2
  let v = 1.0 - u
  let x = v * v * v * x0 +
    3 * v * v * u * mx +
    3 * v * u * u * mx +
    u * u * u * x1
  let y = v * v * v * y0 +
    3 * v * v * u * y0 +
    3 * v * u * u * y1 +
    u * u * u * y1
  (x, y)
}

///|
/// A painted night: a deep gradient, slow nebula washes, then the stars.
fn sky(p : @p5.P5, v : View) -> Unit {
  p.no_stroke()
  let bands = 24
  for i in 0..<bands {
    let f = i.to_double() / (bands - 1).to_double()
    let c = (
      lerp(16, 5, f).to_int(),
      lerp(17, 6, f).to_int(),
      lerp(42, 15, f).to_int(),
    )
    p.fill(c)
    p.rect(0, f * h - 2, w, h / bands.to_double() + 4)
  }
  let tints = [(130, 90, 210), (50, 120, 170), (210, 120, 90), (90, 70, 160)]
  for k in 0..<22 {
    let span = 2800.0
    let x = (hash01(k * 5) * span - v.x * v.zoom * 0.07) % span
    let y = (hash01(k * 5 + 1) * 1500.0 - v.y * v.zoom * 0.07) % 1500.0
    let x = (if x < 0 { x + span } else { x }) - 440
    let y = (if y < 0 { y + 1500 } else { y }) - 210
    let r = 260.0 + 420 * hash01(k * 5 + 2)
    let c = tints[k % tints.length()]
    for j in 0..<5 {
      p.fill(rgba(c, 5))
      p.ellipse(
        x,
        y,
        r * (1 - j.to_double() * 0.16) * 1.6,
        h=r * (1 - j.to_double() * 0.16),
      )
    }
  }
  stars(p, v)
}

///|
fn stars(p : @p5.P5, v : View) -> Unit {
  p.no_stroke()
  for i in 0..<240 {
    let depth = 0.3 + hash01(i * 7 + 3)
    let span = 2300.0
    let x = (hash01(i) * span - v.x * v.zoom * 0.04 * depth) % span
    let y = (hash01(i + 500) * 1300.0 - v.y * v.zoom * 0.04 * depth) % 1300.0
    let x = if x < 0 { x + span } else { x }
    let y = if y < 0 { y + 1300 } else { y }
    p.fill(rgba((200, 205, 255), 30 + 90 * hash01(i + 77) * depth))
    p.circle(x - 190, y - 110, 1.2 + 2.2 * depth * hash01(i + 9))
  }
}

///|
/// Draws the whole map as seen by `v`. `sx` squeezes the frame horizontally
/// (for the card flip).
fn draw_view(p : @p5.P5, v : View, t : Double, sx : Double) -> Unit {
  p.push()
  sky(p, v)
  p.translate(w / 2, h / 2)
  p.scale(sx, y=1)
  p.rotate(v.rot)
  p.scale(v.zoom)
  p.translate(-v.x, -v.y)
  detail.val = v.zoom > 0.3
  let far = smooth((0.42 - v.zoom) / 0.22)
  far_out.val = far
  if far > 0 {
    draw_lanes(p, v, far)
  }
  draw_edges(p, v, t)
  for i in 0..<positions.length() {
    if visible(i, v) {
      if t >= born(i) {
        if i == @story.moon_node {
          moon_plate(p, t)
        } else {
          draw_node(p, i, t)
        }
      } else if far > 0 && i != @story.moon_node {
        ghost(p, i, v, far)
      }
    }
  }
  if far > 0 {
    map_labels(p, v, t)
  }
  target(p, v, t)
  ai_swarm(p, v, t)
  p.pop()
  detail.val = true
}

///|
fn visible(i : Int32, v : View) -> Bool {
  let (nx, ny) = positions[i]
  let dx = (nx - v.x) * v.zoom
  let dy = (ny - v.y) * v.zoom
  let r = 1500.0 * v.zoom
  dx * dx + dy * dy < (1150 + r) * (1150 + r)
}

///|
fn draw_lanes(p : @p5.P5, v : View, far : Double) -> Unit {
  for lane in lanes {
    let (y, name) = lane
    p.stroke(rgba(dim, 55 * far))
    p.stroke_weight(1.5 / v.zoom)
    let mut x = -700.0
    while x < 12600 {
      p.line(x, y + 40, x + 160, y + 40)
      x += 320
    }
    p.no_stroke()
    p.fill(rgba(dim, 200 * far))
    p.text_font(mono)
    p.text_size(17 / v.zoom)
    p.text_align(Left, vertical=Bottom)
    p.text(name, -700, y + 40 - 10 / v.zoom)
  }
}

///|
fn draw_edges(p : @p5.P5, v : View, t : Double) -> Unit {
  // the "standing on the shoulders" wave across the whole map
  let wave_t = (t - (@story.overview_end - 0.2)) / 2.6
  for k, e in edges {
    let (a, b) = e
    // the lines into MoonBit draw themselves one by one once the whole map
    // is in view; the others as each language arrives
    let grow = if b == @story.moon_node {
      let m = (k - (edges.length() - 6)).to_double()
      clamp01((t - (@story.overview_end + 0.3 + m * 0.45)) / 0.9)
    } else {
      clamp01((t - born(b) + 0.25) / 0.6)
    }
    if grow <= 0 {
      continue
    }
    let wave = if wave_t > 0 && wave_t < 1.3 {
      let pos = wave_t * edges.length().to_double()
      @cmath.exp(-(pos - k.to_double()).abs() * 1.2)
    } else {
      0
    }
    let c = accent_of(b)
    p.no_fill()
    p.stroke(rgba(c, 110 + 145 * wave))
    p.stroke_weight((2.4 + 3 * wave) / v.zoom.max(0.05))
    p.begin_shape()
    for j in 0..<=28 {
      let (x, y) = edge_point(a, b, j.to_double() / 28 * grow)
      p.vertex(x, y)
    }
    p.end_shape()
    if b == @story.moon_node {
      idea_label(p, v, t, a, grow)
    }
    // a spark runs along the line while it is drawn, or when the wave passes
    let spark = if grow < 1 { grow } else { -1.0 }
    if spark >= 0 || wave > 0.2 {
      let u = if spark >= 0 {
        spark
      } else {
        clamp01(wave_t * edges.length().to_double() - k.to_double() + 0.5)
      }
      let (x, y) = edge_point(a, b, u)
      p.no_stroke()
      p.fill(rgba(c, 70))
      p.circle(x, y, 34 / v.zoom.max(0.05))
      p.fill(rgba((255, 255, 255), 230))
      p.circle(x, y, 12 / v.zoom.max(0.05))
    }
  }
}

///|
/// A language that has not arrived yet: a dashed outline on the map.
fn ghost(p : @p5.P5, i : Int32, v : View, far : Double) -> Unit {
  let (nx, ny) = positions[i]
  p.no_fill()
  p.stroke(rgba(dim, 60 * far))
  p.stroke_weight(2 / v.zoom)
  let (x0, y0, x1, y1) = (nx - 505, ny - 320, nx + 505, ny + 400)
  let step = 90.0
  let mut x = x0
  while x < x1 {
    p.line(x, y0, (x + step / 2).min(x1), y0)
    p.line(x, y1, (x + step / 2).min(x1), y1)
    x += step
  }
  let mut y = y0
  while y < y1 {
    p.line(x0, y, x0, (y + step / 2).min(y1))
    p.line(x1, y, x1, (y + step / 2).min(y1))
    y += step
  }
}

///|
/// Close up, each screen has its own title; from afar, the map has labels.
/// They cross-fade without overlapping.
fn plate_alpha() -> Double {
  1 - smooth(far_out.val / 0.4)
}

///|
fn map_alpha() -> Double {
  smooth((far_out.val - 0.4) / 0.4)
}

///|
fn map_labels(p : @p5.P5, v : View, t : Double) -> Unit {
  for i in 0..<positions.length() {
    if t < born(i) {
      continue
    }
    let (nx, ny) = positions[i]
    let (year, name) = if i == @story.moon_node {
      ("2023", "MoonBit")
    } else {
      (langs[i].year, langs[i].name)
    }
    p.no_stroke()
    p.text_align(HCenter, vertical=Bottom)
    p.text_font(serif)
    p.text_size(30 / v.zoom)
    p.fill(rgba(cream, 255 * map_alpha()))
    p.text(name, nx, ny - 360)
    p.text_style(Italic)
    p.text_size(21 / v.zoom)
    p.fill(rgba(accent_of(i), 255 * map_alpha()))
    p.text(year, nx, ny - 360 - 36 / v.zoom)
    p.text_style(Normal)
  }
}

///|
/// Year, name and author above a language's screen.
fn plate_label(
  p : @p5.P5,
  nx : Double,
  ny : Double,
  year : String,
  name : String,
  who : String,
  accent : (Int32, Int32, Int32),
  a : Double,
) -> Unit {
  // like a museum label: year in italics, the name, the maker
  p.no_stroke()
  p.text_align(Left, vertical=Baseline)
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(46)
  p.fill(rgba(accent, 255 * a))
  p.text(year, nx - 505, ny - 382)
  let yw = p.font_width(year)
  p.text_style(Normal)
  p.text_size(84)
  p.fill(rgba(cream, 255 * a))
  p.text(name, nx - 505 + yw + 22, ny - 382)
  p.text_style(Italic)
  p.text_size(23)
  p.text_align(Right, vertical=Baseline)
  p.fill(rgba(dim, 255 * a))
  p.text(who, nx + 505, ny - 384)
  p.text_style(Normal)
}

///|
/// How many characters of node `i`'s program are on screen at `t`.
fn shown_chars(i : Int32, code : Array[String], t : Double) -> Int32 {
  let start = arrival(i) - 0.15
  let dur = ((hold_end(i) - start) * 0.7).max(0.35).min(4.2)
  (clamp01((t - start) / dur) * char_count(code).to_double()).floor().to_int()
}

///|
fn draw_node(p : @p5.P5, i : Int32, t : Double) -> Unit {
  let l = langs[i]
  let (nx, ny) = positions[i]
  let boot = clamp01((t - born(i)) / 0.45)
  let s = t - arrival(i)
  if detail.val {
    plate_label(
      p,
      nx,
      ny,
      l.year,
      l.name,
      l.who,
      era_accent(l.era),
      smooth(boot * 1.5) * plate_alpha(),
    )
  }
  let shown = shown_chars(i, l.code, t)
  p.push()
  // each kind of machine switches on in its own way
  match l.era {
    Card => p.translate(0, -90 * (1 - ease_in_out(boot)))
    Classic | Window => {
      let k = 1.0 +
        0.12 * @cmath.sin(boot * 3.14159) * (1 - boot) -
        0.08 * (1 - boot)
      p.translate(nx, ny + 40)
      p.scale(k)
      p.translate(-nx, -ny - 40)
    }
    Modern | Moon => p.translate(0, 50 * (1 - smooth(boot)))
    _ => ()
  }
  p.translate(nx - 1305, ny - 470)
  match l.era {
    Paper => paper(p, l, shown, s)
    Card => cards(p, l, shown, s)
    Crt => crt(p, l, shown, s)
    Classic => classic(p, l, shown, s)
    Window => gui_window(p, l, shown, s)
    Modern | Moon => {
      let pos = editor(
        p,
        l.file,
        l.code,
        shown,
        800,
        150,
        1010,
        720,
        Modern,
        l.keywords,
        l.comment,
        l.quotes,
      )
      cursor(p, pos, 24, (224, 228, 236), s)
    }
  }
  // the CRT warms up: a bright line opens into the picture
  if l.era is Crt && boot < 1 {
    let open = ease_in_out(boot)
    let half = 325.0 * open
    p.no_stroke()
    p.fill((7, 24, 13))
    p.rect(845, 185, 920, 325 - half)
    p.rect(845, 510 + half, 920, 325 - half)
    p.fill(rgba((200, 255, 210), 255 * (1 - open)))
    p.rect(845, 508.0 - 2 * (1 - open), 920, 4)
  }
  p.pop()
  // everything fades up from the dark
  if boot < 1 {
    p.no_stroke()
    p.fill(rgba(bg, 255 * (1 - smooth(boot))))
    p.rect(nx - 560, ny - 360, 1120, 840)
  }
}

///|
/// Where every line leads, glowing before MoonBit appears there.
fn target(p : @p5.P5, v : View, t : Double) -> Unit {
  let a = smooth((t - @story.overview_end - 0.6) / 1.0) *
    (1 - smooth((t - @story.moon_born) / 0.3))
  if a <= 0 {
    return
  }
  let (mx, my) = positions[@story.moon_node]
  let z = v.zoom.max(0.05)
  let pulse = 0.5 + 0.5 * @cmath.sin(t * 4)
  p.no_stroke()
  for i in 0..<10 {
    p.fill(rgba(moon_purple, a * (10 + 8 * pulse)))
    p.circle(mx, my + 40, (60 + i.to_double() * 34 * (1 + 0.2 * pulse)) / z)
  }
  p.fill(rgba((236, 230, 255), 255 * a))
  p.circle(mx, my + 40, 26 / z)
  p.text_font(mono)
  p.text_size(20 / z)
  p.text_align(HCenter, vertical=Top)
  p.fill(
    rgba(moon_purple, 230 * a * smooth((t - @story.overview_end - 3.0) / 0.6)),
  )
  p.text("?", mx, my + 40 + 90 / z)
}

///|
/// The idea each language passed on, written along its line into MoonBit.
/// Shown only once the whole map is in view.
let ideas : Array[String] = [
  "speed", "functions as values", "close to the machine", "types inferred", "safety by default",
  "runs anywhere",
]

///|
fn idea_label(
  p : @p5.P5,
  v : View,
  t : Double,
  a : Int32,
  grow : Double,
) -> Unit {
  let alpha = smooth((grow - 0.35) / 0.4) *
    map_alpha() *
    (1 - smooth((t - @story.ai_start) / 0.6))
  if alpha <= 0 {
    return
  }
  // LISP's line runs behind ML's screen, so its label sits earlier on it
  let u = if a == 1 { 0.15 } else { 0.42 }
  let (x, y) = edge_point(a, @story.moon_node, u)
  let z = v.zoom.max(0.05)
  p.no_stroke()
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(27 / z)
  p.text_align(HCenter, vertical=Bottom)
  p.fill(rgba((205, 190, 255), 235 * alpha))
  p.text(ideas[a], x, y - 12 / z)
  p.text_style(Normal)
}
