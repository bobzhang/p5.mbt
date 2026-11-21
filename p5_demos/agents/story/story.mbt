// The film's timeline: when each language arrives and how, and the caption
// for each moment. The film is silent; the captions tell the story.

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
/// One caption and when it is on screen.
pub(all) struct Line {
  start : Double
  end : Double
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
/// Captions with a special role.
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
    { start: 1.0, end: 7.4, zh: "每个时代，都有自己的语言。", },
    {
      start: 9.6,
      end: 16.2,
      zh: "FORTRAN：编译出的代码，也能很快。",
    },
    {
      start: 17.4,
      end: 24.0,
      zh: "LISP：函数即是值，最初的 AI 梦想。",
    },
    { start: 25.6, end: 32.2, zh: "C：贴近机器，造就了 Unix。", },
    { start: 33.8, end: 40.2, zh: "ML：类型，可以自己推导。", },
    { start: 41.8, end: 48.2, zh: "Rust：安全，成为默认。", },
    {
      start: 49.6,
      end: 55.8,
      zh: "WebAssembly：代码，处处安全运行。",
    },
    {
      start: 56.8,
      end: 62.8,
      zh: "退后一步：六十年的思想，汇向同一处。",
    },
    {
      start: 63.6,
      end: 69.2,
      zh: "如今，AI 也在写代码。它需要可信的语言。",
    },
    {
      start: 70.6,
      end: 79.0,
      zh: "MoonBit：为 AI 而生。安全，可验证，快。",
    },
    {
      start: 79.6,
      end: 84.8,
      zh: "Unix 有 C，GPU 有 CUDA，智能体时代有 MoonBit。",
    },
    { start: 86.0, end: 90.0, zh: "这部影片，用 MoonBit 制作。", },
  ]
}

///|
/// When a reader reaches `phrase` in caption `i`, assuming an even pace.
pub fn phrase_time(i : Int32, phrase : String) -> Double {
  let l = lines()[i]
  let text = l.zh.to_array()
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
