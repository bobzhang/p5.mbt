// Big-endian readers over font data (Typr's `B`).

///|
/// Errors in font files.
#derive(Debug)
pub suberror FontError {
  FontError(String)
}

///|
fn u8(d : Bytes, p : Int32) -> Int32 {
  if p >= 0 && p < d.length() {
    d[p].to_int()
  } else {
    0
  }
}

///|
fn u16(d : Bytes, p : Int32) -> Int32 {
  (u8(d, p) << 8) | u8(d, p + 1)
}

///|
fn i16(d : Bytes, p : Int32) -> Int32 {
  let v = u16(d, p)
  if v >= 0x8000 {
    v - 0x10000
  } else {
    v
  }
}

///|
fn i8(d : Bytes, p : Int32) -> Int32 {
  let v = u8(d, p)
  if v >= 0x80 {
    v - 0x100
  } else {
    v
  }
}

///|
/// Unsigned 32-bit value as a Double (exact).
fn u32(d : Bytes, p : Int32) -> Double {
  let hi = u16(d, p).to_double()
  let lo = u16(d, p + 2).to_double()
  hi * 65536 + lo
}

///|
fn i32(d : Bytes, p : Int32) -> Double {
  let v = u32(d, p)
  if v >= 2147483648.0 {
    v - 4294967296.0
  } else {
    v
  }
}

///|
fn f2dot14(d : Bytes, p : Int32) -> Double {
  i16(d, p).to_double() / 16384.0
}

///|
fn ascii(d : Bytes, p : Int32, n : Int32) -> String {
  let sb = StringBuilder()
  for i in 0..<n {
    sb.write_char(Int32::unsafe_to_char(u8(d, p + i)))
  }
  sb.to_string()
}

///|
pub impl Show for FontError with fn output(self, logger) {
  let FontError(msg) = self
  logger.write_string("FontError: " + msg)
}
