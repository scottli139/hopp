#!/bin/bash
#
# 完整测试套件运行脚本
# 运行所有 Peekaboo 自动化测试
#

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp - Peekaboo 完整测试套件"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "开始时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 测试结果汇总
PASSED=0
FAILED=0
TOTAL=0

# 运行单个测试的函数
run_test() {
    local test_name=$1
    local test_script=$2
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${BLUE}▶ 运行测试: $test_name${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    ((TOTAL++))
    
    if [ -f "$test_script" ]; then
        if bash "$test_script"; then
            echo ""
            echo -e "${GREEN}✅ $test_name - 通过${NC}"
            ((PASSED++))
        else
            echo ""
            echo -e "${RED}❌ $test_name - 失败${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${RED}❌ 测试脚本不存在: $test_script${NC}"
        ((FAILED++))
    fi
}

# 前置检查
echo "📋 前置检查"
echo "───────────────────────────────────────────────────────────────"

# 检查 Peekaboo
if ! command -v peekaboo &> /dev/null; then
    echo -e "${RED}❌ Peekaboo CLI 未安装${NC}"
    echo "   请运行: brew install peekaboo"
    exit 1
fi
echo -e "${GREEN}✅ Peekaboo CLI 已安装${NC}"

# 检查 Hopp 应用
if ! pgrep -x "hopp" > /dev/null; then
    echo -e "${YELLOW}⚠️  Hopp 应用未运行，尝试启动...${NC}"
    
    if [ -d "/Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Debug/hopp.app" ]; then
        /Volumes/hagibis1t/huicom/github/postman/build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp &
        sleep 5
    else
        echo -e "${RED}❌ 未找到 Hopp 应用，请手动启动${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ Hopp 应用已运行${NC}"
echo ""

# 运行所有测试
echo "═══════════════════════════════════════════════════════════════"
echo "  开始运行测试"
echo "═══════════════════════════════════════════════════════════════"

run_test "基本请求测试" "$SCRIPT_DIR/test_basic_request.sh"
run_test "多标签页测试" "$SCRIPT_DIR/test_multiple_tabs.sh"
run_test "保存集合测试" "$SCRIPT_DIR/test_save_collection.sh"

# 测试结果汇总
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  测试结果汇总"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo "总计: $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}⚠️  部分测试失败，请检查日志${NC}"
    exit 1
fi
