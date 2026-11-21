// The film's timeline: when each language arrives and how, what the narrator
// says and when. The picture (the agents package) and the sound
// (tools/audio.py, via the cues package) are both driven by this one table.

///|
/// How the camera travels to the next language.
pub(all) enum Style {
  Ignite // out of the dark
  Swoop // fly up over the map and back down
  Flip // the frame flips like a card
  Whip // a fast pan with motion streaks
  Dive // plunge into the screen, burst out of the next
  Spin // a barrel roll on the way
  Swing // a tilting arc
  Glitch // a CRT signal tear
  Iris // a circle opens on the next scene
  Dissolve // the frame breaks into tiles
  Ink // the next scene blooms through like ink in water
  Leak // a warm light leak washes one scene into the next
}

///|
pub fn Style::name(self : Style) -> String {
  match self {
    Ignite => "ignite"
    Swoop => "swoop"
    Flip => "flip"
    Whip => "whip"
    Dive => "dive"
    Spin => "spin"
    Swing => "swing"
    Glitch => "glitch"
    Iris => "iris"
    Dissolve => "dissolve"
    Ink => "ink"
    Leak => "leak"
  }
}

///|
/// The camera arrives at language `node`: the move starts at `start` and
/// takes `trans` seconds.
pub(all) struct Shot {
  node : Int32
  start : Double
  trans : Double
  style : Style
}

///|
pub fn Shot::arrive(self : Shot) -> Double {
  self.start + self.trans
}

///|
/// One narrated line, its Chinese subtitle, and the slot it must fit.
pub(all) struct Line {
  start : Double
  end : Double
  text : String
  zh : String
}

///|
pub let total : Double = 90

///|
/// The opening title cards, before the first language.
pub let title_start : Double = 3.6

///|
/// After WebAssembly: pull back to the whole map.
pub let overview_start : Double = 56.0

///|
pub let overview_end : Double = 58.6

///|
/// AI agents flood the map with code.
pub let ai_start : Double = 63.4

///|
/// The tokens gather where MoonBit is about to appear.
pub let ai_converge : Double = 68.0

///|
/// MoonBit is born, and the camera dives in.
pub let moon_born : Double = 69.4

///|
pub let moon_arrive : Double = 70.6

///|
/// "Unix had C. The GPU had CUDA. The age of agents has MoonBit."
pub let tagline_start : Double = 79.4

///|
/// The code becomes a crescent: "Made in MoonBit."
pub let finale_start : Double = 85.2

///|
pub let moon_node : Int32 = 6

///|
/// Narration lines with a special role.
pub let moon_line : Int32 = 9

///|
pub let tagline_line : Int32 = 10

///|
pub let finale_line : Int32 = 11

///|
pub fn shots() -> Array[Shot] {
  [
    { node: 0, start: 8.0, trans: 1.6, style: Ignite, },
    { node: 1, start: 16.6, trans: 1.2, style: Ink, },
    { node: 2, start: 24.4, trans: 1.0, style: Dive, },
    { node: 3, start: 32.4, trans: 1.4, style: Swoop, },
    { node: 4, start: 40.4, trans: 1.3, style: Leak, },
    { node: 5, start: 48.4, trans: 1.3, style: Swing, },
  ]
}

///|
pub fn lines() -> Array[Line] {
  [
    {
      start: 1.0,
      end: 3.0,
      text: "Every age has its own language.",
      zh: "每个时代，都有自己的语言。",
    },
    {
      start: 9.4,
      end: 15.4,
      text: "1957. FORTRAN showed that compiled code could be fast. MoonBit keeps that speed.",
      zh: "FORTRAN：编译出的代码，也能很快。",
    },
    {
      start: 16.9,
      end: 22.7,
      text: "1958. LISP gave us closures, garbage collection, and the first dreams of AI.",
      zh: "LISP：闭包、垃圾回收，与最初的 AI 梦想。",
    },
    {
      start: 24.9,
      end: 30.5,
      text: "1972. C brought code close to the machine, and gave us Unix.",
      zh: "C：贴近机器，造就了 Unix。",
    },
    {
      start: 32.9,
      end: 38.8,
      text: "1973. ML taught the compiler to infer types. That idea is MoonBit's heart.",
      zh: "ML：类型自己推导，这是 MoonBit 的核心。",
    },
    {
      start: 40.9,
      end: 45.5,
      text: "2015. Rust made safety the default. So does MoonBit.",
      zh: "Rust：安全，成为默认。MoonBit 亦然。",
    },
    {
      start: 48.9,
      end: 55.0,
      text: "2017. WebAssembly let code run anywhere, safely. MoonBit was born for it.",
      zh: "WebAssembly：处处安全运行。MoonBit 为它而生。",
    },
    {
      start: 56.8,
      end: 61.1,
      text: "Step back. Sixty years of ideas, all pointing to one place.",
      zh: "退后一步：六十年，指向同一处。",
    },
    {
      start: 63.6,
      end: 67.7,
      text: "Now, AI writes code too. It needs a language it can trust.",
      zh: "如今 AI 也写代码，它需要可信的语言。",
    },
    {
      start: 70.6,
      end: 77.1,
      text: "MoonBit. Designed for AI. Safe. Verifiable. Fast to compile, and fast to run.",
      zh: "MoonBit：为 AI 而生。安全，可验证，快。",
    },
    {
      start: 79.6,
      end: 83.7,
      text: "Unix had C. The GPU had CUDA. The age of agents has MoonBit.",
      zh: "Unix 有 C，GPU 有 CUDA，智能体时代有 MoonBit。",
    },
    {
      start: 86.0,
      end: 87.8,
      text: "This film was made in MoonBit.",
      zh: "这部影片，用 MoonBit 制作。",
    },
  ]
}

///|
/// When the narrator reaches `phrase` in line `i`, assuming an even pace.
pub fn phrase_time(i : Int32, phrase : String) -> Double {
  let l = lines()[i]
  let text = l.text.to_array()
  let pat = phrase.to_array()
  let mut at = 0
  for k in 0..<=(text.length() - pat.length()) {
    let mut ok = true
    for j, c in pat {
      if text[k + j] != c {
        ok = false
        break
      }
    }
    if ok {
      at = k
      break
    }
  }
  l.start + (l.end - l.start) * at.to_double() / text.length().to_double()
}

///|
fn json_string(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      _ => buf.write_char(c)
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
/// The timeline as JSON, for tools/audio.py.
pub fn cues_json() -> String {
  let shots = shots()
    .map(s => {
      "{\"node\":\{s.node},\"start\":\{s.start},\"trans\":\{s.trans},\"style\":\"\{s.style.name()}\"}"
    })
    .join(",")
  let lines = lines()
    .map(l => {
      "{\"start\":\{l.start},\"end\":\{l.end},\"text\":\{json_string(l.text)},\"zh\":\{json_string(l.zh)}}"
    })
    .join(",")
  let events = [
      ("overview", overview_start),
      ("ai", ai_start),
      ("converge", ai_converge),
      ("born", moon_born),
      ("moon", moon_arrive),
      ("title", title_start),
      ("tagline", tagline_start),
      ("finale", finale_start),
    ]
    .map(e => "\"\{e.0}\":\{e.1}")
    .join(",")
  "{\"total\":\{total},\"moon_line\":\{moon_line},\"tagline_line\":\{tagline_line},\"finale_line\":\{finale_line},\"shots\":[\{shots}],\"lines\":[\{lines}],\"events\":{\{events}}}"
}
