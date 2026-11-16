///|
/// A 2D affine transformation, using the same layout as the canvas
/// `setTransform(a, b, c, d, e, f)`:
///
/// ```text
/// | a c e |
/// | b d f |
/// | 0 0 1 |
/// ```
#derive(Eq, Debug)
pub(all) struct Matrix2D {
  a : Double
  b : Double
  c : Double
  d : Double
  e : Double
  f : Double
}

///|
/// The identity transform.
pub let identity : Matrix2D = { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0, }

///|
/// Returns `self * other` (apply `other` first, then `self`).
pub fn Matrix2D::multiply(self : Matrix2D, m : Matrix2D) -> Matrix2D {
  {
    a: self.a * m.a + self.c * m.b,
    b: self.b * m.a + self.d * m.b,
    c: self.a * m.c + self.c * m.d,
    d: self.b * m.c + self.d * m.d,
    e: self.a * m.e + self.c * m.f + self.e,
    f: self.b * m.e + self.d * m.f + self.f,
  }
}

///|
/// Like canvas `translate(x, y)`: post-multiplies a translation.
pub fn Matrix2D::translate(self : Matrix2D, x : Double, y : Double) -> Matrix2D {
  self.multiply({ a: 1, b: 0, c: 0, d: 1, e: x, f: y, })
}

///|
/// Like canvas `scale(x, y)`.
pub fn Matrix2D::scale(self : Matrix2D, x : Double, y : Double) -> Matrix2D {
  self.multiply({ a: x, b: 0, c: 0, d: y, e: 0, f: 0, })
}

///|
/// Like canvas `rotate(angle)` (radians, clockwise in screen space).
pub fn Matrix2D::rotate(self : Matrix2D, angle : Double) -> Matrix2D {
  let c = @cmath.cos(angle)
  let s = @cmath.sin(angle)
  self.multiply({ a: c, b: s, c: -s, d: c, e: 0, f: 0, })
}

///|
/// Shear along the x axis by `angle` radians.
pub fn Matrix2D::shear_x(self : Matrix2D, angle : Double) -> Matrix2D {
  self.multiply({ a: 1, b: 0, c: @cmath.tan(angle), d: 1, e: 0, f: 0, })
}

///|
/// Shear along the y axis by `angle` radians.
pub fn Matrix2D::shear_y(self : Matrix2D, angle : Double) -> Matrix2D {
  self.multiply({ a: 1, b: @cmath.tan(angle), c: 0, d: 1, e: 0, f: 0, })
}

///|
/// Inverse transform (`None` when singular).
pub fn Matrix2D::invert(self : Matrix2D) -> Matrix2D? {
  let det = self.a * self.d - self.b * self.c
  if det == 0 {
    return None
  }
  Some({
    a: self.d / det,
    b: -self.b / det,
    c: -self.c / det,
    d: self.a / det,
    e: (self.c * self.f - self.d * self.e) / det,
    f: (self.b * self.e - self.a * self.f) / det,
  })
}

///|
/// Applies the transform to a point.
pub fn Matrix2D::apply(
  self : Matrix2D,
  x : Double,
  y : Double,
) -> (Double, Double) {
  (self.a * x + self.c * y + self.e, self.b * x + self.d * y + self.f)
}
