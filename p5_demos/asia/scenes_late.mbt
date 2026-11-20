// Chapters from paper to the bullet train, and the outro.

///|
/// A square card with one character, used as a texture.
fn glyph_card(
  p : @p5.P5,
  ch : String,
  ink : (Int32, Int32, Int32),
  paper : (Int32, Int32, Int32),
) -> @p5.P5 {
  let g = p.create_graphics(256, 256)
  g.pixel_density(1)
  g.background(paper)
  g.no_stroke()
  g.fill(ink)
  g.text_font(cjk)
  g.text_size(190)
  g.text_align(HCenter, vertical=VCenter)
  g.text(ch, 128, 138)
  g
}

// ---- AD 105: paper ----

///|
fn paper(
  p : @p5.P5,
  _ui : @p5.P5,
  s : Double,
  d : Double,
  tex : Ref[@p5.P5?],
) -> Unit {
  let card = match tex.val {
    Some(c) => c
    None => {
      let c = glyph_card(p, "紙", (40, 36, 30), (238, 228, 205))
      tex.val = Some(c)
      c
    }
  }
  backdrop(p, (70, 52, 40), (30, 22, 18))
  p.camera(eye=(0, -120, 700), center=(0, 0, 0), up=(0, 1, 0))
  p.perspective(fovy=0.9)
  p.ambient_light(120)
  p.directional_light((255, 240, 220), -0.3, 0.5, -0.8)
  p.no_stroke()
  p.texture_mode(Normal)
  // sheets drifting down and turning in the air
  for i in 0..<14 {
    let seed = i.to_double() * 1.7
    let fall = (s * 50 + seed * 97) % 900.0 - 450
    p.push()
    p.translate(
      (p.noise(seed) - 0.5) * 900 + p.sin(s + seed) * 40,
      fall,
      z=(p.noise(seed + 9) - 0.5) * 500,
    )
    p.rotate_y(s * 0.6 + seed)
    p.rotate_x(p.sin(s * 0.8 + seed) * 0.6)
    p.texture(card)
    p.plane(w=110, h=140)
    p.pop()
  }
  ignore(d)
}

// ---- c. 1040: movable type ----

///|
fn movable_type(
  p : @p5.P5,
  _ui : @p5.P5,
  s : Double,
  d : Double,
  tex : Ref[Array[@p5.P5]],
) -> Unit {
  if tex.val.is_empty() {
    for
      ch in [
        "天", "地", "人", "和", "文", "書", "印", "字", "學", "道",
      ] {
      tex.val.push(glyph_card(p, ch, (230, 220, 200), (120, 70, 50)))
    }
  }
  backdrop(p, (28, 24, 22), (12, 10, 10))
  let a = 0.9 + s / d * 0.5
  p.camera(
    eye=(p.cos(a) * 520, -620, p.sin(a) * 520),
    center=(0, 0, 0),
    up=(0, 1, 0),
  )
  p.perspective(fovy=0.8)
  p.ambient_light(90)
  p.directional_light((255, 235, 210), -0.4, 0.8, -0.4)
  p.no_stroke()
  // a forme of type pieces: each one rises into place
  for gx in -4..<=4 {
    for gz in -3..<=3 {
      let id = (gx + 4) * 7 + gz + 3
      let t = smooth((s - 0.4 - p.noise(id.to_double() * 0.3) * 2.5) / 0.8)
      if t > 0 {
        p.push()
        p.translate(gx.to_double() * 62, -30.0 * t, z=gz.to_double() * 62)
        p.rotate_x(-@p5.HALF_PI)
        p.texture(tex.val[id % tex.val.length()])
        p.box(w=56, h=56, d=40)
        p.pop()
      }
    }
  }
}

// ---- c. 1150: Angkor Wat ----

