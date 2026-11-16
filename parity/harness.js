// Renders every case with p5.js and with p5.mbt and compares the pixels.
// A pixel "differs" when any channel differs by more than TOLERANCE.
import { cases, svgCases } from './cases.js';

const TOLERANCE = 2;
const only = new URLSearchParams(location.search).get('case');

function cell(row) { const td = document.createElement('td'); row.appendChild(td); return td; }

function renderP5(draw, w, h, host, load) {
  return new Promise((resolve, reject) => {
    new p5(p => {
      p.setup = async () => {
        try {
          p.createCanvas(w, h);
          p.pixelDensity(1);
          p.randomSeed(1);
          p.noLoop();
          const data = load ? await load(p) : undefined;
          draw(p, data);
          resolve(p.canvas);
        } catch (e) { reject(e); }
      };
    }, host);
  });
}

function renderMbt(name, host) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('timed out')), 10000);
    const ok = globalThis.p5mbt_render(name, host.id, () => {
      clearTimeout(timer);
      resolve(host.querySelector('canvas'));
    });
    if (!ok) { clearTimeout(timer); reject(new Error('unknown case')); }
  });
}

function pixelsOf(canvas) {
  return canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data;
}

async function run() {
  const results = [];
  for (const [name, [w, h, draw, load]] of Object.entries(cases)) {
    if (only && only !== name) continue;
    const row = document.createElement('tr');
    document.getElementById('rows').appendChild(row);
    cell(row).textContent = name;
    const a = cell(row); a.id = 'js-' + name;
    const b = cell(row); b.id = 'mbt-' + name;
    const d = cell(row);
    const r = cell(row);
    let jsCanvas, mbtCanvas;
    try {
      jsCanvas = await renderP5(draw, w, h, a, load);
    } catch (e) { r.innerHTML = `<span class=bad>p5.js error: ${e}</span>`; results.push({ name, error: String(e) }); continue; }
    try {
      mbtCanvas = await renderMbt(name, b);
    } catch (e) { r.innerHTML = `<span class=bad>p5.mbt error: ${e}</span>`; results.push({ name, error: String(e) }); continue; }
    const pa = pixelsOf(jsCanvas), pb = pixelsOf(mbtCanvas);
    const diff = document.createElement('canvas'); diff.width = w; diff.height = h; d.appendChild(diff);
    const dctx = diff.getContext('2d'); const img = dctx.createImageData(w, h);
    let bad = 0, maxDelta = 0;
    if (pa.length !== pb.length) { bad = -1; }
    else for (let i = 0; i < pa.length; i += 4) {
      const delta = Math.max(Math.abs(pa[i] - pb[i]), Math.abs(pa[i + 1] - pb[i + 1]),
        Math.abs(pa[i + 2] - pb[i + 2]), Math.abs(pa[i + 3] - pb[i + 3]));
      maxDelta = Math.max(maxDelta, delta);
      const off = delta > TOLERANCE;
      if (off) bad++;
      img.data[i] = off ? 255 : 230; img.data[i + 1] = off ? 0 : 230; img.data[i + 2] = off ? 0 : 230; img.data[i + 3] = 255;
    }
    dctx.putImageData(img, 0, 0);
    const pct = bad < 0 ? 100 : (100 * bad) / (w * h);
    const ok = bad === 0;
    r.innerHTML = ok ? `<span class=ok>identical</span> (max Δ ${maxDelta})`
      : `<span class=bad>${bad < 0 ? 'size mismatch' : bad + ' px (' + pct.toFixed(2) + '%)'}</span> max Δ ${maxDelta}`;
    results.push({ name, differing: bad, percent: +pct.toFixed(3), maxDelta });
  }
  for (const [name, [w, h, scene]] of Object.entries(svgCases)) {
    if (only && only !== name) continue;
    const row = document.createElement('tr');
    document.getElementById('rows').appendChild(row);
    cell(row).textContent = name + ' (getSVG rendered)';
    const a = cell(row), b = cell(row), d = cell(row), r = cell(row);
    try {
      const jsSvg = await new Promise(resolve => {
        new p5(p => { p.setup = () => { p.createCanvas(w, h); p.pixelDensity(1); p.noLoop();
          const rec = p.buildShape(() => scene(p)); resolve(p.getSVG(rec)); p.remove(); }; }, a);
      });
      const mbtSvg = await new Promise((resolve, reject) => {
        const holder = document.createElement('div'); holder.id = 'svgsrc-' + name; holder.style.display = 'none';
        document.body.appendChild(holder);
        if (!globalThis.p5mbt_svg(name, holder.id, resolve)) reject(new Error('unknown svg case'));
      });
      const ca = await svgToCanvas(jsSvg, w, h), cb = await svgToCanvas(mbtSvg, w, h);
      a.appendChild(ca); b.appendChild(cb);
      const res = compare(ca, cb, w, h, d);
      res.name = name; results.push(res); report(r, res);
    } catch (e) { r.innerHTML = `<span class=bad>${e}</span>`; results.push({ name, error: String(e) }); }
  }
  const failed = results.filter(r => r.error || r.differing !== 0);
  document.getElementById('summary').textContent =
    `${results.length - failed.length} / ${results.length} cases identical`;
  globalThis.parityResults = results;
}
run();

function svgToCanvas(svg, w, h) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => { const c = document.createElement('canvas'); c.width = w; c.height = h;
      c.getContext('2d').drawImage(img, 0, 0, w, h); resolve(c); };
    img.onerror = () => reject(new Error('SVG did not render'));
    img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  });
}

function compare(ca, cb, w, h, d) {
  const pa = pixelsOf(ca), pb = pixelsOf(cb);
  const diff = document.createElement('canvas'); diff.width = w; diff.height = h; d.appendChild(diff);
  const dctx = diff.getContext('2d'); const img = dctx.createImageData(w, h);
  let bad = 0, maxDelta = 0;
  for (let i = 0; i < pa.length; i += 4) {
    const delta = Math.max(Math.abs(pa[i] - pb[i]), Math.abs(pa[i + 1] - pb[i + 1]), Math.abs(pa[i + 2] - pb[i + 2]), Math.abs(pa[i + 3] - pb[i + 3]));
    maxDelta = Math.max(maxDelta, delta);
    const off = delta > TOLERANCE; if (off) bad++;
    img.data[i] = off ? 255 : 230; img.data[i + 1] = off ? 0 : 230; img.data[i + 2] = off ? 0 : 230; img.data[i + 3] = 255;
  }
  dctx.putImageData(img, 0, 0);
  return { differing: bad, percent: +(100 * bad / (w * h)).toFixed(3), maxDelta };
}

function report(r, res) {
  r.innerHTML = res.differing === 0 ? `<span class=ok>identical</span> (max Δ ${res.maxDelta})`
    : `<span class=bad>${res.differing} px (${res.percent}%)</span> max Δ ${res.maxDelta}`;
}
