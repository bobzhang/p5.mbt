# Parity tests against p5.js

Every case is drawn twice on identical canvases — by p5.js
([`cases.js`](cases.js)) and by p5.mbt ([`cases/main.mbt`](cases/main.mbt)) —
and compared pixel by pixel. A pixel differs when a channel is off by more
than 2.

## Running

1. Build the p5.js checkout the port follows (once):

   ```bash
   git clone https://github.com/processing/p5.js .repos/p5.js
   cd .repos/p5.js && npm ci --ignore-scripts && npm run build && cd -
   ```

2. Build p5.mbt and serve the repository:

   ```bash
   moon build --target js --release
   python3 -m http.server 8765
   ```

3. Open <http://localhost:8765/parity/> (or `?case=NAME` for one case). The
   page shows both renderings and a difference image, and exposes the
   results as `window.parityResults`.

## Data cases

Some cases compare values instead of pixels: `dataCases` in `cases.js` and
`data_cases()` in `cases/main.mbt` return JSON (for example the points of
`font.textToPoints`), compared number by number with a tolerance of 1e-9.

## Font outlines in node

`font/` checks the `font` package against the libraries p5.js uses, without a
browser:

```bash
# glyph outlines, advances and kerning vs Typr.js
parity/font/compare.sh examples/assets/SourceSansPro-Regular.otf "Hamburgefonstiv"
python3 parity/font/diff.py /path/to/font.ttf "text"   # detailed diff

# contour sampling vs @davepagurek/bezier-path
moon build --target js parity/font/points
node parity/font/points_dump.mjs examples/assets/Lato-Regular.woff "Qg" 0.1 0.05
```

Run over the 400-odd fonts that ship with macOS, the outlines match Typr's
byte for byte except for variable fonts (Typr applies `fvar`/`gvar` deltas,
which the port does not do yet) and fonts Typr itself fails to read.
