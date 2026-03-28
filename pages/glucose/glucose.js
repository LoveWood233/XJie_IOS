const api = require('../../utils/api');
const { toFixed, glucoseColor } = require('../../utils/util');
const app = getApp();

Page({
  data: {
    loading: true,
    window: '24h', // '24h' | '7d' | 'all'
    points: [],
    summary: null, // from dashboard
    range: null,
    canvasWidth: 0,
    canvasHeight: 200,
  },

  onLoad() {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    const sysInfo = wx.getWindowInfo();
    this.setData({ canvasWidth: sysInfo.windowWidth - 64 }); // 两侧 padding
    this.fetchRange();
  },

  async fetchRange() {
    try {
      const range = await api.get('/api/glucose/range', { silent: true });
      this.setData({ range });
      this.fetchPoints();
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  async fetchPoints() {
    this.setData({ loading: true });
    const now = new Date();
    let from;
    if (this.data.window === '24h') {
      from = new Date(now.getTime() - 24 * 3600 * 1000);
    } else if (this.data.window === '7d') {
      from = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
    } else {
      from = this.data.range ? new Date(this.data.range.min_ts) : new Date(now.getTime() - 30 * 24 * 3600 * 1000);
    }

    try {
      const [points, dashboard] = await Promise.all([
        api.get(`/api/glucose?from=${from.toISOString()}&to=${now.toISOString()}&limit=2000`),
        api.get('/api/dashboard/health', { silent: true }).catch(() => null),
      ]);

      const windowKey = this.data.window === '24h' ? 'last_24h' : 'last_7d';
      const summary = dashboard && dashboard.glucose ? dashboard.glucose[windowKey] : null;

      this.setData({ points: points || [], summary, loading: false });
      this.drawChart();
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  /** 切换时间窗口 */
  switchWindow(e) {
    const w = e.currentTarget.dataset.w;
    if (w !== this.data.window) {
      this.setData({ window: w });
      this.fetchPoints();
    }
  },

  /** Canvas 绘制血糖曲线 */
  drawChart() {
    const pts = this.data.points;
    if (!pts.length) return;

    const query = wx.createSelectorQuery();
    query.select('#glucoseCanvas').fields({ node: true, size: true }).exec((res) => {
      if (!res[0]) return;
      const canvas = res[0].node;
      const ctx = canvas.getContext('2d');
      const dpr = wx.getWindowInfo().pixelRatio;
      const width = res[0].width;
      const height = res[0].height;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      ctx.scale(dpr, dpr);

      // 清空
      ctx.clearRect(0, 0, width, height);

      // 数据范围
      const values = pts.map(p => p.glucose_mgdl);
      const minVal = Math.min(...values, 50);
      const maxVal = Math.max(...values, 200);
      const range = maxVal - minVal || 1;

      const padLeft = 40;
      const padRight = 8;
      const padTop = 8;
      const padBottom = 20;
      const chartW = width - padLeft - padRight;
      const chartH = height - padTop - padBottom;

      // 目标范围背景 (70-180)
      const y180 = padTop + chartH * (1 - (180 - minVal) / range);
      const y70 = padTop + chartH * (1 - (70 - minVal) / range);
      ctx.fillStyle = 'rgba(34, 197, 94, 0.08)';
      ctx.fillRect(padLeft, Math.max(y180, padTop), chartW, Math.min(y70 - y180, chartH));

      // 参考线
      [70, 140, 180].forEach(v => {
        const y = padTop + chartH * (1 - (v - minVal) / range);
        ctx.strokeStyle = '#e2e8f0';
        ctx.lineWidth = 0.5;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(padLeft, y);
        ctx.lineTo(width - padRight, y);
        ctx.stroke();
        ctx.setLineDash([]);
        // 标签
        ctx.fillStyle = '#94a3b8';
        ctx.font = '10px sans-serif';
        ctx.fillText(String(v), 2, y + 3);
      });

      // 曲线
      const timestamps = pts.map(p => new Date(p.ts).getTime());
      const minT = Math.min(...timestamps);
      const maxT = Math.max(...timestamps);
      const tRange = maxT - minT || 1;

      ctx.beginPath();
      ctx.strokeStyle = '#6366f1';
      ctx.lineWidth = 1.5;
      pts.forEach((p, i) => {
        const x = padLeft + chartW * ((timestamps[i] - minT) / tRange);
        const y = padTop + chartH * (1 - (p.glucose_mgdl - minVal) / range);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      });
      ctx.stroke();
    });
  },

  onPullDownRefresh() {
    this.fetchPoints().then(() => wx.stopPullDownRefresh());
  },

  toFixed,
  glucoseColor,
});
