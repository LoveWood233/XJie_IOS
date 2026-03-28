# Xjie — 微信小程序版

智能代谢健康管理平台，支持 CGM 血糖追踪、膳食记录（拍照识别）、AI 对话、代理干预系统。

## 项目结构

```
XJie/
├── app.js / app.json / app.wxss    ← 小程序入口
├── pages/                           ← 页面
│   ├── index/                       ← 首页（仪表板）
│   ├── glucose/                     ← 血糖曲线
│   ├── meals/                       ← 膳食记录
│   ├── chat/                        ← AI 助手
│   ├── health/                      ← 健康数据 / 每日简报
│   ├── settings/                    ← 设置
│   └── login/                       ← 登录
├── utils/                           ← 工具函数
│   ├── api.js                       ← 请求封装（JWT 自动刷新）
│   └── util.js                      ← 通用工具
├── images/                          ← tabBar 图标
├── project.config.json              ← 微信开发者工具配置
├── backend/                         ← FastAPI 后端 API
│   ├── app/routers/                 ← 路由（auth, glucose, meals, chat, agent ...）
│   ├── app/models/                  ← 数据库模型（16 张表）
│   ├── app/services/                ← 业务逻辑
│   └── app/core/                    ← 配置、安全、中间件
├── docker-compose.yml               ← 后端基础设施
└── data/                            ← 研究数据（已 gitignore）
```

## 技术栈

| 层级     | 技术                                      |
| -------- | ----------------------------------------- |
| 前端     | 微信小程序原生框架 (WXML + WXSS + JS)     |
| 后端     | FastAPI + SQLAlchemy 2.0 + Pydantic v2    |
| 数据库   | PostgreSQL 16                             |
| 缓存     | Redis 7                                   |
| 任务队列 | Celery 5.3                                |
| 对象存储 | MinIO (S3 兼容)                           |
| LLM      | OpenAI / Gemini                           |

## 快速开始

### 后端

```bash
# 启动基础设施
docker compose up -d db redis minio

# 安装依赖并启动
cd backend
pip install -e .
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 小程序

1. 下载并打开 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
2. 导入项目，选择 `XJie/` 根目录
3. AppID: `wx24a461ae309ac297`
4. 在 `app.js` 中配置 `baseUrl` 指向后端地址

### 环境变量

在 `backend/.env` 中配置：

```env
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/metabodash
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=your-secret-key
WX_APPID=wx24a461ae309ac297
WX_SECRET=your-wechat-secret
OPENAI_API_KEY=sk-xxx
```

## 核心功能

- **微信登录**: 一键授权，自动创建账户
- **血糖监测**: CGM 数据导入、24h/7d 曲线、TIR 统计
- **膳食记录**: 拍照上传 → AI 视觉识别热量 → 记录
- **AI 助手**: 基于血糖 + 膳食上下文的智能对话
- **代理系统**: 每日简报、餐前模拟、血糖救援、周评
- **三级干预**: L1 温和 / L2 标准 / L3 积极

## API 端点

| 路由                         | 功能         |
| ---------------------------- | ------------ |
| POST /api/auth/wx-login      | 微信登录     |
| GET  /api/dashboard/health   | 健康总览     |
| GET  /api/glucose            | 血糖数据     |
| POST /api/meals              | 膳食记录     |
| POST /api/chat               | AI 对话      |
| GET  /api/agent/today        | 每日简报     |
| POST /api/agent/premeal-sim  | 餐前模拟     |
| GET  /api/agent/rescue       | 救援检查     |

## 测试

```bash
cd backend
pytest -q
```

Frontend e2e smoke:

```bash
cd frontend
npm run e2e
```
