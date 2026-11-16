// Port of p5.js src/dom/p5.MediaElement.js: video, audio and camera
// capture elements. Videos can be drawn with image() and read as pixels.

///|
priv struct Cue {
  id : Int32
  time : Double
  callback : () -> Unit
}

///|
/// A `<video>` or `<audio>` element (p5.MediaElement).
pub struct MediaElement {
  /// The DOM element, for positioning, styling, hiding, etc.
  element : Element
  /// Width of the video in pixels (0 until its metadata has loaded).
  mut width : Double
  /// Height of the video in pixels.
  mut height : Double
  /// Pixels filled by `load_pixels()`.
  mut pixels : FixedArray[Byte]
  priv sketch : P5
  priv canvas : @dom.Canvas
  priv flipped : Bool
  priv mut loaded : Bool
  priv mut frame_on_canvas : Int32
  priv mut preset_speed : Double?
  priv cues : Array[Cue]
  priv mut next_cue : Int32
  priv mut prev_time : Double
}

///|
fn P5::make_media(
  self : P5,
  elt : @dom.Element,
  flipped : Bool,
) -> MediaElement {
  let e = wrap(elt)
  self.elements.push(e)
  let m : MediaElement = {
    element: e,
    width: 0,
    height: 0,
    pixels: [],
    sketch: self,
    canvas: @dom.create_canvas(1, 1, 1, "", false),
    flipped,
    loaded: false,
    frame_on_canvas: -1,
    preset_speed: None,
    cues: [],
    next_cue: 0,
    prev_time: 0,
  }
  @dom.media_on_time_update(elt, now => {
    for cue in m.cues {
      if cue.time <= now && cue.time > m.prev_time {
        (cue.callback)()
      }
    }
    m.prev_time = now
  })
  m
}

///|
fn MediaElement::on_metadata(self : MediaElement, w : Int32, h : Int32) -> Unit {
  let size = @dom.element_attr_size(self.element.elt)
  self.width = if size[0] > 0 { size[0] } else { w.to_double() }
  self.height = if size[1] > 0 { size[1] } else { h.to_double() }
  if self.preset_speed is Some(s) {
    @dom.media_set_number(self.element.elt, "playbackRate", s)
    self.preset_speed = None
  }
  self.loaded = true
}

///|
fn P5::create_media(
  self : P5,
  kind : String,
  sources : Array[String],
  on_load : ((MediaElement) -> Unit)?,
) -> MediaElement {
  let cell : Ref[MediaElement?] = Ref(None)
  let elt = @dom.create_media(
    kind,
    FixedArray::from_array(sources),
    self.container,
    (w, h) => if cell.val is Some(m) { m.on_metadata(w, h) },
    () => if cell.val is Some(m) && on_load is Some(f) { f(m) },
  )
  let m = self.make_media(elt, false)
  cell.val = Some(m)
  m
}

///|
/// Creates a `<video>` from one or more source URLs (alternative formats).
/// `on_load` runs when it can play through. Hide it with
/// `.element.hide()` to draw it on the canvas with `image()` instead.
pub fn P5::create_video(
  self : P5,
  sources : Array[String],
  on_load? : (MediaElement) -> Unit,
) -> MediaElement {
  self.create_media("video", sources, on_load)
}

///|
/// Creates an `<audio>` element from one or more source URLs.
pub fn P5::create_audio(
  self : P5,
  sources : Array[String],
  on_load? : (MediaElement) -> Unit,
) -> MediaElement {
  self.create_media("audio", sources, on_load)
}

///|
/// Captures the webcam (and/or microphone) in a `<video>`, like p5's
/// `createCapture()`. The browser asks the user for permission. With
/// `flipped`, the image is mirrored.
pub fn P5::create_capture(
  self : P5,
  video~ : Bool = true,
  audio~ : Bool = false,
  flipped~ : Bool = false,
  on_ready? : (MediaElement) -> Unit,
) -> MediaElement {
  let cell : Ref[MediaElement?] = Ref(None)
  let elt = @dom.create_capture(
    video,
    audio,
    flipped,
    self.container,
    (w, h) => {
      if cell.val is Some(m) {
        m.on_metadata(w, h)
        if on_ready is Some(f) {
          f(m)
        }
      }
    },
    msg => warn(msg),
  )
  let m = self.make_media(elt, flipped)
  cell.val = Some(m)
  m
}

///|
/// Copies the current video frame into the hidden canvas, at most once
/// per sketch frame (p5's `_ensureCanvas`).
fn MediaElement::ensure_canvas(self : MediaElement) -> Unit {
  if self.loaded && self.frame_on_canvas != self.sketch.frame_count {
    @dom.media_to_canvas(self.element.elt, self.canvas, self.flipped)
    self.frame_on_canvas = self.sketch.frame_count
  }
}

///|
pub impl ImageSource for MediaElement with fn image_source(self) {
  if !self.loaded {
    return None
  }
  self.ensure_canvas()
  Some(
    (
      @dom.canvas_as_image(self.canvas),
      @dom.canvas_width(self.canvas),
      @dom.canvas_height(self.canvas),
      self.width,
      self.height,
    ),
  )
}

///|
/// Plays from the current position (from the start when it had ended).
pub fn MediaElement::play(self : MediaElement) -> Unit {
  @dom.media_play(self.element.elt)
}

///|
/// Pauses playback.
pub fn MediaElement::pause(self : MediaElement) -> Unit {
  @dom.media_pause(self.element.elt)
}

