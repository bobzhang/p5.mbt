// CFF (Compact Font Format) parsing, a port of Typr.js's `T.CFF`.

///|
/// A value from a CFF DICT: a number, or an array of them.
priv enum DictVal {
  Num(Double)
  Arr(Array[Double])
}

///|
priv struct Subrs {
  items : Array[Bytes]
  bias : Int32
}

///|
priv struct PrivateDict {
  subrs : Subrs?
}

///|
priv struct Cff {
  char_strings : Array[Bytes]
  gsubrs : Subrs
  private_dict : PrivateDict?
  // CID-keyed fonts
  fd_array : Array[PrivateDict?]
  fd_select : Array[Int32]?
  // glyph id -> SID; -1 for .notdef
  charset : Array[Int32]
}

///|
fn DictVal::first(self : DictVal) -> Double {
  match self {
    Num(v) => v
    Arr(a) => a.get(0).unwrap_or(0)
  }
}

///|
fn DictVal::at(self : DictVal, i : Int32) -> Double {
  match self {
    Num(v) => if i == 0 { v } else { 0 }
    Arr(a) => a.get(i).unwrap_or(0)
  }
}

///|
/// Reads an INDEX into `inds` and returns the offset its data is relative
/// to (`readIndex`).
fn read_index(d : Bytes, offset : Int32, inds : Array[Int32]) -> Int32 {
  let count = u16(d, offset) + 1
  let mut o = offset + 2
  let offsize = u8(d, o)
  o += 1
  match offsize {
    1 =>
      for i in 0..<count {
        inds.push(u8(d, o + i))
      }
    2 =>
      for i in 0..<count {
        inds.push(u16(d, o + i * 2))
      }
    3 =>
      for i in 0..<count {
        inds.push(
          (u8(d, o + i * 3) << 16) |
          (u8(d, o + i * 3 + 1) << 8) |
          u8(d, o + i * 3 + 2),
        )
      }
    4 =>
      for i in 0..<count {
        inds.push(u32(d, o + i * 4).to_int())
      }
    _ => ()
  }
  o += count * offsize
  o - 1
}

///|
fn read_bytes(d : Bytes, offset : Int32) -> Array[Bytes] {
  let arr : Array[Int32] = []
  let o = read_index(d, offset, arr)
  let out : Array[Bytes] = []
  for i in 0..<(arr.length() - 1) {
    let s = (o + arr[i]).clamp(min=0, max=d.length())
    let e = (o + arr[i + 1]).clamp(min=s, max=d.length())
    out.push(d[s:e].to_owned())
  }
  out
}

///|
fn read_subrs(d : Bytes, offset : Int32) -> Subrs {
  let items = read_bytes(d, offset)
  let n = items.length() + 1
  let bias = if n < 1240 { 107 } else if n < 33900 { 1131 } else { 32768 }
  { items, bias, }
}

///|
let dict_keys : Array[String] = [
  "version", "Notice", "FullName", "FamilyName", "Weight", "FontBBox", "BlueValues",
  "OtherBlues", "FamilyBlues", "FamilyOtherBlues", "StdHW", "StdVW", "escape", "UniqueID",
  "XUID", "charset", "Encoding", "CharStrings", "Private", "Subrs", "defaultWidthX",
  "nominalWidthX",
]

///|
let dict_keys12 : Array[String] = [
  "Copyright", "isFixedPitch", "ItalicAngle", "UnderlinePosition", "UnderlineThickness",
  "PaintType", "CharstringType", "FontMatrix", "StrokeWidth", "BlueScale", "BlueShift",
  "BlueFuzz", "StemSnapH", "StemSnapV", "ForceBold", "", "", "LanguageGroup", "ExpansionFactor",
  "initialRandomSeed", "SyntheticBase", "PostScript", "BaseFontName", "BaseFontBlend",
  "", "", "", "", "", "", "ROS", "CIDFontVersion", "CIDFontRevision", "CIDFontType",
  "CIDCount", "UIDBase", "FDArray", "FDSelect", "FontName",
]

///|
fn read_dict(d : Bytes, offset : Int32, end : Int32) -> Map[String, DictVal] {
  let dict : Map[String, DictVal] = Map([])
  let carr : Array[Double] = []
  let mut o = offset
  while o < end {
    let b0 = u8(d, o)
    let b1 = u8(d, o + 1)
    let mut vs = 1
    let mut key : String? = None
    let mut val = @double.not_a_number
    if b0 == 28 {
      val = i16(d, o + 1).to_double()
      vs = 3
    }
    if b0 == 29 {
      val = i32(d, o + 1)
      vs = 5
    }
    if b0 >= 32 && b0 <= 246 {
      val = (b0 - 139).to_double()
    }
    if b0 >= 247 && b0 <= 250 {
      val = ((b0 - 247) * 256 + b1 + 108).to_double()
      vs = 2
    }
    if b0 >= 251 && b0 <= 254 {
      val = (-(b0 - 251) * 256 - b1 - 108).to_double()
      vs = 2
    }
    if b0 == 30 {
      // packed real
      let chars = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "e", "e-", "reserved",
        "-", "endOfNumber",
      ]
      let sb = StringBuilder()
      vs = 1
      for ;; {
        let b = u8(d, o + vs)
        vs += 1
        let n0 = b >> 4
        let n1 = b & 0xf
        if n0 != 0xf {
          sb.write_string(chars[n0])
        }
        if n1 != 0xf {
          sb.write_string(chars[n1])
        }
        if n1 == 0xf || o + vs > end {
          break
        }
      }
      val = @string.parse_double(sb.to_string()) catch {
        _ => @double.not_a_number
      }
    }
    if b0 <= 21 {
      key = dict_keys.get(b0)
      vs = 1
      if b0 == 12 {
        key = dict_keys12.get(b1)
        vs = 2
      }
    }
    match key {
      Some(k) => {
        dict[k] = if carr.length() == 1 {
          Num(carr[0])
        } else {
          Arr(carr.copy())
        }
        carr.clear()
      }
      None => carr.push(val)
    }
    o += vs
  }
  dict
}

