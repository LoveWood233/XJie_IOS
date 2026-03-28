const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    loading: true,
    doc: null,
  },

  onLoad(options) {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    if (options.id) {
      this.fetchDetail(options.id);
    }
  },

  async fetchDetail(id) {
    this.setData({ loading: true });
    try {
      const doc = await api.get(`/api/health-data/documents/${id}`);
      this.setData({ doc, loading: false });
      wx.setNavigationBarTitle({ title: doc.name || '病例详情' });
    } catch (_) {
      this.setData({ loading: false });
    }
  },
});
