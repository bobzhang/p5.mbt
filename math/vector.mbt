// Port of p5.js src/math/p5.Vector.js (2D/3D subset).
//
// Like p5.js, instance methods such as `add`, `mult`, `normalize` mutate the
// vector in place.  Operators (`+`, `-`, unary `-`) and `scaled` return new
// vectors instead.

///|
/// A 2D or 3D Euclidean vector.
#derive(Eq, Debug)
pub struct Vector {
  mut x : Double
  mut y : Double
  mut z : Double
}

///|
/// Creates a new vector. `z` defaults to 0.
///
/// ```mbt check
/// test {
///   let v = @math.Vector(3, 4)
///   inspect(v.mag(), content="5")
///   inspect(v, content="vector[3, 4, 0]")
/// }
/// ```
pub fn Vector::Vector(x : Double, y : Double, z~ : Double = 0) -> Vector {
  { x, y, z, }
}

///|
pub impl Show for Vector with fn output(self, logger) {
  logger.write_string("vector[\{self.x}, \{self.y}, \{self.z}]")
}

///|
/// Sets the components of the vector.
pub fn Vector::set(
  self : Vector,
  x : Double,
  y : Double,
  z~ : Double = 0,
) -> Unit {
  self.x = x
  self.y = y
  self.z = z
}

///|
/// Copies the components of `other` into `self`.
pub fn Vector::set_vec(self : Vector, other : Vector) -> Unit {
  self.x = other.x
  self.y = other.y
  self.z = other.z
}

///|
/// Returns a copy of the vector.
pub fn Vector::copy(self : Vector) -> Vector {
  { x: self.x, y: self.y, z: self.z, }
}

///|
/// Adds `other` to this vector (in place).
pub fn Vector::add(self : Vector, other : Vector) -> Unit {
  self.x += other.x
  self.y += other.y
  self.z += other.z
}

///|
/// Adds the given components to this vector (in place).
pub fn Vector::add_xy(
  self : Vector,
  x : Double,
  y : Double,
  z~ : Double = 0,
) -> Unit {
  self.x += x
  self.y += y
  self.z += z
}

///|
/// Subtracts `other` from this vector (in place).
pub fn Vector::sub(self : Vector, other : Vector) -> Unit {
  self.x -= other.x
  self.y -= other.y
  self.z -= other.z
}

///|
/// Subtracts the given components from this vector (in place).
pub fn Vector::sub_xy(
  self : Vector,
  x : Double,
  y : Double,
  z~ : Double = 0,
) -> Unit {
  self.x -= x
  self.y -= y
  self.z -= z
}

///|
/// Multiplies this vector by a scalar (in place).
pub fn Vector::mult(self : Vector, n : Double) -> Unit {
  self.x *= n
  self.y *= n
  self.z *= n
}

///|
/// Multiplies this vector component-wise by `other` (in place).
pub fn Vector::mult_vec(self : Vector, other : Vector) -> Unit {
  self.x *= other.x
  self.y *= other.y
  self.z *= other.z
}

///|
/// Divides this vector by a scalar (in place). Dividing by 0 is ignored,
/// as in p5.js.
pub fn Vector::div(self : Vector, n : Double) -> Unit {
  if n == 0 || n.is_nan() {
    return
  }
  self.x /= n
  self.y /= n
  self.z /= n
}

///|
/// Remainder of this vector divided by `n` (in place, JavaScript `%`).
pub fn Vector::rem(self : Vector, n : Double) -> Unit {
  if n.abs() > 0 {
    self.x = js_rem(self.x, n)
    self.y = js_rem(self.y, n)
    self.z = js_rem(self.z, n)
  }
}

///|
/// JavaScript `%` on doubles (result has the sign of the dividend).
pub fn js_rem(a : Double, b : Double) -> Double {
  a - (a / b).trunc() * b
}

///|
/// Magnitude (length) of the vector.
pub fn Vector::mag(self : Vector) -> Double {
  self.mag_sq().sqrt()
}

///|
/// Squared magnitude of the vector.
pub fn Vector::mag_sq(self : Vector) -> Double {
  self.x * self.x + self.y * self.y + self.z * self.z
}

///|
/// Dot product.
pub fn Vector::dot(self : Vector, other : Vector) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
/// Cross product, returned as a new vector.
pub fn Vector::cross(self : Vector, v : Vector) -> Vector {
  {
    x: self.y * v.z - self.z * v.y,
    y: self.z * v.x - self.x * v.z,
    z: self.x * v.y - self.y * v.x,
  }
}

///|
/// Distance between two points represented as vectors.
pub fn Vector::dist(self : Vector, other : Vector) -> Double {
  let dx = self.x - other.x
  let dy = self.y - other.y
  let dz = self.z - other.z
  (dx * dx + dy * dy + dz * dz).sqrt()
}

///|
/// Scales this vector to length 1 (in place). The zero vector is unchanged.
pub fn Vector::normalize(self : Vector) -> Unit {
  let len = self.mag()
  if len != 0 {
    self.mult(1.0 / len)
  }
}

///|
/// Limits the magnitude of this vector to `max` (in place).
pub fn Vector::limit(self : Vector, max : Double) -> Unit {
  let m_sq = self.mag_sq()
  if m_sq > max * max {
    self.div(m_sq.sqrt())
    self.mult(max)
  }
}

///|
/// Sets the magnitude of this vector (in place).
pub fn Vector::set_mag(self : Vector, n : Double) -> Unit {
  self.normalize()
  self.mult(n)
}

///|
/// Angle of rotation of a 2D vector, in radians.
pub fn Vector::heading(self : Vector) -> Double {
  @cmath.atan2(self.y, self.x)
}

