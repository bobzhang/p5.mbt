// p5.mbt side of the parity cases; parity/cases.js has the p5.js side.
// The page calls `p5mbt_render(name, container)` for each case.

///|
struct Case {
  w : Double
  h : Double
  draw : (@p5.P5) -> Unit
  preload : ((@p5.P5) -> Unit)?
  webgl : Bool
}

///|
fn cases() -> Map[String, Case] {
  let sync : Map[String, (Double, Double, (@p5.P5) -> Unit)] = {
    "basics": (200, 150, basics),
    "modes": (220, 160, modes),
    "rounded": (200, 120, rounded),
    "arcs": (240, 170, arcs),
    "strokes": (240, 160, strokes),
    "polygons": (220, 120, polygons),
    "curves": (240, 160, curves),
    "shape_kinds": (300, 200, shape_kinds),
    "contours": (220, 160, contours),
    "transforms": (220, 220, transforms),
    "color_modes": (260, 120, color_modes),
    "blend_erase": (200, 120, blend_erase),
    "clipping": (200, 140, clipping),
    "text_basic": (260, 160, text_basic),
    "text_align": (260, 200, text_align),
    "text_box": (260, 200, text_box),
    "text_metrics": (300, 120, text_metrics),
    "random_noise": (200, 200, random_noise),
    "vectors_trig": (200, 200, vectors_trig),
    "pixels": (100, 80, pixels),
    "copy_blend": (240, 160, copy_blend),
    "image_modes": (240, 160, image_modes),
    "filter_gray": (120, 90, p => filtered(p, Gray)),
    "filter_invert": (120, 90, p => filtered(p, Invert)),
    "filter_threshold": (120, 90, p => filtered(p, Threshold(0.4))),
    "filter_posterize": (120, 90, p => filtered(p, Posterize(3))),
    "filter_erode": (120, 90, p => filtered(p, Erode)),
    "filter_dilate": (120, 90, p => filtered(p, Dilate)),
    "filter_blur": (120, 90, p => filtered(p, Blur(3))),
    "shader_filter_gray": (120, 90, p => filtered_gl(p, Gray)),
    "shader_filter_threshold": (120, 90, p => filtered_gl(p, Threshold(0.4))),
    "shader_filter_posterize": (120, 90, p => filtered_gl(p, Posterize(3))),
    "shader_filter_blur": (120, 90, p => filtered_gl(p, Blur(3))),
    "shader_filter_erode": (120, 90, p => filtered_gl(p, Erode)),
  }
  let all : Map[String, Case] = Map([])
  for name, c in sync {
    all[name] = { w: c.0, h: c.1, draw: c.2, preload: None, webgl: false, }
  }
  // gif_frames needs the image loaded first
  let img : Ref[@p5.Image?] = Ref(None)
  all["gif_frames"] = {
    w: 300,
    h: 160,
    preload: Some(p => {
      img.val = Some(p.load_image("../examples/assets/testcard.gif"))
    }),
    draw: p => if img.val is Some(img) { gif_frames(p, img) },
    webgl: false,
  }
  let svg : Ref[@p5.ShapeCollection?] = Ref(None)
  all["svg_import"] = {
    w: 240,
    h: 160,
    preload: Some(p => {
      p.load_svg("../examples/assets/shapes.svg", c => svg.val = Some(c))
    }),
    draw: p => {
      p.background(255)
      if svg.val is Some(c) {
        p.shape(c)
      }
    },
    webgl: false,
  }
  all["svg_replay"] = {
    w: 220,
    h: 160,
    preload: None,
    draw: svg_replay,
    webgl: false,
  }
  let inconsolata : Ref[@p5.Font?] = Ref(None)
  all["font_points"] = {
    w: 260,
    h: 120,
    preload: Some(p => {
      inconsolata.val = Some(
        p.load_font("../examples/assets/Inconsolata-Bold.ttf"),
      )
    }),
    draw: p => if inconsolata.val is Some(f) { font_points(p, f) },
    webgl: false,
  }
  let source_sans : Ref[@p5.Font?] = Ref(None)
  all["font_text"] = {
    w: 260,
    h: 120,
    preload: Some(p => {
      source_sans.val = Some(
        p.load_font("../examples/assets/SourceSansPro-Regular.otf"),
      )
    }),
    draw: p => if source_sans.val is Some(f) { font_text(p, f) },
    webgl: false,
  }
  for name, c in gl_cases() {
    all[name] = { w: c.0, h: c.1, draw: c.2, preload: None, webgl: true, }
  }
  all
}

///|
fn gl_cases() -> Map[String, (Double, Double, (@p5.P5) -> Unit)] {
  {
    "gl_primitives": (260, 200, gl_primitives),
    "gl_2d": (280, 200, gl_2d),
    "gl_filter": (240, 160, gl_filter),
    "gl_framebuffer": (260, 180, gl_framebuffer),
    "gl_textures": (280, 200, gl_textures),
    "gl_shader": (240, 160, gl_shader),
    "gl_shapes": (280, 200, gl_shapes),
    "gl_lights": (260, 200, gl_lights),
    "gl_camera": (260, 200, gl_camera),
  }
}

