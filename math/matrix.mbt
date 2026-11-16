// p5.Matrix (src/math/Matrices/Matrix.js) for 3x3 and 4x4 matrices.
// Entries are stored as 32-bit floats, like p5's Float32Array, so results
// match p5.js bit for bit; arithmetic happens in doubles between stores.

///|
/// A square matrix in column-major order (p5.Matrix).
pub struct Matrix {
  /// The side length: 3 or 4.
  dim : Int32
  priv mut m : FixedArray[Float]
}

///|
fn f32(x : Double) -> Float {
  Float::from_double(x)
}

///|
fn identity_array(dim : Int32) -> FixedArray[Float] {
  let a = FixedArray::make(dim * dim, (0 : Float))
  for i in 0..<dim {
    a[i * dim + i] = 1
  }
  a
}

///|
/// The identity matrix of side `dim`.
pub fn Matrix::new(dim : Int32) -> Matrix {
  { dim, m: identity_array(dim), }
}

///|
/// A matrix from column-major entries (16 for 4x4, 9 for 3x3).
pub fn Matrix::from_array(values : ArrayView[Double]) -> Matrix {
  let dim = if values.length() == 9 { 3 } else { 4 }
  { dim, m: FixedArray::makei(values.length(), i => f32(values[i])), }
}

///|
/// Entry `i` (column-major).
pub fn Matrix::get(self : Matrix, i : Int32) -> Double {
  self.m[i].to_double()
}

///|
fn Matrix::put(self : Matrix, i : Int32, v : Double) -> Unit {
  self.m[i] = f32(v)
}

///|
/// The entries as 32-bit floats (what is sent to shaders).
pub fn Matrix::floats(self : Matrix) -> FixedArray[Float] {
  self.m
}

///|
/// The entries as doubles.
pub fn Matrix::to_array(self : Matrix) -> Array[Double] {
  [
    for v in self.m => v.to_double()
  ]
}

///|
pub fn Matrix::copy(self : Matrix) -> Matrix {
  { dim: self.dim, m: self.m.copy(), }
}

///|
/// Resets to the identity.
pub fn Matrix::reset(self : Matrix) -> Unit {
  self.m = identity_array(self.dim)
}

///|
/// Copies the entries of `other`.
pub fn Matrix::set(self : Matrix, other : Matrix) -> Unit {
  self.m = other.m.copy()
}

///|
/// Sets the entries from doubles (column-major).
pub fn Matrix::set_values(self : Matrix, values : ArrayView[Double]) -> Unit {
  if values.length() == self.m.length() {
    self.m = FixedArray::makei(values.length(), i => f32(values[i]))
  }
}

///|
pub fn Matrix::set_element(self : Matrix, i : Int32, v : Double) -> Unit {
  if i >= 0 && i < self.m.length() {
    self.put(i, v)
  }
}

///|
/// `self = self × other` in p5's convention (`mult`).
pub fn Matrix::mult(self : Matrix, other : Matrix) -> Matrix {
  let s = other.m.copy()
  let src = (i : Int32) => s[i].to_double()
  if self.dim == 4 {
    for r in 0..<4 {
      let b0 = self.get(r * 4)
      let b1 = self.get(r * 4 + 1)
      let b2 = self.get(r * 4 + 2)
      let b3 = self.get(r * 4 + 3)
      for c in 0..<4 {
        self.put(
          r * 4 + c,
          b0 * src(c) + b1 * src(4 + c) + b2 * src(8 + c) + b3 * src(12 + c),
        )
      }
    }
  } else {
    for r in 0..<3 {
      let b0 = self.get(r * 3)
      let b1 = self.get(r * 3 + 1)
      let b2 = self.get(r * 3 + 2)
      for c in 0..<3 {
        self.put(r * 3 + c, b0 * src(c) + b1 * src(3 + c) + b2 * src(6 + c))
      }
    }
  }
  self
}

///|
/// Applies `src` (16 entries) on the left, like p5's `apply`.
pub fn Matrix::apply(self : Matrix, src : ArrayView[Double]) -> Matrix {
  for c in 0..<4 {
    let m0 = self.get(c)
    let m4 = self.get(4 + c)
    let m8 = self.get(8 + c)
    let m12 = self.get(12 + c)
    self.put(c, src[0] * m0 + src[1] * m4 + src[2] * m8 + src[3] * m12)
    self.put(4 + c, src[4] * m0 + src[5] * m4 + src[6] * m8 + src[7] * m12)
    self.put(8 + c, src[8] * m0 + src[9] * m4 + src[10] * m8 + src[11] * m12)
    self.put(12 + c, src[12] * m0 + src[13] * m4 + src[14] * m8 + src[15] * m12)
  }
  self
}

