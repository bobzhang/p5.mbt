// Animated GIFs: loading (p5's _createGif), playback (p5.Image's
// _animateGif, play, pause, setFrame, ...), saveGif() and saveFrames().

///|
/// Decodes a GIF into an image, compositing frames with their disposal
/// methods like p5's `_createGif`.
fn Image::load_gif_bytes(
  self : Image,
  bytes : Bytes,
) -> Unit raise @gif.GifError {
  let reader = @gif.Reader::new(bytes)
  let w = reader.width
  let h = reader.height
  self.width = w.to_double()
  self.height = h.to_double()
  @dom.resize_canvas(self.canvas, self.width, self.height, 1)
  let canvas_px = FixedArray::make(w * h * 4, (0 : Byte))
  let frames : Array[(FixedArray[Byte], Double)] = []
  for j, info in reader.frames {
    let prev = canvas_px.copy()
    let frame_px = canvas_px.copy()
    reader.blit_frame_rgba(j, frame_px)
    frame_px.blit_to(canvas_px, len=frame_px.length())
    let delay = if info.delay == 0 { 10 } else { info.delay }
    frames.push((canvas_px.copy(), delay.to_double() * 10))
    let restore_region = (src : FixedArray[Byte]?) => {
      for y in info.y..<(info.y + info.height).min(h) {
        for x in info.x..<(info.x + info.width).min(w) {
          let i = (y * w + x) * 4
          for c in 0..<4 {
            canvas_px[i + c] = match src {
              Some(s) => s[i + c]
              None => 0
            }
          }
        }
      }
    }
    if info.disposal == 2 {
      restore_region(None)
    } else if info.disposal == 3 {
      restore_region(Some(prev))
    }
  }
  let loop_limit = match reader.loop_count {
    None => Some(1)
    Some(0) => None
    Some(n) => Some(n)
  }
  if frames.length() > 0 {
    self.surface.write_pixels(frames[0].0, 0, 0, w, h)
  }
  self.gif = if frames.length() > 1 {
    Some({
      frames,
      display_index: 0,
      loop_limit,
      loop_count: 0,
      playing: true,
      time_displayed: 0,
      last_change_time: 0,
    })
  } else {
    None
  }
}

///|
fn Image::show_gif_frame(self : Image, gif : GifState, index : Int32) -> Unit {
  self.surface.write_pixels(
    gif.frames[index].0,
    0,
    0,
    self.device_w(),
    self.device_h(),
  )
}

///|
pub impl ImageSource for Image with fn advance(self, now) {
  guard self.gif is Some(props) else { return }
  if props.last_change_time == 0 {
    props.last_change_time = now
  }
  if props.playing {
    props.time_displayed = now - props.last_change_time
    let cur_delay = props.frames[props.display_index].1
    if props.time_displayed >= cur_delay {
      let skips = (props.time_displayed / cur_delay).floor().to_int()
      props.time_displayed = 0
      props.last_change_time = now
      props.display_index += skips
      props.loop_count = props.display_index / props.frames.length()
      if props.loop_limit is Some(limit) && props.loop_count >= limit {
        props.playing = false
      } else {
        let ind = props.display_index % props.frames.length()
        self.show_gif_frame(props, ind)
        props.display_index = ind
      }
    }
  }
}

///|
/// Number of frames of an animated GIF (1 for still images).
pub fn Image::num_frames(self : Image) -> Int32 {
  match self.gif {
    Some(g) => g.frames.length()
    None => 1
  }
}

///|
/// Index of the frame currently shown.
pub fn Image::get_current_frame(self : Image) -> Int32 {
  match self.gif {
    Some(g) => g.display_index % g.frames.length()
    None => 0
  }
}

///|
/// Shows frame `index` of an animated GIF.
pub fn Image::set_frame(self : Image, index : Int32) -> Unit {
  guard self.gif is Some(g) else { return }
  if index >= 0 && index < g.frames.length() {
    g.time_displayed = 0
    g.last_change_time = 0
    g.display_index = index
    self.show_gif_frame(g, index)
  } else {
    warn(
      "Cannot set GIF to a frame number that is higher than total number of frames or below zero.",
    )
  }
}

///|
/// Resumes an animated GIF.
pub fn Image::play(self : Image) -> Unit {
  if self.gif is Some(g) {
    g.playing = true
  }
}

///|
/// Pauses an animated GIF.
pub fn Image::pause(self : Image) -> Unit {
  if self.gif is Some(g) {
    g.playing = false
  }
}

///|
/// Sets the delay (ms) of one frame, or of every frame when `index` is
/// omitted or out of range.
pub fn Image::delay(self : Image, ms : Double, index? : Int32) -> Unit {
  guard self.gif is Some(g) else { return }
  match index {
    Some(i) if i >= 0 && i < g.frames.length() =>
      g.frames[i] = (g.frames[i].0, ms)
    _ =>
      for i in 0..<g.frames.length() {
        g.frames[i] = (g.frames[i].0, ms)
      }
  }
}

