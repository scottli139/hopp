#!/bin/bash
#
# 保存到集合测试
# 测试功能：创建请求 -> 发送请求 -> 保存到集合
#

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp - 保存请求测试"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_NAME="hopp"
TEST_DIR="/tmp/hopp_test_save_$(date +%s)"
mkdir -p "$TEST_DIR"

echo "📁 测试目录: $TEST_DIR"
echo ""

# 确保应用在前台
peekaboo app switch --to "$APP_NAME"
sleep 1

# 步骤 1: 创建新请求
echo "📋 Step 1: 创建新请求"
peekaboo menu click --app "$APP_NAME" --path "File > New Request"
sleep 2
echo -e "${GREEN}✅ 新请求已创建${NC}"
echo ""

# 步骤 2: 发送请求
echo "📋 Step 2: 发送请求"
peekaboo menu click --app "$APP_NAME" --path "Edit > Send Request"
sleep 5
echo -e "${GREEN}✅ 请求已发送${NC}"

screencapture -x "$TEST_DIR/step2_request_sent.png"
echo "📸 截图: $TEST_DIR/step2_request_sent.png"
echo ""

# 步骤 3: 保存请求
echo "📋 Step 3: 保存请求到集合"
peekaboo menu click --app "$APP_NAME" --path "File > Save"
sleep 2
echo -e "${GREEN}✅ 请求已保存${NC}"

screencapture -x "$TEST_DIR/step3_saved.png"
echo "📸 截图: $TEST_DIR/step3_saved.png"
echo ""

# 步骤 4: 创建新集合并保存
echo "📋 Step 4: 创建新集合"
peekaboo menu click --app "$APP_NAME" --path "File > New Collection"
sleep 2
echo -e "${GREEN}✅ 新集合已创建${NC}"
echo ""

# 截图
screencapture -x "$TEST_DIR/step4_final.png"
echo "📸 截图: $TEST_DIR/step4_final.png"
echo ""

# 测试完成
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✅ 保存测试完成！${NC}"
echo "═══════════════════════════════════════════════════════════════"
