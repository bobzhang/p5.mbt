// The engine's own Math functions, so results match p5.js exactly.

///|
extern "js" fn js_round(x : Double) -> Double = "Math.round"

///|
extern "js" fn js_num(x : Double) -> String = "String"

///|
extern "js" fn js_asin(x : Double) -> Double = "Math.asin"

///|
extern "js" fn js_sin(x : Double) -> Double = "Math.sin"

///|
extern "js" fn js_cos(x : Double) -> Double = "Math.cos"

///|
extern "js" fn js_tan(x : Double) -> Double = "Math.tan"

///|
extern "js" fn js_atan(x : Double) -> Double = "Math.atan"

///|
extern "js" fn js_atan2(y : Double, x : Double) -> Double = "Math.atan2"

///|
/// `Number.prototype.toPrecision(4)` parsed back to a number.
extern "js" fn to_precision4(x : Double) -> Double = "(x) => +x.toPrecision(4)"
