// Port of p5.js src/utilities/{utility_functions,conversion,time_date}.js
// and src/data/local_storage.js (string values).

///|
/// Splits a number string at its decimal point.
fn split_dot(s : String) -> (String, String?) {
  let parts = [ for p in s.split(".") => p.to_owned() ]
  match parts {
    [a, b] => (a, Some(b))
    _ => (s, None)
  }
}

///|
fn pad_start(s : String, width : Int32, ch : Char) -> String {
  let n = width - s.length()
  if n <= 0 {
    s
  } else {
    String::make(n, ch) + s
  }
}

///|
/// Formats a number with at least `left` digits before the decimal point
/// (zero-padded) and, when given, exactly `right` digits after it.
///
/// ```mbt check
/// test {
///   inspect(@p5.nf(42, left=4), content="0042")
///   inspect(@p5.nf(3.14159, left=2, right=2), content="03.14")
///   inspect(@p5.nf(-7.5, left=3), content="-007.5")
/// }
/// ```
pub fn nf(num : Double, left~ : Int32 = 0, right? : Int32) -> String {
  let negative = num < 0
  let abs = num.abs()
  let s = match right {
    None => @dom.number_to_string(abs)
    Some(r) => @dom.number_to_fixed(abs, r)
  }
  let (int_part, frac) = split_dot(s)
  let int_part = pad_start(int_part, left, '0')
  let result = match frac {
    Some(f) => int_part + "." + f
    None => int_part
  }
  if negative {
    "-" + result
  } else {
    result
  }
}

///|
/// Formats a number with commas between groups of thousands and, when
/// given, `right` digits after the decimal point (truncated or padded).
///
/// ```mbt check
/// test {
///   inspect(@p5.nfc(1234567.891, right=2), content="1,234,567.89")
///   inspect(@p5.nfc(1000), content="1,000")
/// }
/// ```
pub fn nfc(num : Double, right? : Int32) -> String {
  let s = @dom.number_to_string(num)
  let (n, frac) = split_dot(s)
  let (rem, has_dot) = match frac {
    Some(f) => ("." + f, true)
    None => ("", false)
  }
  // insert commas
  let negative = n.has_prefix("-")
  let digits = if negative { n.replace(old="-", new="") } else { n }
  let sb = StringBuilder()
  let len = digits.length()
  for i, c in digits.to_array() {
    if i > 0 && (len - i) % 3 == 0 {
      sb.write_char(',')
    }
    sb.write_char(c)
  }
  let grouped = (if negative { "-" } else { "" }) + sb.to_string()
  let rem = match right {
    None => rem
    Some(0) => ""
    Some(r) =>
      if r > rem.length() {
        let base = if has_dot { rem } else { rem + "." }
        base + String::make(r - base.length() + 1, '0')
      } else {
        String::from_array(rem.to_array()[:r + 1])
      }
  }
  grouped + rem
}

///|
/// Like `nf`, but adds a `+` in front of positive numbers.
pub fn nfp(num : Double, left~ : Int32 = 0, right? : Int32) -> String {
  let s = nf(num, left~, right?)
  if num > 0 {
    "+" + s
  } else {
    s
  }
}

///|
/// Like `nf`, but adds a space in front of non-negative numbers so they
/// line up with negative ones.
pub fn nfs(num : Double, left~ : Int32 = 0, right? : Int32) -> String {
  let s = nf(num, left~, right?)
  if num >= 0 {
    " " + s
  } else {
    s
  }
}

///|
/// Splits a string at any of the characters in `delims` (whitespace by
/// default), dropping empty tokens.
///
/// ```mbt check
/// test {
///   debug_inspect(
///     @p5.split_tokens("a, b,,c", delims=", "),
///     content=(
///       #|["a", "b", "c"]
///     ),
///   )
/// }
/// ```
pub fn split_tokens(
  s : String,
  delims~ : String = " \t\n\r\u{0c}",
) -> Array[String] {
  let out : Array[String] = []
  let cur = StringBuilder()
  for c in s {
    if delims.contains_char(c) {
      if !cur.is_empty() {
        out.push(cur.to_string())
        cur.reset()
      }
    } else {
      cur.write_char(c)
    }
  }
  if !cur.is_empty() {
    out.push(cur.to_string())
  }
  out
}