///|
fn tower(p : @p5.P5, scale : Double) -> Unit {
  let tiers = 6
  for i in 0..<tiers {
    let f = 1.0 - i.to_double() / tiers.to_double() * 0.8
    p.push()
    p.translate(0, -(i.to_double() * 26 + 13) * scale, z=0)
    p.box(w=70 * f * scale, h=26 * scale, d=70 * f * scale)
    p.pop()
  }
  p.push()
  p.translate(0, -(tiers.to_double() * 26 + 30) * scale, z=0)
  p.rotate_x(@p5.PI)
  p.cone(r=12 * scale, h=60 * scale, detail_x=12)
  p.pop()
}

///|
fn temple(p : @p5.P5) -> Unit {
  p.fill((150, 130, 104))
  for i in 0..<3 {
    let f = 1.0 - i.to_double() * 0.25
    p.push()
    p.translate(0, -(i.to_double() * 30 + 15), z=0)
    p.box(w=520 * f, h=30, d=380 * f)
    p.pop()
  }
  p.fill((140, 120, 96))
  p.push()
  p.translate(0, -90, z=0)
  tower(p, 1.6)
  p.pop()
  for (x, z) in [(-170.0, -110.0), (170, -110), (-170, 110), (170, 110)] {
    p.push()
    p.translate(x, -60, z~)
    tower(p, 1.0)
    p.pop()
  }
}

///|
fn angkor(p : @p5.P5, _ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (250, 160, 90), (120, 70, 90))
  let a = -0.3 + s / d * 0.4
  p.camera(
    eye=(p.sin(a) * 900, -230, p.cos(a) * 900),
    center=(0, -110, 0),
    up=(0, 1, 0),
  )
  p.perspective(fovy=0.8, near=10, far=6000)
  p.ambient_light((140, 110, 100))
  p.directional_light((255, 200, 150), 0.7, 0.5, -0.4)
  p.no_stroke()
  // the temple and its reflection in the moat
  temple(p)
  p.push()
  p.scale(1, y=-1, z=1)
  temple(p)
  p.pop()
  p.push()
  p.rotate_x(@p5.HALF_PI)
  p.fill((70, 90, 120, 200))
  p.plane(w=3000, h=3000)
  p.pop()
  // palms along the causeway
  p.fill((40, 70, 40))
  for i in 0..<8 {
    let side = if i < 4 { -1.0 } else { 1.0 }
    p.push()
    p.translate(
      side * (420 + (i % 4).to_double() * 120),
      -60,
      z=-200.0 + (i % 4).to_double() * 120,
    )
    p.cylinder(r=5, h=120)
    p.translate(0, -70, z=0)
    p.ellipsoid(rx=50, ry=18, rz=50, detail_x=10, detail_y=6)
    p.pop()
  }
}

// ---- 1206: the Mongol Empire ----

///|
fn mongol(p : @p5.P5, ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (40, 52, 60), (20, 26, 32))
  p.push()
  flat(p)
  p.no_stroke()
  // a plain map of Eurasia's latitude band
  p.fill((90, 110, 90))
  p.rect(100, 230, 1720, 560, tl=20)
  // the empire spreads from the steppe north of the Gobi
  let grow = smooth(ease(s - 0.6, d * 0.6))
  let cx = 1260.0
  let cy = 430.0
  p.fill((200, 70, 50, 200))
  p.begin_shape()
  for i in 0..<120 {
    let a = i.to_double() / 120.0 * @p5.TWO_PI
    let n = p.noise(p.cos(a) * 1.4 + 3, y=p.sin(a) * 1.4 + 3)
    // stretched east-west, more to the west
    let rx = (50.0 + 560 * grow) *
      (0.6 + n) *
      (if p.cos(a) < 0 { 1.3 } else { 0.55 })
    let ry = (30.0 + 130 * grow) * (0.7 + n * 0.6)
    p.vertex(cx + p.cos(a) * rx, cy + p.sin(a) * ry)
  }
  p.end_shape(mode=Close)
  // riders crossing it
  p.stroke(rgba(cream, 230))
  p.stroke_weight(7)
  p.begin_shape(kind=Points)
  for i in 0..<40 {
    let a = i.to_double() * 2.39
    let r = (s * 40 + i.to_double() * 37) % 420.0 * grow
    p.vertex(
      cx + p.cos(a) * r * (if p.cos(a) < 0 { 1.2 } else { 0.6 }),
      cy + p.sin(a) * r * 0.3,
    )
  }
  p.end_shape()
  p.pop()
  let a = smooth((s - 4) / 1)
  ui.text_align(HCenter, vertical=Baseline)
  ui.text_font(sans)
  ui.text_size(26)
  ui.fill(rgba(cream, 255 * a))
  ui.text(
    "by 1279: from Korea to Hungary and from Siberia to the Persian Gulf",
    w / 2,
    760,
  )
}

