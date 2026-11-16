// The rest of p5.js src/io/files.js and src/data/local_storage.js:
// tables, XML, bytes, HTTP, writers and typed local storage.

///|
pub using @io {
  type Table,
  type TableRow,
  type Column,
  type Xml,
  type XmlNode,
  parse_float,
}

///|
/// Loads a CSV (or TSV with `separator='\t'`) file into a table. With
/// `header`, the first row holds the column titles. In `preload`, `setup`
/// waits for it.
pub fn P5::load_table(
  self : P5,
  url : String,
  on_load : (Table) -> Unit,
  header~ : Bool = false,
  separator~ : Char = ',',
) -> Unit {
  self.load_text(url, on_load=text => {
    let table = Table::from_csv(text, header~, separator~) catch {
      @io.CsvError(msg) => {
        warn("Could not parse \{url}: \{msg}")
        return
      }
    }
    on_load(table)
  })
}

///|
/// Loads and parses an XML file. In `preload`, `setup` waits for it.
pub fn P5::load_xml(self : P5, url : String, on_load : (Xml) -> Unit) -> Unit {
  self.load_text(url, on_load=text => {
    let xml = Xml::parse(text) catch {
      @io.XmlError(msg) => {
        warn("Could not parse \{url}: \{msg}")
        return
      }
    }
    on_load(xml)
  })
}

///|
/// Loads a file as raw bytes. In `preload`, `setup` waits for it.
pub fn P5::load_bytes(
  self : P5,
  url : String,
  on_load : (Bytes) -> Unit,
) -> Unit {
  self.begin_load()
  @dom.fetch_bytes(
    url,
    bytes => {
      on_load(Bytes::from_iter(bytes.iter()))
      self.end_load()
    },
    msg => {
      warn(msg)
      self.end_load()
    },
  )
}

///|
/// Makes an HTTP request (`http_method` such as `"GET"`, `"POST"`, `"PUT"`);
/// `on_response(body)` receives the response text, `on_error(message)`
/// network errors and non-2xx statuses.
pub fn P5::http_do(
  self : P5,
  url : String,
  http_method~ : String = "GET",
  body~ : String = "",
  content_type~ : String = "",
  on_response~ : (String) -> Unit,
  on_error? : (String) -> Unit,
) -> Unit {
  self.begin_load()
  @dom.http_request(
    url,
    http_method,
    body,
    content_type,
    (_, text) => {
      on_response(text)
      self.end_load()
    },
    msg => {
      match on_error {
        Some(f) => f(msg)
        None => warn("HTTP request to \{url} failed: \{msg}")
      }
      self.end_load()
    },
  )
}

///|
/// GET request.
pub fn P5::http_get(
  self : P5,
  url : String,
  on_response : (String) -> Unit,
  on_error? : (String) -> Unit,
) -> Unit {
  self.http_do(url, on_response~, on_error?)
}

///|
/// POST request; JSON bodies get a JSON content type.
pub fn P5::http_post(
  self : P5,
  url : String,
  body : String,
  on_response : (String) -> Unit,
  on_error? : (String) -> Unit,
  content_type~ : String = "text/plain",
) -> Unit {
  self.http_do(
    url,
    http_method="POST",
    body~,
    content_type~,
    on_response~,
    on_error?,
  )
}

///|
/// Accumulates text and downloads it as a file on `close()` (p5's
/// `createWriter` / p5.PrintWriter).
pub struct PrintWriter {
  priv name : String
  priv ext : String
  priv content : StringBuilder
}

///|
/// Creates a writer for `name.ext` (`txt` by default).
pub fn P5::create_writer(
  _self : P5,
  name : String,
  ext~ : String = "txt",
) -> PrintWriter {
  { name, ext, content: StringBuilder(), }
}

///|
/// Appends text.
pub fn PrintWriter::write(self : PrintWriter, text : String) -> Unit {
  self.content.write_string(text)
}

///|
/// Appends text and a newline.
pub fn PrintWriter::print(self : PrintWriter, text : String) -> Unit {
  self.content.write_string(text)
  self.content.write_char('\n')
}

///|
/// Discards what was written.
pub fn PrintWriter::clear(self : PrintWriter) -> Unit {
  self.content.reset()
}

///|
/// Downloads the file.
pub fn PrintWriter::close(self : PrintWriter) -> Unit {
  let name = if self.ext.is_empty() {
    self.name
  } else {
    "\{self.name}.\{self.ext}"
  }
  @dom.download_text(self.content.to_string(), name, "text/plain")
}

///|
fn html_escape(s : String) -> String {
  s
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
}

