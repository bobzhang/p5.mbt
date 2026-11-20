// The chapters of the film.

///|
fn scenes(font : @p5.Font?) -> Array[Scene] {
  let paper_tex : Ref[@p5.P5?] = Ref(None)
  let type_tex : Ref[Array[@p5.P5]] = Ref([])
  [
    {
      year: "",
      title: "",
      caption: "",
      features: "",
      seconds: 8,
      draw: (p, ui, s, d) => intro(p, ui, s, d, font),
    },
    {
      year: "c. 2600 BC",
      title: "Cities of the Indus Valley",
      caption: "Mohenjo-daro and Harappa were laid out on grids of streets, with baked-brick houses, wells and covered drains — some of the world's first planned cities.",
      features: "box · camera · directional_light · ambient_light",
      seconds: 8,
      draw: indus,
    },
    {
      year: "c. 1200 BC",
      title: "Writing on bone",
      caption: "Diviners of the Shang dynasty carved questions into ox bones and turtle shells and read the answers in cracks made by heat — the oldest known Chinese writing.",
      features: "begin_shape · noise · create_graphics · CJK text",
      seconds: 8,
      draw: oracle,
    },
    {
      year: "c. 500 BC",
      title: "An age of teachers",
      caption: "Confucius taught in China and the Buddha in northern India within a few generations of each other; their ideas still shape the lives of billions.",
      features: "ellipsoid · specular_material · point_light",
      seconds: 8,
      draw: lotus,
    },
    {
      year: "221 BC",
      title: "The first emperor",
      caption: "Qin Shi Huang united China, standardised its script, coins and weights, and was buried with an army of thousands of life-size terracotta soldiers.",
      features: "cylinder · sphere · box · perspective · lights",
      seconds: 8,
      draw: terracotta,
    },
    {
      year: "c. 130 BC",
      title: "The Silk Road",
      caption: "Han dynasty envoys opened routes from Chang'an to Central Asia, Persia and the Mediterranean. Silk, spices and paper moved along them — and Buddhism travelled east.",
      features: "bezier_point · emissive_material · Points shapes",
      seconds: 9,
      draw: silk_road,
    },
    {
      year: "AD 105",
      title: "Paper",
      caption: "Cai Lun, an official at the Han court, improved papermaking from bark, hemp and rags. Paper reached Samarkand and Baghdad in the 8th century.",
      features: "texture(create_graphics) · plane · rotate",
      seconds: 8,
      draw: (p, ui, s, d) => paper(p, ui, s, d, paper_tex),
    },
    {
      year: "c. 1040",
      title: "Movable type",
      caption: "Bi Sheng printed with movable type made of clay, four centuries before Gutenberg. Korea's Jikji (1377) is the oldest surviving book printed with metal type.",
      features: "box · texture · camera",
      seconds: 8,
      draw: (p, ui, s, d) => movable_type(p, ui, s, d, type_tex),
    },
    {
      year: "c. 1150",
      title: "Angkor Wat",
      caption: "Built for King Suryavarman II of the Khmer Empire, Angkor Wat in Cambodia is the largest religious monument in the world.",
      features: "box · cone · scale(1, -1) reflection · vertex colors",
      seconds: 8,
      draw: angkor,
    },
    {
      year: "1206",
      title: "The Mongol Empire",
      caption: "Temüjin was proclaimed Genghis Khan in 1206. Within decades the Mongols ruled the largest contiguous land empire in history, joining the trade routes of Eurasia.",
      features: "begin_shape · noise · libtess tessellation",
      seconds: 8,
      draw: mongol,
    },
    {
      year: "1405",
      title: "Zheng He's treasure fleets",
      caption: "Between 1405 and 1433 Admiral Zheng He led seven Ming fleets across the Indian Ocean, as far as Arabia and the coast of East Africa.",
      features: "TriangleStrip waves · vertex colors · lights",
      seconds: 9,
      draw: fleet,
    },
    {
      year: "1653",
      title: "The Taj Mahal",
      caption: "The emperor Shah Jahan built the Taj Mahal in Agra as a tomb for his wife Mumtaz Mahal; it was largely complete by 1653.",
      features: "ellipsoid · cylinder · specular_material · reflection",
      seconds: 8,
      draw: taj,
    },
    {
      year: "c. 1831",
      title: "The Great Wave",
      caption: "Hokusai's \"Under the Wave off Kanagawa\", from his Thirty-six Views of Mount Fuji, became one of the most recognised images in art.",
      features: "bezier_vertex · contours · 2D shapes in WEBGL",
      seconds: 8,
      draw: great_wave,
    },
    {
      year: "1964",
      title: "The bullet train",
      caption: "Japan's Shinkansen opened in 1964, just before the Tokyo Olympics. Today high-speed railways link cities across Asia.",
      features: "ellipsoid · box · emissive windows · camera tracking",
      seconds: 8,
      draw: shinkansen,
    },
    {
      year: "",
      title: "",
      caption: "",
      features: "",
      seconds: 10,
      draw: outro,
    },
  ]
}

