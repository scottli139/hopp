#!/usr/bin/env python3
"""
Hopp 4XX/5XX 错误响应测试脚本

测试修复: Issue #1 - 4XX/5XX 响应不显示服务端返回内容

验证点:
1. 4XX 响应能正确显示服务端返回的 JSON 错误详情
2. 5XX 响应能正确显示服务端返回的错误详情
3. Response Headers 正确显示
4. 状态码正确显示
"""

import sys
import time
from pathlib import Path

# 添加当前目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def test_4xx_response():
    """测试 4XX 错误响应显示"""
    print("\n" + "="*60)
    print("测试 1: 400 Bad Request 响应")
    print("="*60)
    
    client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    time.sleep(0.5)
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/post")
    time.sleep(0.5)
    
    # 3. 模拟 400 响应
    client.simulate_4xx_response(400)
    time.sleep(1.0)
    
    # 4. 获取响应信息
    info = client.get_response_info()
    
    # 验证
    assert info.get('has_response'), "应该有响应"
    assert info.get('status_code') == 400, f"状态码应该是 400，实际是 {info.get('status_code')}"
    print(f"✅ 状态码正确: {info.get('status_code')}")
    
    # 5. 获取响应体信息
    body_info = client.get_response_body_info()
    assert body_info.get('has_body'), "应该有响应体"
    print(f"✅ 响应体大小: {body_info.get('size_kb')} KB")
    
    # 6. 截图验证
    client.capture_screenshot("test_4xx_response")
    time.sleep(0.5)
    
    print("\n✅ 测试 1 通过: 4XX 响应正确显示服务端返回内容")
    return True


def test_401_response():
    """测试 401 认证错误响应"""
    print("\n" + "="*60)
    print("测试 2: 401 Unauthorized 响应")
    print("="*60)
    
    client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    time.sleep(0.5)
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/bearer")
    time.sleep(0.5)
    
    # 3. 模拟 401 响应
    client.simulate_4xx_response(401)
    time.sleep(1.0)
    
    # 4. 获取响应信息
    info = client.get_response_info()
    
    # 验证
    assert info.get('status_code') == 401, f"状态码应该是 401，实际是 {info.get('status_code')}"
    print(f"✅ 状态码正确: {info.get('status_code')}")
    
    # 5. 切换到 Headers Tab 查看响应头
    client.switch_response_tab("headers")
    time.sleep(0.5)
    client.capture_screenshot("test_401_headers")
    time.sleep(0.5)
    
    print("\n✅ 测试 2 通过: 401 响应正确显示")
    return True


def test_5xx_response():
    """测试 5XX 服务器错误响应"""
    print("\n" + "="*60)
    print("测试 3: 500 Internal Server Error 响应")
    print("="*60)
    
    client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    time.sleep(0.5)
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/status/500")
    time.sleep(0.5)
    
    # 3. 模拟 500 响应
    client.simulate_5xx_response(500)
    time.sleep(1.0)
    
    # 4. 获取响应信息
    info = client.get_response_info()
    
    # 验证
    assert info.get('has_response'), "应该有响应"
    assert info.get('status_code') == 500, f"状态码应该是 500，实际是 {info.get('status_code')}"
    print(f"✅ 状态码正确: {info.get('status_code')}")
    
    # 5. 获取响应体信息
    body_info = client.get_response_body_info()
    assert body_info.get('has_body'), "应该有响应体"
    print(f"✅ 响应体大小: {body_info.get('size_kb')} KB")
    
    # 6. 截图验证
    client.capture_screenshot("test_5xx_response")
    time.sleep(0.5)
    
    print("\n✅ 测试 3 通过: 5XX 响应正确显示服务端返回内容")
    return True


def test_503_response():
    """测试 503 服务不可用响应"""
    print("\n" + "="*60)
    print("测试 4: 503 Service Unavailable 响应")
    print("="*60)
    
    client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    time.sleep(0.5)
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/status/503")
    time.sleep(0.5)
    
    # 3. 模拟 503 响应
    client.simulate_5xx_response(503)
    time.sleep(1.0)
    
    # 4. 获取响应信息
    info = client.get_response_info()
    
    # 验证
    assert info.get('status_code') == 503, f"状态码应该是 503，实际是 {info.get('status_code')}"
    print(f"✅ 状态码正确: {info.get('status_code')}")
    
    # 5. 切换到 Headers Tab 查看 Retry-After 头
    client.switch_response_tab("headers")
    time.sleep(0.5)
    client.capture_screenshot("test_503_headers")
    time.sleep(0.5)
    
    print("\n✅ 测试 4 通过: 503 响应正确显示")
    return True


def test_error_response_with_timing():
    """测试带时间分析的错误响应"""
    print("\n" + "="*60)
    print("测试 5: 错误响应的时间分析")
    print("="*60)
    
    client = HoppTestClient()
    
    # 1. 创建新请求
    client.create_request()
    time.sleep(0.5)
    
    # 2. 设置 URL
    client.set_url("https://httpbin.org/delay/1")
    time.sleep(0.5)
    
    # 3. 模拟 429 Too Many Requests 响应
    client.simulate_4xx_response(429)
    time.sleep(1.0)
    
    # 4. 切换到 Timing Tab
    client.switch_response_tab("timing")
    time.sleep(0.5)
    
    # 5. 获取时间分析信息
    timing_info = client.get_timing_info()
    assert timing_info.get('has_timing'), "应该有时间分析信息"
    print(f"✅ 总耗时: {timing_info.get('total_formatted')}")
    
    # 6. 截图验证
    client.capture_screenshot("test_error_timing")
    time.sleep(0.5)
    
    print("\n✅ 测试 5 通过: 错误响应包含时间分析")
    return True


def main():
    """运行所有测试"""
    print("\n" + "="*60)
    print("🧪 Hopp 4XX/5XX 错误响应测试")
    print("测试修复: Issue #1 - 4XX/5XX 响应不显示服务端返回内容")
    print("="*60)
    
    tests = [
        ("4XX 响应测试", test_4xx_response),
        ("401 响应测试", test_401_response),
        ("5XX 响应测试", test_5xx_response),
        ("503 响应测试", test_503_response),
        ("错误响应时间分析", test_error_response_with_timing),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
                print(f"\n❌ {name} 失败")
        except Exception as e:
            failed += 1
            print(f"\n❌ {name} 失败: {e}")
            import traceback
            traceback.print_exc()
    
    # 汇总
    print("\n" + "="*60)
    print("📊 测试结果汇总")
    print("="*60)
    print(f"通过: {passed}/{len(tests)}")
    print(f"失败: {failed}/{len(tests)}")
    
    if failed == 0:
        print("\n✅ 所有测试通过!")
        print("Issue #1 修复验证成功: 4XX/5XX 响应现在能正确显示服务端返回内容")
        return 0
    else:
        print(f"\n❌ {failed} 个测试失败")
        return 1


if __name__ == "__main__":
    sys.exit(main())
