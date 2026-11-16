// The 3-component vector arithmetic of p5.Vector, in the same operation
// order so geometry matches p5.js exactly.

///|
/// A mutable 3D vector.
#derive(Debug)
pub struct Vec3 {
  mut x : Double
  mut y : Double
  mut z : Double
}

///|
pub fn Vec3::new(x : Double, y : Double, z : Double) -> Vec3 {
  { x, y, z, }
}

///|
pub fn Vec3::copy(self : Vec3) -> Vec3 {
  { x: self.x, y: self.y, z: self.z, }
}

///|
fn Vec3::add_(self : Vec3, v : Vec3) -> Vec3 {
  self.x += v.x
  self.y += v.y
  self.z += v.z
  self
}

///|
fn Vec3::sub_(self : Vec3, v : Vec3) -> Vec3 {
  self.x -= v.x
  self.y -= v.y
  self.z -= v.z
  self
}

///|
fn Vec3::mult_(self : Vec3, s : Double) -> Vec3 {
  self.x *= s
  self.y *= s
  self.z *= s
  self
}

///|
fn Vec3::div_(self : Vec3, s : Double) -> Vec3 {
  if s == 0 {
    return self
  }
  self.x /= s
  self.y /= s
  self.z /= s
  self
}

///|
fn Vec3::mag(self : Vec3) -> Double {
  (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
}

///|
fn Vec3::mag_sq(self : Vec3) -> Double {
  self.x * self.x + self.y * self.y + self.z * self.z
}

///|
fn Vec3::normalize_(self : Vec3) -> Vec3 {
  let len = self.mag()
  if len != 0 {
    ignore(self.mult_(1.0 / len))
  }
  self
}

///|
fn Vec3::dot(self : Vec3, v : Vec3) -> Double {
  self.x * v.x + self.y * v.y + self.z * v.z
}

///|
fn Vec3::cross(self : Vec3, v : Vec3) -> Vec3 {
  {
    x: self.y * v.z - self.z * v.y,
    y: self.z * v.x - self.x * v.z,
    z: self.x * v.y - self.y * v.x,
  }
}
