// MoonBit side of points_dump.mjs.

///|
extern "js" fn read_file(path : String) -> Bytes =
  #|(p) => new Uint8Array(require('fs').readFileSync(p))

///|
extern "js" fn argv(i : Int32) -> String =
  #|(i) => process.argv[i] ?? ""

///|
extern "js" fn num(d : Double) -> String =
  #|(d) => String(d)

///|
extern "js" fn parse_num(s : String) -> Double =
  #|(s) => +s

///|
fn main {
  let font = @font.FontData::parse(read_file(argv(2))) catch {
    e => {
      println("\{e}")
      return
    }
  }
  let factor = parse_num(argv(3))
  let simp = if argv(5) == "" { 0.0 } else { parse_num(argv(5)) }
  let out : Array[String] = []
  let counts = (c : @font.PathCmd) => {
    match c {
      M | L => 2
      Q => 4
      C => 6
      Z => 0
    }
  }
  for g in font.shape(argv(4)) {
    let p = font.glyph_path(g.glyph)
    // split into contours at each M
    let mut k = 0
    let mut start_cmd = 0
    let mut start_crd = 0
    let flush = (end_cmd : Int32, end_crd : Int32) => {
      let pts = @font.path_to_points(
        p.cmds[start_cmd:end_cmd],
        p.crds[start_crd:end_crd],
        sample_factor=factor,
        simplify_threshold=simp,
      )
      out.push(
        pts.map(q => "\{num(q.x)},\{num(q.y)},\{num(q.angle)}").join(" "),
      )
    }
    for i, c in p.cmds {
      if c == M && i > 0 {
        flush(i, k)
        start_cmd = i
        start_crd = k
      }
      k += counts(c)
    }
    if p.cmds.length() > 0 {
      flush(p.cmds.length(), k)
    }
  }
  println(out.join("\n"))
}
