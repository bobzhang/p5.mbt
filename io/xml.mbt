// An XML tree with the API of p5.js src/io/p5.XML.js. p5.js wraps the
// browser's DOMParser; this is a small parser of its own.

///|
/// A node in an XML tree.
pub(all) enum XmlNode {
  Element(Xml)
  Text(String)
  CData(String)
  Comment(String)
}

///|
/// An XML element (p5.XML).
pub struct Xml {
  priv mut name : String
  priv attrs : Array[(String, String)]
  priv children : Array[XmlNode]
  priv mut parent : Xml?
}

///|
/// Errors in malformed XML.
#derive(Debug)
pub suberror XmlError {
  XmlError(String)
}

///|
/// Creates an empty element (`<root/>` by default, as in p5).
pub fn Xml::new(name~ : String = "root") -> Xml {
  { name, attrs: [], children: [], parent: None, }
}

///|
fn decode_entities(s : String) -> String {
  if !s.contains("&") {
    return s
  }
  let out = StringBuilder()
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i] == '&' {
      let mut j = i + 1
      while j < chars.length() && chars[j] != ';' && j - i < 12 {
        j += 1
      }
      if j < chars.length() && chars[j] == ';' {
        let ent = String::from_array(chars[i + 1:j])
        let decoded : Char? = match ent {
          "lt" => Some('<')
          "gt" => Some('>')
          "amp" => Some('&')
          "quot" => Some('"')
          "apos" => Some('\'')
          _ =>
            if ent is ['#', 'x', .. hex] {
              (@string.parse_int(hex.to_owned(), base=16) catch { _ => -1 })
              |> code_char
            } else if ent is ['#', .. dec] {
              (@string.parse_int(dec.to_owned()) catch { _ => -1 }) |> code_char
            } else {
              None
            }
        }
        if decoded is Some(c) {
          out.write_char(c)
          i = j + 1
          continue
        }
      }
    }
    out.write_char(chars[i])
    i += 1
  }
  out.to_string()
}

///|
fn code_char(code : Int32) -> Char? {
  if code < 0 {
    None
  } else {
    Some(Int32::unsafe_to_char(code))
  }
}

///|
/// Parses an XML document and returns its root element.
///
/// ```mbt check
/// test {
///   let x = @io.Xml::parse(
///     "<animals><mammal id=\"0\" species=\"Panthera\">Goat</mammal></animals>",
///   )
///   inspect(x.get_name(), content="animals")
///   let m = x.get_child_by_name("mammal").unwrap()
///   inspect(m.get_content().unwrap_or(""), content="Goat")
///   inspect(m.get_num("id"), content="0")
///   inspect(
///     x.serialize(),
///     content="<animals><mammal id=\"0\" species=\"Panthera\">Goat</mammal></animals>",
///   )
/// }
/// ```
pub fn Xml::parse(text : String) -> Xml raise XmlError {
  let s = text.to_array()
  let n = s.length()
  let mut i = 0
  let starts = (prefix : String) => {
    let p = prefix.to_array()
    if i + p.length() > n {
      false
    } else {
      let mut ok = true
      for k in 0..<p.length() {
        if s[i + k] != p[k] {
          ok = false
          break
        }
      }
      ok
    }
  }
  // Skips past `end`, returning the text before it.
  let skip_to = (end : String) => {
    let begin = i
    while i < n && !starts(end) {
      i += 1
    }
    let content = String::from_array(s[begin:i])
    i = (i + end.length()).min(n)
    content
  }
  let is_name_char = (c : Char) => {
    c.is_ascii_alphabetic() ||
    c.is_ascii_digit() ||
    c == '_' ||
    c == '-' ||
    c == '.' ||
    c == ':' ||
    c.to_int() > 127
  }
  let read_name = () => {
    let b = i
    while i < n && is_name_char(s[i]) {
      i += 1
    }
    String::from_array(s[b:i])
  }
  let skip_ws = () => {
    while i < n && s[i].is_ascii_whitespace() {
      i += 1
    }
  }
  let stack : Array[Xml] = []
  let mut root : Xml? = None
  while i < n {
    if starts("<?") {
      ignore(skip_to("?>"))
    } else if starts("<!--") {
      i += 4
      let content = skip_to("-->")
      if stack.last() is Some(top) {
        top.children.push(Comment(content))
      }
    } else if starts("<![CDATA[") {
      i += 9
      let content = skip_to("]]>")
      if stack.last() is Some(top) {
        top.children.push(CData(content))
      }
    } else if starts("<!") {
      // DOCTYPE and other declarations
      ignore(skip_to(">"))
    } else if starts("</") {
      i += 2
      let name = read_name()
      skip_ws()
      if i < n && s[i] == '>' {
        i += 1
      }
      guard stack.pop() is Some(el) && el.name == name else {
        raise XmlError("Mismatched closing tag </\{name}>")
      }
    } else if s[i] == '<' {
      i += 1
      let el = Xml::new(name=read_name())
      if el.name.is_empty() {
        raise XmlError("Invalid tag at offset \{i}")
      }
      let mut self_closing = false
      for ;; {
        skip_ws()
        if i >= n {
          raise XmlError("Unterminated tag <\{el.name}>")
        }
        if s[i] == '/' && i + 1 < n && s[i + 1] == '>' {
          i += 2
          self_closing = true
          break
        }
        if s[i] == '>' {
          i += 1
          break
        }
        let attr = read_name()
        if attr.is_empty() {
          raise XmlError("Invalid attribute in <\{el.name}>")
        }
        skip_ws()
        let mut value = ""
        if i < n && s[i] == '=' {
          i += 1
          skip_ws()
          if i < n && (s[i] == '"' || s[i] == '\'') {
            let q = s[i]
            i += 1
            let b = i
            while i < n && s[i] != q {
              i += 1
            }
            value = decode_entities(String::from_array(s[b:i]))
            i += 1
          }
        }
        el.attrs.push((attr, value))
      }
      match stack.last() {
        Some(top) => {
          el.parent = Some(top)
          top.children.push(Element(el))
        }
        None => if root is None { root = Some(el) }
      }
      if !self_closing {
        stack.push(el)
      }
    } else {
      let b = i
      while i < n && s[i] != '<' {
        i += 1
      }
      if stack.last() is Some(top) {
        top.children.push(Text(decode_entities(String::from_array(s[b:i]))))
      }
    }
  }
  if stack.length() > 0 {
    raise XmlError("Unclosed tag <\{stack[stack.length() - 1].name}>")
  }
  match root {
    Some(r) => r
    None => raise XmlError("No root element")
  }
}