// ---- 1405: Zheng He's fleets ----

///|
fn junk(p : @p5.P5, sway : Double) -> Unit {
  p.rotate_z(sway * 0.08)
  p.fill((110, 70, 40))
  p.push()
  p.translate(0, -20, z=0)
  p.box(w=240, h=40, d=70)
  p.translate(-110, -20, z=0)
  p.box(w=50, h=30, d=66)
  p.pop()
  for (x, hgt) in [(-60.0, 200.0), (20, 240), (90, 170)] {
    p.push()
    p.translate(x, -40 - hgt / 2, z=0)
    p.fill((80, 50, 30))
    p.cylinder(r=3, h=hgt, detail_x=8)
    p.translate(8, -10, z=0)
    p.fill((200, 60, 45))
    p.box(w=6, h=hgt * 0.7, d=hgt * 0.45)
    p.pop()
  }
}

///|
fn fleet(p : @p5.P5, _ui : @p5.P5, s : Double, _d : Double) -> Unit {
  backdrop(p, (255, 190, 120), (90, 110, 150))
  p.camera(eye=(-200, -260, 900), center=(100, -60, 0), up=(0, 1, 0))
  p.perspective(fovy=0.8, near=10, far=8000)
  p.ambient_light((120, 120, 140))
  p.directional_light((255, 210, 160), 0.6, 0.6, -0.5)
  p.no_stroke()
  let wave = (x : Double, z : Double) => {
    p.sin(x * 0.012 + s * 1.6) * 12 + p.sin(z * 0.02 + s * 1.1) * 8
  }
  // the sea, as strips of vertices
  let cell = 60.0
  for zi in 0..<24 {
    p.begin_shape(kind=TriangleStrip)
    for xi in 0..<44 {
      for dz in 0..<2 {
        let x = xi.to_double() * cell - 1300
        let z = (zi + dz).to_double() * cell - 1200
        let y = wave(x, z)
        let b = 140 + (y * 3).to_int()
        p.fill((30, 70 + b / 4, b))
        p.vertex(x, y, z~)
      }
    }
    p.end_shape()
  }
  // the fleet sailing
  for i in 0..<5 {
    let x = -900.0 + i.to_double() * 330 + s * 25
    let z = -600.0 + (i % 2).to_double() * 380
    p.push()
    p.translate(x, wave(x, z), z~)
    p.scale(0.8 + (i % 2).to_double() * 0.3)
    junk(p, p.sin(s * 1.6 + i.to_double()))
    p.pop()
  }
}

// ---- 1653: the Taj Mahal ----

///|
fn taj_body(p : @p5.P5) -> Unit {
  p.fill((246, 242, 236))
  // plinth and main hall
  p.push()
  p.translate(0, -20, z=0)
  p.box(w=520, h=40, d=520)
  p.translate(0, -110, z=0)
  p.box(w=300, h=180, d=300)
  p.pop()
  // onion dome on a drum, with a finial
  p.push()
  p.translate(0, -240, z=0)
  p.cylinder(r=85, h=40, detail_x=24)
  p.translate(0, -70, z=0)
  p.ellipsoid(rx=110, ry=120, rz=110, detail_x=28, detail_y=20)
  p.translate(0, -125, z=0)
  p.rotate_x(@p5.PI)
  p.cone(r=12, h=60, detail_x=10)
  p.pop()
  // four minarets
  for (x, z) in [(-230.0, -230.0), (230, -230), (-230, 230), (230, 230)] {
    p.push()
    p.translate(x, -170, z~)
    p.cylinder(r=16, h=300, detail_x=16)
    p.translate(0, -165, z=0)
    p.sphere(r=22, detail_x=12, detail_y=8)
    p.pop()
  }
}

