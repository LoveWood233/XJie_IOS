/**
 * 工具函数
 */

/** 格式化日期为  YYYY-MM-DD HH:mm */
function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** 格式化时间为 HH:mm */
function formatTime(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

/** 保留 n 位小数 */
function toFixed(num, n = 1) {
  if (num == null || isNaN(num)) return '--';
  return Number(num).toFixed(n);
}

/** 血糖范围着色  */
function glucoseColor(val) {
  if (val == null) return '';
  if (val < 70) return 'text-warning';
  if (val > 180) return 'text-danger';
  return 'text-success';
}

/** 简单节流 */
function throttle(fn, delay = 500) {
  let last = 0;
  return function (...args) {
    const now = Date.now();
    if (now - last >= delay) {
      last = now;
      fn.apply(this, args);
    }
  };
}

module.exports = { formatDate, formatTime, toFixed, glucoseColor, throttle };