///|
/// The parent element (the element itself for the root).
pub fn Xml::get_parent(self : Xml) -> Xml {
  self.parent.unwrap_or(self)
}

///|
/// The tag name.
pub fn Xml::get_name(self : Xml) -> String {
  self.name
}

///|
/// Renames the element.
pub fn Xml::set_name(self : Xml, name : String) -> Unit {
  self.name = name
}

///|
fn Xml::elements(self : Xml) -> Array[Xml] {
  let out : Array[Xml] = []
  for c in self.children {
    if c is Element(e) {
      out.push(e)
    }
  }
  out
}

///|
/// Whether the element has child elements.
pub fn Xml::has_children(self : Xml) -> Bool {
  self.elements().length() > 0
}

///|
/// The node names of all children (`"#text"` for text, like the DOM).
pub fn Xml::list_children(self : Xml) -> Array[String] {
  self.children.map(c => {
    match c {
      Element(e) => e.name
      Text(_) => "#text"
      CData(_) => "#cdata-section"
      Comment(_) => "#comment"
    }
  })
}

///|
fn collect(el : Xml, name : String, out : Array[Xml]) -> Unit {
  for c in el.elements() {
    if c.name == name {
      out.push(c)
    }
    collect(c, name, out)
  }
}

///|
/// Child elements, or every descendant with the given tag name (like
/// `getElementsByTagName`).
pub fn Xml::get_children(self : Xml, name? : String) -> Array[Xml] {
  match name {
    None => self.elements()
    Some(n) => {
      let out = []
      collect(self, n, out)
      out
    }
  }
}

///|
/// The first child element with the given tag name.
pub fn Xml::get_child_by_name(self : Xml, name : String) -> Xml? {
  for c in self.elements() {
    if c.name == name {
      return Some(c)
    }
  }
  None
}

///|
/// The child element at `index`.
pub fn Xml::get_child(self : Xml, index : Int32) -> Xml? {
  self.elements().get(index)
}

///|
/// Appends a child element.
pub fn Xml::add_child(self : Xml, child : Xml) -> Unit {
  child.parent = Some(self)
  self.children.push(Element(child))
}

///|
/// Removes the first child element with the given name.
pub fn Xml::remove_child_by_name(self : Xml, name : String) -> Unit {
  match self.children.search_by(c => c is Element(e) && e.name == name) {
    Some(i) => ignore(self.children.remove(i))
    None => ()
  }
}

