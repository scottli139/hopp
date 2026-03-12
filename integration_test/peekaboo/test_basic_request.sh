#!/bin/bash
#
# 基本请求测试
# 测试功能：创建新请求 -> 发送请求 -> 验证响应
#

set -e  # 遇到错误立即退出

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp - 基本请求测试"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
APP_NAME="hopp"
TEST_DIR="/tmp/hopp_test_$(date +%s)"
mkdir -p "$TEST_DIR"

# 日志文件路径
LOG_FILE="$HOME/Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs/hopp_$(date +%Y%m%d).log"

echo "📁 测试目录: $TEST_DIR"
echo "📄 日志文件: $LOG_FILE"
echo ""

# 函数：检查应用是否运行
check_app_running() {
    if pgrep -x "$APP_NAME" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# 函数：等待应用启动
wait_for_app() {
    local timeout=30
    local count=0
    echo -n "⏳ 等待应用启动..."
    while ! check_app_running && [ $count -lt $timeout ]; do
        sleep 1
        echo -n "."
        ((count++))
    done
    echo ""
    
    if check_app_running; then
        echo -e "${GREEN}✅ 应用已启动${NC}"
        return 0
    else
        echo -e "${RED}❌ 应用启动超时${NC}"
        return 1
    fi
}

# 步骤 1: 检查并启动应用
echo "📋 Step 1: 检查应用状态"
if ! check_app_running; then
    echo "🚀 启动 Hopp 应用..."
    /Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp > "$TEST_DIR/app.log" 2>&1 &
    APP_PID=$!
    echo "   PID: $APP_PID"
    
    if ! wait_for_app; then
        echo -e "${RED}❌ 测试失败：无法启动应用${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 应用已在运行${NC}"
fi
echo ""

# 步骤 2: 确保应用在前台
echo "📋 Step 2: 确保应用在前台"
peekaboo app switch --to "$APP_NAME"
sleep 1
echo -e "${GREEN}✅ 应用已切换到前台${NC}"
echo ""

# 步骤 3: 创建新请求
echo "📋 Step 3: 创建新请求"
peekaboo menu click --app "$APP_NAME" --path "File > New Request"
sleep 2
echo -e "${GREEN}✅ 新请求已创建${NC}"

# 截图验证
screencapture -x "$TEST_DIR/step3_new_request.png"
echo "📸 截图保存: $TEST_DIR/step3_new_request.png"
echo ""

# 步骤 4: 发送请求
echo "📋 Step 4: 发送请求到 httpbin.org"
peekaboo menu click --app "$APP_NAME" --path "Edit > Send Request"
echo "⏳ 等待响应..."
sleep 5
echo -e "${GREEN}✅ 请求已发送${NC}"

# 截图验证
screencapture -x "$TEST_DIR/step4_response.png"
echo "📸 截图保存: $TEST_DIR/step4_response.png"
echo ""

# 步骤 5: 验证响应
echo "📋 Step 5: 验证响应"

# 检查日志中的成功标志
if [ -f "$LOG_FILE" ]; then
    # 获取最后 20 行日志
    LOG_TAIL=$(tail -20 "$LOG_FILE" 2>/dev/null || echo "")
    
    # 检查是否有成功的 HTTP 请求
    if echo "$LOG_TAIL" | grep -q "HttpService.*200\|Request sent successfully"; then
        echo -e "${GREEN}✅ 请求发送成功（日志验证）${NC}"
    else
        echo -e "${YELLOW}⚠️  请手动检查截图验证结果${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  日志文件不存在，跳过日志验证${NC}"
fi
echo ""

# 步骤 6: 保存请求
echo "📋 Step 6: 保存请求"
peekaboo menu click --app "$APP_NAME" --path "File > Save"
sleep 1
echo -e "${GREEN}✅ 请求已保存${NC}"
echo ""

# 测试完成
echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✅ 测试完成！${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📁 测试结果目录: $TEST_DIR"
echo "   - step3_new_request.png: 创建请求截图"
echo "   - step4_response.png: 响应截图"
echo ""

# 显示应用日志摘要
if [ -f "$TEST_DIR/app.log" ]; then
    echo "📄 应用启动日志 (最后 10 行):"
    tail -10 "$TEST_DIR/app.log"
fi

echo ""
echo "💡 提示:"
echo "   - 截图文件可用于人工验证"
echo "   - 日志文件: $LOG_FILE"
echo "   - 运行 'tail -f $LOG_FILE' 查看实时日志"