///|
/// Restarts an animated GIF from its first frame.
pub fn Image::reset(self : Image) -> Unit {
  guard self.gif is Some(g) else { return }
  g.playing = true
  g.time_displayed = 0
  g.last_change_time = 0
  g.loop_count = 0
  g.display_index = 0
  self.show_gif_frame(g, 0)
}

///|
/// Builds an animated GIF from RGBA frames: a global palette (exact when
/// the frames use at most 256 colors, quantized otherwise) and pixels that
/// don't change between frames encoded as transparent, like p5.
fn encode_frames(
  frames : Array[FixedArray[Byte]],
  width : Int32,
  height : Int32,
  delays : Array[Double],
  repeat : Int32,
) -> Bytes {
  // exact palette when possible
  let colors : Map[Int32, Int32] = Map([])
  let mut exact = true
  for f in frames {
    for k in 0..<(f.length() / 4) {
      let c = (f[k * 4].to_int() << 16) |
        (f[k * 4 + 1].to_int() << 8) |
        f[k * 4 + 2].to_int()
      if !colors.contains(c) {
        if colors.length() >= 255 {
          exact = false
          break
        }
        colors[c] = colors.length()
      }
    }
  }
  let palette : Array[Array[Int32]] = if exact {
    [
      for c, _ in colors => [(c >> 16) & 255, (c >> 8) & 255, c & 255]
    ]
  } else {
    let all = FixedArray::make(frames.length() * width * height * 4, (0 : Byte))
    for i, f in frames {
      f.blit_to(all, len=f.length(), dst_offset=i * f.length())
    }
    @gif.quantize(all, 255, format=Rgb565)
  }
  let transparent_index = palette.length()
  palette.push([0, 0, 0])
  let cache : Map[Int32, Int32] = Map([])
  let index_of = (f : FixedArray[Byte], k : Int32) => {
    let c = (f[k * 4].to_int() << 16) |
      (f[k * 4 + 1].to_int() << 8) |
      f[k * 4 + 2].to_int()
    match cache.get(c) {
      Some(i) => i
      None => {
        let i = if exact {
          colors[c]
        } else {
          @gif.nearest_color_index(palette[:transparent_index], [
            (c >> 16) & 255,
            (c >> 8) & 255,
            c & 255,
          ])
        }
        cache[c] = i
        i
      }
    }
  }
  let enc = @gif.Encoder::new()
  let mut prev : FixedArray[Byte] = []
  for i, f in frames {
    let n = width * height
    let indexed = FixedArray::make(n, (0 : Byte))
    for k in 0..<n {
      indexed[k] = index_of(f, k).to_byte()
    }
    let original = indexed.copy()
    if i == 0 {
      enc.write_frame(
        indexed,
        width,
        height,
        palette~,
        delay=delays[i],
        repeat~,
        dispose=1,
      )
    } else {
      for k in 0..<n {
        if indexed[k] == prev[k] {
          indexed[k] = transparent_index.to_byte()
        }
      }
      enc.write_frame(
        indexed,
        width,
        height,
        delay=delays[i],
        transparent=true,
        transparent_index~,
        dispose=1,
      )
    }
    prev = original
  }
  enc.finish()
}

///|
/// Saves the image as a PNG, or as an animated GIF when `ext` is `"gif"`
/// and the image is an animated GIF.
pub fn Image::save_as(
  self : Image,
  filename : String,
  ext~ : String = "png",
) -> Unit {
  match (ext, self.gif) {
    ("gif", Some(g)) => {
      let repeat = match g.loop_limit {
        None => 0
        Some(1) => -1
        Some(n) => n
      }
      let bytes = encode_frames(
        g.frames.map(f => f.0),
        self.device_w(),
        self.device_h(),
        g.frames.map(f => f.1),
        repeat,
      )
      @dom.download_bytes(
        FixedArray::from_iter(bytes.iter()),
        "\{filename}.gif",
        "image/gif",
      )
    }
    _ => {
      let mime = if ext is ("jpg" | "jpeg") {
        "image/jpeg"
      } else {
        "image/png"
      }
      @dom.download_url(
        @dom.to_data_url(self.canvas, mime),
        "\{filename}.\{ext}",
      )
    }
  }
}

