// Port of p5.js src/image/{p5.Image,image,loading_displaying,pixels}.js for
// the 2D renderer.

///|
/// An image (loaded from a file or created with `create_image`), backed by
/// an off-screen canvas. Use `load_pixels` / `pixels` / `update_pixels` to
/// edit pixels.
pub struct Image {
  /// Width in pixels.
  mut width : Double
  /// Height in pixels.
  mut height : Double
  /// RGBA pixel data filled by `load_pixels()`.
  mut pixels : FixedArray[Byte]
  priv canvas : @dom.Canvas
  priv surface : &Surface
  priv mut gif : GifState?
}

///|
/// Playback state of an animated GIF (p5's `gifProperties`).
priv struct GifState {
  frames : Array[(FixedArray[Byte], Double)]
  mut display_index : Int32
  loop_limit : Int32?
  mut loop_count : Int32
  mut playing : Bool
  mut time_displayed : Double
  mut last_change_time : Double
}

///|
fn Image::with_size(w : Double, h : Double) -> Image {
  let w = w.max(1)
  let h = h.max(1)
  let canvas = @dom.create_canvas(w, h, 1, "", false)
  {
    width: w,
    height: h,
    pixels: [],
    canvas,
    surface: CanvasSurface::new(canvas),
    gif: None,
  }
}

///|
fn Image::device_w(self : Image) -> Int32 {
  self.width.to_int()
}

///|
fn Image::device_h(self : Image) -> Int32 {
  self.height.to_int()
}

///|
/// Things that can be drawn with `image()`: `Image` and graphics buffers
/// (`P5` sketches created with `create_graphics`).
pub(open) trait ImageSource {
  /// The source element, its size in device pixels and its size in logical
  /// pixels.
  fn image_source(Self) -> (@dom.ImageElement, Int32, Int32, Double, Double)?
  /// Called before the source is drawn at time `now` (ms), so animated
  /// sources can advance.
  fn advance(Self, now : Double) -> Unit = _
  /// The source as a WEBGL texture.
  fn gl_source(Self) -> @webgl.TexSource? = _
}

///|
impl ImageSource with fn gl_source(self) {
  self
  .image_source()
  .map(s => { elt: Some(s.0), fb: None, width: s.3, height: s.4, })
}

///|
impl ImageSource with fn advance(_self, _now) {

}

///|
pub impl ImageSource for Image with fn image_source(self) {
  Some(
    (
      @dom.canvas_as_image(self.canvas),
      self.device_w(),
      self.device_h(),
      self.width,
      self.height,
    ),
  )
}

///|
pub impl ImageSource for P5 with fn image_source(self) {
  match self.canvas() {
    None => None
    Some(c) =>
      Some(
        (
          @dom.canvas_as_image(c),
          @dom.canvas_width(c),
          @dom.canvas_height(c),
          self.width,
          self.height,
        ),
      )
  }
}

///|
/// Loads the pixels of the image into `pixels`.
pub fn Image::load_pixels(self : Image) -> Unit {
  self.pixels = self.surface.read_pixels(0, 0, self.device_w(), self.device_h())
}

///|
/// Writes `pixels` back into the image.
pub fn Image::update_pixels(self : Image) -> Unit {
  if self.pixels.length() == self.device_w() * self.device_h() * 4 {
    self.surface.write_pixels(
      self.pixels,
      0,
      0,
      self.device_w(),
      self.device_h(),
    )
  }
}

///|
fn color_from_bytes(px : FixedArray[Byte], i : Int32) -> Color {
  Color::rgb(
    px[i].to_double(),
    px[i + 1].to_double(),
    px[i + 2].to_double(),
    alpha=px[i + 3].to_double(),
  )
}

///|
/// The color of one pixel (transparent black outside the image).
pub fn Image::get(self : Image, x : Double, y : Double) -> Color {
  let xi = x.floor().to_int()
  let yi = y.floor().to_int()
  if xi < 0 || yi < 0 || xi >= self.device_w() || yi >= self.device_h() {
    return Color::rgb(0, 0, 0, alpha=0)
  }
  color_from_bytes(self.surface.read_pixels(xi, yi, 1, 1), 0)
}

