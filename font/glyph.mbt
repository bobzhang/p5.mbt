// Glyph outlines: TrueType `glyf` and CFF Type 2 charstrings, a port of
// Typr.js's `glyphToPath`, `_simpleGlyph`, `_compoGlyph` and `_drawCFF`.

///|
/// A path command of a glyph outline.
#derive(Debug, Eq, Hash)
pub(all) enum PathCmd {
  /// Move to (x, y).
  M
  /// Line to (x, y).
  L
  /// Quadratic curve: control (x, y), end (x, y).
  Q
  /// Cubic curve: two controls then the end point.
  C
  /// Close the contour.
  Z
}

///|
/// A glyph outline in font units, y up: commands plus their flattened
/// coordinates (Typr's `{cmds, crds}`).
#derive(Debug)
pub struct GlyphPath {
  cmds : Array[PathCmd]
  crds : Array[Double]
}

///|
fn GlyphPath::new() -> GlyphPath {
  { cmds: [], crds: [], }
}

///|
fn GlyphPath::move_to(self : GlyphPath, x : Double, y : Double) -> Unit {
  self.cmds.push(M)
  self.crds.push(x)
  self.crds.push(y)
}

///|
fn GlyphPath::line_to(self : GlyphPath, x : Double, y : Double) -> Unit {
  self.cmds.push(L)
  self.crds.push(x)
  self.crds.push(y)
}

///|
fn GlyphPath::q_to(
  self : GlyphPath,
  x1 : Double,
  y1 : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.cmds.push(Q)
  for v in [x1, y1, x, y] {
    self.crds.push(v)
  }
}

///|
fn GlyphPath::c_to(
  self : GlyphPath,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.cmds.push(C)
  for v in [x1, y1, x2, y2, x, y] {
    self.crds.push(v)
  }
}

///|
fn GlyphPath::close(self : GlyphPath) -> Unit {
  self.cmds.push(Z)
}

///|
/// The outline of glyph `gid` (cached).
pub fn FontData::glyph_path(self : FontData, gid : Int32) -> GlyphPath {
  if self.glyph_cache.get(gid) is Some(p) {
    return p
  }
  let path = GlyphPath::new()
  match self.cff {
    Some(cff) => {
      let mut pdct = cff.private_dict
      if cff.fd_select is Some(sel) {
        let mut gi = 0
        while gi + 2 < sel.length() && sel[gi + 2] <= gid {
          gi += 2
        }
        pdct = cff.fd_array.get(sel.get(gi + 1).unwrap_or(0)).unwrap_or(None)
      }
      if cff.char_strings.get(gid) is Some(cs) {
        let state = {
          x: 0.0,
          y: 0.0,
          stack: [],
          n_stems: 0,
          have_width: false,
          open: false,
        }
        draw_cff(cs, state, cff, pdct, path, 0)
      }
    }
    None => self.draw_glyf(gid, path, 0)
  }
  self.glyph_cache[gid] = path
  path
}

// ---- TrueType glyf ----

///|
priv struct Component {
  glyph : Int32
  a : Double
  b : Double
  c : Double
  d : Double
  tx : Double
  ty : Double
}

