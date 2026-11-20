// GPU instancing: one box is drawn 8,000 times in a single call with
// `instances`. A hook added to p5's material shader with `modify` places
// and colors each copy from `gl_InstanceID`, so the CPU does almost no
// work per box. Needs WebGL 2.

///|
let count : Int32 = 8000

///|
let object_inputs : String =
  #|(Vertex inputs) {
  #|  float id = float(gl_InstanceID);
  #|  float n = float(uCount);
  #|  // points spread over a sphere shell by the golden angle
  #|  float y = 1.0 - 2.0 * (id + 0.5) / n;
  #|  float r = sqrt(1.0 - y * y);
  #|  float a = id * 2.39996323;
  #|  vec3 dir = vec3(cos(a) * r, y, sin(a) * r);
  #|  float wave = sin(uTime * 1.6 + dir.y * 6.0 + a * 0.05);
  #|  float radius = 210.0 + 40.0 * wave;
  #|  // spin each box about its own axis
  #|  float s = uTime * 1.3 + id;
  #|  mat2 rot = mat2(cos(s), -sin(s), sin(s), cos(s));
  #|  inputs.position.xz = rot * inputs.position.xz;
  #|  inputs.normal.xz = rot * inputs.normal.xz;
  #|  inputs.position *= 7.0 * (0.7 + 0.5 * (wave * 0.5 + 0.5));
  #|  inputs.position += dir * radius;
  #|  vec3 c = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + dir.y * 0.5 + uTime * 0.1));
  #|  inputs.color = vec4(c, 1.0);
  #|  return inputs;
  #|}

///|
fn main {
  let shader : Ref[@p5.Shader?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      if p.base_material_shader() is Some(base) {
        shader.val = Some(
          base.modify(
            vertex=[("Vertex getObjectInputs", object_inputs)],
            declarations="uniform float uTime;\nuniform int uCount;",
          ),
        )
      }
    },
    draw=p => {
      guard shader.val is Some(sh) else { return }
      p.background((8, 10, 18))
      p.orbit_control()
      p.ambient_light((70, 70, 90))
      p.directional_light((255, 255, 255), 0.3, 0.6, -1)
      p.rotate_y(p.millis() / 9000)
      p.set_uniform(sh, "uTime", [p.millis() / 1000])
      p.set_uniform(sh, "uCount", [count.to_double()])
      p.shader(sh)
      p.no_stroke()
      p.fill(255)
      p.specular_material((120, 120, 120))
      p.shininess(20)
      p.instances(count, () => p.box(w=1))
    },
  )
}
