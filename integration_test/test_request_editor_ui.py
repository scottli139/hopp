#!/usr/bin/env python3
"""
Hopp Request Editor UI 测试脚本

测试 Request Editor 的 Tab 样式、Headers/Params 列表 UI 等。

使用方法:
    python test_request_editor_ui.py
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path

from test_client import HoppTestClient


def get_test_client(port=None):
    """获取测试客户端实例"""
    return HoppTestClient(port=port)


def capture_screenshot(filename):
    """截取屏幕并保存"""
    screenshot_path = Path(__file__).parent / filename
    try:
        subprocess.run(
            ["screencapture", "-x", str(screenshot_path)],
            check=True,
            capture_output=True,
        )
        print(f"📸 截图已保存: {screenshot_path}")
        return str(screenshot_path)
    except Exception as e:
        print(f"⚠️ 截图失败: {e}")
        return None


def test_basic_connection(port=None):
    """测试 1: 基础连接"""
    print("\n" + "="*60)
    print("🧪 测试 1: 基础连接")
    print("="*60)
    
    client = get_test_client(port)
    client.ping()
    print("✅ 基础连接测试通过")
    return True


def test_create_request(port=None):
    """测试 2: 创建新请求"""
    print("\n" + "="*60)
    print("🧪 测试 2: 创建新请求")
    print("="*60)
    
    client = get_test_client(port)
    client.create_request()
    time.sleep(0.5)
    print("✅ 创建请求测试通过")
    return True


def test_tab_switching(port=None):
    """测试 3: Tab 切换"""
    print("\n" + "="*60)
    print("🧪 测试 3: Tab 切换 (Params -> Headers -> Body -> Auth)")
    print("="*60)
    
    client = get_test_client(port)
    
    # 切换到 Headers Tab
    client.switch_request_tab("headers")
    time.sleep(0.5)
    
    # 切换到 Body Tab
    client.switch_request_tab("body")
    time.sleep(0.5)
    
    # 切换到 Auth Tab
    client.switch_request_tab("auth")
    time.sleep(0.5)
    
    # 切换回 Params Tab
    client.switch_request_tab("params")
    time.sleep(0.5)
    
    print("✅ Tab 切换测试通过")
    return True


def test_headers_count_badge(port=None):
    """测试 4: Headers 数量标记"""
    print("\n" + "="*60)
    print("🧪 测试 4: Headers 数量标记")
    print("="*60)
    
    client = get_test_client(port)
    
    # 先获取初始信息
    print("📋 添加 Headers 前的状态:")
    info = client.get_request_editor_info()
    initial_count = info.get('headers_count', 0)
    print(f"   初始 Headers 数量: {initial_count}")
    
    # 添加几个 headers
    print("\n📝 添加 Headers...")
    client.add_header_with_description("Content-Type", "application/json", "Request content type")
    client.add_header_with_description("Authorization", "Bearer token123", "Auth token")
    client.add_header_with_description("X-Custom-Header", "custom-value")
    
    time.sleep(0.5)
    
    # 验证 Headers 数量
    print("\n📋 添加 Headers 后的状态:")
    info = client.get_request_editor_info()
    new_count = info.get('headers_count', 0)
    print(f"   当前 Headers 数量: {new_count}")
    
    if new_count >= initial_count + 3:
        print("✅ Headers 数量标记测试通过")
        return True
    else:
        print(f"❌ Headers 数量不正确，期望 >= {initial_count + 3}，实际 {new_count}")
        return False


def test_body_dot_indicator(port=None):
    """测试 5: Body 圆点指示器"""
    print("\n" + "="*60)
    print("🧪 测试 5: Body 圆点指示器")
    print("="*60)
    
    client = get_test_client(port)
    
    # 先获取初始状态
    print("📋 设置 Body 前的状态:")
    info = client.get_request_editor_info()
    initial_has_body = info.get('has_body_content', False)
    print(f"   初始 Body 内容: {'有' if initial_has_body else '无'}")
    
    # 设置 Body
    print("\n📝 设置 Body...")
    client.set_body('{"message": "Hello, World!"}', "json")
    time.sleep(0.5)
    
    # 验证 Body 状态
    print("\n📋 设置 Body 后的状态:")
    info = client.get_request_editor_info()
    new_has_body = info.get('has_body_content', False)
    print(f"   当前 Body 内容: {'有' if new_has_body else '无'}")
    print(f"   Body 类型: {info.get('body_type')}")
    print(f"   Body 长度: {info.get('body_length')} 字符")
    
    # 切换到 Body Tab 以便截图
    client.switch_request_tab("body")
    time.sleep(0.5)
    
    if new_has_body:
        print("✅ Body 圆点指示器测试通过")
        return True
    else:
        print("❌ Body 内容未正确设置")
        return False


def test_params_count_badge(port=None):
    """测试 6: Params 数量标记"""
    print("\n" + "="*60)
    print("🧪 测试 6: Params 数量标记")
    print("="*60)
    
    client = get_test_client(port)
    
    # 切换到 Params Tab
    client.switch_request_tab("params")
    
    # 先获取初始信息
    print("📋 添加 Params 前的状态:")
    info = client.get_request_editor_info()
    initial_count = info.get('params_count', 0)
    print(f"   初始 Params 数量: {initial_count}")
    
    # 添加几个 params
    print("\n📝 添加 Params...")
    client.add_param("page", "1")
    client.add_param("limit", "10")
    client.add_param("search", "test")
    
    time.sleep(0.5)
    
    # 验证 Params 数量
    print("\n📋 添加 Params 后的状态:")
    info = client.get_request_editor_info()
    new_count = info.get('params_count', 0)
    print(f"   当前 Params 数量: {new_count}")
    
    if new_count >= initial_count + 3:
        print("✅ Params 数量标记测试通过")
        return True
    else:
        print(f"❌ Params 数量不正确，期望 >= {initial_count + 3}，实际 {new_count}")
        return False


def test_headers_with_info_icon(port=None):
    """测试 7: Headers Info Icon 显示"""
    print("\n" + "="*60)
    print("🧪 测试 7: Headers Info Icon 显示")
    print("="*60)
    
    client = get_test_client(port)
    
    # 切换到 Headers Tab
    client.switch_request_tab("headers")
    
    # 添加常见 headers（应该显示 info icon）
    print("📝 添加常见 Headers（应该显示 info icon）...")
    common_headers = [
        ("Accept", "application/json"),
        ("Content-Type", "application/json"),
        ("Authorization", "Bearer token"),
        ("User-Agent", "Hopp/1.0"),
    ]
    
    for key, value in common_headers:
        client.add_header_with_description(key, value)
    
    time.sleep(0.5)
    
    print("✅ Headers Info Icon 测试准备完成（请查看截图）")
    return True


def run_all_tests(args):
    """运行所有测试"""
    print("\n" + "="*60)
    print("🚀 Hopp Request Editor UI 自动化测试")
    print("="*60)
    
    results = []
    port = args.port
    
    try:
        # 测试 1: 基础连接
        results.append(("基础连接", test_basic_connection(port)))
        
        # 测试 2: 创建新请求
        results.append(("创建新请求", test_create_request(port)))
        
        # 测试 3: Tab 切换
        results.append(("Tab 切换", test_tab_switching(port)))
        
        # 截图 1: Tab 切换后的状态
        if args.screenshots:
            time.sleep(0.5)
            capture_screenshot("test_request_tabs.png")
        
        # 测试 4: Headers 数量标记
        results.append(("Headers 数量标记", test_headers_count_badge(port)))
        
        # 截图 2: Headers Tab
        if args.screenshots:
            client = get_test_client(port)
            client.switch_request_tab("headers")
            time.sleep(0.5)
            capture_screenshot("test_headers_tab.png")
        
        # 测试 5: Body 圆点指示器
        results.append(("Body 圆点指示器", test_body_dot_indicator(port)))
        
        # 截图 3: Body Tab
        if args.screenshots:
            time.sleep(0.5)
            capture_screenshot("test_body_tab.png")
        
        # 测试 6: Params 数量标记
        results.append(("Params 数量标记", test_params_count_badge(port)))
        
        # 截图 4: Params Tab
        if args.screenshots:
            client = get_test_client(port)
            client.switch_request_tab("params")
            time.sleep(0.5)
            capture_screenshot("test_params_tab.png")
        
        # 测试 7: Headers Info Icon
        results.append(("Headers Info Icon", test_headers_with_info_icon(port)))
        
        # 截图 5: Headers with Info Icon
        if args.screenshots:
            time.sleep(0.5)
            capture_screenshot("test_headers_info_icon.png")
        
    except Exception as e:
        print(f"\n❌ 测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()
    
    # 打印测试报告
    print("\n" + "="*60)
    print("📊 测试报告")
    print("="*60)
    
    passed = sum(1 for _, result in results if result)
    failed = sum(1 for _, result in results if not result)
    
    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"   {status}: {name}")
    
    print(f"\n总计: {len(results)} 个测试")
    print(f"通过: {passed} 个")
    print(f"失败: {failed} 个")
    
    if failed == 0:
        print("\n🎉 所有测试通过！")
    else:
        print(f"\n⚠️ {failed} 个测试失败")
    
    return failed == 0


def main():
    parser = argparse.ArgumentParser(
        description="Hopp Request Editor UI 测试脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 运行所有测试
  %(prog)s --screenshots      # 运行测试并截图
        """
    )
    
    parser.add_argument(
        "--screenshots",
        action="store_true",
        help="启用截图功能"
    )
    
    parser.add_argument(
        "--port",
        type=int,
        help="测试服务器端口（可选，默认从文件读取）"
    )
    
    args = parser.parse_args()
    
    # 如果指定了端口，设置环境变量供 HoppTestClient 使用
    if args.port:
        import os
        os.environ['HOPP_TEST_PORT'] = str(args.port)
    
    success = run_all_tests(args)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
