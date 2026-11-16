// Reference values come from running gifenc and omggif (the libraries p5.js
// uses) on the same input under Node.

///|
fn test_image() -> FixedArray[Byte] {
  let (w, h) = (32, 24)
  let px = FixedArray::make(w * h * 4, (0 : Byte))
  for y in 0..<h {
    for x in 0..<w {
      let i = (y * w + x) * 4
      px[i] = ((x * 8) & 255).to_byte()
      px[i + 1] = ((y * 10) & 255).to_byte()
      px[i + 2] = ((x * y * 3) & 255).to_byte()
      px[i + 3] = (if y > 18 { 60 } else { 255 }).to_byte()
    }
  }
  px
}

///|
fn hash(bytes : Iter[Byte]) -> UInt32 {
  let mut h : UInt32 = 0
  for b in bytes {
    h = h * 31 + b.to_uint()
  }
  h
}

///|
test "quantize matches gifenc" {
  let pal = @gif.quantize(test_image(), 16, format=Rgba4444, one_bit_alpha=127)
  debug_inspect(
    pal,
    content=(
      #|[
      #|  [0, 0, 0, 0],
      #|  [182, 181, 52, 255],
      #|  [86, 187, 97, 255],
      #|  [34, 168, 145, 255],
      #|  [141, 186, 199, 255],
      #|  [71, 178, 223, 255],
      #|  [219, 147, 221, 255],
      #|  [22, 54, 27, 255],
      #|  [136, 15, 31, 255],
      #|  [199, 71, 49, 255],
      #|  [94, 107, 56, 255],
      #|  [89, 51, 114, 255],
      #|  [205, 113, 130, 255],
      #|  [110, 90, 196, 255],
      #|  [208, 54, 194, 255],
      #|]
    ),
  )
  let pal2 = @gif.quantize(test_image(), 64)
  inspect(pal2.length(), content="64")
  debug_inspect(
    pal2[:4],
    content=(
      #|<ArrayView: [[20, 9, 7], [17, 47, 29], [3, 91, 10], [0, 180, 0]]>
    ),
  )
}

///|
test "encoder output is byte-identical to gifenc, and decodes like omggif" {
  let img = test_image()
  let pal = @gif.quantize(img, 16, format=Rgba4444, one_bit_alpha=127)
  let index = @gif.apply_palette(img, pal, format=Rgba4444)
  let enc = @gif.Encoder::new()
  enc.write_frame(index, 32, 24, palette=pal, delay=50, dispose=1)
  let index2 = index.map(v => ((v.to_int() + 1) % pal.length()).to_byte())
  enc.write_frame(
    index2,
    32,
    24,
    delay=50,
    transparent=true,
    transparent_index=pal.length() - 1,
    dispose=1,
  )
  let bytes = enc.finish()
  inspect(bytes.length(), content="767")
  inspect(hash(bytes.iter()), content="3469709366")
  let reader = @gif.Reader::new(bytes)
  let px = FixedArray::make(32 * 24 * 4, (0 : Byte))
  reader.blit_frame_rgba(1, px)
  inspect(reader.frames.length(), content="2")
  debug_inspect(reader.loop_count, content="Some(0)")
  inspect(hash(px.iter()), content="2053019396")
  let f = reader.frames[1]
  debug_inspect(
    (
      f.palette_offset,
      f.palette_size,
      f.data_offset,
      f.transparent_index,
      f.delay,
      f.disposal,
    ),
    content="(13, 16, 441, Some(14), 5, 1)",
  )
}

///|
test "invalid gifs raise" {
  try @gif.Reader::new(b"not a gif") catch {
    @gif.GifError(msg) => inspect(msg, content="Invalid GIF 87a/89a header.")
  } noraise {
    _ => fail("expected an error")
  }
}
