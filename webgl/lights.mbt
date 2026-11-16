// Lights and materials (src/webgl/light.js, material.js). Colors are RGB
// or RGBA in [0, 1]; angles in radians.

///|
pub fn Renderer3D::ambient_light(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
) -> Unit {
  let s = self.state
  s.ambient_light_colors = s.ambient_light_colors.copy()
  s.ambient_light_colors.append([r, g, b])
  s.enable_lighting = true
}

///|
/// The specular color of lights created after this call.
pub fn Renderer3D::specular_color(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
) -> Unit {
  self.state.specular_colors = [r, g, b]
}

///|
pub fn Renderer3D::directional_light(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  let s = self.state
  let l = (x * x + y * y + z * z).sqrt()
  s.directional_directions = s.directional_directions.copy()
  s.directional_directions.append([x / l, y / l, z / l])
  s.directional_diffuse = s.directional_diffuse.copy()
  s.directional_diffuse.append([r, g, b])
  s.directional_specular = s.directional_specular.copy()
  s.directional_specular.append(s.specular_colors)
  s.enable_lighting = true
}

///|
pub fn Renderer3D::point_light(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
  x : Double,
  y : Double,
  z : Double,
) -> Unit {
  let s = self.state
  s.point_positions = s.point_positions.copy()
  s.point_positions.append([x, y, z])
  s.point_diffuse = s.point_diffuse.copy()
  s.point_diffuse.append([r, g, b])
  s.point_specular = s.point_specular.copy()
  s.point_specular.append(s.specular_colors)
  s.enable_lighting = true
}

///|
/// A spot light; at most 4. `angle` is the cone angle in radians
/// (default π/3), `concentration` at least 1 (default 100).
pub fn Renderer3D::spot_light(
  self : Renderer3D,
  r : Double,
  g : Double,
  b : Double,
  position : (Double, Double, Double),
  direction : (Double, Double, Double),
  angle~ : Double = 3.141592653589793 / 3,
  concentration~ : Double = 100,
) -> Unit {
  let s = self.state
  if s.spot_diffuse.length() / 3 >= 4 {
    return
  }
  let concentration = if concentration < 1 { 1.0 } else { concentration }
  s.spot_diffuse = s.spot_diffuse.copy()
  s.spot_diffuse.append([r, g, b])
  s.spot_specular = s.spot_specular.copy()
  s.spot_specular.append(s.specular_colors)
  s.spot_positions = s.spot_positions.copy()
  s.spot_positions.append([position.0, position.1, position.2])
  let d = Vec3::new(direction.0, direction.1, direction.2).normalize_()
  s.spot_directions = s.spot_directions.copy()
  s.spot_directions.append([d.x, d.y, d.z])
  s.spot_angle = s.spot_angle.copy()
  s.spot_angle.push(js_cos(angle))
  s.spot_conc = s.spot_conc.copy()
  s.spot_conc.push(concentration)
  s.enable_lighting = true
}

///|
/// Gray ambient light plus a gray directional light from the front.
pub fn Renderer3D::lights(self : Renderer3D) -> Unit {
  let gray = 128.0 / 255.0
  self.ambient_light(gray, gray, gray)
  self.directional_light(gray, gray, gray, 0, 0, -1)
}

///|
pub fn Renderer3D::light_falloff(
  self : Renderer3D,
  constant : Double,
  linear : Double,
  quadratic : Double,
) -> Unit {
  let mut c = constant.max(0)
  let l = linear.max(0)
  let q = quadratic.max(0)
  if c == 0 && l == 0 && q == 0 {
    c = 1
  }
  self.state.constant_attenuation = c
  self.state.linear_attenuation = l
  self.state.quadratic_attenuation = q
}

///|
pub fn Renderer3D::no_lights(self : Renderer3D) -> Unit {
  let s = self.state
  s.enable_lighting = false
  s.ambient_light_colors = []
  s.specular_colors = [1, 1, 1]
  s.directional_directions = []
  s.directional_diffuse = []
  s.directional_specular = []
  s.point_positions = []
  s.point_diffuse = []
  s.point_specular = []
  s.spot_positions = []
  s.spot_directions = []
  s.spot_diffuse = []
  s.spot_specular = []
  s.spot_angle = []
  s.spot_conc = []
  s.constant_attenuation = 1
  s.linear_attenuation = 0
  s.quadratic_attenuation = 0
  s.shininess = 1
  s.metalness = 0
}

///|
pub fn Renderer3D::ambient_material(
  self : Renderer3D,
  rgba : FixedArray[Double],
) -> Unit {
  let s = self.state
  s.has_set_ambient = true
  s.ambient_color = rgba
  s.normal_material = false
  s.enable_lighting = true
}

///|
pub fn Renderer3D::emissive_material(
  self : Renderer3D,
  rgba : FixedArray[Double],
) -> Unit {
  let s = self.state
  s.emissive_color = rgba
  s.use_emissive = true
  s.normal_material = false
  s.enable_lighting = true
}

///|
pub fn Renderer3D::specular_material(
  self : Renderer3D,
  rgba : FixedArray[Double],
) -> Unit {
  let s = self.state
  s.specular_color = rgba
  s.use_specular = true
  s.normal_material = false
  s.enable_lighting = true
}

///|
pub fn Renderer3D::shininess(self : Renderer3D, shine : Double) -> Unit {
  self.state.shininess = shine.max(1)
}

///|
pub fn Renderer3D::metalness(self : Renderer3D, metallic : Double) -> Unit {
  self.state.metalness = 1.0 - @cmath.exp(-metallic / 100)
}

///|
/// `normalMaterial()`: also resets specular/emissive use.
pub fn Renderer3D::use_normal_material(self : Renderer3D) -> Unit {
  let s = self.state
  s.use_specular = false
  s.use_emissive = false
  s.normal_material = true
}

///|
/// Sets the tint used for textures (0-255 RGBA).
pub fn Renderer3D::set_tint(
  self : Renderer3D,
  rgba : FixedArray[Double],
) -> Unit {
  self.state.tint = rgba
}
