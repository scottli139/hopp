#!/bin/bash
#
# 快速测试 - 最常用的测试流程
# 创建请求 -> 发送请求 -> 截图
#

APP_NAME="hopp"
TIMESTAMP=$(date +%s)
OUTPUT_DIR="${1:-/tmp}"

echo "🚀 Hopp 快速测试"
echo "───────────────────────────────────────────────────────────────"

# 确保应用在前台
peekaboo app switch --to "$APP_NAME" 2>/dev/null || true
sleep 1

# 创建新请求
echo "1️⃣  创建新请求"
peekaboo menu click --app "$APP_NAME" --path "File > New Request"
sleep 2

# 发送请求
echo "2️⃣  发送请求"
peekaboo menu click --app "$APP_NAME" --path "Edit > Send Request"
sleep 5

# 截图
echo "3️⃣  保存截图"
OUTPUT_FILE="$OUTPUT_DIR/hopp_test_$TIMESTAMP.png"
screencapture -x "$OUTPUT_FILE"

echo ""
echo "✅ 测试完成！"
echo "📸 截图: $OUTPUT_FILE"

# 如果安装了 imgcat (iTerm2)，显示图片
if command -v imgcat &> /dev/null; then
    imgcat "$OUTPUT_FILE"
fi