///|
fn FontData::draw_glyf(
  self : FontData,
  gid : Int32,
  p : GlyphPath,
  depth : Int32,
) -> Unit {
  guard self.glyf_offset is Some(glyf) && depth < 16 else { return }
  guard gid >= 0 && gid + 1 < self.loca.length() else { return }
  if self.loca[gid] == self.loca[gid + 1] {
    return
  }
  let d = self.data
  let mut o = glyf + self.loca[gid].to_int()
  let noc = i16(d, o)
  let x_min = i16(d, o + 2)
  let y_min = i16(d, o + 4)
  let x_max = i16(d, o + 6)
  let y_max = i16(d, o + 8)
  o += 10
  if x_min >= x_max || y_min >= y_max {
    return
  }
  if noc >= 0 {
    let end_pts = [ for i in 0..<noc => u16(d, o + i * 2) ]
    o += noc * 2
    let ilen = u16(d, o)
    o += 2
    if d.length() - o < ilen {
      return
    }
    o += ilen
    if noc == 0 {
      return
    }
    let n = end_pts[noc - 1] + 1
    let flags : Array[Int32] = []
    while flags.length() < n {
      let flag = u8(d, o)
      o += 1
      flags.push(flag)
      if (flag & 8) != 0 {
        let rep = u8(d, o)
        o += 1
        for _ in 0..<rep {
          flags.push(flag)
        }
      }
    }
    let xs : Array[Double] = []
    let ys : Array[Double] = []
    let mut acc = 0
    for i in 0..<n {
      let short = (flags[i] & 2) != 0
      let same = (flags[i] & 16) != 0
      if short {
        acc += if same { u8(d, o) } else { -u8(d, o) }
        o += 1
      } else if !same {
        acc += i16(d, o)
        o += 2
      }
      xs.push(acc.to_double())
    }
    acc = 0
    for i in 0..<n {
      let short = (flags[i] & 4) != 0
      let same = (flags[i] & 32) != 0
      if short {
        acc += if same { u8(d, o) } else { -u8(d, o) }
        o += 1
      } else if !same {
        acc += i16(d, o)
        o += 2
      }
      ys.push(acc.to_double())
    }
    simple_glyph(noc, end_pts, flags, xs, ys, p)
  } else {
    let parts : Array[Component] = []
    for ;; {
      let flags = u16(d, o)
      let glyph = u16(d, o + 2)
      o += 4
      let (arg1, arg2) = if (flags & 1) != 0 {
        o += 4
        (i16(d, o - 4), i16(d, o - 2))
      } else {
        o += 2
        (i8(d, o - 2), i8(d, o - 1))
      }
      // point-matched offsets (ARGS_ARE_XY_VALUES unset) are ignored, as
      // in Typr
      let (tx, ty) = if (flags & 2) != 0 {
        (arg1.to_double(), arg2.to_double())
      } else {
        (0.0, 0.0)
      }
      let mut a = 1.0
      let mut b = 0.0
      let mut c = 0.0
      let mut dd = 1.0
      if (flags & 8) != 0 {
        a = f2dot14(d, o)
        dd = a
        o += 2
      } else if (flags & 64) != 0 {
        a = f2dot14(d, o)
        dd = f2dot14(d, o + 2)
        o += 4
      } else if (flags & 128) != 0 {
        a = f2dot14(d, o)
        b = f2dot14(d, o + 2)
        c = f2dot14(d, o + 4)
        dd = f2dot14(d, o + 6)
        o += 8
      }
      parts.push({ glyph, a, b, c, d: dd, tx, ty, })
      if (flags & 32) == 0 || o >= d.length() {
        break
      }
    }
    for part in parts {
      let sub = GlyphPath::new()
      self.draw_glyf(part.glyph, sub, depth + 1)
      for i = 0; i + 1 < sub.crds.length(); i = i + 2 {
        let x = sub.crds[i]
        let y = sub.crds[i + 1]
        p.crds.push(x * part.a + y * part.c + part.tx)
        p.crds.push(x * part.b + y * part.d + part.ty)
      }
      for cmd in sub.cmds {
        p.cmds.push(cmd)
      }
    }
  }
}

///|
fn simple_glyph(
  noc : Int32,
  end_pts : Array[Int32],
  flags : Array[Int32],
  xs : Array[Double],
  ys : Array[Double],
  p : GlyphPath,
) -> Unit {
  let floor = @cmath.floor
  for c in 0..<noc {
    let i0 = if c == 0 { 0 } else { end_pts[c - 1] + 1 }
    let il = end_pts[c]
    for i in i0..<=il {
      let pr = if i == i0 { il } else { i - 1 }
      let nx = if i == il { i0 } else { i + 1 }
      let on = (flags[i] & 1) != 0
      let pr_on = (flags[pr] & 1) != 0
      let nx_on = (flags[nx] & 1) != 0
      let x = xs[i]
      let y = ys[i]
      if i == i0 {
        if on {
          if pr_on {
            p.move_to(xs[pr], ys[pr])
          } else {
            p.move_to(x, y)
            continue
          }
        } else if pr_on {
          p.move_to(xs[pr], ys[pr])
        } else {
          p.move_to(floor((xs[pr] + x) * 0.5), floor((ys[pr] + y) * 0.5))
        }
      }
      if on {
        if pr_on {
          p.line_to(x, y)
        }
      } else if nx_on {
        p.q_to(x, y, xs[nx], ys[nx])
      } else {
        p.q_to(x, y, floor((x + xs[nx]) * 0.5), floor((y + ys[nx]) * 0.5))
      }
    }
    p.close()
  }
}

