// p5.js side of the parity cases. Each case draws one frame on a canvas of
// the given size; parity/cases/main.mbt draws the same thing with p5.mbt.
export const cases = {
  basics: [200, 150, p => {
    p.background(220);
    p.fill(255, 0, 0); p.rect(20, 20, 60, 40);
    p.stroke(0, 0, 255); p.strokeWeight(4); p.fill(0, 255, 0, 128); p.ellipse(120, 60, 70, 50);
    p.noStroke(); p.fill('#ff8800'); p.circle(60, 110, 40);
    p.stroke(30); p.strokeWeight(1); p.noFill(); p.square(120, 95, 40);
  }],
  modes: [220, 160, p => {
    p.background(250); p.fill(100, 150, 250, 180); p.stroke(20);
    p.rectMode(p.CENTER); p.rect(50, 40, 60, 40);
    p.rectMode(p.CORNERS); p.rect(100, 20, 150, 70);
    p.rectMode(p.RADIUS); p.rect(190, 45, 20, 25);
    p.ellipseMode(p.CORNER); p.ellipse(10, 90, 60, 50);
    p.ellipseMode(p.RADIUS); p.ellipse(120, 115, 30, 20);
    p.ellipseMode(p.CORNERS); p.ellipse(160, 90, 210, 150);
  }],
  rounded: [200, 120, p => {
    p.background(240); p.fill(250, 200, 60); p.stroke(0); p.strokeWeight(2);
    p.rect(10, 10, 80, 50, 12);
    p.rect(110, 10, 80, 50, 5, 20, 0, 30);
    p.rect(10, 70, 40, 40, 100);
    p.square(110, 70, 40, 8, 2);
  }],
  arcs: [240, 170, p => {
    p.background(230); p.fill(80, 160, 220); p.stroke(10); p.strokeWeight(3);
    p.arc(40, 40, 60, 60, 0, p.HALF_PI);
    p.arc(120, 40, 60, 60, 0, p.PI + p.QUARTER_PI, p.OPEN);
    p.arc(200, 40, 60, 40, p.PI, p.TWO_PI, p.CHORD);
    p.arc(40, 120, 60, 60, -p.HALF_PI, p.PI, p.PIE);
    p.arc(120, 120, 70, 40, 1, 5, p.PIE);
    p.angleMode(p.DEGREES); p.arc(200, 120, 60, 60, 30, 330, p.PIE);
  }],
  strokes: [240, 160, p => {
    p.background(255); p.stroke(30, 30, 120);
    p.strokeWeight(12);
    p.strokeCap(p.ROUND); p.line(20, 20, 100, 20);
    p.strokeCap(p.SQUARE); p.line(20, 50, 100, 50);
    p.strokeCap(p.PROJECT); p.line(20, 80, 100, 80);
    p.noFill(); p.strokeWeight(10);
    p.strokeJoin(p.MITER); p.triangle(130, 40, 160, 10, 190, 40);
    p.strokeJoin(p.BEVEL); p.triangle(130, 90, 160, 60, 190, 90);
    p.strokeJoin(p.ROUND); p.triangle(130, 140, 160, 110, 190, 140);
    p.strokeWeight(8); p.point(30, 130); p.strokeWeight(20); p.point(70, 130);
    p.strokeWeight(0.5); p.line(210, 10, 230, 150);
  }],
  polygons: [220, 120, p => {
    p.background(245); p.stroke(0); p.fill(200, 100, 160);
    p.triangle(10, 100, 50, 10, 90, 100);
    p.quad(110, 20, 200, 10, 210, 100, 120, 90);
  }],
  curves: [240, 160, p => {
    p.background(250); p.noFill(); p.strokeWeight(3);
    p.stroke(200, 0, 0); p.bezier(10, 140, 40, 10, 120, 10, 150, 140);
    p.stroke(0, 120, 0); p.spline(20, 20, 60, 120, 140, 30, 230, 150);
    p.splineProperty('tightness', 0.5);
    p.stroke(0, 0, 200); p.spline(20, 60, 80, 150, 160, 60, 230, 100);
    p.splineProperty('tightness', 0);
    p.splineProperty('ends', p.EXCLUDE);
    p.stroke(120, 0, 120);
    p.beginShape(); for (const [x, y] of [[0, 80], [40, 40], [100, 90], [160, 30], [220, 90], [240, 40]]) p.splineVertex(x, y); p.endShape();
  }],
  shape_kinds: [300, 200, p => {
    p.background(240); p.stroke(0); p.fill(120, 180, 240, 200);
    const pts = [[10, 10], [40, 40], [70, 10], [100, 40], [130, 10], [160, 40]];
    p.beginShape(p.POINTS); p.strokeWeight(6); for (const [x, y] of pts) p.vertex(x, y); p.endShape();
    p.strokeWeight(1);
    p.beginShape(p.LINES); for (const [x, y] of pts) p.vertex(x, y + 50); p.endShape();
    p.beginShape(p.TRIANGLES); for (const [x, y] of pts) p.vertex(x, y + 100); p.endShape();
    p.beginShape(p.TRIANGLE_STRIP); for (const [x, y] of pts) p.vertex(x + 140, y + 100); p.endShape();
    p.beginShape(p.TRIANGLE_FAN); p.vertex(230, 40); for (let i = 0; i < 6; i++) p.vertex(230 + 40 * Math.cos(i), 40 + 40 * Math.sin(i)); p.endShape();
    p.beginShape(p.QUADS); p.vertex(180, 150); p.vertex(210, 150); p.vertex(210, 190); p.vertex(180, 190); p.endShape();
    p.beginShape(p.QUAD_STRIP); for (let i = 0; i < 4; i++) { p.vertex(220 + i * 25, 150); p.vertex(220 + i * 25, 190); } p.endShape();
  }],
  contours: [220, 160, p => {
    p.background(255); p.fill(250, 180, 40); p.stroke(0); p.strokeWeight(2);
    p.beginShape();
    p.vertex(20, 20); p.vertex(200, 20); p.vertex(200, 140); p.vertex(20, 140);
    p.beginContour(); p.vertex(60, 60); p.vertex(60, 100); p.vertex(160, 100); p.vertex(160, 60); p.endContour(p.CLOSE);
    p.endShape(p.CLOSE);
    p.bezierOrder(2);
    p.beginShape(); p.vertex(20, 150); p.bezierVertex(110, 100); p.bezierVertex(200, 150); p.endShape();
  }],
  transforms: [220, 220, p => {
    p.background(230); p.fill(255, 100, 100); p.stroke(0);
    p.push(); p.translate(60, 60); p.rotate(p.QUARTER_PI); p.rect(-20, -20, 40, 40); p.pop();
    p.push(); p.translate(160, 60); p.scale(1.5, 0.7); p.ellipse(0, 0, 50, 50); p.pop();
    p.push(); p.translate(60, 160); p.shearX(0.4); p.rect(-20, -20, 40, 40); p.pop();
    p.push(); p.translate(160, 160); p.applyMatrix(1, 0.3, -0.2, 1, 0, 0); p.shearY(0.2); p.triangle(-30, 30, 0, -30, 30, 30); p.pop();
    p.rect(5, 5, 10, 10);
  }],
  color_modes: [260, 120, p => {
    p.background(255); p.noStroke();
    p.colorMode(p.HSB); for (let i = 0; i < 12; i++) { p.fill(i * 30, 80, 90); p.rect(i * 20 + 10, 10, 20, 25); }
    p.colorMode(p.HSL); for (let i = 0; i < 12; i++) { p.fill(i * 30, 70, 50); p.rect(i * 20 + 10, 40, 20, 25); }
    p.colorMode(p.RGB, 1); p.fill(0.2, 0.6, 0.4, 0.5); p.rect(10, 75, 60, 35);
    p.colorMode(p.HSB, 100); p.fill(70, 100, 100); p.rect(80, 75, 60, 35);
    p.colorMode(p.RGB); p.fill(p.lerpColor(p.color(255, 0, 0), p.color(0, 0, 255), 0.3)); p.rect(150, 75, 50, 35);
    p.fill('hsl(160, 80%, 40%)'); p.rect(205, 75, 45, 35);
  }],
  blend_erase: [200, 120, p => {
    p.background(40, 80, 160); p.noStroke();
    p.fill(255, 0, 0); p.circle(60, 60, 80);
    p.blendMode(p.ADD); p.fill(0, 200, 0); p.circle(100, 60, 80);
    p.blendMode(p.MULTIPLY); p.fill(250, 250, 0); p.circle(140, 60, 80);
    p.blendMode(p.BLEND);
    p.erase(); p.rect(80, 90, 60, 20); p.noErase();
  }],
  clipping: [200, 140, p => {
    p.background(255); p.noStroke();
    p.push(); p.clip(() => { p.circle(60, 70, 100); });
    for (let i = 0; i < 12; i++) { p.fill(i % 2 ? 200 : 60, 100, 160); p.rect(i * 10, 0, 10, 140); }
    p.pop();
    p.push(); p.clip(() => { p.rect(130, 30, 50, 80); }, { invert: true });
    p.fill(250, 120, 0); p.circle(155, 70, 70);
    p.pop();
  }],
  text_basic: [260, 160, p => {
    p.background(250); p.fill(20);
    p.textSize(20); p.text('Hello p5', 10, 30);
    p.textStyle(p.BOLD); p.textFont('Georgia'); p.text('Bold Georgia', 10, 60);
    p.textStyle(p.ITALIC); p.textSize(16); p.text('italic 16px', 10, 85);
    p.textStyle(p.NORMAL); p.textFont('monospace'); p.textSize(14);
    p.text('multi\nline text', 10, 110);
    p.fill(200, 0, 0); p.stroke(0, 0, 255); p.strokeWeight(1); p.textSize(28); p.text('Stroke', 150, 40);
  }],
  text_align: [260, 200, p => {
    p.background(255); p.stroke(200); p.line(130, 0, 130, 200); p.line(0, 50, 260, 50); p.line(0, 120, 260, 120);
    p.noStroke(); p.fill(0); p.textSize(18);
    p.textAlign(p.LEFT, p.TOP); p.text('left top', 130, 50);
    p.textAlign(p.RIGHT, p.BOTTOM); p.text('right bottom', 130, 50);
    p.textAlign(p.CENTER, p.CENTER); p.text('center\ncenter', 130, 120);
    p.textAlign(p.LEFT, p.BASELINE); p.text('baseline', 10, 180);
    p.textAlign(p.RIGHT, p.CENTER); p.text('right', 250, 180);
  }],
  text_box: [260, 200, p => {
    p.background(255); p.noFill(); p.stroke(180); p.rect(20, 20, 140, 90); p.rect(170, 20, 80, 160);
    p.noStroke(); p.fill(0); p.textSize(15); p.textLeading(19);
    p.text('The quick brown fox jumps over the lazy dog again and again', 20, 20, 140, 90);
    p.textAlign(p.CENTER, p.CENTER); p.textWrap(p.CHAR);
    p.text('characterwrappingdemo text', 170, 20, 80, 160);
    p.textAlign(p.RIGHT, p.BOTTOM); p.textWrap(p.WORD); p.rectMode(p.CENTER);
    p.text('right bottom box', 90, 160, 140, 60);
  }],
  text_metrics: [300, 120, p => {
    p.background(255); p.textSize(22); p.fill(0); p.noStroke();
    const s = 'Measure gyp';
    p.text(s, 20, 50);
    const b = p.textBounds(s, 20, 50); p.noFill(); p.stroke(255, 0, 0); p.rect(b.x, b.y, b.w, b.h);
    const f = p.fontBounds(s, 20, 90); p.stroke(0, 0, 255); p.rect(f.x, f.y, f.w, f.h);
    p.stroke(0, 150, 0); p.line(20, 100, 20 + p.textWidth(s), 100); p.line(20, 106, 20 + p.fontWidth(s), 106);
    p.line(250, 50 - p.textAscent(), 250, 50 + p.textDescent());
    p.line(260, 50 - p.textAscent('gyp'), 260, 50 + p.textDescent('gyp'));
  }],
  random_noise: [200, 200, p => {
    p.background(20); p.randomSeed(42); p.noiseSeed(7); p.noStroke();
    for (let i = 0; i < 300; i++) { p.fill(p.random(255), p.random(100, 255), 200); p.circle(p.random(200), p.random(200), p.random(2, 8)); }
    p.stroke(255, 200, 0); p.noFill(); p.beginShape();
    for (let x = 0; x <= 200; x += 4) p.vertex(x, 100 + 80 * (p.noise(x * 0.02) - 0.5));
    p.endShape();
    p.stroke(0, 220, 255); for (let i = 0; i < 40; i++) p.point(100 + p.randomGaussian(0, 30), 160 + p.randomGaussian(0, 10));
  }],
  vectors_trig: [200, 200, p => {
    p.background(250); p.angleMode(p.DEGREES); p.stroke(0); p.noFill();
    for (let a = 0; a < 360; a += 15) {
      const v = p5.Vector.fromAngle(p.radians(a), 60 + 20 * p.sin(a * 3));
      p.line(100, 100, 100 + v.x, 100 + v.y);
    }
    const w = p.createVector(30, 40); w.setMag(70); w.rotate(20);
    p.stroke(255, 0, 0); p.strokeWeight(3); p.line(100, 100, 100 + w.x, 100 + w.y);
    p.text(p.nf(p.atan2(1, 1), 2, 2), 10, 190);
  }],
  pixels: [100, 80, p => {
    p.background(255, 0, 0); p.loadPixels();
    const d = p.pixelDensity();
    for (let y = 0; y < p.height * d; y++) for (let x = 0; x < p.width * d; x++) {
      const i = 4 * (y * p.width * d + x);
      p.pixels[i] = x * 2; p.pixels[i + 1] = y * 3; p.pixels[i + 2] = 128; p.pixels[i + 3] = 255;
    }
    p.updatePixels();
    p.set(10, 10, p.color(255)); p.set(11, 10, p.color(255)); p.updatePixels();
    const c = p.get(50, 40); p.fill(c); p.noStroke(); p.rect(60, 50, 30, 20);
  }],
  gif_frames: [300, 160, (p, img) => {
    p.background(255); img.pause();
    p.image(img, 0, 0);
    img.setFrame(5); p.image(img, 100, 0);
    img.setFrame(11); p.image(img, 200, 0, 48, 36);
    p.fill(0); p.noStroke(); p.textSize(14);
    p.text(img.numFrames() + ' frames, now ' + img.getCurrentFrame(), 10, 110);
  }, async p => await p.loadImage('../examples/assets/testcard.gif')],
  copy_blend: [240, 160, p => {
    p.background(240); p.noStroke();
    for (let i = 0; i < 6; i++) { p.fill(i * 40, 120, 255 - i * 40); p.circle(15 + i * 8, 25, 30); }
    p.copy(0, 0, 80, 50, 100, 0, 140, 90);
    p.fill(250, 200, 0); p.rect(0, 100, 240, 60);
    p.blend(0, 0, 80, 50, 20, 105, 80, 50, p.MULTIPLY);
    p.blend(0, 0, 80, 50, 130, 105, 80, 50, p.DIFFERENCE);
  }],
  image_modes: [240, 160, p => {
    p.background(255);
    const img = p.createImage(40, 30); img.loadPixels();
    for (let y = 0; y < 30; y++) for (let x = 0; x < 40; x++) {
      const i = 4 * (y * 40 + x); img.pixels[i] = x * 6; img.pixels[i + 1] = y * 8; img.pixels[i + 2] = 200; img.pixels[i + 3] = 255;
    }
    img.updatePixels();
    p.image(img, 5, 5);
    p.imageMode(p.CENTER); p.image(img, 120, 40, 80, 60);
    p.imageMode(p.CORNERS); p.image(img, 170, 10, 230, 70);
    p.imageMode(p.CORNER); p.tint(255, 120, 120); p.image(img, 5, 90, 60, 45);
    p.tint(255, 128); p.image(img, 80, 90, 60, 45);
    p.noTint(); p.image(img, 150, 90, 80, 60, 10, 5, 20, 15);
  }],
  filter_gray: [120, 90, p => { gradientScene(p); p.filter(p.GRAY, false); }],
  filter_invert: [120, 90, p => { gradientScene(p); p.filter(p.INVERT, false); }],
  filter_threshold: [120, 90, p => { gradientScene(p); p.filter(p.THRESHOLD, 0.4, false); }],
  filter_posterize: [120, 90, p => { gradientScene(p); p.filter(p.POSTERIZE, 3, false); }],
  filter_erode: [120, 90, p => { gradientScene(p); p.filter(p.ERODE, false); }],
  filter_dilate: [120, 90, p => { gradientScene(p); p.filter(p.DILATE, false); }],
  filter_blur: [120, 90, p => { gradientScene(p); p.filter(p.BLUR, 3, false); }],
  svg_import: [240, 160, (p, rec) => { p.background(255); p.shape(rec, 0, 0); },
    async p => await p.loadSVG('../examples/assets/shapes.svg')],
  font_points: [260, 120, (p, font) => {
    p.background(255); p.noStroke(); p.fill(0); p.textSize(64);
    for (const q of font.textToPoints('p5*js', 10, 80, { sampleFactor: 0.3 })) p.circle(q.x, q.y, 3);
  }, async p => await p.loadFont('../examples/assets/Inconsolata-Bold.ttf')],
  font_text: [260, 120, (p, font) => {
    p.background(250); p.fill(20, 40, 120); p.textFont(font, 40); p.text('Typography', 10, 50);
    p.textSize(20); p.textAlign(p.CENTER); p.text('centred in a box that wraps', 20, 70, 220);
  }, async p => await p.loadFont('../examples/assets/SourceSansPro-Regular.otf')],
  svg_replay: [220, 160, p => {
    p.background(250);
    const rec = p.buildShape(() => {
      p.fill(255, 0, 100); p.stroke(0); p.strokeWeight(2); p.circle(50, 50, 60);
      p.noStroke(); p.fill(0, 120, 255); p.rect(80, 30, 60, 40);
    });
    p.shape(rec, 0, 0);
    p.shape(rec, 60, 80, { scale: 0.6 });
  }],
};