///|
fn checker(p : @p5.P5) -> @p5.Image {
  let img = p.create_image(32, 32)
  img.load_pixels()
  for y in 0..<32 {
    for x in 0..<32 {
      let i = 4 * (y * 32 + x)
      let on = ((x >> 2) + (y >> 2)) % 2 == 1
      img.pixels[i] = (if on { 250 } else { 40 }).to_byte()
      img.pixels[i + 1] = (x * 8).to_byte()
      img.pixels[i + 2] = (y * 8).to_byte()
      img.pixels[i + 3] = 255
    }
  }
  img.update_pixels()
  img
}

///|
fn gl_textures(p : @p5.P5) -> Unit {
  let img = checker(p)
  p.background(200)
  p.no_stroke()
  p.push()
  p.translate(-90, -40)
  p.rotate_x(0.5)
  p.rotate_y(0.7)
  p.texture(img)
  p.box(w=60)
  p.pop()
  p.push()
  p.translate(0, -40)
  p.texture(img)
  p.sphere(r=35)
  p.pop()
  p.push()
  p.translate(90, -40)
  p.texture_mode(Normal)
  p.texture_wrap(Repeat)
  p.texture(img)
  p.begin_shape()
  p.vertex(-40, -30, u=0, v=0)
  p.vertex(40, -30, u=3, v=0)
  p.vertex(40, 30, u=3, v=2)
  p.vertex(-40, 30, u=0, v=2)
  p.end_shape(mode=Close)
  p.pop()
  p.image(img, -130, 30, w=60, h=60)
  p.tint((255, 120, 120))
  p.image_region(img, -60, 30, 60, 60, 8, 8, 16, 16)
  p.no_tint()
  p.push()
  p.translate(70, 60)
  p.texture(img)
  p.texture_mode(Image)
  p.ellipse(0, 0, 70, h=50)
  p.pop()
}

///|
fn gl_shader(p : @p5.P5) -> Unit {
  let img = checker(p)
  let sh = p.create_shader(
    (
      #|
      #|precision highp float;
      #|attribute vec3 aPosition; attribute vec2 aTexCoord;
      #|uniform mat4 uModelViewMatrix; uniform mat4 uProjectionMatrix;
      #|varying vec2 vUv;
      #|void main() { vUv = aTexCoord; gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0); }
    ),
    (
      #|
      #|precision highp float;
      #|varying vec2 vUv; uniform float uMix; uniform vec3 uTint; uniform sampler2D uTex;
      #|void main() { vec4 t = texture2D(uTex, vUv); gl_FragColor = vec4(mix(t.rgb, uTint * vUv.x, uMix), 1.0); }
    ),
  )
  p.background(30)
  p.no_stroke()
  p.shader(sh)
  p.set_uniform(sh, "uMix", [0.4])
  p.set_uniform(sh, "uTint", [1.0, 0.5, 0.2])
  p.set_uniform_texture(sh, "uTex", img)
  p.push()
  p.translate(-60, 0)
  p.rotate_y(0.6)
  p.box(w=70)
  p.pop()
  p.push()
  p.translate(60, 0)
  p.sphere(r=45)
  p.pop()
  p.reset_shader()
  p.fill(255)
  p.circle(0, 60, 20)
}

///|
fn gl_framebuffer(p : @p5.P5) -> Unit {
  guard p.create_framebuffer(width=120, height=90) is Some(fb) else { return }
  fb.draw(() => {
    p.background((40, 60, 120))
    p.no_stroke()
    p.lights()
    p.rotate_x(0.6)
    p.rotate_y(0.8)
    p.fill((250, 180, 60))
    p.box(w=45)
  })
  guard p.create_framebuffer(width=64, height=64, antialias=0) is Some(small) else {
    return
  }
  small.draw(() => {
    p.clear()
    p.fill((255, 60, 120))
    p.no_stroke()
    p.circle(0, 0, 50)
  })
  p.background(230)
  p.image(fb, -125, -85)
  p.push()
  p.translate(65, -20)
  p.rotate_y(0.5)
  p.texture(fb)
  p.no_stroke()
  p.plane(w=110, h=80)
  p.pop()
  p.image(small, -60, 20, w=64, h=64)
  p.push()
  p.translate(70, 55)
  p.texture(small)
  p.no_stroke()
  p.sphere(r=30)
  p.pop()
}

///|
fn gl_filter(p : @p5.P5) -> Unit {
  p.background((30, 40, 60))
  p.no_stroke()
  p.lights()
  p.fill((250, 120, 60))
  p.push()
  p.translate(-60, 0)
  p.rotate_x(0.5)
  p.rotate_y(0.7)
  p.box(w=70)
  p.pop()
  p.fill((80, 200, 160))
  p.push()
  p.translate(60, 0)
  p.sphere(r=45)
  p.pop()
  p.filter(Gray)
  p.filter(Blur(2))
  p.fill(255)
  p.circle(0, 55, 30)
}

