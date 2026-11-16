// Port of p5.js src/io/p5.Table.js and p5.TableRow.js. Cells are strings;
// `get_num` parses them like `parseFloat`.
//
// One deliberate difference: in p5.js 2.x, setting a cell by column name
// leaves the value returned by `get(name)` stale; here every access sees
// the same cell.

///|
/// A row of a `Table`.
pub struct TableRow {
  priv arr : Array[String]
  priv mut columns : Array[String?]
}

///|
/// Creates a row from its cells.
pub fn TableRow::new(cells~ : Array[String] = []) -> TableRow {
  { arr: cells, columns: [], }
}

///|
/// A column, by index or by title.
pub(all) enum Column {
  Index(Int32)
  Title(String)
}

///|
fn index_of_title(columns : Array[String?], title : String) -> Int32 {
  match columns.search_by(c => c == Some(title)) {
    Some(i) => i
    None => -1
  }
}

///|
fn TableRow::index(self : TableRow, column : Column) -> Int32 {
  match column {
    Index(i) => i
    Title(t) => index_of_title(self.columns, t)
  }
}

///|
/// The cell in `column` (empty when out of range).
pub fn TableRow::get(self : TableRow, column : Column) -> String {
  self.arr.get(self.index(column)).unwrap_or("")
}

///|
/// The cell as a string.
pub fn TableRow::get_string(self : TableRow, column : Column) -> String {
  self.get(column)
}

///|
/// The cell parsed as a number (`parseFloat`); NaN when it isn't one.
pub fn TableRow::get_num(self : TableRow, column : Column) -> Double {
  parse_float(self.get(column))
}

///|
/// Sets a cell.
pub fn TableRow::set(self : TableRow, column : Column, value : String) -> Unit {
  let i = self.index(column)
  if i < 0 {
    return
  }
  while self.arr.length() <= i {
    self.arr.push("")
  }
  self.arr[i] = value
}

///|
/// Sets a cell to a number.
pub fn TableRow::set_num(
  self : TableRow,
  column : Column,
  value : Double,
) -> Unit {
  self.set(column, format_number(value))
}

///|
/// Sets a cell to a string.
pub fn TableRow::set_string(
  self : TableRow,
  column : Column,
  value : String,
) -> Unit {
  self.set(column, value)
}

///|
/// The cells of the row.
pub fn TableRow::cells(self : TableRow) -> Array[String] {
  self.arr
}

///|
/// JavaScript `parseFloat`: the longest numeric prefix, NaN when none.
pub fn parse_float(s : String) -> Double {
  let t = s.trim_start().to_owned()
  let chars = t.to_array()
  let mut end = 0
  let mut seen_digit = false
  let mut seen_dot = false
  let mut seen_exp = false
  let mut i = 0
  if i < chars.length() && (chars[i] == '+' || chars[i] == '-') {
    i += 1
  }
  if String::from_array(chars[i:]).has_prefix("Infinity") {
    return if chars.get(0) == Some('-') { -1.0 / 0.0 } else { 1.0 / 0.0 }
  }
  while i < chars.length() {
    let c = chars[i]
    if c >= '0' && c <= '9' {
      seen_digit = true
      i += 1
      end = i
    } else if c == '.' && !seen_dot && !seen_exp {
      seen_dot = true
      i += 1
      if seen_digit {
        end = i
      }
    } else if (c == 'e' || c == 'E') && seen_digit && !seen_exp {
      // only part of the number when followed by digits
      let mut j = i + 1
      if j < chars.length() && (chars[j] == '+' || chars[j] == '-') {
        j += 1
      }
      if j < chars.length() && chars[j] >= '0' && chars[j] <= '9' {
        seen_exp = true
        i = j
      } else {
        break
      }
    } else {
      break
    }
  }
  if !seen_digit {
    return 0.0 / 0.0
  }
  let num = String::from_array(chars[:end])
  @string.parse_double(num) catch {
    _ => 0.0 / 0.0
  }
}

