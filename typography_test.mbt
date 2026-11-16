///|
fn text_sketch() -> (@p5.P5, @p5.Recorder) {
  let rec = @p5.Recorder::new()
  let p = @p5.P5::headless(rec, 200, 200)
  ignore(rec.take())
  (p, rec)
}

///|
test "text defaults: black fill, no stroke, 12px sans-serif" {
  let (p, rec) = text_sketch()
  p.text("hello", 10, 20)
  inspect(
    rec.take().join("\n"),
    content=(
      #|font normal normal 12px sans-serif left alphabetic
      #|transform 1 0 0 1 0 0
      #|fill_text #000000 "hello" 10,20
    ),
  )
}

///|
test "multi-line text uses leading = 1.275 x size" {
  let (p, rec) = text_sketch()
  p.text_size(20)
  p.text_style(BoldItalic)
  p.text_font("Comic Sans MS")
  p.fill("red")
  p.stroke("blue")
  p.text_align(HCenter, vertical=VCenter)
  p.text("a\nb", 100, 100)
  inspect(
    rec.take().join("\n"),
    content=(
      #|font italic bold 20px "Comic Sans MS" center middle
      #|transform 1 0 0 1 0 0
      #|stroke_text #0000ff w=1 "a" 100,87.25
      #|fill_text #ff0000 "a" 100,87.25
      #|stroke_text #0000ff w=1 "b" 100,112.75
      #|fill_text #ff0000 "b" 100,112.75
    ),
  )
}

///|
test "text in a box wraps words and truncates to the height" {
  let (p, rec) = text_sketch()
  p.text_size(10) // the recorder measures 5px per character
  p.text_leading(12)
  p.text("one two three four five", 0, 0, max_width=50, max_height=30)
  inspect(
    rec.take().join("\n"),
    content=(
      #|font normal normal 10px sans-serif left top
      #|transform 1 0 0 1 0 0
      #|fill_text #000000 "one two" 0,0
      #|fill_text #000000 "three" 0,12
    ),
  )
  p.text_align(Right)
  p.text_wrap(Char)
  p.rect_mode(Center)
  p.text("abcdefgh", 50, 50, max_width=20)
  inspect(
    rec.take().join("\n"),
    content=(
      #|font normal normal 10px sans-serif right top
      #|transform 1 0 0 1 0 0
      #|fill_text #000000 "abcd" 60,50
      #|fill_text #000000 "efgh" 60,62
    ),
  )
}

///|
test "text measurement" {
  let (p, _) = text_sketch()
  p.text_size(10)
  inspect(p.text_width("abcd\nab"), content="20")
  inspect(p.text_ascent(), content="8")
  inspect(p.text_descent(), content="2")
}

///|
test "number formatting matches p5.js" {
  inspect(@p5.nf(1.5, left=3, right=3), content="001.500")
  inspect(@p5.nf(0.1 + 0.2), content="0.30000000000000004")
  inspect(@p5.nfp(5, left=2), content="+05")
  inspect(@p5.nfs(5, left=2), content=" 05")
  inspect(@p5.nfs(-5, left=2), content="-05")
  inspect(@p5.nfc(-1234.5, right=3), content="-1,234.500")
  inspect(@p5.nfc(1234.5678, right=0), content="1,234")
  inspect(@p5.binary(5, digits=4), content="0101")
  inspect(@p5.unbinary("1010"), content="10")
  inspect(@p5.hex(0x1234ABCD), content="1234ABCD")
}

///|
test "shuffle uses the sketch's random generator" {
  let (p, _) = text_sketch()
  p.random_seed(1)
  let a = p.shuffle([1, 2, 3, 4, 5])
  p.random_seed(1)
  let b = p.shuffle([1, 2, 3, 4, 5])
  assert_eq(a, b)
  let sorted = a.copy()
  sorted.sort()
  debug_inspect(sorted, content="[1, 2, 3, 4, 5]")
}