function checker(p) {
  const img = p.createImage(32, 32); img.loadPixels();
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    const i = 4 * (y * 32 + x), on = ((x >> 2) + (y >> 2)) % 2;
    img.pixels[i] = on ? 250 : 40; img.pixels[i + 1] = x * 8; img.pixels[i + 2] = y * 8; img.pixels[i + 3] = 255;
  }
  img.updatePixels();
  return img;
}

export const glCases = {
  gl_framebuffer: [260, 180, p => {
    const fb = p.createFramebuffer({ width: 120, height: 90 });
    fb.draw(() => {
      p.background(40, 60, 120); p.noStroke(); p.lights();
      p.rotateX(0.6); p.rotateY(0.8); p.fill(250, 180, 60); p.box(45);
    });
    const small = p.createFramebuffer({ width: 64, height: 64, antialias: false });
    small.draw(() => { p.clear(); p.fill(255, 60, 120); p.noStroke(); p.circle(0, 0, 50); });
    p.background(230);
    p.image(fb, -125, -85);
    p.push(); p.translate(65, -20); p.rotateY(0.5); p.texture(fb); p.noStroke(); p.plane(110, 80); p.pop();
    p.image(small, -60, 20, 64, 64);
    p.push(); p.translate(70, 55); p.texture(small); p.noStroke(); p.sphere(30); p.pop();
  }],
  gl_textures: [280, 200, p => {
    const img = checker(p);
    p.background(200); p.noStroke();
    p.push(); p.translate(-90, -40); p.rotateX(0.5); p.rotateY(0.7); p.texture(img); p.box(60); p.pop();
    p.push(); p.translate(0, -40); p.texture(img); p.sphere(35); p.pop();
    p.push(); p.translate(90, -40); p.textureMode(p.NORMAL); p.textureWrap(p.REPEAT); p.texture(img);
    p.beginShape(); p.vertex(-40, -30, 0, 0, 0); p.vertex(40, -30, 0, 3, 0); p.vertex(40, 30, 0, 3, 2); p.vertex(-40, 30, 0, 0, 2); p.endShape(p.CLOSE); p.pop();
    p.image(img, -130, 30, 60, 60);
    p.tint(255, 120, 120); p.image(img, -60, 30, 60, 60, 8, 8, 16, 16);
    p.noTint(); p.push(); p.translate(70, 60); p.texture(img); p.textureMode(p.IMAGE); p.ellipse(0, 0, 70, 50); p.pop();
  }],
  gl_shader: [240, 160, p => {
    const img = checker(p);
    const sh = p.createShader(`
precision highp float;
attribute vec3 aPosition; attribute vec2 aTexCoord;
uniform mat4 uModelViewMatrix; uniform mat4 uProjectionMatrix;
varying vec2 vUv;
void main() { vUv = aTexCoord; gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0); }`, `
precision highp float;
varying vec2 vUv; uniform float uMix; uniform vec3 uTint; uniform sampler2D uTex;
void main() { vec4 t = texture2D(uTex, vUv); gl_FragColor = vec4(mix(t.rgb, uTint * vUv.x, uMix), 1.0); }`);
    p.background(30); p.noStroke();
    p.shader(sh); sh.setUniform('uMix', 0.4); sh.setUniform('uTint', [1.0, 0.5, 0.2]); sh.setUniform('uTex', img);
    p.push(); p.translate(-60, 0); p.rotateY(0.6); p.box(70); p.pop();
    p.push(); p.translate(60, 0); p.sphere(45); p.pop();
    p.resetShader(); p.fill(255); p.circle(0, 60, 20);
  }],
  gl_2d: [280, 200, p => {
    p.background(250); p.translate(-140, -100); p.stroke(20); p.strokeWeight(3); p.fill(240, 120, 60);
    p.rect(10, 10, 60, 40); p.rect(80, 10, 60, 40, 12); p.ellipse(190, 30, 60, 40);
    p.arc(250, 30, 40, 40, 0, p.PI * 1.3, p.PIE);
    p.arc(40, 90, 50, 40, 0.3, 4, p.CHORD); p.noFill(); p.arc(100, 90, 50, 40, 0.3, 4, p.OPEN);
    p.fill(60, 160, 220); p.arc(160, 90, 50, 40, 1, 5);
    p.triangle(200, 70, 270, 80, 220, 120);
    p.quad(10, 130, 70, 125, 80, 190, 20, 180);
    p.strokeWeight(6); p.line(100, 130, 160, 190); p.point(180, 140); p.strokeCap(p.SQUARE); p.point(200, 140);
    p.strokeWeight(2); p.noFill(); p.bezier(180, 190, 200, 120, 260, 200, 270, 150);
  }],
  gl_shapes: [280, 200, p => {
    p.background(240); p.translate(-140, -100); p.stroke(0); p.strokeWeight(2);
    p.fill(250, 200, 0);
    p.beginShape(); p.vertex(20, 20); p.vertex(120, 20); p.vertex(120, 90); p.vertex(20, 90);
    p.beginContour(); p.vertex(50, 40); p.vertex(50, 70); p.vertex(90, 70); p.vertex(90, 40); p.endContour(p.CLOSE);
    p.endShape(p.CLOSE);
    p.fill(200, 40, 120);
    p.beginShape();
    for (let i = 0; i < 5; i++) { const a = -p.HALF_PI + i * p.TWO_PI * 2 / 5; p.vertex(200 + 50 * Math.cos(a), 60 + 50 * Math.sin(a)); }
    p.endShape(p.CLOSE);
    p.beginShape(p.TRIANGLES); p.fill(255, 0, 0); p.vertex(20, 120); p.fill(0, 255, 0); p.vertex(80, 120); p.fill(0, 0, 255); p.vertex(50, 180); p.endShape();
    p.fill(120, 200, 255);
    p.beginShape(p.QUAD_STRIP); p.vertex(100, 120); p.vertex(100, 180); p.vertex(140, 130); p.vertex(140, 170); p.vertex(180, 120); p.vertex(180, 190); p.endShape();
    p.fill(100, 220, 100); p.beginShape(); p.vertex(200, 120); p.bezierVertex(280, 110); p.bezierVertex(260, 200); p.bezierVertex(210, 190); p.endShape(p.CLOSE);
  }],
  gl_primitives: [260, 200, p => {
    p.background(220); p.fill(200, 100, 50); p.stroke(0);
    p.push(); p.translate(-80, -45); p.rotateX(0.5); p.rotateY(0.6); p.box(50); p.pop();
    p.push(); p.translate(0, -45); p.sphere(32); p.pop();
    p.push(); p.translate(85, -45); p.rotateX(1); p.cylinder(22, 50); p.pop();
    p.push(); p.translate(-80, 50); p.rotateX(0.7); p.cone(25, 50); p.pop();
    p.push(); p.translate(0, 50); p.rotateX(1.1); p.torus(28, 9); p.pop();
    p.push(); p.translate(85, 50); p.rotateY(0.8); p.normalMaterial(); p.ellipsoid(32, 22, 16); p.pop();
  }],
  gl_lights: [260, 200, p => {
    p.background(25); p.noStroke();
    p.ambientLight(50); p.directionalLight(255, 255, 255, 0.3, 0.5, -1);
    p.pointLight(255, 0, 0, 100, -100, 100);
    p.push(); p.translate(-70, 0); p.fill(255); p.specularMaterial(250); p.shininess(20); p.sphere(55); p.pop();
    p.push(); p.translate(70, 0); p.rotateX(0.6); p.rotateY(0.4); p.fill(60, 140, 255); p.ambientMaterial(100, 200, 50); p.box(70); p.pop();
    p.push(); p.translate(0, 75); p.emissiveMaterial(40, 0, 60); p.fill(200); p.torus(30, 8); p.pop();
  }],
  gl_camera: [260, 200, p => {
    p.background(240); p.stroke(30); p.strokeWeight(2); p.fill(250, 200, 0);
    p.camera(150, -120, 260, 0, 0, 0, 0, 1, 0);
    p.perspective(p.PI / 4, 260 / 200, 10, 2000);
    p.box(80); p.translate(90, 0, -60); p.fill(0, 150, 200); p.sphere(30, 12, 8);
    p.translate(-180, 0, 120); p.ortho(); p.fill(220, 60, 90); p.cone(30, 60);
  }],
};