// ---- CFF Type 2 charstrings ----

///|
priv struct CffState {
  mut x : Double
  mut y : Double
  stack : Array[Double]
  mut n_stems : Int32
  mut have_width : Bool
  mut open : Bool
}

///|
/// `stack.shift()`; NaN when empty, like JS's `undefined` in arithmetic.
fn shift(stack : Array[Double]) -> Double {
  if stack.is_empty() {
    @double.not_a_number
  } else {
    stack.remove(0)
  }
}

///|
fn pop(stack : Array[Double]) -> Double {
  stack.pop().unwrap_or(@double.not_a_number)
}

///|
/// Decodes one charstring token at `i`: `(operator or -1, operand, size)`.
fn char_token(d : Bytes, i : Int32) -> (Int32, Double, Int32) {
  let b0 = u8(d, i)
  let b1 = u8(d, i + 1)
  if b0 == 12 {
    (1200 + b1, 0, 2)
  } else if b0 <= 20 || (b0 >= 21 && b0 <= 27) || (b0 >= 29 && b0 <= 31) {
    (b0, 0, 1)
  } else if b0 == 28 {
    (-1, i16(d, i + 1).to_double(), 3)
  } else if b0 <= 246 {
    (-1, (b0 - 139).to_double(), 1)
  } else if b0 <= 250 {
    (-1, ((b0 - 247) * 256 + b1 + 108).to_double(), 2)
  } else if b0 <= 254 {
    (-1, (-(b0 - 251) * 256 - b1 - 108).to_double(), 2)
  } else {
    (-1, i32(d, i + 1) / 65535.0, 5)
  }
}

///|
fn stem_width(stack : Array[Double], have_width : Bool) -> Unit {
  if stack.length() % 2 != 0 && !have_width {
    ignore(shift(stack))
  }
}