///|
fn taj(p : @p5.P5, _ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (255, 200, 170), (150, 140, 190))
  let lift = s / d
  p.camera(
    eye=(0, -220 - lift * 80, 1500 - lift * 250),
    center=(0, -170, 0),
    up=(0, 1, 0),
  )
  p.perspective(fovy=0.75, near=10, far=8000)
  p.ambient_light((150, 140, 150))
  p.directional_light((255, 220, 200), -0.5, 0.6, -0.6)
  p.no_stroke()
  p.specular_material(80)
  p.shininess(20)
  taj_body(p)
  // reflection in the long pool
  p.push()
  p.scale(1, y=-1, z=1)
  taj_body(p)
  p.pop()
  p.push()
  p.rotate_x(@p5.HALF_PI)
  p.translate(0, 600, z=0)
  p.fill((90, 120, 160, 210))
  p.plane(w=240, h=1300)
  p.fill((120, 150, 100))
  p.translate(-420, 0, z=-1)
  p.plane(w=600, h=1300)
  p.translate(840, 0, z=0)
  p.plane(w=600, h=1300)
  p.pop()
}

// ---- c. 1831: the Great Wave ----

///|
fn great_wave(p : @p5.P5, _ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (236, 222, 190), (220, 200, 160))
  p.push()
  flat(p)
  p.no_stroke()
  // Mount Fuji, small in the distance
  p.fill((40, 60, 100))
  p.triangle(1150, 700, 1330, 520, 1510, 700)
  p.fill((245, 240, 230))
  p.triangle(1285, 565, 1330, 520, 1375, 565)
  // the great wave rises and curls
  let rise = smooth(ease(s, d * 0.5))
  let crest = 820.0 - 420 * rise
  p.fill((26, 50, 110))
  p.begin_shape()
  p.vertex(0, 1080)
  p.vertex(0, 760)
  p.bezier_vertex(240, 660)
  p.bezier_vertex(380, crest - 40)
  p.bezier_vertex(620, crest)
  p.bezier_vertex(840, crest + 30)
  p.bezier_vertex(900, crest + 180)
  p.bezier_vertex(820, crest + 240)
  p.bezier_vertex(760, crest + 160)
  p.bezier_vertex(700, 860)
  p.bezier_vertex(1000, 820)
  p.vertex(1920, 860)
  p.vertex(1920, 1080)
  p.end_shape(mode=Close)
  // lighter inner band of the wave
  p.fill((70, 110, 170))
  p.begin_shape()
  p.vertex(80, 1080)
  p.vertex(120, 820)
  p.bezier_vertex(300, 720)
  p.bezier_vertex(420, crest + 40)
  p.bezier_vertex(620, crest + 60)
  p.bezier_vertex(560, 860)
  p.bezier_vertex(470, 960)
  p.bezier_vertex(430, 1080)
  p.end_shape(mode=Close)
  // the foam "claws"
  p.fill((250, 248, 240))
  for i in 0..<18 {
    let t = i.to_double() / 17.0
    let x = 420.0 + t * 460
    let y = crest - 20 + p.sin(t * @p5.PI) * -30 + t * 60
    p.circle(x, y, 26 - t * 10)
    p.circle(x + 14, y + 22, 16)
  }
  // small swells in the foreground
  for i in 0..<6 {
    let x = 1000.0 + i.to_double() * 160 + p.sin(s + i.to_double()) * 20
    p.fill((26, 50, 110))
    p.arc(x, 900, 200, 120, @p5.PI, @p5.TWO_PI, mode=Chord)
    p.fill((250, 248, 240))
    p.circle(x - 60, 860, 18)
  }
  p.pop()
}

