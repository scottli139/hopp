# Peekaboo CLI 学习笔记

> 学习日期: 2026-03-11  
> 项目地址: https://github.com/steipete/Peekaboo  
> 文档地址: https://github.com/steipete/Peekaboo/blob/main/docs/cli-command-reference.md

---

## 一、工具概述

**Peekaboo** 是 macOS 平台的 CLI 工具 + MCP 服务器，用于：
- 高保真屏幕截图（应用、窗口、菜单栏）
- AI 驱动的 UI 分析（GPT-5.1、Claude 4.x、Grok、Gemini、Ollama 本地模型）
- 完整的 GUI 自动化（点击、输入、滚动、快捷键、菜单操作等）
- 自然语言 Agent 自动化任务

### 两种使用模式

| 模式 | 用途 | 启动方式 |
|------|------|----------|
| **CLI 工具** | 命令行工作流、脚本自动化、CI/CD | `peekaboo <command>` |
| **MCP Server** | Claude Desktop、Cursor 集成 | `npx -y @steipete/peekaboo` |

---

## 二、安装方式

### 方式 1: Homebrew (推荐)
```bash
brew tap steipete/tap
brew install peekaboo
```

### 方式 2: 直接下载
```bash
curl -L https://github.com/steipete/peekaboo/releases/latest/download/peekaboo-macos-universal.tar.gz | tar xz
sudo mv peekaboo-macos-universal/peekaboo /usr/local/bin/
```

### 方式 3: npm (包含 MCP server)
```bash
npm install -g @steipete/peekaboo
```

### 方式 4: 从源码构建
```bash
git clone https://github.com/steipete/peekaboo.git
cd peekaboo
./scripts/build-cli-standalone.sh --install
```

---

## 三、核心能力地图

### 3.1 视觉与捕获 (Vision & Capture)

| 命令 | 功能 | 典型用法 |
|------|------|----------|
| `peekaboo see` | 捕获带注释的 UI 地图，获取元素 ID | `peekaboo see --app Safari --json-output` |
| `peekaboo image` | 保存原始 PNG/JPG 截图 | `peekaboo image --mode screen --format png` |
| `peekaboo capture` | 长时捕获，支持视频 | `capture live` / `capture video` |
| `peekaboo list` | 列出应用/窗口/屏幕/菜单栏/权限 | `peekaboo list apps` |
| `peekaboo tools` | 列出可用工具（原生 vs MCP） | `peekaboo tools --json` |

#### `see` 命令详解
```bash
# 基本用法 - 捕获最前窗口并输出 JSON
peekaboo see --json-output

# 捕获特定应用窗口
peekaboo see --app "Google Chrome" --window-title "Login"

# 捕获整个屏幕
peekaboo see --mode screen

# 带注释的截图（在图片上标注元素 ID）
peekaboo see --annotate --path /tmp/annotated.png

# 捕获菜单栏弹出层
peekaboo see --menubar
```

**关键输出字段** (JSON):
- `snapshot_id` - 用于后续 click/type 命令
- `ui_map` - UI 结构文件路径
- `ui_elements` - 可交互元素列表（按钮、文本框、链接等）
- 每个元素包含: `title`, `label`, `description`, `role_description`, `help`, `identifier`

```bash
# 使用 jq 查找元素
peekaboo see --app Safari --json-output | \
  jq '.data.ui_elements[] | select(.label | test("Sign in"; "i"))'
```

---

### 3.2 交互命令 (Interaction)

| 命令 | 功能 | 关键参数 |
|------|------|----------|
| `peekaboo click` | 点击元素（ID/文本/坐标） | `--on B12`, `--coords x,y`, `--double`, `--right` |
| `peekaboo type` | 输入文本 | `--clear`, `--delay`, 支持控制键 |
| `peekaboo press` | 按下特殊键 | `SpecialKey` 序列，支持重复次数 |
| `peekaboo hotkey` | 快捷键组合 | `cmd,shift,t` 格式 |
| `peekaboo paste` | 粘贴（原子操作） | 自动处理剪贴板 |
| `peekaboo scroll` | 滚动 | 方向、可选元素目标、平滑模式 |
| `peekaboo swipe` | 滑动手势 | `--duration`, `--steps` |
| `peekaboo drag` | 拖拽 | 跨元素、坐标或 Dock 目标 |
| `peekaboo move` | 移动光标 | 坐标、元素中心或屏幕中心 |