///|
/// Rotates a 2D vector to the given heading (radians), keeping its magnitude.
pub fn Vector::set_heading(self : Vector, a : Double) -> Unit {
  let m = self.mag()
  self.x = m * @cmath.cos(a)
  self.y = m * @cmath.sin(a)
}

///|
/// Rotates a 2D vector by `a` radians (in place).
pub fn Vector::rotate(self : Vector, a : Double) -> Unit {
  let new_heading = self.heading() + a
  let m = self.mag()
  self.x = @cmath.cos(new_heading) * m
  self.y = @cmath.sin(new_heading) * m
}

///|
/// Signed angle between two vectors, in radians (NaN if one is zero).
pub fn Vector::angle_between(self : Vector, v : Vector) -> Double {
  let mag_sq_mult = self.mag_sq() * v.mag_sq()
  if mag_sq_mult == 0 {
    return @double.not_a_number
  }
  let u = self.cross(v)
  let sign = if u.z == 0 { 1.0 } else { u.z.signum() }
  @cmath.atan2(u.mag(), self.dot(v)) * sign
}

///|
/// Linearly interpolates this vector towards `other` (in place).
pub fn Vector::lerp(self : Vector, other : Vector, amt : Double) -> Unit {
  self.x += (other.x - self.x) * amt
  self.y += (other.y - self.y) * amt
  self.z += (other.z - self.z) * amt
}

///|
/// Spherical linear interpolation towards `v` (in place).
pub fn Vector::slerp(self : Vector, v : Vector, amt : Double) -> Unit {
  if amt == 0 {
    return
  }
  if amt == 1 {
    self.set_vec(v)
    return
  }
  let self_mag = self.mag()
  let v_mag = v.mag()
  let linear = () => {
    self.mult(1 - amt)
    self.add_xy(v.x * amt, v.y * amt, z=v.z * amt)
  }
  if self_mag * v_mag == 0 {
    linear()
    return
  }
  let axis = self.cross(v)
  let axis_mag = axis.mag()
  let theta = @cmath.atan2(axis_mag, self.dot(v))
  if axis_mag > 0 {
    axis.div(axis_mag)
  } else if theta < PI * 0.5 {
    linear()
    return
  } else if self.z == 0 && v.z == 0 {
    axis.set(0, 0, z=1)
  } else if self.x != 0 {
    axis.set(self.y, -self.x)
    axis.normalize()
  } else {
    axis.set(1, 0)
  }
  let ey = axis.cross(self)
  let lerped_mag_factor = 1.0 - amt + amt * v_mag / self_mag
  let cos_m = lerped_mag_factor * @cmath.cos(amt * theta)
  let sin_m = lerped_mag_factor * @cmath.sin(amt * theta)
  self.x = self.x * cos_m + ey.x * sin_m
  self.y = self.y * cos_m + ey.y * sin_m
  self.z = self.z * cos_m + ey.z * sin_m
}

///|
/// Reflects this vector about a surface normal (in place).
pub fn Vector::reflect(self : Vector, surface_normal : Vector) -> Unit {
  let n = surface_normal.copy()
  n.normalize()
  n.mult(2 * self.dot(n))
  self.sub(n)
}

///|
/// Components as an array `[x, y, z]`.
pub fn Vector::array(self : Vector) -> Array[Double] {
  [self.x, self.y, self.z]
}

///|
/// Sets components very close to zero to exactly zero (in place).
pub fn Vector::clamp_to_zero(self : Vector) -> Unit {
  let eps = 2.220446049250313e-16
  if self.x.abs() <= eps {
    self.x = 0
  }
  if self.y.abs() <= eps {
    self.y = 0
  }
  if self.z.abs() <= eps {
    self.z = 0
  }
}

///|
/// Returns a new vector multiplied by `n`.
pub fn Vector::scaled(self : Vector, n : Double) -> Vector {
  { x: self.x * n, y: self.y * n, z: self.z * n, }
}

///|
/// Returns a normalized copy of the vector.
pub fn Vector::normalized(self : Vector) -> Vector {
  let v = self.copy()
  v.normalize()
  v
}

///|
pub impl Add for Vector with fn add(a, b) {
  { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, }
}

///|
pub impl Sub for Vector with fn sub(a, b) {
  { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z, }
}

///|
pub impl Neg for Vector with fn neg(a) {
  { x: -a.x, y: -a.y, z: -a.z, }
}

///|
/// Creates a 2D unit vector (times `length`) pointing at `angle` radians.
pub fn Vector::from_angle(angle : Double, length~ : Double = 1) -> Vector {
  { x: length * @cmath.cos(angle), y: length * @cmath.sin(angle), z: 0, }
}

///|
/// Creates a 3D vector from spherical angles `theta` and `phi`.
pub fn Vector::from_angles(
  theta : Double,
  phi : Double,
  length~ : Double = 1,
) -> Vector {
  let cos_phi = @cmath.cos(phi)
  let sin_phi = @cmath.sin(phi)
  let cos_theta = @cmath.cos(theta)
  let sin_theta = @cmath.sin(theta)
  {
    x: length * sin_theta * sin_phi,
    y: -length * cos_theta,
    z: length * sin_theta * cos_phi,
  }
}

///|
/// A random 2D unit vector.
pub fn Vector::random2d(rng : Random) -> Vector {
  Vector::from_angle(rng.next() * TWO_PI)
}

///|
/// A random 3D unit vector.
pub fn Vector::random3d(rng : Random) -> Vector {
  let angle = rng.next() * TWO_PI
  let vz = rng.next() * 2 - 1
  let vz_base = (1.0 - vz * vz).sqrt()
  { x: vz_base * @cmath.cos(angle), y: vz_base * @cmath.sin(angle), z: vz, }
}
