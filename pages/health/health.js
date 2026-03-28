const api = require('../../utils/api');
const { formatDate, toFixed } = require('../../utils/util');

Page({
  data: {
    loading: true,
    briefing: null,    // { daily_plan, pending_rescues, recent_actions, glucose_status }
    reports: null,     // health-reports (liver cohort)
    aiSummary: '',
    summaryLoading: false,
  },

  onLoad() {
    this.fetchData();
  },

  async fetchData() {
    this.setData({ loading: true });
    try {
      const [briefing, reports] = await Promise.all([
        api.get('/api/agent/today', { silent: true }).catch(() => null),
        api.get('/api/health-reports', { silent: true }).catch(() => null),
      ]);
      this.setData({ briefing, reports, loading: false });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  /** 请求 AI 健康摘要 */
  async loadAISummary() {
    this.setData({ summaryLoading: true, aiSummary: '' });
    try {
      const res = await api.get('/api/health-reports/ai-summary-sync', { silent: true });
      this.setData({ aiSummary: res.summary || '暂无摘要', summaryLoading: false });
    } catch (_) {
      this.setData({ aiSummary: '获取失败，请重试', summaryLoading: false });
    }
  },

  onPullDownRefresh() {
    this.fetchData().then(() => wx.stopPullDownRefresh());
  },

  formatDate,
  toFixed,
});