///|
fn draw_cff(
  cmds : Bytes,
  state : CffState,
  font : Cff,
  pdct : PrivateDict?,
  p : GlyphPath,
  depth : Int32,
) -> Unit {
  if depth > 10 {
    return
  }
  let stack = state.stack
  let mut n_stems = state.n_stems
  let mut have_width = state.have_width
  let mut open = state.open
  let mut x = state.x
  let mut y = state.y
  let mut i = 0
  let curve = (c1x, c1y, c2x, c2y, ex, ey) => p.c_to(c1x, c1y, c2x, c2y, ex, ey)
  while i < cmds.length() {
    let (op, v, size) = char_token(cmds, i)
    i += size
    match op {
      -1 => stack.push(v)
      1 | 18 | 3 | 23 => {
        stem_width(stack, have_width)
        n_stems += stack.length() >> 1
        stack.clear()
        have_width = true
      }
      4 => {
        if stack.length() > 1 && !have_width {
          ignore(shift(stack))
          have_width = true
        }
        if open {
          p.close()
        }
        y += pop(stack)
        p.move_to(x, y)
        open = true
      }
      5 =>
        while stack.length() > 0 {
          x += shift(stack)
          y += shift(stack)
          p.line_to(x, y)
        }
      6 | 7 => {
        let count = stack.length()
        let mut is_x = op == 6
        for _ in 0..<count {
          let s = shift(stack)
          if is_x {
            x += s
          } else {
            y += s
          }
          is_x = !is_x
          p.line_to(x, y)
        }
      }
      8 | 24 => {
        let count = stack.length()
        let mut index = 0
        while index + 6 <= count {
          let c1x = x + shift(stack)
          let c1y = y + shift(stack)
          let c2x = c1x + shift(stack)
          let c2y = c1y + shift(stack)
          x = c2x + shift(stack)
          y = c2y + shift(stack)
          curve(c1x, c1y, c2x, c2y, x, y)
          index += 6
        }
        if op == 24 {
          x += shift(stack)
          y += shift(stack)
          p.line_to(x, y)
        }
      }
      11 => break
      1234 => {
        let c1x = x + shift(stack)
        let c1y = y
        let c2x = c1x + shift(stack)
        let c2y = c1y + shift(stack)
        let jpx = c2x + shift(stack)
        let jpy = c2y
        let c3x = jpx + shift(stack)
        let c3y = c2y
        let c4x = c3x + shift(stack)
        let c4y = y
        x = c4x + shift(stack)
        curve(c1x, c1y, c2x, c2y, jpx, jpy)
        curve(c3x, c3y, c4x, c4y, x, y)
      }
      1235 => {
        let c1x = x + shift(stack)
        let c1y = y + shift(stack)
        let c2x = c1x + shift(stack)
        let c2y = c1y + shift(stack)
        let jpx = c2x + shift(stack)
        let jpy = c2y + shift(stack)
        let c3x = jpx + shift(stack)
        let c3y = jpy + shift(stack)
        let c4x = c3x + shift(stack)
        let c4y = c3y + shift(stack)
        x = c4x + shift(stack)
        y = c4y + shift(stack)
        ignore(shift(stack))
        curve(c1x, c1y, c2x, c2y, jpx, jpy)
        curve(c3x, c3y, c4x, c4y, x, y)
      }
      1236 => {
        let c1x = x + shift(stack)
        let c1y = y + shift(stack)
        let c2x = c1x + shift(stack)
        let c2y = c1y + shift(stack)
        let jpx = c2x + shift(stack)
        let jpy = c2y
        let c3x = jpx + shift(stack)
        let c3y = c2y
        let c4x = c3x + shift(stack)
        let c4y = c3y + shift(stack)
        x = c4x + shift(stack)
        curve(c1x, c1y, c2x, c2y, jpx, jpy)
        curve(c3x, c3y, c4x, c4y, x, y)
      }
      1237 => {
        let c1x = x + shift(stack)
        let c1y = y + shift(stack)
        let c2x = c1x + shift(stack)
        let c2y = c1y + shift(stack)
        let jpx = c2x + shift(stack)
        let jpy = c2y + shift(stack)
        let c3x = jpx + shift(stack)
        let c3y = jpy + shift(stack)
        let c4x = c3x + shift(stack)
        let c4y = c3y + shift(stack)
        if (c4x - x).abs() > (c4y - y).abs() {
          x = c4x + shift(stack)
        } else {
          y = c4y + shift(stack)
        }
        curve(c1x, c1y, c2x, c2y, jpx, jpy)
        curve(c3x, c3y, c4x, c4y, x, y)
      }
      14 => {
        if stack.length() > 0 && stack.length() != 4 && !have_width {
          ignore(shift(stack))
          have_width = true
        }
        if stack.length() == 4 {
          // seac: an accented character from two standard-encoding glyphs
          let adx = shift(stack)
          let ady = shift(stack)
          let bchar = shift(stack).to_int()
          let achar = shift(stack).to_int()
          let bind = font.glyph_by_se(bchar)
          let aind = font.glyph_by_se(achar)
          if font.char_strings.get(bind) is Some(cs) {
            draw_cff(cs, state, font, pdct, p, depth + 1)
          }
          state.x = adx
          state.y = ady
          if font.char_strings.get(aind) is Some(cs) {
            draw_cff(cs, state, font, pdct, p, depth + 1)
          }
        }
        if open {
          p.close()
          open = false
        }
      }
      19 | 20 => {
        stem_width(stack, have_width)
        n_stems += stack.length() >> 1
        stack.clear()
        have_width = true
        i += (n_stems + 7) >> 3
      }
      21 => {
        if stack.length() > 2 && !have_width {
          ignore(shift(stack))
          have_width = true
        }
        y += pop(stack)
        x += pop(stack)
        if open {
          p.close()
        }
        p.move_to(x, y)
        open = true
      }
      22 => {
        if stack.length() > 1 && !have_width {
          ignore(shift(stack))
          have_width = true
        }
        x += pop(stack)
        if open {
          p.close()
        }
        p.move_to(x, y)
        open = true
      }
      25 => {
        while stack.length() > 6 {
          x += shift(stack)
          y += shift(stack)
          p.line_to(x, y)
        }
        let c1x = x + shift(stack)
        let c1y = y + shift(stack)
        let c2x = c1x + shift(stack)
        let c2y = c1y + shift(stack)
        x = c2x + shift(stack)
        y = c2y + shift(stack)
        curve(c1x, c1y, c2x, c2y, x, y)
      }
      26 => {
        if stack.length() % 2 != 0 {
          x += shift(stack)
        }
        while stack.length() > 0 {
          let c1x = x
          let c1y = y + shift(stack)
          let c2x = c1x + shift(stack)
          let c2y = c1y + shift(stack)
          x = c2x
          y = c2y + shift(stack)
          curve(c1x, c1y, c2x, c2y, x, y)
        }
      }
      27 => {
        if stack.length() % 2 != 0 {
          y += shift(stack)
        }
        while stack.length() > 0 {
          let c1x = x + shift(stack)
          let c1y = y
          let c2x = c1x + shift(stack)
          let c2y = c1y + shift(stack)
          x = c2x + shift(stack)
          y = c2y
          curve(c1x, c1y, c2x, c2y, x, y)
        }
      }
      10 | 29 => {
        let subrs = if op == 10 {
          match pdct {
            Some(pd) => pd.subrs
            None => None
          }
        } else {
          Some(font.gsubrs)
        }
        if stack.length() > 0 && subrs is Some(s) {
          let ind = pop(stack).to_int() + s.bias
          if s.items.get(ind) is Some(subr) {
            state.x = x
            state.y = y
            state.n_stems = n_stems
            state.have_width = have_width
            state.open = open
            draw_cff(subr, state, font, pdct, p, depth + 1)
            x = state.x
            y = state.y
            n_stems = state.n_stems
            have_width = state.have_width
            open = state.open
          }
        }
      }
      30 | 31 => {
        let count1 = stack.length()
        let count = count1 & -3
        let mut index = count1 - count
        let mut alternate = op == 31
        while index < count {
          let (c1x, c1y, c2x, c2y) = if alternate {
            let c1x = x + shift(stack)
            let c1y = y
            let c2x = c1x + shift(stack)
            let c2y = c1y + shift(stack)
            y = c2y + shift(stack)
            if count - index == 5 {
              x = c2x + shift(stack)
              index += 1
            } else {
              x = c2x
            }
            (c1x, c1y, c2x, c2y)
          } else {
            let c1x = x
            let c1y = y + shift(stack)
            let c2x = c1x + shift(stack)
            let c2y = c1y + shift(stack)
            x = c2x + shift(stack)
            if count - index == 5 {
              y = c2y + shift(stack)
              index += 1
            } else {
              y = c2y
            }
            (c1x, c1y, c2x, c2y)
          }
          alternate = !alternate
          curve(c1x, c1y, c2x, c2y, x, y)
          index += 4
        }
      }
      // unknown operators throw in Typr; stop drawing this glyph here
      _ => break
    }
  }
  state.x = x
  state.y = y
  state.n_stems = n_stems
  state.have_width = have_width
  state.open = open
}

///|
/// The SVG/Typr letter of a command: "M", "L", "Q", "C" or "Z".
pub fn PathCmd::letter(self : PathCmd) -> String {
  match self {
    M => "M"
    L => "L"
    Q => "Q"
    C => "C"
    Z => "Z"
  }
}