///|
fn gl_2d(p : @p5.P5) -> Unit {
  p.background(250)
  p.translate(-140, -100)
  p.stroke(20)
  p.stroke_weight(3)
  p.fill((240, 120, 60))
  p.rect(10, 10, 60, 40)
  p.rect(80, 10, 60, 40, tl=12)
  p.ellipse(190, 30, 60, h=40)
  p.arc(250, 30, 40, 40, 0, @p5.PI * 1.3, mode=Pie)
  p.arc(40, 90, 50, 40, 0.3, 4, mode=Chord)
  p.no_fill()
  p.arc(100, 90, 50, 40, 0.3, 4, mode=Open)
  p.fill((60, 160, 220))
  p.arc(160, 90, 50, 40, 1, 5)
  p.triangle(200, 70, 270, 80, 220, 120)
  p.quad(10, 130, 70, 125, 80, 190, 20, 180)
  p.stroke_weight(6)
  p.line(100, 130, 160, 190)
  p.point(180, 140)
  p.stroke_cap(Square)
  p.point(200, 140)
  p.stroke_weight(2)
  p.no_fill()
  p.bezier(180, 190, 200, 120, 260, 200, 270, 150)
}

///|
fn gl_shapes(p : @p5.P5) -> Unit {
  p.background(240)
  p.translate(-140, -100)
  p.stroke(0)
  p.stroke_weight(2)
  p.fill((250, 200, 0))
  p.begin_shape()
  p.vertex(20, 20)
  p.vertex(120, 20)
  p.vertex(120, 90)
  p.vertex(20, 90)
  p.begin_contour()
  p.vertex(50, 40)
  p.vertex(50, 70)
  p.vertex(90, 70)
  p.vertex(90, 40)
  p.end_contour(mode=Close)
  p.end_shape(mode=Close)
  p.fill((200, 40, 120))
  p.begin_shape()
  for i in 0..<5 {
    let a = -@p5.HALF_PI + i.to_double() * @p5.TWO_PI * 2 / 5
    p.vertex(200 + 50 * js_cos(a), 60 + 50 * js_sin(a))
  }
  p.end_shape(mode=Close)
  p.begin_shape(kind=Triangles)
  p.fill((255, 0, 0))
  p.vertex(20, 120)
  p.fill((0, 255, 0))
  p.vertex(80, 120)
  p.fill((0, 0, 255))
  p.vertex(50, 180)
  p.end_shape()
  p.fill((120, 200, 255))
  p.begin_shape(kind=QuadStrip)
  p.vertex(100, 120)
  p.vertex(100, 180)
  p.vertex(140, 130)
  p.vertex(140, 170)
  p.vertex(180, 120)
  p.vertex(180, 190)
  p.end_shape()
  p.fill((100, 220, 100))
  p.begin_shape()
  p.vertex(200, 120)
  p.bezier_vertex(280, 110)
  p.bezier_vertex(260, 200)
  p.bezier_vertex(210, 190)
  p.end_shape(mode=Close)
}

///|
fn gl_primitives(p : @p5.P5) -> Unit {
  p.background(220)
  p.fill((200, 100, 50))
  p.stroke(0)
  p.push()
  p.translate(-80, -45)
  p.rotate_x(0.5)
  p.rotate_y(0.6)
  p.box(w=50)
  p.pop()
  p.push()
  p.translate(0, -45)
  p.sphere(r=32)
  p.pop()
  p.push()
  p.translate(85, -45)
  p.rotate_x(1)
  p.cylinder(r=22, h=50)
  p.pop()
  p.push()
  p.translate(-80, 50)
  p.rotate_x(0.7)
  p.cone(r=25, h=50)
  p.pop()
  p.push()
  p.translate(0, 50)
  p.rotate_x(1.1)
  p.torus(r=28, tube=9)
  p.pop()
  p.push()
  p.translate(85, 50)
  p.rotate_y(0.8)
  p.normal_material()
  p.ellipsoid(rx=32, ry=22, rz=16)
  p.pop()
}

///|
fn gl_lights(p : @p5.P5) -> Unit {
  p.background(25)
  p.no_stroke()
  p.ambient_light(50)
  p.directional_light((255, 255, 255), 0.3, 0.5, -1)
  p.point_light((255, 0, 0), 100, -100, 100)
  p.push()
  p.translate(-70, 0)
  p.fill(255)
  p.specular_material(250)
  p.shininess(20)
  p.sphere(r=55)
  p.pop()
  p.push()
  p.translate(70, 0)
  p.rotate_x(0.6)
  p.rotate_y(0.4)
  p.fill((60, 140, 255))
  p.ambient_material((100, 200, 50))
  p.box(w=70)
  p.pop()
  p.push()
  p.translate(0, 75)
  p.emissive_material((40, 0, 60))
  p.fill(200)
  p.torus(r=30, tube=8)
  p.pop()
}

///|
fn gl_camera(p : @p5.P5) -> Unit {
  p.background(240)
  p.stroke(30)
  p.stroke_weight(2)
  p.fill((250, 200, 0))
  p.camera(eye=(150, -120, 260), center=(0, 0, 0), up=(0, 1, 0))
  p.perspective(fovy=@p5.PI / 4, aspect=260.0 / 200.0, near=10, far=2000)
  p.box(w=80)
  p.translate(90, 0, z=-60)
  p.fill((0, 150, 200))
  p.sphere(r=30, detail_x=12, detail_y=8)
  p.translate(-180, 0, z=120)
  p.ortho()
  p.fill((220, 60, 90))
  p.cone(r=30, h=60)
}

