// Text in WEBGL (src/webgl/text.js): glyph outlines become quadratic
// "strokes" packed into small textures, sampled by p5's font shader.

///|
let char_grid : Int32 = 9

///|
let image_size : Int32 = 64

///|
priv struct ImageInfo {
  data : FixedArray[Double]
  mut index : Int32
  mut dirty : Bool
}

///|
priv struct ImageInfos {
  infos : Array[ImageInfo]
}

///|
fn ImageInfos::find(self : ImageInfos, space : Int32) -> (ImageInfo, Int32) {
  let size = image_size * image_size
  let mut found : ImageInfo? = None
  let mut ii = self.infos.length() - 1
  while ii >= 0 {
    if self.infos[ii].index + space < size {
      found = Some(self.infos[ii])
      break
    }
    ii -= 1
  }
  let info = match found {
    Some(i) => i
    None => {
      let i : ImageInfo = {
        data: FixedArray::make(size * 4, 0.0),
        index: 0,
        dirty: true,
      }
      self.infos.push(i)
      i
    }
  }
  let index = info.index
  info.index += space
  info.dirty = true
  (info, index)
}

///|
fn ImageInfo::set_pixel(
  self : ImageInfo,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  let i = self.index * 4
  self.index += 1
  self.data[i] = r
  self.data[i + 1] = g
  self.data[i + 2] = b
  self.data[i + 3] = a
}

///|
priv struct GlyphInfo {
  rect : FixedArray[Double]
  strokes : ImageInfo
  row_cells : ImageInfo
  row_dims : ImageInfo
  col_cells : ImageInfo
  col_dims : ImageInfo
  grid_offset : FixedArray[Double]
}

///|
/// Per-font glyph data for WEBGL text (p5's FontInfo).
priv struct FontInfo {
  strokes : ImageInfos
  col_dims : ImageInfos
  row_dims : ImageInfos
  col_cells : ImageInfos
  row_cells : ImageInfos
  glyphs : Map[Int32, GlyphInfo?]
}

///|
fn FontInfo::new() -> FontInfo {
  {
    strokes: { infos: [], },
    col_dims: { infos: [], },
    row_dims: { infos: [], },
    col_cells: { infos: [], },
    row_cells: { infos: [], },
    glyphs: Map([]),
  }
}

///|
priv struct V2 {
  x : Double
  y : Double
}

///|
fn v_lerp(a : V2, b : V2, t : Double) -> V2 {
  { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t, }
}

///|
fn v_sub(a : V2, b : V2) -> V2 {
  { x: a.x - b.x, y: a.y - b.y, }
}

///|
fn v_mult(a : V2, s : Double) -> V2 {
  { x: a.x * s, y: a.y * s, }
}

///|
priv struct Cubic {
  mut p0 : V2
  mut c0 : V2
  mut c1 : V2
  p1 : V2
}

///|
fn Cubic::quad_error(self : Cubic) -> Double {
  let v = v_sub(v_sub(self.p1, self.p0), v_mult(v_sub(self.c1, self.c0), 3))
  (v.x * v.x + v.y * v.y).sqrt() / 2
}

///|
fn Cubic::split(self : Cubic, t : Double) -> Cubic {
  let m1 = v_lerp(self.p0, self.c0, t)
  let m2 = v_lerp(self.c0, self.c1, t)
  let mm1 = v_lerp(m1, m2, t)
  self.c1 = v_lerp(self.c1, self.p1, t)
  self.c0 = v_lerp(m2, self.c1, t)
  let pt = v_lerp(mm1, self.c0, t)
  let part1 : Cubic = { p0: self.p0, c0: m1, c1: mm1, p1: pt, }
  self.p0 = pt
  part1
}

///|
fn Cubic::split_inflections(self : Cubic) -> Array[Cubic] {
  let a = v_sub(self.c0, self.p0)
  let b = v_sub(v_sub(self.c1, self.c0), a)
  let c = v_sub(v_sub(v_sub(self.p1, self.c1), a), v_mult(b, 2))
  let cubics : Array[Cubic] = []
  let mut aa = b.x * c.y - b.y * c.x
  if aa != 0 {
    let mut bb = a.x * c.y - a.y * c.x
    let mut cc = a.x * b.y - a.y * b.x
    let disc = bb * bb - 4.0 * aa * cc
    if disc >= 0 {
      if aa < 0 {
        aa = -aa
        bb = -bb
        cc = -cc
      }
      let q = disc.sqrt()
      let t0 = (-bb - q) / (2.0 * aa)
      let mut t1 = (-bb + q) / (2.0 * aa)
      if t0 > 0 && t0 < 1 {
        cubics.push(self.split(t0))
        t1 = 1.0 - (1.0 - t1) / (1.0 - t0)
      }
      if t1 > 0 && t1 < 1 {
        cubics.push(self.split(t1))
      }
    }
  }
  cubics.push(self)
  cubics
}

