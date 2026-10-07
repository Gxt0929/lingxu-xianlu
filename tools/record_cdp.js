// CDP 录屏 + 驱动一体脚本：Page.startScreencast 抓页面帧 + Input 派发真实点击
// 用法：node record_cdp.js <wsUrl> <durationSeconds> <outDir>
const wsUrl = process.argv[2];
const DURATION = Number(process.argv[3] || 40);
const OUT = process.argv[4] || '.';
const fs = require('fs');
const path = require('path');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const mid = ++id;
      pending.set(mid, { resolve, reject });
      ws.send(JSON.stringify({ id: mid, method, params }));
    });
  const frames = [];
  let frameCount = 0;
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      m.error ? p.reject(new Error(m.error.message)) : p.resolve(m.result);
      return;
    }
    if (m.method === 'Page.screencastFrame') {
      const { data, metadata, sessionId } = m.params;
      const ts = metadata && metadata.timestamp ? metadata.timestamp : Date.now() / 1000;
      const f = frameCount++;
      const file = path.join(OUT, `f_${String(f).padStart(5, '0')}.jpg`);
      fs.writeFileSync(file, Buffer.from(data, 'base64'));
      frames.push({ file, ts });
      ws.send(JSON.stringify({ id: ++id, method: 'Page.screencastFrameAck', params: { sessionId } }));
    }
  };
  await new Promise((r) => (ws.onopen = r));
  await send('Runtime.enable');
  await send('Page.enable');

  const evalJs = async (expr) => {
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true });
    return r && r.result ? r.result.value : undefined;
  };

  // 刷新页面重建渲染管线（避免 screencast 空转），再进游戏
  await send('Page.reload');
  await sleep(2500);
  // 进入游戏（若在主菜单）
  await evalJs(`(function(){ const b=[...document.querySelectorAll('button')].find(x=>/修炼/.test(x.textContent)); if(b){b.click(); return 'menu-clicked';} return 'in-game'; })()`);
  await sleep(1800);
  // 注入灵气（画面为真实 UI 与真实交互响应）
  await evalJs(`(function(){ if(typeof S!=='undefined'){ S.qi=(S.qi||0)+300000; S.totalRun=(S.totalRun||0)+300000; if(typeof refreshList==='function')refreshList(); if(typeof renderUps==='function')renderUps(); } return 'ok'; })()`);

  // 滚回顶部并取关键元素中心坐标
  await evalJs(`window.scrollTo(0,0); 'ok'`);
  await sleep(300);
  const rects = await evalJs(`(function(){
    function c(el){ if(!el) return null; const r=el.getBoundingClientRect(); return [Math.round(r.x+r.width/2), Math.round(r.y+r.height/2)]; }
    return { orb: c(document.querySelector('.orb')), tabs: [...document.querySelectorAll('.tab')].map(c), rows: [...document.querySelectorAll('.b-row')].slice(0,3).map(c).filter(r=>r&&r[1]<900) };
  })()`);
  console.log('rects', JSON.stringify(rects));
  const orb = rects.orb;
  if (!orb) { console.error('orb not found'); process.exit(1); }
  const click = async (x, y) => {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  };

  // 开始录屏（等首帧到达）
  await send('Page.startScreencast', { format: 'jpeg', quality: 85, maxWidth: 560, maxHeight: 1000, everyNthFrame: 1 });
  const t0 = Date.now();
  while (frameCount === 0 && Date.now() - t0 < 5000) await sleep(50);
  console.log('recording started, first frame at', ((Date.now() - t0) / 1000).toFixed(2));

  const phase0 = Date.now();
  const ph = () => (Date.now() - phase0) / 1000;
  let last = -1, tabIdx = 0;
  while (ph() < DURATION - 2) {
    const t = ph();
    const p = t < 12 ? 0 : t < 24 ? 1 : t < 32 ? 2 : 3;
    if (p !== last) { console.log('phase', p, 'at', t.toFixed(1)); last = p; }
    if (p === 0) { await click(orb[0], orb[1]); await sleep(350); }
    else if (p === 1) {
      const row = rects.rows.length ? rects.rows[Math.floor(t) % rects.rows.length] : orb;
      await click(row[0], row[1]);
      await sleep(500);
      if (Math.floor(t) % 4 === 0) await click(orb[0], orb[1]);
    }
    else if (p === 2) {
      if (rects.tabs[tabIdx % rects.tabs.length]) await click(...rects.tabs[tabIdx % rects.tabs.length]);
      tabIdx++;
      await sleep(1600);
    }
    else { await click(orb[0], orb[1]); await sleep(350); }
  }
  await send('Page.stopScreencast');
  await sleep(500);
  console.log('frames captured:', frameCount);

  // 生成 ffconcat（按真实时间戳）
  if (frames.length > 1) {
    let concat = "ffconcat version 1.0\n";
    for (let i = 0; i < frames.length; i++) {
      let d = i + 1 < frames.length ? frames[i + 1].ts - frames[i].ts : 0.1;
      d = Math.min(Math.max(d, 0.02), 1.0);
      concat += `file '${frames[i].file.replace(/\\/g, '/')}'\nduration ${d.toFixed(4)}\n`;
    }
    concat += `file '${frames[frames.length - 1].file.replace(/\\/g, '/')}'\n`;
    fs.writeFileSync(path.join(OUT, 'frames.ffconcat'), concat);
    console.log('concat written, total ts span:', (frames[frames.length - 1].ts - frames[0].ts).toFixed(2), 's');
  }
  ws.close();
  process.exit(0);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
