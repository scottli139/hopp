#!/usr/bin/env python3
"""
请求详情展示功能 UI 测试

测试内容：
1. 创建带参数、Headers、Body 的请求
2. 发送请求
3. 切换到 Request Tab
4. 验证请求详情展示正确
5. 切换回 Body Tab 对比

使用方法：
    python test_request_details.py --port <PORT>
    或
    python test_request_details.py（自动从日志读取端口）
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path

from test_client import HoppTestClient


def test_request_details(port=None):
    """测试请求详情展示功能"""
    client = HoppTestClient(port=port)

    print("\n" + "=" * 60)
    print("🧪 请求详情展示功能 UI 测试")
    print("=" * 60 + "\n")

    # 1. 测试连接
    print("1️⃣ 测试连接...")
    client.ping()
    time.sleep(0.5)

    # 2. 创建新请求
    print("\n2️⃣ 创建新请求...")
    client.create_request()
    time.sleep(0.5)

    # 3. 设置 URL 和添加参数
    print("\n3️⃣ 设置 URL 和参数...")
    client.set_url("https://httpbin.org/get")
    client.add_param("page", "1")
    client.add_param("limit", "10")
    time.sleep(0.5)

    # 4. 添加 Headers
    print("\n4️⃣ 添加 Headers...")
    client.add_header("Accept", "application/json")
    client.add_header("X-Custom-Header", "test-value")
    time.sleep(0.5)

    # 5. 设置 Body
    print("\n5️⃣ 设置 Body...")
    client.set_body('{"name": "test", "value": 123}', "json")
    time.sleep(0.5)

    # 6. 发送请求
    print("\n6️⃣ 发送请求...")
    client.send_request()
    time.sleep(3)

    # 7. 切换到 Request Tab
    print("\n7️⃣ 切换到 Request Tab...")
    client.switch_response_tab("request")
    time.sleep(1)

    # 8. 获取请求详情
    print("\n8️⃣ 验证请求详情...")
    details = client.get_request_details()

    # 验证结果
    assert details.get('method') == 'GET', f"方法不匹配: {details.get('method')}"
    assert 'httpbin.org/get' in details.get('url', ''), f"URL 不匹配: {details.get('url')}"
    assert 'page=1' in details.get('full_url', ''), f"完整 URL 不包含参数: {details.get('full_url')}"
    assert 'limit=10' in details.get('full_url', ''), f"完整 URL 不包含参数: {details.get('full_url')}"
    assert details.get('headers_count') >= 2, f"Headers 数量不足: {details.get('headers_count')}"
    assert details.get('has_body') == True, f"应该有 Body"

    print("\n✅ 请求详情验证通过！")

    # 9. 切换回 Body Tab 对比
    print("\n9️⃣ 切换回 Body Tab...")
    client.switch_response_tab("body")
    time.sleep(1)

    # 10. 再切换回 Request Tab
    print("\n🔟 再次切换到 Request Tab...")
    client.switch_response_tab("request")
    time.sleep(1)

    print("\n" + "=" * 60)
    print("✅ 所有测试通过！")
    print("=" * 60 + "\n")

    return True


def test_request_details_empty(port=None):
    """测试空请求详情"""
    client = HoppTestClient(port=port)

    print("\n" + "=" * 60)
    print("🧪 空请求详情测试")
    print("=" * 60 + "\n")

    # 创建简单 GET 请求
    client.create_request()
    client.set_url("https://httpbin.org/get")
    client.send_request()
    time.sleep(3)

    # 切换到 Request Tab
    client.switch_response_tab("request")
    time.sleep(1)

    # 获取详情
    details = client.get_request_details()

    # 验证
    assert details.get('method') == 'GET', f"方法不匹配: {details.get('method')}"
    assert details.get('headers_count') >= 0, f"Headers 数量不应为负: {details.get('headers_count')}"
    assert details.get('has_body') == False, f"不应该有 Body"

    print("\n✅ 空请求测试通过！")
    return True


def test_post_request_details(port=None):
    """测试 POST 请求详情"""
    client = HoppTestClient(port=port)

    print("\n" + "=" * 60)
    print("🧪 POST 请求详情测试")
    print("=" * 60 + "\n")

    # 创建 POST 请求
    client.create_request()
    client.set_url("https://httpbin.org/post")
    client.set_method("POST")
    client.add_header("Content-Type", "application/json")
    client.set_body('{"key": "value", "number": 42}', "json")
    time.sleep(0.5)

    client.send_request()
    time.sleep(3)

    # 切换到 Request Tab
    client.switch_response_tab("request")
    time.sleep(1)

    # 获取详情
    details = client.get_request_details()

    # 验证
    assert details.get('method') == 'POST', f"方法不匹配: {details.get('method')}"
    assert 'httpbin.org/post' in details.get('url', ''), f"URL 不匹配: {details.get('url')}"
    assert details.get('has_body') == True, f"POST 请求应该有 Body"
    assert 'application/json' in str(details.get('headers', [])), f"应该有 Content-Type header"

    print("\n✅ POST 请求测试通过！")
    return True


def main():
    parser = argparse.ArgumentParser(description="请求详情展示功能 UI 测试")
    parser.add_argument("--port", type=int, help="测试服务器端口")

    args = parser.parse_args()

    try:
        # 运行测试
        test_request_details(port=args.port)
        test_request_details_empty(port=args.port)
        test_post_request_details(port=args.port)

        print("\n🎉 所有测试通过！请求详情展示功能正常工作。")
        sys.exit(0)

    except AssertionError as e:
        print(f"\n❌ 断言失败: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
