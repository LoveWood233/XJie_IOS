# CGM 对接指南（Webhook 入口）

本文档对应接口：`/api/integrations/cgm/*`

## 1. 现状判断

`CGM对接.docx` 当前只给了字段结构和示例 JSON，没有给出：
- 厂商 API 基础 URL
- 鉴权方式（Token / HMAC / AppKey）
- 推送模式（你拉数据还是对方推送）
- 重试策略与回执约定

因此项目里先实现了标准 webhook 入口，你拿到厂商补充信息后只需填配置并联通。

## 2. 已实现接口

### 2.1 绑定设备到当前用户（需登录）
- `POST /api/integrations/cgm/bindings`
- Body:

```json
{
  "provider": "vendor_cgm",
  "phone": "13900001111",
  "device_sn": "222227VKD9",
  "device_id": "321d889ce73ba718d9f088213d386d96",
  "is_active": true
}
```

### 2.2 查询当前用户绑定（需登录）
- `GET /api/integrations/cgm/bindings`

### 2.3 删除绑定（需登录）
- `DELETE /api/integrations/cgm/bindings/{binding_id}`

### 2.4 厂商推送入口（无需用户登录）
- `POST /api/integrations/cgm/ingest`
- Header:
  - `X-CGM-Timestamp`: Unix 时间戳（字符串）
  - `X-CGM-Signature`: HMAC SHA256 签名（`hex` 或 `sha256=<hex>`）
  - `X-CGM-Provider`: 可选，不传则用环境变量默认值

签名串：
- `signature = HMAC_SHA256(secret, f"{timestamp}.{raw_body}")`

## 3. 本地联调

### 3.1 配置环境变量（`backend/.env`）

```env
CGM_PROVIDER_NAME=vendor_cgm
CGM_SHARED_SECRET=replace_with_real_secret
CGM_ALLOW_UNSIGNED=true
CGM_DEVICE_TIMEZONE=Asia/Shanghai
CGM_SOURCE_NAME=cgm_device_api
```

说明：
- `CGM_ALLOW_UNSIGNED=true` 仅建议本地调试。
- 服务器环境请改成 `false`，并强制验签。

### 3.2 示例 payload

```json
[
  {
    "phone": "13900001111",
    "name": "测试人员",
    "deviceSn": "222227VKD9",
    "deviceId": "321d889ce73ba718d9f088213d386d96",
    "recordList": [
      {
        "deviceTime": "2026-01-20 10:40:35",
        "eventData": 160.0,
        "timeOffset": 4167
      }
    ]
  }
]
```

### 3.3 `curl` 调用

```bash
TS=$(date +%s)
BODY='[{"phone":"13900001111","name":"测试人员","deviceSn":"222227VKD9","deviceId":"321d889ce73ba718d9f088213d386d96","recordList":[{"deviceTime":"2026-01-20 10:40:35","eventData":160.0,"timeOffset":4167}]}]'
SIG=$(printf "%s.%s" "$TS" "$BODY" | openssl dgst -sha256 -hmac "$CGM_SHARED_SECRET" | awk '{print $2}')

curl -X POST "http://localhost:8000/api/integrations/cgm/ingest" \
  -H "Content-Type: application/json" \
  -H "X-CGM-Timestamp: $TS" \
  -H "X-CGM-Signature: $SIG" \
  -H "X-CGM-Provider: vendor_cgm" \
  -d "$BODY"
```

## 4. 服务器迁移建议

## 4.1 部署结构
- API 服务（FastAPI）
- Postgres（持久卷）
- Redis（可选，后续异步任务）
- Nginx/Caddy（TLS + 反向代理）

## 4.2 关键要求
- 强制 HTTPS（厂商回调只允许 TLS）。
- `CGM_ALLOW_UNSIGNED=false`。
- 配置 API 限流与 WAF（至少针对 `/api/integrations/cgm/ingest`）。
- 记录 webhook 审计日志（请求 ID、来源 IP、验签状态）。

## 4.3 零改动迁移原则
- 本地和服务器使用同一 webhook path：`/api/integrations/cgm/ingest`
- 差异仅在 `.env` 与反向代理域名。
- 在厂商后台只改回调域名，不改 body 结构。

## 5. 还需要向厂商确认

至少补齐以下契约后再联调生产：
- 回调 URL 和调用频率（实时/批量/分钟级）
- 失败重试策略（重试次数、间隔、幂等要求）
- 验签规范（header 名、拼接规则、算法）
- `deviceTime` 时区定义
- 数据补传机制（离线后补历史）
- 是否会发送删除/更正事件
