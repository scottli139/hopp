#!/bin/bash
# Hopp 应用自动化 UI 测试脚本
# 使用 Peekaboo CLI 进行测试
# 创建时间: 2026-03-11

set -e

# 配置
APP_NAME="hopp"
TEST_DIR="/tmp/hopp_peekaboo_test_$(date +%Y%m%d_%H%M%S)"
OUTPUT_JSON="$TEST_DIR/test_results.json"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建测试目录
mkdir -p "$TEST_DIR"
log_info "测试目录: $TEST_DIR"

# ============ 测试步骤 ============

step_1_check_permissions() {
    log_info "步骤 1: 检查权限"
    peekaboo permissions status
    log_info "权限检查完成"
}

step_2_find_app() {
    log_info "步骤 2: 查找 Hopp 应用"
    
    # 尝试从 Dock 查找
    if peekaboo dock list 2>/dev/null | grep -i "$APP_NAME"; then
        log_info "在 Dock 中找到 $APP_NAME"
    fi
    
    # 尝试从运行中的应用查找
    APP_INFO=$(peekaboo app list --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for app in data['data']['apps']:
    if '$APP_NAME'.lower() in app['name'].lower():
        print(f\"Found: {app['name']} (PID: {app['pid']})\")
        break
else:
    print('Not running')
")
    
    if [[ "$APP_INFO" == *"Not running"* ]]; then
        log_warn "$APP_NAME 未运行，需要手动启动"
        return 1
    else
        log_info "$APP_INFO"
    fi
}

step_3_capture_screenshot() {
    log_info "步骤 3: 捕获屏幕截图"
    local screenshot="$TEST_DIR/01_initial_screen.png"
    
    if peekaboo image --mode screen --path "$screenshot" 2>&1 | grep -q "📸"; then
        log_info "截图已保存: $screenshot"
    else
        log_warn "截图可能失败，检查文件..."
    fi
    
    if [ -f "$screenshot" ]; then
        log_info "截图文件大小: $(ls -lh "$screenshot" | awk '{print $5}')"
    fi
}

step_4_list_windows() {
    log_info "步骤 4: 列出 $APP_NAME 窗口"
    
    peekaboo window list --app "$APP_NAME" 2>&1 | tee "$TEST_DIR/02_windows.txt" || {
        log_warn "无法获取窗口列表"
        return 1
    }
}

step_5_capture_ui_map() {
    log_info "步骤 5: 捕获 UI 元素地图"
    local annotated="$TEST_DIR/03_ui_annotated.png"
    local json_output="$TEST_DIR/03_ui_data.json"
    
    # 尝试捕获带注释的 UI
    log_info "尝试捕获带注释的 UI..."
    timeout 45 peekaboo see --app "$APP_NAME" --annotate --path "$annotated" --json-output > "$json_output" 2>&1 || {
        log_warn "see 命令超时或失败，但截图可能已生成"
    }
    
    if [ -f "$annotated" ]; then
        log_info "UI 注释图已保存: $annotated"
    fi
    
    if [ -f "$json_output" ]; then
        log_info "UI JSON 数据已保存: $json_output"
        # 统计元素数量
        local count=$(grep -c '"id"' "$json_output" 2>/dev/null || echo "0")
        log_info "检测到约 $count 个 UI 元素"
    fi
}

step_6_test_basic_interaction() {
    log_info "步骤 6: 测试基本交互"
    
    # 点击屏幕中心（测试 click）
    log_info "测试点击屏幕中心..."
    peekaboo click --coords 720,450 2>&1 | tee "$TEST_DIR/04_click.txt" || {
        log_warn "点击命令可能失败"
    }
    
    peekaboo sleep 500
    
    # 测试快捷键
    log_info "测试快捷键 Command+N..."
    peekaboo hotkey "cmd,n" 2>&1 | tee -a "$TEST_DIR/04_click.txt" || {
        log_warn "快捷键命令可能失败"
    }
    
    peekaboo sleep 500
}

step_7_test_menu() {
    log_info "步骤 7: 测试菜单列表"
    
    peekaboo menu list --app "$APP_NAME" 2>&1 | tee "$TEST_DIR/05_menu.txt" || {
        log_warn "无法获取菜单列表"
    }
}

step_8_final_screenshot() {
    log_info "步骤 8: 最终截图"
    local final="$TEST_DIR/06_final_screen.png"
    
    peekaboo image --mode screen --path "$final" 2>&1 || true
    
    if [ -f "$final" ]; then
        log_info "最终截图已保存: $final"
    fi
}

# ============ 主流程 ============

main() {
    echo "========================================"
    echo "  Hopp 应用 Peekaboo UI 测试"
    echo "  时间: $(date)"
    echo "========================================"
    echo ""
    
    # 检查 peekaboo 是否安装
    if ! command -v peekaboo &> /dev/null; then
        log_error "peekaboo 未安装，请先安装"
        exit 1
    fi
    
    log_info "Peekaboo 版本: $(peekaboo --version)"
    
    # 执行测试步骤
    step_1_check_permissions
    step_2_find_app || true
    step_3_capture_screenshot || true
    step_4_list_windows || true
    step_5_capture_ui_map || true
    step_6_test_basic_interaction || true
    step_7_test_menu || true
    step_8_final_screenshot || true
    
    # 生成报告
    echo ""
    echo "========================================"
    log_info "测试完成！"
    echo "测试目录: $TEST_DIR"
    echo "文件列表:"
    ls -lh "$TEST_DIR/"
    echo "========================================"
}

# 运行主流程
main "$@"