///|
fn Cubic::to_quadratic(
  self : Cubic,
) -> (Double, Double, Double, Double, Double, Double) {
  (
    self.p0.x,
    self.p0.y,
    self.p1.x,
    self.p1.y,
    ((self.c0.x + self.c1.x) * 3 - (self.p0.x + self.p1.x)) / 4,
    ((self.c0.y + self.c1.y) * 3 - (self.p0.y + self.p1.y)) / 4,
  )
}

///|
fn cubic_to_quadratics(
  x0 : Double,
  y0 : Double,
  cx0 : Double,
  cy0 : Double,
  cx1 : Double,
  cy1 : Double,
  x1 : Double,
  y1 : Double,
) -> Array[Cubic] {
  let cubics = (
    {
      p0: { x: x0, y: y0, },
      c0: { x: cx0, y: cy0, },
      c1: { x: cx1, y: cy1, },
      p1: { x: x1, y: y1, },
    } : Cubic).split_inflections()
  let qs : Array[Cubic] = []
  let precision = 30.0 / 1.7320508075688772
  for c in cubics {
    let mut cubic = c
    let tail : Array[Cubic] = []
    let mut t3 = 0.0
    for ;; {
      t3 = precision / cubic.quad_error()
      if t3 >= 0.5 * 0.5 * 0.5 {
        break
      }
      let t = js_pow(t3, 1.0 / 3.0)
      let start = cubic.split(t)
      let middle = cubic.split(1.0 - t / (1.0 - t))
      qs.push(start)
      tail.push(cubic)
      cubic = middle
    }
    if t3 < 1 {
      qs.push(cubic.split(0.5))
    }
    qs.push(cubic)
    tail.rev_in_place()
    qs.append(tail)
  }
  qs
}

///|
extern "js" fn js_pow(x : Double, y : Double) -> Double = "Math.pow"

///|
fn byte_val(v : Double) -> Double {
  (255.0 * v).clamp(min=0, max=255)
}