// ---- helpers ----

///|
/// A vertical gradient filling the canvas, behind everything.
fn backdrop(
  p : @p5.P5,
  top : (Int32, Int32, Int32),
  bottom : (Int32, Int32, Int32),
) -> Unit {
  p.push()
  flat(p)
  p.no_stroke()
  p.begin_shape(kind=Quads)
  p.fill(top)
  p.vertex(0, 0)
  p.vertex(w, 0)
  p.fill(bottom)
  p.vertex(w, h)
  p.vertex(0, h)
  p.end_shape()
  p.pop()
  p.clear_depth()
}

///|
fn ease(s : Double, d : Double) -> Double {
  clamp01(s / d)
}

// ---- intro ----

///|
fn intro(
  p : @p5.P5,
  ui : @p5.P5,
  s : Double,
  _d : Double,
  font : @p5.Font?,
) -> Unit {
  backdrop(p, (12, 12, 24), (40, 18, 30))
  p.push()
  flat(p)
  // "ASIA" assembles from points scattered across the screen
  if font is Some(f) {
    p.text_size(330)
    p.text_align(HCenter)
    let pts = f.text_to_points("ASIA", w / 2, 560, sample_factor=0.16)
    let k = smooth((s - 0.3) / 3)
    p.stroke(rgba(gold, 255))
    p.stroke_weight(5)
    p.begin_shape(kind=Points)
    for i, q in pts {
      let a = i.to_double() * 2.399963
      let r = 900.0 * (1.0 - k)
      let x = q.x + p.cos(a) * r
      let y = q.y + p.sin(a * 1.3) * r * 0.6
      p.vertex(x, y, z=(1.0 - k) * 300 * p.sin(a))
    }
    p.end_shape()
  }
  p.pop()
  ui.no_stroke()
  ui.text_align(HCenter, vertical=Baseline)
  ui.text_font(serif)
  ui.text_size(56)
  ui.fill(rgba(cream, 255 * smooth((s - 3) / 1.2)))
  ui.text("Five Thousand Years of", w / 2, 300)
  ui.text_font(cjk)
  ui.text_size(40)
  ui.fill(rgba(dim, 255 * smooth((s - 3.8) / 1.2)))
  ui.text(
    "亚洲 · アジア · 아시아 · एशिया · เอเชีย · آسيا · châu Á",
    w / 2,
    700,
  )
  ui.text_font(mono)
  ui.text_size(22)
  ui.fill(rgba(dim, 230 * smooth((s - 4.6) / 1)))
  ui.text(
    "a short film drawn with p5.mbt — MoonBit's port of p5.js",
    w / 2,
    770,
  )
}

// ---- c. 2600 BC: Indus cities ----

