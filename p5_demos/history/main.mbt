// "A Short History of Computation": a short film drawn with p5.mbt.
//
// Preview live:        examples/history/
// Jump to a time:      examples/history/?t=42.5&still
// Record to MP4:       python3 tools/record.py --out history.mp4
//                      then open http://localhost:8766/examples/history/?record

///|
const FPS : Double = 60

///|
let w : Double = 1920

///|
let h : Double = 1080

///|
let serif : String = "\"Iowan Old Style\", \"Palatino\", Georgia, serif"

///|
let sans : String = "\"Avenir Next\", \"Helvetica Neue\", Helvetica, sans-serif"

///|
let mono : String = "Menlo, Monaco, monospace"

///|
let bg : (Int32, Int32, Int32) = (11, 13, 26)

///|
let cream : (Int32, Int32, Int32) = (238, 232, 216)

///|
let amber : (Int32, Int32, Int32) = (255, 176, 70)

///|
let cyan : (Int32, Int32, Int32) = (90, 205, 235)

///|
let dim : (Int32, Int32, Int32) = (130, 136, 165)

///|
fn rgba(c : (Int32, Int32, Int32), a : Double) -> (Int32, Int32, Int32, Double) {
  (c.0, c.1, c.2, a)
}

///|
/// One chapter of the film.
struct Scene {
  year : String
  title : String
  caption : String
  features : String
  seconds : Double
  draw : (@p5.P5, Double, Double) -> Unit
}

///|
fn scenes() -> Array[Scene] {
  [
    { year: "", title: "", caption: "", features: "", seconds: 6, draw: intro, },
    {
      year: "c. 100 BC",
      title: "The Antikythera mechanism",
      caption: "Found in a shipwreck in 1901, this Greek gear train predicted the positions of the Sun and Moon and the timing of eclipses.",
      features: "begin_shape · vertex · rotate · push/pop",
      seconds: 7,
      draw: antikythera,
    },
    {
      year: "1642",
      title: "Pascal's calculator",
      caption: "Blaise Pascal builds a machine that adds with gears. When a wheel passes 9, it carries one to its neighbour.",
      features: "clip · text · translate",
      seconds: 7,
      draw: pascaline,
    },
    {
      year: "1804",
      title: "The Jacquard loom",
      caption: "Joseph Marie Jacquard's loom weaves patterns read from chains of punched cards: a program stored as holes.",
      features: "rect · circle · color",
      seconds: 7,
      draw: jacquard,
    },
    {
      year: "1843",
      title: "Ada Lovelace's Note G",
      caption: "For Charles Babbage's Analytical Engine, Ada Lovelace writes out a method to compute Bernoulli numbers, often called the first published program.",
      features: "text · text_font · exact rationals in MoonBit",
      seconds: 8,
      draw: lovelace,
    },
    {
      year: "1854",
      title: "George Boole's laws of thought",
      caption: "George Boole shows that logic can be calculated: true and false become 1 and 0, and reasoning becomes algebra.",
      features: "clip · clip(invert=true) · ellipse",
      seconds: 7,
      draw: boole,
    },
    {
      year: "1936",
      title: "Alan Turing's machine",
      caption: "Alan Turing imagines a machine with a tape and a table of rules, and shows that one universal machine can imitate any other.",
      features: "lerp · triangle · rect(tl=…)",
      seconds: 8,
      draw: turing,
    },
    {
      year: "1945",
      title: "ENIAC",
      caption: "Nearly 18,000 vacuum tubes, programmed by rewiring its panels — work done by Kay McNulty, Betty Jennings, Betty Snyder, Marlyn Wescoff, Fran Bilas and Ruth Lichterman.",
      features: "noise · bezier · blend_mode(Add)",
      seconds: 8,
      draw: eniac,
    },
    {
      year: "1947",
      title: "The transistor",
      caption: "At Bell Labs, John Bardeen, Walter Brattain and William Shockley demonstrate the transistor: a switch with no moving parts.",
      features: "begin_shape · stroke_weight · lerp",
      seconds: 7,
      draw: transistor,
    },
    {
      year: "1958",
      title: "The integrated circuit, and Moore's law",
      caption: "Jack Kilby and Robert Noyce put whole circuits on one chip. In 1965 Gordon Moore predicts the number of components will keep doubling, and for decades it does.",
      features: "line · map · nfc · text_align",
      seconds: 8,
      draw: moore,
    },
    {
      year: "1969",
      title: "ARPANET",
      caption: "29 October 1969: UCLA sends the first message to SRI. It was meant to say LOGIN; the system crashed after LO.",
      features: "Vector · lerp · text_font(mono)",
      seconds: 8,
      draw: arpanet,
    },
    {
      year: "1989",
      title: "The World Wide Web",
      caption: "At CERN, Tim Berners-Lee proposes linking documents with hypertext. By 1991 the first website is online at info.cern.ch.",
      features: "Vector · Random · a force-directed graph",
      seconds: 7,
      draw: web,
    },
    {
      year: "2001",
      title: "Code as a sketchbook",
      caption: "Casey Reas and Ben Fry create Processing for artists and designers. In 2013 Lauren Lee McCarthy starts p5.js, bringing it to the web.",
      features: "noise · color_mode(HSB) · Vector",
      seconds: 7,
      draw: sketchbook,
    },
    {
      year: "Today",
      title: "",
      caption: "",
      features: "",
      seconds: 9,
      draw: outro,
    },
  ]
}

