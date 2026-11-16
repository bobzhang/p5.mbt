// Port of omggif's GifReader (MIT, Dean McNamee), which p5.js uses to load
// animated GIFs.

///|
/// Information about one frame of a GIF.
#derive(Debug)
pub(all) struct FrameInfo {
  x : Int32
  y : Int32
  width : Int32
  height : Int32
  palette_offset : Int32
  palette_size : Int32
  data_offset : Int32
  transparent_index : Int32?
  interlaced : Bool
  /// Delay in hundredths of a second.
  delay : Int32
  disposal : Int32
}

///|
/// A parsed GIF file.
pub struct Reader {
  buf : Bytes
  width : Int32
  height : Int32
  frames : Array[FrameInfo]
  /// `None` without a NETSCAPE loop block, `Some(0)` to loop forever.
  loop_count : Int32?
}

///|
/// Errors raised while reading a GIF.
#derive(Debug)
pub suberror GifError {
  GifError(String)
}

///|
/// Parses the structure of a GIF (frames are decoded on demand).
pub fn Reader::new(buf : Bytes) -> Reader raise GifError {
  let at = (i : Int32) => if i < buf.length() { buf[i].to_int() } else { -1 }
  let mut p = 0
  if at(0) != 0x47 ||
    at(1) != 0x49 ||
    at(2) != 0x46 ||
    at(3) != 0x38 ||
    ((at(4) + 1) & 0xfd) != 0x38 ||
    at(5) != 0x61 {
    raise GifError("Invalid GIF 87a/89a header.")
  }
  p = 6
  let width = at(p) | (at(p + 1) << 8)
  let height = at(p + 2) | (at(p + 3) << 8)
  let pf0 = at(p + 4)
  p += 7
  let global_palette_flag = pf0 >> 7
  let num_global_colors = 1 << ((pf0 & 7) + 1)
  let mut global_offset = 0
  let mut global_size = 0
  if global_palette_flag != 0 {
    global_offset = p
    global_size = num_global_colors
    p += num_global_colors * 3
  }
  let frames : Array[FrameInfo] = []
  let mut delay = 0
  let mut transparent_index : Int32? = None
  let mut disposal = 0
  let mut loop_count : Int32? = None
  let skip_subblocks = () => {
    for ;; {
      let size = at(p)
      p += 1
      if size < 0 {
        return false
      }
      if size == 0 {
        return true
      }
      p += size
    }
  }
  let mut eof = false
  while !eof && p < buf.length() {
    let tag = at(p)
    p += 1
    match tag {
      0x21 => {
        let label = at(p)
        p += 1
        match label {
          0xff => {
            let netscape = at(p) == 0x0b &&
              at(p + 1) == 0x4e &&
              at(p + 2) == 0x45 &&
              at(p + 3) == 0x54 &&
              at(p + 4) == 0x53 &&
              at(p + 5) == 0x43 &&
              at(p + 6) == 0x41 &&
              at(p + 7) == 0x50 &&
              at(p + 8) == 0x45 &&
              at(p + 9) == 0x32 &&
              at(p + 10) == 0x2e &&
              at(p + 11) == 0x30 &&
              at(p + 12) == 0x03 &&
              at(p + 13) == 0x01 &&
              at(p + 16) == 0
            if netscape {
              p += 14
              loop_count = Some(at(p) | (at(p + 1) << 8))
              p += 3
            } else {
              p += 12
              if !skip_subblocks() {
                raise GifError("Invalid block size")
              }
            }
          }
          0xf9 => {
            if at(p) != 4 || at(p + 5) != 0 {
              raise GifError("Invalid graphics extension block.")
            }
            let pf1 = at(p + 1)
            delay = at(p + 2) | (at(p + 3) << 8)
            transparent_index = if (pf1 & 1) == 0 {
              None
            } else {
              Some(at(p + 4))
            }
            disposal = (pf1 >> 2) & 7
            p += 6
          }
          0xfe | 0x01 =>
            if !skip_subblocks() {
              raise GifError("Invalid block size")
            }
          _ => raise GifError("Unknown graphic control label: \{label}")
        }
      }
      0x2c => {
        let x = at(p) | (at(p + 1) << 8)
        let y = at(p + 2) | (at(p + 3) << 8)
        let w = at(p + 4) | (at(p + 5) << 8)
        let h = at(p + 6) | (at(p + 7) << 8)
        let pf2 = at(p + 8)
        p += 9
        let mut palette_offset = global_offset
        let mut palette_size = global_size
        if pf2 >> 7 != 0 {
          let n = 1 << ((pf2 & 7) + 1)
          palette_offset = p
          palette_size = n
          p += n * 3
        }
        let data_offset = p
        p += 1
        if !skip_subblocks() {
          raise GifError("Invalid block size")
        }
        frames.push({
          x,
          y,
          width: w,
          height: h,
          palette_offset,
          palette_size,
          data_offset,
          transparent_index,
          interlaced: ((pf2 >> 6) & 1) == 1,
          delay,
          disposal,
        })
      }
      0x3b => eof = true
      _ => raise GifError("Unknown gif block: \{tag}")
    }
  }
  { buf, width, height, frames, loop_count, }
}