export const dataCases = {
  font_points_ttf: ['Inconsolata-Bold.ttf', (p, f) => {
    p.textSize(48);
    return f.textToPoints('p5*js', 10, 70, { sampleFactor: 0.3 }).map(q => [q.x, q.y, q.angle]);
  }],
  font_contours_otf: ['SourceSansPro-Regular.otf', (p, f) => {
    p.textSize(30); p.textAlign(p.CENTER); p.rectMode(p.CENTER); p.angleMode(p.DEGREES);
    return f.textToContours('Hello brave new\nworld', 120, 70, 200, 120,
      { sampleFactor: 0.2, simplifyThreshold: 0.05 }).map(c => c.map(q => [q.x, q.y, q.angle]));
  }],
  font_paths_woff: ['Lato-Regular.woff', (p, f) => {
    p.textSize(36);
    return f.textToPaths('Quiz&', 5, 60);
  }],
};

export const svgCases = {
  svg_export_shapes: [220, 160, p => {
    p.background(240); p.stroke(20); p.strokeWeight(3); p.fill(255, 120, 80);
    p.rect(10, 10, 60, 40, 8); p.ellipse(120, 30, 70, 40);
    p.noFill(); p.stroke(30, 90, 200); p.bezier(10, 150, 40, 70, 120, 150, 150, 80);
    p.fill(80, 200, 120, 180); p.noStroke(); p.triangle(160, 150, 190, 90, 215, 150);
    p.push(); p.translate(60, 110); p.rotate(0.4); p.fill(120, 60, 200); p.rect(-15, -10, 30, 20); p.pop();
  }],
  svg_export_arcs: [200, 120, p => {
    p.background(255); p.stroke(0); p.strokeWeight(2); p.fill(250, 200, 0);
    p.arc(40, 40, 60, 60, 0, p.HALF_PI, p.PIE); p.arc(110, 40, 60, 40, 0.5, 4, p.CHORD);
    p.noFill(); p.arc(170, 40, 50, 50, p.PI, p.TWO_PI);
    p.beginShape(); p.vertex(10, 110); p.vertex(60, 80); p.vertex(110, 110); p.endShape(p.CLOSE);
  }],
};

function gradientScene(p) {
  p.background(30, 60, 90); p.noStroke();
  for (let i = 0; i < 10; i++) { p.fill(25 * i, 255 - 20 * i, 120); p.circle(10 + i * 11, 45 + 25 * Math.sin(i), 26); }
  p.fill(255); p.rect(80, 10, 30, 12);
}
