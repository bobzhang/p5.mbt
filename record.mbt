// Offline recording: render a fixed number of frames at a fixed time step and
// upload each one, independently of the display's frame rate. Pair it with
// tools/record.py, which turns the frames into a video with ffmpeg.

///|
priv struct Recording {
  total : Int32
  fps : Double
  endpoint : String
  mut index : Int32
  on_done : () -> Unit
}

///|
/// Records the sketch instead of running it live: `draw` is called
/// `frames` times, as fast as possible, with `delta_time`, `millis()` and
/// `get_frame_rate()` advancing as if it ran at exactly `fps`. After each
/// frame the canvas is uploaded as a PNG to `endpoint` (`?frame=N`), and
/// `endpoint + "/done"` is notified at the end.
///
/// Call it in `setup`. Seed `random` and `noise` (e.g. `run(seed=…)`) for a
/// reproducible video.
///
/// ```mbt nocheck
/// setup=p => {
///   p.create_canvas(1920, 1080)
///   p.pixel_density(1)
///   if @p5.query_param("record") is Some(_) {
///     p.record(frames=1200)
///   }
/// }
/// ```
pub fn P5::record(
  self : P5,
  frames~ : Int32,
  fps~ : Double = 60,
  endpoint~ : String = "/frame",
  on_done~ : () -> Unit = () => (),
) -> Unit {
  self.recording = Some({ total: frames, fps, endpoint, index: 0, on_done, })
}

///|
/// Whether the sketch is being recorded with `record`.
pub fn P5::is_recording(self : P5) -> Bool {
  self.recording is Some(_)
}

///|
fn P5::record_step(self : P5) -> Unit {
  guard self.recording is Some(r) else { return }
  guard self.canvas() is Some(canvas) else { return }
  if r.index >= r.total {
    self.looping = false
    @dom.post_text(r.endpoint + "/done", "\{r.total}")
    print("p5.mbt: recorded \{r.total} frames")
    (r.on_done)()
    return
  }
  self.delta_time = 1000.0 / r.fps
  self.frame_rate_value = r.fps
  self.redraw_once()
  self.update_mouse_coords()
  r.index += 1
  @dom.upload_canvas_png(
    canvas,
    r.endpoint,
    r.index - 1,
    () => self.record_step(),
    msg => {
      warn("recording stopped at frame \{r.index - 1}: \{msg}")
      self.recording = None
    },
  )
}

///|
/// The value of a query parameter of the page URL (`?name=value`), or
/// `None` when it is absent.
pub fn query_param(name : String) -> String? {
  if @dom.has_query_param(name) {
    Some(@dom.query_param(name))
  } else {
    None
  }
}
