///|
fn sketch() -> (@p5.P5, @p5.Recorder) {
  let rec = @p5.Recorder::new()
  let p = @p5.P5::headless(rec, 100, 100)
  ignore(rec.take())
  (p, rec)
}

///|
test "default style: white fill, black 1px stroke" {
  let (p, rec) = sketch()
  p.rect(10, 20, 30, 40)
  inspect(
    rec.take().join("\n"),
    content=(
      #|transform 1 0 0 1 0 0
      #|fill #ffffff R10,20,30,40
      #|stroke #000000 w=1 round/miter R10,20,30,40
    ),
  )
}

///|
test "color arguments" {
  let (p, rec) = sketch()
  p.no_stroke()
  p.fill(128)
  p.circle(50, 50, 20)
  p.fill((255, 0, 0, 127))
  p.ellipse(50, 50, 20, h=10)
  p.fill((0.5, 1, 1.0))
  p.color_mode(HSB)
  p.fill((120, 100, 100))
  p.square(0, 0, 5)
  p.fill("steelblue")
  p.triangle(0, 0, 10, 0, 0, 10)
  inspect(
    rec.take().join("\n"),
    content=(
      #|transform 1 0 0 1 0 0
      #|fill #808080 M60,50 E50,50,10,10,0,6.283
      #|transform 1 0 0 1 0 0
      #|fill #ff00007f M60,50 E50,50,10,5,0,6.283
      #|transform 1 0 0 1 0 0
      #|fill rgb(0% 100% 0%) R0,0,5,5
      #|transform 1 0 0 1 0 0
      #|fill #4682b4 M0,0 L10,0 L0,10 Z
    ),
  )
}

///|
test "modes, transforms and push/pop" {
  let (p, rec) = sketch()
  p.no_fill()
  p.rect_mode(Center)
  p.push()
  p.translate(50, 50)
  p.rotate(@p5.HALF_PI)
  p.scale(2)
  p.stroke_weight(4)
  p.stroke_cap(Square)
  p.rect(0, 0, 10, 20)
  p.pop()
  p.angle_mode(Degrees)
  p.ellipse_mode(Corner)
  p.arc(0, 0, 20, 20, 0, 90, mode=Pie)
  inspect(
    rec.take().join("\n"),
    content=(
      #|save
      #|transform 0 2 -2 0 50 50
      #|stroke #000000 w=4 butt/miter R-5,-10,10,20
      #|restore
      #|blend source-over
      #|smoothing true
      #|transform 1 0 0 1 0 0
      #|stroke #000000 w=1 round/miter M20,10 E10,10,10,10,0,1.571 L10,10 Z
    ),
  )
}

///|
test "rounded rect, lines, points and custom shapes" {
  let (p, rec) = sketch()
  p.rect(0, 0, 10, 10, tl=2)
  p.line(0, 0, 5, 5)
  p.stroke_weight(10)
  p.point(3, 4)
  p.no_stroke()
  p.point(3, 4) // invisible without a stroke
  p.begin_shape()
  p.vertex(0, 0)
  p.bezier_vertex(10, 0)
  p.bezier_vertex(10, 10)
  p.bezier_vertex(0, 10)
  p.end_shape(mode=Close)
  inspect(
    rec.take().join("\n"),
    content=(
      #|transform 1 0 0 1 0 0
      #|fill #ffffff RR0,0,10,10,2,2,2,2
      #|stroke #000000 w=1 round/miter RR0,0,10,10,2,2,2,2
      #|transform 1 0 0 1 0 0
      #|stroke #000000 w=1 round/miter M0,0 L5,5
      #|transform 1 0 0 1 0 0
      #|stroke #000000 w=10 round/miter M3,4 L3,4
      #|transform 1 0 0 1 0 0
      #|fill #ffffff M0,0 C10,0,10,10,0,10 Z
    ),
  )
}

