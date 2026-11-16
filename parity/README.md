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
