// The languages, and the machines and screens they were written on.

///|
enum Era {
  Paper // a handwritten table
  Card // punched cards
  Crt // a green phosphor terminal
  Classic // a text-mode IDE
  Window // a desktop GUI window
  Modern // a dark code editor
  Moon // MoonBit's editor
}

///|
struct Lang {
  year : String
  name : String
  who : String
  era : Era
  file : String
  code : Array[String]
  keywords : Array[String]
  comment : String
  quotes : String
}

///|
fn languages() -> Array[Lang] {
  [
    {
      year: "1843",
      name: "Note G",
      who: "Ada Lovelace · Analytical Engine",
      era: Paper,
      file: "",
      code: [
        "1   ×   1V2 × 1V3     →  1V4, 1V5, 1V6", "2   −   1V4 − 1V1     →  2V4",
        "3   +   1V5 + 1V1     →  2V5", "4   ÷   2V5 ÷ 2V4     →  1V11", "5   ÷   1V11 ÷ 1V2    →  2V11",
        "6   −   0V13 − 2V11   →  1V13",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1957",
      name: "FORTRAN",
      who: "John Backus and team · IBM",
      era: Card,
      file: "",
      code: [
        "C     SUM OF SQUARES", "      ISUM = 0", "      DO 10 I = 1, 10", "   10 ISUM = ISUM + I*I",
        "      PRINT 20, ISUM", "   20 FORMAT (I6)", "      END",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1958",
      name: "LISP",
      who: "John McCarthy · MIT",
      era: Card,
      file: "",
      code: [
        "(DEFUN FACTORIAL (N)", "  (COND ((ZEROP N) 1)", "        (T (* N (FACTORIAL (- N 1))))))",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1959",
      name: "COBOL",
      who: "CODASYL · after Grace Hopper's FLOW-MATIC",
      era: Card,
      file: "",
      code: [
        "IDENTIFICATION DIVISION.", "PROGRAM-ID. HELLO.", "PROCEDURE DIVISION.",
        "    DISPLAY 'HELLO, WORLD'.", "    STOP RUN.",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1972",
      name: "C",
      who: "Dennis Ritchie · Bell Labs",
      era: Crt,
      file: "",
      code: [
        "#include <stdio.h>", "", "main()", "{", "    printf(\"hello, world\\n\");",
        "}", "", "$ cc hello.c && ./a.out", "hello, world",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1973",
      name: "ML",
      who: "Robin Milner · University of Edinburgh",
      era: Crt,
      file: "",
      code: [
        "fun map f []      = []", "  | map f (x::xs) = f x :: map f xs", "", "> val map = fn",
        ">   : ('a -> 'b) -> 'a list -> 'b list",
      ],
      keywords: [],
      comment: "",
      quotes: "",
    },
    {
      year: "1985",
      name: "C++",
      who: "Bjarne Stroustrup · Bell Labs",
      era: Classic,
      file: "SHAPE.CPP",
      code: [
        "class Shape {", "public:", "    virtual double area() const = 0;", "};",
        "", "class Circle : public Shape {", "    double r;", "public:", "    double area() const {",
        "        return 3.14159 * r * r;", "    }", "};",
      ],
      keywords: ["class", "public", "virtual", "double", "const", "return"],
      comment: "//",
      quotes: "\"",
    },
    {
      year: "1991",
      name: "Python",
      who: "Guido van Rossum · CWI",
      era: Window,
      file: "fib.py",
      code: [
        "def fib(n):", "    a, b = 0, 1", "    for _ in range(n):", "        a, b = b, a + b",
        "    return a", "", "print(fib(10))   # 55",
      ],
      keywords: ["def", "for", "in", "return", "print", "range"],
      comment: "#",
      quotes: "\"'",
    },
    {
      year: "1995",
      name: "Java",
      who: "James Gosling · Sun Microsystems",
      era: Window,
      file: "Hello.java",
      code: [
        "public class Hello {", "    public static void main(String[] args) {", "        System.out.println(",
        "            \"Write once, run anywhere\");", "    }", "}",
      ],
      keywords: ["public", "class", "static", "void"],
      comment: "//",
      quotes: "\"",
    },
    {
      year: "1995",
      name: "JavaScript",
      who: "Brendan Eich · Netscape",
      era: Window,
      file: "index.html",
      code: [
        "<script>", "button.onclick = function () {", "  alert(\"Hello, Web!\");",
        "};", "</script>",
      ],
      keywords: ["function", "script"],
      comment: "//",
      quotes: "\"'",
    },
    {
      year: "2009",
      name: "Go",
      who: "Griesemer, Pike & Thompson · Google",
      era: Modern,
      file: "main.go",
      code: [
        "func main() {", "    ch := make(chan int)", "    go func() {", "        ch <- compute()",
        "    }()", "    fmt.Println(<-ch)", "}",
      ],
      keywords: ["func", "go", "chan", "make", "int"],
      comment: "//",
      quotes: "\"",
    },
    {
      year: "2012",
      name: "TypeScript",
      who: "Anders Hejlsberg · Microsoft",
      era: Modern,
      file: "greet.ts",
      code: [
        "interface User {", "  name: string;", "  age?: number;", "}", "", "const greet = (u: User): string =>",
        "  `Hello, ${u.name}!`;",
      ],
      keywords: ["interface", "const", "string", "number"],
      comment: "//",
      quotes: "\"`",
    },
    {
      year: "2015",
      name: "Rust",
      who: "Graydon Hoare · Mozilla · 1.0",
      era: Modern,
      file: "main.rs",
      code: [
        "fn longest<'a>(x: &'a str, y: &'a str)", "    -> &'a str", "{", "    if x.len() > y.len() { x } else { y }",
        "}",
      ],
      keywords: ["fn", "if", "else", "str"],
      comment: "//",
      quotes: "\"",
    },
    {
      year: "2017",
      name: "WebAssembly",
      who: "W3C Community Group",
      era: Modern,
      file: "add.wat",
      code: [
        "(module", "  (func (export \"add\")", "    (param $a i32) (param $b i32)",
        "    (result i32)", "    local.get $a", "    local.get $b", "    i32.add))",
      ],
      keywords: ["module", "func", "export", "param", "result", "local", "i32"],
      comment: ";;",
      quotes: "\"",
    },
  ]
}

///|
/// The six languages the film follows.
let picked : Array[String] = [
  "FORTRAN", "LISP", "C", "ML", "Rust", "WebAssembly",
]

///|
fn era_background(era : Era) -> (Int32, Int32, Int32) {
  match era {
    Paper => (26, 19, 14)
    Card => (14, 18, 30)
    Crt => (6, 11, 9)
    Classic => (10, 12, 32)
    Window => (14, 60, 66)
    Modern => (12, 14, 26)
    Moon => (14, 11, 30)
  }
}

///|
fn era_accent(era : Era) -> (Int32, Int32, Int32) {
  match era {
    Crt => (90, 255, 140)
    Window => (255, 214, 120)
    Moon => moon_purple
    _ => amber
  }
}

///|
fn plain_tokens(line : String) -> Array[(String, Tok)] {
  [(line, Plain)]
}

///|
fn paper(p : @p5.P5, l : Lang, shown : Int32, s : Double) -> Unit {
  p.push()
  p.translate(1300, 520)
  p.rotate(-0.012)
  p.no_stroke()
  p.fill((0, 0, 0, 90))
  p.rect(-495, -335, 1010, 690)
  p.fill((234, 222, 192))
  p.rect(-505, -345, 1010, 690)
  // paper grain
  for i in 0..<(if detail.val { 260 } else { 0 }) {
    p.fill((120, 90, 50, 18))
    p.circle(
      -500 + hash01(i) * 1000,
      -340 + hash01(i + 999) * 680,
      2 + hash01(i + 7) * 3,
    )
  }
  p.fill((70, 45, 26))
  p.text_font(serif)
  p.text_style(Italic)
  p.text_size(25)
  p.text_align(HCenter, vertical=Baseline)
  p.text(
    "Diagram for the computation by the Engine of the Numbers of Bernoulli.", 0,
    -280,
  )
  p.text_style(Normal)
  p.text_size(19)
  p.text_align(Left, vertical=Baseline)
  p.fill((100, 70, 45))
  p.text(
    "No.  Op.   Variables acted upon      Variables receiving results", -440, -210,
  )
  p.stroke((120, 85, 55, 160))
  p.stroke_weight(1.5)
  p.line(-460, -190, 460, -190)
  for i in 0..<7 {
    let y = -190.0 + (i + 1).to_double() * 62
    p.line(-460, y, 460, y)
  }
  p.line(-380, -235, -380, 244)
  p.line(-300, -235, -300, 244)
  p.line(60, -235, 60, 244)
  let pos = draw_code(
    p,
    l.code,
    shown,
    -440,
    -145,
    29,
    62,
    serif,
    plain_tokens,
    palette(Paper),
  )
  cursor(p, pos, 26, (62, 40, 24), s)
  p.pop()
}

///|
fn cards(p : @p5.P5, l : Lang, shown : Int32, s : Double) -> Unit {
  let x = 800.0
  let cw = 1010.0
  let ch = 420.0
  let col = (cw - 60) / 80.0
  let mut left = shown
  for k, line in l.code {
    // a blank card waits in the punch before the first key is pressed
    if left <= 0 && k > 0 {
      break
    }
    let chars = line.to_array()
    let n = chars.length().min(left.max(0))
    left -= chars.length() + 1
    let top = 150.0 + k.to_double() * 52
    let is_current = left <= 0 || k == l.code.length() - 1
    // the card, with its corner cut off
    p.no_stroke()
    p.fill((0, 0, 0, 70))
    p.rect(x + 8, top + 8, cw, ch)
    p.fill((236, 224, 188))
    p.begin_shape()
    p.vertex(x + 34, top)
    p.vertex(x + cw, top)
    p.vertex(x + cw, top + ch)
    p.vertex(x, top + ch)
    p.vertex(x, top + 34)
    p.end_shape(mode=Close)
    if is_current && detail.val {
      // the printed digit rows
      p.text_font(mono)
      p.text_size(10)
      p.text_align(HCenter, vertical=VCenter)
      p.fill((190, 90, 80, 150))
      for r in 0..<10 {
        for c in 0..<80 {
          p.text(
            r.to_string(),
            x + 30 + (c.to_double() + 0.5) * col,
            top + 142 + r.to_double() * 26,
          )
        }
      }
    }
    // holes: two punches per character, Hollerith-style
    p.fill(era_background(Card))
    for j in 0..<n {
      let code = chars[j].to_int()
      if chars[j] != ' ' {
        let hx = x + 30 + j.to_double() * col + col * 0.2
        p.rect(hx, top + 82 + (code % 12).to_double() * 26, col * 0.6, 17)
        p.rect(hx, top + 82 + (code / 12 % 12).to_double() * 26, col * 0.6, 17)
      }
    }
    // the line printed along the top edge
    p.fill((40, 36, 60))
    p.text_font(mono)
    p.text_size(21)
    p.text_align(Left, vertical=Baseline)
    let printed = String::from_array(chars[:n])
    p.text(printed, x + 30, top + 34)
    if is_current && left > -2 {
      cursor(
        p,
        (x + 30 + mono_width(p, printed), top + 34),
        21,
        (40, 36, 60),
        s,
      )
    }
  }
}

///|
fn crt(p : @p5.P5, l : Lang, shown : Int32, s : Double) -> Unit {
  // the terminal's case and stand
  p.no_stroke()
  p.fill((40, 39, 36))
  p.quad(1180, 900, 1430, 900, 1470, 930, 1140, 930)
  p.fill((62, 60, 55))
  p.rect(790, 130, 1030, 780, tl=46)
  p.fill((48, 46, 42))
  p.rect(820, 160, 970, 700, tl=34)
  p.fill((7, 24, 13))
  p.rect(845, 185, 920, 650, tl=26)
  // phosphor glow: the program drawn twice, the first pass soft and wide
  p.push()
  p.blend_mode(Add)
  p.translate(1.5, 1.5)
  let glow = (_ : Tok) => (20, 90, 40)
  draw_code(p, l.code, shown, 895, 255, 26, 40, mono, plain_tokens, glow)
  |> ignore
  p.pop()
  let pos = draw_code(
    p,
    l.code,
    shown,
    895,
    255,
    26,
    40,
    mono,
    plain_tokens,
    palette(Crt),
  )
  cursor(p, pos, 26, (80, 255, 130), s)
  // scanlines
  p.no_stroke()
  p.fill((0, 0, 0, 70))
  let mut y = if detail.val { 187.0 } else { 900.0 }
  while y < 833 {
    p.rect(847, y, 916, 1.6)
    y += 4
  }
  p.fill((90, 255, 140, 10))
  p.rect(845, 185, 920, 650, tl=26)
  p.fill((150, 150, 140))
  p.text_font(sans)
  p.text_size(14)
  p.text_align(Right, vertical=Baseline)
  p.text("TERMINAL", 1760, 893)
}

///|
fn classic(p : @p5.P5, l : Lang, shown : Int32, s : Double) -> Unit {
  let (x, y, ww, hh) = (800.0, 150.0, 1010.0, 720.0)
  p.no_stroke()
  p.fill((0, 0, 0, 120))
  p.rect(x + 12, y + 12, ww, hh)
  p.fill((0, 0, 170))
  p.rect(x, y, ww, hh)
  p.fill((170, 170, 170))
  p.rect(x, y, ww, 34)
  p.rect(x, y + hh - 34, ww, 34)
  p.fill((0, 0, 0))
  p.text_font(mono)
  p.text_size(20)
  p.text_align(Left, vertical=VCenter)
  p.text("  ≡  File  Edit  Search  Run  Compile  Debug  Options", x, y + 17)
  p.text("  F1 Help  F2 Save  F3 Open  F9 Make  F10 Menu", x, y + hh - 17)
  p.no_fill()
  p.stroke((255, 255, 255))
  p.stroke_weight(2)
  p.rect(x + 12, y + 50, ww - 24, hh - 100)
  p.rect(x + 18, y + 56, ww - 36, hh - 112)
  let title = "[ " + l.file + " ]"
  p.no_stroke()
  p.text_size(20)
  let tw = p.text_width(title)
  p.fill((0, 0, 170))
  p.rect(x + ww / 2 - tw / 2 - 8, y + 42, tw + 16, 22)
  p.fill((255, 255, 255))
  p.text_align(HCenter, vertical=VCenter)
  p.text(title, x + ww / 2, y + 53)
  let colorize = (line : String) => {
    tokenize(line, l.keywords, l.comment, l.quotes)
  }
  let pos = draw_code(
    p,
    l.code,
    shown,
    x + 50,
    y + 110,
    25,
    40,
    mono,
    colorize,
    palette(Classic),
  )
  cursor(p, pos, 25, (255, 255, 85), s)
}

///|
fn bevel(
  p : @p5.P5,
  x : Double,
  y : Double,
  ww : Double,
  hh : Double,
  raised : Bool,
) -> Unit {
  let (a, b) = if raised {
    ((255, 255, 255), (64, 64, 64))
  } else {
    ((128, 128, 128), (255, 255, 255))
  }
  p.stroke_weight(2)
  p.stroke(a)
  p.line(x, y, x + ww, y)
  p.line(x, y, x, y + hh)
  p.stroke(b)
  p.line(x, y + hh, x + ww, y + hh)
  p.line(x + ww, y, x + ww, y + hh)
}

///|
fn gui_window(p : @p5.P5, l : Lang, shown : Int32, s : Double) -> Unit {
  let (x, y, ww, hh) = (800.0, 150.0, 1010.0, 720.0)
  p.no_stroke()
  p.fill((0, 0, 0, 90))
  p.rect(x + 10, y + 10, ww, hh)
  p.fill((192, 192, 192))
  p.rect(x, y, ww, hh)
  bevel(p, x, y, ww, hh, true)
  // title bar gradient
  p.no_stroke()
  for i in 0..<60 {
    let f = i.to_double() / 60
    p.fill((0, (f * 110).to_int(), (128.0 + f * 80).to_int()))
    p.rect(x + 6 + f * (ww - 12), y + 6, (ww - 12) / 60 + 1, 36)
  }
  p.fill((255, 255, 255))
  p.text_font(sans)
  p.text_weight(700)
  p.text_size(20)
  p.text_align(Left, vertical=VCenter)
  p.text(l.file + " - Editor", x + 18, y + 24)
  p.text_weight(400)
  for i in 0..<3 {
    let bx = x + ww - 112 + i.to_double() * 34
    p.no_stroke()
    p.fill((192, 192, 192))
    p.rect(bx, y + 11, 28, 26)
    bevel(p, bx, y + 11, 28, 26, true)
    p.no_stroke()
    p.fill((0, 0, 0))
    p.text_align(HCenter, vertical=VCenter)
    p.text_size(18)
    p.text(["_", "□", "×"][i], bx + 14, y + 23)
  }
  p.fill((0, 0, 0))
  p.text_size(19)
  p.text_align(Left, vertical=VCenter)
  p.text("File   Edit   Search   Help", x + 18, y + 62)
  p.no_stroke()
  p.fill((255, 255, 255))
  p.rect(x + 12, y + 84, ww - 24, hh - 96)
  bevel(p, x + 12, y + 84, ww - 24, hh - 96, false)
  let colorize = (line : String) => {
    tokenize(line, l.keywords, l.comment, l.quotes)
  }
  let pos = draw_code(
    p,
    l.code,
    shown,
    x + 42,
    y + 140,
    25,
    40,
    mono,
    colorize,
    palette(Window),
  )
  cursor(p, pos, 25, (20, 20, 20), s)
}

///|
/// A dark code editor with a tab, line numbers and highlighting. Returns the
/// cursor position.
fn editor(
  p : @p5.P5,
  file : String,
  code : Array[String],
  shown : Int32,
  x : Double,
  y : Double,
  ww : Double,
  hh : Double,
  era : Era,
  keywords : Array[String],
  comment : String,
  quotes : String,
) -> (Double, Double) {
  let accent = if era is Moon { moon_purple } else { (97, 175, 239) }
  p.no_stroke()
  p.fill((0, 0, 0, 110))
  p.rect(x + 14, y + 18, ww, hh, tl=18, tr=18, br=18, bl=18)
  p.fill((30, 33, 44))
  p.rect(x, y, ww, hh, tl=18, tr=18, br=18, bl=18)
  p.fill((22, 24, 33))
  p.rect(x, y, ww, 52, tl=18, tr=18, br=0, bl=0)
  for i, c in [(255, 95, 87), (254, 188, 46), (40, 200, 64)] {
    p.fill(c)
    p.circle(x + 30 + i.to_double() * 24, y + 26, 13)
  }
  p.fill((30, 33, 44))
  p.rect(x + 110, y + 10, 210, 42, tl=8, tr=8, br=0, bl=0)
  p.fill(accent)
  p.rect(x + 110, y + 10, 210, 3)
  p.fill((224, 228, 236))
  p.text_font(sans)
  p.text_size(18)
  p.text_align(Left, vertical=VCenter)
  p.text(file, x + 130, y + 32)
  // line numbers, up to the line being typed
  let mut left = shown
  let mut lines_shown = 0
  for line in code {
    if left <= 0 {
      break
    }
    lines_shown += 1
    left -= line.to_array().length() + 1
  }
  p.text_font(mono)
  p.text_size(19)
  p.text_align(Right, vertical=Baseline)
  p.fill((90, 96, 116))
  for i in 0..<lines_shown.max(1) {
    p.text((i + 1).to_string(), x + 66, y + 110 + i.to_double() * 38)
  }
  let colorize = (line : String) => tokenize(line, keywords, comment, quotes)
  draw_code(
    p,
    code,
    shown,
    x + 92,
    y + 110,
    24,
    38,
    mono,
    colorize,
    palette(era),
  )
}
