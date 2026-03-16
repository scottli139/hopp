#!/usr/bin/env python3
"""
Hopp Dropdown 样式测试脚本

测试 METHOD dropdown 和 Raw Content Type dropdown 的样式，
获取截图用于样式改进前后对比。

使用方法:
    python test_dropdown_style.py [--port PORT]
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path

# 添加当前目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def capture_screenshot(filename):
    """捕获屏幕截图（确保 Hopp 在前台）"""
    try:
        # 先激活 Hopp 窗口到前台
        subprocess.run(
            ["osascript", "-e", 'tell application "Hopp" to activate'],
            check=True,
            capture_output=True
        )
        # 等待窗口激活
        time.sleep(0.5)
        # 截图
        subprocess.run(["screencapture", "-o", filename], check=True)
        print(f"   📸 截图已保存: {filename}")
    except Exception as e:
        print(f"   ⚠️ 截图失败: {e}")


def test_method_dropdown(port=None):
    """测试 Method Dropdown 样式"""
    client = HoppTestClient(port=port)
    
    print("\n" + "="*60)
    print("🧪 Method Dropdown 样式测试")
    print("="*60 + "\n")
    
    # 1. 测试连接
    print("1️⃣ 测试连接...")
    client.ping()
    print()
    
    # 2. 创建新请求
    print("2️⃣ 创建新请求...")
    client.create_request()
    print()
    
    # 3. 展开 Method Dropdown
    print("3️⃣ 展开 Method Dropdown...")
    client.expand_method_dropdown()
    time.sleep(2.5)  # 增加等待时间确保菜单展开
    capture_screenshot("test_method_dropdown_open.png")
    print()
    
    # 4. 测试不同 Method
    print("4️⃣ 测试不同 Method...")
    methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]
    for method in methods:
        print(f"   切换到 {method}...")
        client.set_method(method)
        time.sleep(0.5)
    capture_screenshot("test_method_changed.png")
    print()
    
    print("✅ Method Dropdown 测试完成！")
    return {"success": True}


def test_raw_content_type_dropdown(port=None):
    """测试 Raw Content Type Dropdown 样式"""
    client = HoppTestClient(port=port)
    
    print("\n" + "="*60)
    print("🧪 Raw Content Type Dropdown 样式测试")
    print("="*60 + "\n")
    
    # 1. 测试连接
    print("1️⃣ 测试连接...")
    client.ping()
    print()
    
    # 2. 创建新请求并切换到 Body Tab
    print("2️⃣ 创建新请求...")
    client.create_request()
    client.switch_request_tab("body")
    time.sleep(1)
    print()
    
    # 3. 设置 Body 类型为 raw
    print("3️⃣ 设置 Body 类型为 raw...")
    client.set_body_type("raw")
    time.sleep(1)
    capture_screenshot("test_raw_dropdown_initial.png")
    print()
    
    # 4. 展开 Raw Content Type Dropdown
    print("4️⃣ 展开 Raw Content Type Dropdown...")
    client.expand_raw_content_type_dropdown()
    time.sleep(2.5)  # 增加等待时间确保菜单展开
    capture_screenshot("test_raw_dropdown_open.png")
    print()
    
    # 5. 测试不同 Raw Content Type
    print("5️⃣ 测试不同 Raw Content Type...")
    content_types = ["text", "javascript", "json", "html", "xml"]
    for ct in content_types:
        print(f"   切换到 {ct}...")
        client.set_raw_content_type(ct)
        time.sleep(0.5)
    capture_screenshot("test_raw_content_types.png")
    print()
    
    print("✅ Raw Content Type Dropdown 测试完成！")
    return {"success": True}


def test_all_dropdowns(port=None):
    """测试所有 Dropdown"""
    test_method_dropdown(port)
    test_raw_content_type_dropdown(port)
    
    print("\n" + "="*60)
    print("✅ 所有 Dropdown 样式测试完成！")
    print("="*60)
    print("\n📸 截图文件:")
    print("   - test_method_dropdown_open.png (Method Dropdown 展开)")
    print("   - test_method_changed.png (Method 切换后)")
    print("   - test_raw_dropdown_initial.png (Raw Dropdown 初始)")
    print("   - test_raw_dropdown_open.png (Raw Dropdown 展开)")
    print("   - test_raw_content_types.png (Raw Content Types)")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Hopp Dropdown 样式测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 运行完整测试
  %(prog)s --port 8080        # 使用指定端口
  %(prog)s --method-only      # 只测试 Method Dropdown
  %(prog)s --raw-only         # 只测试 Raw Content Type Dropdown
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口")
    parser.add_argument("--method-only", action="store_true", help="只测试 Method Dropdown")
    parser.add_argument("--raw-only", action="store_true", help="只测试 Raw Content Type Dropdown")
    
    args = parser.parse_args()
    
    try:
        if args.method_only:
            test_method_dropdown(port=args.port)
        elif args.raw_only:
            test_raw_content_type_dropdown(port=args.port)
        else:
            test_all_dropdowns(port=args.port)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