///|
test "background ignores transforms; pixel density scales" {
  let rec = @p5.Recorder::new()
  let p = @p5.P5::headless(rec, 100, 50, pixel_density=2)
  ignore(rec.take())
  p.translate(10, 10)
  p.background(220)
  p.clear()
  p.no_stroke()
  p.rect(0, 0, 1, 1)
  inspect(
    rec.take().join("\n"),
    content=(
      #|save
      #|transform 2 0 0 2 0 0
      #|fill_rect #dcdcdc 0,0,100,50
      #|restore
      #|save
      #|transform 1 0 0 1 0 0
      #|clear_rect 0,0,200,100
      #|restore
      #|transform 2 0 0 2 20 20
      #|fill #ffffff R0,0,1,1
    ),
  )
}

///|
test "clipping" {
  let (p, rec) = sketch()
  p.push()
  p.clip(() => {
    p.translate(10, 0)
    p.rect(0, 0, 20, 20)
  })
  p.no_stroke()
  p.circle(0, 0, 10)
  p.pop()
  inspect(
    rec.take().join("\n"),
    content=(
      #|save
      #|clip base=1 0 0 1 0 0 [1 0 0 1 10 0] R0,0,20,20
      #|transform 1 0 0 1 10 0
      #|fill #ffffff M5,0 E0,0,5,5,0,6.283
      #|restore
      #|blend source-over
      #|smoothing true
    ),
  )
}

///|
test "draw loop resets the matrix and counts frames" {
  let (p, rec) = sketch()
  p.set_draw(p => {
    p.translate(5, 0)
    p.no_stroke()
    p.point(0, 0)
    p.stroke(0)
    p.point(p.frame_count.to_double(), 0)
  })
  p.redraw(n=2)
  inspect(p.frame_count, content="2")
  inspect(
    rec.take().join("\n"),
    content=(
      #|save
      #|transform 1 0 0 1 5 0
      #|stroke #000000 w=1 round/miter M1,0 L1,0
      #|restore
      #|blend source-over
      #|smoothing true
      #|save
      #|transform 1 0 0 1 5 0
      #|stroke #000000 w=1 round/miter M2,0 L2,0
      #|restore
      #|blend source-over
      #|smoothing true
    ),
  )
}

///|
test "color readers follow the color mode" {
  let (p, _) = sketch()
  let c = p.color((255, 128, 0))
  inspect(p.red(c), content="255")
  inspect(@p5.round(p.hue(c)), content="30")
  p.color_mode_max(RGB, 1)
  inspect(@p5.round(p.green(c), decimals=2), content="0.5")
  let mixed = p.lerp_color(p.color((1, 0, 0)), p.color((0, 0, 1)), 0.5)
  inspect(mixed.to_css(), content="#7f007f")
}

///|
test "random and noise are seedable" {
  let (p, _) = sketch()
  p.random_seed(99)
  inspect(p.random(), content="0.27443566313013434")
  p.noise_seed(42)
  inspect(p.noise(0.5), content="0.2027877284999704")
  p.angle_mode(Degrees)
  inspect(@p5.round(p.sin(90)), content="1")
  inspect(p.atan2(1, 0), content="90")
}

///|
test "vectors from create_vector follow the angle mode, like p5.js" {
  let (p, _) = sketch()
  let v = p.create_vector(1, 0)
  p.angle_mode(Degrees)
  v.rotate(90)
  inspect(@p5.round(v.heading()), content="90")
  p.angle_mode(Radians)
  inspect(@p5.round(v.heading(), decimals=4), content="1.5708")
  // plain vectors always use radians
  let w = @p5.Vector(0, 1)
  p.angle_mode(Degrees)
  inspect(@p5.round(w.heading(), decimals=4), content="1.5708")
  // push/pop do not save the angle mode
  p.push()
  p.angle_mode(Radians)
  p.pop()
  debug_inspect(p.get_angle_mode(), content="Radians")
}
