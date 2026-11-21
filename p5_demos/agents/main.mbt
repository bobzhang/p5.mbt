// "Made in MoonBit" (From Punched Cards to AI Agents): ninety seconds of
// programming-language history, drawn frame by frame by this MoonBit program.
//
// Preview live:        p5_demos/agents/
// Jump to a time:      p5_demos/agents/?t=60&still
// Record to MP4:       python3 p5_demos/agents/tools/audio.py
//                      node p5_demos/agents/tools/render.cjs

///|
const FPS : Double = 30

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
let bg : (Int32, Int32, Int32) = (7, 9, 20)

///|
let cream : (Int32, Int32, Int32) = (240, 234, 218)

///|
let amber : (Int32, Int32, Int32) = (255, 178, 72)

///|
let dim : (Int32, Int32, Int32) = (128, 134, 166)

///|
let moon_purple : (Int32, Int32, Int32) = (171, 140, 255)

///|
let langs : Array[Lang] = languages().filter(l => picked.contains(l.name))

///|
let all_shots : Array[@story.Shot] = @story.shots()

///|
let all_lines : Array[@story.Line] = @story.lines()

///|
/// Skip fine detail (paper grain, card digits, scanlines) when the camera is
/// far away.
let detail : Ref[Bool] = { val: true, }

///|
/// How far out the camera is: 0 close up, 1 looking at the whole map.
let far_out : Ref[Double] = { val: 0, }

///|
fn rgba(c : (Int32, Int32, Int32), a : Double) -> (Int32, Int32, Int32, Double) {
  (c.0, c.1, c.2, a.max(0).min(255))
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
fn ease_in_out(x : Double) -> Double {
  let t = clamp01(x)
  if t < 0.5 {
    4.0 * t * t * t
  } else {
    1 - @cmath.pow(-2 * t + 2, 3) / 2
  }
}

///|
fn lerp(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
/// Deterministic pseudo-random number in [0, 1) for an integer key, so any
/// frame can be rendered on its own.
fn hash01(i : Int32) -> Double {
  let mut x = i * 747796405 + 289133645
  x = (x ^ (x >> 15)) * 277803737
  x = x ^ (x >> 13)
  (x & 0xffffff).to_double() / 16777216.0
}

///|
/// The first `progress` (0-1) of a string, for typewriter effects.
fn typed(s : String, progress : Double) -> String {
  let chars = s.to_array()
  let n = (clamp01(progress) * chars.length().to_double()).floor().to_int()
  String::from_array(chars[:n])
}

///|
fn full_rect(p : @p5.P5, c : (Int32, Int32, Int32, Double)) -> Unit {
  p.no_stroke()
  p.fill(c)
  p.rect(0, 0, w, h)
}

///|
/// Draws the film at time `t` (seconds).
fn film(p : @p5.P5, t : Double) -> Unit {
  full_rect(p, rgba(bg, 255))
  opening(p, t)
  if t >= all_shots[0].start && t < @story.finale_start + 1.0 {
    camera_and_world(p, t)
  }
  ai_titles(p, t)
  tagline_card(p, t)
  if t >= @story.finale_start - 0.2 {
    finale(p, t)
  }
  film_look(p, t)
  year_counter(p, t)
  captions(p, t)
  // in from black; the last frame stays on "Made in MoonBit"
  let fade = smooth(t / 0.6)
  if fade < 1 {
    full_rect(p, rgba((0, 0, 0), 255 * (1 - fade)))
  }
}

///|
fn main {
  let offset = match @p5.query_param("t") {
    Some(v) => @string.parse_double(v) catch { _ => 0 }
    None => 0
  }
  @p5.run(
    container="film",
    seed=1843,
    setup=p => {
      p.create_canvas(w, h)
      p.pixel_density(1)
      @p5.set_title("Made in MoonBit")
      if @p5.query_param("record") is Some(_) {
        p.record(frames=(@story.total * FPS).to_int(), fps=FPS)
      }
      if @p5.query_param("still") is Some(_) {
        p.no_loop()
      }
    },
    draw=p => {
      let t = offset + (p.frame_count - 1).to_double() / FPS
      film(p, t.min(@story.total - 1.0 / FPS))
    },
  )
}
