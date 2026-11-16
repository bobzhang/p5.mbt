# p5.mbt

A port of [p5.js](https://p5js.org) to [MoonBit](https://www.moonbitlang.com),
running on MoonBit's JavaScript backend and drawing on an HTML canvas.

It covers the 2D core of p5.js 2.x: the setup/draw lifecycle, shapes and
custom shapes, color (including p5 2.x's color spaces), transforms,
typography, images and pixels, events, math (vectors, noise, random), DOM
helpers, and data loading. The algorithms follow the p5.js sources closely:
`random()`/`noise()` produce the same numbers as p5.js for the same seed, and
shapes go through a port of p5 2.x's `Shape` → `Path2D` pipeline.

```moonbit
fn main {
  @p5.run(
    setup=p => p.create_canvas(400, 400),
    draw=p => {
      p.background(220)
      p.fill((237, 34, 93))
      p.circle(p.mouse_x, p.mouse_y, 50)
    },
  )
}
```

## Getting started

1. Add the module and import it in your main package:

   ```
   // moon.pkg
   import {
     "bobzhang/p5",
   }

   supported_targets = "js"

   options(
     "is-main": true,
   )
   ```

2. Build for JavaScript:

   ```bash
   moon build --target js --release
   ```

3. Load the generated script from a page:

   ```html
   <main></main>
   <script src="_build/js/release/build/<your-package>/<name>.js"></script>
   ```

### Running the examples

```bash
moon build --target js --release
python3 -m http.server 8765
```

Then open <http://localhost:8765/examples/>. The examples are:

| Example | Shows |
| --- | --- |
| [`shapes`](examples/shapes/main.mbt) | primitives, Bézier/spline curves, contours, HSB colors, transforms, text, mouse |
| [`images`](examples/images/main.mbt) | `load_image` in `preload`, filters, tint, per-pixel edits, graphics buffers |
| [`flowfield`](examples/flowfield/main.mbt) | vectors, Perlin noise, sliders and buttons |
| [`input`](examples/input/main.mbt) | keyboard, mouse, wheel, `clip`, `erase` |
| [`data`](examples/data/main.mbt) | `load_json` and `load_strings` |
| [`history`](examples/history/main.mbt) | *A Short History of Computation*, a 104-second film made entirely with p5.mbt |

### Recording a sketch to video

`p.record(frames=…)` renders a sketch offline: `draw` runs as fast as
possible with `delta_time` and `millis()` advancing as if it ran at exactly
60 fps, and each frame is uploaded as a PNG. `tools/record.py` serves the
repository and pipes the frames into ffmpeg:

```bash
moon build --target js --release
python3 tools/record.py --out history.mp4
```

Then open <http://localhost:8766/examples/history/?record>. The film's page
also accepts `?t=SECONDS&still` to inspect a single moment.

## From p5.js to MoonBit

p5.js runs sketches in "global mode"; p5.mbt uses the equivalent of p5's
*instance mode*: every callback receives the sketch `p : @p5.P5`, and all
p5 functions are methods on it.

| p5.js | p5.mbt |
| --- | --- |
| `function setup() {…}` / `function draw() {…}` | `@p5.run(setup=p => …, draw=p => …)` |
| `function mousePressed() {…}` (and other event functions) | `@p5.run(mouse_pressed=p => …)` |
| `createCanvas(w, h)` | `p.create_canvas(w, h)` |
| `width`, `mouseX`, `frameCount`, `key` | `p.width`, `p.mouse_x`, `p.frame_count`, `p.key` |
| `fill(200)`, `fill(255, 0, 0)`, `fill(0, 0, 255, 128)`, `fill('red')` | `p.fill(200)`, `p.fill((255, 0, 0))`, `p.fill((0, 0, 255, 128))`, `p.fill("red")` |
| `ellipse(x, y, w, h)` | `p.ellipse(x, y, w, h=h)` (`h` defaults to `w`) |
| `rect(x, y, w, h, r)` | `p.rect(x, y, w, h, tl=r)` |
| `arc(x, y, w, h, a, b, PIE)` | `p.arc(x, y, w, h, a, b, mode=Pie)` |
| `endShape(CLOSE)` | `p.end_shape(mode=Close)` |
| `random()`, `random(10)`, `random(5, 10)`, `random(arr)` | `p.random()`, `p.random_max(10)`, `p.random_range(5, 10)`, `p.random_choice(arr)` |
| `noise(x, y)` | `p.noise(x, y=y)` |
| `textAlign(CENTER, CENTER)` | `p.text_align(HCenter, vertical=VCenter)` |
| `colorMode(HSB, 1)` | `p.color_mode_max(HSB, 1)` |
| `loop()` | `p.loop_()` (`loop` is a MoonBit keyword) |
| `createVector(x, y)` | `p.create_vector(x, y)` or `@p5.Vector(x, y)` |
| `v.add(w).mult(2)` | `v.add(w); v.mult(2)` (mutating methods return `Unit`), or `(v + w).scaled(2)` |
| `bezierVertex(x2, y2, x3, y3, x4, y4)` (p5 1.x) | `p.bezier_vertex3(x2, y2, x3, y3, x4, y4)`; p5 2.x style `p.bezier_vertex(x, y)` per point |
| `loadImage(url)` in `preload`/`async setup` | `p.load_image(url)` in `preload` (setup waits for it) |

Naming: camelCase becomes snake_case. Overloads become optional labeled
arguments (`ellipse(…, h=…)`), separate functions (`random_max`,
`random_range`), or the `ColorArg` trait for colors, which accepts numbers,
2/3/4-tuples of numbers (`Int` and `Double` can be mixed), CSS strings,
`Array[Double]` and `Color`. Constants are enum constructors (`Center`,
`Pie`, `Close`, `HSB`, `Degrees`, `Square`, …).

## Packages

| Package | Contents | Targets |
| --- | --- | --- |
| `bobzhang/p5` | the sketch API (`P5`, `run`, `Image`, `Element`, …) | js |
| `bobzhang/p5/math` | `Vector`, `Noise`, `Random` (p5's LCG), `Matrix2D`, `map`/`lerp`/… | all |
| `bobzhang/p5/color` | `Color`: RGB/HSB/HSL/HWB/Lab/LCH/OKLab/OKLCH, CSS parsing, `lerp` | all |
| `bobzhang/p5/shape` | the p5 2.x shape model and its conversion to canvas path commands | all |
| `bobzhang/p5/filters` | CPU image filters (threshold, gray, invert, posterize, erode, dilate, blur) | all |
| `bobzhang/p5/dom` | JavaScript FFI bindings (canvas, events, images, DOM) | js |

The sketch draws through the `Surface` trait. `CanvasSurface` paints on an
HTML canvas; `Recorder` logs every drawing call, so sketches can run
headless:

```moonbit
let rec = @p5.Recorder::new()
let p = @p5.P5::headless(rec, 100, 100)
p.fill("red")
p.rect(10, 10, 20, 20)
rec.take() // ["…", "fill #ff0000 R10,10,20,20", "stroke #000000 w=1 …"]
```

## What is ported

- **Structure**: `run` with `preload`/`setup`/`draw`, frame-rate throttling as
  in p5's `_draw`, `no_loop`/`loop_`/`redraw`, `push`/`pop`, `clip`/
  `begin_clip`/`end_clip` (with `invert`).
- **Shapes**: `point`, `line`, `rect`/`square` (with rounded corners),
  `ellipse`/`circle`, `arc` (`Open`/`Chord`/`Pie`), `triangle`, `quad`,
  `bezier`, `spline`/`curve`; `begin_shape` (`Path`, `Points`, `Lines`,
  `Triangles`, `Quads`, `TriangleFan`, `TriangleStrip`, `QuadStrip`), `vertex`,
  `bezier_vertex` (order 2 or 3), `spline_vertex` with ends/tightness,
  contours; `rect_mode`, `ellipse_mode`, stroke weight/cap/join,
  `bezier_point`/`bezier_tangent`/`spline_point`/`spline_tangent`.
- **Color**: `color`, `fill`, `stroke`, `background`, `clear`, `erase`,
  `blend_mode`, `color_mode` with custom maxes, `lerp_color`,
  `palette_lerp`, `red`/`green`/`blue`/`alpha`/`hue`/`saturation`/
  `brightness`/`lightness`.
- **Transform**: `translate`, `rotate`, `scale`, `shear_x`/`shear_y`,
  `apply_matrix`, `reset_matrix`, `angle_mode`.
- **Typography**: `text` (multi-line, wrapped in a box, truncated),
  `text_size`, `text_leading`, `text_font`, `load_font`, `text_style`,
  `text_align`, `text_wrap`, `text_width`, `text_ascent`, `text_descent`.
- **Image**: `load_image`, `create_image`, `image`/`image_region`,
  `image_mode`, `tint`, `pixels`/`load_pixels`/`update_pixels`, `get`/`set`,
  `filter`, `create_graphics`, `save_canvas`; `Image` `resize`/`copy`/
  `copy_from`/`mask`/`filter`/`save`.
- **Events**: mouse/pointer (`mouse_x`, `pmouse_x`, `mouse_button`,
  `moved_x`, `touches`, pressed/released/clicked/double-clicked/moved/
  dragged/wheel, touch callbacks), keyboard (`key`, `code`, `key_code`,
  `key_is_down`, pressed/released/typed), `window_resized`.
- **Recording**: `record` for frame-exact offline rendering to video.
- **Environment**: `frame_rate`, `delta_time`, `millis`, `cursor`,
  `no_cursor`, `fullscreen`, `pixel_density`, `display_density`,
  `window_width`/`window_height`, `resize_canvas`, `focused`.
- **Math**: `Vector` (all p5.Vector 2D/3D operations, `slerp`, `reflect`,
  `angle_between`, …), `noise`/`noise_detail`/`noise_seed`, `random*`,
  `random_seed`, `random_gaussian`, `map`, `constrain`, `lerp`, `dist`,
  `mag`, `norm`, `sq`, `fract`, `round`, trigonometry in the current angle
  mode.
- **Utilities and data**: `nf`/`nfc`/`nfp`/`nfs`, `split_tokens`, `shuffle`,
  `hex`/`unhex`/`binary`/`unbinary`, `year`…`second`, local storage
  (`store_item`/`get_item`), `load_strings`/`load_text`/`load_json`,
  `save_strings`/`save_json`.
- **DOM**: `create_div`/`p`/`span`/`a`/`img`/`button`/`slider`/`checkbox`/
  `select`/`input`/`color_picker`, `select`, and `Element` methods for
  values, styling, positioning and callbacks.

## Not ported

WebGL and WebGPU rendering (3D, shaders, p5.strands, framebuffers),
`p5.Font` glyph access (`textToPoints`, `textToContours`), SVG import/export,
media elements (video, audio, camera capture), `p5.Table`/`p5.XML`,
accessibility outputs (`describe`, `gridOutput`), and the Friendly Error
System. Color strings for non-RGB colors are serialized as CSS `rgb()` instead
of color.js's formats.

## Development

```bash
moon check
moon test        # runs on the JS backend (Node), using the Recorder surface
moon fmt
moon info        # regenerates pkg.generated.mbti
```

Reference values in the math tests come from running the original p5.js
sources under Node.

## License

p5.js is licensed under the GNU Lesser General Public License v2.1, and this
port is distributed under the same license; see [LICENSE](LICENSE).