///|
fn font_points(p : @p5.P5, font : @p5.Font) -> Unit {
  p.background(255)
  p.no_stroke()
  p.fill(0)
  p.text_size(64)
  for q in font.text_to_points("p5*js", 10, 80, sample_factor=0.3) {
    p.circle(q.x, q.y, 3)
  }
}

///|
fn font_text(p : @p5.P5, font : @p5.Font) -> Unit {
  p.background(250)
  p.fill((20, 40, 120))
  p.text_font_face(font, size=40)
  p.text("Typography", 10, 50)
  p.text_size(20)
  p.text_align(HCenter)
  p.text("centred in a box that wraps", 20, 70, max_width=220)
}

///|
extern "js" fn json_num(d : Double) -> String =
  #|(d) => JSON.stringify(d)

///|
fn points_json(pts : Array[@p5.TextPoint]) -> String {
  "[" +
  pts
  .map(q => "[\{json_num(q.x)},\{json_num(q.y)},\{json_num(q.angle)}]")
  .join(",") +
  "]"
}

///|
/// Cases whose result is data (JSON) rather than pixels.
fn data_cases() -> Map[String, (String, (@p5.P5, @p5.Font) -> String)] {
  {
    "font_points_ttf": (
      "Inconsolata-Bold.ttf",
      (p, f) => {
        p.text_size(48)
        points_json(f.text_to_points("p5*js", 10, 70, sample_factor=0.3))
      },
    ),
    "font_contours_otf": (
      "SourceSansPro-Regular.otf",
      (p, f) => {
        p.text_size(30)
        p.text_align(HCenter)
        p.rect_mode(Center)
        p.angle_mode(Degrees)
        let cs = f.text_to_contours(
          "Hello brave new\nworld",
          120,
          70,
          max_width=200,
          max_height=120,
          sample_factor=0.2,
          simplify_threshold=0.05,
        )
        "[" + cs.map(points_json).join(",") + "]"
      },
    ),
    "font_paths_woff": (
      "Lato-Regular.woff",
      (p, f) => {
        p.text_size(36)
        let cmds = f.text_to_paths("Quiz&", 5, 60)
        "[" +
        cmds
        .map(c => {
          match c {
            MoveTo(x, y) => "[\"M\",\{json_num(x)},\{json_num(y)}]"
            LineTo(x, y) => "[\"L\",\{json_num(x)},\{json_num(y)}]"
            QuadraticCurveTo(a, b, x, y) =>
              "[\"Q\",\{json_num(a)},\{json_num(b)},\{json_num(x)},\{json_num(y)}]"
            BezierCurveTo(a, b, c, d, x, y) =>
              "[\"C\",\{json_num(a)},\{json_num(b)},\{json_num(c)},\{json_num(d)},\{json_num(x)},\{json_num(y)}]"
            ClosePath => "[\"Z\"]"
            _ => "[\"?\"]"
          }
        })
        .join(",") +
        "]"
      },
    ),
  }
}

///|
extern "js" fn expose_data(
  run : (String, String, (String) -> Unit) -> Bool,
) -> Unit = "(f) => { globalThis.p5mbt_data = f; }"

///|
fn svg_replay(p : @p5.P5) -> Unit {
  p.background(250)
  let rec = p.build_shape(() => {
    p.fill((255, 0, 100))
    p.stroke(0)
    p.stroke_weight(2)
    p.circle(50, 50, 60)
    p.no_stroke()
    p.fill((0, 120, 255))
    p.rect(80, 30, 60, 40)
  })
  p.shape(rec)
  p.shape(rec, x=60, y=80, scale=0.6)
}

///|
fn svg_cases() -> Map[String, (Double, Double, (@p5.P5) -> Unit)] {
  {
    "svg_export_shapes": (220, 160, svg_export_shapes),
    "svg_export_arcs": (200, 120, svg_export_arcs),
  }
}

///|
fn svg_export_shapes(p : @p5.P5) -> Unit {
  p.background(240)
  p.stroke(20)
  p.stroke_weight(3)
  p.fill((255, 120, 80))
  p.rect(10, 10, 60, 40, tl=8)
  p.ellipse(120, 30, 70, h=40)
  p.no_fill()
  p.stroke((30, 90, 200))
  p.bezier(10, 150, 40, 70, 120, 150, 150, 80)
  p.fill((80, 200, 120, 180))
  p.no_stroke()
  p.triangle(160, 150, 190, 90, 215, 150)
  p.push()
  p.translate(60, 110)
  p.rotate(0.4)
  p.fill((120, 60, 200))
  p.rect(-15, -10, 30, 20)
  p.pop()
}

///|
fn svg_export_arcs(p : @p5.P5) -> Unit {
  p.background(255)
  p.stroke(0)
  p.stroke_weight(2)
  p.fill((250, 200, 0))
  p.arc(40, 40, 60, 60, 0, @p5.HALF_PI, mode=Pie)
  p.arc(110, 40, 60, 40, 0.5, 4, mode=Chord)
  p.no_fill()
  p.arc(170, 40, 50, 50, @p5.PI, @p5.TWO_PI)
  p.begin_shape()
  p.vertex(10, 110)
  p.vertex(60, 80)
  p.vertex(110, 110)
  p.end_shape(mode=Close)
}

