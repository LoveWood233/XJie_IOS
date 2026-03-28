const api = require('../../utils/api');
const { toFixed } = require('../../utils/util');
const app = getApp();

Page({
  data: {
    loading: true,
    dashboard: null,  // { glucose: {last_24h, last_7d}, kcal_today, meals_today, data_quality }
    proactive: null,  // { message, has_rescue }
    subjectId: '',
  },

  onShow() {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    this.setData({ subjectId: app.globalData.subjectId });
    this.fetchData();
  },

  async fetchData() {
    this.setData({ loading: true });
    try {
      const [dashboard, proactive] = await Promise.all([
        api.get('/api/dashboard/health', { silent: true }).catch(() => null),
        api.get('/api/agent/proactive', { silent: true }).catch(() => null),
      ]);
      this.setData({ dashboard, proactive, loading: false });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  onPullDownRefresh() {
    this.fetchData().then(() => wx.stopPullDownRefresh());
  },

  /** 跳转到每日简报 */
  goToday() {
    wx.navigateTo({ url: '/pages/health/health' });
  },

  /** 跳转到救援 */
  goRescue() {
    wx.navigateTo({ url: '/pages/chat/chat' });
  },

  /** 快捷入口 */
  goGlucose() { wx.switchTab({ url: '/pages/glucose/glucose' }); },
  goMeals()   { wx.switchTab({ url: '/pages/meals/meals' }); },
  goChat()    { wx.switchTab({ url: '/pages/chat/chat' }); },
  goSettings(){ wx.navigateTo({ url: '/pages/settings/settings' }); },

  toFixed,
});