///|
/// A copy of a rectangular region (the whole image by default).
pub fn Image::get_region(
  self : Image,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Image {
  let out = Image::with_size(w, h)
  @dom.copy_region(
    out.canvas,
    @dom.canvas_as_image(self.canvas),
    x,
    y,
    w,
    h,
    0,
    0,
    w,
    h,
  )
  out
}

///|
/// A copy of the image.
pub fn Image::copy(self : Image) -> Image {
  self.get_region(0, 0, self.width, self.height)
}

///|
/// Sets one pixel in `pixels` (loading them first if needed). Call
/// `update_pixels()` to apply.
pub fn Image::set(self : Image, x : Double, y : Double, c : Color) -> Unit {
  if self.pixels.length() == 0 {
    self.load_pixels()
  }
  let xi = x.floor().to_int()
  let yi = y.floor().to_int()
  if xi < 0 || yi < 0 || xi >= self.device_w() || yi >= self.device_h() {
    return
  }
  let (r, g, b, a) = c.rgba()
  let i = (yi * self.device_w() + xi) * 4
  self.pixels[i] = @filters.clamp_byte(r)
  self.pixels[i + 1] = @filters.clamp_byte(g)
  self.pixels[i + 2] = @filters.clamp_byte(b)
  self.pixels[i + 3] = @filters.clamp_byte(a)
}

///|
/// Resizes the image. A size of 0 keeps the aspect ratio.
pub fn Image::resize(self : Image, w : Double, h : Double) -> Unit {
  let (w, h) = if w == 0 && h == 0 {
    (self.width, self.height)
  } else if w == 0 {
    (self.width * h / self.height, h)
  } else if h == 0 {
    (w, self.height * w / self.width)
  } else {
    (w, h)
  }
  let w = w.floor().max(1)
  let h = h.floor().max(1)
  let tmp = Image::with_size(self.width, self.height)
  @dom.blit(
    tmp.canvas,
    @dom.canvas_as_image(self.canvas),
    self.width,
    self.height,
  )
  @dom.resize_canvas(self.canvas, w, h, 1)
  @dom.blit(self.canvas, @dom.canvas_as_image(tmp.canvas), w, h)
  self.width = w
  self.height = h
  if self.pixels.length() > 0 {
    self.load_pixels()
  }
}

///|
/// Copies a region of `src` into a region of this image, scaling it.
pub fn[I : ImageSource] Image::copy_from(
  self : Image,
  src : I,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit {
  guard src.image_source() is Some((elt, dw_px, _, lw, _)) else { return }
  let s = dw_px.to_double() / lw
  @dom.copy_region(
    self.canvas,
    elt,
    sx * s,
    sy * s,
    sw * s,
    sh * s,
    dx,
    dy,
    dw,
    dh,
  )
}

///|
/// Uses the alpha channel of `mask` as this image's alpha.
pub fn[I : ImageSource] Image::mask(self : Image, mask : I) -> Unit {
  guard mask.image_source() is Some((elt, _, _, _, _)) else { return }
  @dom.apply_mask(self.canvas, elt)
}

///|
fn apply_filter(px : FixedArray[Byte], width : Int32, f : Filter) -> Unit {
  match f {
    Threshold(level) => @filters.threshold(px, level~)
    Gray => @filters.gray(px)
    Opaque => @filters.make_opaque(px)
    Invert => @filters.invert(px)
    Posterize(levels) => @filters.posterize(px, levels~)
    Blur(radius) => @filters.blur(px, width, radius)
    Erode => @filters.erode(px, width)
    Dilate => @filters.dilate(px, width)
  }
}

///|
/// Applies a filter to the image.
pub fn Image::filter(self : Image, f : Filter) -> Unit {
  self.load_pixels()
  apply_filter(self.pixels, self.device_w(), f)
  self.update_pixels()
}

///|
/// Downloads the image as a PNG.
pub fn Image::save(self : Image, filename~ : String = "untitled") -> Unit {
  @dom.download_url(
    @dom.to_data_url(self.canvas, "image/png"),
    filename + ".png",
  )
}

///|
/// Creates a blank (transparent) image.
pub fn P5::create_image(_self : P5, w : Double, h : Double) -> Image {
  Image::with_size(w, h)
}

///|
fn repr_error(e : @gif.GifError) -> String {
  match e {
    GifError(msg) => msg
  }
}

///|
/// Loads an image from a URL. The returned image is 1×1 until it has
/// loaded; when called in `preload`, `setup` waits for it. Animated GIFs are
/// decoded frame by frame and play when drawn with `image()`.
pub fn P5::load_image(
  self : P5,
  url : String,
  on_load? : (Image) -> Unit,
) -> Image {
  let img = Image::with_size(1, 1)
  self.begin_load()
  let loaded = () => {
    if on_load is Some(f) {
      f(img)
    }
    self.end_load()
  }
  let failed = (msg : String) => {
    warn(msg)
    self.end_load()
  }
  let path = match url.find("?") {
    Some(i) =>
      url.to_array()[:i].iter().fold(init="", (s, c) => s + c.to_string())
    None => url
  }
  if path.to_lower().has_suffix(".gif") {
    // Animated GIFs are decoded in MoonBit, like p5 does with omggif.
    @dom.fetch_bytes(
      url,
      bytes => {
        img.load_gif_bytes(Bytes::from_iter(bytes.iter())) catch {
          e => {
            failed("Could not decode GIF \{url}: \{repr_error(e)}")
            return
          }
        }
        loaded()
      },
      failed,
    )
  } else {
    @dom.load_image(
      url,
      (elt, w, h) => {
        img.width = w.to_double()
        img.height = h.to_double()
        @dom.resize_canvas(img.canvas, img.width, img.height, 1)
        @dom.blit(img.canvas, elt, img.width, img.height)
        loaded()
      },
      failed,
    )
  }
  img
}

///|
/// Sets how `image()` interprets its position and size arguments
/// (`Corner`, `Corners` or `Center`).
pub fn P5::image_mode(self : P5, mode : ShapeMode) -> Unit {
  self.state.image_mode = mode
}

///|
/// Tints images drawn afterwards with a color (alpha makes them
/// translucent).
pub fn[C : ColorArg] P5::tint(self : P5, c : C) -> Unit {
  self.state.tint = Some(c.to_color(self))
}

///|
/// Removes the tint.
pub fn P5::no_tint(self : P5) -> Unit {
  self.state.tint = None
}

///|
/// Draws an image (or graphics buffer) at `(x, y)`, optionally scaled to
/// `w`×`h`, following `image_mode()`.
pub fn[I : ImageSource] P5::image(
  self : P5,
  img : I,
  x : Double,
  y : Double,
  w? : Double,
  h? : Double,
  fit? : ImageFit,
  x_align? : HAlign,
  y_align? : VAlign,
) -> Unit {
  let size = match img.image_source() {
    Some((_, _, _, lw, lh)) => Some((lw, lh))
    None => img.gl_source().map(s => (s.width, s.height))
  }
  guard size is Some((lw, lh)) else { return }
  self.image_region(
    img,
    x,
    y,
    w.unwrap_or(lw),
    h.unwrap_or(lh),
    0,
    0,
    lw,
    lh,
    fit?,
    x_align?,
    y_align?,
  )
}

///|
/// How `image()` fits an image into a destination of another aspect ratio
/// (p5's `CONTAIN` and `COVER`).
#derive(Eq, Debug)
pub(all) enum ImageFit {
  /// Scale the image down to fit entirely inside, keeping its proportions.
  Contain
  /// Crop the image so it fills the destination, keeping its proportions.
  Cover
}

///|
/// p5's `_imageFit`: adjusts the source (cover) or destination (contain)
/// rectangle.
fn image_fit(
  fit : ImageFit,
  x_align : HAlign,
  y_align : VAlign,
  d : (Double, Double, Double, Double),
  s : (Double, Double, Double, Double),
) -> ((Double, Double, Double, Double), (Double, Double, Double, Double)) {
  let (dx, dy, dw, dh) = d
  let (sx, sy, sw, sh) = s
  let shift_x = (room : Double) => {
    match x_align {
      HCenter => room / 2
      Right => room
      _ => 0.0
    }
  }
  let shift_y = (room : Double) => {
    match y_align {
      VCenter => room / 2
      Bottom => room
      _ => 0.0
    }
  }
  match fit {
    Cover => {
      let r = (dw / sw).max(dh / sh)
      let aw = dw / r
      let ah = dh / r
      (d, (sx + shift_x(sw - aw), sy + shift_y(sh - ah), aw, ah))
    }
    Contain => {
      let r = (sw / dw).max(sh / dh)
      let aw = sw / r
      let ah = sh / r
      ((dx + shift_x(dw - aw), dy + shift_y(dh - ah), aw, ah), s)
    }
  }
}

///|
/// Draws the source rectangle `(sx, sy, sw, sh)` of an image into the
/// destination rectangle `(dx, dy, dw, dh)` (interpreted with
/// `image_mode()`).
pub fn[I : ImageSource] P5::image_region(
  self : P5,
  img : I,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  fit? : ImageFit,
  x_align~ : HAlign = HCenter,
  y_align~ : VAlign = VCenter,
) -> Unit {
  let fitted = (x : Double, y : Double, w : Double, h : Double) => {
    match fit {
      Some(f) => image_fit(f, x_align, y_align, (x, y, w, h), (sx, sy, sw, sh))
      None => ((x, y, w, h), (sx, sy, sw, sh))
    }
  }
  img.advance(
    if self.recording is Some(_) || !self.is_main {
      self.last_real_frame_time
    } else {
      @dom.now()
    },
  )
  if self.gl is Some(r) {
    guard img.gl_source() is Some(src) else { return }
    let (x, y, w, h) = @shape.mode_adjust(dx, dy, dw, dh, self.state.image_mode)
    let (w, h) = if self.state.image_mode is Corner { (dw, dh) } else { (w, h) }
    let ((x, y, w, h), (sx, sy, sw, sh)) = fitted(x, y, w, h)
    let s = match img.image_source() {
      Some((_, pw, _, lw, _)) => pw.to_double() / lw
      None => 1.0
    }
    self.gl_sync_tint()
    r.image(src, sx * s, sy * s, sw * s, sh * s, x, y, w, h, self.gl_style())
    return
  }
  guard img.image_source() is Some((elt, pw, ph, lw, _)) else { return }
  let (x, y, w, h) = @shape.mode_adjust(dx, dy, dw, dh, self.state.image_mode)
  let (w, h) = if self.state.image_mode is Corner { (dw, dh) } else { (w, h) }
  let ((x, y, w, h), (sx, sy, sw, sh)) = fitted(x, y, w, h)
  let s = pw.to_double() / lw
  let tint = self.state.tint.map(c => c.rgba())
  self.sync_transform()
  if self.state.erasing {
    self.surface.set_blend_mode(self.state.blend_mode)
  }
  self.surface.draw_image(
    elt,
    pw,
    ph,
    tint,
    sx * s,
    sy * s,
    sw * s,
    sh * s,
    x,
    y,
    w,
    h,
  )
  if self.state.erasing {
    self.surface.set_blend_mode(Remove)
  }
}

///|
fn P5::device_size(self : P5) -> (Int32, Int32) {
  (
    (self.width * self.density).round().to_int(),
    (self.height * self.density).round().to_int(),
  )
}

///|
/// Loads the canvas pixels into `pixels` (RGBA bytes, row by row, in device
/// pixels: the array is `pixel_density²` times larger than width×height).
pub fn P5::load_pixels(self : P5) -> Unit {
  let (w, h) = self.device_size()
  self.pixels = self.read_canvas(0, 0, w, h)
}

///|
/// Reads device pixels from the canvas (2D surface or WebGL buffer).
fn P5::read_canvas(
  self : P5,
  x : Int32,
  y : Int32,
  w : Int32,
  h : Int32,
) -> FixedArray[Byte] {
  match self.gl {
    Some(r) => r.read_pixels(x, y, w, h)
    None => self.surface.read_pixels(x, y, w, h)
  }
}

///|
/// Writes `pixels` back to the canvas.
pub fn P5::update_pixels(self : P5) -> Unit {
  let (w, h) = self.device_size()
  if self.pixels.length() == w * h * 4 {
    match self.gl {
      Some(r) => {
        // p5 draws the pixels as an image over the cleared canvas
        let c = @dom.create_canvas(
          self.width,
          self.height,
          self.density,
          "",
          false,
        )
        Surface::write_pixels(CanvasSurface::new(c), self.pixels, 0, 0, w, h)
        r.push()
        r.reset_matrix()
        r.clear(0, 0, 0, 0)
        r.image(
          {
            elt: Some(@dom.canvas_as_image(c)),
            fb: None,
            width: self.width,
            height: self.height,
          },
          0,
          0,
          self.width,
          self.height,
          -self.width / 2,
          -self.height / 2,
          self.width,
          self.height,
          { ..self.gl_style(), fill: Some([1, 1, 1, 1]), },
        )
        r.pop()
        r.clear_depth()
      }
      None => self.surface.write_pixels(self.pixels, 0, 0, w, h)
    }
  }
}

///|
/// The color of the canvas at `(x, y)`.
pub fn P5::get(self : P5, x : Double, y : Double) -> Color {
  let (w, h) = self.device_size()
  let xi = (x * self.density).floor().to_int()
  let yi = (y * self.density).floor().to_int()
  if xi < 0 || yi < 0 || xi >= w || yi >= h {
    return Color::rgb(0, 0, 0, alpha=0)
  }
  color_from_bytes(self.read_canvas(xi, yi, 1, 1), 0)
}

///|
/// Copies a region of the canvas into a new image.
pub fn P5::get_region(
  self : P5,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Image {
  let d = self.density
  let out = Image::with_size(w * d, h * d)
  if self.canvas is Some(c) {
    @dom.copy_region(
      out.canvas,
      @dom.canvas_as_image(c),
      x * d,
      y * d,
      w * d,
      h * d,
      0,
      0,
      w * d,
      h * d,
    )
  }
  out
}

///|
/// Sets a pixel in `pixels` (loading them first if needed); call
/// `update_pixels()` to show the change.
pub fn[C : ColorArg] P5::set(self : P5, x : Double, y : Double, c : C) -> Unit {
  let (w, h) = self.device_size()
  if self.pixels.length() != w * h * 4 {
    self.load_pixels()
  }
  let (r, g, b, a) = c.to_color(self).rgba()
  let d = self.density.to_int().max(1)
  let x0 = x.floor().to_int() * d
  let y0 = y.floor().to_int() * d
  for j in 0..<d {
    for i in 0..<d {
      let px = x0 + i
      let py = y0 + j
      if px >= 0 && py >= 0 && px < w && py < h {
        let idx = (py * w + px) * 4
        self.pixels[idx] = @filters.clamp_byte(r)
        self.pixels[idx + 1] = @filters.clamp_byte(g)
        self.pixels[idx + 2] = @filters.clamp_byte(b)
        self.pixels[idx + 3] = @filters.clamp_byte(a)
      }
    }
  }
}

///|
/// Applies a filter to the whole canvas, on the CPU (like p5's
/// `filter(type, param, false)`).
pub fn P5::filter(self : P5, f : Filter, use_webgl~ : Bool = true) -> Unit {
  let (op, param) : (String, Double?) = match f {
    Threshold(t) => ("threshold", Some(t))
    Gray => ("gray", None)
    Opaque => ("opaque", None)
    Invert => ("invert", None)
    Posterize(n) => ("posterize", Some(n.to_double()))
    Blur(r) => ("blur", Some(r))
    Erode => ("erode", None)
    Dilate => ("dilate", None)
  }
  if self.gl is Some(r) {
    r.filter(op, param, self.gl_style(), None)
    return
  }
  if use_webgl && self.canvas is Some(c) {
    self.filter_webgl_2d(c, op, param)
    return
  }
  let (w, _) = self.device_size()
  self.load_pixels()
  apply_filter(self.pixels, w, f)
  self.update_pixels()
}

///|
/// Creates an off-screen graphics buffer with the same drawing API as the
/// sketch. Draw it with `image()`.
pub fn P5::create_graphics(self : P5, w : Double, h : Double) -> P5 {
  let canvas = @dom.create_canvas(w, h, self.density, "", false)
  let g = P5::make(
    CanvasSurface::new(canvas),
    w,
    h,
    self.density,
    self.rng.next() * 4294967296.0,
  )
  g.canvas = Some(canvas)
  g.setup_done = true
  g.apply_defaults()
  g
}

///|
/// Removes the sketch's canvas from the page and stops the draw loop.
pub fn P5::remove(self : P5) -> Unit {
  self.looping = false
  if self.canvas is Some(c) {
    @dom.remove_canvas(c)
  }
}

///|
/// p5's FilterRenderer2D: the filter shader runs on a helper WebGL canvas
/// reading this canvas, and the result is drawn back.
fn P5::filter_webgl_2d(
  self : P5,
  c : @dom.Canvas,
  op : String,
  param : Double?,
  user? : @webgl.Shader,
) -> Unit {
  let fr = match self.filter2d {
    Some(f) => f
    None => {
      let f = @webgl.Filter2D::new(self.width, self.height)
      self.filter2d = Some(f)
      f
    }
  }
  let src = @dom.canvas_as_image(c)
  let w = self.width
  let h = self.height
  let draw_back = (out : @dom.ImageElement) => {
    self.surface.save()
    self.surface.set_transform(@math.identity)
    self.surface.clear_rect(0, 0, w * self.density, h * self.density)
    self.surface.set_transform(@math.identity.scale(self.density, self.density))
    self.surface.set_blend_mode(Blend)
    self.surface.draw_image(
      out,
      w.to_int(),
      h.to_int(),
      None,
      0,
      0,
      w,
      h,
      0,
      0,
      w,
      h,
    )
    self.surface.restore()
  }
  if op == "blur" {
    if fr.pass(op, param, (1, 0), src, w, h, self.density) is Some(out) {
      draw_back(out)
    }
    if fr.pass(op, param, (0, 1), src, w, h, self.density) is Some(out) {
      draw_back(out)
    }
  } else if fr.pass(op, param, (0, 0), src, w, h, self.density, user?)
    is Some(out) {
    draw_back(out)
  }
  self.surface.set_blend_mode(
    if self.state.erasing {
      Remove
    } else {
      self.state.blend_mode
    },
  )
}