///|
/// Removes the child element at `index`.
pub fn Xml::remove_child(self : Xml, index : Int32) -> Unit {
  let mut k = 0
  for i, c in self.children {
    if c is Element(_) {
      if k == index {
        ignore(self.children.remove(i))
        return
      }
      k += 1
    }
  }
}

///|
/// Number of attributes.
pub fn Xml::get_attribute_count(self : Xml) -> Int32 {
  self.attrs.length()
}

///|
/// Attribute names.
pub fn Xml::list_attributes(self : Xml) -> Array[String] {
  self.attrs.map(a => a.0)
}

///|
fn Xml::attr(self : Xml, name : String) -> String? {
  for a in self.attrs {
    if a.0 == name {
      return Some(a.1)
    }
  }
  None
}

///|
/// Whether the attribute exists with a non-empty value (as in p5).
pub fn Xml::has_attribute(self : Xml, name : String) -> Bool {
  match self.attr(name) {
    Some(v) => !v.is_empty()
    None => false
  }
}

///|
/// An attribute as a number (`default` when missing, empty or 0, like
/// p5's `Number(v) || default || 0`).
pub fn Xml::get_num(self : Xml, name : String, default~ : Double = 0) -> Double {
  let v = match self.attr(name) {
    Some(s) =>
      @string.parse_double(s.trim().to_owned()) catch {
        _ => 0.0 / 0.0
      }
    None => 0.0 / 0.0
  }
  if v.is_nan() || v == 0 {
    default
  } else {
    v
  }
}

///|
/// An attribute as a string (`default` when missing or empty).
pub fn Xml::get_string(self : Xml, name : String, default? : String) -> String? {
  match self.attr(name) {
    Some(v) if !v.is_empty() => Some(v)
    _ => default
  }
}

///|
/// Sets an attribute.
pub fn Xml::set_attribute(self : Xml, name : String, value : String) -> Unit {
  match self.attrs.search_by(a => a.0 == name) {
    Some(i) => self.attrs[i] = (name, value)
    None => self.attrs.push((name, value))
  }
}

///|
fn text_content(el : Xml, out : StringBuilder) -> Unit {
  for c in el.children {
    match c {
      Element(e) => text_content(e, out)
      Text(t) | CData(t) => out.write_string(t)
      Comment(_) => ()
    }
  }
}

///|
/// The text content, with runs of whitespace replaced by commas (as p5
/// does); `default` when empty.
pub fn Xml::get_content(self : Xml, default? : String) -> String? {
  let sb = StringBuilder()
  text_content(self, sb)
  // p5: str.replace(/\s\s+/g, ',')
  let out = StringBuilder()
  let chars = sb.to_string().to_array()
  let mut i = 0
  while i < chars.length() {
    if chars[i].is_ascii_whitespace() &&
      i + 1 < chars.length() &&
      chars[i + 1].is_ascii_whitespace() {
      while i < chars.length() && chars[i].is_ascii_whitespace() {
        i += 1
      }
      out.write_char(',')
    } else {
      out.write_char(chars[i])
      i += 1
    }
  }
  let s = out.to_string()
  if s.is_empty() {
    default
  } else {
    Some(s)
  }
}

///|
/// Replaces the content with text (only when there are no child elements,
/// as in p5).
pub fn Xml::set_content(self : Xml, content : String) -> Unit {
  if !self.has_children() {
    self.children.clear()
    self.children.push(Text(content))
  }
}

///|
fn escape(s : String, attr : Bool) -> String {
  let out = StringBuilder()
  for c in s {
    match c {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' if attr => out.write_string("&quot;")
      _ => out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn write_xml(el : Xml, out : StringBuilder) -> Unit {
  out.write_string("<" + el.name)
  for a in el.attrs {
    out.write_string(" \{a.0}=\"\{escape(a.1, true)}\"")
  }
  if el.children.is_empty() {
    out.write_string("/>")
    return
  }
  out.write_char('>')
  for c in el.children {
    match c {
      Element(e) => write_xml(e, out)
      Text(t) => out.write_string(escape(t, false))
      CData(t) => out.write_string("<![CDATA[\{t}]]>")
      Comment(t) => out.write_string("<!--\{t}-->")
    }
  }
  out.write_string("</\{el.name}>")
}

///|
/// The element as XML text (like `XMLSerializer`).
pub fn Xml::serialize(self : Xml) -> String {
  let out = StringBuilder()
  write_xml(self, out)
  out.to_string()
}
