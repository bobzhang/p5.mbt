// Model loading (src/webgl/loading.js): OBJ (without MTL materials) and
// STL (ASCII and binary), plus Geometry.normalize/flipU/flipV.

///|
/// `line.trim().split(/\b\s+/)`, as p5 tokenizes OBJ lines.
extern "js" fn obj_tokens(line : String) -> FixedArray[String] =
  #|(line) => line.trim().split(/\b\s+/)

///|
extern "js" fn js_parse_float(s : String) -> Double = "parseFloat"

///|
/// `parseInt(s)` with p5's 1-based fix-up; NaN becomes 0 like `.at(NaN)`.
extern "js" fn obj_index(s : String) -> Int32 =
  #|(s) => { let i = parseInt(s); if (i > 0) i -= 1; return Number.isNaN(i) ? 0 : i; }

///|
fn[T] at(arr : Array[T], i : Int32) -> T? {
  let i = if i < 0 { arr.length() + i } else { i }
  arr.get(i)
}

///|
/// Parses an OBJ file (vertices, texture coordinates, normals, faces).
pub fn parse_obj(text : String) -> Geometry {
  let model = Geometry::new()
  let vs : Array[Vec3] = []
  let vts : Array[(Double, Double)] = []
  let vns : Array[Vec3] = []
  let used : Map[String, Int32] = Map([])
  for line in text.split("\n") {
    let tokens = obj_tokens(line.to_string())
    if tokens.length() == 0 {
      continue
    }
    match tokens[0] {
      "v" | "vn" => {
        let v = Vec3::new(
          js_parse_float(tokens.get(1).unwrap_or("")),
          js_parse_float(tokens.get(2).unwrap_or("")),
          js_parse_float(tokens.get(3).unwrap_or("")),
        )
        if tokens[0] == "v" {
          vs.push(v)
        } else {
          vns.push(v)
        }
      }
      "vt" =>
        vts.push(
          (
            js_parse_float(tokens.get(1).unwrap_or("")),
            1.0 - js_parse_float(tokens.get(2).unwrap_or("")),
          ),
        )
      "f" =>
        for tri in 3..<tokens.length() {
          let face : Array[Int32] = []
          for ti in [1, tri - 1, tri] {
            let vert = tokens[ti]
            match used.get(vert) {
              Some(i) => face.push(i)
              None => {
                let parts = vert
                  .split("/")
                  .map(s => obj_index(s.to_string()))
                  .collect()
                let idx = model.vertices.length()
                guard at(vs, parts[0]) is Some(p) else { continue }
                model.vertices.push(p.copy())
                // a missing index reads entry 0, like `.at(undefined)` in p5
                match at(vts, parts.get(1).unwrap_or(0)) {
                  Some((u, v)) => model.uvs.append([u, v])
                  None => model.uvs.append([0, 0])
                }
                match at(vns, parts.get(2).unwrap_or(0)) {
                  Some(n) => model.vertex_normals.push(n.copy())
                  None => model.vertex_normals.push(Vec3::new(0, 0, 0))
                }
                used[vert] = idx
                face.push(idx)
              }
            }
          }
          if face.length() == 3 &&
            face[0] != face[1] &&
            face[0] != face[2] &&
            face[1] != face[2] {
            model.faces.push((face[0], face[1], face[2]))
          }
        }
      _ => ()
    }
  }
  if model.vertex_normals.is_empty() {
    ignore(model.compute_normals())
  }
  model
}

///|
extern "js" fn stl_is_binary(data : FixedArray[Byte]) -> Bool =
  #|(data) => {
  #|  const solid = [115, 111, 108, 105, 100];
  #|  for (let off = 0; off < 5; off++) {
  #|    let ok = true;
  #|    for (let i = 0; i < 5; i++) if (data[off + i] !== solid[i]) { ok = false; break; }
  #|    if (ok) return false;
  #|  }
  #|  return true;
  #|}

///|
/// Reads the binary STL triangles: per face, normal then three vertices
/// (12 floats).
extern "js" fn stl_binary_floats(data : FixedArray[Byte]) -> FixedArray[Double] =
  #|(data) => {
  #|  const r = new DataView(data.buffer, data.byteOffset, data.byteLength);
  #|  const faces = r.getUint32(80, true), out = [];
  #|  for (let f = 0; f < faces; f++) {
  #|    const s = 84 + f * 50;
  #|    for (let k = 0; k < 12; k++) out.push(r.getFloat32(s + k * 4, true));
  #|  }
  #|  return out;
  #|}

///|
extern "js" fn utf8_decode(data : FixedArray[Byte]) -> String =
  #|(data) => new TextDecoder('utf-8').decode(data)

