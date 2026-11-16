// Parsing of CSS color strings (the subset handled by p5's `color("...")`).

///|
/// Parses a CSS color string: hex (`#rgb`, `#rgba`, `#rrggbb`,
/// `#rrggbbaa`), `rgb()`/`rgba()`, `hsl()`/`hsla()`, `hwb()`, named colors
/// and `transparent`. Returns `None` for unsupported input.
///
/// ```mbt check
/// test {
///   inspect(@color.Color::parse("tomato").unwrap().to_css(), content="#ff6347")
///   inspect(@color.Color::parse("#0f08").unwrap().to_css(), content="#00ff0088")
///   inspect(
///     @color.Color::parse("rgb(255 0 0 / 50%)").unwrap().to_css(),
///     content="#ff00007f",
///   )
///   inspect(
///     @color.Color::parse("hsl(120, 100%, 50%)").unwrap().mode(),
///     content="hsl",
///   )
/// }
/// ```
pub fn Color::parse(input : StringView) -> Color? {
  let s = input.trim().to_lower()
  if s is "transparent" {
    return Some(Color::from_native(RGB, 0, 0, 0, alpha=0) |> with_hex)
  }
  if s is ['#', .. hex] {
    return parse_hex(hex)
  }
  if named_colors.get(s.to_owned()) is Some(v) {
    return Some(rgb_from_uint(v, 255))
  }
  guard s.find("(") is Some(open) && s.has_suffix(")") else { return None }
  let name = s[:open].trim()
  let args = s[open + 1:s.length() - 1]
  let parts = split_args(args)
  match name {
    "rgb" | "rgba" => {
      guard parts.length() is (3 | 4) else { return None }
      let channel = (p : StringView) => {
        parse_component(p, 255).map(v => v / 255)
      }
      guard channel(parts[0]) is Some(r) &&
        channel(parts[1]) is Some(g) &&
        channel(parts[2]) is Some(b) else {
        return None
      }
      let a = if parts.length() == 4 {
        parse_alpha(parts[3])
      } else {
        Some(1.0)
      }
      guard a is Some(a) else { return None }
      Some(
        Color::from_native(
          RGB,
          clamp01(r),
          clamp01(g),
          clamp01(b),
          alpha=clamp01(a),
        )
        |> with_hex,
      )
    }
    "hsl" | "hsla" | "hwb" => {
      guard parts.length() is (3 | 4) else { return None }
      guard parse_hue(parts[0]) is Some(h) &&
        parse_component(parts[1], 100) is Some(c1) &&
        parse_component(parts[2], 100) is Some(c2) else {
        return None
      }
      let a = if parts.length() == 4 {
        parse_alpha(parts[3])
      } else {
        Some(1.0)
      }
      guard a is Some(a) else { return None }
      let mode = if name is "hwb" { HWB } else { HSL }
      Some(Color::from_native(mode, h, c1, c2, alpha=clamp01(a)))
    }
    _ => None
  }
}

///|
fn with_hex(c : Color) -> Color {
  let (r, g, b) = c.coords()
  c.default_string = Some(hex_string(r, g, b, c.alpha))
  c
}

///|
fn rgb_from_uint(v : UInt32, alpha : UInt32) -> Color {
  let r = ((v >> 16) & 0xff).to_double() / 255
  let g = ((v >> 8) & 0xff).to_double() / 255
  let b = (v & 0xff).to_double() / 255
  Color::from_native(RGB, r, g, b, alpha=alpha.to_double() / 255) |> with_hex
}

///|
fn hex_digit(c : Char) -> UInt32? {
  match c {
    '0'..<='9' => Some((c.to_int() - '0'.to_int()).reinterpret_as_uint())
    'a'..<='f' => Some((c.to_int() - 'a'.to_int() + 10).reinterpret_as_uint())
    _ => None
  }
}

///|
fn parse_hex(hex : StringView) -> Color? {
  let digits : Array[UInt32] = []
  for c in hex {
    guard hex_digit(c) is Some(d) else { return None }
    digits.push(d)
  }
  match digits {
    [r, g, b] =>
      Some(rgb_from_uint(((r * 17) << 16) | ((g * 17) << 8) | (b * 17), 255))
    [r, g, b, a] =>
      Some(rgb_from_uint(((r * 17) << 16) | ((g * 17) << 8) | (b * 17), a * 17))
    [r1, r2, g1, g2, b1, b2] =>
      Some(
        rgb_from_uint(
          ((r1 * 16 + r2) << 16) | ((g1 * 16 + g2) << 8) | (b1 * 16 + b2),
          255,
        ),
      )
    [r1, r2, g1, g2, b1, b2, a1, a2] =>
      Some(
        rgb_from_uint(
          ((r1 * 16 + r2) << 16) | ((g1 * 16 + g2) << 8) | (b1 * 16 + b2),
          a1 * 16 + a2,
        ),
      )
    _ => None
  }
}

///|
/// Splits `a, b, c` / `a b c / d` argument lists.
fn split_args(args : StringView) -> Array[StringView] {
  let normalized = args
    .to_owned()
    .replace_all(old=",", new=" ")
    .replace_all(old="/", new=" ")
  normalized.split(" ").filter(p => !p.is_empty()).collect()
}

///|
fn parse_number(s : StringView) -> Double? {
  try @string.parse_double(s) catch {
    _ => None
  } noraise {
    v => Some(v)
  }
}

///|
/// A number, or a percentage of `full`.
fn parse_component(s : StringView, full : Double) -> Double? {
  if s is [.. num, '%'] {
    parse_number(num).map(v => v / 100 * full)
  } else {
    parse_number(s)
  }
}

///|
fn parse_alpha(s : StringView) -> Double? {
  parse_component(s, 1)
}

///|
fn parse_hue(s : StringView) -> Double? {
  if s is [.. num, 'd', 'e', 'g'] {
    parse_number(num)
  } else if s is [.. num, 'r', 'a', 'd'] {
    parse_number(num).map(v => v * @math.RAD_TO_DEG)
  } else if s is [.. num, 't', 'u', 'r', 'n'] {
    parse_number(num).map(v => v * 360)
  } else {
    parse_number(s)
  }
}
