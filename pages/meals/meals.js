const api = require('../../utils/api');
const { formatDate, toFixed } = require('../../utils/util');

Page({
  data: {
    loading: true,
    meals: [],       // 膳食记录列表
    photos: [],      // 处理过的照片
    uploading: false,
  },

  onShow() {
    this.fetchData();
  },

  async fetchData() {
    this.setData({ loading: true });
    try {
      const [mealsRes, photosRes] = await Promise.all([
        api.get('/api/meals?limit=50', { silent: true }).catch(() => []),
        api.get('/api/dashboard/meals', { silent: true }).catch(() => []),
      ]);
      this.setData({
        meals: mealsRes || [],
        photos: photosRes || [],
        loading: false,
      });
    } catch (_) {
      this.setData({ loading: false });
    }
  },

  /** 拍照 / 选图上传 */
  choosePhoto() {
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const file = res.tempFiles[0];
        this.uploadPhoto(file.tempFilePath);
      },
    });
  },

  /** 上传流程: 1) 获取上传凭证 → 2) 上传文件 → 3) 完成处理 */
  async uploadPhoto(filePath) {
    this.setData({ uploading: true });
    wx.showLoading({ title: '上传中...' });
    try {
      // Step 1: 获取上传 URL
      const ticket = await api.post('/api/meals/photo/upload-url', {
        filename: 'meal.jpg',
        content_type: 'image/jpeg',
      });

      // Step 2: 上传到后端 (或 S3)
      if (ticket.upload_url) {
        await new Promise((resolve, reject) => {
          wx.uploadFile({
            url: ticket.upload_url,
            filePath,
            name: 'file',
            success: (res) => res.statusCode < 300 ? resolve(res) : reject(res),
            fail: reject,
          });
        });
      } else {
        // 直接上传到后端
        await api.uploadFile('/api/meals/photo/upload', filePath);
      }

      // Step 3: 通知完成
      await api.post('/api/meals/photo/complete', {
        object_key: ticket.object_key,
      });

      wx.showToast({ title: '上传成功', icon: 'success' });
      this.fetchData();
    } catch (err) {
      wx.showToast({ title: '上传失败', icon: 'none' });
    } finally {
      wx.hideLoading();
      this.setData({ uploading: false });
    }
  },

  /** 手动添加膳食记录 */
  addMealManual() {
    // 弹出简单输入对话框
    wx.showModal({
      title: '记录膳食',
      editable: true,
      placeholderText: '输入估算热量 (kcal)',
      success: async (res) => {
        if (res.confirm && res.content) {
          const kcal = parseInt(res.content, 10);
          if (isNaN(kcal) || kcal <= 0) {
            wx.showToast({ title: '请输入有效热量', icon: 'none' });
            return;
          }
          try {
            await api.post('/api/meals', {
              meal_ts: new Date().toISOString(),
              meal_ts_source: 'manual',
              kcal,
              tags: [],
              notes: '',
            });
            wx.showToast({ title: '添加成功', icon: 'success' });
            this.fetchData();
          } catch (_) { /* toast in api.js */ }
        }
      },
    });
  },

  onPullDownRefresh() {
    this.fetchData().then(() => wx.stopPullDownRefresh());
  },

  formatDate,
  toFixed,
});
