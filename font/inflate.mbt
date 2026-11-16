// zlib/DEFLATE decompression (RFC 1950/1951), for WOFF tables.

///|
priv struct BitReader {
  data : Bytes
  mut pos : Int32
  mut bit : Int32
  mut bits : Int32
}

///|
fn BitReader::need(self : BitReader, n : Int32) -> Int32 raise FontError {
  while self.bits < n {
    if self.pos >= self.data.length() {
      raise FontError("deflate: unexpected end of data")
    }
    self.bit = self.bit | (self.data[self.pos].to_int() << self.bits)
    self.pos += 1
    self.bits += 8
  }
  let v = self.bit & ((1 << n) - 1)
  self.bit = self.bit >> n
  self.bits -= n
  v
}

///|
/// A canonical Huffman decoding table: counts per length and symbols.
priv struct Huffman {
  counts : FixedArray[Int32]
  symbols : FixedArray[Int32]
}

///|
fn Huffman::new(lengths : ArrayView[Int32]) -> Huffman {
  let counts = FixedArray::make(16, 0)
  for l in lengths {
    counts[l] += 1
  }
  counts[0] = 0
  let offs = FixedArray::make(16, 0)
  for i in 1..<16 {
    offs[i] = offs[i - 1] + counts[i - 1]
  }
  let symbols = FixedArray::make(lengths.length(), 0)
  for i, l in lengths {
    if l != 0 {
      symbols[offs[l]] = i
      offs[l] += 1
    }
  }
  { counts, symbols, }
}

///|
fn BitReader::decode(self : BitReader, h : Huffman) -> Int32 raise FontError {
  let mut code = 0
  let mut first = 0
  let mut index = 0
  for len in 1..<16 {
    code = code | self.need(1)
    let count = h.counts[len]
    if code - count < first {
      return h.symbols[index + (code - first)]
    }
    index += count
    first += count
    first = first << 1
    code = code << 1
  }
  raise FontError("deflate: bad Huffman code")
}

///|
let len_base : Array[Int32] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83,
  99, 115, 131, 163, 195, 227, 258,
]

///|
let len_extra : Array[Int32] = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,
  5, 0,
]

///|
let dist_base : Array[Int32] = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
  1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
]

///|
let dist_extra : Array[Int32] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]

///|
fn BitReader::codes(
  self : BitReader,
  out : Array[Byte],
  lit : Huffman,
  dist : Huffman,
) -> Unit raise FontError {
  for ;; {
    let sym = self.decode(lit)
    if sym < 256 {
      out.push(sym.to_byte())
    } else if sym == 256 {
      return
    } else {
      let s = sym - 257
      if s >= 29 {
        raise FontError("deflate: bad length symbol")
      }
      let len = len_base[s] + self.need(len_extra[s])
      let ds = self.decode(dist)
      if ds >= 30 {
        raise FontError("deflate: bad distance symbol")
      }
      let d = dist_base[ds] + self.need(dist_extra[ds])
      if d > out.length() {
        raise FontError("deflate: distance too far back")
      }
      let start = out.length() - d
      for i in 0..<len {
        out.push(out[start + i])
      }
    }
  }
}

///|
/// Decompresses zlib-wrapped (or raw, when `zlib` is false) DEFLATE data.
pub fn inflate(data : Bytes, zlib~ : Bool = true) -> Bytes raise FontError {
  let r : BitReader = { data, pos: if zlib { 2 } else { 0 }, bit: 0, bits: 0, }
  let out : Array[Byte] = []
  for ;; {
    let last = r.need(1)
    let typ = r.need(2)
    match typ {
      0 => {
        r.bit = 0
        r.bits = 0
        if r.pos + 4 > data.length() {
          raise FontError("deflate: truncated stored block")
        }
        let len = data[r.pos].to_int() | (data[r.pos + 1].to_int() << 8)
        r.pos += 4
        if r.pos + len > data.length() {
          raise FontError("deflate: truncated stored block")
        }
        for i in 0..<len {
          out.push(data[r.pos + i])
        }
        r.pos += len
      }
      1 => {
        let lengths = Array::make(288, 8)
        for i in 144..<256 {
          lengths[i] = 9
        }
        for i in 256..<280 {
          lengths[i] = 7
        }
        r.codes(out, Huffman::new(lengths), Huffman::new(Array::make(30, 5)))
      }
      2 => {
        let hlit = r.need(5) + 257
        let hdist = r.need(5) + 1
        let hclen = r.need(4) + 4
        let order = [
          16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
        ]
        let cl = Array::make(19, 0)
        for i in 0..<hclen {
          cl[order[i]] = r.need(3)
        }
        let clh = Huffman::new(cl)
        let lengths : Array[Int32] = []
        while lengths.length() < hlit + hdist {
          let sym = r.decode(clh)
          if sym < 16 {
            lengths.push(sym)
          } else {
            let (rep, v) = match sym {
              16 => {
                guard lengths.last() is Some(prev) else {
                  raise FontError("deflate: repeat with no previous length")
                }
                (3 + r.need(2), prev)
              }
              17 => (3 + r.need(3), 0)
              _ => (11 + r.need(7), 0)
            }
            for _ in 0..<rep {
              lengths.push(v)
            }
          }
        }
        r.codes(
          out,
          Huffman::new(lengths[:hlit]),
          Huffman::new(lengths[hlit:hlit + hdist]),
        )
      }
      _ => raise FontError("deflate: bad block type")
    }
    if last == 1 {
      break
    }
  }
  Bytes::from_array(out)
}

///|
/// Converts WOFF (1.0) data to an sfnt font, like Typr's `woffToOtf`.
pub fn woff_to_sfnt(data : Bytes) -> Bytes raise FontError {
  let num = u16(data, 12)
  let total = u32(data, 16).to_int()
  let otf = FixedArray::make(total, (0 : Byte))
  let put16 = (o : Int32, v : Int32) => {
    otf[o] = (v >> 8).to_byte()
    otf[o + 1] = v.to_byte()
  }
  let put32 = (o : Int32, v : Int32) => {
    put16(o, v >> 16)
    put16(o + 2, v & 0xffff)
  }
  for i, c in "OTTO" {
    otf[i] = c.to_int().to_byte()
  }
  put16(4, num)
  let mut toff = 12 + num * 16
  let mut off = 44
  for i in 0..<num {
    let tof = u32(data, off + 4).to_int()
    let clen = u32(data, off + 8).to_int()
    let olen = u32(data, off + 12).to_int()
    let to = 12 + i * 16
    for k in 0..<4 {
      otf[to + k] = data[off + k]
    }
    off += 20
    let raw = data[tof:tof + clen].to_owned()
    let tab = if clen != olen { inflate(raw) } else { raw }
    put32(to + 8, toff)
    put32(to + 12, olen)
    for k in 0..<tab.length() {
      if toff + k < total {
        otf[toff + k] = tab[k]
      }
    }
    toff += olen
  }
  Bytes::from_array(otf)
}
