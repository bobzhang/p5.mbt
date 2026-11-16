// Port of p5.js src/events/{pointer,keyboard}.js.

///|
fn P5::update_mouse_coords(self : P5) -> Unit {
  self.pmouse_x = self.mouse_x
  self.pmouse_y = self.mouse_y
  self.pwin_mouse_x = self.win_mouse_x
  self.pwin_mouse_y = self.win_mouse_y
}

///|
fn P5::handle_pointer(
  self : P5,
  e : @dom.PointerEvent,
  active : Map[Int32, (Double, Double, Double, Double, Int32)],
) -> Unit {
  match e.kind {
    "down" | "move" | "up" | "cancel" => {
      if e.kind is ("down" | "move") &&
        (e.kind is "down" || active.contains(e.pointer_id)) {
        active[e.pointer_id] = (e.x, e.y, e.win_x, e.win_y, e.buttons)
      }
      if e.kind is ("up" | "cancel") {
        active.remove(e.pointer_id)
      }
      if e.pointer_type is "touch" {
        self.touches = [
          for id, t in active => { x: t.0, y: t.1, win_x: t.2, win_y: t.3, id, }
        ]
      }
      let mut left = false
      let mut right = false
      let mut center = false
      for _, t in active {
        left = left || (t.4 & 1) != 0
        right = right || (t.4 & 2) != 0
        center = center || (t.4 & 4) != 0
      }
      self.mouse_button.left = left
      self.mouse_button.right = right
      self.mouse_button.center = center
      self.moved_x = e.moved_x
      self.moved_y = e.moved_y
      self.mouse_x = e.x
      self.mouse_y = e.y
      self.win_mouse_x = e.win_x
      self.win_mouse_y = e.win_y
      if !self.has_mouse_interacted {
        self.update_mouse_coords()
        self.has_mouse_interacted = true
      }
      let cb = self.callbacks
      let touch = e.pointer_type is "touch"
      match e.kind {
        "down" => {
          self.mouse_is_pressed = true
          (cb.mouse_pressed)(self)
          if touch {
            (cb.touch_started)(self)
          }
        }
        "move" =>
          if self.mouse_is_pressed {
            (cb.mouse_dragged)(self)
            if touch {
              (cb.touch_moved)(self)
            }
          } else {
            (cb.mouse_moved)(self)
          }
        "up" => {
          self.mouse_is_pressed = false
          (cb.mouse_released)(self)
          if touch {
            (cb.touch_ended)(self)
          }
        }
        _ => if active.is_empty() { self.mouse_is_pressed = false }
      }
    }
    "click" => (self.callbacks.mouse_clicked)(self)
    "dblclick" => (self.callbacks.double_clicked)(self)
    _ => ()
  }
}

///|
fn P5::handle_key(
  self : P5,
  kind : String,
  key : String,
  code : String,
  key_code : Int32,
) -> Unit {
  match kind {
    "down" => {
      if self.keys_down.contains(code) {
        // auto-repeat: only key_typed fires again
        if key.length() == 1 {
          self.key = key
          (self.callbacks.key_typed)(self)
        }
        return
      }
      self.key_is_pressed = true
      self.key_code = key_code
      self.key = key
      self.code = code
      self.keys_down[code] = true
      self.keys_down[key] = true
      (self.callbacks.key_pressed)(self)
      if key.length() == 1 {
        (self.callbacks.key_typed)(self)
      }
    }
    "up" => {
      self.key = key
      self.code = code
      self.key_code = key_code
      (self.callbacks.key_released)(self)
      self.keys_down.remove(code)
      self.keys_down.remove(key)
      if self.keys_down.is_empty() {
        self.key_is_pressed = false
      }
    }
    _ => {
      self.keys_down.clear()
      self.key_is_pressed = false
    }
  }
}

///|
/// Whether a key is currently held, by `key` value (`"a"`, `"ArrowLeft"`,
/// `"Shift"`) or physical `code` (`"KeyA"`, `"Space"`).
pub fn P5::key_is_down(self : P5, key : String) -> Bool {
  self.keys_down.contains(key)
}

///|
fn P5::install_events(self : P5, canvas : @dom.Canvas) -> Unit {
  let active : Map[Int32, (Double, Double, Double, Double, Int32)] = Map([])
  @dom.listen_pointer(canvas, () => self.width, () => self.height, e => {
    self.handle_pointer(e, active)
    true
  })
  @dom.listen_wheel(canvas, (_, dy) => {
    (self.callbacks.mouse_wheel)(self, dy)
    true
  })
  @dom.listen_keys((kind, key, code, key_code) => {
    self.handle_key(kind, key, code, key_code)
    true
  })
  @dom.on_window_resize(() => {
    self.window_width = @dom.window_width()
    self.window_height = @dom.window_height()
    (self.callbacks.window_resized)(self)
  })
  @dom.on_focus_change(f => self.focused = f)
}
