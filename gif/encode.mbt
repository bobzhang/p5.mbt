// Port of gifenc's GIFEncoder and lzwEncode.js (MIT). The LZW coder goes
// back to Kevin Weiner's Java LZWEncoder and GIFCOMPR.C.

///|
const BITS : Int32 = 12

///|
const HSIZE : Int32 = 5003

///|
let masks : FixedArray[Int32] = [
  0x0000, 0x0001, 0x0003, 0x0007, 0x000f, 0x001f, 0x003f, 0x007f, 0x00ff, 0x01ff,
  0x03ff, 0x07ff, 0x0fff, 0x1fff, 0x3fff, 0x7fff, 0xffff,
]

///|
/// An animated GIF being written.
pub struct Encoder {
  priv out : Array[Byte]
  priv mut has_init : Bool
}

///|
/// Creates an encoder.
pub fn Encoder::new() -> Encoder {
  { out: [], has_init: false, }
}

///|
fn Encoder::byte(self : Encoder, b : Int32) -> Unit {
  self.out.push((b & 0xff).to_byte())
}

///|
fn Encoder::u16(self : Encoder, v : Int32) -> Unit {
  self.byte(v & 0xff)
  self.byte((v >> 8) & 0xff)
}

///|
fn Encoder::ascii(self : Encoder, s : String) -> Unit {
  for c in s {
    self.byte(c.to_int())
  }
}

///|
fn color_table_size(length : Int32) -> Int32 {
  @cmath.log2(length.to_double()).ceil().to_int().max(1)
}

///|
fn Encoder::color_table(
  self : Encoder,
  palette : ArrayView[Array[Int32]],
) -> Unit {
  let n = 1 << color_table_size(palette.length())
  for i in 0..<n {
    if i < palette.length() {
      let c = palette[i]
      self.byte(c[0])
      self.byte(c[1])
      self.byte(c[2])
    } else {
      self.byte(0)
      self.byte(0)
      self.byte(0)
    }
  }
}

///|
/// Appends a frame of palette indices (`width × height`). The first frame
/// must carry the (global) palette; later frames may carry a local one.
/// `delay` is in milliseconds; `repeat` is -1 (once), 0 (forever) or a
/// count; `dispose` overrides the disposal method when >= 0.
pub fn Encoder::write_frame(
  self : Encoder,
  index : FixedArray[Byte],
  width : Int32,
  height : Int32,
  palette? : Array[Array[Int32]],
  delay~ : Double = 0,
  transparent~ : Bool = false,
  transparent_index~ : Int32 = 0,
  repeat~ : Int32 = 0,
  color_depth~ : Int32 = 8,
  dispose~ : Int32 = -1,
) -> Unit {
  let first = !self.has_init
  if first {
    self.ascii("GIF89a")
    self.has_init = true
    guard palette is Some(pal) else {
      abort("First frame must include a palette")
    }
    // logical screen descriptor
    self.u16(width)
    self.u16(height)
    self.byte(
      (1 << 7) | ((color_depth - 1) << 4) | (color_table_size(pal.length()) - 1),
    )
    self.byte(0)
    self.byte(0)
    self.color_table(pal)
    if repeat >= 0 {
      self.byte(0x21)
      self.byte(0xff)
      self.byte(11)
      self.ascii("NETSCAPE2.0")
      self.byte(3)
      self.byte(1)
      self.u16(repeat)
      self.byte(0)
    }
  }
  // graphic control extension
  let delay_time = (delay / 10 + 0.5).floor().to_int()
  let (transparent, transparent_index) = if transparent_index < 0 {
    (false, 0)
  } else {
    (transparent, transparent_index)
  }
  let mut disp = if transparent { 2 } else { 0 }
  if dispose >= 0 {
    disp = dispose & 7
  }
  self.byte(0x21)
  self.byte(0xf9)
  self.byte(4)
  self.byte((disp << 2) | (if transparent { 1 } else { 0 }))
  self.u16(delay_time)
  self.byte(transparent_index)
  self.byte(0)
  // image descriptor
  let local_palette = if first { None } else { palette }
  self.byte(0x2c)
  self.u16(0)
  self.u16(0)
  self.u16(width)
  self.u16(height)
  match local_palette {
    Some(pal) => {
      self.byte(0x80 | (color_table_size(pal.length()) - 1))
      self.color_table(pal)
    }
    None => self.byte(0)
  }
  self.lzw(index, color_depth)
}

