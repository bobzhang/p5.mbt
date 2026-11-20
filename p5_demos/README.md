# p5_demos

Demos for [p5.mbt](https://github.com/bobzhang/p5.mbt), MoonBit's port of
[p5.js](https://p5js.org): WEBGL scenes, custom shaders, framebuffers,
particles, generative art and two short films. Every demo is an executable
package that imports `bobzhang/p5` and compiles to JavaScript.

| Demo | What it shows |
| --- | --- |
| [`asia`](asia/) | *Five Thousand Years of Asia*, a two-minute WEBGL film in 13 chapters, with lit 3D scenes and CJK captions |
| [`history`](history/) | *A Short History of Computation*, a 104-second 2D film |
| [`galaxy`](galaxy/main.mbt) | 12,000 stars as `POINTS` with per-vertex colors, `orbit_control` |
| [`lorenz`](lorenz/main.mbt) | the Lorenz attractor as a 3D line colored by speed |
| [`orrery`](orrery/main.mbt) | lights, emissive/specular materials, generated textures, font-shader labels |
| [`terrain`](terrain/main.mbt) | noise terrain from triangle strips, fog added to p5's material shader with a hook |
| [`mandelbrot`](mandelbrot/main.mbt) | a deep zoom in a custom fragment shader (`create_shader`, uniforms) |
| [`feedback`](feedback/main.mbt) | two framebuffers feeding each other for trails |
| [`boids`](boids/main.mbt) | flocking: separation, alignment, cohesion; the mouse attracts |
| [`particles`](particles/main.mbt) | `text_to_points` words made of springy particles |
| [`tree`](tree/main.mbt) | a recursive tree swaying in Perlin-noise wind |
| [`chrome`](chrome/main.mbt) | image-based lighting and a 360° background (`image_light`, `panorama`) on metal spheres |
| [`type3d`](type3d/main.mbt) | extruded 3D letters from font outlines (`text_to_model`) |
| [`bumpy`](bumpy/main.mbt) | bump and normal maps (`bump_texture`, `normal_texture`) generated in graphics buffers |
| [`swarm`](swarm/main.mbt) | GPU instancing: 8,000 boxes in one draw call (`instances`, `gl_InstanceID` in a shader hook) |
| [`ribbons`](ribbons/main.mbt) | a custom per-vertex attribute (`vertex_property`) read by shader hooks |
| [`crt`](crt/main.mbt) | a custom filter shader over a 2D sketch (`create_filter_shader`, `filter_shader`) |
| [`accessible`](accessible/main.mbt) | screen-reader descriptions and generated outputs (`describe`, `text_output`, `grid_output`) |

## Running

The p5.mbt repository is a `moon.work` workspace containing both the library
and this module, so one build compiles everything. From the repository root:

```bash
moon build --target js --release
python3 -m http.server 8765
```

Then open <http://localhost:8765/p5_demos/> for the gallery. Each page loads
`_build/js/release/build/bobzhang/p5_demos/<demo>/<demo>.js`.

The films accept `?t=SECONDS&still` to show a single moment, and `?record`
to render frame-exact video with `tools/record.py` (see the p5.mbt README).

## Writing your own

Each demo is a package with a `moon.pkg` like

```
import {
  "bobzhang/p5",
}

supported_targets = "js"

pkgtype(kind: "executable")
```

and a `main` that calls `@p5.run(setup=..., draw=...)`.
