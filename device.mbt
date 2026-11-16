// Port of p5.js src/events/acceleration.js (device motion and orientation)
// and pointer lock from src/events/pointer.js.

///|
priv struct Motion {
  mut start_x : Double
  mut start_y : Double
  mut start_z : Double
  mut dir_x : String
  mut dir_y : String
  mut dir_z : String
  mut p_dir_x : String
  mut p_dir_y : String
  mut p_dir_z : String
  mut move_threshold : Double
  mut shake_threshold : Double
}

///|
fn Motion::new() -> Motion {
  {
    start_x: 0,
    start_y: 0,
    start_z: 0,
    dir_x: "clockwise",
    dir_y: "clockwise",
    dir_z: "clockwise",
    p_dir_x: "",
    p_dir_y: "",
    p_dir_z: "",
    move_threshold: 0.5,
    shake_threshold: 30,
  }
}

///|
/// Sets how much acceleration change fires `device_moved` (default 0.5).
pub fn P5::set_move_threshold(self : P5, v : Double) -> Unit {
  self.motion.move_threshold = v
}

///|
/// Sets how much acceleration change fires `device_shaken` (default 30).
pub fn P5::set_shake_threshold(self : P5, v : Double) -> Unit {
  self.motion.shake_threshold = v
}

///|
fn P5::to_degrees_value(self : P5, a : Double) -> Double {
  if self.degrees.val {
    a
  } else {
    a * RAD_TO_DEG
  }
}

///|
fn P5::from_degrees_value(self : P5, a : Double) -> Double {
  if self.degrees.val {
    a
  } else {
    a * DEG_TO_RAD
  }
}

///|
fn P5::on_device_orientation(
  self : P5,
  alpha : Double,
  beta : Double,
  gamma : Double,
) -> Unit {
  self.p_rotation_x = self.rotation_x
  self.p_rotation_y = self.rotation_y
  self.p_rotation_z = self.rotation_z
  self.rotation_x = self.from_degrees_value(beta)
  self.rotation_y = self.from_degrees_value(gamma)
  self.rotation_z = self.from_degrees_value(alpha)
  self.handle_motion()
}

///|
fn P5::on_device_motion(self : P5, x : Double, y : Double, z : Double) -> Unit {
  self.p_acceleration_x = self.acceleration_x
  self.p_acceleration_y = self.acceleration_y
  self.p_acceleration_z = self.acceleration_z
  self.acceleration_x = x * 2
  self.acceleration_y = y * 2
  self.acceleration_z = z * 2
  self.handle_motion()
}

///|
fn P5::handle_motion(self : P5) -> Unit {
  let m = self.motion
  self.device_orientation = match @dom.screen_orientation_type() {
    "landscape-primary" | "landscape-secondary" => "landscape"
    "portrait-primary" | "portrait-secondary" => "portrait"
    _ => "undefined"
  }
  if self.callbacks.device_moved is Some(f) {
    if (self.acceleration_x - self.p_acceleration_x).abs() > m.move_threshold ||
      (self.acceleration_y - self.p_acceleration_y).abs() > m.move_threshold ||
      (self.acceleration_z - self.p_acceleration_z).abs() > m.move_threshold {
      f(self)
    }
  }
  if self.callbacks.device_turned is Some(f) {
    // X
    let w_rx = self.to_degrees_value(self.rotation_x) + 180
    let w_prx = self.to_degrees_value(self.p_rotation_x) + 180
    let mut w_sax = m.start_x + 180
    let dx = w_rx - w_prx
    if (dx > 0 && dx < 270) || dx < -270 {
      m.dir_x = "clockwise"
    } else if dx < 0 || dx > 270 {
      m.dir_x = "counter-clockwise"
    }
    if m.dir_x != m.p_dir_x {
      w_sax = w_rx
    }
    if (w_rx - w_sax).abs() > 90 && (w_rx - w_sax).abs() < 270 {
      w_sax = w_rx
      self.turn_axis = "X"
      f(self)
    }
    m.p_dir_x = m.dir_x
    m.start_x = w_sax - 180
    // Y (p5 compares against the raw p_rotation_y in one branch)
    let w_ry = self.to_degrees_value(self.rotation_y) + 180
    let w_pry = self.to_degrees_value(self.p_rotation_y) + 180
    let mut w_say = m.start_y + 180
    let dy = w_ry - w_pry
    if (dy > 0 && dy < 270) || dy < -270 {
      m.dir_y = "clockwise"
    } else if dy < 0 || w_ry - self.p_rotation_y > 270 {
      m.dir_y = "counter-clockwise"
    }
    if m.dir_y != m.p_dir_y {
      w_say = w_ry
    }
    if (w_ry - w_say).abs() > 90 && (w_ry - w_say).abs() < 270 {
      w_say = w_ry
      self.turn_axis = "Y"
      f(self)
    }
    m.p_dir_y = m.dir_y
    m.start_y = w_say - 180
    // Z
    let rot_z = self.to_degrees_value(self.rotation_z)
    let p_rot_z = self.to_degrees_value(self.p_rotation_z)
    let dz = rot_z - p_rot_z
    if (dz > 0 && dz < 270) || dz < -270 {
      m.dir_z = "clockwise"
    } else if dz < 0 || dz > 270 {
      m.dir_z = "counter-clockwise"
    }
    if m.dir_z != m.p_dir_z {
      m.start_z = rot_z
    }
    if (rot_z - m.start_z).abs() > 90 && (rot_z - m.start_z).abs() < 270 {
      m.start_z = rot_z
      self.turn_axis = "Z"
      f(self)
    }
    m.p_dir_z = m.dir_z
    self.turn_axis = ""
  }
  if self.callbacks.device_shaken is Some(f) {
    let change_x = (self.acceleration_x - self.p_acceleration_x).abs()
    let change_y = (self.acceleration_y - self.p_acceleration_y).abs()
    if change_x + change_y > m.shake_threshold {
      f(self)
    }
  }
}

///|
/// Locks the pointer to the canvas (hiding it); `moved_x`/`moved_y` keep
/// reporting movement. Must be called from a user gesture. Returns false
/// when the browser doesn't support it.
pub fn P5::request_pointer_lock(self : P5) -> Bool {
  match self.canvas {
    Some(c) => @dom.request_pointer_lock(c)
    None => false
  }
}

///|
/// Releases a pointer lock.
pub fn P5::exit_pointer_lock(_self : P5) -> Unit {
  @dom.exit_pointer_lock()
}
