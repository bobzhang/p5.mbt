// Samples each glyph contour with the real @davepagurek/bezier-path the way
// p5's pathToPoints does. Usage: node points_dump.mjs font text factor [simplify]
import fs from 'fs';
globalThis.window = {};
const Typr = (await import('../../.repos/p5.js/src/type/lib/Typr.js')).default;
const { createFromCommands } = await import('../../.repos/p5.js/node_modules/@davepagurek/bezier-path/build/index.js');
const [file, text, factor, simp] = process.argv.slice(2);
const font = Typr.parse(new Uint8Array(fs.readFileSync(file)).buffer)[0];
const counts = { M: 2, L: 2, Q: 4, C: 6, Z: 0 };
const out = [];
for (const g of Typr.U.shape(font, text, true)) {
  const p = Typr.U.glyphToPath(font, g.g);
  let k = 0, contours = [];
  for (const c of p.cmds) {
    const a = p.crds.slice(k, k + counts[c]); k += counts[c];
    if (c === 'M') contours.push([]);
    const o = c === 'Z' ? { type: c } : c === 'Q' ? { type: c, x1: a[0], y1: a[1], x: a[2], y: a[3] }
      : c === 'C' ? { type: c, x1: a[0], y1: a[1], x2: a[2], y2: a[3], x: a[4], y: a[5] } : { type: c, x: a[0], y: a[1] };
    contours[contours.length - 1].push(o);
  }
  for (const cmds of contours) {
    let pts;
    try {
      const path = createFromCommands(cmds);
      const n = Math.max(1, Math.ceil(path.getTotalLength() * +factor));
      pts = [];
      for (let i = 0; i < n; i++) {
        const len = path.getTotalLength() * (n === 1 ? 0 : i / (n - 1));
        pts.push({ ...path.getPointAtLength(len), angle: path.getAngleAtLength(len) });
      }
      if (+simp) {
        const at = (v, i) => { const s = v.length; return v[i < 0 ? (i % s) + s : i % s]; };
        const col = (a, b, c, t) => { const abx = b.x - a.x, aby = b.y - a.y, bcx = c.x - b.x, bcy = c.y - b.y;
          return Math.acos((abx * bcx + aby * bcy) / (Math.sqrt(abx * abx + aby * aby) * Math.sqrt(bcx * bcx + bcy * bcy))) < t; };
        for (let i = pts.length - 1; pts.length > 3 && i >= 0; --i)
          if (col(at(pts, i - 1), at(pts, i), at(pts, i + 1), +simp)) pts.splice(i % pts.length, 1);
      }
    } catch (e) { pts = 'error'; }
    out.push(pts === 'error' ? 'error' : pts.map(p => `${p.x},${p.y},${p.angle}`).join(' '));
  }
}
console.log(out.join('\n'));
