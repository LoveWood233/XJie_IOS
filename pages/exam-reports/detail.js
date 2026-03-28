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
      // Mark abnormal rows for styling
      if (doc.csv_data && doc.csv_data.rows) {
        doc.csv_data.rows = doc.csv_data.rows.map((row) => {
          // Check if last column contains abnormal flag
          const lastCell = row[row.length - 1];
          const isAbnormal = lastCell && (lastCell === '↑' || lastCell === '↓' || lastCell === '异常' || lastCell.includes('偏'));
          return { cells: row, isAbnormal };
        });
      }
      // Process abnormal_flags
      if (doc.abnormal_flags && doc.abnormal_flags.length > 0) {
        doc.hasAbnormal = true;
      }
      this.setData({ doc, loading: false });
      wx.setNavigationBarTitle({ title: doc.name || '体检详情' });
    } catch (_) {
      this.setData({ loading: false });
    }
  },
});