///|
/// Returns a shuffled copy of `arr` (Fisher-Yates with the sketch's random
/// generator, like p5's `shuffle`).
pub fn[T] P5::shuffle(self : P5, arr : ArrayView[T]) -> Array[T] {
  let a = arr.to_owned()
  let mut idx = a.length()
  while idx > 1 {
    let rnd = (self.rng.next() * idx.to_double()).floor().to_int()
    idx -= 1
    let tmp = a[idx]
    a[idx] = a[rnd]
    a[rnd] = tmp
  }
  a
}

///|
/// Hexadecimal representation (uppercase, `digits` long, two's complement
/// for negative numbers).
///
/// ```mbt check
/// test {
///   inspect(@p5.hex(255, digits=2), content="FF")
///   inspect(@p5.hex(-1), content="FFFFFFFF")
///   inspect(@p5.unhex("ff"), content="255")
/// }
/// ```
pub fn hex(n : Int32, digits~ : Int32 = 8) -> String {
  let u = n.reinterpret_as_uint()
  let sb = StringBuilder()
  let hexd = "0123456789ABCDEF"
  for i = 7; i >= 0; i = i - 1 {
    sb.write_char(
      hexd.get_char(((u >> (i * 4)) & 0xF).reinterpret_as_int()).unwrap(),
    )
  }
  let full = sb.to_string()
  if digits >= 8 {
    pad_start(full, digits, '0')
  } else {
    String::from_array(full.to_array()[8 - digits.max(0):])
  }
}

///|
/// Parses a hexadecimal string (returns 0 when invalid).
pub fn unhex(s : String) -> Int32 {
  @string.parse_int(s, base=16) catch {
    _ => 0
  }
}

///|
/// Binary representation, `digits` long (8 by default).
pub fn binary(n : Int32, digits~ : Int32 = 8) -> String {
  let u = n.reinterpret_as_uint()
  let sb = StringBuilder()
  for i = 31; i >= 0; i = i - 1 {
    sb.write_char(if ((u >> i) & 1) == 1 { '1' } else { '0' })
  }
  let full = sb.to_string()
  if digits >= 32 {
    pad_start(full, digits, '0')
  } else {
    String::from_array(full.to_array()[32 - digits.max(0):])
  }
}

///|
/// Parses a binary string (returns 0 when invalid).
pub fn unbinary(s : String) -> Int32 {
  @string.parse_int(s, base=2) catch {
    _ => 0
  }
}

///|
/// The current year.
pub fn year() -> Int32 {
  @dom.date_part(0)
}

///|
/// The current month (1-12).
pub fn month() -> Int32 {
  @dom.date_part(1)
}

///|
/// The current day of the month (1-31).
pub fn day() -> Int32 {
  @dom.date_part(2)
}

///|
/// The current hour (0-23).
pub fn hour() -> Int32 {
  @dom.date_part(3)
}

///|
/// The current minute (0-59).
pub fn minute() -> Int32 {
  @dom.date_part(4)
}

///|
/// The current second (0-59).
pub fn second() -> Int32 {
  @dom.date_part(5)
}

///|
/// Saves a string in the browser's local storage.
pub fn store_item(key : String, value : String) -> Unit {
  @dom.storage_set(key, value)
}

///|
/// Reads a string from local storage (`None` when missing).
pub fn get_item(key : String) -> String? {
  let v = @dom.storage_get(key)
  if v == "" {
    None
  } else {
    Some(v)
  }
}

///|
/// Removes an item from local storage.
pub fn remove_item(key : String) -> Unit {
  @dom.storage_remove(key)
}

///|
/// Clears local storage.
pub fn clear_storage() -> Unit {
  @dom.storage_clear()
}
