// Every MoonBit snippet the film shows, exactly as it appears on screen.

// FORTRAN: compiles fast, runs fast

///|
fn sum_squares(n : Int32) -> Int32 {
  let mut s = 0
  for i in 1..<=n {
    s += i * i
  }
  s
}

// LISP: closures and garbage collection

///|
fn adder(n : Int32) -> (Int32) -> Int32 {
  x => x + n
}

///|
test {
  let add2 = adder(2)
  assert_eq([1, 2, 3].map(add2), [3, 4, 5])
}

// C: close to the machine

///|
fn checksum(data : Bytes) -> Int32 {
  let mut sum = 0
  for b in data {
    sum = (sum + b.to_int()) & 0xFFFF
  }
  sum
}

// ML: types inferred, data matched

///|
enum Shape {
  Circle(Double)
  Rect(Double, Double)
}

///|
fn area(s : Shape) -> Double {
  match s {
    Circle(r) => 3.14 * r * r
    Rect(w, h) => w * h
  }
}

// Rust: no null

///|
fn find(xs : Array[Int32], x : Int32) -> Int32? {
  for i, v in xs {
    if v == x {
      return Some(i)
    }
  }
  None
}

// MoonBit, written by an agent

///|
fn fib(n : Int32) -> Int32 {
  match n {
    0 | 1 => n
    _ => fib(n - 1) + fib(n - 2)
  }
}

///|
test "fib" {
  inspect(fib(10), content="55")
}
