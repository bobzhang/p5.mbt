// Dumps Typr glyph outlines and shaping for comparison with p5.mbt's font
// package. Usage: node typr_dump.mjs font.ttf "text"
import fs from 'fs';
globalThis.window = {};
const Typr = (await import('../../.repos/p5.js/src/type/lib/Typr.js')).default;
const [file, text] = process.argv.slice(2);
const buf = fs.readFileSync(file);
const font = Typr.parse(new Uint8Array(buf).buffer)[0];
const shape = Typr.U.shape(font, text, true);
const out = { upem: font.head.unitsPerEm, asc: font.hhea.ascender, desc: font.hhea.descender, glyphs: [] };
for (const g of shape) {
  const p = Typr.U.glyphToPath(font, g.g);
  out.glyphs.push({ g: g.g, ax: g.ax, cmds: p.cmds.join(''), crds: p.crds.map(v => +v.toFixed(4)) });
}
console.log(JSON.stringify(out));