#### `click` 命令详解
```bash
# 通过元素 ID 点击（来自之前的 see 命令）
peekaboo click --on B12

# 模糊搜索文本点击
peekaboo click "Send" --wait-for 8000

# 坐标点击
peekaboo click --coords 1024,88 --right --no-auto-focus

# 带 Space 切换的焦点处理
peekaboo click "Allow" --space-switch --bring-to-current-space
```

**关键选项**:
- `--on <id>` / `--id <id>` - 指定 Peekaboo 元素 ID (如 B1, T2)
- `--coords x,y` - 精确坐标点击
- `--snapshot <id>` - 复用之前的快照
- `--wait-for <ms>` - 等待元素出现的超时时间（默认 5000ms）
- `--double` / `--right` - 双击或右键
- `--no-auto-focus` - 禁用自动焦点

---

### 3.3 窗口、应用、空间管理

| 命令 | 子命令 | 功能 |
|------|--------|------|
| `peekaboo window` | `close`, `minimize`, `maximize`, `move`, `resize`, `set-bounds`, `focus`, `list` | 窗口管理 |
| `peekaboo space` | `list`, `switch`, `move-window` | Spaces/虚拟桌面管理 |
| `peekaboo menu` | `click`, `click-extra`, `list`, `list-all` | 应用菜单操作 |
| `peekaboo menubar` | `list`, `click` | 状态栏图标操作 |
| `peekaboo app` | `launch`, `quit`, `relaunch`, `hide`, `unhide`, `switch`, `list` | 应用生命周期管理 |
| `peekaboo open` | - | 增强版 macOS open 命令 |
| `peekaboo dock` | `launch`, `right-click`, `hide`, `show`, `list` | Dock 操作 |
| `peekaboo dialog` | `click`, `input`, `file`, `dismiss`, `list` | 系统对话框处理 |

#### 应用管理示例
```bash
# 启动应用并传递文件
peekaboo app launch Safari --open https://example.com --wait-until-ready

# 切换应用
peekaboo app switch "Visual Studio Code"

# 列出所有运行中的应用
peekaboo app list --json
```

#### 窗口管理示例
```bash
# 列出应用的所有窗口
peekaboo list windows --app "Visual Studio Code"

# 调整窗口大小和位置
peekaboo window set-bounds --app Safari --x 100 --y 100 --width 1200 --height 800

# 聚焦特定窗口
peekaboo window focus --window-id 12345
```

#### Spaces (虚拟桌面) 管理
```bash
# 列出所有 Spaces
peekaboo space list

# 切换到 Space 2
peekaboo space switch --index 2

# 移动窗口到另一个 Space
peekaboo space move-window --window-id 12345 --space-index 3
```

---

### 3.4 Agent 自动化 (自然语言)

| 命令 | 功能 | 关键参数 |
|------|------|----------|
| `peekaboo agent` | 自然语言自动化 | `--dry-run`, `--max-steps`, `--model`, `--resume` |

```bash
# 基本用法 - 让 Agent 执行任务
peekaboo agent "Check Slack mentions and reply to urgent messages"

# 指定模型
peekaboo agent "Install the nightly build" --model claude-sonnet-4.5

# 干运行（只计划不执行）
peekaboo agent "Configure Xcode settings" --dry-run

# 恢复上次会话
peekaboo agent --resume

# 查看会话历史
peekaboo agent --list-sessions

# 限制最大步骤数
peekaboo agent "Run tests" --max-steps 50
```

**支持的模型**:
- `gpt-5.1` (默认)
- `claude-sonnet-4.5`
- `gemini-3-flash`
- `grok-4-fast`
- `ollama/llava:latest` (本地)

**Chat 模式**:
```bash
# 进入交互式聊天
peekaboo agent --chat

# 聊天命令
/help      # 显示帮助
Esc        # 取消当前操作
Ctrl+C     # 退出
```

