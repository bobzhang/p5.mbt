///|
fn px(values : Array[Int32]) -> FixedArray[Byte] {
  FixedArray::from_array(values.map(v => v.to_byte()))
}

///|
fn ints(p : FixedArray[Byte]) -> Array[Int32] {
  [
    for b in p => b.to_int()
  ]
}

///|
test "clamp_byte rounds like Uint8ClampedArray" {
  debug_inspect(
    [0.5, 1.5, 2.5, 254.6, -3, 300].map(v => @filters.clamp_byte(v).to_int()),
    content="[0, 2, 2, 255, 0, 255]",
  )
}

///|
test "gray, invert, opaque, posterize" {
  let p = px([255, 0, 0, 100, 10, 20, 30, 255])
  @filters.gray(p)
  debug_inspect(ints(p), content="[54, 54, 54, 100, 19, 19, 19, 255]")
  @filters.invert(p)
  debug_inspect(ints(p), content="[201, 201, 201, 100, 236, 236, 236, 255]")
  @filters.make_opaque(p)
  debug_inspect(ints(p), content="[201, 201, 201, 255, 236, 236, 236, 255]")
  let q = px([0, 100, 200, 255])
  @filters.posterize(q, levels=2)
  debug_inspect(ints(q), content="[0, 0, 255, 255]")
}

///|
test "dilate and erode" {
  // 3x1 image: dark, bright, dark.
  let p = px([0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0, 255])
  @filters.dilate(p, 3)
  debug_inspect(
    ints(p),
    content="[255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]",
  )
  let q = px([0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255])
  @filters.erode(q, 3)
  debug_inspect(
    ints(q),
    // Like p5.js, an out-of-range "up" neighbour is pixel 0, so the last
    // pixel also erodes.
    content="[0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255]",
  )
}

///|
test "blur spreads a bright pixel" {
  let p = FixedArray::make(5 * 5 * 4, (0 : Byte))
  for i in 0..<25 {
    p[i * 4 + 3] = 255
  }
  p[12 * 4] = 255
  @filters.blur(p, 5, 1)
  inspect(p[12 * 4].to_int() < 255 && p[12 * 4].to_int() > 0, content="true")
  inspect(p[11 * 4].to_int() > 0, content="true")
  inspect(p[12 * 4 + 3].to_int(), content="255")
}
