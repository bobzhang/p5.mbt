// p5.Quat (src/webgl/p5.Quat.js): quaternions for rotating vectors, used
// by the camera's `roll`.

///|
/// A quaternion `w + xi + yj + zk`.
#derive(Debug)
pub struct Quat {
  w : Double
  vec : Vec3
}

///|
pub fn Quat::new(w : Double, x : Double, y : Double, z : Double) -> Quat {
  { w, vec: Vec3::new(x, y, z), }
}

///|
/// The rotation by `angle` radians about the axis `(x, y, z)`.
pub fn Quat::from_axis_angle(
  angle : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Quat {
  let w = @cmath.cos(angle / 2)
  let v = Vec3::new(x, y, z).normalize_().mult_(@cmath.sin(angle / 2))
  Quat::new(w, v.x, v.y, v.z)
}

///|
pub fn Quat::conjugate(self : Quat) -> Quat {
  Quat::new(self.w, -self.vec.x, -self.vec.y, -self.vec.z)
}

///|
/// The product `self × q`.
pub fn Quat::multiply(self : Quat, q : Quat) -> Quat {
  let a = self.vec
  let b = q.vec
  Quat::new(
    self.w * q.w - a.x * b.x - a.y * b.y - a.z * b.z,
    self.w * b.x + a.x * q.w + a.y * b.z - a.z * b.y,
    self.w * b.y - a.x * b.z + a.y * q.w + a.z * b.x,
    self.w * b.z + a.x * b.y - a.y * b.x + a.z * q.w,
  )
}

///|
fn clamp_to_zero(v : Vec3) -> Vec3 {
  let eps = 2.220446049250313e-16
  if v.x.abs() < eps {
    v.x = 0
  }
  if v.y.abs() < eps {
    v.y = 0
  }
  if v.z.abs() < eps {
    v.z = 0
  }
  v
}

///|
/// Rotates `p` by this (unit) quaternion.
pub fn Quat::rotate_vector(self : Quat, p : Vec3) -> Vec3 {
  let v = self.vec
  let a = p.copy().mult_(self.w * self.w - v.dot(v))
  let b = v.copy().mult_(2 * p.dot(v))
  let c = v.copy().mult_(2 * self.w).cross(p)
  clamp_to_zero(a.add_(b).add_(c))
}

///|
/// The vector part of `axes × self × axes⁻¹` (p5's `rotateBy`).
pub fn Quat::rotate_by(self : Quat, axes : Quat) -> Vec3 {
  clamp_to_zero(axes.multiply(self).multiply(axes.conjugate()).vec.copy())
}

///|
/// Rotates the camera about its own z-axis (the viewing direction) by
/// `angle` radians.
pub fn Camera::roll(self : Camera, angle : Double) -> Unit {
  let (_, _, z) = self.local_axes()
  let q = Quat::from_axis_angle(angle, z.x, z.y, z.z)
  let up = q.rotate_vector(Vec3::new(self.up_x, self.up_y, self.up_z))
  self.camera(
    eye=(self.eye_x, self.eye_y, self.eye_z),
    center=(self.center_x, self.center_y, self.center_z),
    up=(up.x, up.y, up.z),
  )
}