///|
fn indus(p : @p5.P5, _ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (228, 186, 126), (180, 120, 70))
  let a = 0.5 + s / d * 0.6
  p.camera(
    eye=(p.cos(a) * 900, -650, p.sin(a) * 900),
    center=(0, 0, 0),
    up=(0, 1, 0),
  )
  p.perspective(fovy=0.75, near=10, far=5000)
  p.ambient_light((120, 100, 90))
  p.directional_light((255, 230, 190), -0.5, 0.8, -0.3)
  p.no_stroke()
  // ground
  p.push()
  p.rotate_x(@p5.HALF_PI)
  p.fill((198, 160, 110))
  p.plane(w=1400, h=1400)
  p.pop()
  // a grid of blocks separated by streets; houses rise one by one
  let rise = ease(s, d * 0.6)
  for bx in -3..<=3 {
    for bz in -3..<=3 {
      for hx in 0..<2 {
        for hz in 0..<2 {
          let id = ((bx + 3) * 7 + bz + 3) * 4 + hx * 2 + hz
          let n = p.noise(id.to_double() * 0.37)
          let appear = clamp01(rise * 1.6 - n * 0.6)
          if appear > 0 {
            let hh = (30.0 + n * 50) * smooth(appear)
            p.push()
            p.translate(
              bx.to_double() * 170 + (hx.to_double() - 0.5) * 62,
              -hh / 2,
              z=bz.to_double() * 170 + (hz.to_double() - 0.5) * 62,
            )
            p.fill((176 + (n * 40).to_int(), 104 + (n * 30).to_int(), 72))
            p.box(w=56, h=hh, d=56)
            p.pop()
          }
        }
      }
    }
  }
  // the covered drains along the streets
  p.fill((120, 90, 70))
  for i in -3..<=3 {
    p.push()
    p.translate(i.to_double() * 170 + 85, -1, z=0)
    p.box(w=8, h=2, d=1200)
    p.pop()
  }
  // the Great Bath
  p.push()
  p.translate(0, -2, z=0)
  p.fill((70, 140, 170))
  p.box(w=70, h=4, d=40)
  p.pop()
}

// ---- c. 1200 BC: oracle bones ----

///|
fn oracle(p : @p5.P5, ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (36, 28, 24), (16, 12, 10))
  p.push()
  flat(p)
  let cx = w / 2
  let cy = 520.0
  // the bone: a rounded plate with a gentle wobble
  p.no_stroke()
  p.fill((226, 208, 170))
  p.begin_shape()
  for i in 0..<64 {
    let a = i.to_double() / 64.0 * @p5.TWO_PI
    let r = 1.0 + 0.06 * p.noise(p.cos(a) + 1, y=p.sin(a) + 1)
    p.vertex(cx + p.cos(a) * 520 * r, cy + p.sin(a) * 230 * r)
  }
  p.end_shape(mode=Close)
  // heat cracks grow from three hollows
  p.stroke((70, 50, 40))
  p.stroke_weight(4)
  p.no_fill()
  let grow = ease(s - 1.5, 3)
  for k in 0..<3 {
    let x0 = cx - 300 + k.to_double() * 300
    let y0 = cy - 40
    p.begin_shape()
    let n = (grow * 30).to_int()
    for i in 0..<=n {
      let t = i.to_double() * 6
      p.vertex(
        x0 +
        t * (if k == 1 { 0.2 } else { 1.0 }) * (if k == 2 { -1.0 } else { 1.0 }),
        y0 +
        t * 0.9 +
        (p.noise(k.to_double() * 10, y=i.to_double() * 0.2) - 0.5) * 50,
      )
    }
    p.end_shape()
  }
  p.pop()
  // early characters appear beside their modern meaning
  let glyphs = [
    ("日", "sun"),
    ("月", "moon"),
    ("山", "mountain"),
    ("水", "water"),
    ("人", "person"),
    ("王", "king"),
  ]
  for i, g in glyphs {
    let a = smooth((s - 0.8 - i.to_double() * 0.45) / 0.8)
    let x = cx - 375 + i.to_double() * 150
    ui.text_align(HCenter, vertical=Baseline)
    ui.text_font(cjk)
    ui.text_size(78)
    ui.fill((90, 40, 30, 255.0 * a))
    ui.text(g.0, x, cy + 10 - (1.0 - a) * 20)
    ui.text_font(sans)
    ui.text_size(22)
    ui.fill(rgba(cream, 230 * a))
    ui.text(g.1, x, cy + 330)
  }
  ignore(d)
}

// ---- c. 500 BC: a lotus for the teachers ----

