#!/usr/bin/env python3
"""
Hopp UI 测试 - URL 输入框 Focus 状态对齐验证

测试内容:
1. 创建新请求
2. 设置 URL
3. 触发 URL 输入框 focus 状态
4. 截图验证边框对齐

使用方法:
    python test_url_input_focus.py [--port PORT]

截图验证:
    - url_focus_state.png: URL 输入框 focus 状态（紫色边框与灰色区域对齐）
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path

# 导入测试客户端
from test_client import HoppTestClient


def run_test(port=None):
    """执行 URL 输入框 focus 状态测试"""
    client = HoppTestClient(port=port)
    screenshots = []
    
    print("\n" + "="*60)
    print("🧪 Hopp UI 测试 - URL 输入框 Focus 状态对齐验证")
    print("="*60 + "\n")
    
    try:
        # 1. 测试连接
        print("📍 测试 1: 基础连接")
        client.ping()
        print("✅ 连接成功\n")
        
        # 2. 创建新请求
        print("📍 测试 2: 创建新请求")
        client.create_request()
        print("✅ 请求创建成功\n")
        
        # 3. 设置 URL
        print("📍 测试 3: 设置 URL")
        client.set_url("https://httpbin.org/get")
        print("✅ URL 设置成功\n")
        
        # 等待 UI 稳定
        time.sleep(0.5)
        
        # 4. 截图 - 非 focus 状态
        print("📍 测试 4: 截图 - 非 focus 状态")
        screenshot_path = str(Path.cwd() / "url_unfocused.png")
        subprocess.run(["screencapture", "-x", screenshot_path], check=True)
        screenshots.append(("非 focus 状态", screenshot_path))
        print(f"✅ 截图已保存: {screenshot_path}\n")
        
        # 5. 触发 focus 状态
        print("📍 测试 5: 触发 URL 输入框 focus 状态")
        client.focus_url_input()
        time.sleep(0.5)  # 等待 focus 动画
        print("✅ Focus 状态已触发\n")
        
        # 6. 截图 - focus 状态
        print("📍 测试 6: 截图 - focus 状态（验证边框对齐）")
        screenshot_path = str(Path.cwd() / "url_focus_state.png")
        subprocess.run(["screencapture", "-x", screenshot_path], check=True)
        screenshots.append(("focus 状态", screenshot_path))
        print(f"✅ 截图已保存: {screenshot_path}\n")
        
        # 7. 验证 UI 信息
        print("📍 测试 7: 验证 UI 信息")
        info = client.get_ui_info()
        assert info.get('has_active_request') == True, "应该有活动请求"
        assert info.get('active_request_url') == "https://httpbin.org/get", "URL 应该匹配"
        print("✅ UI 信息验证通过\n")
        
        # 测试完成
        print("="*60)
        print("✅ 所有测试通过!")
        print("="*60)
        print("\n📸 截图文件:")
        for desc, path in screenshots:
            print(f"   - {desc}: {path}")
        print("\n📝 验证要点:")
        print("   1. url_focus_state.png 中紫色边框应该与灰色背景区域完全对齐")
        print("   2. URL 文字应该垂直居中")
        print("   3. 边框高度应该与 Method 下拉框一致（36px）")
        print()
        
        return {"success": True, "screenshots": screenshots}
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        return {"success": False, "error": str(e)}


def main():
    parser = argparse.ArgumentParser(
        description="URL 输入框 Focus 状态对齐验证",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--port", type=int, help="测试服务器端口（可选）")
    
    args = parser.parse_args()
    
    result = run_test(port=args.port)
    
    if not result.get("success"):
        sys.exit(1)


if __name__ == "__main__":
    main()
