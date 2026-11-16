///|
test "keyboard state follows p5.js" {
  let p = P5::headless(Recorder::new(), 10, 10)
  let events : Array[String] = []
  p.callbacks.key_pressed = p => events.push("pressed \{p.key}")
  p.callbacks.key_typed = p => events.push("typed \{p.key}")
  p.callbacks.key_released = p => events.push("released \{p.key}")
  p.handle_key("down", "a", "KeyA", 65)
  p.handle_key("down", "a", "KeyA", 65) // auto-repeat
  p.handle_key("down", "Shift", "ShiftLeft", 16)
  inspect(
    p.key_is_down("a") && p.key_is_down("KeyA") && p.key_is_down("Shift"),
    content="true",
  )
  p.handle_key("up", "a", "KeyA", 65)
  inspect(p.key_is_pressed, content="true")
  p.handle_key("up", "Shift", "ShiftLeft", 16)
  inspect(p.key_is_pressed, content="false")
  inspect(p.key, content="")
  debug_inspect(
    events,
    content=(
      #|[
      #|  "pressed a",
      #|  "typed a",
      #|  "pressed Shift",
      #|  "released a",
      #|  "released Shift",
      #|]
    ),
  )
}

///|
test "mouse state, pmouse and drag" {
  let p = P5::headless(Recorder::new(), 10, 10)
  let events : Array[String] = []
  p.callbacks.mouse_pressed = p => {
    events.push("pressed \{p.mouse_x},\{p.mouse_y}")
  }
  p.callbacks.mouse_dragged = p => {
    events.push("dragged \{p.pmouse_x}->\{p.mouse_x}")
  }
  p.callbacks.mouse_moved = _ => events.push("moved")
  p.callbacks.mouse_released = _ => events.push("released")
  let active = Map([])
  let ev = fn(kind : String, x : Double, buttons : Int32) -> @dom.PointerEvent {
    {
      kind,
      x,
      y: 1,
      win_x: x,
      win_y: 1,
      moved_x: 0,
      moved_y: 0,
      button: 0,
      buttons,
      pointer_id: 1,
      pointer_type: "mouse",
      is_primary: true,
    }
  }
  p.handle_pointer(ev("move", 2, 0), active)
  p.handle_pointer(ev("down", 3, 1), active)
  inspect(p.mouse_is_pressed && p.mouse_button.left, content="true")
  p.update_mouse_coords() // end of frame
  p.handle_pointer(ev("move", 5, 1), active)
  p.handle_pointer(ev("up", 5, 0), active)
  inspect(p.mouse_is_pressed || p.mouse_button.left, content="false")
  debug_inspect(
    events,
    content=(
      #|["moved", "pressed 3,1", "dragged 3->5", "released"]
    ),
  )
}

///|
test "clip without push ends with the frame" {
  let rec = Recorder::new()
  let p = P5::headless(rec, 10, 10)
  p.set_draw(p => {
    p.begin_clip()
    p.rect(0, 0, 5, 5)
    p.end_clip()
  })
  ignore(rec.take())
  p.redraw()
  debug_inspect(
    rec.take(),
    content=(
      #|[
      #|  "save",
      #|  "clip base=1 0 0 1 0 0 [1 0 0 1 0 0] R0,0,5,5",
      #|  "restore",
      #|  "blend source-over",
      #|  "smoothing true",
      #|]
    ),
  )
}
