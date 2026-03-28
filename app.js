App({
  globalData: {
    baseUrl: 'http://localhost:8000', // 开发环境后端地址
    token: '',
    refreshToken: '',
    userInfo: null,
    subjectId: '',
  },

  onLaunch() {
    // 从本地缓存读取登录态
    const token = wx.getStorageSync('token');
    const refreshToken = wx.getStorageSync('refreshToken');
    const subjectId = wx.getStorageSync('subjectId');
    if (token) {
      this.globalData.token = token;
      this.globalData.refreshToken = refreshToken;
      this.globalData.subjectId = subjectId;
    }
  },

  /** 保存登录态 */
  setAuth(data) {
    this.globalData.token = data.access_token;
    this.globalData.refreshToken = data.refresh_token || '';
    wx.setStorageSync('token', data.access_token);
    wx.setStorageSync('refreshToken', data.refresh_token || '');
  },

  /** 保存受试者 ID */
  setSubject(sid) {
    this.globalData.subjectId = sid;
    wx.setStorageSync('subjectId', sid);
  },

  /** 退出登录 */
  logout() {
    this.globalData.token = '';
    this.globalData.refreshToken = '';
    this.globalData.subjectId = '';
    this.globalData.userInfo = null;
    wx.removeStorageSync('token');
    wx.removeStorageSync('refreshToken');
    wx.removeStorageSync('subjectId');
  },

  /** 是否已登录 */
  isLoggedIn() {
    return !!this.globalData.token;
  },
});
