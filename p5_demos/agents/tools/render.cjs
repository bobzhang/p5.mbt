// Records the film with p5.mbt's own `p.record()` and encodes it to MP4.
//
//   node p5_demos/agents/tools/render.cjs [out.mp4]
//
// A tiny local server serves the page; the sketch (opened with ?record)
// renders every frame at a fixed time step and POSTs it as a PNG to /frame,
// which is piped straight into ffmpeg. The film is silent.
const fs = require('fs'), path = require('path'), http = require('http');
const { spawn } = require('child_process');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || '/Users/dii/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const FFMPEG = process.env.FFMPEG || '/Users/dii/git/video/node_modules/@remotion/compositor-darwin-arm64/ffmpeg';
const ROOT = path.resolve(__dirname, '..'); // the demo
const REPO = path.resolve(ROOT, '..', '..'); // served, so ../../_build resolves
const OUT = path.resolve(process.argv[2] || path.join(ROOT, 'output', 'made-in-moonbit.mp4'));
const FPS = 30;

// Refuse to record unless every MoonBit snippet on screen is verified code.
require('child_process').execFileSync('python3', [path.join(ROOT, 'tools', 'check_snippets.py')], { stdio: 'inherit' });

const types = { '.html': 'text/html', '.js': 'text/javascript', '.wav': 'audio/wav', '.png': 'image/png' };

function startEncoder() {
  const args = ['-y', '-v', 'error', '-f', 'image2pipe', '-c:v', 'png', '-framerate', String(FPS), '-i', 'pipe:0'];
  args.push('-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p',
    '-metadata', 'title=Made in MoonBit', '-movflags', '+faststart', OUT);
  return spawn(FFMPEG, args, { env: { ...process.env, DYLD_LIBRARY_PATH: path.dirname(FFMPEG) }, stdio: ['pipe', 'inherit', 'inherit'] });
}

(async () => {
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  const ffmpeg = startEncoder();
  const ffmpegDone = new Promise((res, rej) => ffmpeg.on('close', c => c === 0 ? res() : rej(new Error('ffmpeg exited ' + c))));
  let expected = 0, finished, t0 = Date.now();
  const done = new Promise(r => finished = r);
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    if (req.method === 'POST') {
      const chunks = [];
      req.on('data', c => chunks.push(c));
      req.on('end', () => {
        if (url.pathname.endsWith('/done')) { res.end('done'); finished(); return; }
        const i = Number(url.searchParams.get('frame'));
        if (i !== expected) { res.writeHead(400); res.end(`expected ${expected}, got ${i}`); return; }
        expected++;
        const ok = ffmpeg.stdin.write(Buffer.concat(chunks));
        const reply = () => res.end('ok');
        ok ? reply() : ffmpeg.stdin.once('drain', reply);
        if (expected % 300 === 0) console.log(`  ${expected} frames (${(expected / ((Date.now() - t0) / 1000)).toFixed(1)} fps)`);
      });
      return;
    }
    const file = path.join(REPO, decodeURIComponent(url.pathname));
    if (!file.startsWith(REPO) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
    page.on('pageerror', e => { console.error('page error:', e.message); process.exitCode = 1; });
    page.on('console', m => { if (m.type() === 'error' || m.text().includes('p5.mbt')) console.log('page:', m.text()); });
    console.log(`recording http://127.0.0.1:${port}/p5_demos/agents/index.html?record -> ${OUT}`);
    await page.goto(`http://127.0.0.1:${port}/p5_demos/agents/index.html?record`);
    await done;
  } finally {
    await browser.close();
    server.close();
  }
  ffmpeg.stdin.end();
  await ffmpegDone;
  console.log(`wrote ${expected} frames in ${((Date.now() - t0) / 1000).toFixed(0)} s -> ${OUT}`);
})().catch(e => { console.error(e); process.exit(1); });
