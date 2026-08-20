# 贡献指南

感谢您对 Hopp 项目的关注！欢迎提交 Issue、PR 或参与讨论。

> 参与本项目即表示同意遵守我们的 [行为准则](./CODE_OF_CONDUCT.md)。

## 快速开始

```bash
git clone https://github.com/scottli139/hopp.git
cd hopp

# 安装 FVM (Flutter Version Management)
dart pub global activate fvm

# 使用项目指定的 Flutter 版本
fvm use

# 安装依赖
fvm flutter pub get

# 生成代码 (Freezed, Hive, Riverpod)
fvm dart run build_runner build --delete-conflicting-outputs

# 运行开发
fvm flutter run -d macos
```

## 提交前检查

```bash
# 1. 格式化（CI 会用同样方式检查）
fvm dart format --output=none --set-exit-if-changed lib/ test/

# 2. 静态分析（与 CI 一致，容忍 info，但需 0 error / 0 warning）
fvm flutter analyze --no-fatal-infos

# 3. 重新生成并提交生成文件（*.g.dart / *.freezed.dart）
fvm dart run build_runner build --delete-conflicting-outputs

# 4. 跑测试
fvm flutter test
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
ci: CI/工作流
```

## PR 流程

1. Fork 本仓库
2. 创建分支: `git checkout -b feature/your-feature`
3. 提交更改: `git commit -m "feat: add feature"`
4. 推送: `git push origin feature/your-feature`
5. 创建 Pull Request（请按 PR 模板填写）

## 提交 Issue

- 报告 Bug 请使用「Bug Report」模板
- 提功能建议请使用「Feature Request」模板

## 代码规范

- Dart 严格类型检查
- 使用 `dart format` 格式化代码
- 使用 `dart analyze` 静态分析
- 遵循 Effective Dart 指南
- 单元测试覆盖率 ≥ 80%

## 开发环境要求

- Flutter 3.27+
- Dart 3.6+
- FVM (推荐)

## AI 辅助贡献

本项目本身由 AI 开发。欢迎使用 AI 辅助贡献，但请：

- 在提交前完整运行上方「提交前检查」并确保通过
- 如实说明 AI 参与的部分
- 对生成代码负责（可读性、正确性、测试）

## 许可证

[MIT License](./LICENSE)
