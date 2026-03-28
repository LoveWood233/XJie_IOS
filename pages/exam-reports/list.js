const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    loading: true,
    items: [],
  },

  onShow() {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    this.fetchList();
  },

  async fetchList() {
    this.setData({ loading: true });
    try {
      const res = await api.get('/api/health-data/documents?doc_type=exam');
      this.setData({ items: res.items || [], loading: false });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  viewDetail(e) {
    const id = e.currentTarget.dataset.id;
    wx.navigateTo({ url: `/pages/exam-reports/detail?id=${id}` });
  },

  uploadExam() {
    wx.chooseMessageFile({
      count: 1,
      type: 'file',
      extension: ['jpg', 'jpeg', 'png', 'csv', 'pdf'],
      success: (res) => {
        const file = res.tempFiles[0];
        const isImage = /\.(jpg|jpeg|png|heic)$/i.test(file.name);
        if (isImage) {
          this.doUpload(file.path, '');
        } else {
          wx.showModal({
            title: '请输入名称',
            content: '格式：医院-时间',
            editable: true,
            placeholderText: '如：北京协和-2026-03-20',
            success: (modalRes) => {
              if (modalRes.confirm && modalRes.content) {
                this.doUpload(file.path, modalRes.content);
              }
            },
          });
        }
      },
      fail: () => {
        wx.chooseMedia({
          count: 1,
          mediaType: ['image'],
          sourceType: ['album', 'camera'],
          success: (mediaRes) => {
            this.doUpload(mediaRes.tempFiles[0].tempFilePath, '');
          },
        });
      },
    });
  },

  doUpload(filePath, name) {
    wx.showLoading({ title: '上传中...' });
    wx.uploadFile({
      url: `${app.globalData.baseUrl}/api/health-data/upload`,
      filePath,
      name: 'file',
      formData: { doc_type: 'exam', name },
      header: { Authorization: `Bearer ${app.globalData.token}` },
      success: (res) => {
        wx.hideLoading();
        if (res.statusCode >= 200 && res.statusCode < 300) {
          wx.showToast({ title: '上传成功', icon: 'success' });
          this.fetchList();
        } else {
          const data = JSON.parse(res.data || '{}');
          wx.showToast({ title: data.detail || '上传失败', icon: 'none' });
        }
      },
      fail: () => {
        wx.hideLoading();
        wx.showToast({ title: '网络错误', icon: 'none' });
      },
    });
  },

  deleteExam(e) {
    const id = e.currentTarget.dataset.id;
    wx.showModal({
      title: '确认删除',
      content: '删除后无法恢复，确定吗？',
      success: async (res) => {
        if (res.confirm) {
          try {
            await api.del(`/api/health-data/documents/${id}`);
            wx.showToast({ title: '已删除', icon: 'success' });
            this.fetchList();
          } catch (_) {}
        }
      },
    });
  },

  onPullDownRefresh() {
    this.fetchList().then(() => wx.stopPullDownRefresh());
  },
});