///|
fn lotus(p : @p5.P5, ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (14, 26, 40), (24, 56, 70))
  p.camera(eye=(0, -240, 470), center=(0, -60, 0), up=(0, 1, 0))
  p.perspective(fovy=0.8)
  p.ambient_light(50)
  p.point_light((255, 220, 230), 0, -400, 300)
  p.directional_light((120, 140, 200), 0.3, 0.6, -0.8)
  p.no_stroke()
  p.rotate_y(s * 0.25)
  // water
  p.push()
  p.rotate_x(@p5.HALF_PI)
  p.fill((30, 70, 90))
  p.specular_material(120)
  p.shininess(40)
  p.circle(0, 0, 1100)
  p.pop()
  // leaves
  p.fill((50, 120, 80))
  for i in 0..<5 {
    let a = i.to_double() * 1.3
    p.push()
    p.translate(p.cos(a) * 240, -2, z=p.sin(a) * 240)
    p.rotate_x(@p5.HALF_PI)
    p.ellipse(0, 0, 110, h=90)
    p.pop()
  }
  // petals open in three rings
  let open = smooth(ease(s, d * 0.7))
  for ring in 0..<3 {
    let n = 8 + ring * 4
    let tilt = (0.15 + ring.to_double() * 0.35) * open + 0.1
    for i in 0..<n {
      let a = i.to_double() / n.to_double() * @p5.TWO_PI +
        ring.to_double() * 0.2
      p.push()
      p.rotate_y(a)
      p.rotate_x(tilt)
      p.translate(0, -70, z=0)
      p.fill((250, 190 - ring * 30, 210 - ring * 20))
      p.specular_material(255)
      p.shininess(25)
      p.ellipsoid(rx=22, ry=70, rz=8, detail_x=12, detail_y=10)
      p.pop()
    }
  }
  p.fill((240, 200, 90))
  p.emissive_material((80, 60, 10))
  p.translate(0, -30, z=0)
  p.sphere(r=24, detail_x=16, detail_y=12)
  // their names
  let a = smooth((s - 2) / 1)
  ui.text_align(HCenter, vertical=Baseline)
  ui.text_font(cjk)
  ui.text_size(48)
  ui.fill(rgba(cream, 230 * a))
  ui.text("孔子", 420, 560)
  ui.text("बुद्ध", w - 420, 560)
  ui.text_font(sans)
  ui.text_size(24)
  ui.fill(rgba(dim, 230 * a))
  ui.text("Confucius · 551–479 BC", 420, 600)
  ui.text("the Buddha · 5th century BC", w - 420, 600)
}

// ---- 221 BC: the terracotta army ----

///|
fn soldier(p : @p5.P5, seed : Double) -> Unit {
  let tint = (p.noise(seed) * 30).to_int()
  p.fill((168 + tint, 112 + tint / 2, 82))
  p.push()
  p.translate(0, -8, z=0)
  p.box(w=34, h=16, d=34)
  p.pop()
  p.push()
  p.translate(0, -50, z=0)
  p.cylinder(r=17, h=70, detail_x=12)
  p.pop()
  p.push()
  p.translate(0, -94, z=0)
  p.box(w=48, h=22, d=22)
  p.pop()
  p.push()
  p.translate(0, -118, z=0)
  p.sphere(r=13, detail_x=10, detail_y=8)
  p.translate(0, -12, z=0)
  p.sphere(r=6, detail_x=8, detail_y=6)
  p.pop()
}

///|
fn terracotta(p : @p5.P5, _ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (40, 30, 24), (90, 64, 44))
  let z = 700.0 - s / d * 500
  p.camera(eye=(-180, -260, z), center=(60, -60, z - 700), up=(0, 1, 0))
  p.perspective(fovy=0.9, near=10, far=6000)
  p.ambient_light((90, 70, 60))
  p.directional_light((255, 220, 180), 0.6, 0.7, -0.4)
  p.no_stroke()
  // the pit floor and its earthen walls between columns
  p.push()
  p.rotate_x(@p5.HALF_PI)
  p.fill((120, 84, 58))
  p.plane(w=3000, h=4000)
  p.pop()
  for col in -1..<=2 {
    p.push()
    p.translate(col.to_double() * 260 - 130, -40, z=-1200)
    p.fill((140, 98, 66))
    p.box(w=40, h=80, d=2800)
    p.pop()
  }
  for row in 0..<16 {
    for col in 0..<6 {
      p.push()
      p.translate(
        col.to_double() * 80 - 200 + (if row % 2 == 0 { 0.0 } else { 10.0 }),
        0,
        z=-row.to_double() * 110,
      )
      soldier(p, (row * 6 + col).to_double() * 0.71)
      p.pop()
    }
  }
}