///|
fn FontInfo::glyph_info(
  self : FontInfo,
  data : @font.FontData,
  gid : Int32,
) -> GlyphInfo? {
  if self.glyphs.get(gid) is Some(gi) {
    return gi
  }
  let path = data.glyph_path(gid)
  // p5's _singleShapeToPath at scale 1: y is flipped
  let crds = path.crds.mapi((i, v) => if i % 2 == 1 { -v } else { v })
  let mut x_min = @double.infinity
  let mut x_max = @double.neg_infinity
  let mut y_min = @double.infinity
  let mut y_max = @double.neg_infinity
  for i = 0; i + 1 < crds.length(); i = i + 2 {
    x_min = x_min.min(crds[i])
    x_max = x_max.max(crds[i])
    y_min = y_min.min(crds[i + 1])
    y_max = y_max.max(crds[i + 1])
  }
  if x_min >= x_max || y_min >= y_max || path.cmds.is_empty() {
    self.glyphs[gid] = None
    return None
  }
  let gw = x_max - x_min
  let gh = y_max - y_min
  // strokes: (x, y, cx, cy) or a bare point (x, y)
  let strokes : Array[(Double, Double, Double?, Double?)] = []
  let rows : Array[Array[Int32]] = [ for _ in 0..<char_grid => [] ]
  let cols : Array[Array[Int32]] = [ for _ in 0..<char_grid => [] ]
  let push = (
    xs : Array[Double],
    ys : Array[Double],
    s : (Double, Double, Double?, Double?),
  ) => {
    let index = strokes.length()
    strokes.push(s)
    let mm = (rg : Array[Double]) => {
      let mut lo = 1.0
      let mut hi = 0.0
      let mut i = rg.length()
      while i > 0 {
        i -= 1
        let v = rg[i]
        if lo > v {
          lo = v
        }
        if hi < v {
          hi = v
        }
      }
      (lo, hi)
    }
    let (lo, hi) = mm(xs)
    let ix0 = @cmath.floor(lo * char_grid.to_double() - 0.5).to_int().max(0)
    let ix1 = @cmath.ceil(hi * char_grid.to_double() + 0.5)
      .to_int()
      .min(char_grid)
    for i in ix0..<ix1 {
      cols[i].push(index)
    }
    let (lo, hi) = mm(ys)
    let iy0 = @cmath.floor(lo * char_grid.to_double() - 0.5).to_int().max(0)
    let iy1 = @cmath.ceil(hi * char_grid.to_double() + 0.5)
      .to_int()
      .min(char_grid)
    for i in iy0..<iy1 {
      rows[i].push(index)
    }
  }
  let push_line = (x0 : Double, y0 : Double, x1 : Double, y1 : Double) => {
    push([x0, x1], [y0, y1], (x0, y0, Some((x0 + x1) / 2), Some((y0 + y1) / 2)))
  }
  let same = (x0 : Double, y0 : Double, x1 : Double, y1 : Double) => {
    (x1 - x0).abs() < 0.00001 && (y1 - y0).abs() < 0.00001
  }
  let mut x0 = @double.not_a_number
  let mut y0 = @double.not_a_number
  let mut xs = @double.not_a_number
  let mut ys = @double.not_a_number
  let mut k = 0
  for cmd in path.cmds {
    let n = match cmd {
      M | L => 2
      Q => 4
      C => 6
      Z => 0
    }
    // the command's end point (p5 reads cmd.x/cmd.y; Z has none -> NaN)
    let (ex, ey) = if n == 0 {
      (@double.not_a_number, @double.not_a_number)
    } else {
      (crds[k + n - 2], crds[k + n - 1])
    }
    let x1 = (ex - x_min) / gw
    let y1 = (ey - y_min) / gh
    if !same(x0, y0, x1, y1) {
      match cmd {
        M => {
          xs = x1
          ys = y1
        }
        L => push_line(x0, y0, x1, y1)
        Q => {
          let cx = (crds[k] - x_min) / gw
          let cy = (crds[k + 1] - y_min) / gh
          push([x0, x1, cx], [y0, y1, cy], (x0, y0, Some(cx), Some(cy)))
        }
        Z =>
          if !same(x0, y0, xs, ys) {
            push_line(x0, y0, xs, ys)
            strokes.push((xs, ys, None, None))
          } else {
            strokes.push((x0, y0, None, None))
          }
        C => {
          let cx1 = (crds[k] - x_min) / gw
          let cy1 = (crds[k + 1] - y_min) / gh
          let cx2 = (crds[k + 2] - x_min) / gw
          let cy2 = (crds[k + 3] - y_min) / gh
          for q in cubic_to_quadratics(x0, y0, cx1, cy1, cx2, cy2, x1, y1) {
            let (qx, qy, qx1, qy1, qcx, qcy) = q.to_quadratic()
            push([qx, qx1, qcx], [qy, qy1, qcy], (qx, qy, Some(qcx), Some(qcy)))
          }
        }
      }
      x0 = x1
      y0 = y1
    }
    k += n
  }
  let (stroke_info, stroke_offset) = self.strokes.find(strokes.length())
  stroke_info.index = stroke_offset
  for s in strokes {
    let (x, y, cx, cy) = s
    // a missing control point is `undefined`: 255 * undefined is NaN -> 0
    stroke_info.set_pixel(
      byte_val(x),
      byte_val(y),
      match cx {
        Some(v) => byte_val(v)
        None => 0
      },
      match cy {
        Some(v) => byte_val(v)
        None => 0
      },
    )
  }
  let layout = (
    dim : Array[Array[Int32]],
    dims : ImageInfos,
    cells : ImageInfos,
  ) => {
    let (dim_info, dim_offset) = dims.find(dim.length())
    dim_info.index = dim_offset
    let total = dim.fold(init=0, (a, d) => a + d.length())
    let (cell_info, cell_start) = cells.find(total)
    cell_info.index = cell_start
    for indices in dim {
      let line = cell_info.index
      dim_info.set_pixel(
        (line >> 7).to_double(),
        (line & 0x7f).to_double(),
        (indices.length() >> 7).to_double(),
        (indices.length() & 0x7f).to_double(),
      )
      for si in indices {
        let s = si + stroke_offset
        cell_info.set_pixel((s >> 7).to_double(), (s & 0x7f).to_double(), 0, 0)
      }
    }
    (cell_info, dim_info, dim_offset)
  }
  let (col_cells, col_dims, col_off) = layout(
    cols,
    self.col_dims,
    self.col_cells,
  )
  let (row_cells, row_dims, row_off) = layout(
    rows,
    self.row_dims,
    self.row_cells,
  )
  let gi : GlyphInfo = {
    rect: [x_min, y_min, x_max, y_max],
    strokes: stroke_info,
    row_cells,
    row_dims,
    col_cells,
    col_dims,
    grid_offset: [col_off.to_double(), row_off.to_double()],
  }
  self.glyphs[gid] = Some(gi)
  Some(gi)
}