///|
/// Records the sketch for `duration` (seconds, or frames with
/// `units="frames"`) and downloads it as an animated GIF, like p5's
/// `saveGif()`. `delay` skips that much at the start; with `reset` (the
/// default) the frame count restarts from 0.
pub fn P5::save_gif(
  self : P5,
  filename : String,
  duration : Double,
  delay~ : Double = 0,
  units~ : String = "seconds",
  silent~ : Bool = false,
  reset~ : Bool = true,
  on_done~ : () -> Unit = () => (),
) -> Unit {
  let fps = if self.target_frame_rate.is_inf() || self.target_frame_rate == 0 {
    60.0
  } else {
    self.target_frame_rate
  }
  let frame_delay = (1000.0 / fps).max(20)
  let n_frames = if units == "seconds" { duration * fps } else { duration }
  let n_delay = if units == "seconds" { delay * fps } else { delay }
  let (start, total) = if reset {
    self.frame_count = n_delay.to_int()
    (n_delay, n_frames + n_delay)
  } else {
    let s = self.frame_count.to_double() + n_delay
    (s, s + n_frames)
  }
  let last_density = self.density
  self.pixel_density(1)
  let note = if silent { None } else { Some(self.create_p(html="")) }
  if note is Some(e) {
    e.style("font-size", "16px")
    e.style("background-color", "#ffffffa0")
    e.style("padding", "8px")
    e.style("border-radius", "10px")
    e.position(0, 0)
  }
  let was_looping = self.looping
  self.no_loop()
  let frames : Array[FixedArray[Byte]] = []
  let w = self.width.to_int()
  let h = self.height.to_int()
  let mut iterator = start
  let finish = () => {
    if note is Some(e) {
      e.html("Frames processed, generating color palette...")
    }
    let bytes = encode_frames(
      frames,
      w,
      h,
      Array::make(frames.length(), frame_delay),
      0,
    )
    self.pixel_density(last_density)
    if was_looping {
      self.loop_()
    }
    if note is Some(e) {
      e.remove()
    }
    @dom.download_bytes(
      FixedArray::from_iter(bytes.iter()),
      filename + ".gif",
      "image/gif",
    )
    on_done()
  }
  fn step() {
    if iterator >= total {
      finish()
      return
    }
    self.redraw_once()
    frames.push(self.read_canvas(0, 0, w, h))
    iterator += 1
    if note is Some(e) {
      e.html(
        "Saved frame <b>\{frames.length()}</b> out of \{n_frames.to_int()}",
      )
    }
    @dom.set_timeout(step, 0)
  }
  @dom.set_timeout(step, 0)
}

///|
/// A frame captured by `save_frames`.
pub(all) struct SavedFrame {
  /// The frame as a data URL.
  image_data : String
  filename : String
  ext : String
}

///|
/// Captures the canvas `fps` times per second for `duration` seconds (at
/// most 15 s and 22 fps, as in p5). With `on_done`, the frames are handed
/// to it; otherwise each one is downloaded.
pub fn P5::save_frames(
  self : P5,
  filename : String,
  ext : String,
  duration~ : Double = 3,
  fps~ : Double = 15,
  on_done? : (Array[SavedFrame]) -> Unit,
) -> Unit {
  guard self.canvas is Some(canvas) else { return }
  let duration = duration.min(15).max(0)
  let fps = fps.min(22).max(1)
  let total = (duration * fps).ceil().to_int()
  let mime = if ext is ("jpg" | "jpeg") { "image/jpeg" } else { "image/png" }
  let frames : Array[SavedFrame] = []
  fn capture() {
    let count = frames.length()
    frames.push({
      image_data: @dom.to_data_url(canvas, mime),
      filename: filename + count.to_string(),
      ext,
    })
    if frames.length() >= total {
      match on_done {
        Some(f) => f(frames)
        None =>
          for f in frames {
            @dom.download_url(f.image_data, "\{f.filename}.\{f.ext}")
          }
      }
    } else {
      @dom.set_timeout(capture, 1000.0 / fps)
    }
  }
  @dom.set_timeout(capture, 1000.0 / fps)
}

///|
/// Copies a region of `src` (an image, a graphics buffer, or the sketch
/// itself) into a region of the canvas, scaling it, like p5's `copy()`.
pub fn[I : ImageSource] P5::copy(
  self : P5,
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
  guard src.image_source() is Some((elt, pw, ph, lw, _)) else { return }
  let s = pw.to_double() / lw
  self.sync_transform()
  self.surface.draw_image(
    elt,
    pw,
    ph,
    None,
    s * sx,
    s * sy,
    s * sw,
    s * sh,
    dx,
    dy,
    dw,
    dh,
  )
}

///|
/// Copies a region like `copy`, combining pixels with `mode`, like p5's
/// `blend()`.
pub fn[I : ImageSource] P5::blend(
  self : P5,
  src : I,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
  mode : BlendMode,
) -> Unit {
  self.surface.set_blend_mode(mode)
  self.copy(src, sx, sy, sw, sh, dx, dy, dw, dh)
  self.surface.set_blend_mode(
    if self.state.erasing {
      Remove
    } else {
      self.state.blend_mode
    },
  )
}

///|
/// Combines a region of `src` into this image with `mode`.
pub fn[I : ImageSource] Image::blend_from(
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
  mode : BlendMode,
) -> Unit {
  self.surface.set_blend_mode(mode)
  self.copy_from(src, sx, sy, sw, sh, dx, dy, dw, dh)
  self.surface.set_blend_mode(Blend)
}
