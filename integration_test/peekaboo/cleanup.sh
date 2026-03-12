#!/bin/bash
#
# 清理 Hopp 测试环境
# 用于重置测试状态
#

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp - 测试环境清理"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 停止应用
echo "📋 Step 1: 停止 Hopp 应用"
if pgrep -x "hopp" > /dev/null; then
    pkill -x "hopp"
    sleep 2
    echo -e "${GREEN}✅ 应用已停止${NC}"
else
    echo -e "${YELLOW}⚠️  应用未运行${NC}"
fi
echo ""

# 2. 清理 Hive 锁文件
echo "📋 Step 2: 清理数据库锁文件"
LOCK_DIR="$HOME/Library/Containers/com.example.hopp/Data/Documents/hopp"
if [ -d "$LOCK_DIR" ]; then
    rm -f "$LOCK_DIR"/*.lock
    echo -e "${GREEN}✅ 锁文件已清理${NC}"
else
    echo -e "${YELLOW}⚠️  数据目录不存在${NC}"
fi
echo ""

# 3. 清理测试截图
echo "📋 Step 3: 清理测试截图"
echo "   保留截图目录:"
echo "     /tmp/hopp_test_*"
read -p "   是否删除所有测试截图? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /tmp/hopp_test_*
    echo -e "${GREEN}✅ 测试截图已清理${NC}"
else
    echo -e "${YELLOW}⚠️  跳过截图清理${NC}"
fi
echo ""

# 4. 清理日志（可选）
echo "📋 Step 4: 清理日志文件"
LOG_DIR="$HOME/Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs"
read -p "   是否删除所有日志文件? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$LOG_DIR" ]; then
        rm -f "$LOG_DIR"/*.log
        echo -e "${GREEN}✅ 日志文件已清理${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  跳过日志清理${NC}"
fi
echo ""

# 5. 重置应用数据（危险操作）
echo "📋 Step 5: 重置应用数据"
echo "   ⚠️  警告: 这将删除所有保存的请求和集合！"
read -p "   是否重置所有应用数据? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    APP_DATA="$HOME/Library/Containers/com.example.hopp"
    if [ -d "$APP_DATA" ]; then
        rm -rf "$APP_DATA"
        echo -e "${GREEN}✅ 应用数据已重置${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  跳过数据重置${NC}"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo -e "${GREEN}  ✅ 清理完成！${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 提示:"
echo "   - 重新启动应用: ./run_full_test.sh"
echo "   - 查看日志: ./view_logs.sh"