///|
/// Downloads a table as `csv` (default), `tsv` or `html`.
pub fn save_table(
  table : Table,
  filename : String,
  ext~ : String = "csv",
) -> Unit {
  match ext {
    "html" => {
      let sb = StringBuilder()
      sb.write_string(
        "<html>\n<head>\n  <meta http-equiv=\"content-type\" content=\"text/html;charset=utf-8\" />\n</head>\n<body>\n  <table>\n",
      )
      let titles = table.columns()
      if titles.length() > 0 && titles.iter().all(t => t is Some(_)) {
        sb.write_string("    <tr>\n")
        for t in titles {
          sb.write_string("      <td>\{html_escape(t.unwrap_or(""))}</td>\n")
        }
        sb.write_string("    </tr>\n")
      }
      for row in table.get_rows() {
        sb.write_string("    <tr>\n")
        for cell in row.cells() {
          sb.write_string("      <td>\{html_escape(cell)}</td>\n")
        }
        sb.write_string("    </tr>\n")
      }
      sb.write_string("  </table>\n</body>\n</html>\n")
      @dom.download_text(sb.to_string(), "\{filename}.html", "text/html")
    }
    "tsv" =>
      @dom.download_text(
        table.to_csv(separator='\t'),
        "\{filename}.tsv",
        "text/tab-separated-values",
      )
    _ => @dom.download_text(table.to_csv(), "\{filename}.csv", "text/csv")
  }
}

///|
/// Downloads an XML tree as a file.
pub fn save_xml(xml : Xml, filename : String) -> Unit {
  @dom.download_text(xml.serialize(), "\{filename}.xml", "application/xml")
}

///|
/// Values `store_item` can store, with p5's type tags so p5.js sketches on
/// the same page can read them back.
pub(open) trait Storable {
  fn to_storage(Self) -> (String, String)
}

///|
pub impl Storable for String with fn to_storage(self) {
  (self, "string")
}

///|
pub impl Storable for Double with fn to_storage(self) {
  (@dom.number_to_string(self), "number")
}

///|
pub impl Storable for Int32 with fn to_storage(self) {
  (self.to_string(), "number")
}

///|
pub impl Storable for Bool with fn to_storage(self) {
  (self.to_string(), "boolean")
}

///|
pub impl Storable for Json with fn to_storage(self) {
  (self.stringify(), "object")
}

///|
pub impl Storable for Color with fn to_storage(self) {
  (Json::string(self.to_css()).stringify(), "p5.Color")
}

///|
pub impl Storable for Vector with fn to_storage(self) {
  (
    Json::array([
      Json::number(self.x),
      Json::number(self.y),
      Json::number(self.z),
    ]).stringify(),
    "p5.Vector",
  )
}

///|
/// Saves a value in the browser's local storage (with p5's type tag).
pub fn[T : Storable] store_item(key : String, value : T) -> Unit {
  let (text, kind) = value.to_storage()
  @dom.storage_set(key, text)
  @dom.storage_set(key + "p5TypeID", kind)
}

///|
/// Reads a stored value as a string (`None` when missing).
pub fn get_item(key : String) -> String? {
  if @dom.storage_has(key) {
    Some(@dom.storage_get(key))
  } else {
    None
  }
}

///|
/// Reads a stored number (`parseFloat`).
pub fn get_item_number(key : String) -> Double? {
  get_item(key).map(@io.parse_float)
}

///|
/// Reads a stored boolean.
pub fn get_item_bool(key : String) -> Bool? {
  get_item(key).map(v => v == "true")
}

///|
/// Reads a stored JSON value.
pub fn get_item_json(key : String) -> Json? {
  match get_item(key) {
    Some(v) =>
      try @json.parse(v) catch {
        _ => None
      } noraise {
        j => Some(j)
      }
    None => None
  }
}

///|
/// Reads a stored color.
pub fn get_item_color(key : String) -> Color? {
  match get_item_json(key) {
    Some(String(css)) => Color::parse(css)
    _ => None
  }
}

///|
/// Reads a stored vector.
pub fn get_item_vector(key : String) -> Vector? {
  match get_item_json(key) {
    Some(Array([Number(x, ..), Number(y, ..), .. rest])) =>
      Some(
        Vector(
          x,
          y,
          z=match rest {
            [Number(z, ..), ..] => z
            _ => 0
          },
        ),
      )
    _ => None
  }
}

///|
/// Removes a stored value and its type tag.
pub fn remove_item(key : String) -> Unit {
  @dom.storage_remove(key)
  @dom.storage_remove(key + "p5TypeID")
}

///|
/// Removes every value stored with `store_item` (keys with a p5 type tag),
/// like p5's `clearStorage()`.
pub fn clear_storage() -> Unit {
  for key in @dom.storage_keys() {
    if key.has_suffix("p5TypeID") {
      let base = String::from_array(key.to_array()[:key.length() - 8])
      @dom.storage_remove(key)
      @dom.storage_remove(base)
    }
  }
}
