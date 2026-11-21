///|
test "sum_squares" {
  assert_eq(sum_squares(0), 0)
  assert_eq(sum_squares(3), 14)
  assert_eq(sum_squares(10), 385)
}

///|
test "checksum" {
  assert_eq(checksum(b""), 0)
  assert_eq(checksum(b"\x01\x02\x03"), 6)
  assert_eq(checksum(Bytes::make(300, b'\xFF')), (300 * 255) & 0xFFFF)
}

///|
test "area" {
  assert_eq(area(Rect(2, 3)), 6)
  assert_true((area(Circle(1)) - 3.14).abs() < 1.0e-12)
}

///|
test "find" {
  assert_eq(find([4, 5, 6], 5), Some(1))
  assert_eq(find([4, 5, 6], 7), None)
  assert_eq(find([], 1), None)
}
