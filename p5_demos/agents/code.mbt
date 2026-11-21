// Source code on screen: a tiny tokenizer, era-specific palettes and a
// typewriter that draws a program one character at a time.

///|
#derive(Eq, Debug)
enum Tok {
  Plain
  Keyword
  Str
  Num
  Comment
  TypeName
  Punct
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn starts_at(cs : Array[Char], i : Int32, pat : String) -> Bool {
  let ps = pat.to_array()
  if ps.length() == 0 || i + ps.length() > cs.length() {
    return false
  }
  for j, c in ps {
    if cs[i + j] != c {
      return false
    }
  }
  true
}

///|
/// Splits one line into highlighted tokens.
fn tokenize(
  line : String,
  keywords : Array[String],
  comment : String,
  quotes : String,
) -> Array[(String, Tok)] {
  let cs = line.to_array()
  let qs = quotes.to_array()
  let n = cs.length()
  let out : Array[(String, Tok)] = []
  let mut i = 0
  while i < n {
    let c = cs[i]
    if starts_at(cs, i, comment) {
      out.push((String::from_array(cs[i:]), Comment))
      break
    }
    let start = i
    if qs.contains(c) {
      i += 1
      while i < n && cs[i] != c {
        i += 1
      }
      i = (i + 1).min(n)
      out.push((String::from_array(cs[start:i]), Str))
    } else if is_digit(c) {
      while i < n && (is_digit(cs[i]) || cs[i] == '.') {
        i += 1
      }
      out.push((String::from_array(cs[start:i]), Num))
    } else if is_alpha(c) {
      while i < n && (is_alpha(cs[i]) || is_digit(cs[i])) {
        i += 1
      }
      let word = String::from_array(cs[start:i])
      let kind = if keywords.contains(word) {
        Keyword
      } else if c >= 'A' && c <= 'Z' {
        TypeName
      } else {
        Plain
      }
      out.push((word, kind))
    } else if c == ' ' {
      while i < n && cs[i] == ' ' {
        i += 1
      }
      out.push((String::from_array(cs[start:i]), Plain))
    } else {
      i += 1
      out.push((String::from_array(cs[start:i]), Punct))
    }
  }
  out
}

///|
fn char_count(lines : Array[String]) -> Int32 {
  lines.fold(init=0, (acc, l) => acc + l.to_array().length() + 1)
}

///|
/// Draws `lines` with at most `shown` characters visible and returns where
/// the cursor ended up.
fn draw_code(
  p : @p5.P5,
  lines : Array[String],
  shown : Int32,
  x : Double,
  y : Double,
  size : Double,
  leading : Double,
  font : String,
  colorize : (String) -> Array[(String, Tok)],
  palette : (Tok) -> (Int32, Int32, Int32),
) -> (Double, Double) {
  p.text_font(font)
  p.text_size(size)
  p.text_align(Left, vertical=Baseline)
  p.no_stroke()
  let mut remaining = shown
  let mut cx = x
  let mut cy = y
  for li, line in lines {
    if remaining <= 0 {
      break
    }
    cy = y + li.to_double() * leading
    cx = x
    let mut left = remaining
    for tok in colorize(line) {
      if left <= 0 {
        break
      }
      let (text, kind) = tok
      let chars = text.to_array()
      let part = if chars.length() <= left {
        text
      } else {
        String::from_array(chars[:left])
      }
      p.fill(palette(kind))
      if part.trim() != "" {
        p.text(part, cx, cy)
      }
      cx += p.font_width(part)
      left -= chars.length()
    }
    remaining -= line.to_array().length() + 1
    if remaining > 0 && li + 1 < lines.length() {
      // the cursor sits at the start of the next line
      cx = x
      cy = y + (li + 1).to_double() * leading
    }
  }
  (cx, cy)
}

///|
/// Advance width of `s` in the current font. `text_width` measures only the
/// inked part, which leaves out spaces, so text laid out piece by piece
/// uses `font_width`.
fn mono_width(p : @p5.P5, s : String) -> Double {
  p.font_width(s)
}

///|
fn cursor(
  p : @p5.P5,
  pos : (Double, Double),
  size : Double,
  c : (Int32, Int32, Int32),
  s : Double,
) -> Unit {
  if @cmath.sin(s * 9.0) > -0.2 {
    p.no_stroke()
    p.fill(rgba(c, 220))
    p.rect(pos.0 + 2, pos.1 - size * 0.85, size * 0.58, size * 1.05)
  }
}

///|
/// Editor colors for each kind of token, per era.
fn tok_color(era : Era, tok : Tok) -> (Int32, Int32, Int32) {
  match (era, tok) {
    (Paper, _) => (62, 40, 24)
    (Card, _) => (40, 36, 60)
    (Crt, _) => (80, 255, 130)
    (Classic, Keyword) => (255, 255, 255)
    (Classic, Str | Num) => (0, 255, 255)
    (Classic, Comment) => (170, 170, 170)
    (Classic, _) => (255, 255, 85)
    (Window, Keyword) => (0, 0, 160)
    (Window, Str) => (163, 21, 21)
    (Window, Num) => (9, 134, 88)
    (Window, Comment) => (0, 128, 0)
    (Window, TypeName) => (38, 127, 153)
    (Window, _) => (20, 20, 20)
    (Modern | Moon, Keyword) => (198, 120, 221)
    (Modern | Moon, Str) => (152, 195, 121)
    (Modern | Moon, Num) => (209, 154, 102)
    (Modern | Moon, Comment) => (110, 118, 138)
    (Modern | Moon, TypeName) => (229, 192, 123)
    (Modern | Moon, Punct) => (171, 178, 191)
    (Modern | Moon, Plain) => (224, 228, 236)
  }
}

///|
fn palette(era : Era) -> (Tok) -> (Int32, Int32, Int32) {
  tok => tok_color(era, tok)
}
