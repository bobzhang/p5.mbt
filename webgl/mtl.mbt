// MTL materials for OBJ models (src/webgl/loading.js: parseMtlData,
// mtlToPartState, buildMaterialParts; p5.GeometryPart.js): a model whose
// faces use several materials is split into parts, each drawn with its
// own colors and texture maps.

///|
/// A material from an MTL file. Texture paths are relative to the model;
/// the loaded textures are filled in by the loader.
pub struct Material {
  mut diffuse : (Double, Double, Double)?
  mut ambient : (Double, Double, Double)?
  mut specular : (Double, Double, Double)?
  mut shininess : Double?
  mut opacity : Double?
  mut illumination : Int32?
  mut texture_path : String?
  mut ambient_texture_path : String?
  mut specular_texture_path : String?
  mut shininess_texture_path : String?
  mut bump_texture_path : String?
  mut normal_texture_path : String?
  mut bump_scale : Double?
  mut texture : TexSource?
  mut ambient_texture : TexSource?
  mut specular_texture : TexSource?
  mut shininess_texture : TexSource?
  mut bump_texture : TexSource?
  mut normal_texture : TexSource?
}

///|
fn Material::new() -> Material {
  {
    diffuse: None,
    ambient: None,
    specular: None,
    shininess: None,
    opacity: None,
    illumination: None,
    texture_path: None,
    ambient_texture_path: None,
    specular_texture_path: None,
    shininess_texture_path: None,
    bump_texture_path: None,
    normal_texture_path: None,
    bump_scale: None,
    texture: None,
    ambient_texture: None,
    specular_texture: None,
    shininess_texture: None,
    bump_texture: None,
    normal_texture: None,
  }
}

///|
extern "js" fn mtl_tokens(line : String) -> FixedArray[String] =
  #|(line) => line.trim().split(/\s+/)

///|
/// Parses an MTL file into materials by name (p5's `parseMtlData`).
pub fn parse_mtl(text : String) -> Map[String, Material] {
  let materials : Map[String, Material] = Map([])
  let mut current : Material? = None
  for line in text.split("\n") {
    let t = mtl_tokens(line.to_owned())
    let tok = (i : Int32) => t.get(i).unwrap_or("")
    let num = (i : Int32) => js_parse_float(tok(i))
    let rgb = () => (num(1), num(2), num(3))
    if tok(0) == "newmtl" {
      let m = Material::new()
      materials[tok(1)] = m
      current = Some(m)
      continue
    }
    guard current is Some(m) else { continue }
    let bump_scale = () => {
      for i in 0..<(t.length() - 1) {
        if t[i] == "-bm" {
          let v = js_parse_float(t[i + 1])
          if !v.is_nan() {
            m.bump_scale = Some(v)
          }
        }
      }
    }
    match tok(0) {
      "Kd" => m.diffuse = Some(rgb())
      "Ka" => m.ambient = Some(rgb())
      "Ks" => m.specular = Some(rgb())
      "Ns" => m.shininess = Some(num(1))
      "d" => m.opacity = Some(num(1))
      "Tr" => m.opacity = Some(1 - num(1))
      "illum" => m.illumination = Some(num(1).to_int())
      "map_Kd" => m.texture_path = Some(tok(1))
      "map_Ka" => m.ambient_texture_path = Some(tok(1))
      "map_Ks" => m.specular_texture_path = Some(tok(1))
      "map_Ns" => m.shininess_texture_path = Some(tok(1))
      "map_Bump" | "bump" => {
        m.bump_texture_path = Some(t[t.length() - 1])
        bump_scale()
      }
      "norm" => {
        m.normal_texture_path = Some(t[t.length() - 1])
        bump_scale()
      }
      _ => ()
    }
  }
  materials
}

///|
/// The texture maps of a material: its path and a setter for the loaded
/// texture (p5's `MATERIAL_TEXTURE_MAPS`).
pub fn Material::texture_maps(
  self : Material,
) -> Array[(String, (TexSource) -> Unit)] {
  let out : Array[(String, (TexSource) -> Unit)] = []
  if self.texture_path is Some(p) {
    out.push((p, t => self.texture = Some(t)))
  }
  if self.specular_texture_path is Some(p) {
    out.push((p, t => self.specular_texture = Some(t)))
  }
  if self.ambient_texture_path is Some(p) {
    out.push((p, t => self.ambient_texture = Some(t)))
  }
  if self.shininess_texture_path is Some(p) {
    out.push((p, t => self.shininess_texture = Some(t)))
  }
  if self.bump_texture_path is Some(p) {
    out.push((p, t => self.bump_texture = Some(t)))
  }
  if self.normal_texture_path is Some(p) {
    out.push((p, t => self.normal_texture = Some(t)))
  }
  out
}

