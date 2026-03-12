#!/bin/bash
#
# 多标签页测试
# 测试功能：创建多个请求标签页 -> 切换标签 -> 关闭标签
#

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp - 多标签页测试"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_NAME="hopp"
TEST_DIR="/tmp/hopp_test_tabs_$(date +%s)"
mkdir -p "$TEST_DIR"

echo "📁 测试目录: $TEST_DIR"
echo ""

# 确保应用在前台
peekaboo app switch --to "$APP_NAME"
sleep 1

# 步骤 1: 创建多个请求
echo "📋 Step 1: 创建 5 个新请求标签页"
for i in {1..5}; do
    echo "   创建标签页 $i..."
    peekaboo menu click --app "$APP_NAME" --path "File > New Request"
    sleep 1
done
echo -e "${GREEN}✅ 已创建 5 个标签页${NC}"
echo ""

# 截图
screencapture -x "$TEST_DIR/step1_multiple_tabs.png"
echo "📸 截图保存: $TEST_DIR/step1_multiple_tabs.png"
echo ""

# 步骤 2: 使用快捷键切换标签（Cmd+1, Cmd+2 等）
echo "📋 Step 2: 测试标签切换快捷键"
# 注意：这些快捷键可能不工作，但会尝试
for i in {1..3}; do
    echo "   切换到标签 $i..."
    peekaboo hotkey --keys "cmd,$i" 2>/dev/null || echo "   (快捷键可能未触发)"
    sleep 0.5
done
echo -e "${GREEN}✅ 标签切换测试完成${NC}"
echo ""

# 步骤 3: 关闭部分标签
echo "📋 Step 3: 关闭 3 个标签页"
for i in {1..3}; do
    echo "   关闭标签页..."
    peekaboo menu click --app "$APP_NAME" --path "File > Close Tab"
    sleep 1
done
echo -e "${GREEN}✅ 已关闭 3 个标签页${NC}"
echo ""

# 截图
screencapture -x "$TEST_DIR/step3_after_close.png"
echo "📸 截图保存: $TEST_DIR/step3_after_close.png"
echo ""

# 测试完成
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✅ 多标签页测试完成！${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📁 测试结果:"
echo "   - $TEST_DIR/step1_multiple_tabs.png: 多标签页截图"
echo "   - $TEST_DIR/step3_after_close.png: 关闭后截图"
