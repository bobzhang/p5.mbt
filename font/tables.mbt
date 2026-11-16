// Port of the font table parsers of Typr.js (MIT, Photopea), as used by
// p5.js's p5.Font: head, hhea, maxp, hmtx, cmap, loca, glyf, kern and CFF.

///|
priv enum CmapTable {
  Format0(Array[Int32])
  Format4(Array[Int32], Array[Int32], Array[Int32], Array[Int32], Array[Int32])
  Format6(Int32, Array[Int32])
  Format12(Array[Double])
  Unsupported
}

///|
priv struct KernPairs {
  glyph1 : Array[Int32]
  rval : Array[(Array[Int32], Array[Int32])]
}

///|
/// A parsed font (the parts p5.js uses for glyph outlines).
pub struct FontData {
  priv data : Bytes
  /// Font units per em.
  units_per_em : Int32
  /// Ascender from `hhea`, in font units.
  ascender : Int32
  /// Descender from `hhea`, in font units.
  descender : Int32
  /// Number of glyphs.
  num_glyphs : Int32
  priv advance : Array[Int32]
  priv cmap : CmapTable
  priv loca : Array[Double]
  priv glyf_offset : Int32?
  priv cff : Cff?
  priv kern : KernPairs?
  priv glyph_cache : Map[Int32, GlyphPath]
}

///|
fn find_table(d : Bytes, tag : String, foff : Int32) -> (Int32, Int32)? {
  let num = u16(d, foff + 4)
  let mut off = foff + 12
  for _ in 0..<num {
    if ascii(d, off, 4) == tag {
      return Some((u32(d, off + 8).to_int(), u32(d, off + 12).to_int()))
    }
    off += 16
  }
  None
}

///|
fn parse_cmap(d : Bytes, base : Int32) -> CmapTable {
  let num = u16(d, base + 2)
  // platform/encoding pairs Typr prefers, in order
  let prefs = [(3, 10), (0, 4), (3, 1), (1, 0), (0, 3), (0, 1), (3, 0), (3, 5)]
  let ids : Map[(Int32, Int32), Int32] = Map([])
  for i in 0..<num {
    let rec = base + 4 + i * 8
    let key = (u16(d, rec), u16(d, rec + 2))
    // later records win, like Typr's `obj.ids[id] = tind`
    ids[key] = u32(d, rec + 4).to_int()
  }
  let mut sub = -1
  for p in prefs {
    if ids.get(p) is Some(o) {
      sub = o
      break
    }
  }
  if sub < 0 {
    return Unsupported
  }
  let off = base + sub
  match u16(d, off) {
    0 => {
      let len = u16(d, off + 2)
      Format0([ for i in 0..<(len - 6) => u8(d, off + 6 + i) ])
    }
    4 => {
      let length = u16(d, off + 2)
      let seg = u16(d, off + 6) >> 1
      let mut o = off + 14
      let end_count = [ for i in 0..<seg => u16(d, o + i * 2) ]
      o += seg * 2 + 2
      let start_count = [ for i in 0..<seg => u16(d, o + i * 2) ]
      o += seg * 2
      let id_delta = [ for i in 0..<seg => i16(d, o + i * 2) ]
      o += seg * 2
      let id_range = [ for i in 0..<seg => u16(d, o + i * 2) ]
      o += seg * 2
      let n = (off + length - o) >> 1
      let glyph_ids = [ for i in 0..<n.max(0) => u16(d, o + i * 2) ]
      Format4(end_count, start_count, id_delta, id_range, glyph_ids)
    }
    6 => {
      let first = u16(d, off + 6)
      let count = u16(d, off + 8)
      Format6(first, [ for i in 0..<count => u16(d, off + 10 + i * 2) ])
    }
    12 => {
      let n = u32(d, off + 12).to_int() * 3
      Format12([ for i in 0..<n => u32(d, off + 16 + i * 4) ])
    }
    _ => Unsupported
  }
}