///|
pub fn Matrix::scale(
  self : Matrix,
  x : Double,
  y : Double,
  z : Double,
) -> Matrix {
  for i in 0..<4 {
    self.put(i, self.get(i) * x)
    self.put(4 + i, self.get(4 + i) * y)
    self.put(8 + i, self.get(8 + i) * z)
  }
  self
}

///|
/// Rotates by `a` radians about the axis `(x, y, z)` (`rotate4x4`).
pub fn Matrix::rotate(
  self : Matrix,
  a : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Matrix {
  let len = (x * x + y * y + z * z).sqrt()
  let x = x * (1.0 / len)
  let y = y * (1.0 / len)
  let z = z * (1.0 / len)
  let a00 = self.get(0)
  let a01 = self.get(1)
  let a02 = self.get(2)
  let a03 = self.get(3)
  let a10 = self.get(4)
  let a11 = self.get(5)
  let a12 = self.get(6)
  let a13 = self.get(7)
  let a20 = self.get(8)
  let a21 = self.get(9)
  let a22 = self.get(10)
  let a23 = self.get(11)
  let s = js_sin(a)
  let c = js_cos(a)
  let t = 1.0 - c
  let b00 = x * x * t + c
  let b01 = y * x * t + z * s
  let b02 = z * x * t - y * s
  let b10 = x * y * t - z * s
  let b11 = y * y * t + c
  let b12 = z * y * t + x * s
  let b20 = x * z * t + y * s
  let b21 = y * z * t - x * s
  let b22 = z * z * t + c
  self.put(0, a00 * b00 + a10 * b01 + a20 * b02)
  self.put(1, a01 * b00 + a11 * b01 + a21 * b02)
  self.put(2, a02 * b00 + a12 * b01 + a22 * b02)
  self.put(3, a03 * b00 + a13 * b01 + a23 * b02)
  self.put(4, a00 * b10 + a10 * b11 + a20 * b12)
  self.put(5, a01 * b10 + a11 * b11 + a21 * b12)
  self.put(6, a02 * b10 + a12 * b11 + a22 * b12)
  self.put(7, a03 * b10 + a13 * b11 + a23 * b12)
  self.put(8, a00 * b20 + a10 * b21 + a20 * b22)
  self.put(9, a01 * b20 + a11 * b21 + a21 * b22)
  self.put(10, a02 * b20 + a12 * b21 + a22 * b22)
  self.put(11, a03 * b20 + a13 * b21 + a23 * b22)
  self
}

///|
pub fn Matrix::translate(
  self : Matrix,
  x : Double,
  y : Double,
  z : Double,
) -> Matrix {
  for i in 0..<4 {
    self.put(
      12 + i,
      self.get(12 + i) +
      (self.get(i) * x + self.get(4 + i) * y + self.get(8 + i) * z),
    )
  }
  self
}

///|
/// Transposes `src` (a 3x3 or 4x4 matrix's entries) into `self`.
pub fn Matrix::transpose_from(self : Matrix, src : Matrix) -> Matrix {
  let n = self.dim
  let s = src.m.copy()
  for r in 0..<n {
    for c in 0..<n {
      self.m[r * n + c] = s[c * n + r]
    }
  }
  self
}

///|
/// Inverts `src` into `self`; `None` (and `self` unchanged) when singular.
pub fn Matrix::invert_from(self : Matrix, src : Matrix) -> Matrix? {
  if self.dim == 3 {
    let a = (i : Int32) => src.get(i)
    let a00 = a(0)
    let a01 = a(1)
    let a02 = a(2)
    let a10 = a(3)
    let a11 = a(4)
    let a12 = a(5)
    let a20 = a(6)
    let a21 = a(7)
    let a22 = a(8)
    let b01 = a22 * a11 - a12 * a21
    let b11 = -a22 * a10 + a12 * a20
    let b21 = a21 * a10 - a11 * a20
    let det = a00 * b01 + a01 * b11 + a02 * b21
    if det == 0 || det.is_nan() {
      return None
    }
    let det = 1.0 / det
    self.put(0, b01 * det)
    self.put(1, (-a22 * a01 + a02 * a21) * det)
    self.put(2, (a12 * a01 - a02 * a11) * det)
    self.put(3, b11 * det)
    self.put(4, (a22 * a00 - a02 * a20) * det)
    self.put(5, (-a12 * a00 + a02 * a10) * det)
    self.put(6, b21 * det)
    self.put(7, (-a21 * a00 + a01 * a20) * det)
    self.put(8, (a11 * a00 - a01 * a10) * det)
    return Some(self)
  }
  let a = src.m.copy()
  let g = (i : Int32) => a[i].to_double()
  let (a00, a01, a02, a03) = (g(0), g(1), g(2), g(3))
  let (a10, a11, a12, a13) = (g(4), g(5), g(6), g(7))
  let (a20, a21, a22, a23) = (g(8), g(9), g(10), g(11))
  let (a30, a31, a32, a33) = (g(12), g(13), g(14), g(15))
  let b00 = a00 * a11 - a01 * a10
  let b01 = a00 * a12 - a02 * a10
  let b02 = a00 * a13 - a03 * a10
  let b03 = a01 * a12 - a02 * a11
  let b04 = a01 * a13 - a03 * a11
  let b05 = a02 * a13 - a03 * a12
  let b06 = a20 * a31 - a21 * a30
  let b07 = a20 * a32 - a22 * a30
  let b08 = a20 * a33 - a23 * a30
  let b09 = a21 * a32 - a22 * a31
  let b10 = a21 * a33 - a23 * a31
  let b11 = a22 * a33 - a23 * a32
  let det = b00 * b11 -
    b01 * b10 +
    b02 * b09 +
    b03 * b08 -
    b04 * b07 +
    b05 * b06
  if det == 0 || det.is_nan() {
    return None
  }
  let det = 1.0 / det
  self.put(0, (a11 * b11 - a12 * b10 + a13 * b09) * det)
  self.put(1, (a02 * b10 - a01 * b11 - a03 * b09) * det)
  self.put(2, (a31 * b05 - a32 * b04 + a33 * b03) * det)
  self.put(3, (a22 * b04 - a21 * b05 - a23 * b03) * det)
  self.put(4, (a12 * b08 - a10 * b11 - a13 * b07) * det)
  self.put(5, (a00 * b11 - a02 * b08 + a03 * b07) * det)
  self.put(6, (a32 * b02 - a30 * b05 - a33 * b01) * det)
  self.put(7, (a20 * b05 - a22 * b02 + a23 * b01) * det)
  self.put(8, (a10 * b10 - a11 * b08 + a13 * b06) * det)
  self.put(9, (a01 * b08 - a00 * b10 - a03 * b06) * det)
  self.put(10, (a30 * b04 - a31 * b02 + a33 * b00) * det)
  self.put(11, (a21 * b02 - a20 * b04 - a23 * b00) * det)
  self.put(12, (a11 * b07 - a10 * b09 - a12 * b06) * det)
  self.put(13, (a00 * b09 - a01 * b07 + a02 * b06) * det)
  self.put(14, (a31 * b01 - a30 * b03 - a32 * b00) * det)
  self.put(15, (a20 * b03 - a21 * b01 + a22 * b00) * det)
  Some(self)
}

///|
/// For a 3x3 `self`: the inverse transpose of the upper-left 3x3 of the
/// 4x4 `m` (the normal matrix), or zeros when singular.
pub fn Matrix::inverse_transpose4x4(self : Matrix, m : Matrix) -> Matrix {
  for
    (i, j) in [
      (0, 0),
      (1, 1),
      (2, 2),
      (3, 4),
      (4, 5),
      (5, 6),
      (6, 8),
      (7, 9),
      (8, 10),
    ] {
    self.m[i] = m.m[j]
  }
  match self.invert_from(self) {
    Some(inv) => inv.transpose_from(inv)
    None => {
      for i in 0..<9 {
        self.m[i] = 0
      }
      self
    }
  }
}

///|
/// `m × (x, y, z, w)` as four doubles.
pub fn Matrix::multiply_vec4(
  self : Matrix,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
) -> (Double, Double, Double, Double) {
  let m = (i : Int32) => self.get(i)
  (
    m(0) * x + m(4) * y + m(8) * z + m(12) * w,
    m(1) * x + m(5) * y + m(9) * z + m(13) * w,
    m(2) * x + m(6) * y + m(10) * z + m(14) * w,
    m(3) * x + m(7) * y + m(11) * z + m(15) * w,
  )
}

///|
#cfg(target="js")
extern "js" fn js_sin(x : Double) -> Double = "Math.sin"

///|
#cfg(target="js")
extern "js" fn js_cos(x : Double) -> Double = "Math.cos"

///|
#cfg(not(target="js"))
fn js_sin(x : Double) -> Double {
  @cmath.sin(x)
}

///|
#cfg(not(target="js"))
fn js_cos(x : Double) -> Double {
  @cmath.cos(x)
}
