// A surface that records drawing operations (for build_shape, shape(),
// getSVG() and saveSVG()), optionally forwarding them to another surface.

///|
/// One recorded drawing operation. Matrices map the operation's
/// coordinates to CSS pixels of the sketch.
pub(all) enum DrawOp {
  FillPath(@shape.Path, String, Matrix2D)
  StrokePath(@shape.Path, String, Double, StrokeCap, StrokeJoin, Matrix2D)
  FillRect(Double, Double, Double, Double, String, Matrix2D)
  FillText(String, Double, Double, String, String, HAlign, VAlign, Matrix2D)
  StrokeText(
    String,
    Double,
    Double,
    String,
    Double,
    String,
    HAlign,
    VAlign,
    Matrix2D
  )
  DrawImage(
    @dom.ImageElement,
    Int32,
    Int32,
    (Double, Double, Double, Double)?,
    (Double, Double, Double, Double),
    (Double, Double, Double, Double),
    Matrix2D
  )
  Clip(Matrix2D, Array[(@shape.Path, Matrix2D)])
  Save
  Restore
  SetBlend(BlendMode)
}

///|
/// Records the calls it receives as `DrawOp`s.
pub struct DisplayList {
  ops : Array[DrawOp]
  priv forward : &Surface?
  priv unscale : Matrix2D
  priv mut matrix : Matrix2D
  priv mut font : String
  priv mut align : HAlign
  priv mut baseline : VAlign
  priv measure : &Surface
}

///|
/// A display list recording a sketch with the given pixel density,
/// measuring text with `measure` and optionally forwarding every call.
pub fn DisplayList::new(
  density : Double,
  measure : &Surface,
  forward? : &Surface,
) -> DisplayList {
  {
    ops: [],
    forward,
    unscale: @math.identity.scale(1.0 / density, 1.0 / density),
    matrix: @math.identity,
    font: "12px sans-serif",
    align: Left,
    baseline: Baseline,
    measure,
  }
}

///|
fn DisplayList::user(self : DisplayList, m : Matrix2D) -> Matrix2D {
  self.unscale.multiply(m)
}

///|
pub impl Surface for DisplayList with fn set_transform(self, m) {
  self.matrix = self.user(m)
  if self.forward is Some(f) {
    f.set_transform(m)
  }
}

///|
pub impl Surface for DisplayList with fn save(self) {
  self.ops.push(Save)
  if self.forward is Some(f) {
    f.save()
  }
}

///|
pub impl Surface for DisplayList with fn restore(self) {
  self.ops.push(Restore)
  if self.forward is Some(f) {
    f.restore()
  }
}

///|
pub impl Surface for DisplayList with fn fill_path(self, path, style) {
  self.ops.push(FillPath(path, style, self.matrix))
  if self.forward is Some(f) {
    f.fill_path(path, style)
  }
}

///|
pub impl Surface for DisplayList with fn stroke_path(
  self,
  path,
  style,
  w,
  cap,
  join,
) {
  self.ops.push(StrokePath(path, style, w, cap, join, self.matrix))
  if self.forward is Some(f) {
    f.stroke_path(path, style, w, cap, join)
  }
}

///|
pub impl Surface for DisplayList with fn clip(self, base, parts) {
  self.ops.push(Clip(self.user(base), parts))
  if self.forward is Some(f) {
    f.clip(base, parts)
  }
}

///|
pub impl Surface for DisplayList with fn fill_rect(self, x, y, w, h, style) {
  self.ops.push(FillRect(x, y, w, h, style, self.matrix))
  if self.forward is Some(f) {
    f.fill_rect(x, y, w, h, style)
  }
}

///|
pub impl Surface for DisplayList with fn clear_rect(self, x, y, w, h) {
  if self.forward is Some(f) {
    f.clear_rect(x, y, w, h)
  }
}

///|
pub impl Surface for DisplayList with fn set_blend_mode(self, mode) {
  self.ops.push(SetBlend(mode))
  if self.forward is Some(f) {
    f.set_blend_mode(mode)
  }
}

///|
pub impl Surface for DisplayList with fn set_text_style(
  self,
  font,
  align,
  baseline,
  direction,
) {
  self.font = font
  self.align = align
  self.baseline = baseline
  self.measure.set_text_style(font, align, baseline, direction)
  if self.forward is Some(f) {
    f.set_text_style(font, align, baseline, direction)
  }
}

///|
pub impl Surface for DisplayList with fn fill_text(self, s, x, y, style) {
  self.ops.push(
    FillText(s, x, y, style, self.font, self.align, self.baseline, self.matrix),
  )
  if self.forward is Some(f) {
    f.fill_text(s, x, y, style)
  }
}

///|
pub impl Surface for DisplayList with fn stroke_text(
  self,
  s,
  x,
  y,
  style,
  w,
  join,
) {
  self.ops.push(
    StrokeText(
      s,
      x,
      y,
      style,
      w,
      self.font,
      self.align,
      self.baseline,
      self.matrix,
    ),
  )
  if self.forward is Some(f) {
    f.stroke_text(s, x, y, style, w, join)
  }
}

///|
pub impl Surface for DisplayList with fn measure_text(self, s) {
  self.measure.measure_text(s)
}

///|
pub impl Surface for DisplayList with fn draw_image(
  self,
  img,
  iw,
  ih,
  tint,
  sx,
  sy,
  sw,
  sh,
  dx,
  dy,
  dw,
  dh,
) {
  self.ops.push(
    DrawImage(
      img,
      iw,
      ih,
      tint,
      (sx, sy, sw, sh),
      (dx, dy, dw, dh),
      self.matrix,
    ),
  )
  if self.forward is Some(f) {
    f.draw_image(img, iw, ih, tint, sx, sy, sw, sh, dx, dy, dw, dh)
  }
}

///|
pub impl Surface for DisplayList with fn read_pixels(self, x, y, w, h) {
  match self.forward {
    Some(f) => f.read_pixels(x, y, w, h)
    None => self.measure.read_pixels(x, y, w, h)
  }
}

///|
pub impl Surface for DisplayList with fn write_pixels(self, bytes, x, y, w, h) {
  if self.forward is Some(f) {
    f.write_pixels(bytes, x, y, w, h)
  }
}

///|
pub impl Surface for DisplayList with fn resize(self, w, h, density) {
  if self.forward is Some(f) {
    f.resize(w, h, density)
  }
}

///|
pub impl Surface for DisplayList with fn set_smoothing(self, on) {
  if self.forward is Some(f) {
    f.set_smoothing(on)
  }
}

///|
pub impl Surface for DisplayList with fn set_css_filter(self, filter) {
  if self.forward is Some(f) {
    f.set_css_filter(filter)
  }
}
