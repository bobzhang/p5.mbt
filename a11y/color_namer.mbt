// p5.js src/accessibility/color_namer.js: names a color for screen readers
// by rounding it in HSB and looking the result up in a table.

///|
/// p5's `_rgbaToHSBA`, applied to RGBA in [0, 255] as p5's accessible
/// outputs do: hue and saturation come out in [0, 1], brightness in
/// [0, 255].
fn rgba_to_hsba(rgba : FixedArray[Double]) -> Array[Double] {
  let red = rgba[0]
  let green = rgba[1]
  let blue = rgba[2]
  let v = red.max(green).max(blue)
  let chroma = v - red.min(green).min(blue)
  let (hue, sat) = if chroma == 0 {
    (0.0, 0.0)
  } else {
    let mut h = if red == v {
      (green - blue) / chroma
    } else if green == v {
      2.0 + (blue - red) / chroma
    } else {
      4.0 + (red - green) / chroma
    }
    if h < 0 {
      h += 6
    } else if h >= 6 {
      h -= 6
    }
    (h, chroma / v)
  }
  [hue / 6, sat, v, rgba[3]]
}

///|
/// JavaScript's `Math.round`.
fn js_round(x : Double) -> Double {
  (x + 0.5).floor()
}

///|
/// p5's `_calculateColor`.
fn calculate_color(hsb : Array[Double], original : Array[Double]) -> String {
  if hsb[0] != 0 {
    hsb[0] = js_round(hsb[0] * 100)
    let digits = hsb[0].to_int().to_string().to_array()
    let hue = digits.map(c => (c.to_int() - '0'.to_int()).to_double())
    let last = hue.length() - 1
    if hue[last] < 2.5 {
      hue[last] = 0
    } else if hue[last] >= 2.5 && hue[last] < 7.5 {
      hue[last] = 5
    }
    if hue.length() == 2 {
      if hue[last] >= 7.5 {
        hue[last] = 0
        hue[0] = hue[0] + 1
      }
      hsb[0] = hue[0] * 10 + hue[1]
    } else if hue[last] >= 7.5 {
      hsb[0] = 10
    } else {
      hsb[0] = hue[last]
    }
  }
  hsb[2] = hsb[2] / 255
  for i = hsb.length() - 1; i >= 1; i = i - 1 {
    hsb[i] = if hsb[i] <= 0.25 {
      0
    } else if hsb[i] > 0.25 && hsb[i] < 0.75 {
      0.5
    } else {
      1
    }
  }
  if hsb[0] == 0 && hsb[1] == 0 && hsb[2] == 1 {
    for i = 2; i >= 0; i = i - 1 {
      original[i] = js_round(original[i] * 10000) / 10000
    }
    let mut text = "undefined"
    for e in color_exceptions {
      let (h, s, b, name) = e
      if h == original[0] && s == original[1] && b == original[2] {
        text = name
        break
      } else {
        text = "white"
      }
    }
    text
  } else {
    for e in color_lookup {
      let (h, s, b, name) = e
      if h == hsb[0] && s == hsb[1] && b == hsb[2] {
        return name
      }
    }
    "undefined"
  }
}

///|
/// The name p5's accessible outputs give a color, from RGBA in [0, 255]
/// (`_rgbColorName`).
pub fn color_name(rgba : FixedArray[Double]) -> String {
  let hsb = rgba_to_hsba(rgba)
  calculate_color([hsb[0], hsb[1], hsb[2]], hsb)
}
