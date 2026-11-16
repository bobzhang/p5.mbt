///|
fn rgb255(c : @color.Color) -> String {
  let (r, g, b, a) = c.rgba()
  "\{@math.round(r)}, \{@math.round(g)}, \{@math.round(b)}, \{@math.round(a)}"
}

///|
test "color() arguments in RGB mode" {
  let m = @color.default_maxes(RGB)
  inspect(@color.Color::new([127], RGB, m).to_css(), content="#7f7f7f")
  inspect(@color.Color::new([0, 128], RGB, m).to_css(), content="#00000080")
  inspect(@color.Color::new([300, -5, 64], RGB, m).to_css(), content="#ff0040")
  inspect(
    @color.Color::new([10, 20, 30, 40], RGB, m).to_css(),
    content="#0a141e28",
  )
}

///|
test "color() arguments in HSB / HSL / HWB modes" {
  let hsb = @color.default_maxes(HSB)
  inspect(
    rgb255(@color.Color::new([0, 100, 100], HSB, hsb)),
    content="255, 0, 0, 255",
  )
  inspect(
    rgb255(@color.Color::new([240, 100, 50], HSB, hsb)),
    content="0, 0, 128, 255",
  )
  inspect(
    rgb255(@color.Color::new([50], HSB, hsb)),
    content="128, 128, 128, 255",
  )
  let hsl = @color.default_maxes(HSL)
  inspect(
    rgb255(@color.Color::new([120, 100, 50], HSL, hsl)),
    content="0, 255, 0, 255",
  )
  inspect(
    rgb255(@color.Color::new([60, 100, 25, 0.5], HSL, hsl)),
    content="128, 128, 0, 128",
  )
  let hwb = @color.default_maxes(HWB)
  inspect(
    rgb255(@color.Color::new([0, 0, 0], HWB, hwb)),
    content="255, 0, 0, 255",
  )
  // custom maxes like colorMode(HSB, 1)
  let unit = @color.maxes(1, 1, 1, 1)
  inspect(
    rgb255(@color.Color::new([0.5, 1, 1], HSB, unit)),
    content="0, 255, 255, 255",
  )
}

///|
test "perceptual spaces round trip" {
  let red = @color.Color::rgb(255, 0, 0)
  for
    mode in [
      @color.ColorMode::LAB,
      @color.ColorMode::LCH,
      @color.ColorMode::OKLAB,
      @color.ColorMode::OKLCH,
      @color.ColorMode::HSB,
      @color.ColorMode::HSL,
      @color.ColorMode::HWB,
    ] {
    let back = red.to_mode(mode).to_mode(RGB)
    assert_eq(rgb255(back), "255, 0, 0, 255")
  }
  let (l, a, b) = red.to_mode(LAB).coords()
  // CIE Lab (D50) of sRGB red, as computed by color.js
  inspect(@math.round(l, decimals=2), content="54.29")
  inspect(@math.round(a, decimals=2), content="80.8")
  inspect(@math.round(b, decimals=2), content="69.89")
  let (ol, _, oh) = red.to_mode(OKLCH).coords()
  inspect(@math.round(ol, decimals=3), content="0.628")
  inspect(@math.round(oh, decimals=1), content="29.2")
}

///|
test "readers" {
  let c = @color.Color::rgb(255, 204, 0)
  inspect(c.red(), content="255")
  inspect(@math.round(c.hue()), content="48")
  inspect(@math.round(c.saturation()), content="100")
  inspect(@math.round(c.brightness()), content="100")
  inspect(@math.round(c.lightness()), content="50")
  c.set_alpha(51)
  inspect(c.to_css(), content="#ffcc0033")
  c.set_red(0)
  inspect(c.to_css(), content="#00cc0033")
}

///|
test "lerp" {
  let from = @color.Color::rgb(218, 165, 32)
  let to = @color.Color::rgb(72, 61, 139)
  inspect(
    from.lerp(to, 0.33).to_css(),
    content=(
      #|#a98243
    ),
  )
  let hsb = @color.default_maxes(HSB)
  // In HSB the hue takes the short way round: 350 -> 10 passes through 0.
  let a = @color.Color::new([350, 100, 100], HSB, hsb)
  let b = @color.Color::new([10, 100, 100], HSB, hsb)
  inspect(a.lerp(b, 0.5).hue(), content="0")
  let p = @color.palette_lerp(
    [(@color.Color::rgb(255, 0, 0), 0), (@color.Color::rgb(0, 0, 255), 1)],
    0.5,
  )
  inspect(p.to_css(), content="#7f007f")
}

///|
test "parse" {
  let css = (s : String) => {
    match @color.Color::parse(s) {
      Some(c) => c.to_css()
      None => "invalid"
    }
  }
  inspect(css("RebeccaPurple"), content="#663399")
  inspect(css("#abc"), content="#aabbcc")
  inspect(css("#11223344"), content="#11223344")
  inspect(css("rgba(255, 0, 0, 0.25)"), content="#ff00003f")
  inspect(css("rgb(100% 50% 0%)"), content="#ff7f00")
  inspect(css("hsl(0deg 100% 50%)"), content="rgb(100% 0% 0%)")
  inspect(css("transparent"), content="#00000000")
  inspect(css("nope"), content="invalid")
  inspect(css("#12"), content="invalid")
}

///|
test "contrast" {
  let black = @color.Color::rgb(0, 0, 0)
  let white = @color.Color::rgb(255, 255, 255)
  inspect(black.contrast_ratio(white), content="21")
}
