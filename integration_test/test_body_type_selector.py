#!/usr/bin/env python3
"""
Hopp Body 类型选择器测试脚本

测试 Postman 风格的 Body 类型选择器功能：
1. Body 类型 Radio 组（none/form-data/x-www-form-urlencoded/raw/binary/GraphQL）
2. Raw 子类型下拉菜单（Text/JavaScript/JSON/HTML/XML）

使用方法:
    python test_body_type_selector.py [--port PORT]
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
        # 截图（-o 表示只截取前台窗口，-w 表示包含窗口阴影）
        subprocess.run(["screencapture", "-o", filename], check=True)
        print(f"   📸 截图已保存: {filename}")
    except Exception as e:
        print(f"   ⚠️ 截图失败: {e}")


def test_body_type_selector(port=None):
    """测试 Body 类型选择器"""
    client = HoppTestClient(port=port)
    
    print("\n" + "="*60)
    print("🧪 Hopp Body 类型选择器测试")
    print("="*60 + "\n")
    
    # 1. 测试连接
    print("1️⃣ 测试连接...")
    client.ping()
    print()
    
    # 2. 创建新请求
    print("2️⃣ 创建新请求...")
    client.create_request()
    print()
    
    # 3. 切换到 Body Tab
    print("3️⃣ 切换到 Body Tab...")
    client.switch_request_tab("body")
    time.sleep(2)  # 增加等待时间确保界面切换完成
    capture_screenshot("test_body_initial.png")
    print()
    
    # 4. 测试各种 Body 类型
    body_types = [
        ("none", "无 Body"),
        ("form-data", "表单数据"),
        ("x-www-form-urlencoded", "URL 编码表单"),
        ("raw", "原始文本"),
        ("binary", "二进制文件"),
        ("graphql", "GraphQL"),
    ]
    
    print("4️⃣ 测试各种 Body 类型...")
    for body_type, description in body_types:
        print(f"\n   测试 {body_type} ({description})...")
        client.set_body_type(body_type)
        time.sleep(1.5)  # 增加等待时间确保界面更新
        capture_screenshot(f"test_body_{body_type.replace('-', '_')}.png")
        
        # 如果是 raw 类型，测试所有子类型
        if body_type == "raw":
            print("   \n   📄 测试 Raw 子类型...")
            content_types = [
                ("text", "Text"),
                ("javascript", "JavaScript"),
                ("json", "JSON"),
                ("html", "HTML"),
                ("xml", "XML"),
            ]
            for content_type, ct_description in content_types:
                print(f"      切换至 {ct_description}...")
                client.set_raw_content_type(content_type)
                time.sleep(0.5)
                capture_screenshot(f"test_body_raw_{content_type}.png")
    
    print("\n5️⃣ 获取最终 Body 信息...")
    client.get_body_info()
    
    print("\n" + "="*60)
    print("✅ 所有测试完成！")
    print("="*60)
    print("\n📸 截图文件:")
    print("   - test_body_initial.png")
    for body_type, _ in body_types:
        print(f"   - test_body_{body_type.replace('-', '_')}.png")
        if body_type == "raw":
            for content_type in ["text", "javascript", "json", "html", "xml"]:
                print(f"   - test_body_raw_{content_type}.png")
    print()
    
    return {"success": True}


def test_raw_with_content(port=None):
    """测试 Raw 类型带内容"""
    client = HoppTestClient(port=port)
    
    print("\n" + "="*60)
    print("🧪 Raw 类型内容编辑测试")
    print("="*60 + "\n")
    
    # 创建请求
    client.create_request()
    client.switch_request_tab("body")
    
    # 设置 Body 类型为 raw
    print("1️⃣ 设置 Body 类型为 raw...")
    client.set_body_type("raw")
    
    # 设置 JSON 内容
    print("2️⃣ 设置 JSON 内容...")
    json_content = '{\n  "username": "test",\n  "password": "123456"\n}'
    client.set_body(json_content, "json")
    time.sleep(1)
    capture_screenshot("test_body_raw_with_content.png")
    
    # 切换 Raw 子类型
    print("3️⃣ 切换 Raw 子类型...")
    for content_type in ["javascript", "html", "xml", "text"]:
        client.set_raw_content_type(content_type)
        time.sleep(0.5)
    
    print("\n✅ Raw 类型测试完成！")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="Hopp Body 类型选择器测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 运行完整测试
  %(prog)s --port 8080        # 使用指定端口
  %(prog)s --raw-only         # 只测试 Raw 类型
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口")
    parser.add_argument("--raw-only", action="store_true", help="只测试 Raw 类型")
    
    args = parser.parse_args()
    
    try:
        if args.raw_only:
            test_raw_with_content(port=args.port)
        else:
            test_body_type_selector(port=args.port)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
