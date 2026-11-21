///|
test "every language has a place on the map" {
  assert_eq(langs.length() + 1, positions.length())
  assert_eq(all_shots.length(), langs.length())
  for e in edges {
    assert_true(e.0 < e.1) // influence flows forward in time
    assert_true(e.1 < positions.length())
  }
}

///|
test "the crescent has room for the code" {
  assert_true(crescent.length() > 200)
  assert_true(all_glyphs.length() > crescent.length())
}

///|
test "tokenizer keeps every character" {
  let line = "fn fib(n : Int) -> Int { \"x\" } // done"
  let toks = tokenize(line, ["fn"], "//", "\"")
  assert_eq(toks.map(t => t.0).join(""), line)
  assert_eq(toks[0], ("fn", Keyword))
  assert_true(toks.contains(("\"x\"", Str)))
  assert_eq(toks[toks.length() - 1], ("// done", Comment))
}

///|
test "rust lifetimes are not strings" {
  let toks = tokenize("fn f<'a>(x: &'a str)", ["fn", "str"], "//", "\"")
  assert_false(toks.iter().any(t => t.1 == Str))
}
