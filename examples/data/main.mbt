///|
struct Planet {
  name : String
  radius : Double
  color : String
}

///|
/// Loading JSON and text files in `preload`.
fn main {
  let title = Ref("")
  let planets : Array[Planet] = []
  let poem : Ref[Array[String]] = Ref([])
  let moons : Ref[@p5.Table?] = Ref(None)
  let discoveries : Ref[@p5.Xml?] = Ref(None)
  @p5.run(
    preload=p => {
      p.load_json("../assets/planets.json", json => {
        guard json is { "title": String(t), "planets": Array(items), .. } else {
          return
        }
        title.val = t
        for item in items {
          if item
            is {
              "name": String(name),
              "radius": Number(radius, ..),
              "color": String(color),
              ..
            } {
            planets.push({ name, radius, color, })
          }
        }
      })
      poem.val = p.load_strings("../assets/haiku.txt")
      p.load_table("../assets/moons.csv", header=true, t => moons.val = Some(t))
      p.load_xml("../assets/discoverers.xml", x => discoveries.val = Some(x))
    },
    setup=p => {
      p.create_canvas(640, 460)
      @p5.set_title("p5.mbt — data")
      p.no_loop()
    },
    draw=p => {
      p.background(18)
      p.fill(240)
      p.no_stroke()
      p.text_size(18)
      p.text(title.val, 20, 34)
      let max_r = @p5.max_of(planets.map(pl => pl.radius))
      let mut x = 30.0
      for pl in planets {
        let d = @p5.map(pl.radius.sqrt(), 0, max_r.sqrt(), 4, 110)
        p.fill(pl.color)
        p.circle(x + d / 2, 140, d)
        p.fill(220)
        p.text_size(11)
        p.text_align(HCenter)
        p.text(pl.name, x + d / 2, 215)
        p.text(@p5.nfc(pl.radius), x + d / 2, 230)
        p.text_align(Left)
        x += d + 14
      }
      p.fill(200)
      p.text_size(15)
      p.text_style(Italic)
      for i, line in poem.val {
        p.text(line, 30, 280 + i.to_double() * 22)
      }
      p.text_style(Normal)
      p.text_size(13)
      if moons.val is Some(t) {
        let counts = t.get_column(Title("moons")).map(@p5.parse_float)
        let total = counts.fold(init=0.0, (a, b) => a + b)
        p.fill(amber_color())
        p.text(
          "moons.csv: \{t.get_row_count()} rows, \{total} moons in all; most: \{t.find_row("146", Title("moons")).map(r => r.get(Title("planet"))).unwrap_or("?")}",
          30,
          370,
        )
      }
      if discoveries.val is Some(x) {
        for i, planet in x.get_children(name="planet") {
          p.fill(200)
          p.text(
            "\{planet.get_string("name").unwrap_or("")} (\{planet.get_num("year")}): \{planet.get_content().unwrap_or("")}",
            30,
            400 + i.to_double() * 20,
          )
        }
      }
    },
  )
}

///|
fn amber_color() -> (Int32, Int32, Int32) {
  (255, 176, 70)
}