///|
/// Parses an STL file (binary or ASCII).
pub fn parse_stl(data : FixedArray[Byte]) -> Geometry {
  let model = Geometry::new()
  if stl_is_binary(data) {
    let f = stl_binary_floats(data)
    let faces = f.length() / 12
    for face in 0..<faces {
      let b = face * 12
      let n = Vec3::new(f[b], f[b + 1], f[b + 2])
      for i in 1..<=3 {
        model.vertices.push(
          Vec3::new(f[b + i * 3], f[b + i * 3 + 1], f[b + i * 3 + 2]),
        )
        model.vertex_normals.push(n)
      }
      model.faces.push((3 * face, 3 * face + 1, 3 * face + 2))
      model.uvs.append([0, 0, 0, 0, 0, 0])
    }
    return model
  }
  let mut state = ""
  let mut cur : Array[Int32] = []
  for raw in utf8_decode(data).split("\n") {
    let parts = raw
      .trim()
      .split(" ")
      .map(s => s.to_string())
      .collect()
      .filter(p => p != "")
    if parts.is_empty() {
      continue
    }
    let p0 = parts[0]
    let p1 = parts.get(1).unwrap_or("")
    let normal = () => {
      let n = Vec3::new(
        js_parse_float(parts.get(2).unwrap_or("")),
        js_parse_float(parts.get(3).unwrap_or("")),
        js_parse_float(parts.get(4).unwrap_or("")),
      )
      model.vertex_normals.push(n)
      model.vertex_normals.push(n)
      model.vertex_normals.push(n)
    }
    match state {
      "" => if p0 != "solid" { return model } else { state = "solid" }
      "solid" =>
        if p0 != "facet" || p1 != "normal" {
          return model
        } else {
          normal()
          state = "facet normal"
        }
      "facet normal" =>
        if p0 != "outer" || p1 != "loop" {
          return model
        } else {
          state = "vertex"
        }
      "vertex" =>
        if p0 == "vertex" {
          model.vertices.push(
            Vec3::new(
              js_parse_float(p1),
              js_parse_float(parts.get(2).unwrap_or("")),
              js_parse_float(parts.get(3).unwrap_or("")),
            ),
          )
          model.uvs.append([0, 0])
          cur.push(model.vertices.length() - 1)
        } else if p0 == "endloop" {
          if cur.length() >= 3 {
            model.faces.push((cur[0], cur[1], cur[2]))
          }
          cur = []
          state = "endloop"
        } else {
          return model
        }
      "endloop" =>
        if p0 != "endfacet" {
          return model
        } else {
          state = "endfacet"
        }
      "endfacet" =>
        if p0 == "endsolid" {
          ()
        } else if p0 == "facet" && p1 == "normal" {
          normal()
          state = "facet normal"
        } else {
          return model
        }
      _ => ()
    }
  }
  model
}

///|
/// Scales and centers the model to fit 200 units (`normalize`).
pub fn Geometry::normalize(self : Geometry) -> Geometry {
  if self.vertices.length() > 0 {
    let max = self.vertices[0].copy()
    let min = self.vertices[0].copy()
    for v in self.vertices {
      max.x = max.x.max(v.x)
      min.x = min.x.min(v.x)
      max.y = max.y.max(v.y)
      min.y = min.y.min(v.y)
      max.z = max.z.max(v.z)
      min.z = min.z.min(v.z)
    }
    let center = Vec3::new(
      max.x + (min.x - max.x) * 0.5,
      max.y + (min.y - max.y) * 0.5,
      max.z + (min.z - max.z) * 0.5,
    )
    let dist = max.copy().sub_(min)
    let longest = dist.x.max(dist.y).max(dist.z)
    let scale = 200.0 / longest
    for v in self.vertices {
      ignore(v.sub_(center).mult_(scale))
    }
    self.dirty = true
  }
  self
}

///|
/// Mirrors texture coordinates horizontally.
pub fn Geometry::flip_u(self : Geometry) -> Unit {
  for i = 0; i < self.uvs.length(); i = i + 2 {
    self.uvs[i] = 1.0 - self.uvs[i]
  }
  self.dirty = true
}

///|
/// Mirrors texture coordinates vertically.
pub fn Geometry::flip_v(self : Geometry) -> Unit {
  for i = 1; i < self.uvs.length(); i = i + 2 {
    self.uvs[i] = 1.0 - self.uvs[i]
  }
  self.dirty = true
}

///|
/// Copies another geometry's contents into this one (used when a model
/// finishes loading into a geometry handed out earlier).
pub fn Geometry::assign(self : Geometry, other : Geometry) -> Unit {
  for
    (dst, src) in [
      (self.vertices, other.vertices),
      (self.vertex_normals, other.vertex_normals),
    ] {
    dst.clear()
    dst.append(src)
  }
  self.uvs.clear()
  self.uvs.append(other.uvs)
  self.faces.clear()
  self.faces.append(other.faces)
  self.edges.clear()
  self.edges.append(other.edges)
  self.vertex_colors.clear()
  self.vertex_colors.append(other.vertex_colors)
  self.dirty = true
}
