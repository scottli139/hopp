# GitHub 仓库设置指南

> 配置 GitHub 仓库的 About 信息，提升项目可发现性

---

## 📋 Description（仓库描述）

### 推荐描述（English - 默认）

**简短描述（适合 GitHub 主页显示）：**
```
🐰 Hopp - A lightweight, cross-platform API testing tool built with Flutter. 100% AI-developed by Kimi.
```

**完整描述（项目 About 区域）：**
```
🐰 Hopp - A lightweight, cross-platform API testing tool and open-source alternative to Postman.

Built with ❤️ using Flutter 3.27.x + Dart + Riverpod. 
🤖 100% AI-developed by Kimi Code CLI (Kimi K3 & DeepSeek V4 Pro)

Features:
• 🚀 Lightweight & Fast - Native performance with Flutter
• 💻 Cross-platform (macOS, Windows, Linux)
• 🔧 Full-featured (HTTP/HTTPS, Collections, Environments, Pre-request chain)
• 🔐 Environment variables with {{var}} interpolation & secret masking
• ✅ Lightweight assertions + hopp run CLI for CI
• 📥 OpenAPI/Swagger import (3.x + 2.0, file or URL)
• 🌍 Multi-language (English & 简体中文)
• 📊 Collections management with nested folders
• 🎨 Material Design 3 with Dark/Light theme support
```

### 中文描述（备用）

```
🐰 Hopp - 轻量级跨平台 API 测试工具，Postman 的开源替代品。

使用 Flutter 3.27.x + Dart + Riverpod 构建。
🤖 100% AI 开发：由 Kimi Code CLI（Kimi K3 & DeepSeek V4 Pro）开发
```

---

## 🏷️ Topics（主题标签）

### 推荐 Topics（按优先级排序）

#### 核心技术（必选）
| Topic | 说明 |
|-------|------|
| `api-testing` | API 测试工具 - 核心关键词 |
| `postman-alternative` | Postman 替代品 - 用户搜索词 |
| `http-client` | HTTP 客户端 |
| `rest-api` | REST API 测试 |
| `flutter` | Flutter 框架 |
| `dart` | Dart 语言 |
| `riverpod` | Riverpod 状态管理 |

#### 功能特性
| Topic | 说明 |
|-------|------|
| `websocket` | WebSocket 支持 |
| `cross-platform` | 跨平台应用 |
| `desktop-app` | 桌面应用 |
| `developer-tools` | 开发者工具 |

#### AI 相关（突出特色）
| Topic | 说明 |
|-------|------|
| `ai-developed` | AI 开发的项目 |
| `kimi-ai` | Kimi AI 标识 |

#### 开源相关
| Topic | 说明 |
|-------|------|
| `open-source` | 开源项目 |
| `mit-license` | MIT 许可证 |

### 完整的 Topics 列表（复制到 GitHub）

```
api-testing, postman-alternative, http-client, rest-api, developer-tools, 
flutter, dart, riverpod, desktop-app, cross-platform, 
ai-developed, open-source
```

**GitHub 限制**：最多 20 个 topics，建议选择最相关的 10-15 个

---

## 🔧 如何在 GitHub 设置

### 步骤 1：进入仓库设置
1. 打开 https://github.com/scottli139/hopp
2. 点击右侧的 **⚙️ Settings** 齿轮图标（或 About 区域的 ⚙️）

### 步骤 2：设置 Description
1. 在 "Description" 字段粘贴推荐描述
2. 在 "Website" 字段填写：https://scottli139.github.io/hopp

### 步骤 3：设置 Topics
1. 在 "Topics" 区域点击输入框
2. 逐个添加推荐的 topics（输入时会自动提示）
3. 按回车确认每个 topic

### 步骤 4：保存
- 设置会自动保存
- 刷新页面查看效果

---

## 📊 SEO 优化建议

### 为什么选择这些 Topics？

1. **api-testing** - 月搜索量最高的相关词
2. **postman-alternative** - 用户寻找替代品时的常用搜索词
3. **flutter** + **dart** - Flutter 社区用户可能会关注
4. **ai-developed** - 突出项目特色，吸引关注 AI 开发的用户

### Description 关键词优化

确保 description 包含以下关键词：
- ✅ API testing tool
- ✅ Postman alternative
- ✅ Flutter
- ✅ Cross-platform
- ✅ Open source
- ✅ AI developed (突出特色)

---

## 🎯 设置后的效果预览

设置完成后，GitHub 仓库首页将显示：

```
🐰 Hopp - A lightweight, cross-platform API testing tool built with Flutter. 100% AI-developed by Kimi.

🏷️ api-testing · postman-alternative · http-client · rest-api · flutter · dart · riverpod · desktop-app · ai-developed

🌐 https://scottli139.github.io/hopp
```

---

## 📌 附加建议

### 设置 Social Preview（社交预览图）
1. 在 Settings → General → Social preview 上传图片
2. 推荐尺寸：1280×640 px
3. 可包含：Logo + 项目名称 + 简短标语

### 启用 Discussion（讨论区）
1. Settings → General → Discussions
2. 勾选 "Enable discussions"
3. 用于用户反馈和功能讨论

### 设置 Release 标签
- 发布版本时使用语义化版本号：v0.1.0, v0.2.0 等
- 添加详细的 Release Notes
- 推送 `v*` tag 自动触发 CI 三平台构建，并经 `softprops/action-gh-release` 上传 zip 附件；macOS 签名 dmg 由维护者本地构建后手动上传到对应 release（见 TESTING.md CI/CD 一节）

---

## 🌐 GitHub Pages 站点

Hopp 的文档站由 `.github/workflows/pages.yml` 自动部署到 https://scottli139.github.io/hopp。

### 站点源目录 `site/`

站点源文件独立于 workflow 维护，便于直接编辑与复用：

```
site/
├── index.html          # 英文首页（landing + 文档中心）
├── index.zh-CN.html    # 简体中文首页
└── styles.css          # 共享样式
```

### 部署流程

1. 推送到 `main` 分支，且变更涉及 `site/**`、`docs/**`、`README*.md` 或 workflow 自身时触发
2. workflow 将 `site/` 与 `LICENSE` 复制到 `_site/` 后上传 artifact
3. `actions/deploy-pages` 发布到 GitHub Pages

### 首页内容

首页集中展示：功能特性、快速开始、架构与项目结构、技术栈、测试统计、完整文档索引、贡献指南与许可证。文档索引链接到 GitHub 上的 Markdown 渲染页，保证阅读体验。

### 修改站点

- 修改页面内容：编辑 `site/index.html` 或 `site/index.zh-CN.html`
- 修改样式：编辑 `site/styles.css`
- 本地预览：直接用浏览器打开 `site/index.html`
