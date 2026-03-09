# 贡献指南

感谢您对 Hopp 项目的关注！

## 快速开始

```bash
git clone https://github.com/scottli139/hopp.git
cd hopp
pnpm install
pnpm tauri dev
```

## 提交规范

使用 Conventional Commits：

```
feat: 新功能
fix: Bug 修复
docs: 文档更新
style: 代码格式
refactor: 重构
perf: 性能优化
test: 测试
chore: 构建/依赖
```

## PR 流程

1. Fork 本仓库
2. 创建分支: `git checkout -b feature/your-feature`
3. 提交更改: `git commit -m "feat: add feature"`
4. 推送: `git push origin feature/your-feature`
5. 创建 Pull Request

## 代码规范

- TypeScript 严格模式
- ESLint + Prettier 自动格式化
- Rust: clippy + rustfmt
- 单元测试覆盖率 ≥ 80%

## 许可证

[MIT License](./LICENSE)
