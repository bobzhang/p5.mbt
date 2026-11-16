// p5.Camera (src/webgl/p5.Camera.js). Angles are in radians; the sketch
// converts from its angle mode.

///|
/// A camera: eye, center and up vectors plus a projection.
pub struct Camera {
  mut width : Double
  mut height : Double
  mut camera_type_default : Bool
  mut use_line_perspective : Bool
  camera_matrix : @math.Matrix
  mut proj_matrix : @math.Matrix
  y_scale : Double
  mut eye_x : Double
  mut eye_y : Double
  mut eye_z : Double
  mut center_x : Double
  mut center_y : Double
  mut center_z : Double
  mut up_x : Double
  mut up_y : Double
  mut up_z : Double
  mut camera_fov : Double
  mut aspect_ratio : Double
  mut camera_near : Double
  mut camera_far : Double
  mut default_aspect_ratio : Double
  mut default_eye_z : Double
  mut default_camera_fov : Double
  mut default_camera_near : Double
  mut default_camera_far : Double
}

///|
/// A camera for a `width × height` view with p5's default settings.
pub fn Camera::new(width : Double, height : Double) -> Camera {
  let c : Camera = {
    width,
    height,
    camera_type_default: true,
    use_line_perspective: true,
    camera_matrix: @math.Matrix::new(4),
    proj_matrix: @math.Matrix::new(4),
    y_scale: 1,
    eye_x: 0,
    eye_y: 0,
    eye_z: 0,
    center_x: 0,
    center_y: 0,
    center_z: 0,
    up_x: 0,
    up_y: 1,
    up_z: 0,
    camera_fov: 0,
    aspect_ratio: 1,
    camera_near: 0,
    camera_far: 0,
    default_aspect_ratio: 1,
    default_eye_z: 800,
    default_camera_fov: 0,
    default_camera_near: 0,
    default_camera_far: 0,
  }
  c.compute_default_settings()
  c.set_default_camera()
  c
}

///|
fn Camera::compute_default_settings(self : Camera) -> Unit {
  self.default_aspect_ratio = self.width / self.height
  self.default_eye_z = 800
  self.default_camera_fov = 2.0 *
    js_atan(self.height / 2.0 / self.default_eye_z)
  self.default_camera_near = self.default_eye_z * 0.1
  self.default_camera_far = self.default_eye_z * 10.0
}

///|
fn Camera::set_default_camera(self : Camera) -> Unit {
  self.camera_fov = self.default_camera_fov
  self.aspect_ratio = self.default_aspect_ratio
  self.eye_x = 0
  self.eye_y = 0
  self.eye_z = self.default_eye_z
  self.center_x = 0
  self.center_y = 0
  self.center_z = 0
  self.up_x = 0
  self.up_y = 1
  self.up_z = 0
  self.camera_near = self.default_camera_near
  self.camera_far = self.default_camera_far
  self.perspective()
  self.camera()
  self.camera_type_default = true
}

///|
/// Re-derives the default projection after a canvas resize.
pub fn Camera::resize(self : Camera, width : Double, height : Double) -> Unit {
  self.width = width
  self.height = height
  if self.camera_type_default {
    self.compute_default_settings()
    self.camera_fov = self.default_camera_fov
    self.aspect_ratio = self.default_aspect_ratio
    self.perspective()
  }
}

///|
pub fn Camera::copy(self : Camera) -> Camera {
  {
    ..self,
    camera_matrix: self.camera_matrix.copy(),
    proj_matrix: self.proj_matrix.copy(),
  }
}

///|
/// A perspective projection; omitted values use the defaults.
pub fn Camera::perspective(
  self : Camera,
  fovy? : Double,
  aspect? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  self.camera_type_default = fovy is None &&
    aspect is None &&
    near is None &&
    far is None
  self.camera_fov = fovy.unwrap_or(self.default_camera_fov)
  let aspect = aspect.unwrap_or(self.default_aspect_ratio)
  let mut near = near.unwrap_or(self.default_camera_near)
  let far = far.unwrap_or(self.default_camera_far)
  if near <= 0.0001 {
    near = 0.01
  }
  self.aspect_ratio = aspect
  self.camera_near = near
  self.camera_far = far
  let f = 1.0 / js_tan(self.camera_fov / 2)
  let nf = 1.0 / (near - far)
  let a = (far + near) * nf
  let b = 2.0 * far * near * nf
  self.proj_matrix = @math.Matrix::from_array([
    f / aspect,
    0,
    0,
    0,
    0,
    -f * self.y_scale,
    0,
    0,
    0,
    0,
    a,
    -1,
    0,
    0,
    b,
    0,
  ])
}

