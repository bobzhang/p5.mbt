// Screenshots of single moments: node p5_demos/agents/tools/stills.cjs 3 10 20 ...
const path = require('path');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || '/Users/dii/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true });
  const out = process.env.OUT || path.join(__dirname, '..', 'output', 'stills');
  require('fs').mkdirSync(out, { recursive: true });
  try {
    for (const t of process.argv.slice(2)) {
      const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
      page.on('pageerror', e => console.error(`t=${t}:`, e.message));
      page.on('console', m => { if (m.type() === 'error') console.error(`t=${t}:`, m.text()); });
      await page.goto('file://' + path.join(__dirname, '..', 'index.html') + `?t=${t}&still`);
      await page.waitForSelector('canvas');
      await page.waitForTimeout(250);
      await page.locator('canvas').screenshot({ path: `${out}/t${t}.png` });
      await page.close();
    }
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exit(1); });
