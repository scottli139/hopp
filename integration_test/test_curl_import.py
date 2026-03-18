#!/usr/bin/env python3
"""
cURL 导入功能 UI 测试脚本

测试 cURL 命令解析和导入功能。

使用方法:
    python test_curl_import.py
"""

import argparse
import sys
import time
from pathlib import Path

try:
    from test_client import HoppTestClient
except ImportError:
    print("Error: test_client.py not found in the same directory")
    sys.exit(1)


def test_simple_get():
    """测试简单 GET 请求解析"""
    print("\n============================================================")
    print("Test 1: Simple GET request")
    print("============================================================")
    
    client = HoppTestClient()
    
    # 测试解析
    result = client.send_command("parse_curl", {
        "command": "curl https://httpbin.org/get"
    })
    
    assert result.get("success") is True, f"Parse failed: {result.get('error')}"
    assert result["request"]["method"] == "GET", f"Expected GET, got {result['request']['method']}"
    assert "httpbin.org" in result["request"]["url"], f"Unexpected URL: {result['request']['url']}"
    
    print("✅ Simple GET request parsed successfully")
    return True


def test_post_with_json():
    """测试 POST 带 JSON body"""
    print("\n============================================================")
    print("Test 2: POST with JSON body")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": 'curl -X POST -H "Content-Type: application/json" -d \'{"name":"test","value":123}\' https://httpbin.org/post'
    })
    
    assert result.get("success") is True, f"Parse failed: {result.get('error')}"
    assert result["request"]["method"] == "POST"
    assert result["request"]["body_type"] == "raw"
    assert result["request"]["headers_count"] >= 1
    
    print("✅ POST with JSON body parsed successfully")
    return True


def test_with_headers():
    """测试带 Headers 的请求"""
    print("\n============================================================")
    print("Test 3: Request with headers")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": 'curl -H "Authorization: Bearer token123" -H "X-Custom-Header: value" https://api.example.com/data'
    })
    
    assert result.get("success") is True
    assert result["request"]["headers_count"] == 2, f"Expected 2 headers, got {result['request']['headers_count']}"
    
    print("✅ Request with headers parsed successfully")
    return True


def test_basic_auth():
    """测试基础认证"""
    print("\n============================================================")
    print("Test 4: Basic authentication")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": "curl -u admin:secret123 https://api.example.com/admin"
    })
    
    assert result.get("success") is True
    # 认证信息应该被转换为 Authorization header
    assert result["request"]["headers_count"] >= 1
    
    print("✅ Basic authentication parsed successfully")
    return True


def test_form_data():
    """测试 Form Data"""
    print("\n============================================================")
    print("Test 5: Form data")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": 'curl -X POST -F "name=John" -F "email=john@example.com" -F "file=@/path/to/file.pdf" https://api.example.com/upload'
    })
    
    assert result.get("success") is True
    assert result["request"]["body_type"] == "formData"
    
    print("✅ Form data parsed successfully")
    return True


def test_ssl_options():
    """测试 SSL 相关选项"""
    print("\n============================================================")
    print("Test 6: SSL options")
    print("============================================================")
    
    client = HoppTestClient()
    
    # 测试 -k (insecure)
    result = client.send_command("parse_curl", {
        "command": "curl -k https://self-signed.example.com"
    })
    
    assert result.get("success") is True
    assert result["request"]["validate_certificates"] is False
    
    print("✅ SSL options parsed successfully")
    return True


def test_follow_redirects():
    """测试跟随重定向"""
    print("\n============================================================")
    print("Test 7: Follow redirects")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": "curl -L https://api.example.com/redirect"
    })
    
    assert result.get("success") is True
    assert result["request"]["follow_redirects"] is True
    
    print("✅ Follow redirects parsed successfully")
    return True


def test_multiline_command():
    """测试多行命令"""
    print("\n============================================================")
    print("Test 8: Multiline command")
    print("============================================================")
    
    client = HoppTestClient()
    
    multiline_cmd = """curl -X POST \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer token" \\
  -d '{"data":"test"}' \\
  https://api.example.com/data"""
    
    result = client.send_command("parse_curl", {
        "command": multiline_cmd
    })
    
    assert result.get("success") is True
    assert result["request"]["method"] == "POST"
    assert result["request"]["headers_count"] == 2
    
    print("✅ Multiline command parsed successfully")
    return True


def test_import_and_open():
    """测试导入并打开请求"""
    print("\n============================================================")
    print("Test 9: Import and open request")
    print("============================================================")
    
    client = HoppTestClient()
    
    # 首先创建一个新请求 Tab 来确保有一个活动的 Tab
    client.create_request()
    time.sleep(0.5)
    
    # 导入 cURL 命令
    result = client.send_command("import_curl", {
        "command": "curl -X PUT -H 'Content-Type: application/json' -d '{\"status\":\"active\"}' https://api.example.com/users/123",
        "open_tab": True
    })
    
    assert result.get("success") is True
    assert "request_id" in result
    assert result["method"] == "PUT"
    
    print(f"✅ Request imported successfully: {result['name']}")
    return True


def test_invalid_command():
    """测试无效命令处理"""
    print("\n============================================================")
    print("Test 10: Invalid command handling")
    print("============================================================")
    
    client = HoppTestClient()
    
    result = client.send_command("parse_curl", {
        "command": "invalid command"
    })
    
    assert result.get("success") is False, "Should fail for invalid command"
    assert "error" in result
    
    print(f"✅ Invalid command handled correctly: {result.get('error')}")
    return True


def test_browser_curl():
    """测试浏览器导出的 cURL 命令"""
    print("\n============================================================")
    print("Test 11: Browser exported cURL")
    print("============================================================")
    
    client = HoppTestClient()
    
    # 模拟浏览器开发者工具导出的 cURL
    browser_curl = """curl 'https://api.github.com/user/repos' \\
  -H 'authority: api.github.com' \\
  -H 'accept: application/vnd.github.v3+json' \\
  -H 'authorization: token ghp_xxxxxxxxxxxx' \\
  -H 'user-agent: Mozilla/5.0' \\
  --compressed"""
    
    result = client.send_command("parse_curl", {
        "command": browser_curl
    })
    
    assert result.get("success") is True
    assert "github.com" in result["request"]["url"]
    assert result["request"]["headers_count"] >= 3
    
    print("✅ Browser cURL parsed successfully")
    return True


def run_all_tests():
    """运行所有测试"""
    print("=" * 60)
    print("cURL Import Feature Test Suite")
    print("=" * 60)
    
    tests = [
        test_simple_get,
        test_post_with_json,
        test_with_headers,
        test_basic_auth,
        test_form_data,
        test_ssl_options,
        test_follow_redirects,
        test_multiline_command,
        test_import_and_open,
        test_invalid_command,
        test_browser_curl,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            failed += 1
            print(f"❌ Test failed: {e}")
    
    print("\n" + "=" * 60)
    print(f"Test Results: {passed} passed, {failed} failed")
    print("=" * 60)
    
    return failed == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="cURL Import Feature Test")
    parser.add_argument("--port", type=int, help="Test server port")
    args = parser.parse_args()
    
    if args.port:
        import test_client
        test_client.DEFAULT_PORT = args.port
    
    success = run_all_tests()
    sys.exit(0 if success else 1)