///|
fn clamp01(x : Double) -> Double {
  x.max(0).min(1)
}

///|
fn smooth(x : Double) -> Double {
  let t = clamp01(x)
  t * t * (3.0 - 2.0 * t)
}

///|
/// The first `progress` (0-1) of a string, for typewriter effects.
fn typed(s : String, progress : Double) -> String {
  let chars = s.to_array()
  let n = (clamp01(progress) * chars.length().to_double()).floor().to_int()
  String::from_array(chars[:n])
}

///|
fn header(p : @p5.P5, sc : Scene, s : Double) -> Unit {
  p.no_stroke()
  p.text_align(Left, vertical=Baseline)
  p.text_style(Normal)
  p.text_font(serif)
  p.text_size(96)
  p.fill(rgba(amber, 255 * smooth(s / 0.8)))
  p.text(sc.year, 110, 170)
  p.text_font(sans)
  p.text_size(44)
  p.fill(rgba(cream, 255 * smooth((s - 0.3) / 0.8)))
  p.text(sc.title, 112, 232)
  // the p5.mbt functions this chapter uses
  p.text_font(mono)
  p.text_size(20)
  p.text_align(Right)
  p.fill(rgba(dim, 230 * smooth((s - 0.8) / 0.8)))
  p.text("p5.mbt · " + sc.features, w - 110, 170)
  // caption
  p.text_align(Left, vertical=Top)
  p.text_font(sans)
  p.text_size(34)
  p.text_leading(46)
  p.fill(rgba(cream, 235))
  p.text(
    typed(sc.caption, (s - 0.9) / 3.2),
    112,
    850,
    max_width=1696,
    max_height=100,
  )
}

///|
fn timeline(
  p : @p5.P5,
  all : Array[Scene],
  index : Int32,
  progress : Double,
) -> Unit {
  let x0 = 160.0
  let x1 = w - 160.0
  let y = 1010.0
  let n = all.length() - 2 // dated chapters
  let pos = (i : Int32) => {
    x0 + (x1 - x0) * (i - 1).to_double() / (n - 1).to_double()
  }
  p.stroke(rgba(dim, 90))
  p.stroke_weight(2)
  p.line(x0, y, x1, y)
  let current = if index == 0 {
    x0 - 30
  } else if index > n {
    x1
  } else {
    pos(index) +
    (if index < n { (pos(index + 1) - pos(index)) * progress } else { 0 })
  }
  p.stroke(rgba(amber, 200))
  p.line(x0, y, current.max(x0), y)
  p.text_font(mono)
  p.text_size(16)
  p.text_align(HCenter, vertical=Top)
  for i in 1..<=n {
    let past = i <= index
    p.no_stroke()
    p.fill(if past { rgba(amber, 255) } else { rgba(dim, 160) })
    p.circle(pos(i), y, if i == index { 14 } else { 8 })
    p.fill(if i == index { rgba(cream, 255) } else { rgba(dim, 200) })
    p.text(all[i].year, pos(i), y + 16)
  }
}

///|
/// Draws the film at time `t` (seconds).
fn film(p : @p5.P5, all : Array[Scene], t : Double) -> Unit {
  p.background(bg)
  let mut start = 0.0
  let mut index = all.length() - 1
  for i, sc in all {
    if t < start + sc.seconds {
      index = i
      break
    }
    start += sc.seconds
  } nobreak {
    start -= all[all.length() - 1].seconds
  }
  let sc = all[index]
  let s = t - start
  p.push()
  (sc.draw)(p, s, sc.seconds)
  p.pop()
  if sc.year != "" && sc.title != "" {
    header(p, sc, s)
  }
  // fade in / out between chapters
  let fade = smooth(s / 0.6).min(smooth((sc.seconds - s) / 0.6))
  if fade < 1 {
    p.no_stroke()
    p.fill(rgba(bg, 255 * (1.0 - fade)))
    p.rect(0, 0, w, h)
  }
  if index > 0 {
    timeline(p, all, index, s / sc.seconds)
  }
}

///|
fn total_seconds(all : Array[Scene]) -> Double {
  all.fold(init=0.0, (acc, sc) => acc + sc.seconds)
}

///|
fn main {
  let all = scenes()
  let offset = match @p5.query_param("t") {
    Some(v) => @string.parse_double(v) catch { _ => 0 }
    None => 0
  }
  @p5.run(
    container="film",
    seed=1936,
    setup=p => {
      p.create_canvas(w, h)
      p.pixel_density(1)
      @p5.set_title("A Short History of Computation — p5.mbt")
      if @p5.query_param("record") is Some(_) {
        p.record(frames=(total_seconds(all) * FPS).to_int())
      }
      if @p5.query_param("still") is Some(_) {
        p.no_loop()
      }
    },
    draw=p => {
      let t = offset + (p.frame_count - 1).to_double() / FPS
      film(p, all, t)
    },
  )
}

///|
impl Show for Frac with fn output(self, logger) {
  logger.write_string(self.to_string())
}
