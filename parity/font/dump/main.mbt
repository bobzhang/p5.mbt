// Dumps p5.mbt's font outlines in the same JSON shape as typr_dump.mjs.

///|
extern "js" fn read_file(path : String) -> Bytes =
  #|(p) => new Uint8Array(require('fs').readFileSync(p))

///|
extern "js" fn argv(i : Int32) -> String =
  #|(i) => process.argv[i] ?? ""

///|
extern "js" fn num(d : Double) -> String =
  #|(d) => String(+d.toFixed(4))

///|
fn main {
  let file = argv(2)
  let text = argv(3)
  let font = @font.FontData::parse(read_file(file)) catch {
    e => {
      println("error: \{e}")
      return
    }
  }
  let glyphs = font
    .shape(text)
    .map(g => {
      let p = font.glyph_path(g.glyph)
      let cmds = p.cmds.map(c => c.letter()).join("")
      let crds = p.crds.map(num).join(",")
      "{\"g\":\{g.glyph},\"ax\":\{g.advance},\"cmds\":\"\{cmds}\",\"crds\":[\{crds}]}"
    })
  println(
    "{\"upem\":\{font.units_per_em},\"asc\":\{font.ascender},\"desc\":\{font.descender},\"glyphs\":[\{glyphs.join(",")}]}",
  )
}
