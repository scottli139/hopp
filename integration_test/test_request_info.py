#!/usr/bin/env python3
"""
Hopp Request Tab 完整请求信息测试脚本

测试 Response 区域 Request Tab 展示的完整请求信息，包括：
- HTTP 方法
- 完整 URL（包含查询参数）
- Scheme/Host/Path/Port 分解
- Headers（用户添加 + 自动添加）
- Body 内容

使用方法:
    python test_request_info.py

前置条件:
    Hopp 应用以 --test-mode 启动
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path

# 导入 test_client 中的 HoppTestClient
from test_client import HoppTestClient


def run_screenshot(filename):
    """执行截图"""
    try:
        screenshot_path = Path.home() / f"Desktop/{filename}"
        subprocess.run(
            ["screencapture", "-x", str(screenshot_path)],
            check=True,
            capture_output=True,
        )
        print(f"📸 截图已保存: {screenshot_path}")
        return True
    except Exception as e:
        print(f"⚠️ 截图失败: {e}")
        return False


def test_request_info_basic(client=None):
    """测试基本请求信息展示"""
    print("\n" + "="*60)
    print("🧪 测试 1: 基本请求信息展示")
    print("="*60)
    
    if client is None:
        client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/get")
    
    # 3. 添加查询参数
    client.add_param("foo", "bar")
    client.add_param("page", "1")
    
    # 4. 添加 Headers
    client.add_header("Accept", "application/json")
    client.add_header("X-Custom-Header", "test-value")
    
    # 5. 模拟响应（带 requestInfo）
    client.simulate_response_with_timing()
    
    # 6. 切换到 Request Tab
    client.switch_response_tab("request")
    
    # 7. 等待渲染
    time.sleep(2)
    
    # 8. 获取请求详情
    result = client.get_request_details()
    
    # 9. 验证结果
    assert result.get('has_request_info'), "应该有 requestInfo"
    assert result.get('method') == 'GET', f"方法应该是 GET，实际是 {result.get('method')}"
    assert 'httpbin.org' in result.get('full_url', ''), "URL 应该包含 httpbin.org"
    
    # 验证 URL 分解
    assert result.get('scheme') == 'https', f"Scheme 应该是 https"
    assert result.get('host') == 'httpbin.org', f"Host 应该是 httpbin.org"
    
    # 验证 Headers
    headers_count = result.get('headers_count', 0)
    assert headers_count >= 2, f"Headers 数量应该 >= 2，实际是 {headers_count}"
    
    # 验证自定义 headers 存在
    headers = result.get('headers', [])
    header_keys = [h.get('key', '').lower() for h in headers]
    assert 'accept' in header_keys, "应该有 Accept header"
    assert 'x-custom-header' in header_keys, "应该有 X-Custom-Header"
    
    # 10. 截图验证
    run_screenshot("test_request_info_basic.png")
    
    print("\n✅ 测试 1 通过: 基本请求信息展示正确")
    return True


def test_request_info_post_with_body(client=None):
    """测试 POST 请求带 Body 的信息展示"""
    print("\n" + "="*60)
    print("🧪 测试 2: POST 请求带 Body")
    print("="*60)
    
    if client is None:
        client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    
    # 2. 设置方法和 URL
    client.set_method("POST")
    client.set_url("https://httpbin.org/post")
    
    # 3. 设置 Body
    body_content = '{"name": "John", "email": "john@example.com"}'
    client.set_body(body_content, "json")
    
    # 4. 添加 Content-Type header
    client.add_header("Content-Type", "application/json")
    
    # 5. 模拟响应
    client.simulate_response_with_timing()
    
    # 6. 切换到 Request Tab
    client.switch_response_tab("request")
    
    # 7. 等待渲染
    time.sleep(2)
    
    # 8. 获取请求详情
    result = client.get_request_details()
    
    # 9. 验证结果
    assert result.get('method') == 'POST', f"方法应该是 POST"
    assert result.get('has_body'), "应该有 Body"
    assert result.get('body_type') == 'json', f"Body 类型应该是 json"
    
    # 验证 Content-Type
    assert result.get('content_type') == 'application/json', "Content-Type 应该是 application/json"
    
    # 10. 截图验证
    run_screenshot("test_request_info_post.png")
    
    print("\n✅ 测试 2 通过: POST 请求带 Body 展示正确")
    return True


def test_request_info_headers_categorization(client=None):
    """测试 Headers 分类展示（用户添加 vs 自动添加）"""
    print("\n" + "="*60)
    print("🧪 测试 3: Headers 分类展示")
    print("="*60)
    
    if client is None:
        client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/headers")
    
    # 3. 只添加一个自定义 header
    client.add_header("X-Test-Header", "test-value")
    
    # 4. 模拟响应（会包含自动添加的 headers）
    client.simulate_response_with_timing()
    
    # 5. 切换到 Request Tab
    client.switch_response_tab("request")
    
    # 6. 等待渲染
    time.sleep(2)
    
    # 7. 获取请求详情
    result = client.get_request_details()
    
    # 8. 验证 Headers 分类
    headers = result.get('headers', [])
    
    # 应该有用户添加的 header
    custom_headers = [h for h in headers if h.get('key', '').lower() == 'x-test-header']
    assert len(custom_headers) > 0, "应该有 X-Test-Header"
    
    # 应该有自动添加的 headers (User-Agent)
    auto_headers = [h for h in headers if h.get('key', '').lower() == 'user-agent']
    assert len(auto_headers) > 0, "应该有自动添加的 User-Agent"
    
    # 9. 截图验证
    run_screenshot("test_request_info_headers.png")
    
    print("\n✅ 测试 3 通过: Headers 分类展示正确")
    return True


def test_request_info_empty(client=None):
    """测试空请求状态"""
    print("\n" + "="*60)
    print("🧪 测试 4: 空请求状态")
    print("="*60)
    
    if client is None:
        client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    
    # 2. 不发送请求，直接获取请求详情
    result = client.get_request_details()
    
    # 3. 验证没有 requestInfo（因为还没发送请求）
    # 但应该返回基本的请求信息
    assert 'method' in result, "应该有 method 字段"
    assert 'url' in result, "应该有 url 字段"
    
    print("\n✅ 测试 4 通过: 空请求状态处理正确")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Hopp Request Tab 完整请求信息测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
测试流程:
  1. 基本请求信息展示
  2. POST 请求带 Body
  3. Headers 分类展示
  4. 空请求状态

示例:
  python test_request_info.py
  python test_request_info.py --port 8080
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口（可选）")
    
    args = parser.parse_args()
    
    print("\n" + "="*60)
    print("🚀 Hopp Request Tab 完整请求信息测试")
    print("="*60)
    
    # 创建客户端
    client = HoppTestClient(port=args.port)
    
    # 测试连接
    try:
        client.ping()
    except Exception as e:
        print(f"\n❌ 无法连接到 Hopp 测试服务器: {e}")
        print("请确保应用以 --test-mode 启动")
        sys.exit(1)
    
    # 运行所有测试
    tests = [
        test_request_info_basic,
        test_request_info_post_with_body,
        test_request_info_headers_categorization,
        test_request_info_empty,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test(client):
                passed += 1
        except Exception as e:
            failed += 1
            print(f"\n❌ 测试失败: {e}")
            import traceback
            traceback.print_exc()
    
    # 输出总结
    print("\n" + "="*60)
    print("📊 测试总结")
    print("="*60)
    print(f"通过: {passed}")
    print(f"失败: {failed}")
    print(f"总计: {passed + failed}")
    
    if failed == 0:
        print("\n✅ 所有测试通过！")
        return 0
    else:
        print(f"\n❌ 有 {failed} 个测试失败")
        return 1


if __name__ == "__main__":
    sys.exit(main())
