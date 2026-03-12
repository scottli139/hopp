# Hopp - Peekaboo 自动化测试 Makefile
# 使用方式: make <target>

.PHONY: help test quick clean logs menu test-basic test-tabs test-save

# 默认目标
help:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "  Hopp - Peekaboo 自动化测试"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "可用命令:"
	@echo ""
	@echo "  make test       - 运行完整测试套件"
	@echo "  make quick      - 快速测试 (创建 + 发送 + 截图)"
	@echo "  make test-basic - 运行基本请求测试"
	@echo "  make test-tabs  - 运行多标签页测试"
	@echo "  make test-save  - 运行保存请求测试"
	@echo ""
	@echo "  make logs       - 查看实时日志 (tail -f)"
	@echo "  make logs-error - 查看错误日志"
	@echo "  make menu       - 查看应用菜单结构"
	@echo ""
	@echo "  make clean      - 清理测试环境"
	@echo "  make reset      - 重置应用数据"
	@echo ""
	@echo "  make help       - 显示此帮助"
	@echo ""

# 测试命令
test:
	@bash run_full_test.sh

quick:
	@bash quick_test.sh

test-basic:
	@bash test_basic_request.sh

test-tabs:
	@bash test_multiple_tabs.sh

test-save:
	@bash test_save_collection.sh

# 日志相关
logs:
	@bash view_logs.sh tail

logs-error:
	@bash view_logs.sh errors

logs-menu:
	@bash view_logs.sh menu

logs-http:
	@bash view_logs.sh http

# 菜单查看
menu:
	@peekaboo menu list --app "hopp"

# 清理
clean:
	@bash cleanup.sh

reset:
	@echo "⚠️  即将重置所有应用数据..."
	@pkill -x "hopp" 2>/dev/null || true
	@sleep 1
	@rm -rf ~/Library/Containers/com.example.hopp
	@echo "✅ 应用数据已重置，请重新启动应用"

# 应用控制
app-start:
	@echo "🚀 启动 Hopp 应用..."
	@/Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp &
	@sleep 3
	@echo "✅ 应用已启动"

app-stop:
	@echo "🛑 停止 Hopp 应用..."
	@pkill -x "hopp" 2>/dev/null || true
	@sleep 1
	@echo "✅ 应用已停止"

app-focus:
	@peekaboo app switch --to "hopp"
	@echo "✅ 应用已切换到前台"

# 开发工具
build:
	@echo "🔨 构建 Hopp 应用..."
	@cd /Volumes/hagibis1t/huicom/github/postman && fvm flutter build macos --debug
	@echo "✅ 构建完成"

# 单次操作
new-request:
	@peekaboo menu click --app "hopp" --path "File > New Request"

send-request:
	@peekaboo menu click --app "hopp" --path "Edit > Send Request"

save-request:
	@peekaboo menu click --app "hopp" --path "File > Save"

close-tab:
	@peekaboo menu click --app "hopp" --path "File > Close Tab"

# 截图
screenshot:
	@screencapture -x /tmp/hopp_screenshot_$(shell date +%s).png
	@echo "📸 截图已保存到 /tmp/"
