// The MoonBit code the film shows, exactly as it appears on screen.

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
