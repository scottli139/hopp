#!/usr/bin/env python3
"""
Response Body 区域对比测试
用于截取 hopp 的 response body 截图，与 Postman 对比
"""

import argparse
import json
import subprocess
import sys
import time
from test_client import HoppTestClient


def run_test(port: int = 8080):
    """运行 response body 对比测试"""
    client = HoppTestClient(port=port)

    # 测试 1: 基础连接
    print("=" * 60)
    print("测试 1: 基础连接")
    print("=" * 60)
    result = client.send_command("ping")
    if result.get("status") != "ok":
        print("❌ 连接失败")
        return False
    print("✅ 连接成功")
    time.sleep(0.5)

    # 测试 2: 创建请求并模拟响应
    print("\n" + "=" * 60)
    print("测试 2: 创建请求并模拟 JSON 响应")
    print("=" * 60)
    
    # 创建新请求
    result = client.send_command("create_request")
    if result.get("status") != "ok":
        print("❌ 创建请求失败")
        return False
    print("✅ 创建新请求")
    time.sleep(0.5)

    # 设置 URL
    result = client.send_command("set_url", {"url": "https://httpbin.org/json"})
    if result.get("status") != "ok":
        print("❌ 设置 URL 失败")
        return False
    print("✅ 设置 URL")
    time.sleep(0.5)

    # 模拟带有完整 JSON 数据的响应
    mock_response = {
        "slideshow": {
            "author": "Yours Truly",
            "date": "date of publication",
            "slides": [
                {
                    "type": "all",
                    "title": "Wake up to WonderWidgets!"
                },
                {
                    "type": "all",
                    "title": "Overview",
                    "items": [
                        "Why <em>WonderWidgets</em> are great",
                        "Who <em>buys</em> WonderWidgets"
                    ]
                }
            ],
            "title": "Sample Slide Show"
        }
    }
    
    # 使用 simulate_response_with_timing 模拟响应
    result = client.send_command("simulate_response_with_timing", {
        "body": json.dumps(mock_response, indent=2),
        "statusCode": 200,
        "contentType": "application/json",
        "sizeBytes": 512,
        "durationMs": 150,
        "timing": {
            "dnsMs": 25,
            "tcpMs": 30,
            "tlsMs": 40,
            "ttfbMs": 45,
            "downloadMs": 10,
            "totalMs": 150
        }
    })
    if result.get("status") != "ok":
        print("❌ 模拟响应失败")
        return False
    print("✅ 模拟 JSON 响应")
    time.sleep(1.0)

    # 测试 3: 切换到 Body Tab 并截图
    print("\n" + "=" * 60)
    print("测试 3: Response Body Tab 截图")
    print("=" * 60)
    
    result = client.send_command("switch_response_tab", {"tab": "body"})
    if result.get("status") != "ok":
        print("❌ 切换 Tab 失败")
        return False
    print("✅ 切换到 Body Tab")
    time.sleep(1.0)

    # 设置窗口大小以便更好展示
    result = client.send_command("set_window_size", {
        "width": 1400,
        "height": 900
    })
    time.sleep(0.5)

    # 触发截图 - Response Body 区域
    result = client.send_command("capture_screenshot", {
        "name": "response_body_json"
    })
    if result.get("status") != "ok":
        print("❌ 截图失败")
        return False
    print("✅ Response Body JSON 截图已保存")
    time.sleep(1.0)

    # 测试 4: 切换到 Full 模式再截图对比
    print("\n" + "=" * 60)
    print("测试 4: Full 模式 Response Body 截图")
    print("=" * 60)
    
    result = client.send_command("set_response_display_mode", {"mode": "full"})
    if result.get("status") != "ok":
        print("❌ 切换显示模式失败")
        return False
    print("✅ 切换到 Full 模式")
    time.sleep(1.0)

    result = client.send_command("capture_screenshot", {
        "name": "response_body_full"
    })
    if result.get("status") != "ok":
        print("❌ 截图失败")
        return False
    print("✅ Full 模式 Response Body 截图已保存")
    time.sleep(1.0)

    # 测试 5: 模拟更大的响应体（测试行号显示）
    print("\n" + "=" * 60)
    print("测试 5: 较大响应体（测试行号）")
    print("=" * 60)
    
    # 生成一个更大的 JSON
    large_data = {
        "users": [],
        "total": 100,
        "page": 1,
        "per_page": 20
    }
    for i in range(20):
        large_data["users"].append({
            "id": i + 1,
            "name": f"User {i + 1}",
            "email": f"user{i + 1}@example.com",
            "role": "admin" if i < 5 else "user",
            "active": i % 2 == 0,
            "created_at": "2024-01-15T08:30:00Z",
            "profile": {
                "avatar": f"https://example.com/avatar{i + 1}.png",
                "bio": f"This is the bio for user {i + 1}",
                "location": "Beijing, China"
            }
        })
    
    result = client.send_command("simulate_response_with_timing", {
        "body": json.dumps(large_data, indent=2),
        "statusCode": 200,
        "contentType": "application/json",
        "sizeBytes": 2048,
        "durationMs": 200,
        "timing": {
            "dnsMs": 20,
            "tcpMs": 25,
            "tlsMs": 35,
            "ttfbMs": 100,
            "downloadMs": 20,
            "totalMs": 200
        }
    })
    time.sleep(1.0)
    
    result = client.send_command("capture_screenshot", {
        "name": "response_body_large"
    })
    print("✅ 较大响应体截图已保存")
    time.sleep(1.0)

    print("\n" + "=" * 60)
    print("所有测试完成！")
    print("=" * 60)
    print("\n截图文件位置: ~/Downloads/hopp_screenshot_*.png")
    print("\n与 Postman 对比要点:")
    print("1. 行号区域宽度")
    print("2. 编辑器边框样式")
    print("3. JSON 语法高亮效果")
    print("4. 工具栏布局")
    print("5. 整体视觉精致度")
    
    return True


def main():
    parser = argparse.ArgumentParser(description="Response Body 对比测试")
    parser.add_argument("--port", type=int, default=8080, help="测试服务器端口")
    args = parser.parse_args()

    try:
        success = run_test(port=args.port)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
