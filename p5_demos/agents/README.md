# From Punched Cards to AI Agents

A 90-second film drawn by this MoonBit program. Its refrain: every age has
its own language. Unix had C, the GPU had CUDA, the age of agents has
MoonBit. It ends on **Made in MoonBit**.

Six languages, each typed on the machine of its time, each with what MoonBit
took from it: FORTRAN (fast compiled code), LISP (closures, garbage
collection), C (low-level code), ML (type inference, pattern matching), Rust
(safety by default) and WebAssembly. Then the big picture, AI agents, and
MoonBit: designed for AI, safe, verifiable, fast.

## Watch and record

From the repository root:

```sh
moon build --target js --release
python3 -m http.server 8765          # then open /p5_demos/agents/
```

`?t=60&still` shows one moment. To make the MP4 (English narration with
macOS `say`, Chinese subtitles, an original score):

```sh
python3 p5_demos/agents/tools/check_snippets.py
python3 p5_demos/agents/tools/audio.py   # -> assets/soundtrack.wav, output/*.srt
node p5_demos/agents/tools/render.cjs    # -> output/made-in-moonbit.mp4
```

`render.cjs` opens the page with `?record`: `p.record()` renders each frame
at a fixed time step and posts it to a local server that pipes it into
ffmpeg. `PLAYWRIGHT_PATH`, `CHROME_PATH`, `FFMPEG` and `VOICE` override the
tool locations and the narrator.

## Layout

- `story/`: the timeline (camera moves, narration, subtitles) shared by the
  picture and the sound; `cues/` prints it as JSON for `tools/audio.py`
- `world.mbt`, `camera.mbt`: the night-sky map and the camera moves
- `languages.mbt`, `code.mbt`: the six languages, their machines, the
  typewriter
- `scenes.mbt`: title cards, MoonBit panels, the agent orbit, the finale,
  the film look
- `snippets/`: every MoonBit snippet shown on screen, compiled and tested;
  `tools/check_snippets.py` checks the film matches it, and `render.cjs`
  refuses to record if it does not