---

### 3.5 配置与工具命令

| 命令 | 子命令 | 功能 |
|------|--------|------|
| `peekaboo config` | `init`, `show`, `edit`, `validate`, `add`, `login`, `set-credential`, `add-provider`, `list-providers`, `test-provider`, `remove-provider`, `models` | 配置管理 |
| `peekaboo run` | - | 执行 `.peekaboo.json` 脚本 |
| `peekaboo sleep` | - | 毫秒级暂停 |
| `peekaboo clean` | - | 清理快照缓存 |
| `peekaboo daemon` | `start`, `stop`, `status` | 后台守护进程 |
| `peekaboo permissions` | `status`, `grant` | 权限管理 |

#### 配置文件
```bash
# 初始化配置
peekaboo config init

# 显示当前配置
peekaboo config show --effective

# 编辑配置
peekaboo config edit
```

配置文件路径: `~/.config/peekaboo/config.json`

```json
{
  "aiProviders": {
    "providers": "openai/gpt-4o,ollama/llava:latest",
    "openaiApiKey": "${OPENAI_API_KEY}",
    "ollamaBaseUrl": "http://localhost:11434"
  },
  "defaults": {
    "savePath": "~/Desktop/Screenshots",
    "imageFormat": "png",
    "captureMode": "window"
  }
}
```

---

### 3.6 MCP 集成

| 命令 | 子命令 | 功能 |
|------|--------|------|
| `peekaboo mcp` | `serve`, `list`, `add`, `remove`, `enable`, `disable`, `info`, `test`, `call`, `inspect` | MCP 服务器管理 |

---

## 四、权限要求

### 必需权限

| 权限 | 必需 | 用途 |
|------|------|------|
| **Screen Recording** | ✅ 必需 | CGWindow 捕获、多应用自动化 |
| **Accessibility** | ⚠️ 推荐 | 窗口焦点、菜单交互、对话框控制 |

### 权限检查与请求
```bash
# 检查权限状态
peekaboo permissions status

# 请求屏幕录制权限
peekaboo permissions grant screen-recording

# 请求辅助功能权限
peekaboo permissions grant accessibility
```

### 手动设置
1. **Screen Recording**: System Settings → Privacy & Security → Screen & System Audio Recording → 启用 Terminal/IDE
2. **Accessibility**: System Settings → Privacy & Security → Accessibility → 启用 Terminal/IDE

---

## 五、实用工作流示例

### 5.1 UI 测试自动化流程
```bash
#!/bin/bash
# ui_test.sh - 自动化 UI 测试脚本

APP_NAME="MyApp"
TEST_TIMEOUT=10000

# 1. 启动应用
peekaboo app launch "$APP_NAME" --wait-until-ready

# 2. 捕获初始 UI 状态
peekaboo see --app "$APP_NAME" --json-output --path /tmp/initial.png

# 3. 点击登录按钮
peekaboo click "Login" --app "$APP_NAME" --wait-for $TEST_TIMEOUT

# 4. 输入用户名
peekaboo type "testuser" --app "$APP_NAME"

# 5. 按 Tab 切换到密码框
peekaboo press Tab

# 6. 输入密码
peekaboo type "password123"

# 7. 点击提交
peekaboo click "Submit"

# 8. 等待并验证结果
sleep 2
peekaboo see --app "$APP_NAME" --json-output | jq '.data.ui_elements[] | select(.label | test("Welcome"; "i"))'

# 9. 清理
peekaboo app quit "$APP_NAME"
```

### 5.2 截图 + AI 分析流程
```bash
# 捕获屏幕并分析
peekaboo image --mode screen --path /tmp/screen.png
peekaboo analyze /tmp/screen.png "What errors are visible on this screen?"

# 或者使用 see 直接获得 AI 分析
peekaboo see --app Safari --analyze "Find all buttons on this page"
```

