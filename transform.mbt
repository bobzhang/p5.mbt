// Port of p5.js src/core/transform.js for the 2D renderer.

///|
/// Moves the origin by `(x, y)`.
pub fn P5::translate(self : P5, x : Double, y : Double) -> Unit {
  self.state.matrix = self.state.matrix.translate(x, y)
}

///|
/// Rotates the coordinate system by `angle` (in the current angle mode).
pub fn P5::rotate(self : P5, angle : Double) -> Unit {
  self.state.matrix = self.state.matrix.rotate(self.to_radians(angle))
}

///|
/// Scales the coordinate system. `y` defaults to `x`.
pub fn P5::scale(self : P5, x : Double, y? : Double) -> Unit {
  self.state.matrix = self.state.matrix.scale(x, y.unwrap_or(x))
}

///|
/// Shears along the x-axis by `angle` (in the current angle mode).
pub fn P5::shear_x(self : P5, angle : Double) -> Unit {
  self.state.matrix = self.state.matrix.shear_x(self.to_radians(angle))
}

///|
/// Shears along the y-axis by `angle` (in the current angle mode).
pub fn P5::shear_y(self : P5, angle : Double) -> Unit {
  self.state.matrix = self.state.matrix.shear_y(self.to_radians(angle))
}

///|
/// Multiplies the current matrix by `[a c e; b d f; 0 0 1]`.
pub fn P5::apply_matrix(
  self : P5,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> Unit {
  self.state.matrix = self.state.matrix.multiply({ a, b, c, d, e, f, })
}

///|
/// Resets the coordinate system to the identity.
pub fn P5::reset_matrix(self : P5) -> Unit {
  self.state.matrix = @math.identity
}

///|
/// The current transform (user space to CSS pixels).
pub fn P5::get_matrix(self : P5) -> Matrix2D {
  self.state.matrix
}

///|
/// Converts a point from the current user space to canvas coordinates.
pub fn P5::world_to_screen(
  self : P5,
  x : Double,
  y : Double,
) -> (Double, Double) {
  self.state.matrix.apply(x, y)
}

///|
/// Converts a point from canvas coordinates to the current user space.
pub fn P5::screen_to_world(
  self : P5,
  x : Double,
  y : Double,
) -> (Double, Double) {
  match self.state.matrix.invert() {
    Some(inv) => inv.apply(x, y)
    None => (x, y)
  }
}

///|
/// Saves the drawing style and transform.
pub fn P5::push(self : P5) -> Unit {
  self.stack.push(self.state.copy())
  self.surface.save()
}

///|
/// Restores the style and transform saved by the last `push()` (and removes
/// any clipping started since).
pub fn P5::pop(self : P5) -> Unit {
  match self.stack.pop() {
    Some(s) => {
      self.state = s
      self.surface.restore()
      self.surface.set_blend_mode(if s.erasing { Remove } else { s.blend_mode })
      self.surface.set_smoothing(s.smooth)
    }
    None => warn("pop() was called more times than push()")
  }
}

///|
/// Runs `body` between `push()` and `pop()`.
pub fn P5::with_push(self : P5, body : () -> Unit) -> Unit {
  self.push()
  body()
  self.pop()
}

///|
/// Starts defining a clipping mask: shapes drawn until `end_clip()` are not
/// painted but form the mask. With `invert=true` the mask is inverted. The
/// clip lasts until the matching `pop()` (or the end of the frame).
pub fn P5::begin_clip(self : P5, invert~ : Bool = false) -> Unit {
  if self.clipping {
    abort(
      "It looks like you're trying to clip while already in the middle of clipping. Did you forget to endClip()?",
    )
  }
  self.clipping = true
  self.clip_invert = invert
  self.clip_parts.clear()
  self.clip_base = self.device_matrix()
  if invert {
    // Slight hack, as in p5: a big rectangle with reverse winding.
    let w = self.width
    let h = self.height
    self.clip_parts.push(
      (
        [
          MoveTo(-2 * w, -2 * h),
          LineTo(-2 * w, 2 * h),
          LineTo(2 * w, 2 * h),
          LineTo(2 * w, -2 * h),
          ClosePath,
        ],
        @math.identity,
      ),
    )
  }
}

///|
/// Finishes the clipping mask started by `begin_clip()`.
pub fn P5::end_clip(self : P5) -> Unit {
  if !self.clipping {
    abort(
      "It looks like you've called endClip() without beginClip(). Did you forget to call beginClip() first?",
    )
  }
  self.clipping = false
  self.surface.clip(self.clip_base, self.clip_parts.copy())
  self.clip_parts.clear()
}

///|
/// Draws the shapes of `mask` as a clipping mask, like p5's `clip()`.
pub fn P5::clip(self : P5, mask : () -> Unit, invert~ : Bool = false) -> Unit {
  self.begin_clip(invert~)
  mask()
  self.end_clip()
}