///|
extern "js" fn expose_svg(
  render : (String, String, (String) -> Unit) -> Bool,
) -> Unit = "(f) => { globalThis.p5mbt_svg = f; }"

///|
fn gif_frames(p : @p5.P5, img : @p5.Image) -> Unit {
  p.background(255)
  img.pause()
  p.image(img, 0, 0)
  img.set_frame(5)
  p.image(img, 100, 0)
  img.set_frame(11)
  p.image(img, 200, 0, w=48, h=36)
  p.fill(0)
  p.no_stroke()
  p.text_size(14)
  p.text("\{img.num_frames()} frames, now \{img.get_current_frame()}", 10, 110)
}

///|
fn copy_blend(p : @p5.P5) -> Unit {
  p.background(240)
  p.no_stroke()
  for i in 0..<6 {
    p.fill((i * 40, 120, 255 - i * 40))
    p.circle(15 + i.to_double() * 8, 25, 30)
  }
  p.copy(p, 0, 0, 80, 50, 100, 0, 140, 90)
  p.fill((250, 200, 0))
  p.rect(0, 100, 240, 60)
  p.blend(p, 0, 0, 80, 50, 20, 105, 80, 50, Multiply)
  p.blend(p, 0, 0, 80, 50, 130, 105, 80, 50, Difference)
}

///|
fn image_modes(p : @p5.P5) -> Unit {
  p.background(255)
  let img = p.create_image(40, 30)
  img.load_pixels()
  for y in 0..<30 {
    for x in 0..<40 {
      let i = 4 * (y * 40 + x)
      img.pixels[i] = (x * 6).to_byte()
      img.pixels[i + 1] = (y * 8).to_byte()
      img.pixels[i + 2] = 200
      img.pixels[i + 3] = 255
    }
  }
  img.update_pixels()
  p.image(img, 5, 5)
  p.image_mode(Center)
  p.image(img, 120, 40, w=80, h=60)
  p.image_mode(Corners)
  p.image(img, 170, 10, w=230, h=70)
  p.image_mode(Corner)
  p.tint((255, 120, 120))
  p.image(img, 5, 90, w=60, h=45)
  p.tint((255, 128))
  p.image(img, 80, 90, w=60, h=45)
  p.no_tint()
  p.image_region(img, 150, 90, 80, 60, 10, 5, 20, 15)
}

///|
fn gradient_scene(p : @p5.P5) -> Unit {
  p.background((30, 60, 90))
  p.no_stroke()
  for i in 0..<10 {
    p.fill((25 * i, 255 - 20 * i, 120))
    p.circle(10 + i.to_double() * 11, 45 + 25 * @cmath.sin(i.to_double()), 26)
  }
  p.fill(255)
  p.rect(80, 10, 30, 12)
}

///|
fn filtered(p : @p5.P5, f : @p5.Filter) -> Unit {
  gradient_scene(p)
  p.filter(f, use_webgl=false)
}

///|
fn filtered_gl(p : @p5.P5, f : @p5.Filter) -> Unit {
  gradient_scene(p)
  p.filter(f)
}

///|
fn basics(p : @p5.P5) -> Unit {
  p.background(220)
  p.fill((255, 0, 0))
  p.rect(20, 20, 60, 40)
  p.stroke((0, 0, 255))
  p.stroke_weight(4)
  p.fill((0, 255, 0, 128))
  p.ellipse(120, 60, 70, h=50)
  p.no_stroke()
  p.fill("#ff8800")
  p.circle(60, 110, 40)
  p.stroke(30)
  p.stroke_weight(1)
  p.no_fill()
  p.square(120, 95, 40)
}

///|
fn modes(p : @p5.P5) -> Unit {
  p.background(250)
  p.fill((100, 150, 250, 180))
  p.stroke(20)
  p.rect_mode(Center)
  p.rect(50, 40, 60, 40)
  p.rect_mode(Corners)
  p.rect(100, 20, 150, 70)
  p.rect_mode(Radius)
  p.rect(190, 45, 20, 25)
  p.ellipse_mode(Corner)
  p.ellipse(10, 90, 60, h=50)
  p.ellipse_mode(Radius)
  p.ellipse(120, 115, 30, h=20)
  p.ellipse_mode(Corners)
  p.ellipse(160, 90, 210, h=150)
}

///|
fn rounded(p : @p5.P5) -> Unit {
  p.background(240)
  p.fill((250, 200, 60))
  p.stroke(0)
  p.stroke_weight(2)
  p.rect(10, 10, 80, 50, tl=12)
  p.rect(110, 10, 80, 50, tl=5, tr=20, br=0, bl=30)
  p.rect(10, 70, 40, 40, tl=100)
  p.square(110, 70, 40, tl=8, tr=2)
}

