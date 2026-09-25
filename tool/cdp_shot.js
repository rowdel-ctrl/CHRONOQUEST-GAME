// Scripted CDP driver for playtesting the web build without a person at the
// keyboard: forces an exact viewport, then runs a list of steps (wait, click,
// screenshot). Chrome's own --headless --screenshot captures the Flutter
// loading bar instead of the game (the debug build pulls ~660 script files),
// so this connects over the DevTools protocol and works in real time.
//
// Usage:
//   node tool/cdp_shot.js --viewport 873x393 --steps "wait:30;shot:a.png;click:520,190;wait:0.3;shot:b.png"
//   node tool/cdp_shot.js --port 8124 --steps "..."   # a build served on a different port, see below
//
// Steps, separated by ';':
//   wait:<seconds>       sleep (fractions allowed)
//   click:<x>,<y>        left click at viewport coordinates
//   scroll:<x>,<y>,<dy>  mouse wheel at x,y by dy pixels (positive = down)
//   nav:<url>            navigate the page (hash routes, e.g. .../#/game/spanish/1)
//   shot:<file.png>      save a screenshot
//   console:<file.txt>   dump everything logged/printed so far to a file
//   clearconsole         forget everything captured so far (start a fresh log)
//
// `nav` exists because some screens can't be reached by clicking: the era
// background/history page only reveals its continue button after you scroll to
// the bottom, and Flutter's web engine ignores the synthetic wheel events the
// `scroll` step sends. Navigating straight to the route skips that gate. Hive
// state (selected character, progress) persists across a nav within the same
// browser profile, so click through character selection first.
//
// `console`/`clearconsole` exist for reading Dart `debugPrint`/`print` output
// back out — e.g. a temporary debug line revealing a shuffled quiz question's
// correct-answer letter, so a scripted playthrough can click the right button
// without knowing the answer in advance. Capture starts as soon as this
// script connects and persists across steps within one run; console output
// from *before* this script connected (an earlier `nav` in a previous
// invocation, for instance) is not retroactively visible — reconnect right
// after the `nav` you care about if you need everything.
//
// --viewport WxH overrides the viewport via Emulation.setDeviceMetricsOverride,
// the only reliable way to get exact dimensions: Chrome's --window-size
// includes browser chrome and does not map 1:1 to the viewport. The override
// lasts only while this script is connected.
//
// --port N looks for a page on that port instead of :8123 — for a static
// `flutter build web` bundle served with any plain static file server rather
// than `flutter run -d web-server`. Worth doing for anything longer than a
// quick screenshot: no DWDS, so no compiled-module caching gotcha (see below)
// and no periodic self-reload wiping game state mid-script.
//
// Requires Chrome already running with --remote-debugging-port=9222 and the
// game served on the target port. Node 22+ (uses the global WebSocket).
//
// This script always brings its target tab to the OS foreground
// (Page.bringToFront) before running any steps: Chrome throttles
// requestAnimationFrame for an occluded/background tab, which silently
// freezes Flame's game loop (dt stops advancing, no error) — indistinguishable
// from a real hang without this. If the browser window itself isn't the
// foreground *OS* window (e.g. it was launched detached, or another window
// has focus), CDP's bringToFront alone is not enough; also raise the actual
// window (PowerShell `SetForegroundWindow`) before a run with waits longer
// than a few seconds.
//
// `flutter run -d web-server` (no Dart Debug Chrome extension installed)
// periodically reloads the page on its own — roughly every 20-30s — while it
// keeps retrying the debug-service handshake that extension would answer.
// A `shot` step landing mid-reload comes back black with a bare HUD (canvas
// cleared, Flame not yet re-mounted); a `wait` step spanning one looks like
// the game froze. Neither is a real bug — just bad luck on timing. If a
// screenshot looks wrong, retake it before trusting it. Point at a static
// build (`--port`, see above) instead for anything long enough that this
// would matter.

const fs = require('fs');

const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};

const port = Number(opt('port') || 8123);
const viewport = opt('viewport');
const steps = (opt('steps') ?? '').split(';').map((s) => s.trim()).filter(Boolean);

if (steps.length === 0) {
  console.error('Usage: node tool/cdp_shot.js [--viewport WxH] [--port N] --steps "wait:5;shot:out.png"');
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
  const page = targets.find((t) => t.type === 'page' && t.url.includes(`:${port}`));
  if (!page) {
    console.error(`No page target on :${port}. Targets:`, targets.map((t) => t.url));
    process.exit(1);
  }

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener('open', r, { once: true }));
  const send = rpc(ws);

  const consoleLog = [];
  ws.addEventListener('message', (ev) => {
    const m = JSON.parse(ev.data);
    if (m.method === 'Runtime.consoleAPICalled') {
      const text = m.params.args.map((a) => a.value ?? a.description ?? '').join(' ');
      if (text.trim()) consoleLog.push(text);
    }
    if (m.method === 'Runtime.exceptionThrown') {
      const d = m.params.exceptionDetails;
      consoleLog.push(`[EXCEPTION] ${d.text} ${d.exception?.description ?? ''}`);
    }
  });
  await send('Runtime.enable');

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

  // See the file header: an occluded tab silently stalls Flame's game loop.
  await send('Page.bringToFront');

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
    } else if (name === 'console') {
      fs.writeFileSync(arg, consoleLog.join('\n'));
      console.log(`wrote console log (${consoleLog.length} lines) to ${arg}`);
    } else if (name === 'clearconsole') {
      consoleLog.length = 0;
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
