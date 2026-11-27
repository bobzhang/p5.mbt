///|
test "color names" {
  let name = (r : Double, g : Double, b : Double) => {
    @a11y.color_name([r, g, b, 255])
  }
  assert_eq(
    [
      name(255, 0, 0),
      name(0, 128, 0),
      name(0, 0, 255),
      name(0, 0, 0),
      name(255, 255, 255),
      name(200, 200, 200),
      name(255, 200, 0),
      name(128, 0, 128),
    ],
    [
      "red", "dark green", "blue", "black", "white", "white", "yellow", "dark fuchsia",
    ],
  )
}

///|
test "outputs" {
  let ing = @a11y.Ingredients::new()
  ing.background([220, 220, 220, 255])
  ing.fill_color([255, 0, 0, 255])
  ing.add("circle", {
    color: ing.fill,
    pos: "middle",
    loc_x: 5,
    loc_y: 5,
    area: Some(12),
    length: None,
  })
  ing.add("line", {
    color: ing.stroke,
    pos: "from top left to bottom right",
    loc_x: 4,
    loc_y: 4,
    area: None,
    length: Some(141),
  })
  inspect(
    ing.text_summary("100", "100"),
    content=(
      #|Your output is a, 100 by 100 pixels, white canvas containing the following 2 shapes:
    ),
  )
  inspect(
    ing.text_list("c"),
    content=(
      #|<li><a href="#cshape0">red circle</a>, at middle, covering 12% of the canvas.</li><li><a href="#cshape1">black line</a>, from top left to bottom right, 141 pixels long.</li>
    ),
  )
  inspect(
    ing.grid_summary_and_details("c", "100", "100").0,
    content=(
      #|white canvas, 100 by 100 pixels, contains 2 shapes:  1 circle 1 line
    ),
  )
  inspect(
    @a11y.description_text("A red circle"),
    content=(
      #|A red circle.
    ),
  )
  inspect(
    @a11y.element_name("Circle"),
    content=(
      #|Circle:
    ),
  )
}