///|
fn arcs(p : @p5.P5) -> Unit {
  p.background(230)
  p.fill((80, 160, 220))
  p.stroke(10)
  p.stroke_weight(3)
  p.arc(40, 40, 60, 60, 0, @p5.HALF_PI)
  p.arc(120, 40, 60, 60, 0, @p5.PI + @p5.QUARTER_PI, mode=Open)
  p.arc(200, 40, 60, 40, @p5.PI, @p5.TWO_PI, mode=Chord)
  p.arc(40, 120, 60, 60, -@p5.HALF_PI, @p5.PI, mode=Pie)
  p.arc(120, 120, 70, 40, 1, 5, mode=Pie)
  p.angle_mode(Degrees)
  p.arc(200, 120, 60, 60, 30, 330, mode=Pie)
}

///|
fn strokes(p : @p5.P5) -> Unit {
  p.background(255)
  p.stroke((30, 30, 120))
  p.stroke_weight(12)
  p.stroke_cap(Round)
  p.line(20, 20, 100, 20)
  p.stroke_cap(Square)
  p.line(20, 50, 100, 50)
  p.stroke_cap(Project)
  p.line(20, 80, 100, 80)
  p.no_fill()
  p.stroke_weight(10)
  p.stroke_join(Miter)
  p.triangle(130, 40, 160, 10, 190, 40)
  p.stroke_join(Bevel)
  p.triangle(130, 90, 160, 60, 190, 90)
  p.stroke_join(RoundJoin)
  p.triangle(130, 140, 160, 110, 190, 140)
  p.stroke_weight(8)
  p.point(30, 130)
  p.stroke_weight(20)
  p.point(70, 130)
  p.stroke_weight(0.5)
  p.line(210, 10, 230, 150)
}

///|
fn polygons(p : @p5.P5) -> Unit {
  p.background(245)
  p.stroke(0)
  p.fill((200, 100, 160))
  p.triangle(10, 100, 50, 10, 90, 100)
  p.quad(110, 20, 200, 10, 210, 100, 120, 90)
}

///|
fn curves(p : @p5.P5) -> Unit {
  p.background(250)
  p.no_fill()
  p.stroke_weight(3)
  p.stroke((200, 0, 0))
  p.bezier(10, 140, 40, 10, 120, 10, 150, 140)
  p.stroke((0, 120, 0))
  p.spline(20, 20, 60, 120, 140, 30, 230, 150)
  p.spline_tightness(0.5)
  p.stroke((0, 0, 200))
  p.spline(20, 60, 80, 150, 160, 60, 230, 100)
  p.spline_tightness(0)
  p.spline_ends(Exclude)
  p.stroke((120, 0, 120))
  p.begin_shape()
  for pt in [(0.0, 80.0), (40, 40), (100, 90), (160, 30), (220, 90), (240, 40)] {
    p.spline_vertex(pt.0, pt.1)
  }
  p.end_shape()
}

///|
fn shape_kinds(p : @p5.P5) -> Unit {
  p.background(240)
  p.stroke(0)
  p.fill((120, 180, 240, 200))
  let pts : Array[(Double, Double)] = [
    (10, 10),
    (40, 40),
    (70, 10),
    (100, 40),
    (130, 10),
    (160, 40),
  ]
  p.begin_shape(kind=Points)
  p.stroke_weight(6)
  for pt in pts {
    p.vertex(pt.0, pt.1)
  }
  p.end_shape()
  p.stroke_weight(1)
  p.begin_shape(kind=Lines)
  for pt in pts {
    p.vertex(pt.0, pt.1 + 50)
  }
  p.end_shape()
  p.begin_shape(kind=Triangles)
  for pt in pts {
    p.vertex(pt.0, pt.1 + 100)
  }
  p.end_shape()
  p.begin_shape(kind=TriangleStrip)
  for pt in pts {
    p.vertex(pt.0 + 140, pt.1 + 100)
  }
  p.end_shape()
  p.begin_shape(kind=TriangleFan)
  p.vertex(230, 40)
  for i in 0..<6 {
    let a = i.to_double()
    p.vertex(230 + 40 * @cmath.cos(a), 40 + 40 * @cmath.sin(a))
  }
  p.end_shape()
  p.begin_shape(kind=Quads)
  p.vertex(180, 150)
  p.vertex(210, 150)
  p.vertex(210, 190)
  p.vertex(180, 190)
  p.end_shape()
  p.begin_shape(kind=QuadStrip)
  for i in 0..<4 {
    p.vertex(220 + i.to_double() * 25, 150)
    p.vertex(220 + i.to_double() * 25, 190)
  }
  p.end_shape()
}

///|
fn contours(p : @p5.P5) -> Unit {
  p.background(255)
  p.fill((250, 180, 40))
  p.stroke(0)
  p.stroke_weight(2)
  p.begin_shape()
  p.vertex(20, 20)
  p.vertex(200, 20)
  p.vertex(200, 140)
  p.vertex(20, 140)
  p.begin_contour()
  p.vertex(60, 60)
  p.vertex(60, 100)
  p.vertex(160, 100)
  p.vertex(160, 60)
  p.end_contour(mode=Close)
  p.end_shape(mode=Close)
  p.bezier_order(2)
  p.begin_shape()
  p.vertex(20, 150)
  p.bezier_vertex(110, 100)
  p.bezier_vertex(200, 150)
  p.end_shape()
}

