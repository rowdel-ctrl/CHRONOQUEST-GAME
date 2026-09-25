// Scripted CDP driver for playtesting the web build without a person at the
// keyboard: forces an exact viewport, then runs a list of steps (wait, click,
// screenshot). Chrome's own --headless --screenshot captures the Flutter
// loading bar instead of the game (the debug build pulls ~660 script files),
// so this connects over the DevTools protocol and works in real time.
//
// Usage:
//   node tool/cdp_shot.js --viewport 873x393 --steps "wait:30;shot:a.png;click:520,190;wait:0.3;shot:b.png"
//
// Steps, separated by ';':
//   wait:<seconds>       sleep (fractions allowed)
//   click:<x>,<y>        left click at viewport coordinates
//   scroll:<x>,<y>,<dy>  mouse wheel at x,y by dy pixels (positive = down)
//   nav:<url>            navigate the page (hash routes, e.g. .../#/game/spanish/1)
//   shot:<file.png>      save a screenshot
//
// `nav` exists because some screens can't be reached by clicking: the era
// background/history page only reveals its continue button after you scroll to
// the bottom, and Flutter's web engine ignores the synthetic wheel events the
// `scroll` step sends. Navigating straight to the route skips that gate. Hive
// state (selected character, progress) persists across a nav within the same
// browser profile, so click through character selection first.
//
// --viewport WxH overrides the viewport via Emulation.setDeviceMetricsOverride,
// the only reliable way to get exact dimensions: Chrome's --window-size
// includes browser chrome and does not map 1:1 to the viewport. The override
// lasts only while this script is connected.
//
// Requires Chrome already running with --remote-debugging-port=9222 and the
// game served on :8123. Node 22+ (uses the global WebSocket).
//
// `flutter run -d web-server` (no Dart Debug Chrome extension installed)
// periodically reloads the page on its own — roughly every 20-30s — while it
// keeps retrying the debug-service handshake that extension would answer.
// A `shot` step landing mid-reload comes back black with a bare HUD (canvas
// cleared, Flame not yet re-mounted); a `wait` step spanning one looks like
// the game froze. Neither is a real bug — just bad luck on timing. If a
// screenshot looks wrong, retake it before trusting it.

const fs = require('fs');

const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};

const viewport = opt('viewport');
const steps = (opt('steps') ?? '').split(';').map((s) => s.trim()).filter(Boolean);

if (steps.length === 0) {
  console.error('Usage: node tool/cdp_shot.js [--viewport WxH] --steps "wait:5;shot:out.png"');
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function rpc(ws) {
  let id = 0;
  const pending = new Map();
  ws.addEventListener('message', (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
    }
  });
  return (method, params = {}) =>
    new Promise((resolve, reject) => {
      const myId = ++id;
      pending.set(myId, { resolve, reject });
      ws.send(JSON.stringify({ id: myId, method, params }));
    });
}

(async () => {
  const targets = await (await fetch('http://localhost:9222/json')).json();
  const page = targets.find((t) => t.type === 'page' && t.url.includes('8123'));
  if (!page) {
    console.error('No page target on :8123. Targets:', targets.map((t) => t.url));
    process.exit(1);
  }

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r, { once: true }));
  const send = rpc(ws);

  // Chrome's HTTP cache happily serves compiled DDC module JS left over from
  // a *previous* `flutter run` process, keyed by URL only — restarting the
  // dev server does not change those URLs or invalidate the cache. A `nav`
  // step can then boot a Frankenstein bundle: some modules fresh, others
  // stale, which produced nonsense game state (e.g. a `size`/`groundY`
  // mismatch that looked like the player fell through the floor at t=0) when
  // debugging a dev-server restart. Always disabled, since a stale module is
  // strictly worse than the small extra load time from a real fetch.
  await send('Network.enable');
  await send('Network.setCacheDisabled', { cacheDisabled: true });

  if (viewport) {
    const [width, height] = viewport.split('x').map(Number);
    await send('Emulation.setDeviceMetricsOverride', {
      width, height, deviceScaleFactor: 1, mobile: false,
    });
    console.log(`viewport forced to ${width}x${height}`);
  }

  for (const step of steps) {
    const sep = step.indexOf(':');
    const name = step.slice(0, sep);
    const arg = step.slice(sep + 1);

    if (name === 'wait') {
      console.log(`wait ${arg}s`);
      await sleep(Number(arg) * 1000);
    } else if (name === 'click') {
      const [x, y] = arg.split(',').map(Number);
      for (const type of ['mousePressed', 'mouseReleased']) {
        await send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
      }
      console.log(`click ${x},${y}`);
    } else if (name === 'scroll') {
      const [x, y, deltaY] = arg.split(',').map(Number);
      await send('Input.dispatchMouseEvent', {
        type: 'mouseWheel', x, y, deltaX: 0, deltaY,
      });
      console.log(`scroll ${deltaY} at ${x},${y}`);
    } else if (name === 'nav') {
      await send('Page.navigate', { url: arg });
      console.log(`nav ${arg}`);
    } else if (name === 'shot') {
      const { data } = await send('Page.captureScreenshot', { format: 'png' });
      fs.writeFileSync(arg, Buffer.from(data, 'base64'));
      console.log(`wrote ${arg}`);
    } else {
      console.error(`unknown step: ${step}`);
      process.exit(1);
    }
  }

  ws.close();
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