### 5.3 批量测试多个窗口
```bash
# 获取所有窗口并测试
peekaboo list windows --app "MyApp" --json-output | jq -r '.data.windows[].id' | while read window_id; do
  echo "Testing window: $window_id"
  peekaboo see --window-id $window_id --json-output --path "/tmp/window_${window_id}.png"
done
```

### 5.4 使用脚本文件 (.peekaboo.json)
```bash
# 执行脚本
peekaboo run workflow.peekaboo.json --output results.json --no-fail-fast
```

脚本示例 (`workflow.peekaboo.json`):
```json
{
  "steps": [
    {"command": "app launch", "args": ["Safari", "--wait-until-ready"]},
    {"command": "sleep", "args": ["1000"]},
    {"command": "see", "args": ["--app", "Safari", "--json-output"]},
    {"command": "click", "args": ["--on", "B1"]},
    {"command": "type", "args": ["https://example.com"]},
    {"command": "press", "args": ["Return"]}
  ]
}
```

---

## 六、Flutter/macOS 应用测试场景

### 6.1 测试 Flutter 应用的具体步骤
```bash
# 1. 启动 Flutter 应用（假设已构建为 macOS 应用）
peekaboo app launch "hopp" --wait-until-ready

# 2. 等待应用完全加载
peekaboo sleep 2000

# 3. 捕获当前 UI 状态
peekaboo see --app "hopp" --json-output --annotate --path /tmp/hopp_initial.png

# 4. 查找并点击特定元素（例如 "New Request" 按钮）
# 先使用 see 获取元素 ID，然后点击
ELEMENT_ID=$(peekaboo see --app "hopp" --json-output | jq -r '.data.ui_elements[] | select(.label | test("New Request"; "i")) | .id' | head -1)
peekaboo click --on "$ELEMENT_ID" --app "hopp"

# 5. 输入 URL
peekaboo type "https://api.example.com/users" --app "hopp"

# 6. 点击发送按钮
peekaboo click "Send" --app "hopp" --wait-for 5000

# 7. 捕获响应
peekaboo see --app "hopp" --json-output --path /tmp/hopp_response.png

# 8. 验证响应内容（使用 AI 分析）
peekaboo analyze /tmp/hopp_response.png "Is the response status 200 OK?"
```

### 6.2 多标签页测试
```bash
# 创建多个请求标签页
for i in {1..3}; do
  peekaboo click "+" --app "hopp"
  peekaboo sleep 500
done

# 切换到第一个标签页
peekaboo click --coords 100,50 --app "hopp"
```

### 6.3 侧边栏操作测试
```bash
# 展开/折叠集合
peekaboo click "Collection 1" --app "hopp"

# 右键点击请求项
peekaboo click "Request Name" --app "hopp" --right

# 选择上下文菜单项
peekaboo click "Duplicate" --app "hopp"
```

---

## 七、关键技巧与最佳实践

### 7.1 元素定位策略
1. **优先使用元素 ID** (`--on B12`) - 最稳定
2. **模糊文本匹配** (`click "Send"`) - 易读但可能不唯一
3. **坐标点击** (`--coords x,y`) - 最后手段，易受分辨率影响

### 7.2 等待策略
```bash
# 显式等待元素出现
peekaboo click "Slow Loading Button" --wait-for 10000

# 在操作间添加延迟
peekaboo sleep 500
```

### 7.3 调试技巧
```bash
# 使用 --json-output 获取结构化数据
peekaboo see --json-output | jq '.'

# 启用详细日志
peekaboo <command> --verbose

# 干运行测试计划
peekaboo agent "Task description" --dry-run

# 保留注释截图用于调试
peekaboo see --annotate --path /tmp/debug.png
```

### 7.4 错误处理
```bash
# 检查上条命令是否成功
if [ $? -eq 0 ]; then
  echo "Success"
else
  echo "Failed, check logs"
  peekaboo permissions status
fi
```

---

## 八、环境变量与配置