///|
/// An orthographic projection; omitted values fit the canvas.
pub fn Camera::ortho(
  self : Camera,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  let left = left.unwrap_or(-self.width / 2)
  let right = right.unwrap_or(self.width / 2)
  let bottom = bottom.unwrap_or(-self.height / 2)
  let top = top.unwrap_or(self.height / 2)
  let near = near.unwrap_or(0)
  let far = far.unwrap_or(self.width.max(self.height) + 800)
  self.camera_near = near
  self.camera_far = far
  let w = right - left
  let h = top - bottom
  let d = far - near
  let x = 2.0 / w
  let y = 2.0 / h * self.y_scale
  let z = -2.0 / d
  let tx = -(right + left) / w
  let ty = -(top + bottom) / h
  let tz = -(far + near) / d
  self.proj_matrix = @math.Matrix::from_array([
    x,
    0,
    0,
    0,
    0,
    -y,
    0,
    0,
    0,
    0,
    z,
    0,
    tx,
    ty,
    tz,
    1,
  ])
  self.camera_type_default = false
}

///|
/// A frustum projection; omitted values use p5's defaults.
pub fn Camera::frustum(
  self : Camera,
  left? : Double,
  right? : Double,
  bottom? : Double,
  top? : Double,
  near? : Double,
  far? : Double,
) -> Unit {
  let left = left.unwrap_or(-self.width * 0.05)
  let right = right.unwrap_or(self.width * 0.05)
  let bottom = bottom.unwrap_or(self.height * 0.05)
  let top = top.unwrap_or(-self.height * 0.05)
  let near = near.unwrap_or(self.default_camera_near)
  let far = far.unwrap_or(self.default_camera_far)
  self.camera_near = near
  self.camera_far = far
  let w = right - left
  let h = top - bottom
  let d = far - near
  let x = 2.0 * near / w
  let y = 2.0 * near / h * self.y_scale
  let z = -(2.0 * far * near) / d
  let tx = (right + left) / w
  let ty = (top + bottom) / h
  let tz = -(far + near) / d
  self.proj_matrix = @math.Matrix::from_array([
    x,
    0,
    0,
    0,
    0,
    -y,
    0,
    0,
    tx,
    ty,
    tz,
    -1,
    0,
    0,
    z,
    0,
  ])
  self.camera_type_default = false
}

///|
fn Camera::local_axes(self : Camera) -> (Vec3, Vec3, Vec3) {
  let mut z0 = self.eye_x - self.center_x
  let mut z1 = self.eye_y - self.center_y
  let mut z2 = self.eye_z - self.center_z
  let eye_dist = (z0 * z0 + z1 * z1 + z2 * z2).sqrt()
  if eye_dist != 0 {
    z0 /= eye_dist
    z1 /= eye_dist
    z2 /= eye_dist
  }
  let mut y0 = self.up_x
  let mut y1 = self.up_y
  let mut y2 = self.up_z
  let mut x0 = y1 * z2 - y2 * z1
  let mut x1 = -y0 * z2 + y2 * z0
  let mut x2 = y0 * z1 - y1 * z0
  y0 = z1 * x2 - z2 * x1
  y1 = -z0 * x2 + z2 * x0
  y2 = z0 * x1 - z1 * x0
  let xmag = (x0 * x0 + x1 * x1 + x2 * x2).sqrt()
  if xmag != 0 {
    x0 /= xmag
    x1 /= xmag
    x2 /= xmag
  }
  let ymag = (y0 * y0 + y1 * y1 + y2 * y2).sqrt()
  if ymag != 0 {
    y0 /= ymag
    y1 /= ymag
    y2 /= ymag
  }
  (Vec3::new(x0, x1, x2), Vec3::new(y0, y1, y2), Vec3::new(z0, z1, z2))
}

///|
/// Places the camera; with no arguments, the default camera.
pub fn Camera::camera(
  self : Camera,
  eye? : (Double, Double, Double),
  center? : (Double, Double, Double),
  up? : (Double, Double, Double),
) -> Unit {
  let (ex, ey, ez) = match eye {
    Some(e) => e
    None => (0.0, 0.0, self.default_eye_z)
  }
  let (center, up) = if eye is None {
    (Some((ex, ey, 0.0)), Some((0.0, 1.0, 0.0)))
  } else {
    (center, up)
  }
  self.eye_x = ex
  self.eye_y = ey
  self.eye_z = ez
  if center is Some((cx, cy, cz)) {
    self.center_x = cx
    self.center_y = cy
    self.center_z = cz
  }
  if up is Some((ux, uy, uz)) {
    self.up_x = ux
    self.up_y = uy
    self.up_z = uz
  }
  let (x, y, z) = self.local_axes()
  self.camera_matrix.set_values([
    x.x,
    y.x,
    z.x,
    0,
    x.y,
    y.y,
    z.y,
    0,
    x.z,
    y.z,
    z.z,
    0,
    0,
    0,
    0,
    1,
  ])
  ignore(self.camera_matrix.translate(-ex, -ey, -ez))
}

