const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    loading: false,
    summary: '',
    summaryUpdatedAt: '',
    generatingSummary: false,
    recordCount: 0,
    examCount: 0,
  },

  onShow() {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    this.fetchAll();
  },

  async fetchAll() {
    this.setData({ loading: true });
    try {
      const [summaryRes, recordsRes, examsRes] = await Promise.all([
        api.get('/api/health-data/summary', { silent: true }).catch(() => ({})),
        api.get('/api/health-data/documents?doc_type=record', { silent: true }).catch(() => ({ total: 0 })),
        api.get('/api/health-data/documents?doc_type=exam', { silent: true }).catch(() => ({ total: 0 })),
      ]);
      this.setData({
        summary: summaryRes.summary_text || '',
        summaryUpdatedAt: summaryRes.updated_at ? new Date(summaryRes.updated_at).toLocaleString('zh-CN') : '',
        recordCount: recordsRes.total || 0,
        examCount: examsRes.total || 0,
        loading: false,
      });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  /** 生成/刷新 AI 总结 */
  async generateSummary() {
    if (this.data.generatingSummary) return;
    this.setData({ generatingSummary: true });
    wx.showLoading({ title: 'AI 分析中...' });
    try {
      const res = await api.post('/api/health-data/summary/generate');
      this.setData({
        summary: res.summary_text || '',
        summaryUpdatedAt: res.updated_at ? new Date(res.updated_at).toLocaleString('zh-CN') : '',
      });
      wx.showToast({ title: '生成完成', icon: 'success' });
    } catch (_) {
      // toast handled by api.js
    } finally {
      this.setData({ generatingSummary: false });
      wx.hideLoading();
    }
  },

  /** 进入历史病例 */
  goRecords() {
    wx.navigateTo({ url: '/pages/medical-records/list' });
  },

  /** 进入历史体检 */
  goExams() {
    wx.navigateTo({ url: '/pages/exam-reports/list' });
  },

  /** 底部快捷拍照上传 */
  quickUpload() {
    wx.showActionSheet({
      itemList: ['上传病例', '上传体检报告'],
      success: (res) => {
        const docType = res.tapIndex === 0 ? 'record' : 'exam';
        this.doUpload(docType);
      },
    });
  },

  /** 选择并上传文件 */
  doUpload(docType) {
    wx.chooseMessageFile({
      count: 1,
      type: 'file',
      extension: ['jpg', 'jpeg', 'png', 'csv', 'pdf'],
      success: (res) => {
        const file = res.tempFiles[0];
        const isImage = /\.(jpg|jpeg|png|heic)$/i.test(file.name);
        if (isImage) {
          this.uploadFile(file.path, file.name, docType, '');
        } else {
          // 非图片需要手动输入名称
          wx.showModal({
            title: '请输入文件名称',
            content: '格式：医院-时间',
            editable: true,
            placeholderText: '如：北京协和-2026-03-20',
            success: (modalRes) => {
              if (modalRes.confirm && modalRes.content) {
                this.uploadFile(file.path, file.name, docType, modalRes.content);
              }
            },
          });
        }
      },
      fail: () => {
        // 也支持拍照
        wx.chooseMedia({
          count: 1,
          mediaType: ['image'],
          sourceType: ['album', 'camera'],
          success: (mediaRes) => {
            const file = mediaRes.tempFiles[0];
            this.uploadFile(file.tempFilePath, 'photo.jpg', docType, '');
          },
        });
      },
    });
  },

  /** 执行上传 */
  uploadFile(filePath, fileName, docType, name) {
    wx.showLoading({ title: '上传中...' });
    const baseUrl = app.globalData.baseUrl;
    wx.uploadFile({
      url: `${baseUrl}/api/health-data/upload`,
      filePath,
      name: 'file',
      formData: { doc_type: docType, name: name },
      header: {
        Authorization: `Bearer ${app.globalData.token}`,
      },
      success: (res) => {
        wx.hideLoading();
        if (res.statusCode >= 200 && res.statusCode < 300) {
          wx.showToast({ title: '上传成功', icon: 'success' });
          this.fetchAll();
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

  onPullDownRefresh() {
    this.fetchAll().then(() => wx.stopPullDownRefresh());
  },
});
