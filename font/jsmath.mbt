// The JS backend uses the engine's own Math functions so sampled points
// match p5.js bit for bit; other backends use moonbitlang/core/math.

///|
#cfg(target="js")
extern "js" fn hypot(x : Double, y : Double) -> Double =
  #|(x, y) => Math.hypot(x, y)

///|
#cfg(target="js")
extern "js" fn pow(x : Double, y : Double) -> Double =
  #|(x, y) => Math.pow(x, y)

///|
#cfg(target="js")
extern "js" fn atan2(y : Double, x : Double) -> Double =
  #|(y, x) => Math.atan2(y, x)

///|
#cfg(target="js")
extern "js" fn acos(x : Double) -> Double =
  #|(x) => Math.acos(x)

///|
#cfg(not(target="js"))
fn hypot(x : Double, y : Double) -> Double {
  @cmath.hypot(x, y)
}

///|
#cfg(not(target="js"))
fn pow(x : Double, y : Double) -> Double {
  @cmath.pow(x, y)
}

///|
#cfg(not(target="js"))
fn atan2(y : Double, x : Double) -> Double {
  @cmath.atan2(y, x)
}

///|
#cfg(not(target="js"))
fn acos(x : Double) -> Double {
  @cmath.acos(x)
}
