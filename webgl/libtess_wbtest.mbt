///|
/// Runs p5's ShapeBuilder triangulation with the real libtess.js (from the
/// p5.js checkout) for comparison; `None` when it is not installed.
extern "js" fn reference(
  contours : FixedArray[FixedArray[Double]],
) -> FixedArray[Double]? =
  #|(contours) => {
  #|  const fs = require('fs'), path = require('path');
  #|  let dir = process.cwd(), lib = null;
  #|  for (;;) {
  #|    const p = path.join(dir, '.repos/p5.js/node_modules/libtess/libtess.cat.js');
  #|    if (fs.existsSync(p)) { lib = require(p); break; }
  #|    const up = path.dirname(dir); if (up === dir) return undefined; dir = up;
  #|  }
  #|  const stride = 12, tessy = new lib.GluTesselator();
  #|  tessy.gluTessCallback(lib.gluEnum.GLU_TESS_VERTEX_DATA, (data, out) => { for (const x of data) out.push(x); });
  #|  tessy.gluTessCallback(lib.gluEnum.GLU_TESS_BEGIN, () => {});
  #|  tessy.gluTessCallback(lib.gluEnum.GLU_TESS_ERROR, () => {});
  #|  tessy.gluTessCallback(lib.gluEnum.GLU_TESS_COMBINE, (coords, data, weight) => {
  #|    const r = new Array(stride).fill(0);
  #|    for (let i = 0; i < weight.length; i++) for (let j = 0; j < r.length; j++) { if (weight[i] === 0 || !data[i]) continue; r[j] += data[i][j] * weight[i]; }
  #|    return r;
  #|  });
  #|  tessy.gluTessCallback(lib.gluEnum.GLU_TESS_EDGE_FLAG, () => {});
  #|  tessy.gluTessProperty(lib.gluEnum.GLU_TESS_WINDING_RULE, lib.windingRule.GLU_TESS_WINDING_NONZERO);
  #|  const z = contours[0][2];
  #|  let same = true;
  #|  for (const c of contours) for (let j = 0; j < c.length; j += stride) if (c[j + 2] !== z) same = false;
  #|  tessy.gluTessNormal(0, 0, same ? 1 : 0);
  #|  const out = [];
  #|  tessy.gluTessBeginPolygon(out);
  #|  for (const c of contours) {
  #|    tessy.gluTessBeginContour();
  #|    for (let j = 0; j < c.length; j += stride) { const v = c.slice(j, j + stride); tessy.gluTessVertex(v, v); }
  #|    tessy.gluTessEndContour();
  #|  }
  #|  tessy.gluTessEndPolygon();
  #|  return out;
  #|}

///|
fn vert(x : Double, y : Double, z~ : Double = 0) -> FixedArray[Double] {
  [x, y, z, x / 100, y / 100, 1, 0.5, 0.25, 1, 0, 0, 1]
}

///|
fn check(name : String, contours : Array[Array[FixedArray[Double]]]) -> String {
  let flat = FixedArray::makei(contours.length(), i => {
    let c = contours[i]
    FixedArray::makei(c.length() * 12, k => c[k / 12][k % 12])
  })
  let mine = libtess_triangulate(contours, 12)
  match reference(flat) {
    None => "\{name}: skipped"
    Some(r) =>
      if same_values(mine, r) {
        "\{name}: same (\{mine.length() / 12} vertices)"
      } else {
        "\{name}: DIFFERENT \{mine.length()} vs \{r.length()}"
      }
  }
}

///|
test "libtess port matches libtess.js" {
  let star : Array[FixedArray[Double]] = []
  for i in 0..<5 {
    let a = -1.5707963267948966 + i.to_double() * 6.283185307179586 * 2 / 5
    star.push(vert(200 + 50 * js_cos(a), 60 + 50 * js_sin(a)))
  }
  let lines = [
    check("quad", [[vert(0, 0), vert(60, 0), vert(60, 60), vert(0, 60)]]),
    check("closed quad", [
      [vert(0, 0), vert(60, 0), vert(60, 60), vert(0, 60), vert(0, 0)],
    ]),
    check("hole", [
      [vert(20, 20), vert(120, 20), vert(120, 90), vert(20, 90), vert(20, 20)],
      [vert(50, 40), vert(50, 70), vert(90, 70), vert(90, 40), vert(50, 40)],
    ]),
    check("star", [star]),
    check("concave", [
      [
        vert(0, 0),
        vert(100, 0),
        vert(50, 30),
        vert(100, 100),
        vert(0, 100),
        vert(30, 50),
      ],
    ]),
    check("bowtie", [[vert(0, 0), vert(100, 100), vert(100, 0), vert(0, 100)]]),
    check("nonplanar", [
      [
        vert(0, 0, z=0),
        vert(50, 0, z=20),
        vert(60, 50, z=10),
        vert(0, 40, z=-5),
      ],
    ]),
    check("overlap", [
      [vert(0, 0), vert(80, 0), vert(80, 80), vert(0, 80)],
      [vert(40, 40), vert(120, 40), vert(120, 120), vert(40, 120)],
    ]),
  ]
  inspect(
    lines.join("\n"),
    content=(
      #|quad: same (6 vertices)
      #|closed quad: same (6 vertices)
      #|hole: same (24 vertices)
      #|star: same (24 vertices)
      #|concave: same (12 vertices)
      #|bowtie: same (6 vertices)
      #|nonplanar: same (6 vertices)
      #|overlap: same (30 vertices)
    ),
  )
}

///|
fn same_values(a : Array[Double], b : FixedArray[Double]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i, v in a {
    if v != b[i] {
      return false
    }
  }
  true
}
