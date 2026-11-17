// Run in a page that loads p5.js (e.g. parity/index.html) to capture the
// GLSL that p5.strands generates for the built-in filters, then save the
// JSON as tools/filter_shaders.json and run tools/gen_filter_shaders.py.
await new Promise((resolve, reject) => {
  new p5(p => {
    p.setup = () => {
      try {
        p.createCanvas(50, 50, p.WEBGL);
        const r = p._renderer, res = {};
        for (const op of ['gray', 'invert', 'threshold', 'posterize', 'blur', 'erode', 'dilate', 'opaque']) {
          const sh = r._makeFilterShader(r, op);
          res[op] = { vert: sh.vertSrc(), frag: sh.fragSrc() };
        }
        res.base = { vert: r.baseFilterShader().vertSrc(), frag: r.baseFilterShader().fragSrc() };
        console.log(JSON.stringify(res));
        resolve(res); p.remove();
      } catch (e) { reject(e); }
    };
  });
});