| 变量 | 用途 |
|------|------|
| `OPENAI_API_KEY` | OpenAI API 密钥 |
| `ANTHROPIC_API_KEY` | Claude API 密钥 |
| `PEEKABOO_AI_PROVIDERS` | AI 提供商配置 (如 `openai/gpt-4o,ollama/llava`) |
| `PEEKABOO_OLLAMA_BASE_URL` | Ollama 服务地址 |
| `PEEKABOO_LOG_LEVEL` | 日志级别 (debug/info/warn/error) |
| `PEEKABOO_LOG_FILE` | 日志文件路径 |
| `PEEKABOO_CONSOLE_LOGGING` | 是否输出到控制台 |
| `PEEKABOO_CLI_PATH` | 自定义 CLI 路径 |

---

## 九、故障排除

| 问题 | 解决方案 |
|------|----------|
| `Permission denied` | 在系统设置中授予屏幕录制和辅助功能权限 |
| `Window not found` | 使用模糊匹配或先用 `peekaboo list windows` 确认 |
| `AI analysis failed` | 检查 API 密钥和提供商配置 |
| `Command not found` | 确保 peekaboo 在 PATH 中或使用完整路径 |
| `SNAPSHOT_NOT_FOUND` | 使用 `peekaboo see` 重新生成快照 |
| 窗口捕获问题 | 授予辅助功能权限以提高可靠性 |

### 调试模式
```bash
export PEEKABOO_LOG_LEVEL=debug
export PEEKABOO_CONSOLE_LOGGING=true
peekaboo <command> --verbose
```

---

## 十、相关资源

### 官方资源
- **GitHub**: https://github.com/steipete/Peekaboo
- **CLI 文档**: https://github.com/steipete/Peekaboo/tree/main/docs/commands
- **NPM 包**: https://www.npmjs.com/package/@steipete/peekaboo

### 学习路径
1. 先掌握 `see`, `click`, `type` 三个核心命令
2. 学习使用 `--json-output` 和 `jq` 处理输出
3. 尝试用 `agent` 命令完成简单自然语言任务
4. 编写 `.peekaboo.json` 脚本实现复杂工作流

### 类似工具对比
| 工具 | 平台 | 特点 |
|------|------|------|
| **Peekaboo** | macOS | AI 驱动、自然语言、MCP 集成 |
| **Selenium** | 跨平台 | Web 专用、成熟生态 |
| **Playwright** | 跨平台 | 现代 Web 测试、自动等待 |
| **Appium** | 跨平台 | 移动端原生应用测试 |
| **AppleScript** | macOS | 系统级、无视觉能力 |

---

## 十一、待探索的高级功能

- [ ] **视频捕获分析**: `capture video` 分析视频流
- [ ] **音频集成**: `--audio` 语音控制
- [ ] **Realtime 模式**: OpenAI 实时 API 低延迟交互
- [ ] **MCP Inspector**: `npx @modelcontextprotocol/inspector` 测试 MCP 工具
- [ ] **自定义 Provider**: 添加本地 AI 模型

---

## 十二、快速参考卡片

```bash
# ===== 基础捕获 =====
peekaboo see --app Safari --json-output           # 捕获 UI 结构
peekaboo image --mode screen --path screen.png    # 截图

# ===== 基本交互 =====
peekaboo click --on B12                           # 点击元素 ID
peekaboo click "Button Text"                      # 点击文本
peekaboo type "Hello World"                       # 输入文本
peekaboo hotkey cmd,shift,t                       # 快捷键

# ===== 应用管理 =====
peekaboo app launch Safari --wait-until-ready     # 启动应用
peekaboo app quit Safari                          # 退出应用
peekaboo window focus --app Safari                # 聚焦窗口

# ===== Agent 自动化 =====
peekaboo agent "Do something" --model gpt-5.1     # 自然语言任务
peekaboo agent --dry-run                          # 干运行

# ===== 权限与调试 =====
peekaboo permissions status                       # 检查权限
peekaboo --version                                # 版本信息
peekaboo <command> --help                         # 命令帮助
```

---

*这份笔记由 AI 助手整理，用于日后参考和使用 Peekaboo CLI 进行 macOS 界面自动化测试。*

---

## 附录 B: 实践练习记录

> 记录时间: 2026-03-11  
> 练习环境: macOS + Peekaboo 3.0.0-beta3

### B.1 实际测试验证