///|
/// Decodes the LZW code stream at `p` into palette indices.
fn lzw_decode(
  code_stream : Bytes,
  p : Int32,
  output : FixedArray[Byte],
) -> Unit {
  let at = (i : Int32) => {
    if i < code_stream.length() {
      code_stream[i].to_int()
    } else {
      0
    }
  }
  let mut p = p
  let min_code_size = at(p)
  p += 1
  let clear_code = 1 << min_code_size
  let eoi_code = clear_code + 1
  let mut next_code = eoi_code + 1
  let mut cur_code_size = min_code_size + 1
  let mut code_mask = (1 << cur_code_size) - 1
  let mut cur_shift = 0
  let mut cur = 0
  let mut op = 0
  let mut subblock_size = at(p)
  p += 1
  let code_table = FixedArray::make(4096, 0)
  let mut prev_code : Int32? = None
  let output_length = output.length()
  for ;; {
    while cur_shift < 16 {
      if subblock_size == 0 {
        break
      }
      cur = cur | (at(p) << cur_shift)
      p += 1
      cur_shift += 8
      if subblock_size == 1 {
        subblock_size = at(p)
        p += 1
      } else {
        subblock_size -= 1
      }
    }
    if cur_shift < cur_code_size {
      break
    }
    let code = cur & code_mask
    cur = cur >> cur_code_size
    cur_shift -= cur_code_size
    if code == clear_code {
      next_code = eoi_code + 1
      cur_code_size = min_code_size + 1
      code_mask = (1 << cur_code_size) - 1
      prev_code = None
      continue
    } else if code == eoi_code {
      break
    }
    let chase_code = if code < next_code {
      code
    } else {
      prev_code.unwrap_or(0)
    }
    let mut chase_length = 0
    let mut chase = chase_code
    while chase > clear_code {
      chase = code_table[chase] >> 8
      chase_length += 1
    }
    let k = chase
    let op_end = op + chase_length + (if chase_code != code { 1 } else { 0 })
    if op_end > output_length {
      return
    }
    output[op] = k.to_byte()
    op += 1
    op += chase_length
    let mut b = op
    if chase_code != code {
      output[op] = k.to_byte()
      op += 1
    }
    chase = chase_code
    while chase_length > 0 {
      chase_length -= 1
      chase = code_table[chase]
      b -= 1
      output[b] = (chase & 0xff).to_byte()
      chase = chase >> 8
    }
    if prev_code is Some(prev) && next_code < 4096 {
      code_table[next_code] = (prev << 8) | k
      next_code += 1
      if next_code >= code_mask + 1 && cur_code_size < 12 {
        cur_code_size += 1
        code_mask = (code_mask << 1) | 1
      }
    }
    prev_code = Some(code)
  }
}

///|
/// Decodes frame `n` onto `pixels` (RGBA, `width × height` of the whole
/// GIF). Transparent pixels are left unchanged.
pub fn Reader::blit_frame_rgba(
  self : Reader,
  n : Int32,
  pixels : FixedArray[Byte],
) -> Unit {
  let frame = self.frames[n]
  let num_pixels = frame.width * frame.height
  let index_stream = FixedArray::make(num_pixels, (0 : Byte))
  lzw_decode(self.buf, frame.data_offset, index_stream)
  let trans = frame.transparent_index.unwrap_or(256)
  let width = self.width
  let framewidth = frame.width
  let framestride = width - framewidth
  let mut xleft = framewidth
  let opbeg = (frame.y * width + frame.x) * 4
  let opend = ((frame.y + frame.height) * width + frame.x) * 4
  let mut op = opbeg
  let mut scanstride = framestride * 4
  if frame.interlaced {
    scanstride += width * 4 * 7
  }
  let mut interlaceskip = 8
  for i in 0..<num_pixels {
    let index = index_stream[i].to_int()
    if xleft == 0 {
      op += scanstride
      xleft = framewidth
      if op >= opend {
        scanstride = framestride * 4 + width * 4 * (interlaceskip - 1)
        op = opbeg + (framewidth + framestride) * (interlaceskip << 1)
        interlaceskip = interlaceskip >> 1
      }
    }
    if index == trans {
      op += 4
    } else {
      let po = frame.palette_offset + index * 3
      if op + 3 < pixels.length() && po + 2 < self.buf.length() {
        pixels[op] = self.buf[po]
        pixels[op + 1] = self.buf[po + 1]
        pixels[op + 2] = self.buf[po + 2]
        pixels[op + 3] = 255
      }
      op += 4
    }
    xleft -= 1
  }
}
