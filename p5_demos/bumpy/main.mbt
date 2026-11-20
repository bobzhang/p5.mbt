// Texture maps: a planet whose surface relief comes from a bump map (noise
// painted into a graphics buffer, brightness as height), and a wall of
// tiles whose bevels come from a normal map, both under a moving light.

///|
fn paint_terrain(g : @p5.P5) -> Unit {
  g.load_pixels()
  let w = g.width.to_int()
  let h = g.height.to_int()
  g.noise_detail(6, falloff=0.55)
  for y in 0..<h {
    for x in 0..<w {
      // sample noise on a cylinder so the map wraps around the sphere
      let a = x.to_double() / w.to_double() * @p5.TWO_PI
      let n = g.noise(
        2 + g.cos(a) * 1.6,
        y=2 + g.sin(a) * 1.6,
        z=y.to_double() / h.to_double() * 3.2,
      )
      let v = (n * 255).floor().to_int().to_byte()
      let i = (y * w + x) * 4
      g.pixels[i] = v
      g.pixels[i + 1] = v
      g.pixels[i + 2] = v
      g.pixels[i + 3] = b'\xFF'
    }
  }
  g.update_pixels()
}

///|
/// A tangent-space normal map of beveled square tiles.
fn paint_tiles(g : @p5.P5) -> Unit {
  let s = g.width
  let tiles = 4.0
  let cell = s / tiles
  let bevel = cell * 0.18
  g.no_stroke()
  g.background((128, 128, 255))
  for i in 0..<tiles.to_int() {
    for j in 0..<tiles.to_int() {
      let x = i.to_double() * cell
      let y = j.to_double() * cell
      // left, right, top, bottom bevels tilt the normal toward each edge
      g.fill((40, 128, 220))
      g.quad(
        x,
        y,
        x + bevel,
        y + bevel,
        x + bevel,
        y + cell - bevel,
        x,
        y + cell,
      )
      g.fill((216, 128, 220))
      g.quad(
        x + cell,
        y,
        x + cell,
        y + cell,
        x + cell - bevel,
        y + cell - bevel,
        x + cell - bevel,
        y + bevel,
      )
      g.fill((128, 216, 220))
      g.quad(
        x,
        y,
        x + cell,
        y,
        x + cell - bevel,
        y + bevel,
        x + bevel,
        y + bevel,
      )
      g.fill((128, 40, 220))
      g.quad(
        x,
        y + cell,
        x + bevel,
        y + cell - bevel,
        x + cell - bevel,
        y + cell - bevel,
        x + cell,
        y + cell,
      )
    }
  }
}

///|
fn main {
  let bump : Ref[@p5.P5?] = Ref(None)
  let tiles : Ref[@p5.P5?] = Ref(None)
  @p5.run(
    setup=p => {
      p.create_canvas(820, 560, renderer=WebGL)
      p.pixel_density(1)
      let b = p.create_graphics(512, 256)
      b.pixel_density(1)
      paint_terrain(b)
      bump.val = Some(b)
      let t = p.create_graphics(256, 256)
      t.pixel_density(1)
      paint_tiles(t)
      tiles.val = Some(t)
    },
    draw=p => {
      guard bump.val is Some(b) && tiles.val is Some(t) else { return }
      p.background((6, 8, 14))
      p.orbit_control()
      let time = p.millis() / 1000
      p.ambient_light((45, 45, 60))
      p.point_light(
        (255, 240, 220),
        p.cos(time * 0.7) * 500,
        -150,
        p.sin(time * 0.7) * 500,
      )
      p.no_stroke()
      // the tiled wall behind
      p.push()
      p.translate(0, 0, z=-260)
      p.fill((150, 140, 130))
      p.specular_material((90, 90, 90))
      p.shininess(30)
      p.normal_texture(Some(t), scale=1.2)
      p.plane(w=900, h=700)
      p.pop()
      // the planet
      p.push()
      p.rotate_y(time * 0.25)
      p.fill((120, 160, 210))
      p.specular_material((40, 40, 50))
      p.shininess(8)
      p.bump_texture(Some(b), scale=14)
      p.sphere(r=170, detail_x=96, detail_y=64)
      p.pop()
    },
  )
}
