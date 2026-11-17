#!/usr/bin/env node
// Talk to the sandboxed T3 Code over the Chrome DevTools Protocol. No dependencies:
// Node's built-in fetch and WebSocket.
//
//   cdp.mjs eval '<js expression>'            print the JSON result
//   cdp.mjs wait '<js expression>' [seconds]  poll until truthy (default 20s), print it
//   cdp.mjs shot <file.png>                   screenshot the app window
//   cdp.mjs click '<text or aria-label>'      real mouse click on the first visible match
//                                             (whole text, its first line, or aria-label)
//   cdp.mjs type '<text>'                     type into the focused field
//   cdp.mjs key <Enter|Escape|Tab|Backspace>  press one key
//
// The port comes from T3V_PORT (set by the verify CLI). T3V_VIEWPORT=<width>x<height>
// lays the app out at that size for this one command, as a smaller window would.
const port = process.env.T3V_PORT || "9339";
const [command, arg, extra] = process.argv.slice(2);

// The app window takes a few seconds to appear after CDP starts answering.
async function page() {
  const deadline = Date.now() + 30000;
  for (;;) {
    const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json().catch(() => []);
    const target = list.find((t) => t.type === "page" && t.url.startsWith("t3code://"));
    if (target) return target.webSocketDebuggerUrl;
    if (Date.now() > deadline) throw new Error(`no t3code:// page on port ${port}`);
    await new Promise((r) => setTimeout(r, 250));
  }
}

async function session() {
  const socket = new WebSocket(await page());
  await new Promise((resolve, reject) => {
    socket.onopen = resolve;
    socket.onerror = () => reject(new Error("CDP websocket failed"));
  });
  let id = 0;
  const pending = new Map();
  socket.onmessage = (event) => {
    const message = JSON.parse(event.data);
    if (pending.has(message.id)) {
      pending.get(message.id)(message);
      pending.delete(message.id);
    }
  };
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      pending.set(++id, (m) => (m.error ? reject(new Error(m.error.message)) : resolve(m.result)));
      socket.send(JSON.stringify({ id, method, params }));
    });
  return { send, close: () => socket.close() };
}

async function evaluate(cdp, expression) {
  const { result, exceptionDetails } = await cdp.send("Runtime.evaluate", {
    expression, returnByValue: true, awaitPromise: true,
  });
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description || exceptionDetails.text);
  return result.value;
}

let cdp;
try {
  cdp = await session();
  if (process.env.T3V_VIEWPORT) {
    const [width, height] = process.env.T3V_VIEWPORT.split("x").map(Number);
    await cdp.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 0, mobile: false });
    await new Promise((r) => setTimeout(r, 600));
  }
  if (command === "eval") {
    console.log(JSON.stringify(await evaluate(cdp, arg), null, 2));
  } else if (command === "wait") {
    const deadline = Date.now() + Number(extra || 20) * 1000;
    let value;
    while (!(value = await evaluate(cdp, arg).catch(() => undefined))) {
      if (Date.now() > deadline) throw new Error(`timed out waiting for: ${arg}`);
      await new Promise((r) => setTimeout(r, 250));
    }
    console.log(JSON.stringify(value, null, 2));
  } else if (command === "click") {
    const box = await evaluate(cdp, `(() => {
      const want = ${JSON.stringify(arg)};
      const nodes = [...document.querySelectorAll("button, a, [role=button], [role=menuitem], [role=option], [role=tab], [cmdk-item]")];
      const named = (n) => {
        const text = (n.innerText || "").trim();
        return text === want || text.split("\\n")[0].trim() === want || n.getAttribute("aria-label") === want;
      };
      const hit = nodes.find((n) => {
        const r = n.getBoundingClientRect();
        return r.width && r.height && named(n);
      });
      if (!hit) return null;
      const r = hit.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    })()`);
    if (!box) throw new Error(`nothing visible to click named: ${arg}`);
    for (const type of ["mouseMoved", "mousePressed", "mouseReleased"]) {
      await cdp.send("Input.dispatchMouseEvent", { type, x: box.x, y: box.y, button: "left", clickCount: 1 });
    }
    console.log(`clicked ${arg} at ${Math.round(box.x)},${Math.round(box.y)}`);
  } else if (command === "type") {
    await cdp.send("Input.insertText", { text: arg });
    console.log(`typed ${JSON.stringify(arg)}`);
  } else if (command === "key") {
    const codes = { Enter: 13, Escape: 27, Tab: 9, Backspace: 8 };
    if (!(arg in codes)) throw new Error(`unknown key: ${arg}`);
    const key = { key: arg, code: arg, windowsVirtualKeyCode: codes[arg] };
    await cdp.send("Input.dispatchKeyEvent", { type: "rawKeyDown", ...key, ...(arg === "Enter" ? { text: "\r" } : {}) });
    await cdp.send("Input.dispatchKeyEvent", { type: "keyUp", ...key });
    console.log(`pressed ${arg}`);
  } else if (command === "shot") {
    const { data } = await cdp.send("Page.captureScreenshot", { format: "png" });
    const { writeFileSync } = await import("node:fs");
    writeFileSync(arg, Buffer.from(data, "base64"));
    console.log(arg);
  } else {
    console.error("usage: cdp.mjs eval <js> | wait <js> [seconds] | click <text> | type <text> | key <name> | shot <file.png>");
    process.exitCode = 2;
  }
} catch (error) {
  console.error(`cdp: ${error.message}`);
  process.exitCode = 1;
} finally {
  cdp?.close();
}
