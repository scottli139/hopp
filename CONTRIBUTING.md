# 贡献指南

感谢您对 Hopp 项目的关注！

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

- Dart 严格类型检查
- 使用 `dart format` 格式化代码
- 使用 `dart analyze` 静态分析
- 遵循 Effective Dart 指南
- 单元测试覆盖率 ≥ 80%

## 开发环境要求

- Flutter 3.27+
- Dart 3.6+
- FVM (推荐)

## 许可证

[MIT License](./LICENSE)
