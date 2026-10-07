// 录屏驱动脚本：通过 CDP 驱动 Edge 中的游戏，产生真实点击用于实机录屏
// 用法：node drive_demo.js  <wsUrl>  <durationSeconds>
const wsUrl = process.argv[2];
const DURATION = Number(process.argv[3] || 40);
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
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      m.error ? p.reject(new Error(m.error.message)) : p.resolve(m.result);
    }
  };
  await new Promise((r) => (ws.onopen = r));
  await send('Runtime.enable');

  const evalJs = async (expr) => {
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true });
    return r && r.result ? r.result.value : undefined;
  };

  // 若在主菜单则先点「开始/继续修炼」进入游戏
  await evalJs(`(function(){ const b=[...document.querySelectorAll('button')].find(x=>/修炼/.test(x.textContent)); if(b){b.click(); return 'menu-clicked';} return 'in-game'; })()`);
  await sleep(1800);

  // 注入灵气让购买演示有内容（画面仍是真实 UI 与真实交互响应）
  await evalJs(`(function(){ if(typeof S!=='undefined'){ S.qi=(S.qi||0)+300000; S.totalRun=(S.totalRun||0)+300000; if(typeof refreshList==='function')refreshList(); if(typeof renderUps==='function')renderUps(); } return 'ok'; })()`);

  // 取关键元素中心坐标
  const rects = await evalJs(`(function(){
    function c(el){ if(!el) return null; const r=el.getBoundingClientRect(); return [Math.round(r.x+r.width/2), Math.round(r.y+r.height/2)]; }
    return {
      orb: c(document.querySelector('.orb')),
      tabs: [...document.querySelectorAll('.tab')].map(c),
      rows: [...document.querySelectorAll('.b-row')].slice(0,3).map(c),
    };
  })()`);
  console.log('rects', JSON.stringify(rects));
  const orb = rects.orb;
  if (!orb) { console.error('orb not found'); process.exit(1); }

  const click = async (x, y) => {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  };

  const t0 = Date.now();
  const phase = () => (Date.now() - t0) / 1000;
  let lastPhase = -1;
  let tabIdx = 0;
  // 编排：0-12s 狂点炁球（核心玩法）；12-24s 买建筑；24-32s 切页签；32s-结束 回炁球
  while (phase() < DURATION - 2) {
    const t = phase();
    const p = t < 12 ? 0 : t < 24 ? 1 : t < 32 ? 2 : 3;
    if (p !== lastPhase) { console.log('phase', p, 'at', t.toFixed(1)); lastPhase = p; }
    if (p === 0) { await click(orb[0], orb[1]); await sleep(350); }
    else if (p === 1) {
      const row = rects.rows[(Math.floor(t) % rects.rows.length)];
      if (row) await click(row[0], row[1]);
      await sleep(500);
      if (Math.floor(t) % 4 === 0 && orb) await click(orb[0], orb[1]);
    }
    else if (p === 2) {
      if (rects.tabs[tabIdx % rects.tabs.length]) await click(...rects.tabs[tabIdx % rects.tabs.length]);
      tabIdx++;
      await sleep(1600);
    }
    else { await click(orb[0], orb[1]); await sleep(350); }
  }
  console.log('done');
  ws.close();
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