///|
/// Stops playback and rewinds.
pub fn MediaElement::stop(self : MediaElement) -> Unit {
  @dom.media_stop(self.element.elt)
}

///|
/// Plays in a loop.
pub fn MediaElement::loop_(self : MediaElement) -> Unit {
  @dom.media_set_loop(self.element.elt, true)
  self.play()
}

///|
/// Stops looping (playback continues to the end).
pub fn MediaElement::no_loop(self : MediaElement) -> Unit {
  @dom.media_set_loop(self.element.elt, false)
}

///|
/// Sets whether the media starts playing on its own.
pub fn MediaElement::autoplay(self : MediaElement, on : Bool) -> Unit {
  @dom.media_set_autoplay(self.element.elt, on)
}

///|
/// Sets the volume (0 to 1).
pub fn MediaElement::volume(self : MediaElement, v : Double) -> Unit {
  @dom.media_set_number(self.element.elt, "volume", v)
}

///|
/// The volume.
pub fn MediaElement::get_volume(self : MediaElement) -> Double {
  @dom.media_get_number(self.element.elt, "volume")
}

///|
/// Sets the playback speed (1 is normal).
pub fn MediaElement::speed(self : MediaElement, v : Double) -> Unit {
  if self.loaded {
    @dom.media_set_number(self.element.elt, "playbackRate", v)
  } else {
    self.preset_speed = Some(v)
  }
}

///|
/// The playback speed.
pub fn MediaElement::get_speed(self : MediaElement) -> Double {
  match self.preset_speed {
    Some(s) => s
    None => @dom.media_get_number(self.element.elt, "playbackRate")
  }
}

///|
/// The current position in seconds.
pub fn MediaElement::time(self : MediaElement) -> Double {
  @dom.media_get_number(self.element.elt, "currentTime")
}

///|
/// Jumps to a position in seconds.
pub fn MediaElement::set_time(self : MediaElement, t : Double) -> Unit {
  @dom.media_set_number(self.element.elt, "currentTime", t)
}

///|
/// The length in seconds.
pub fn MediaElement::duration(self : MediaElement) -> Double {
  @dom.media_get_number(self.element.elt, "duration")
}

///|
/// Shows the browser's playback controls.
pub fn MediaElement::show_controls(self : MediaElement) -> Unit {
  @dom.media_set_controls(self.element.elt, true)
}

///|
/// Hides the browser's playback controls.
pub fn MediaElement::hide_controls(self : MediaElement) -> Unit {
  @dom.media_set_controls(self.element.elt, false)
}

///|
/// Calls `f` when playback reaches the end.
pub fn MediaElement::on_ended(
  self : MediaElement,
  f : (MediaElement) -> Unit,
) -> Unit {
  @dom.media_on_ended(self.element.elt, () => f(self))
}

///|
/// Calls `callback` when playback passes `time` (seconds). Returns an id
/// for `remove_cue`.
pub fn MediaElement::add_cue(
  self : MediaElement,
  time : Double,
  callback : () -> Unit,
) -> Int32 {
  let id = self.next_cue
  self.next_cue += 1
  self.cues.push({ id, time, callback, })
  id
}

///|
/// Removes a cue added with `add_cue`.
pub fn MediaElement::remove_cue(self : MediaElement, id : Int32) -> Unit {
  match self.cues.search_by(c => c.id == id) {
    Some(i) => ignore(self.cues.remove(i))
    None => ()
  }
}

///|
/// Removes every cue.
pub fn MediaElement::clear_cues(self : MediaElement) -> Unit {
  self.cues.clear()
}

///|
/// Loads the current video frame into `pixels`.
pub fn MediaElement::load_pixels(self : MediaElement) -> Unit {
  self.ensure_canvas()
  let w = @dom.canvas_width(self.canvas)
  let h = @dom.canvas_height(self.canvas)
  let surface : &Surface = CanvasSurface::new(self.canvas)
  self.pixels = surface.read_pixels(0, 0, w, h)
}

///|
/// The color of the current frame at `(x, y)`.
pub fn MediaElement::get(self : MediaElement, x : Double, y : Double) -> Color {
  self.ensure_canvas()
  let w = @dom.canvas_width(self.canvas)
  let h = @dom.canvas_height(self.canvas)
  let xi = x.floor().to_int()
  let yi = y.floor().to_int()
  if !self.loaded || xi < 0 || yi < 0 || xi >= w || yi >= h {
    return Color::rgb(0, 0, 0, alpha=0)
  }
  let surface : &Surface = CanvasSurface::new(self.canvas)
  color_from_bytes(surface.read_pixels(xi, yi, 1, 1), 0)
}

///|
/// Sets the displayed size of the element (and of the frames drawn from
/// it).
pub fn MediaElement::size(self : MediaElement, w : Double, h : Double) -> Unit {
  @dom.set_element_size(self.element.elt, w, h)
  self.width = w
  self.height = h
  self.frame_on_canvas = -1
}

///|
/// Hides the element (it can still be drawn with `image()`).
pub fn MediaElement::hide(self : MediaElement) -> Unit {
  self.element.hide()
}

///|
/// Shows the element.
pub fn MediaElement::show(self : MediaElement) -> Unit {
  self.element.show()
}

///|
/// Positions the element on the page.
pub fn MediaElement::position(
  self : MediaElement,
  x : Double,
  y : Double,
) -> Unit {
  self.element.position(x, y)
}