// ---- 1964: the bullet train ----

///|
fn shinkansen(p : @p5.P5, _ui : @p5.P5, s : Double, _d : Double) -> Unit {
  backdrop(p, (20, 24, 50), (60, 40, 70))
  let tx = s * 600 - 1200
  p.camera(eye=(tx - 200, -180, 650), center=(tx + 200, -40, 0), up=(0, 1, 0))
  p.perspective(fovy=0.8, near=10, far=8000)
  p.ambient_light((90, 90, 110))
  p.directional_light((220, 220, 255), -0.3, 0.7, -0.5)
  p.no_stroke()
  // a skyline with lit windows
  for i in 0..<40 {
    let x = -2000.0 + i.to_double() * 140
    let hh = 200.0 + p.noise(i.to_double() * 0.7) * 500
    p.push()
    p.translate(x, -hh / 2, z=-700 - (i % 3).to_double() * 120)
    p.fill((30, 30, 50))
    p.box(w=110, h=hh, d=80)
    p.emissive_material((200, 170, 80))
    p.fill((255, 220, 120))
    p.translate(0, 0, z=41)
    let rows = (hh / 40).to_int()
    for r in 0..<rows {
      if p.noise(i.to_double(), y=r.to_double()) > 0.45 {
        p.push()
        p.translate(0, -hh / 2 + r.to_double() * 40 + 20, z=0)
        p.plane(w=80, h=10)
        p.pop()
      }
    }
    p.pop()
  }
  // the viaduct
  p.fill((150, 150, 160))
  p.push()
  p.translate(0, 10, z=0)
  p.box(w=8000, h=20, d=120)
  p.pop()
  // the train: white cars with a blue stripe and a long nose
  p.specular_material(120)
  p.shininess(30)
  for car in 0..<6 {
    let x = tx - car.to_double() * 260
    p.push()
    p.translate(x, -45, z=0)
    p.fill((246, 246, 250))
    p.box(w=250, h=70, d=80)
    p.fill((30, 60, 160))
    p.translate(0, 18, z=41)
    p.box(w=250, h=10, d=2)
    p.pop()
  }
  p.push()
  p.translate(tx + 180, -45, z=0)
  p.fill((246, 246, 250))
  p.ellipsoid(rx=130, ry=35, rz=40, detail_x=24, detail_y=12)
  p.pop()
}

// ---- outro ----

///|
fn outro(p : @p5.P5, ui : @p5.P5, s : Double, _d : Double) -> Unit {
  backdrop(p, (12, 12, 24), (30, 14, 26))
  // a hundred people; about six in ten live in Asia
  p.push()
  flat(p)
  p.no_stroke()
  let shown = smooth((s - 0.5) / 2.5)
  for i in 0..<100 {
    let x = 560.0 + (i % 20).to_double() * 42
    let y = 320.0 + (i / 20).to_double() * 52
    let asia = i < 59
    let a = smooth(shown * 1.4 - i.to_double() / 100.0)
    p.fill(if asia { rgba(vermilion, 255 * a) } else { rgba(dim, 160 * a) })
    p.circle(x, y, 26)
  }
  p.pop()
  ui.text_align(HCenter, vertical=Baseline)
  ui.text_font(serif)
  ui.text_size(52)
  ui.fill(rgba(cream, 255 * smooth((s - 2.5) / 1)))
  ui.text("About six in ten people alive today live in Asia.", w / 2, 220)
  ui.text_font(sans)
  ui.text_size(26)
  ui.fill(rgba(dim, 255 * smooth((s - 4) / 1)))
  ui.text(
    "Five thousand years of cities, writing, ideas, trade and invention — and the story continues.",
    w / 2,
    680,
  )
  ui.text_font(mono)
  ui.text_size(22)
  ui.fill(rgba(gold, 255 * smooth((s - 5.5) / 1)))
  ui.text(
    "Drawn with p5.mbt 0.2.0 — WEBGL, lights, textures, fonts, libtess — in MoonBit",
    w / 2,
    760,
  )
}