| 命令 | 测试结果 | 备注 |
|------|----------|------|
| `peekaboo --version` | ✅ 通过 | 3.0.0-beta3 |
| `peekaboo permissions status` | ✅ 通过 | 两项权限均已授予 |
| `peekaboo list apps` | ✅ 通过 | 列出 76 个运行中的应用 |
| `peekaboo app list --json` | ✅ 通过 | JSON 格式输出正常 |
| `peekaboo window list --app Terminal` | ✅ 通过 | 显示 4 个 Terminal 窗口 |
| `peekaboo dock list` | ✅ 通过 | 显示 28 个 Dock 项目（发现 Postman） |
| `peekaboo image --mode screen --path ...` | ✅ 通过 | 生成 310KB PNG 截图 |
| `peekaboo see --app Terminal --annotate --path ...` | ✅ 通过 | 生成带注释的截图 |
| `peekaboo sleep 1000` | ✅ 通过 | 正确暂停 1 秒 |
| `peekaboo config init` | ✅ 通过 | 配置文件创建成功 |
| `peekaboo tools --json` | ✅ 通过 | 列出 21 个可用工具 |

### B.2 配置文件实践

```bash
# 初始化配置
peekaboo config init
# 输出: [ok] Configuration file created at: /Users/build/.peekaboo/config.json
```

生成的默认配置 (`~/.peekaboo/config.json`):
```json
{
  "aiProviders": {
    "providers": "openai/gpt-5.1,anthropic/claude-sonnet-4.5"
  },
  "defaults": {
    "savePath": "~/Desktop/Screenshots",
    "imageFormat": "png",
    "captureMode": "window",
    "captureFocus": "auto"
  },
  "logging": {
    "level": "info",
    "path": "~/.peekaboo/logs/peekaboo.log"
  }
}
```

### B.3 窗口信息示例

Terminal 应用的窗口列表：
```
Terminal has 4 window(s):
  [0] "postman — Kimi Code — head ◂ Kimi Code ptr_munge= — 200×63"
       Position: (0, 0)
       Size: 1440x900
  [4] "versions — build@bogon — ~/fvm/versions — -zsh — 175×58"
       Position: (0, 0)
       Size: 1440x900
  [5] "postman — kimi — kimi — Kimi Code ptr_munge= — 200×52"
       Position: (0, 35)
       Size: 1437x786
  [8] "swep-evsdk-iphone-svc-gen2 — Kimi Code — Kimi Code ◂ Kimi Code ptr_munge= — 200×63"
       Position: (0, 0)
       Size: 1440x900
```

### B.4 Dock 项目发现

```
Dock items:
  [0] Finder •
  [2] Safari •
  ...
  [20] Postman •          ← 已安装的 API 测试工具
  ...
  [27] Trash (trash)
```

### B.5 发现的 21 个可用工具

通过 `peekaboo tools --json` 获取的完整工具列表：

| # | 工具名 | 用途 |
|---|--------|------|
| 1 | agent | AI Agent 自动化任务 |
| 2 | analyze | 图像 AI 分析 |
| 3 | app | 应用控制（启动/退出/切换） |
| 4 | capture | 视频/实时捕获 |
| 5 | click | 点击 UI 元素或坐标 |
| 6 | dialog | 系统对话框交互 |
| 7 | dock | Dock 交互 |
| 8 | drag | 拖拽操作 |
| 9 | hotkey | 快捷键组合 |
| 10 | image | 屏幕截图 |
| 11 | list | 列出应用/窗口/状态 |
| 12 | menu | 菜单栏交互 |
| 13 | move | 鼠标移动 |
| 14 | permissions | 权限检查 |
| 15 | scroll | 滚动操作 |
| 16 | see | UI 元素捕获和映射 |
| 17 | sleep | 暂停执行 |
| 18 | space | Spaces 虚拟桌面管理 |
| 19 | swipe | 滑动手势 |
| 20 | type | 文本输入 |
| 21 | window | 窗口管理 |

### B.6 JSON 输出处理技巧

