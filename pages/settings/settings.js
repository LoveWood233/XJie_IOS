const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    loading: true,
    user: null,         // { id, email, created_at, consent, settings }
    settings: null,     // { intervention_level, daily_reminder_limit, ... }
    levels: ['L1', 'L2', 'L3'],
    levelLabels: { L1: '温和', L2: '标准', L3: '积极' },
    levelDescs: {
      L1: '仅在高风险时提醒，每天最多 1 条',
      L2: '中等风险时提醒，每天最多 2 条（默认）',
      L3: '主动提醒，每天最多 4 条',
    },
  },

  onLoad() {
    this.fetchData();
  },

  async fetchData() {
    this.setData({ loading: true });
    try {
      const [user, settings] = await Promise.all([
        api.get('/api/users/me'),
        api.get('/api/users/settings', { silent: true }).catch(() => null),
      ]);
      this.setData({ user, settings, loading: false });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  /** 切换干预级别 */
  async onLevelChange(e) {
    const level = e.currentTarget.dataset.level;
    try {
      await api.patch('/api/users/settings', { intervention_level: level });
      wx.showToast({ title: '已更新', icon: 'success' });
      this.fetchData();
    } catch (_) { /* toast in api.js */ }
  },

  /** 切换 AI 聊天同意 */
  async toggleAiChat() {
    const current = this.data.user?.consent?.allow_ai_chat;
    try {
      await api.patch('/api/users/consent', { allow_ai_chat: !current });
      wx.showToast({ title: '已更新', icon: 'success' });
      this.fetchData();
    } catch (_) { /* toast in api.js */ }
  },

  /** 切换数据上传同意 */
  async toggleDataUpload() {
    const current = this.data.user?.consent?.allow_data_upload;
    try {
      await api.patch('/api/users/consent', { allow_data_upload: !current });
      wx.showToast({ title: '已更新', icon: 'success' });
      this.fetchData();
    } catch (_) { /* toast in api.js */ }
  },

  /** 退出登录 */
  logout() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出登录吗？',
      success: async (res) => {
        if (res.confirm) {
          await api.post('/api/auth/logout', {}, { silent: true }).catch(() => {});
          app.logout();
          wx.reLaunch({ url: '/pages/login/login' });
        }
      },
    });
  },
});