// ---- c. 130 BC: the Silk Road ----

///|
let cities : Array[(String, Double, Double)] = [
  ("Chang'an", 1610, 470),
  ("Dunhuang", 1380, 400),
  ("Kashgar", 1120, 380),
  ("Samarkand", 950, 390),
  ("Merv", 820, 440),
  ("Ctesiphon", 610, 500),
  ("Antioch", 470, 470),
  ("Rome", 230, 380),
]

///|
fn silk_road(p : @p5.P5, ui : @p5.P5, s : Double, d : Double) -> Unit {
  backdrop(p, (60, 46, 32), (34, 26, 20))
  p.push()
  flat(p)
  p.no_stroke()
  // a parchment map with soft land masses
  p.fill((214, 190, 146))
  p.rect(120, 260, 1680, 520, tl=24)
  p.fill((196, 168, 120))
  for i in 0..<13 {
    let x = 260.0 + i.to_double() * 115
    p.ellipse(
      x,
      560 + p.sin(i.to_double()) * 50,
      200,
      h=90 + p.noise(i.to_double()) * 60,
    )
  }
  // the route drawn from east to west
  let progress = smooth(ease(s - 0.5, d * 0.55))
  let n = cities.length()
  p.no_fill()
  p.stroke((150, 40, 30))
  p.stroke_weight(5)
  p.begin_shape()
  let seg = progress * (n - 1).to_double()
  for i in 0..<n {
    let (_, x, y) = cities[i]
    if i.to_double() <= seg {
      p.vertex(x, y)
    } else if i.to_double() - 1 < seg {
      let (_, px, py) = cities[i - 1]
      let f = seg - (i - 1).to_double()
      p.vertex(px + (x - px) * f, py + (y - py) * f)
    }
  }
  p.end_shape()
  // caravans travelling back and forth along the finished route
  p.no_stroke()
  p.begin_shape(kind=Points)
  p.stroke(rgba(vermilion, 255))
  p.stroke_weight(12)
  for c in 0..<10 {
    let u = (c.to_double() * 0.1 + s * 0.05) % 1.0
    let u = if c % 2 == 0 { u } else { 1.0 - u }
    let f = u * (n - 1).to_double()
    if f <= seg {
      let i = f.floor().to_int().min(n - 2)
      let t = f - i.to_double()
      let (_, ax, ay) = cities[i]
      let (_, bx, by) = cities[i + 1]
      p.vertex(ax + (bx - ax) * t, ay + (by - ay) * t)
    }
  }
  p.end_shape()
  // glowing cities
  p.no_stroke()
  p.emissive_material((120, 60, 20))
  for i, c in cities {
    if i.to_double() <= seg + 0.01 {
      p.fill(rgba(gold, 255))
      p.push()
      p.translate(c.1, c.2, z=4)
      p.sphere(r=11, detail_x=10, detail_y=8)
      p.pop()
    }
  }
  p.pop()
  for i, c in cities {
    let a = smooth((seg - i.to_double() + 0.5) * 2)
    ui.text_align(HCenter, vertical=Bottom)
    ui.text_font(serif)
    ui.text_size(26)
    ui.fill((60, 30, 20, 255.0 * a))
    ui.text(c.0, c.1, c.2 - 18)
  }
  let a = smooth((s - 4) / 1)
  ui.text_font(sans)
  ui.text_size(22)
  ui.text_align(Left, vertical=Top)
  ui.fill((70, 45, 30, 255.0 * a))
  ui.text(
    "east → west: silk, porcelain, paper · west → east: horses, glass, silver · and Buddhism",
    160, 730,
  )
}
