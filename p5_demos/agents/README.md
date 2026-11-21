# From Punched Cards to AI Agents

A silent 90-second film drawn by this MoonBit program, told in short Chinese
captions. Its refrain: every age has its own language. Unix had C, the GPU
had CUDA, the age of agents has MoonBit. It ends on **Made in MoonBit**.

Six languages, each typed on the machine of its time: FORTRAN, LISP, C, ML,
Rust and WebAssembly. Then the camera pulls back to the whole map, and the
idea each one passed on (speed, functions as values, close to the machine,
types inferred, safety by default, runs anywhere) flows along its line to
one point, where MoonBit appears: designed for AI, safe, verifiable, fast.

## Watch and record

From the repository root:

```sh
moon build --target js --release
python3 -m http.server 8765          # then open /p5_demos/agents/
```

`?t=60&still` shows one moment. To make the MP4:

```sh
node p5_demos/agents/tools/render.cjs    # -> p5_demos/agents/output/made-in-moonbit.mp4
```

`render.cjs` opens the page with `?record`: `p.record()` renders each frame
at a fixed time step and posts it to a local server that pipes it into
ffmpeg. `PLAYWRIGHT_PATH`, `CHROME_PATH` and `FFMPEG` override the tool
locations.

## Layout

- `story/`: the timeline (camera moves, captions)
- `world.mbt`, `camera.mbt`: the night-sky map and the camera moves
- `languages.mbt`, `code.mbt`: the six languages, their machines, the
  typewriter
- `scenes.mbt`: title cards, the agent orbit, the refrain, the finale, the
  film look
- `snippets/`: the MoonBit code shown on screen, compiled and tested;
  `tools/check_snippets.py` checks the film matches it, and `render.cjs`
  refuses to record if it does not
