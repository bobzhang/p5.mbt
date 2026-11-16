// Port of the CSV parser/serializer bundled with p5.js (src/io/csv.js,
// MIT, Evan Plaice).

///|
/// Errors in malformed CSV.
#derive(Debug)
pub suberror CsvError {
  CsvError(String)
}

///|
priv enum Token {
  Delim
  Sep
  Newline(String)
  Text(String)
}

///|
fn lex(csv : String, delimiter : Char, separator : Char) -> Array[Token] {
  let out : Array[Token] = []
  let chars = csv.to_array()
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c == delimiter {
      out.push(Delim)
      i += 1
    } else if c == separator {
      out.push(Sep)
      i += 1
    } else if c == '\r' && i + 1 < n && chars[i + 1] == '\n' {
      out.push(Newline("\r\n"))
      i += 2
    } else if c == '\n' || c == '\r' {
      out.push(Newline(c.to_string()))
      i += 1
    } else {
      let sb = StringBuilder()
      while i < n &&
            chars[i] != delimiter &&
            chars[i] != separator &&
            chars[i] != '\r' &&
            chars[i] != '\n' {
        sb.write_char(chars[i])
        i += 1
      }
      out.push(Text(sb.to_string()))
    }
  }
  out
}

///|
/// Parses CSV into rows of fields. `delimiter` quotes fields (doubled to
/// escape it); `separator` separates them.
///
/// ```mbt check
/// test {
///   debug_inspect(
///     @io.parse_csv("a,\"b,c\",\"d\"\"e\"\n1,2,3\n"),
///     content=(
///       #|[["a", "b,c", "d\"e"], ["1", "2", "3"]]
///     ),
///   )
/// }
/// ```
pub fn parse_csv(
  csv : String,
  separator~ : Char = ',',
  delimiter~ : Char = '"',
) -> Array[Array[String]] raise CsvError {
  let output : Array[Array[String]] = []
  let mut entry : Array[String] = []
  let value = StringBuilder()
  let mut row = 1
  let mut col = 1
  let value_end = () => {
    entry.push(value.to_string())
    value.reset()
    col += 1
  }
  let entry_end = () => {
    output.push(entry)
    entry = []
    row += 1
    col = 1
  }
  let delim_str = delimiter.to_string()
  let mut state = 0
  for tok in lex(csv, delimiter, separator) {
    match (state, tok) {
      (0, Delim) => state = 3
      (0, Sep) => value_end()
      (0, Newline(_)) => {
        value_end()
        entry_end()
      }
      (0, Text(t)) => {
        value.write_string(t)
        state = 2
      }
      (2, Sep) => {
        state = 0
        value_end()
      }
      (2, Newline(_)) => {
        state = 0
        value_end()
        entry_end()
      }
      (2, _) =>
        raise CsvError("CSVError: Illegal state [row:\{row}, col:\{col}]")
      (3, Delim) => state = 4
      (3, Sep) => value.write_char(separator)
      (3, Newline(nl)) => value.write_string(nl)
      (3, Text(t)) => value.write_string(t)
      (4, Delim) => {
        state = 3
        value.write_string(delim_str)
      }
      (4, Sep) => {
        state = 0
        value_end()
      }
      (4, Newline(_)) => {
        state = 0
        value_end()
        entry_end()
      }
      _ => raise CsvError("CSVError: Illegal state [row:\{row}, col:\{col}]")
    }
  }
  if entry.length() != 0 {
    value_end()
    entry_end()
  }
  output
}

///|
/// Serializes rows as CSV, quoting fields that contain the delimiter, the
/// separator or a line break. Every row ends with `\n` (unless `eof` is
/// false, then the last one doesn't).
pub fn stringify_csv(
  rows : ArrayView[Array[String]],
  separator~ : Char = ',',
  delimiter~ : Char = '"',
  eof~ : Bool = true,
) -> String {
  let out = StringBuilder()
  let d = delimiter.to_string()
  for r, row in rows {
    for c, col in row {
      let escaped = col.replace_all(old=d, new=d + d)
      let needs = escaped.contains(d) ||
        escaped.contains_char(separator) ||
        escaped.contains("\n") ||
        escaped.contains("\r")
      if needs {
        out.write_string(d + escaped + d)
      } else {
        out.write_string(escaped)
      }
      if c != row.length() - 1 {
        out.write_char(separator)
      }
    }
    if eof || r != rows.length() - 1 {
      out.write_string("\n")
    }
  }
  out.to_string()
}