///|
fn transforms(p : @p5.P5) -> Unit {
  p.background(230)
  p.fill((255, 100, 100))
  p.stroke(0)
  p.push()
  p.translate(60, 60)
  p.rotate(@p5.QUARTER_PI)
  p.rect(-20, -20, 40, 40)
  p.pop()
  p.push()
  p.translate(160, 60)
  p.scale(1.5, y=0.7)
  p.ellipse(0, 0, 50, h=50)
  p.pop()
  p.push()
  p.translate(60, 160)
  p.shear_x(0.4)
  p.rect(-20, -20, 40, 40)
  p.pop()
  p.push()
  p.translate(160, 160)
  p.apply_matrix(1, 0.3, -0.2, 1, 0, 0)
  p.shear_y(0.2)
  p.triangle(-30, 30, 0, -30, 30, 30)
  p.pop()
  p.rect(5, 5, 10, 10)
}

///|
fn color_modes(p : @p5.P5) -> Unit {
  p.background(255)
  p.no_stroke()
  p.color_mode(HSB)
  for i in 0..<12 {
    p.fill((i * 30, 80, 90))
    p.rect(i.to_double() * 20 + 10, 10, 20, 25)
  }
  p.color_mode(HSL)
  for i in 0..<12 {
    p.fill((i * 30, 70, 50))
    p.rect(i.to_double() * 20 + 10, 40, 20, 25)
  }
  p.color_mode_max(RGB, 1)
  p.fill((0.2, 0.6, 0.4, 0.5))
  p.rect(10, 75, 60, 35)
  p.color_mode_max(HSB, 100)
  p.fill((70, 100, 100))
  p.rect(80, 75, 60, 35)
  p.color_mode(RGB)
  p.fill(p.lerp_color(p.color((255, 0, 0)), p.color((0, 0, 255)), 0.3))
  p.rect(150, 75, 50, 35)
  p.fill("hsl(160, 80%, 40%)")
  p.rect(205, 75, 45, 35)
}

///|
fn blend_erase(p : @p5.P5) -> Unit {
  p.background((40, 80, 160))
  p.no_stroke()
  p.fill((255, 0, 0))
  p.circle(60, 60, 80)
  p.blend_mode(Add)
  p.fill((0, 200, 0))
  p.circle(100, 60, 80)
  p.blend_mode(Multiply)
  p.fill((250, 250, 0))
  p.circle(140, 60, 80)
  p.blend_mode(Blend)
  p.erase()
  p.rect(80, 90, 60, 20)
  p.no_erase()
}

///|
fn clipping(p : @p5.P5) -> Unit {
  p.background(255)
  p.no_stroke()
  p.push()
  p.clip(() => p.circle(60, 70, 100))
  for i in 0..<12 {
    p.fill((if i % 2 == 1 { 200 } else { 60 }, 100, 160))
    p.rect(i.to_double() * 10, 0, 10, 140)
  }
  p.pop()
  p.push()
  p.clip(() => p.rect(130, 30, 50, 80), invert=true)
  p.fill((250, 120, 0))
  p.circle(155, 70, 70)
  p.pop()
}

///|
fn text_basic(p : @p5.P5) -> Unit {
  p.background(250)
  p.fill(20)
  p.text_size(20)
  p.text("Hello p5", 10, 30)
  p.text_style(Bold)
  p.text_font("Georgia")
  p.text("Bold Georgia", 10, 60)
  p.text_style(Italic)
  p.text_size(16)
  p.text("italic 16px", 10, 85)
  p.text_style(Normal)
  p.text_font("monospace")
  p.text_size(14)
  p.text("multi\nline text", 10, 110)
  p.fill((200, 0, 0))
  p.stroke((0, 0, 255))
  p.stroke_weight(1)
  p.text_size(28)
  p.text("Stroke", 150, 40)
}

///|
fn text_align(p : @p5.P5) -> Unit {
  p.background(255)
  p.stroke(200)
  p.line(130, 0, 130, 200)
  p.line(0, 50, 260, 50)
  p.line(0, 120, 260, 120)
  p.no_stroke()
  p.fill(0)
  p.text_size(18)
  p.text_align(Left, vertical=Top)
  p.text("left top", 130, 50)
  p.text_align(Right, vertical=Bottom)
  p.text("right bottom", 130, 50)
  p.text_align(HCenter, vertical=VCenter)
  p.text("center\ncenter", 130, 120)
  p.text_align(Left, vertical=Baseline)
  p.text("baseline", 10, 180)
  p.text_align(Right, vertical=VCenter)
  p.text("right", 250, 180)
}

///|
fn text_box(p : @p5.P5) -> Unit {
  p.background(255)
  p.no_fill()
  p.stroke(180)
  p.rect(20, 20, 140, 90)
  p.rect(170, 20, 80, 160)
  p.no_stroke()
  p.fill(0)
  p.text_size(15)
  p.text_leading(19)
  p.text(
    "The quick brown fox jumps over the lazy dog again and again",
    20,
    20,
    max_width=140,
    max_height=90,
  )
  p.text_align(HCenter, vertical=VCenter)
  p.text_wrap(Char)
  p.text("characterwrappingdemo text", 170, 20, max_width=80, max_height=160)
  p.text_align(Right, vertical=Bottom)
  p.text_wrap(Word)
  p.rect_mode(Center)
  p.text("right bottom box", 90, 160, max_width=140, max_height=60)
}