///|
fn Camera::recamera(
  self : Camera,
  ex : Double,
  ey : Double,
  ez : Double,
  cx : Double,
  cy : Double,
  cz : Double,
) -> Unit {
  self.camera(
    eye=(ex, ey, ez),
    center=(cx, cy, cz),
    up=(self.up_x, self.up_y, self.up_z),
  )
}

///|
/// Points the camera at `(x, y, z)`.
pub fn Camera::look_at(
  self : Camera,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  self.recamera(self.eye_x, self.eye_y, self.eye_z, x, y, z)
}

///|
/// Moves the camera along its own axes.
pub fn Camera::move_by(
  self : Camera,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  let (lx, ly, lz) = self.local_axes()
  let dx = [lx.x * x, lx.y * x, lx.z * x]
  let dy = [ly.x * y, ly.y * y, ly.z * y]
  let dz = [lz.x * z, lz.y * z, lz.z * z]
  self.recamera(
    self.eye_x + dx[0] + dy[0] + dz[0],
    self.eye_y + dx[1] + dy[1] + dz[1],
    self.eye_z + dx[2] + dy[2] + dz[2],
    self.center_x + dx[0] + dy[0] + dz[0],
    self.center_y + dx[1] + dy[1] + dz[1],
    self.center_z + dx[2] + dy[2] + dz[2],
  )
}

///|
/// Moves the eye to `(x, y, z)` keeping the view direction.
pub fn Camera::set_position(
  self : Camera,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  let dx = x - self.eye_x
  let dy = y - self.eye_y
  let dz = z - self.eye_z
  self.recamera(
    x,
    y,
    z,
    self.center_x + dx,
    self.center_y + dy,
    self.center_z + dz,
  )
}

///|
fn Camera::rotate_view(
  self : Camera,
  a : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  let cx = self.center_x - self.eye_x
  let cy = self.center_y - self.eye_y
  let cz = self.center_z - self.eye_z
  let r = @math.Matrix::new(4).rotate(a, x, y, z)
  let m = (i : Int32) => r.get(i)
  let rx = cx * m(0) + cy * m(4) + cz * m(8) + self.eye_x
  let ry = cx * m(1) + cy * m(5) + cz * m(9) + self.eye_y
  let rz = cx * m(2) + cy * m(6) + cz * m(10) + self.eye_z
  self.recamera(self.eye_x, self.eye_y, self.eye_z, rx, ry, rz)
}

///|
/// Rotates the view left/right (radians) about the camera's y-axis.
pub fn Camera::pan(self : Camera, angle : Double) -> Unit {
  let (_, y, _) = self.local_axes()
  self.rotate_view(angle, y.x, y.y, y.z)
}

///|
/// Rotates the view up/down (radians) about the camera's x-axis.
pub fn Camera::tilt(self : Camera, angle : Double) -> Unit {
  let (x, _, _) = self.local_axes()
  self.rotate_view(angle, x.x, x.y, x.z)
}

///|
/// Orbits around the center (`_orbit`): azimuth, polar change, and a
/// log10 zoom factor.
pub fn Camera::orbit(
  self : Camera,
  d_theta : Double,
  d_phi : Double,
  d_radius : Double,
) -> Unit {
  let diff = Vec3::new(
    self.eye_x - self.center_x,
    self.eye_y - self.center_y,
    self.eye_z - self.center_z,
  )
  let mut radius = js_hypot3(diff.x, diff.y, diff.z)
  let front = diff.copy().normalize_()
  let up = Vec3::new(self.up_x, self.up_y, self.up_z).normalize_()
  let side = up.cross(front).normalize_()
  let vertical = side.cross(up)
  radius *= @cmath.pow(10, d_radius)
  if radius < self.camera_near {
    radius = self.camera_near
  }
  if radius > self.camera_far {
    radius = self.camera_far
  }
  let phi = js_acos(front.dot(up).clamp(min=-1, max=1)) + d_phi
  if phi <= 0 || phi >= pi {
    self.up_x *= -1
    self.up_y *= -1
    self.up_z *= -1
  }
  ignore(up.mult_(js_cos(phi)))
  ignore(vertical.mult_(js_cos(d_theta) * js_sin(phi)))
  ignore(side.mult_(js_sin(d_theta) * js_sin(phi)))
  let f = up.copy().add_(vertical).add_(side)
  self.eye_x = radius * f.x + self.center_x
  self.eye_y = radius * f.y + self.center_y
  self.eye_z = radius * f.z + self.center_z
  self.recamera(
    self.eye_x,
    self.eye_y,
    self.eye_z,
    self.center_x,
    self.center_y,
    self.center_z,
  )
}

///|
extern "js" fn js_hypot3(x : Double, y : Double, z : Double) -> Double = "Math.hypot"

///|
extern "js" fn js_acos(x : Double) -> Double = "Math.acos"