///|
/// Formats a number like JavaScript's `String(n)` for common values.
fn format_number(v : Double) -> String {
  if v == v.trunc() && v.abs() < 1.0e15 {
    v.to_int64().to_string()
  } else {
    v.to_string()
  }
}

///|
/// A table of rows and titled columns (p5.Table).
pub struct Table {
  priv mut columns : Array[String?]
  priv rows : Array[TableRow]
}

///|
/// Creates an empty table.
pub fn Table::new() -> Table {
  { columns: [], rows: [], }
}

///|
/// Builds a table from CSV text (with a header row when `header`).
pub fn Table::from_csv(
  text : String,
  header~ : Bool = false,
  separator~ : Char = ',',
) -> Table raise CsvError {
  let data = parse_csv(text, separator~)
  let t = Table::new()
  if header && data.length() > 0 {
    t.columns = data[0].map(c => Some(c))
    ignore(data.remove(0))
  } else if data.length() > 0 {
    t.columns = Array::make(data[0].length(), None)
  }
  for line in data {
    ignore(t.add_row(row=TableRow::new(cells=line)))
  }
  t
}

///|
/// Adds a row (an empty one by default) and returns it.
pub fn Table::add_row(
  self : Table,
  row~ : TableRow = TableRow::new(),
) -> TableRow {
  row.columns = self.columns
  self.rows.push(row)
  row
}

///|
/// Removes the row at `index`.
pub fn Table::remove_row(self : Table, index : Int32) -> Unit {
  if index >= 0 && index < self.rows.length() {
    ignore(self.rows.remove(index))
  }
}

///|
/// The row at `index`.
pub fn Table::get_row(self : Table, index : Int32) -> TableRow? {
  self.rows.get(index)
}

///|
/// All rows.
pub fn Table::get_rows(self : Table) -> Array[TableRow] {
  self.rows
}

///|
/// The first row whose cell in `column` equals `value`.
pub fn Table::find_row(
  self : Table,
  value : String,
  column : Column,
) -> TableRow? {
  for r in self.rows {
    if r.get(column) == value {
      return Some(r)
    }
  }
  None
}

///|
/// Every row whose cell in `column` equals `value`.
pub fn Table::find_rows(
  self : Table,
  value : String,
  column : Column,
) -> Array[TableRow] {
  self.rows.filter(r => r.get(column) == value)
}

///|
/// The first row whose cell in `column` satisfies `matches` (p5's
/// `matchRow` takes a regular expression).
pub fn Table::match_row(
  self : Table,
  matches : (String) -> Bool,
  column : Column,
) -> TableRow? {
  for r in self.rows {
    if matches(r.get(column)) {
      return Some(r)
    }
  }
  None
}

///|
/// Every row whose cell in `column` satisfies `matches`.
pub fn Table::match_rows(
  self : Table,
  matches : (String) -> Bool,
  column : Column,
) -> Array[TableRow] {
  self.rows.filter(r => matches(r.get(column)))
}

///|
/// All cells of a column.
pub fn Table::get_column(self : Table, column : Column) -> Array[String] {
  self.rows.map(r => r.get(column))
}

///|
/// Removes every row.
pub fn Table::clear_rows(self : Table) -> Unit {
  self.rows.clear()
}

///|
/// Adds a column (untitled by default).
pub fn Table::add_column(self : Table, title? : String) -> Unit {
  self.columns.push(title)
  for r in self.rows {
    r.columns = self.columns
  }
}

///|
/// Column titles (`None` for untitled columns).
pub fn Table::columns(self : Table) -> Array[String?] {
  self.columns
}

///|
/// Number of columns.
pub fn Table::get_column_count(self : Table) -> Int32 {
  self.columns.length()
}

///|
/// Number of rows.
pub fn Table::get_row_count(self : Table) -> Int32 {
  self.rows.length()
}

