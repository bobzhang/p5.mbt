// Port of the text/JSON parts of p5.js src/io/files.js.

///|
/// Loads a text file as lines. The returned array is filled when loading
/// finishes; in `preload`, `setup` waits for it.
pub fn P5::load_strings(
  self : P5,
  url : String,
  on_load? : (Array[String]) -> Unit,
) -> Array[String] {
  let lines : Array[String] = []
  self.load_text(url, on_load=text => {
    lines.append(split_lines_keep(text))
    if on_load is Some(f) {
      f(lines)
    }
  })
  lines
}

///|
fn split_lines_keep(text : String) -> Array[String] {
  let t = text.replace_all(old="\r\n", new="\n")
  let lines = [ for l in t.split("\n") => l.to_owned() ]
  // A trailing newline doesn't start an extra (empty) line.
  if lines.length() > 1 && lines[lines.length() - 1] == "" {
    ignore(lines.pop())
  }
  lines
}

///|
/// Loads a text file and calls `on_load` with its contents.
pub fn P5::load_text(
  self : P5,
  url : String,
  on_load? : (String) -> Unit,
) -> Unit {
  self.begin_load()
  @dom.fetch_text(
    url,
    text => {
      if on_load is Some(f) {
        f(text)
      }
      self.end_load()
    },
    msg => {
      warn(msg)
      self.end_load()
    },
  )
}

///|
/// Loads and parses a JSON file, then calls `on_load` with the value.
pub fn P5::load_json(self : P5, url : String, on_load : (Json) -> Unit) -> Unit {
  self.load_text(url, on_load=text => {
    let parsed = @json.parse(text) catch {
      e => {
        warn("Could not parse JSON from \{url}: \{e}")
        return
      }
    }
    on_load(parsed)
  })
}

///|
/// Downloads lines of text as a file.
pub fn save_strings(
  lines : ArrayView[String],
  filename : String,
  ext~ : String = "txt",
) -> Unit {
  @dom.download_text(
    lines.join("\n") + "\n",
    "\{filename}.\{ext}",
    "text/plain",
  )
}

///|
/// Downloads a JSON value as a file.
pub fn save_json(
  value : Json,
  filename : String,
  pretty~ : Bool = true,
) -> Unit {
  let text = if pretty { value.stringify(indent=2) } else { value.stringify() }
  @dom.download_text(text, filename + ".json", "application/json")
}
