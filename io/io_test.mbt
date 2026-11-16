// CSV reference values come from running p5.js's src/io/csv.js under Node.

///|
test "csv parse matches p5.js" {
  debug_inspect(
    @io.parse_csv("name,age\nAda,36\n\"Turing, Alan\",41\n"),
    content=(
      #|[["name", "age"], ["Ada", "36"], ["Turing, Alan", "41"]]
    ),
  )
  debug_inspect(
    @io.parse_csv("a,\"b \"\"quoted\"\" c\",d\r\n\"multi\r\nline\",x,\r\n"),
    content=(
      #|[["a", "b \"quoted\" c", "d"], ["multi\r\nline", "x", ""]]
    ),
  )
  debug_inspect(
    @io.parse_csv("x;y;z\n1;2;3", separator=';'),
    content=(
      #|[["x", "y", "z"], ["1", "2", "3"]]
    ),
  )
  debug_inspect(
    @io.parse_csv(",,\n\"\",\"\"\n"),
    content=(
      #|[["", "", ""], ["", ""]]
    ),
  )
  try @io.parse_csv("a\"b,c\n") catch {
    @io.CsvError(msg) =>
      inspect(msg, content="CSVError: Illegal state [row:1, col:1]")
  } noraise {
    _ => fail("expected an error")
  }
}

///|
test "csv stringify matches p5.js" {
  inspect(
    @io.stringify_csv([["a", "b,c", "d\"e"], ["line\nbreak", "", "z"]]),
    content=(
      #|a,"b,c","d""e"
      #|"line
      #|break",,z
      #|
    ),
  )
}

///|
test "table" {
  let t = @io.Table::from_csv(
    "id,species,name\n0,Capra hircus,Goat\n1,Panthera pardus,Leopard\n2,Equus zebra,Zebra\n",
    header=true,
  )
  inspect(t.get_row_count(), content="3")
  inspect(t.get_column_count(), content="3")
  inspect(t.get_string(1, Title("name")), content="Leopard")
  inspect(t.get_num(2, Index(0)), content="2")
  debug_inspect(
    t.get_column(Title("name")),
    content=(
      #|["Goat", "Leopard", "Zebra"]
    ),
  )
  inspect(
    t.find_row("Zebra", Title("name")).map(r => r.get(Index(1))).unwrap_or(""),
    content="Equus zebra",
  )
  inspect(
    t.match_rows(s => s.has_prefix("Panthera"), Title("species")).length(),
    content="1",
  )
  let r = t.add_row()
  r.set_string(Title("name"), "Wolf")
  r.set_num(Index(0), 3)
  t.set(3, Title("species"), "Canis lupus")
  t.remove_column(Title("id"))
  t.remove_row(0)
  inspect(
    t.to_csv(),
    content=(
      #|species,name
      #|Panthera pardus,Leopard
      #|Equus zebra,Zebra
      #|Canis lupus,Wolf
      #|
    ),
  )
  t.remove_tokens("aeiou", column=Title("name"))
  debug_inspect(
    t.get_column(Index(1)),
    content=(
      #|["Lprd", "Zbr", "Wlf"]
    ),
  )
  inspect(@io.parse_float("  3.5e2px"), content="350")
  inspect(@io.parse_float("-.5"), content="-0.5")
  inspect(@io.parse_float("abc").is_nan(), content="true")
}

///|
test "xml" {
  let doc =
    #|<?xml version="1.0"?>
    #|<mammals>
    #|  <animal id="0" species="Capra hircus">Goat</animal>
    #|  <animal id="1" species="Panthera pardus">Leopard &amp; cub</animal>
    #|  <group><animal id="2">Zebra</animal></group>
    #|  <!-- comment --><empty/>
    #|</mammals>
  let x = @io.Xml::parse(doc)
  inspect(x.get_name(), content="mammals")
  inspect(x.get_children().length(), content="4")
  inspect(x.get_children(name="animal").length(), content="3")
  debug_inspect(
    x.list_children(),
    content=(
      #|[
      #|  "#text",
      #|  "animal",
      #|  "#text",
      #|  "animal",
      #|  "#text",
      #|  "group",
      #|  "#text",
      #|  "#comment",
      #|  "empty",
      #|  "#text",
      #|]
    ),
  )
  let leopard = x.get_child(1).unwrap()
  debug_inspect(leopard.get_content(), content="Some(\"Leopard & cub\")")
  inspect(leopard.get_num("id"), content="1")
  inspect(leopard.get_num("missing", default=7), content="7")
  debug_inspect(
    leopard.get_string("species"),
    content="Some(\"Panthera pardus\")",
  )
  inspect(leopard.has_attribute("id"), content="true")
  leopard.set_attribute("legs", "4")
  debug_inspect(
    leopard.list_attributes(),
    content=(
      #|["id", "species", "legs"]
    ),
  )
  inspect(leopard.get_parent().get_name(), content="mammals")
  let bird = @io.Xml::new(name="animal")
  bird.set_attribute("name", "Owl \"Hoot\"")
  bird.set_content("bird")
  x.add_child(bird)
  x.remove_child_by_name("group")
  x.remove_child(0)
  inspect(
    x.serialize(),
    content=(
      #|<mammals>
      #|  
      #|  <animal id="1" species="Panthera pardus" legs="4">Leopard &amp; cub</animal>
      #|  
      #|  <!-- comment --><empty/>
      #|<animal name="Owl &quot;Hoot&quot;">bird</animal></mammals>
    ),
  )
  try @io.Xml::parse("<a><b></a>") catch {
    @io.XmlError(msg) => inspect(msg, content="Mismatched closing tag </a>")
  } noraise {
    _ => fail("expected an error")
  }
}

///|
test "xml cdata" {
  let x = @io.Xml::parse("<n><![CDATA[a < b & c]]></n>")
  debug_inspect(x.get_content(), content="Some(\"a < b & c\")")
  inspect(x.serialize(), content="<n><![CDATA[a < b & c]]></n>")
}