///|
fn read_kern_format0(d : Bytes, off : Int32, map : KernPairs) -> Int32 {
  let n = u16(d, off)
  let mut o = off + 8
  let mut pleft = -1
  for _ in 0..<n {
    let left = u16(d, o)
    let right = u16(d, o + 2)
    let value = i16(d, o + 4)
    o += 6
    if left != pleft {
      map.glyph1.push(left)
      map.rval.push(([], []))
    }
    let (g2, vals) = map.rval[map.rval.length() - 1]
    g2.push(right)
    vals.push(value)
    pleft = left
  }
  o
}

///|
fn parse_kern(d : Bytes, off : Int32) -> KernPairs {
  let map : KernPairs = { glyph1: [], rval: [], }
  if u16(d, off) == 1 {
    let n = u32(d, off + 4).to_int()
    let mut o = off + 8
    for _ in 0..<n {
      o += 4
      let coverage = u16(d, o)
      o += 4
      if (coverage & 0xff) == 0 {
        o = read_kern_format0(d, o, map)
      }
    }
  } else {
    let n = u16(d, off + 2)
    let mut o = off + 4
    for _ in 0..<n {
      o += 4
      let coverage = u16(d, o)
      o += 2
      if ((coverage >> 8) & 0xf) == 0 {
        o = read_kern_format0(d, o, map)
      }
    }
  }
  map
}

///|
/// Parses a TrueType/OpenType font (the first font of a collection).
/// WOFF 1.0 data is decompressed first; WOFF2 is not supported.
pub fn FontData::parse(input : Bytes) -> FontData raise FontError {
  let data = if ascii(input, 0, 4) == "wOFF" {
    woff_to_sfnt(input)
  } else {
    input
  }
  let tag = ascii(data, 0, 4)
  let foff = if tag == "ttcf" { u32(data, 12).to_int() } else { 0 }
  if tag == "wOF2" {
    raise FontError("WOFF2 fonts are not supported")
  }
  guard find_table(data, "head", foff) is Some((head, _)) else {
    raise FontError("not a TrueType/OpenType font (no head table)")
  }
  let units_per_em = u16(data, head + 18)
  let index_to_loc = i16(data, head + 50)
  guard find_table(data, "maxp", foff) is Some((maxp, _)) else {
    raise FontError("no maxp table")
  }
  let num_glyphs = u16(data, maxp + 4)
  let (ascender, descender, num_hmetrics) = match
    find_table(data, "hhea", foff) {
    Some((hhea, _)) =>
      (i16(data, hhea + 4), i16(data, hhea + 6), u16(data, hhea + 34))
    None => (0, 0, 0)
  }
  let advance : Array[Int32] = []
  if find_table(data, "hmtx", foff) is Some((hmtx, _)) {
    let mut aw = 0
    for i in 0..<num_glyphs {
      if i < num_hmetrics {
        aw = u16(data, hmtx + i * 4)
      }
      advance.push(aw)
    }
  }
  let cmap = match find_table(data, "cmap", foff) {
    Some((off, _)) => parse_cmap(data, off)
    None => Unsupported
  }
  let loca : Array[Double] = []
  if find_table(data, "loca", foff) is Some((off, _)) {
    for i in 0..<=num_glyphs {
      loca.push(
        if index_to_loc == 0 {
          (u16(data, off + i * 2) * 2).to_double()
        } else {
          u32(data, off + i * 4)
        },
      )
    }
  }
  let glyf_offset = find_table(data, "glyf", foff).map(t => t.0)
  let cff = match find_table(data, "CFF ", foff) {
    Some((off, len)) => Some(parse_cff(data, off, len))
    None => None
  }
  let kern = find_table(data, "kern", foff).map(t => parse_kern(data, t.0))
  {
    data,
    units_per_em,
    ascender,
    descender,
    num_glyphs,
    advance,
    cmap,
    loca,
    glyf_offset,
    cff,
    kern,
    glyph_cache: Map([]),
  }
}