```bash
# 使用 Python 解析 JSON 输出
peekaboo app list --json 2>&1 | python3 -c "
import sys, json
d = json.load(sys.stdin)
for app in d['data']['apps'][:5]:
    print(f\"{app['name']} (PID: {app['pid']})\")
"

# 查找特定应用
peekaboo app list --json 2>&1 | python3 -c "
import sys, json
d = json.load(sys.stdin)
apps = [a['name'] for a in d['data']['apps'] if 'chrome' in a['name'].lower()]
print('Found:', apps)
"
```

### B.7 已知问题与注意事项

1. **命令超时**: `image` 和 `see` 命令虽然成功生成截图，但会报超时错误（30s+），这是 beta 版本的已知问题
2. **Snapshot 缓存**: 某些命令依赖 snapshot 缓存，如果报错 `SNAPSHOT_NOT_FOUND`，需要重新运行 `see` 命令
3. **Daemon 启动**: `daemon start` 可能需要完整 App 支持才能正常工作

### B.8 为明天测试 Hopp 的准备

已验证的可用于 Hopp 测试的命令：

```bash
# 1. 截图验证 UI
peekaboo image --mode screen --path /tmp/hopp_test/step1.png

# 2. 获取应用窗口信息
peekaboo window list --app hopp

# 3. 捕获带元素标注的 UI
peekaboo see --app hopp --annotate --path /tmp/hopp_test/ui_annotated.png

# 4. 点击操作（需要先用 see 获取元素 ID）
# peekaboo click --on B1 --app hopp

# 5. 输入文本
# peekaboo type "https://api.example.com" --app hopp

# 6. 快捷键
peekaboo hotkey "cmd,n"  # 新建窗口
```

---

*这份笔记由 AI 助手整理，记录于 2026-03-11，用于明天进行 Hopp 应用的自动化 UI 测试。*


### B.9 菜单命令练习

```bash
# 获取 Finder 的完整菜单结构
peekaboo menu list --app Finder

# 输出示例（部分）:
# Menu structure for Finder:
# Apple
#   About This Mac
#   System Information
#   System Settings…
#   Recent Items
#     hopp
#     Postman
#     Typora
#     ...
# File
#   New Finder Window [⌘N]
#   New Folder [⇧⌘N]
#   ...
```

### B.10 open 命令练习

```bash
# 打开 URL
peekaboo open https://example.com --json-output

# 用指定应用打开文件
peekaboo open ~/Documents/report.pdf --app "Preview" --wait-until-ready

# 后台打开（不聚焦）
peekaboo open ~/myfile.txt --bundle-id com.apple.TextEdit --no-focus
```

### B.11 明天测试准备清单

#### 已验证可用命令
- [x] `peekaboo permissions status`
- [x] `peekaboo app list --json`
- [x] `peekaboo window list --app <name>`
- [x] `peekaboo dock list`
- [x] `peekaboo image --mode screen --path <path>`
- [x] `peekaboo see --app <name> --annotate --path <path>`
- [x] `peekaboo sleep <ms>`
- [x] `peekaboo hotkey <keys>`
- [x] `peekaboo click --coords x,y`
- [x] `peekaboo menu list --app <name>`
- [x] `peekaboo config init`
- [x] `peekaboo tools --json`

#### 测试脚本已准备
脚本位置: `/Volumes/hagibis1t/huicom/github/postman/scripts/peekaboo_test_hopp.sh`

使用方式:
```bash
# 1. 确保 Hopp 应用已运行
open /Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Release/hopp.app

# 2. 运行测试脚本
/Volumes/hagibis1t/huicom/github/postman/scripts/peekaboo_test_hopp.sh

# 3. 查看测试结果
ls -la /tmp/hopp_peekaboo_test_*/
```

#### 需要明天验证的功能
- [ ] `peekaboo see --app hopp --json-output` 获取 UI 元素 ID
- [ ] `peekaboo click --on <element_id> --app hopp` 点击指定元素
- [ ] `peekaboo type "<url>" --app hopp` 输入 URL
- [ ] `peekaboo click "Send" --app hopp` 点击 Send 按钮
- [ ] 响应结果验证（截图对比）

