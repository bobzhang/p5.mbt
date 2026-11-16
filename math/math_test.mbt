// Reference values were produced by running the original p5.js 2.4
// src/math/{random,noise}.js under Node.

///|
test "random matches p5.js randomSeed(99)" {
  let r = @math.Random::new(99)
  inspect(r.next(), content="0.27443566313013434")
  inspect(r.next(), content="0.2582396597135812")
  inspect(r.range(10, 20), content="16.056527215987444")
  inspect(r.below(5), content="1.6624356142710894")
}

///|
test "randomGaussian matches p5.js randomSeed(42)" {
  let r = @math.Random::new(42)
  inspect(r.gaussian(), content="-0.20503260439968146")
  inspect(r.gaussian(), content="-0.34098990218589886")
  inspect(r.gaussian(mean=50, sd=10), content="53.98583829711966")
}

///|
test "noise matches p5.js noiseSeed(42)" {
  let n = @math.Noise::new(42)
  inspect(n.noise(0.5), content="0.2027877284999704")
  inspect(n.noise(0.5, y=0.25), content="0.39451964056898436")
  inspect(n.noise(1.7, y=2.3, z=3.1), content="0.47469508278664296")
  inspect(n.noise(-12.3, y=100.5), content="0.4662833357477367")
  n.detail(8, falloff=0.65)
  inspect(n.noise(0.5, y=0.25), content="0.6541087869738567")
  inspect(n.noise(10.1, y=3.3, z=0.2), content="0.8869463591055458")
}

///|
test "to_uint32 follows JavaScript >>> 0" {
  inspect(@math.to_uint32(-1), content="4294967295")
  inspect(@math.to_uint32(4294967297.7), content="1")
  inspect(@math.to_uint32(12.9), content="12")
}

///|
test "calculation helpers" {
  inspect(@math.map(0.5, 0, 1, 10, 20), content="15")
  inspect(@math.map(-1, 0, 1, 20, 10, within_bounds=true), content="20")
  inspect(@math.norm(25, 0, 100), content="0.25")
  inspect(@math.lerp(0, 10, 0.25), content="2.5")
  inspect(@math.dist(0, 0, 3, 4), content="5")
  inspect(@math.dist3(0, 0, 0, 1, 2, 2), content="3")
  inspect(@math.fract(-1.25), content="0.75")
  inspect(@math.max_of([1, 5, 3]), content="5")
  inspect(@math.min_of([4, -2, 3]), content="-2")
  inspect(@math.degrees(@math.PI), content="180")
}

///|
test "vector arithmetic" {
  let v = @math.Vector(1, 2, z=3)
  v.add(@math.Vector(1, 1, z=1))
  inspect(v, content="vector[2, 3, 4]")
  v.mult(2)
  inspect(v, content="vector[4, 6, 8]")
  v.div(0) // ignored, like p5.js
  inspect(v, content="vector[4, 6, 8]")
  let w = @math.Vector(3, 4)
  w.set_mag(10)
  inspect(
    w,
    content=(
      #|vector[6.000000000000001, 8, 0]
    ),
  )
  w.limit(5)
  inspect(
    w,
    content=(
      #|vector[3.0000000000000004, 4, 0]
    ),
  )
  inspect(
    @math.Vector(1, 0).cross(@math.Vector(0, 1)),
    content="vector[0, 0, 1]",
  )
  inspect(@math.Vector(1, 0) + @math.Vector(0, 2), content="vector[1, 2, 0]")
  inspect(-@math.Vector(1, 2), content="vector[-1, -2, 0]")
  let r = @math.Vector(5, -5)
  r.rem(3)
  inspect(r, content="vector[2, -2, 0]")
}

///|
test "vector angles" {
  let v = @math.Vector(1, 0)
  v.rotate(@math.HALF_PI)
  v.clamp_to_zero()
  inspect(v.x.abs() < 1.0e-12, content="true")
  inspect(v.y, content="1")
  let a = @math.Vector(1, 0).angle_between(@math.Vector(0, 1))
  inspect(a == @math.HALF_PI, content="true")
  let b = @math.Vector(0, 1).angle_between(@math.Vector(1, 0))
  inspect(b == -@math.HALF_PI, content="true")
  let i = @math.Vector(1, -1)
  i.reflect(@math.Vector(0, 1))
  inspect(i.y > 0.99999, content="true")
}

///|
test "matrix2d" {
  let m = @math.identity.translate(10, 20).scale(2, 2)
  debug_inspect(m.apply(1, 1), content="(12, 22)")
  let inv = m.invert().unwrap()
  debug_inspect(inv.apply(12, 22), content="(1, 1)")
}
