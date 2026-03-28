/**
 * API 请求封装 — 适配微信小程序 wx.request
 * 自动携带 JWT Token，401 时自动刷新
 */

const app = getApp();

/** 从 app.js 或配置读取后端地址 */
function getBaseUrl() {
  return app.globalData.baseUrl || '';
}

/**
 * 通用请求方法
 * @param {string}  path     - API 路径，如 /api/glucose
 * @param {string}  method   - HTTP 方法
 * @param {object}  [data]   - 请求体
 * @param {object}  [extra]  - 额外选项 { header, silent }
 * @returns {Promise<any>}
 */
function request(path, method, data, extra = {}) {
  // Skip auth check for auth endpoints
  if (!path.startsWith('/api/auth/') && !app.globalData.token) {
    wx.reLaunch({ url: '/pages/login/login' });
    return Promise.reject(new Error('Not logged in'));
  }
  return new Promise((resolve, reject) => {
    wx.request({
      url: `${getBaseUrl()}${path}`,
      method,
      data,
      header: {
        'Content-Type': 'application/json',
        Authorization: app.globalData.token ? `Bearer ${app.globalData.token}` : '',
        ...extra.header,
      },
      success(res) {
        if (res.statusCode === 401 && !extra._retried) {
          // 尝试刷新 Token
          refreshAndRetry(path, method, data, extra).then(resolve).catch(reject);
          return;
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data);
        } else {
          const err = { statusCode: res.statusCode, data: res.data };
          if (!extra.silent) {
            wx.showToast({ title: (res.data && res.data.detail) || '请求失败', icon: 'none' });
          }
          reject(err);
        }
      },
      fail(err) {
        if (!extra.silent) {
          wx.showToast({ title: '网络错误', icon: 'none' });
        }
        reject(err);
      },
    });
  });
}

/** 刷新 Token 后重试 */
function refreshAndRetry(path, method, data, extra) {
  const rt = app.globalData.refreshToken;
  if (!rt) {
    app.logout();
    wx.reLaunch({ url: '/pages/login/login' });
    return Promise.reject(new Error('No refresh token'));
  }

  return new Promise((resolve, reject) => {
    wx.request({
      url: `${getBaseUrl()}/api/auth/refresh`,
      method: 'POST',
      data: { refresh_token: rt },
      header: { 'Content-Type': 'application/json' },
      success(res) {
        if (res.statusCode === 200 && res.data.access_token) {
          app.setAuth(res.data);
          // 用新 Token 重试原始请求
          request(path, method, data, { ...extra, _retried: true }).then(resolve).catch(reject);
        } else {
          app.logout();
          wx.reLaunch({ url: '/pages/login/login' });
          reject(new Error('Refresh failed'));
        }
      },
      fail() {
        app.logout();
        wx.reLaunch({ url: '/pages/login/login' });
        reject(new Error('Refresh network error'));
      },
    });
  });
}

// ── 便捷方法 ──

function get(path, extra) {
  return request(path, 'GET', undefined, extra);
}

function post(path, data, extra) {
  return request(path, 'POST', data, extra);
}

function patch(path, data, extra) {
  return request(path, 'PATCH', data, extra);
}

function del(path, extra) {
  return request(path, 'DELETE', undefined, extra);
}

/**
 * 上传文件（wx.uploadFile）
 * @param {string} path      - API 路径
 * @param {string} filePath  - 微信临时文件路径
 * @param {string} [name]    - 表单字段名
 */
function uploadFile(path, filePath, name = 'file') {
  return new Promise((resolve, reject) => {
    wx.uploadFile({
      url: `${getBaseUrl()}${path}`,
      filePath,
      name,
      header: {
        Authorization: app.globalData.token ? `Bearer ${app.globalData.token}` : '',
      },
      success(res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(res.data));
        } else {
          reject({ statusCode: res.statusCode, data: res.data });
        }
      },
      fail: reject,
    });
  });
}

module.exports = { get, post, patch, del, uploadFile, request };
