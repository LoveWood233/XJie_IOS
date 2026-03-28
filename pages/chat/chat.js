const api = require('../../utils/api');
const app = getApp();

Page({
  data: {
    messages: [],      // [{ role: 'user'|'assistant', content: '' }]
    inputValue: '',
    sending: false,
    threadId: null,
    conversations: [],
    showHistory: false,
  },

  onLoad() {
    if (!app.isLoggedIn()) {
      wx.redirectTo({ url: '/pages/login/login' });
      return;
    }
    this.loadConversations();
  },

  /** 加载历史会话列表 */
  async loadConversations() {
    try {
      const list = await api.get('/api/chat/conversations', { silent: true });
      this.setData({ conversations: list || [] });
    } catch (_) { /* ignore */ }
  },

  /** 切换历史面板 */
  toggleHistory() {
    this.setData({ showHistory: !this.data.showHistory });
  },

  /** 加载某个历史会话 */
  async loadConversation(e) {
    const id = e.currentTarget.dataset.id;
    try {
      const res = await api.get(`/api/chat/conversations/${id}`);
      const msgs = (res.messages || res || []).map(m => ({
        role: m.role,
        content: m.content,
      }));
      this.setData({ messages: msgs, threadId: id, showHistory: false });
      this.scrollToBottom();
    } catch (_) { /* toast in api.js */ }
  },

  /** 输入 */
  onInput(e) {
    this.setData({ inputValue: e.detail.value });
  },

  /** 发送消息 */
  async sendMessage() {
    const msg = this.data.inputValue.trim();
    if (!msg || this.data.sending) return;

    const userMsg = { role: 'user', content: msg };
    const messages = [...this.data.messages, userMsg];
    this.setData({ messages, inputValue: '', sending: true });
    this.scrollToBottom();

    try {
      // 使用同步聊天接口（小程序不支持 SSE）
      const res = await api.post('/api/chat', {
        message: msg,
        thread_id: this.data.threadId,
      });

      // answer_markdown may be JSON string from mock provider; extract summary
      let content = res.answer_markdown || res.summary || '...';
      try {
        const parsed = JSON.parse(content);
        if (parsed && parsed.summary) content = parsed.summary;
      } catch (_e) { /* not JSON, use as-is */ }

      const assistantMsg = {
        role: 'assistant',
        content,
        confidence: res.confidence,
        followups: res.followups || [],
      };

      if (res.thread_id) {
        this.setData({ threadId: res.thread_id });
      }

      this.setData({
        messages: [...this.data.messages, assistantMsg],
        sending: false,
      });
      this.scrollToBottom();
    } catch (_) {
      this.setData({
        messages: [...this.data.messages, { role: 'assistant', content: '抱歉，请求失败，请重试。' }],
        sending: false,
      });
    }
  },

  /** 点击推荐问题 */
  onFollowup(e) {
    const text = e.currentTarget.dataset.text;
    this.setData({ inputValue: text });
    this.sendMessage();
  },

  /** 新建对话 */
  newChat() {
    this.setData({ messages: [], threadId: null, showHistory: false });
  },

  scrollToBottom() {
    setTimeout(() => {
      wx.pageScrollTo({ scrollTop: 99999, duration: 200 });
    }, 100);
  },
});
