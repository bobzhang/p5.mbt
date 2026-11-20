// An orrery in WEBGL: an emissive sun lighting procedurally textured
// planets, a starfield, labels drawn with the font shader, and
// orbit_control().

///|
struct Planet {
  name : String
  radius : Double
  distance : Double
  speed : Double
  tilt : Double
  texture : @p5.Image
  ring : Bool
}

///|
/// A planet texture: banded noise in the planet's palette.
fn planet_texture(
  p : @p5.P5,
  seed : Double,
  base : (Double, Double, Double),
  band : (Double, Double, Double),
) -> @p5.Image {
  let img = p.create_image(128, 64)
  img.load_pixels()
  p.noise_seed(seed)
  for y in 0..<64 {
    for x in 0..<128 {
      let u = x.to_double() / 128.0
      let v = y.to_double() / 64.0
      let n = p.noise(
        p.cos(u * @p5.TWO_PI) * 1.5 + 5,
        y=p.sin(u * @p5.TWO_PI) * 1.5 + 5,
        z=v * 6,
      )
      let t = (n * 1.6 + p.sin(v * 18 + n * 6) * 0.25).clamp(min=0, max=1)
      let i = 4 * (y * 128 + x)
      img.pixels[i] = (base.0 + (band.0 - base.0) * t).to_int().to_byte()
      img.pixels[i + 1] = (base.1 + (band.1 - base.1) * t).to_int().to_byte()
      img.pixels[i + 2] = (base.2 + (band.2 - base.2) * t).to_int().to_byte()
      img.pixels[i + 3] = 255
    }
  }
  img.update_pixels()
  img
}

///|
fn main {
  let planets : Array[Planet] = []
  let stars : Array[(Double, Double, Double)] = []
  let font : Ref[@p5.Font?] = Ref(None)
  @p5.run(
    preload=p => {
      font.val = Some(p.load_font("../assets/SourceSansPro-Regular.otf"))
    },
    setup=p => {
      p.create_canvas(720, 480, renderer=WebGL)
      let specs = [
        (
          "Mercury",
          7.0,
          90.0,
          1.6,
          0.0,
          (120.0, 110.0, 100.0),
          (200.0, 190.0, 170.0),
          false,
        ),
        (
          "Venus",
          11.0,
          125.0,
          1.2,
          0.05,
          (200.0, 150.0, 80.0),
          (250.0, 220.0, 160.0),
          false,
        ),
        (
          "Earth",
          12.0,
          165.0,
          1.0,
          0.4,
          (30.0, 70.0, 160.0),
          (70.0, 160.0, 90.0),
          false,
        ),
        (
          "Mars",
          9.0,
          205.0,
          0.8,
          0.44,
          (150.0, 60.0, 30.0),
          (230.0, 140.0, 90.0),
          false,
        ),
        (
          "Saturn",
          22.0,
          275.0,
          0.45,
          0.47,
          (190.0, 160.0, 110.0),
          (240.0, 220.0, 170.0),
          true,
        ),
      ]
      for i, s in specs {
        let (name, radius, distance, speed, tilt, base, band, ring) = s
        planets.push({
          name,
          radius,
          distance,
          speed,
          tilt,
          texture: planet_texture(p, i.to_double() * 7 + 1, base, band),
          ring,
        })
      }
      for _ in 0..<400 {
        let v = p.random3d()
        let r = p.random_range(900, 1400)
        stars.push((v.x * r, v.y * r, v.z * r))
      }
      p.camera(eye=(0, -260, 520), center=(0, 0, 0), up=(0, 1, 0))
      p.perspective(far=4000)
    },
    draw=p => {
      p.background((6, 8, 18))
      p.orbit_control()
      let t = p.frame_count.to_double() / 60.0
      // stars
      p.stroke((255, 255, 255, 180))
      p.stroke_weight(2)
      for s in stars {
        p.point(s.0, s.1, z=s.2)
      }
      // the sun lights everything; it glows by itself
      p.no_stroke()
      p.ambient_light(28)
      p.point_light((255, 240, 210), 0, 0, 0)
      p.push()
      p.emissive_material((255, 190, 60))
      p.fill((255, 200, 80))
      p.rotate_y(t * 0.2)
      p.sphere(r=48, detail_x=32, detail_y=24)
      p.pop()
      for i, pl in planets {
        let a = t * pl.speed * 0.5 + i.to_double() * 1.3
        // orbit path
        p.push()
        p.rotate_x(@p5.HALF_PI)
        p.no_fill()
        p.stroke((255, 255, 255, 40))
        p.stroke_weight(1)
        p.circle(0, 0, pl.distance * 2)
        p.pop()
        p.push()
        p.translate(p.cos(a) * pl.distance, 0, z=p.sin(a) * pl.distance)
        p.rotate_z(pl.tilt)
        p.push()
        p.rotate_y(t * 1.5)
        p.no_stroke()
        p.texture(pl.texture)
        p.shininess(10)
        p.specular_material(60)
        p.sphere(r=pl.radius, detail_x=32, detail_y=20)
        p.pop()
        if pl.ring {
          p.push()
          p.rotate_x(@p5.HALF_PI)
          p.fill((210, 190, 150, 170))
          p.torus(
            r=pl.radius * 1.7,
            tube=pl.radius * 0.25,
            detail_x=40,
            detail_y=6,
          )
          p.pop()
        }
        p.pop()
        // label, facing the viewer's plane
        if font.val is Some(f) {
          p.push()
          p.translate(
            p.cos(a) * pl.distance,
            -pl.radius - 10,
            z=p.sin(a) * pl.distance,
          )
          p.text_font_face(f, size=13)
          p.text_align(HCenter, vertical=Bottom)
          p.fill((230, 235, 255))
          p.text(pl.name, 0, 0)
          p.pop()
        }
      }
    },
  )
}