///|
/// Typr's `arrSearch`: binary search over every `k`-th element.
fn arr_search(arr : Array[Double], k : Int32, v : Double) -> Int32 {
  let mut l = 0
  let mut r = arr.length() / k
  while l + 1 != r {
    let mid = l + ((r - l) >> 1)
    if arr[mid * k] <= v {
      l = mid
    } else {
      r = mid
    }
  }
  l * k
}

///|
fn is_whitespace_code(code : Int32) -> Bool {
  [
    0x9, 0xa, 0xb, 0xc, 0xd, 0x20, 0x85, 0xa0, 0x1680, 0x180e, 0x2028, 0x2029, 0x202f,
    0x2060, 0x3000, 0xfeff,
  ].contains(code) ||
  (code >= 0x2000 && code <= 0x200d)
}

///|
/// The glyph index for a Unicode code point (Typr's `codeToGlyph`).
pub fn FontData::code_to_glyph(self : FontData, code : Int32) -> Int32 {
  let gid = match self.cmap {
    Format0(map) => map.get(code).unwrap_or(0)
    Format4(ec, sc, delta, range, ids) => {
      let mut gid = 0
      if ec.length() > 0 && code <= ec[ec.length() - 1] {
        let ecd = ec.map(v => v.to_double())
        let mut sind = arr_search(ecd, 1, code.to_double())
        if ec[sind] < code {
          sind += 1
        }
        if code >= sc[sind] {
          let gli = if range[sind] != 0 {
            ids
            .get(code - sc[sind] + (range[sind] >> 1) - (range.length() - sind))
            .unwrap_or(0)
          } else {
            code + delta[sind]
          }
          gid = gli & 0xffff
        }
      }
      gid
    }
    Format6(first, arr) => {
      let off = code - first
      if off < 0 || off >= arr.length() {
        0
      } else {
        arr[off]
      }
    }
    Format12(grp) => {
      let mut gid = 0
      if grp.length() >= 3 && code.to_double() <= grp[grp.length() - 2] {
        let i = arr_search(grp, 3, code.to_double())
        if grp[i] <= code.to_double() && code.to_double() <= grp[i + 1] {
          gid = (grp[i + 2] + (code.to_double() - grp[i])).to_int()
        }
      }
      gid
    }
    Unsupported => 0
  }
  if gid != 0 &&
    self.cff is None &&
    self.loca.length() > gid + 1 &&
    self.loca[gid] == self.loca[gid + 1] &&
    !is_whitespace_code(code) {
    0
  } else {
    gid
  }
}

///|
/// Advance width of a glyph, in font units.
pub fn FontData::advance_width(self : FontData, gid : Int32) -> Int32 {
  self.advance.get(gid).unwrap_or(0)
}

///|
/// Kerning between two glyphs from the `kern` table (font units).
pub fn FontData::kerning(self : FontData, g1 : Int32, g2 : Int32) -> Int32 {
  guard self.kern is Some(k) else { return 0 }
  match k.glyph1.search(g1) {
    Some(i) => {
      let (g2s, vals) = k.rval[i]
      match g2s.search(g2) {
        Some(j) => vals[j]
        None => 0
      }
    }
    None => 0
  }
}

///|
/// A positioned glyph from `shape`.
#derive(Debug)
pub(all) struct ShapedGlyph {
  glyph : Int32
  /// Advance in font units, kerning included.
  advance : Int32
}

///|
/// Maps a string to glyphs and advances (Typr's `U.shape`: cmap, `hmtx`
/// advances and `kern` pairs).
pub fn FontData::shape(self : FontData, text : String) -> Array[ShapedGlyph] {
  let gls = [ for c in text => self.code_to_glyph(c.to_int()) ]
  let out : Array[ShapedGlyph] = []
  for i, g in gls {
    let next = gls.get(i + 1).unwrap_or(-1)
    out.push({
      glyph: g,
      advance: self.advance_width(g) + self.kerning(g, next),
    })
  }
  out
}
