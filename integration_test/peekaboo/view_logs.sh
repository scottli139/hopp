#!/bin/bash
#
# 查看 Hopp 日志的便捷脚本
#

LOG_DIR="$HOME/Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs"

if [ ! -d "$LOG_DIR" ]; then
    echo "日志目录不存在: $LOG_DIR"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  Hopp 日志查看器"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "日志目录: $LOG_DIR"
echo ""

# 列出可用的日志文件
echo "可用的日志文件:"
ls -lah "$LOG_DIR"/*.log 2>/dev/null | while read line; do
    echo "  $line"
done
echo ""

# 最新的日志文件
LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "未找到日志文件"
    exit 1
fi

echo "最新日志: $LATEST_LOG"
echo ""

# 根据参数执行不同操作
case "${1:-tail}" in
    "tail"|"t")
        echo "显示最后 50 行 (实时更新 Ctrl+C 退出):"
        tail -50 -f "$LATEST_LOG"
        ;;
    "cat"|"c")
        echo "显示完整日志:"
        cat "$LATEST_LOG"
        ;;
    "errors"|"e")
        echo "显示错误信息:"
        grep -i "error\|exception\|failed" "$LATEST_LOG" | tail -20
        ;;
    "menu"|"m")
        echo "显示菜单相关日志:"
        grep -i "MenuChannel\|menu" "$LATEST_LOG" | tail -20
        ;;
    "http"|"h")
        echo "显示 HTTP 请求日志:"
        grep -i "HttpService\|request\|response" "$LATEST_LOG" | tail -20
        ;;
    *)
        echo "用法: $0 [命令]"
        echo ""
        echo "命令:"
        echo "  tail, t    查看最后 50 行并实时更新 (默认)"
        echo "  cat, c     查看完整日志"
        echo "  errors, e  查看错误信息"
        echo "  menu, m    查看菜单相关日志"
        echo "  http, h    查看 HTTP 请求日志"
        ;;
esac