///|
fn Table::map_cells(
  self : Table,
  column : Column?,
  f : (String) -> String,
) -> Unit {
  for r in self.rows {
    match column {
      None =>
        for i in 0..<r.arr.length() {
          r.arr[i] = f(r.arr[i])
        }
      Some(c) => {
        let i = r.index(c)
        if i >= 0 && i < r.arr.length() {
          r.arr[i] = f(r.arr[i])
        }
      }
    }
  }
}

///|
/// Removes every occurrence of the characters in `chars` (in one column,
/// or everywhere).
pub fn Table::remove_tokens(
  self : Table,
  chars : String,
  column? : Column,
) -> Unit {
  self.map_cells(column, s => {
    let sb = StringBuilder()
    for c in s {
      if !chars.contains_char(c) {
        sb.write_char(c)
      }
    }
    sb.to_string()
  })
}

///|
/// Removes spaces (in one column, or everywhere), like p5's `trim()`.
pub fn Table::trim(self : Table, column? : Column) -> Unit {
  self.map_cells(column, s => s.replace_all(old=" ", new=""))
}

///|
/// Removes a column.
pub fn Table::remove_column(self : Table, column : Column) -> Unit {
  let i = match column {
    Index(i) => i
    Title(t) => index_of_title(self.columns, t)
  }
  if i < 0 || i >= self.columns.length() {
    return
  }
  ignore(self.columns.remove(i))
  for r in self.rows {
    if i < r.arr.length() {
      ignore(r.arr.remove(i))
    }
    r.columns = self.columns
  }
}

///|
/// Sets a cell.
pub fn Table::set(
  self : Table,
  row : Int32,
  column : Column,
  value : String,
) -> Unit {
  if self.rows.get(row) is Some(r) {
    r.set(column, value)
  }
}

///|
/// Sets a cell to a number.
pub fn Table::set_num(
  self : Table,
  row : Int32,
  column : Column,
  value : Double,
) -> Unit {
  self.set(row, column, format_number(value))
}

///|
/// Sets a cell to a string.
pub fn Table::set_string(
  self : Table,
  row : Int32,
  column : Column,
  value : String,
) -> Unit {
  self.set(row, column, value)
}

///|
/// A cell.
pub fn Table::get(self : Table, row : Int32, column : Column) -> String {
  match self.rows.get(row) {
    Some(r) => r.get(column)
    None => ""
  }
}

///|
/// A cell as a number.
pub fn Table::get_num(self : Table, row : Int32, column : Column) -> Double {
  parse_float(self.get(row, column))
}

///|
/// A cell as a string.
pub fn Table::get_string(self : Table, row : Int32, column : Column) -> String {
  self.get(row, column)
}

///|
/// The rows as arrays of cells.
pub fn Table::get_array(self : Table) -> Array[Array[String]] {
  self.rows.map(r => r.arr.copy())
}

///|
/// The rows as JSON objects keyed by column title, themselves keyed by
/// the cell in `header_column` (or by row index), like p5's `getObject`.
pub fn Table::get_object(self : Table, header_column? : String) -> Json {
  let out : Map[String, Json] = Map([])
  for i, r in self.rows {
    let obj : Map[String, Json] = Map([])
    for c, title in self.columns {
      let key = match title {
        Some(t) => t
        None => c.to_string()
      }
      obj[key] = Json::string(r.arr.get(c).unwrap_or(""))
    }
    let key = match header_column {
      Some(h) => r.get(Title(h))
      None => i.to_string()
    }
    out[key] = Json::object(obj)
  }
  Json::object(out)
}

///|
/// The table as CSV (with the header row when every column has a title).
pub fn Table::to_csv(self : Table, separator~ : Char = ',') -> String {
  let rows = self.rows.map(r => r.arr)
  let all = if self.columns.length() > 0 &&
    self.columns.iter().all(c => c is Some(_)) {
    [self.columns.map(c => c.unwrap_or("")), ..rows]
  } else {
    rows
  }
  stringify_csv(all, separator~)
}
