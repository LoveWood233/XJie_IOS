const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    mode: 'subject', // 'subject' | 'email'
    subjects: [],
    loading: false,
    // 受试者登录
    selectedSubject: '',
    // 邮箱登录
    email: '',
    password: '',
    isSignup: false,
  },

  onLoad() {
    if (app.isLoggedIn()) {
      wx.switchTab({ url: '/pages/index/index' });
      return;
    }
    this.loadSubjects();
  },

  /** 获取受试者列表 */
  async loadSubjects() {
    try {
      const subjects = await api.get('/api/auth/subjects', { silent: true });
      this.setData({ subjects: subjects || [] });
    } catch (_) {
      // 后端未启动时忽略
    }
  },

  /** 切换登录模式 */
  switchMode() {
    this.setData({ mode: this.data.mode === 'subject' ? 'email' : 'subject' });
  },

  /** 切换注册 / 登录 */
  toggleSignup() {
    this.setData({ isSignup: !this.data.isSignup });
  },

  /** 选中受试者 */
  onSubjectTap(e) {
    this.setData({ selectedSubject: e.currentTarget.dataset.sid });
  },

  /** 受试者登录 */
  async loginSubject() {
    const sid = this.data.selectedSubject;
    if (!sid) {
      wx.showToast({ title: '请选择受试者', icon: 'none' });
      return;
    }
    this.setData({ loading: true });
    try {
      const res = await api.post('/api/auth/login-subject', { subject_id: sid });
      app.setAuth(res);
      app.setSubject(sid);
      wx.switchTab({ url: '/pages/index/index' });
    } catch (_) {
      // toast handled by api.js
    } finally {
      this.setData({ loading: false });
    }
  },

  /** 邮箱登录 / 注册 */
  async loginEmail() {
    const { email, password, isSignup } = this.data;
    if (!email || !password) {
      wx.showToast({ title: '请填写邮箱和密码', icon: 'none' });
      return;
    }
    if (password.length < 8) {
      wx.showToast({ title: '密码至少 8 位', icon: 'none' });
      return;
    }
    this.setData({ loading: true });
    try {
      const path = isSignup ? '/api/auth/signup' : '/api/auth/login';
      const res = await api.post(path, { email, password });
      app.setAuth(res);
      wx.switchTab({ url: '/pages/index/index' });
    } catch (_) {
      // toast handled by api.js
    } finally {
      this.setData({ loading: false });
    }
  },

  /** 微信一键登录（调用后端 wx-login 接口） */
  async wxLogin() {
    this.setData({ loading: true });
    try {
      const { code } = await wx.login();
      const res = await api.post('/api/auth/wx-login', { code });
      app.setAuth(res);
      wx.switchTab({ url: '/pages/index/index' });
    } catch (_) {
      // toast handled by api.js
    } finally {
      this.setData({ loading: false });
    }
  },

  onEmailInput(e) { this.setData({ email: e.detail.value }); },
  onPasswordInput(e) { this.setData({ password: e.detail.value }); },
});