///|
fn text_metrics(p : @p5.P5) -> Unit {
  p.background(255)
  p.text_size(22)
  p.fill(0)
  p.no_stroke()
  let s = "Measure gyp"
  p.text(s, 20, 50)
  let b = p.text_bounds(s, 20, 50)
  p.no_fill()
  p.stroke((255, 0, 0))
  p.rect(b.x, b.y, b.w, b.h)
  let f = p.font_bounds(s, 20, 90)
  p.stroke((0, 0, 255))
  p.rect(f.x, f.y, f.w, f.h)
  p.stroke((0, 150, 0))
  p.line(20, 100, 20 + p.text_width(s), 100)
  p.line(20, 106, 20 + p.font_width(s), 106)
  p.line(250, 50 - p.text_ascent(), 250, 50 + p.text_descent())
  p.line(260, 50 - p.text_ascent(s="gyp"), 260, 50 + p.text_descent(s="gyp"))
}

///|
fn random_noise(p : @p5.P5) -> Unit {
  p.background(20)
  p.random_seed(42)
  p.noise_seed(7)
  p.no_stroke()
  for _ in 0..<300 {
    p.fill((p.random_max(255), p.random_range(100, 255), 200))
    p.circle(p.random_max(200), p.random_max(200), p.random_range(2, 8))
  }
  p.stroke((255, 200, 0))
  p.no_fill()
  p.begin_shape()
  let mut x = 0
  while x <= 200 {
    p.vertex(x.to_double(), 100 + 80 * (p.noise(x.to_double() * 0.02) - 0.5))
    x += 4
  }
  p.end_shape()
  p.stroke((0, 220, 255))
  for _ in 0..<40 {
    p.point(100 + p.random_gaussian(sd=30), 160 + p.random_gaussian(sd=10))
  }
}

///|
fn vectors_trig(p : @p5.P5) -> Unit {
  p.background(250)
  p.angle_mode(Degrees)
  p.stroke(0)
  p.no_fill()
  let mut a = 0
  while a < 360 {
    let v = @p5.Vector::from_angle(
      @p5.radians(a.to_double()),
      length=60 + 20 * p.sin(a.to_double() * 3),
    )
    p.line(100, 100, 100 + v.x, 100 + v.y)
    a += 15
  }
  let w = p.create_vector(30, 40)
  w.set_mag(70)
  w.rotate(20)
  p.stroke((255, 0, 0))
  p.stroke_weight(3)
  p.line(100, 100, 100 + w.x, 100 + w.y)
  p.text(@p5.nf(p.atan2(1, 1), left=2, right=2), 10, 190)
}

///|
fn pixels(p : @p5.P5) -> Unit {
  p.background((255, 0, 0))
  p.load_pixels()
  let d = p.get_pixel_density().to_int()
  let w = p.width.to_int() * d
  for y in 0..<(p.height.to_int() * d) {
    for x in 0..<w {
      let i = 4 * (y * w + x)
      p.pixels[i] = (x * 2).to_byte()
      p.pixels[i + 1] = (y * 3).to_byte()
      p.pixels[i + 2] = 128
      p.pixels[i + 3] = 255
    }
  }
  p.update_pixels()
  p.set(10, 10, p.color(255))
  p.set(11, 10, p.color(255))
  p.update_pixels()
  let c = p.get(50, 40)
  p.fill(c)
  p.no_stroke()
  p.rect(60, 50, 30, 20)
}

///|
extern "js" fn expose(render : (String, String, () -> Unit) -> Bool) -> Unit = "(f) => { globalThis.p5mbt_render = f; }"

///|
fn main {
  let svgs = svg_cases()
  expose_svg((name, container, done) => {
    guard svgs.get(name) is Some((w, h, scene)) else { return false }
    @p5.run(container~, seed=1, setup=p => {
      p.create_canvas(w, h)
      p.pixel_density(1)
      p.no_loop()
      done(p.get_svg(p.build_shape(() => scene(p))))
    })
    true
  })
  let datas = data_cases()
  expose_data((name, container, done) => {
    guard datas.get(name) is Some((file, compute)) else { return false }
    let font : Ref[@p5.Font?] = Ref(None)
    @p5.run(
      container~,
      seed=1,
      preload=p => font.val = Some(p.load_font("../examples/assets/" + file)),
      setup=p => {
        p.create_canvas(100, 100)
        p.pixel_density(1)
        p.no_loop()
        if font.val is Some(f) {
          done(compute(p, f))
        }
      },
    )
    true
  })
  let all = cases()
  expose((name, container, done) => {
    guard all.get(name) is Some(c) else { return false }
    @p5.run(
      container~,
      seed=1,
      preload?=c.preload,
      setup=p => {
        p.pixel_density(1)
        p.create_canvas(c.w, c.h, renderer=if c.webgl { WebGL } else { P2D })
        p.no_loop()
      },
      draw=p => {
        (c.draw)(p)
        done()
      },
    )
    true
  })
}

///|
extern "js" fn js_cos(x : Double) -> Double = "Math.cos"

///|
extern "js" fn js_sin(x : Double) -> Double = "Math.sin"
