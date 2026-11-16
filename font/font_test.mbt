///|
/// Reads a file from examples/assets (tests run under node).
extern "js" fn read_asset(name : String) -> Bytes =
  #|(name) => {
  #|  const fs = require('fs'), path = require('path');
  #|  let dir = process.cwd();
  #|  while (!fs.existsSync(path.join(dir, 'examples', 'assets', name))) {
  #|    const up = path.dirname(dir); if (up === dir) throw new Error('asset not found: ' + name); dir = up;
  #|  }
  #|  return new Uint8Array(fs.readFileSync(path.join(dir, 'examples', 'assets', name)));
  #|}

///|
extern "js" fn zlib_deflate(data : Bytes) -> Bytes =
  #|(d) => new Uint8Array(require('zlib').deflateSync(d))

///|
test "inflate round-trips zlib data" {
  let text = "p5.mbt font tables, compressed. ".repeat(200)
  let raw = @utf8.encode(text)
  let back = @font.inflate(zlib_deflate(raw))
  inspect(back == raw, content="true")
}

///|
test "TrueType glyph outline (Inconsolata Bold)" {
  let font = @font.FontData::parse(read_asset("Inconsolata-Bold.ttf"))
  debug_inspect(
    (font.units_per_em, font.ascender, font.descender),
    content="(2048, 1759, -389)",
  )
  let shaped = font.shape("Hi")
  debug_inspect(
    shaped,
    content=(
      #|[{ glyph: 43, advance: 1024 }, { glyph: 75, advance: 1024 }]
    ),
  )
  let h = font.glyph_path(43)
  inspect(
    h.cmds.map(c => c.letter()).join(""),
    content="MLLLLLLLLQQQQQLLLLQQQQQZ",
  )
  debug_inspect(h.crds[:6].to_owned(), content="[936, 1204, 936, 0, 700, 0]")
}

///|
test "CFF glyph outline (Source Sans Pro)" {
  let font = @font.FontData::parse(read_asset("SourceSansPro-Regular.otf"))
  let a = font.glyph_path(font.code_to_glyph('A'.to_int()))
  inspect(a.cmds.map(c => c.letter()).join(""), content="MLCLCLZMLLLLLLLZ")
  inspect(font.code_to_glyph(0x10ffff), content="0")
}

///|
test "WOFF font (Lato)" {
  let font = @font.FontData::parse(read_asset("Lato-Regular.woff"))
  inspect(font.units_per_em, content="2000")
  // Lato kerns through GPOS, which Typr (and so p5.js) ignores: only the
  // legacy `kern` table adjusts advances
  let av = font.shape("AV")
  inspect(av[0].advance == font.advance_width(av[0].glyph), content="true")
}

///|
test "path_to_points samples by arc length" {
  // a 100 x 100 square: 400 units of outline
  let cmds : Array[@font.PathCmd] = [M, L, L, L, Z]
  let crds : Array[Double] = [0, 0, 100, 0, 100, 100, 0, 100]
  let pts = @font.path_to_points(cmds, crds, sample_factor=0.01)
  inspect(pts.length(), content="4")
  let corners = pts.map(p => (p.x.round(), p.y.round()))
  debug_inspect(
    corners,
    content=(
      #|[(0, 0), (100, 34), (34, 100), (0, 0)]
    ),
  )
  let simplified = @font.path_to_points(
    cmds,
    crds,
    sample_factor=0.1,
    simplify_threshold=0.1,
  )
  inspect(
    simplified.length(),
    content=(
      #|8
    ),
  )
}