///|
fn Renderer3D::data_tex(self : Renderer3D, info : ImageInfo) -> @gl.Texture {
  let t = @gl.data_texture(
    self.gl,
    info.data,
    image_size,
    image_size,
    info.dirty,
  )
  info.dirty = false
  t
}

///|
/// Draws one line of text at `(x, y)` with a loaded font (p5's
/// `_renderText` in WEBGL). `fill` is the text color (RGBA in [0, 1]).
pub fn Renderer3D::render_text(
  self : Renderer3D,
  font_key : String,
  data : @font.FontData,
  line : String,
  x : Double,
  y : Double,
  size : Double,
  fill : FixedArray[Double],
  style : Style,
) -> Unit {
  let info = match self.font_infos.get(font_key) {
    Some(i) => i
    None => {
      let i = FontInfo::new()
      self.font_infos[font_key] = i
      i
    }
  }
  self.push()
  let saved_tex = self.state.tex
  let upem = if data.units_per_em == 0 { 1000 } else { data.units_per_em }
  let scale = size / upem.to_double()
  self.translate(x, y, 0)
  self.scale(scale, scale, 1)
  let sh = match self.shaders.get("font") {
    Some(s) => s
    None => {
      let webgl2 = @gl.version(self.gl) == 2
      let s = Shader::raw(
        compat_prefix(webgl2, true) +
        glsl_webgl2compatibility_glsl +
        glsl_font_vert,
        compat_prefix(webgl2, false) +
        glsl_webgl2compatibility_glsl +
        glsl_font_frag,
      )
      self.shaders["font"] = s
      s
    }
  }
  guard sh.init(self.gl) is Some(p) else {
    self.pop()
    return
  }
  @gl.use_program(p)
  @gl.set_uniform(p, "uGridImageSize", [64, 64])
  @gl.set_uniform(p, "uCellsImageSize", [64, 64])
  @gl.set_uniform(p, "uStrokeImageSize", [64, 64])
  @gl.set_uniform(p, "uGridSize", [9, 9])
  self.set_global_uniforms(p)
  // drawMode TEXTURE during text: blending is on
  self.state.tex = Some({ elt: None, fb: None, width: 0, height: 0, })
  self.apply_color_blend(style, fill[3], false)
  let g = self.cached_geometry("glyph", () => {
    let g = Geometry::new()
    for i in 0..<=1 {
      for j in 0..<=1 {
        g.vertices.push(Vec3::new(j.to_double(), i.to_double(), 0))
        g.uvs.push(j.to_double())
        g.uvs.push(i.to_double())
      }
    }
    ignore(g.compute_faces().compute_normals())
    g
  })
  let b = self.cached(g)
  self.prepare(
    b,
    p,
    "aPosition",
    "vertex",
    3,
    () => flat3(g.vertices),
    g.vertices.length(),
    false,
  )
  self.prepare(
    b,
    p,
    "aTexCoord",
    "uv",
    2,
    () => FixedArray::from_array(g.uvs),
    g.uvs.length(),
    false,
  )
  @gl.set_uniform(p, "uMaterialColor", fill)
  @gl.disable_other_attribs(p)
  let mut gx = 0.0
  for sg in data.shape(line) {
    if info.glyph_info(data, sg.glyph) is Some(gi) {
      @gl.set_uniform_texture(p, "uSamplerStrokes", self.data_tex(gi.strokes))
      @gl.set_uniform_texture(
        p,
        "uSamplerRowStrokes",
        self.data_tex(gi.row_cells),
      )
      @gl.set_uniform_texture(p, "uSamplerRows", self.data_tex(gi.row_dims))
      @gl.set_uniform_texture(
        p,
        "uSamplerColStrokes",
        self.data_tex(gi.col_cells),
      )
      @gl.set_uniform_texture(p, "uSamplerCols", self.data_tex(gi.col_dims))
      @gl.set_uniform(p, "uGridOffset", gi.grid_offset)
      @gl.set_uniform(p, "uGlyphRect", gi.rect)
      @gl.set_uniform(p, "uGlyphOffset", [gx])
      @gl.bind_textures(p, self.empty_texture())
      match b.index {
        Some(index) => @gl.draw_elements(self.gl, index, 6, false, 1)
        None => ()
      }
    }
    gx += sg.advance.to_double()
  }
  self.state.tex = saved_tex
  self.pop()
}
