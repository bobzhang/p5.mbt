///|
/// Keyboard, mouse, wheel, clipping and erasing.
fn main {
  let x = Ref(320.0)
  let y = Ref(200.0)
  let size = Ref(60.0)
  let log : Array[String] = []
  let say = (s : String) => {
    log.push(s)
    if log.length() > 8 {
      log.remove(0) |> ignore
    }
  }
  @p5.run(
    setup=p => {
      p.create_canvas(640, 400)
      @p5.set_title("p5.mbt — input")
      p.frame_rate(60)
    },
    draw=p => {
      p.background(235)
      // Move with the arrow keys (held keys are polled every frame).
      let step = 4.0
      if p.key_is_down("ArrowLeft") {
        x.val -= step
      }
      if p.key_is_down("ArrowRight") {
        x.val += step
      }
      if p.key_is_down("ArrowUp") {
        y.val -= step
      }
      if p.key_is_down("ArrowDown") {
        y.val += step
      }
      // A striped background, clipped to a circle around the player.
      p.push()
      p.clip(() => p.circle(x.val, y.val, size.val * 2.5))
      p.no_stroke()
      for i in 0..<40 {
        p.fill(if i % 2 == 0 { (255, 200, 120) } else { (255, 160, 90) })
        p.rect(i.to_double() * 16, 0, 16, p.height)
      }
      p.pop()
      p.fill((40, 90, 200))
      p.stroke(255)
      p.stroke_weight(3)
      p.circle(x.val, y.val, size.val)
      // An erased hole that follows the mouse.
      p.erase()
      p.circle(p.mouse_x, p.mouse_y, 24)
      p.no_erase()
      // Event log.
      p.no_stroke()
      p.fill(30)
      p.text_size(14)
      p.text_font("monospace")
      p.text("arrows or drag: move   wheel: resize", 12, 22)
      for i, line in log {
        p.text(line, 12, 50 + i.to_double() * 18)
      }
      p.text_align(Right)
      p.text(
        "fps \{@p5.nf(p.get_frame_rate(), right=0)}  frame \{p.frame_count}",
        p.width - 12,
        22,
      )
      p.text_align(Left)
    },
    key_pressed=p => {
      say("key_pressed key=\{p.key} code=\{p.code} key_code=\{p.key_code}")
    },
    key_typed=p => say("key_typed \{p.key}"),
    mouse_pressed=p => {
      say(
        "mouse_pressed \{@p5.nf(p.mouse_x, right=1)}, \{@p5.nf(p.mouse_y, right=1)} left=\{p.mouse_button.left}",
      )
    },
    mouse_released=_ => say("mouse_released"),
    double_clicked=_ => say("double_clicked"),
    mouse_dragged=p => {
      x.val += p.mouse_x - p.pmouse_x
      y.val += p.mouse_y - p.pmouse_y
    },
    mouse_wheel=(_, delta) => {
      size.val = @p5.constrain(size.val - delta * 0.1, 10, 300)
      say("mouse_wheel \{delta}")
    },
  )
}