///|
/// The material of one part of a model (p5's part state). `None` fields
/// leave the sketch's current material in place.
pub struct PartState {
  /// RGBA in [0, 1].
  fill : FixedArray[Double]?
  ambient : FixedArray[Double]?
  specular : FixedArray[Double]?
  shininess : Double?
  texture : TexSource?
  specular_texture : TexSource?
  ambient_texture : TexSource?
  shininess_texture : TexSource?
  normal_texture : TexSource?
  normal_scale : Double
  /// 0: normal map; 1: bump (height) map.
  normal_map_mode : Int32
}

///|
/// p5's `mtlToPartState`.
pub fn Material::to_part_state(self : Material) -> PartState {
  let rgba = (c : (Double, Double, Double)) => {
    let a : FixedArray[Double] = [c.0, c.1, c.2, 1]
    a
  }
  let fill = self.diffuse.map(c => {
    let a : FixedArray[Double] = [c.0, c.1, c.2, self.opacity.unwrap_or(1)]
    a
  })
  let mut specular = self.specular.map(rgba)
  if self.specular_texture is Some(_) && specular is None {
    specular = Some([1, 1, 1, 1])
  }
  let mut ambient = self.ambient.map(rgba)
  if self.ambient_texture is Some(_) && ambient is None {
    ambient = Some([1, 1, 1, 1])
  }
  let mut shininess = self.shininess
  if self.shininess_texture is Some(_) && shininess is None {
    shininess = Some(1)
  }
  let (normal_texture, mode) = match (self.normal_texture, self.bump_texture) {
    (Some(n), _) => (Some(n), 0)
    (None, Some(b)) => (Some(b), 1)
    _ => (None, 0)
  }
  {
    fill,
    ambient,
    specular,
    shininess,
    texture: self.texture,
    specular_texture: self.specular_texture,
    ambient_texture: self.ambient_texture,
    shininess_texture: self.shininess_texture,
    normal_texture,
    normal_scale: self.bump_scale.unwrap_or(1),
    normal_map_mode: mode,
  }
}

///|
fn PartState::has_material(self : PartState) -> Bool {
  self.fill is Some(_) ||
  self.texture is Some(_) ||
  self.ambient is Some(_) ||
  self.specular is Some(_) ||
  self.shininess is Some(_) ||
  self.specular_texture is Some(_) ||
  self.ambient_texture is Some(_) ||
  self.shininess_texture is Some(_)
}

///|
/// Splits a model into one part per material (p5's `buildMaterialParts`).
/// `face_materials` names the material of each face.
fn build_material_parts(
  model : Geometry,
  face_materials : Array[String?],
  materials : Map[String, Material],
) -> Unit {
  let names : Array[String?] = []
  for m in face_materials {
    if !names.contains(m) {
      names.push(m)
    }
  }
  let state_of = (name : String?) => {
    match name {
      Some(n) => materials.get(n).map(m => m.to_part_state())
      None => None
    }
  }
  if names.length() == 1 && names[0] is Some(_) {
    model.part_state = state_of(names[0])
    return
  }
  if names.filter(n => n is Some(_)).length() < 2 {
    return
  }
  let has_uvs = model.uvs.length() > 0
  let has_normals = model.vertex_normals.length() > 0
  let has_tangents = model.vertex_tangents.length() > 0
  for name in names {
    let part = Geometry::new()
    part.gid = "\{model.gid}|part\{model.parts.length()}"
    part.part_state = state_of(name)
    let local_index : Map[Int32, Int32] = Map([])
    for fi, f in model.faces {
      if face_materials[fi] != name {
        continue
      }
      let map = (vi : Int32) => {
        match local_index.get(vi) {
          Some(i) => i
          None => {
            let i = part.vertices.length()
            local_index[vi] = i
            part.vertices.push(model.vertices[vi])
            if has_uvs {
              part.uvs.append([model.uvs[vi * 2], model.uvs[vi * 2 + 1]])
            }
            if has_normals {
              part.vertex_normals.push(model.vertex_normals[vi])
            }
            if has_tangents {
              for k in 0..<4 {
                part.vertex_tangents.push(model.vertex_tangents[vi * 4 + k])
              }
            }
            i
          }
        }
      }
      part.faces.push((map(f.0), map(f.1), map(f.2)))
    }
    model.parts.push(part)
  }
}