///|
fn read_private(d : Bytes, dict : Map[String, DictVal]) -> PrivateDict? {
  guard dict.get("Private") is Some(p) else { return None }
  let size = p.at(0).to_int()
  let off = p.at(1).to_int()
  let pd = read_dict(d, off, off + size)
  let subrs = match pd.get("Subrs") {
    Some(s) => Some(read_subrs(d, off + s.first().to_int()))
    None => None
  }
  Some({ subrs, })
}

///|
fn read_charset(d : Bytes, offset : Int32, num : Int32) -> Array[Int32] {
  let charset = [-1]
  let format = u8(d, offset)
  let mut o = offset + 1
  if format == 0 {
    for _ in 0..<num {
      charset.push(u16(d, o))
      o += 2
    }
  } else if format == 1 || format == 2 {
    while charset.length() < num && o < d.length() {
      let mut first = u16(d, o)
      o += 2
      let n_left = if format == 1 {
        o += 1
        u8(d, o - 1)
      } else {
        o += 2
        u16(d, o - 2)
      }
      for _ in 0..<=n_left {
        charset.push(first)
        first += 1
      }
    }
  }
  charset
}

///|
fn parse_cff(data : Bytes, table : Int32, length : Int32) -> Cff {
  let end = (table + length).min(data.length())
  let d = data[table:end].to_owned()
  let mut offset = 4
  // Name INDEX
  let ninds : Array[Int32] = []
  offset = read_index(d, offset, ninds)
  offset += ninds.last().unwrap_or(0)
  // Top DICT INDEX
  let tdinds : Array[Int32] = []
  offset = read_index(d, offset, tdinds)
  let top = if tdinds.length() > 1 {
    read_dict(d, offset + tdinds[0], offset + tdinds[1])
  } else {
    Map([])
  }
  offset += tdinds.last().unwrap_or(0)
  // String INDEX
  let sinds : Array[Int32] = []
  offset = read_index(d, offset, sinds)
  offset += sinds.last().unwrap_or(0)
  let gsubrs = read_subrs(d, offset)
  let char_strings = match top.get("CharStrings") {
    Some(v) => read_bytes(d, v.first().to_int())
    None => []
  }
  let fd_array : Array[PrivateDict?] = []
  let mut fd_select : Array[Int32]? = None
  if top.contains("ROS") {
    let fdind : Array[Int32] = []
    let fo = read_index(
      d,
      top.get("FDArray").map(v => v.first().to_int()).unwrap_or(0),
      fdind,
    )
    for i in 0..<(fdind.length() - 1) {
      let dict = read_dict(d, fo + fdind[i], fo + fdind[i + 1])
      fd_array.push(read_private(d, dict))
    }
    let so = top.get("FDSelect").map(v => v.first().to_int()).unwrap_or(0)
    let sel : Array[Int32] = []
    if u8(d, so) == 3 {
      let rns = u16(d, so + 1)
      let mut o = so + 3
      for _ in 0..<(rns + 1) {
        sel.push(u16(d, o))
        sel.push(u8(d, o + 2))
        o += 3
      }
    }
    fd_select = Some(sel)
  }
  let charset = match top.get("charset") {
    Some(v) if v.first() != 0 =>
      read_charset(d, v.first().to_int(), char_strings.length())
    _ => []
  }
  {
    char_strings,
    gsubrs,
    private_dict: read_private(d, top),
    fd_array,
    fd_select,
    charset,
  }
}

///|
let table_se : Array[Int32] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
  40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 0,
  111, 112, 113, 114, 0, 115, 116, 117, 118, 119, 120, 121, 122, 0, 123, 0, 124,
  125, 126, 127, 128, 129, 130, 131, 0, 132, 133, 0, 134, 135, 136, 137, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 138, 0, 139, 0, 0, 0, 0, 140, 141, 142,
  143, 0, 0, 0, 0, 0, 144, 0, 0, 0, 145, 0, 0, 146, 147, 148, 149, 0, 0, 0, 0,
]

///|
/// Glyph by standard encoding (`glyphBySE`), or -1.
fn Cff::glyph_by_se(self : Cff, charcode : Int32) -> Int32 {
  if charcode < 0 || charcode > 255 {
    return -1
  }
  let sid = table_se[charcode]
  match self.charset.search(sid) {
    Some(i) => i
    None => -1
  }
}
