// "Five Thousand Years of Asia": a short film drawn with p5.mbt in WEBGL.
// 3D scenes are lit and textured; titles, captions, the timeline and the
// CJK characters are drawn on a 2D overlay (create_graphics) with the
// system fonts and composited on top.
//
// Preview live:        examples/asia/
// Jump to a time:      examples/asia/?t=42.5&still
// Record to MP4:       python3 tools/record.py --out asia.mp4
//                      then open http://localhost:8766/examples/asia/?record

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
/// Fonts for Chinese and Japanese characters (system fonts).
let cjk : String = "\"Songti SC\", \"STSong\", \"Hiragino Mincho ProN\", \"Noto Serif CJK SC\", serif"

///|
let bg : (Int32, Int32, Int32) = (12, 12, 20)

///|
let cream : (Int32, Int32, Int32) = (242, 234, 214)

///|
let vermilion : (Int32, Int32, Int32) = (227, 66, 52)

///|
let gold : (Int32, Int32, Int32) = (232, 184, 92)

///|
let dim : (Int32, Int32, Int32) = (140, 140, 160)

///|
fn rgba(c : (Int32, Int32, Int32), a : Double) -> (Int32, Int32, Int32, Double) {
  (c.0, c.1, c.2, a)
}

///|
/// One chapter. `draw(p, ui, s, seconds)` draws the 3D scene on `p` and
/// any flat text on the overlay `ui`, `s` seconds into the chapter.
struct Scene {
  year : String
  title : String
  caption : String
  features : String
  seconds : Double
  draw : (@p5.P5, @p5.P5, Double, Double) -> Unit
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
/// The first `progress` (0-1) of a string, for typewriter captions.
fn typed(s : String, progress : Double) -> String {
  let chars = s.to_array()
  let n = (clamp01(progress) * chars.length().to_double()).floor().to_int()
  String::from_array(chars[:n])
}

///|
/// Puts the origin at the top-left of the canvas with the default camera,
/// so (x, y) at z = 0 are canvas pixels.
fn flat(p : @p5.P5) -> Unit {
  p.camera()
  p.perspective()
  p.translate(-w / 2, -h / 2)
}

///|
fn header(ui : @p5.P5, sc : Scene, s : Double) -> Unit {
  ui.no_stroke()
  // a soft dark band behind the title, fading downwards
  for i in 0..<24 {
    ui.fill(rgba(bg, 150.0 * smooth(s / 0.6) * (1.0 - i.to_double() / 24.0)))
    ui.rect(0, i.to_double() * 12, w, 12)
  }
  ui.text_align(Left, vertical=Baseline)
  ui.text_font(serif)
  ui.text_size(92)
  ui.fill(rgba(gold, 255 * smooth(s / 0.8)))
  ui.text(sc.year, 110, 165)
  ui.text_font(sans)
  ui.text_size(44)
  ui.fill(rgba(cream, 255 * smooth((s - 0.3) / 0.8)))
  ui.text(sc.title, 112, 226)
  ui.text_font(mono)
  ui.text_size(20)
  ui.text_align(Right)
  ui.fill(rgba(dim, 230 * smooth((s - 0.8) / 0.8)))
  ui.text("p5.mbt · " + sc.features, w - 110, 165)
  // a dark band behind the caption keeps it legible over bright scenes
  ui.fill(rgba(bg, 150 * smooth((s - 0.6) / 0.6)))
  ui.rect(0, 820, w, 160)
  ui.text_align(Left, vertical=Top)
  ui.text_font(sans)
  ui.text_size(33)
  ui.text_leading(45)
  ui.fill(rgba(cream, 240))
  ui.text(
    typed(sc.caption, (s - 0.9) / 3.2),
    112,
    846,
    max_width=1696,
    max_height=100,
  )
}

///|
fn timeline(
  ui : @p5.P5,
  all : Array[Scene],
  index : Int32,
  progress : Double,
) -> Unit {
  let x0 = 160.0
  let x1 = w - 160.0
  let y = 1012.0
  let n = all.length() - 2
  let pos = (i : Int32) => {
    x0 + (x1 - x0) * (i - 1).to_double() / (n - 1).to_double()
  }
  ui.stroke(rgba(dim, 90))
  ui.stroke_weight(2)
  ui.line(x0, y, x1, y)
  let current = if index > n {
    x1
  } else {
    pos(index) +
    (if index < n { (pos(index + 1) - pos(index)) * progress } else { 0 })
  }
  ui.stroke(rgba(vermilion, 220))
  ui.line(x0, y, current.max(x0), y)
  ui.text_font(mono)
  ui.text_size(15)
  ui.text_align(HCenter, vertical=Top)
  for i in 1..<=n {
    ui.no_stroke()
    ui.fill(if i <= index { rgba(vermilion, 255) } else { rgba(dim, 160) })
    ui.circle(pos(i), y, if i == index { 14 } else { 8 })
    ui.fill(if i == index { rgba(cream, 255) } else { rgba(dim, 200) })
    ui.text(all[i].year, pos(i), y + 16)
  }
}

///|
fn total_seconds(all : Array[Scene]) -> Double {
  all.fold(init=0.0, (acc, sc) => acc + sc.seconds)
}

///|
/// Draws the film at time `t` (seconds).
fn film(p : @p5.P5, ui : @p5.P5, all : Array[Scene], t : Double) -> Unit {
  p.background(bg)
  ui.clear()
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
  ui.push()
  (sc.draw)(p, ui, s, sc.seconds)
  ui.pop()
  p.pop()
  if sc.year != "" {
    header(ui, sc, s)
  }
  // fade between chapters
  let fade = smooth(s / 0.6).min(smooth((sc.seconds - s) / 0.6))
  if fade < 1 {
    ui.no_stroke()
    ui.fill(rgba(bg, 255 * (1.0 - fade)))
    ui.rect(0, 0, w, h)
  }
  if index > 0 && index < all.length() - 1 {
    timeline(ui, all, index, s / sc.seconds)
  }
  // composite the overlay over the 3D scene
  p.push()
  p.reset_matrix()
  p.camera()
  p.perspective()
  p.clear_depth()
  p.no_stroke()
  p.image(ui, -w / 2, -h / 2, w~, h~)
  p.pop()
}

///|
fn main {
  let offset = match @p5.query_param("t") {
    Some(v) => @string.parse_double(v) catch { _ => 0 }
    None => 0
  }
  let font : Ref[@p5.Font?] = Ref(None)
  let ui_ref : Ref[@p5.P5?] = Ref(None)
  let all_ref : Ref[Array[Scene]] = Ref([])
  @p5.run(
    container="film",
    seed=2026,
    preload=p => {
      font.val = Some(p.load_font("../assets/SourceSansPro-Regular.otf"))
    },
    setup=p => {
      p.pixel_density(1)
      p.create_canvas(w, h, renderer=WebGL)
      let ui = p.create_graphics(w, h)
      ui.pixel_density(1)
      ui_ref.val = Some(ui)
      all_ref.val = scenes(font.val)
      @p5.set_title("Five Thousand Years of Asia — p5.mbt")
      if @p5.query_param("record") is Some(_) {
        p.record(frames=(total_seconds(all_ref.val) * FPS).to_int())
      }
      if @p5.query_param("still") is Some(_) {
        p.no_loop()
      }
    },
    draw=p => {
      guard ui_ref.val is Some(ui) else { return }
      let t = offset + (p.frame_count - 1).to_double() / FPS
      film(p, ui, all_ref.val, t)
    },
  )
}
