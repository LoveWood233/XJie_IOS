# Claude Code CLI — 技术架构文档

## 1. 项目概览

Claude Code 是一个基于 **Bun** 运行时构建的 AI 驱动型终端 CLI 工具，使用 **TypeScript + React (Ink)** 实现终端交互式 UI。它提供 60+ 命令和 40+ 工具，支持对话式 AI 编程辅助、代码审查、Git 操作、多智能体协作等功能。

| 属性 | 值 |
|------|-----|
| 运行时 | Bun |
| 语言 | TypeScript (TSX) |
| UI 框架 | React + [Ink](https://github.com/vadimdemedes/ink) (终端 UI) |
| CLI 解析 | @commander-js/extra-typings |
| AI SDK | @anthropic-ai/sdk |
| 协议集成 | @modelcontextprotocol/sdk (MCP) |
| 校验 | Zod |
| 构建方式 | Bun bundler + Feature-gated DCE (死代码消除) |

---

## 2. 项目结构

```
CDB/
├── src/
│   ├── entrypoints/          # 入口点 (CLI、MCP 服务等)
│   ├── main.tsx              # 主启动逻辑
│   ├── ink.ts                # Ink 渲染器初始化
│   ├── commands.ts           # 命令注册中心
│   ├── tools.ts              # 工具注册中心
│   ├── commands/             # 60+ 命令实现
│   ├── tools/                # 40+ 工具实现
│   ├── components/           # 130+ React 终端 UI 组件
│   ├── hooks/                # 100+ React Hooks
│   ├── services/             # 业务服务层
│   ├── bridge/               # 远程桥接系统
│   ├── plugins/              # 插件系统
│   ├── skills/               # 技能系统
│   ├── coordinator/          # 多智能体协调
│   ├── context/              # 上下文管理
│   ├── state/                # 应用状态管理
│   ├── types/                # 核心类型定义
│   ├── constants/            # 常量定义
│   ├── cli/                  # CLI I/O & 传输层
│   ├── tasks/                # 任务运行时
│   ├── query/                # 查询辅助
│   ├── screens/              # 全屏视图
│   ├── vim/                  # Vim 模式
│   ├── voice/                # 语音模式
│   ├── server/               # 直连服务
│   ├── keybindings/          # 快捷键
│   ├── utils/                # 通用工具库 (200+)
│   └── ...
└── vendor/                   # 原生模块源码 (音频采集、图片处理等)
```

---

## 3. 启动与引导流程

### 3.1 快速路径入口 — `src/entrypoints/cli.tsx`

CLI 入口采用**零模块加载优先**策略：

1. **`--version`** — 直接返回版本号，不加载任何模块
2. **`--daemon-worker`** — 进入守护进程工作模式
3. **MCP 服务路由** — Chrome、计算机操作等 MCP 服务快速分流
4. **常规启动** — 懒加载 `main.tsx`

### 3.2 主初始化 — `src/main.tsx`

```
启动性能打点 → 并行预取 (MDM/Keychain) → 参数解析 → 工具组装 → 插件初始化 → Ink 渲染
```

关键步骤：
- **Startup Profiler**: 通过检查点追踪启动耗时
- **并行预取**: MDM 配置 和 Keychain 同时加载
- **Commander 解析**: 使用 `@commander-js/extra-typings` 处理 CLI 参数
- **工具/命令组装**: 根据 Feature Flag 条件注册
- **Ink 渲染**: 挂载 React 终端 UI

---

## 4. 命令系统

### 4.1 命令类型

系统定义三种命令类型：

#### Prompt 命令 (AI 驱动)
```typescript
type PromptCommand = {
  type: 'prompt'
  name: string
  description: string
  progressMessage: string
  allowedTools?: string[]         // 允许使用的工具白名单
  model?: string                  // 指定模型
  source: 'builtin' | 'mcp' | 'plugin' | 'bundled' | SettingSource
  context?: 'inline' | 'fork'    // inline=当前会话 | fork=子代理
  agent?: string                  // fork 时的代理类型
  effort?: EffortValue
  hooks?: HooksSettings
  skillRoot?: string
  applyTo?: string[]              // Glob 匹配模式
  getPromptForCommand(): ContentBlockParam[]
}
```

示例：`/commit` — 读取 git log，生成 AI 辅助的提交信息。

#### Local 命令 (同步本地)
```typescript
type LocalCommand = {
  type: 'local'
  call(args, context): LocalCommandResult  // text | compact | skip
}
```

示例：`/version` — 直接返回 `MACRO.VERSION`。

#### Local-JSX 命令 (交互式 UI)
```typescript
type LocalJSXCommand = {
  type: 'local-jsx'
  call(): React.ReactNode
}
```

示例：`/brief` — 切换精简输出模式，渲染 React 组件。

### 4.2 命令注册中心 — `src/commands.ts`

`COMMANDS()` 函数返回 memoized 的 `Command[]` 数组，包含：

**常驻命令** (~30+)：
`add-dir`, `advisor`, `agents`, `branch`, `commit`, `config`, `cost`, `diff`, `doctor`, `exit`, `files`, `help`, `init`, `keybindings`, `login`, `logout`, `model`, `permissions`, `plugin`, `resume`, `review`, `security-review`, `session`, `skills`, `status`, `tasks`, `upgrade`, `version`, `vim` 等。

**Feature-Gated 命令** (~30+)：

| Feature Flag | 命令 |
|-------------|------|
| `KAIROS` | `brief`, `assistant`, `proactive` |
| `BRIDGE_MODE` | `bridge`, `remote-control-server` |
| `VOICE_MODE` | `voice` |
| `WORKFLOW_SCRIPTS` | `workflows` |
| `CCR_REMOTE_SETUP` | `web` |
| `UDS_INBOX` | `peers` |
| `FORK_SUBAGENT` | `fork` |
| `BUDDY` | `buddy` |
| `ULTRAPLAN` | `ultraplan` |
| `TORCH` | `torch` |

### 4.3 技能加载

`getSkills()` 异步聚合四个来源：
1. `skillDirCommands` — 从文件系统 (技能目录) 加载
2. `pluginSkills` — 从已加载插件获取
3. `bundledSkills` — 内置打包技能
4. `builtinPluginSkills` — 内建插件提供的技能

---

## 5. 工具系统

### 5.1 工具抽象 — `src/Tool.ts`

```typescript
type Tool = {
  name: string
  getSchema(): ToolInputJSONSchema     // JSON Schema 输入校验
  run(input, context): Promise<ToolResult>
  getToolUseSummary?(input): string    // 一行摘要
  getActivityDescription?(input): string
  userFacingName?(input): string
}
```

### 5.2 工具清单

**核心工具** (始终可用)：

| 工具 | 功能 |
|------|------|
| `BashTool` | Shell 命令执行 |
| `FileReadTool` / `FileWriteTool` / `FileEditTool` | 文件读写编辑 |
| `GlobTool` / `GrepTool` | 文件搜索 / 文本搜索 |
| `WebFetchTool` / `WebSearchTool` | 网页抓取 / 网络搜索 |
| `AgentTool` | 子代理调用 |
| `SkillTool` | 技能调用 |
| `LSPTool` | Language Server Protocol 交互 |
| `NotebookEditTool` | Jupyter Notebook 编辑 |
| `TaskCreate/Get/Update/List/Stop/OutputTool` | 任务 CRUD |
| `TodoWriteTool` | Todo 管理 |
| `MCPTool` / `ListMcpResourcesTool` / `ReadMcpResourceTool` | MCP 资源操作 |
| `EnterPlanModeTool` / `ExitPlanModeV2Tool` | 计划模式切换 |
| `EnterWorktreeTool` / `ExitWorktreeTool` | Git Worktree 隔离 |
| `ConfigTool` | 配置管理 |
| `AskUserQuestionTool` | 向用户提问 |
| `ToolSearchTool` | 工具搜索 |
| `BriefTool` | 精简输出 |

**条件加载工具**：

| Feature Flag | 工具 |
|-------------|------|
| `ant` 用户 | `REPLTool`, `SuggestBackgroundPRTool` |
| `KAIROS` | `SleepTool`, `SendUserFileTool`, `PushNotificationTool` |
| `AGENT_TRIGGERS` | `CronCreateTool`, `CronDeleteTool`, `CronListTool` |
| `AGENT_TRIGGERS_REMOTE` | `RemoteTriggerTool` |
| `MONITOR_TOOL` | `MonitorTool` |
| `KAIROS_GITHUB_WEBHOOKS` | `SubscribePRTool` |

### 5.3 工具权限控制

- **`ALL_AGENT_DISALLOWED_TOOLS`**：子代理禁用工具 (TaskOutput、ExitPlanMode、AskUserQuestion 等)
- **`ASYNC_AGENT_ALLOWED_TOOLS`**：异步代理允许工具 (FileRead、Bash、Grep 等)
- **`IN_PROCESS_TEAMMATE_ALLOWED_TOOLS`**：进程内协作者允许工具 (TaskCreate/Get/List/Update 等)

---

## 6. AI 查询引擎 — `src/QueryEngine.ts`

QueryEngine 是与 Claude API 交互的核心枢纽。

### 6.1 主要能力

```typescript
class QueryEngine {
  ask(messages, tools, context, thinkingConfig): AsyncGenerator<StreamEvent>
}
```

| 功能 | 描述 |
|------|------|
| Token 计数与预算追踪 | 追踪输入/输出 token 消耗 |
| 工具 Schema 生成 | 动态生成工具的 JSON Schema |
| 自动压缩 (Auto-Compact) | 上下文过长时自动压缩对话 |
| 流式工具执行 | 流式接收 Claude 响应并执行工具调用 |
| Extended Thinking | 支持 ThinkingConfig 配置思考模式 |
| Prompt Cache | 提示词缓存管理，减少 API 开销 |
| Reactive/Context Collapse | Feature-gated 的上下文折叠优化 |
| Microcompact | 边界消息精简压缩 |

### 6.2 成本追踪 — `src/cost-tracker.ts`

```typescript
// 追踪维度
{
  model: string
  inputTokens: number
  outputTokens: number
  cacheReadTokens: number
  cacheCreationTokens: number
  apiDuration: number           // 含重试
  apiDurationWithoutRetries: number
  webSearchRequests: number
  costUSD: number               // 通过 modelCost.ts 计算
}
```

`useCostSummary()` Hook 在 `process.exit` 时输出消费概览。

---

## 7. 任务系统 — `src/Task.ts`

### 7.1 任务类型

```typescript
type TaskType =
  | 'local_bash'           // 本地 Shell 任务
  | 'local_agent'          // 本地子代理
  | 'remote_agent'         // 远程代理
  | 'in_process_teammate'  // 进程内协作者
  | 'local_workflow'       // 本地工作流
  | 'monitor_mcp'          // MCP 监控
  | 'dream'                // 后台梦境模式
```

### 7.2 任务状态机

```
pending → running → completed
                  → failed
                  → killed
```

### 7.3 任务 ID 生成

格式：`<type_prefix><8_byte_random>`，使用 base36 编码，空间约 36^8 ≈ 2.8 万亿组合。

---

## 8. Bridge 远程桥接系统 — `src/bridge/`

Bridge 是 Claude Code 的远程执行架构，允许通过 Web 端控制本地 CLI 实例。

### 8.1 架构概览

```
Claude Code Web ←→ Bridge API ←→ 本地 CLI (Bridge Worker)
```

### 8.2 核心组件

| 模块 | 职责 |
|------|------|
| `bridgeMain.ts` | 主进程管理、会话超时 (默认24h)、退避策略 (2-10min) |
| `bridgeApi.ts` | API 客户端，Bearer/OAuth 双认证 |
| `bridgeMessaging.ts` | 消息通信协议 |
| `bridgePermissionCallbacks.ts` | 权限回调 |
| `replBridge.ts` / `replBridgeTransport.ts` | REPL 桥接传输 |
| `trustedDevice.ts` | 可信设备管理 |
| `workSecret.ts` | 工作密钥 (base64url 编码) |
| `jwtUtils.ts` | JWT 工具 |
| `sessionRunner.ts` | 会话运行器 |

### 8.3 会话管理

- **Spawn 模式**：single-session / worktree / same-dir
- **传输层**：WebSocket (主) → SSE (备) → Hybrid (故障转移)
- **会话超时**：默认 24 小时
- **重试退避**：2 分钟 → 10 分钟，30 秒关闭宽限期

### 8.4 工作协议

```typescript
interface WorkResponse {
  id: string
  type: 'work'
  environment_id: string
  state: object
  data: { type: 'session' | 'healthcheck'; id: string }
  secret: string  // base64url(WorkSecret)
}
```

---

## 9. 插件与技能系统

### 9.1 插件系统 — `src/plugins/`

```typescript
registerBuiltinPlugin(definition)   // 注册内建插件
isBuiltinPluginId(pluginId)         // 检查是否 "{name}@builtin"
```

**插件能力**：
- 提供 skills (技能/命令)
- 提供 hooks (生命周期钩子)
- 提供 MCP servers
- 支持版本化安装/卸载
- 后台孤儿清理

### 9.2 技能系统 — `src/skills/`

- 内建打包技能注册
- 文件系统动态发现 (`loadSkillsDir`)
- MCP 服务器技能构建
- 技能变更检测

### 9.3 MCP 集成 — `src/services/mcp/`

- MCP 服务器连接管理
- 资源列表 / 读取
- 配置解析与验证
- Xavier (XAA) IDP 身份支持

---

## 10. 状态管理 — `src/state/`

### 10.1 AppState Store

采用 **React Context + 自定义 Store** 模式：

```typescript
// 基于 selector 的订阅机制 (Object.is 比较)
const value = useAppState(state => state.someField)
```

### 10.2 核心状态字段

- `mainLoopModel` / `advisorModel` — 模型选择
- `isBriefOnly` — 精简模式
- `toolPermissionContext` — 工具权限上下文
- `verbose` — 详细输出
- `theme` — 主题
- `workflow` state — 工作流状态

### 10.3 上下文系统 — `src/context.ts`

| 函数 | 作用 |
|------|------|
| `getGitStatus()` | Memoized 获取 Git 上下文 (分支、状态、最近5次提交) |
| `getSystemContext()` | 构建系统提示 (Git 状态 + cache breaker) |
| `getUserContext()` | 构建用户上下文 (CLAUDE.md + 日期) |
| `setSystemPromptInjection()` | 设置调试注入 (ant-only) |

---

## 11. CLI I/O 层 — `src/cli/`

### 11.1 结构化 I/O — `structuredIO.ts`

- **NDJSON 消息协议**：换行分隔的 JSON 消息通信
- 权限请求/响应处理
- 工具控制协商
- 双线程状态追踪 (最多 1000 已解析工具 ID)

### 11.2 传输层 — `src/cli/transports/`

| 传输 | 描述 |
|------|------|
| WebSocket | 主传输 |
| SSE | 备选传输 |
| Hybrid | 自动切换 |
| CCR Client | Claude Code Remote 客户端 |
| Worker 上传 | 工作状态上传 |
| 批量序列化 | 事件批量发送 |

### 11.3 处理器 — `src/cli/handlers/`

代理操作、认证、MCP、插件、自动模式等专用处理器。

---

## 12. 权限系统 — `src/utils/permissions/`

### 12.1 权限模式

| 模式 | 行为 |
|------|------|
| `manual` | 每次操作需用户确认 |
| `auto` | 基于规则自动判断 |
| `bypass` | 跳过确认 (危险操作除外) |

### 12.2 安全分类器

- **`bashClassifier`** — Bash 命令安全分类
- **`yoloClassifier`** — 扩展分类器 (结合 CLAUDE.md 配置)
- **`dangerousPatterns`** — 危险命令模式检测

---

## 13. 会话与历史 — `src/history.ts` + `src/assistant/sessionHistory.ts`

### 13.1 本地历史

```typescript
// 粘贴内容引用格式
"[Pasted text #N +M lines]"
"[Image #N]"

MAX_HISTORY_ITEMS = 100
MAX_PASTED_CONTENT_LENGTH = 1024
```

- 小内容行内存储，大内容使用哈希引用外部文件
- Lockfile 保证线程安全

### 13.2 远程会话历史

- 分页查询 (cursor: firstId, hasMore)
- 每页 100 条事件
- OAuth Bearer + x-organization-uuid 认证

---

## 14. 服务层 — `src/services/`

| 服务 | 职责 |
|------|------|
| `api/` | API 客户端封装 |
| `analytics/` | 分析与遥测 |
| `compact/` | 消息压缩 |
| `lsp/` | LSP 集成 |
| `mcp/` | MCP 协议集成 |
| `oauth/` | OAuth 认证 |
| `plugins/` | 插件安装管理 |
| `voice.ts` / `voiceStreamSTT.ts` | 语音识别 / STT 流 |
| `settingsSync/` | 设置同步 |
| `teamMemorySync/` | 团队记忆同步 |
| `tokenEstimation.ts` | Token 估算 |
| `tips/` | 提示与建议 |
| `MagicDocs/` | 文档自动生成 |
| `AgentSummary/` | 代理总结 |
| `SessionMemory/` | 会话记忆 |
| `policyLimits/` | 策略限流 |
| `preventSleep.ts` | 防止系统休眠 |

---

## 15. UI 组件层 — `src/components/`

130+ React (Ink) 组件，覆盖终端 UI 全部视图：

| 分类 | 示例组件 |
|------|---------|
| 主布局 | `App.tsx`, `FullscreenLayout.tsx`, `Messages.tsx` |
| 消息渲染 | `MessageRow.tsx`, `StructuredDiff/` |
| 对话框 | `ApproveApiKey.tsx`, `BridgeDialog.tsx`, `CostThreshold.tsx` |
| 输入 | `PromptInput/`, `TextInput.tsx`, `VimTextInput.tsx` |
| 工具展示 | `FileEditToolDiff.tsx`, `TaskListV2.tsx` |
| 进度 | `BashModeProgress.tsx`, `ToolUseLoader.tsx` |
| 状态栏 | `CoordinatorAgentStatus.tsx`, `ThinkingToggle.tsx` |

---

## 16. Feature Flag 体系

项目通过 `feature()` 函数实现运行时特性门控，所有条件模块通过 Bun bundler 的 DCE 在构建时消除未启用分支的代码。

### 主要 Feature Flags

| Flag | 控制范围 |
|------|---------|
| `KAIROS` | 后台助手、主动模式、精简模式 |
| `BRIDGE_MODE` | 远程桥接系统 |
| `VOICE_MODE` | 语音输入/输出 |
| `AGENT_TRIGGERS` | 定时任务 (Cron) |
| `WORKFLOW_SCRIPTS` | 工作流脚本 |
| `CCR_REMOTE_SETUP` | Claude Code Remote |
| `COORDINATOR_MODE` | 多智能体协调 |
| `ULTRAPLAN` | 超级规划模式 |
| `FORK_SUBAGENT` | 子代理分叉 |
| `BUDDY` | 伴侣模式 |
| `TORCH` | Torch 特性 |
| `MONITOR_TOOL` | 监控工具 |
| `HISTORY_SNIP` | 历史裁剪 |
| `UDS_INBOX` | Unix Domain Socket 消息 |
| `PROACTIVE` | 主动建议 |

---

## 17. 关键设计模式

### 17.1 延迟加载 + Memoization
- 命令列表 `COMMANDS()` 返回 memoized 数组
- `getGitStatus()` / `getUserContext()` 使用 memoized 异步缓存
- 入口点对 `--version` 等简单场景实现零模块加载

### 17.2 注册表模式
- 命令、工具、技能、插件 均采用集中注册 + 条件组装
- `uniqBy` 去重合并工具池

### 17.3 Feature-Gated DCE
- 构建时通过 Bun bundler 实现死代码消除
- 运行时通过 `feature()` 检测；未启用的 Feature 代码在最终产物中被移除

### 17.4 Stream-based 架构
- QueryEngine 使用 `AsyncGenerator` 流式输出
- Bridge 支持 WebSocket → SSE → Hybrid 传输降级
- NDJSON 结构化 I/O 协议

### 17.5 权限纵深防御
- 三级权限模式 (manual / auto / bypass)
- Bash 命令安全分类器
- 危险模式检测
- CLAUDE.md 驱动的自定义规则

---

## 18. 原生模块 — `vendor/`

| 目录 | 功能 |
|------|------|
| `audio-capture-src/` | 音频采集 |
| `image-processor-src/` | 图片处理 |
| `modifiers-napi-src/` | N-API 修饰器 |
| `url-handler-src/` | URL 处理器 |

---

## 19. 技术架构图 (简化)

```
┌─────────────────────────────────────────────────────────┐
│                     CLI Entry Point                     │
│               (src/entrypoints/cli.tsx)                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   Main Bootstrap                        │
│                   (src/main.tsx)                        │
│  ┌──────────┐  ┌───────────┐  ┌─────────────────────┐   │
│  │Commander │  │Tool Assem.│  │  Plugin/Skill Init  │   │
│  │ Parsing  │  │(tools.ts) │  │                     │   │
│  └──────────┘  └───────────┘  └─────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   ┌────────────┐ ┌─────────┐ ┌─────────────┐
   │  Commands  │ │  Tools  │ │   Skills    │
   │   (60+)    │ │  (40+)  │ │  (dynamic)  │
   └─────┬──────┘ └────┬────┘ └──────┬──────┘
         │              │             │
         └──────────────┼─────────────┘
                        ▼
              ┌──────────────────┐
              │   QueryEngine    │
              │  (Claude API)    │
              │  Stream / Think  │
              │  Auto-Compact    │
              └────────┬─────────┘
                       │
         ┌─────────────┼──────────────┐
         ▼             ▼              ▼
  ┌────────────┐ ┌──────────┐ ┌────────────┐
  │   State    │ │ Cost     │ │  History   │
  │  (AppState)│ │ Tracker  │ │  Manager   │
  └────────────┘ └──────────┘ └────────────┘
         │
         ▼
  ┌──────────────────────────────┐
  │   Ink / React Terminal UI    │
  │   (130+ Components)          │
  │   (100+ Hooks)               │
  └──────────────────────────────┘
         │
         ▼
  ┌──────────────────────────────┐
  │    CLI I/O (NDJSON)          │
  │    WS / SSE / Hybrid        │
  │    Bridge (Remote)           │
  └──────────────────────────────┘
```

---

*文档基于源码静态分析生成，反映代码库当前架构设计。*