///|
/// Writes the trailer and returns the file contents.
pub fn Encoder::finish(self : Encoder) -> Bytes {
  self.byte(0x3b)
  Bytes::from_array(self.out)
}

///|
fn Encoder::lzw(
  self : Encoder,
  pixels : FixedArray[Byte],
  color_depth : Int32,
) -> Unit {
  let accum = FixedArray::make(256, (0 : Byte))
  let htab = FixedArray::make(HSIZE, -1)
  let codetab = FixedArray::make(HSIZE, 0)
  let init_code_size = color_depth.max(2)
  let mut cur_accum = 0
  let mut cur_bits = 0
  let init_bits = init_code_size + 1
  let mut clear_flg = false
  let mut n_bits = init_bits
  let mut maxcode = (1 << n_bits) - 1
  let clear_code = 1 << (init_bits - 1)
  let eof_code = clear_code + 1
  let mut free_ent = clear_code + 2
  let mut a_count = 0
  let mut hshift = 0
  let mut fcode = HSIZE
  while fcode < 65536 {
    hshift += 1
    fcode *= 2
  }
  hshift = 8 - hshift
  self.byte(init_code_size)
  let flush = () => {
    self.byte(a_count)
    for k in 0..<a_count {
      self.out.push(accum[k])
    }
    a_count = 0
  }
  let output = (code : Int32) => {
    cur_accum = cur_accum & masks[cur_bits]
    if cur_bits > 0 {
      cur_accum = cur_accum | (code << cur_bits)
    } else {
      cur_accum = code
    }
    cur_bits += n_bits
    while cur_bits >= 8 {
      accum[a_count] = (cur_accum & 0xff).to_byte()
      a_count += 1
      if a_count >= 254 {
        flush()
      }
      cur_accum = cur_accum >> 8
      cur_bits -= 8
    }
    if free_ent > maxcode || clear_flg {
      if clear_flg {
        n_bits = init_bits
        maxcode = (1 << n_bits) - 1
        clear_flg = false
      } else {
        n_bits += 1
        maxcode = if n_bits == BITS { 1 << n_bits } else { (1 << n_bits) - 1 }
      }
    }
    if code == eof_code {
      while cur_bits > 0 {
        accum[a_count] = (cur_accum & 0xff).to_byte()
        a_count += 1
        if a_count >= 254 {
          flush()
        }
        cur_accum = cur_accum >> 8
        cur_bits -= 8
      }
      if a_count > 0 {
        flush()
      }
    }
  }
  output(clear_code)
  let mut ent = pixels[0].to_int()
  for idx in 1..<pixels.length() {
    let c = pixels[idx].to_int()
    let fc = (c << BITS) + ent
    let mut i = (c << hshift) ^ ent
    let mut found = false
    if htab[i] == fc {
      ent = codetab[i]
      found = true
    } else {
      let disp = if i == 0 { 1 } else { HSIZE - i }
      while htab[i] >= 0 {
        i -= disp
        if i < 0 {
          i += HSIZE
        }
        if htab[i] == fc {
          ent = codetab[i]
          found = true
          break
        }
      }
    }
    if !found {
      output(ent)
      ent = c
      if free_ent < 1 << BITS {
        codetab[i] = free_ent
        free_ent += 1
        htab[i] = fc
      } else {
        htab.fill(-1)
        free_ent = clear_code + 2
        clear_flg = true
        output(clear_code)
      }
    }
  }
  output(ent)
  output(eof_code)
  self.byte(0)
}
