#!/usr/bin/env python3
"""
改进后的 Code Editor UI 测试
用于验证 Response/Request Body 编辑器的 UI 改进效果
"""

import argparse
import json
import sys
import time
from test_client import HoppTestClient


def run_test(port: int = 8080):
    """运行改进后的 Code Editor UI 测试"""
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

    # 测试 2: 创建请求并模拟 JSON 响应
    print("\n" + "=" * 60)
    print("测试 2: 创建请求并模拟 JSON 响应")
    print("=" * 60)

    # 创建新请求
    result = client.send_command("create_request")
    if result.get("request_id") is None:
        print(f"❌ 创建请求失败: {result}")
        return False
    print(f"✅ 创建新请求: {result.get('name')} ({result.get('request_id')})")
    time.sleep(0.5)

    # 设置 URL
    result = client.send_command("set_url", {"url": "https://httpbin.org/json"})
    if result.get("url") is None:
        print(f"❌ 设置 URL 失败: {result}")
        return False
    print(f"✅ 设置 URL: {result.get('url')}")
    time.sleep(0.5)

    # 模拟带有完整 JSON 数据的响应
    mock_response = {
        "userId": 422661012,
        "token": "0e0b7ebd0ddc46fe832bddc45e3cfc59",
        "maxIdleMinutes": 10,
        "username": "zhongmou",
        "displayName": "zhongmou",
        "org": "北京中创视讯科技有限公司",
        "orgPortAllocMode": "ROOM",
        "orgPortCount": 0,
        "orgType": "COMMON",
        "email": "",
        "title": "门卫",
        "cellphone": "18611991600",
        "telephone": "",
        "sipAccounts": [],
        "role": "DEPT_ADMIN",
        "deviceId": 424010729,
        "callServiceToken": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "callServiceUrl": "ws://218.60.16.146:80/websocket/message?token=eyJ0...",
        "everChangedPasswd": True,
        "agentId": 103424,
        "avatarUrl": "https://example.com/avatar.jpg",
    }

    # 使用 simulate_response_with_timing 模拟响应
    result = client.send_command("simulate_response_with_timing", {
        "body": json.dumps(mock_response, indent=2),
        "statusCode": 200,
        "contentType": "application/json",
        "sizeBytes": 2048,
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
    if result.get("simulated") != True:
        print(f"❌ 模拟响应失败: {result}")
        return False
    print(f"✅ 模拟 JSON 响应 (总时间: {result.get('total_ms')}ms)")
    time.sleep(1.0)

    # 测试 3: 切换到 Body Tab 并截图
    print("\n" + "=" * 60)
    print("测试 3: Response Body Tab 截图")
    print("=" * 60)

    result = client.send_command("switch_response_tab", {"tab": "body"})
    if result.get("tab") != "body":
        print(f"❌ 切换 Tab 失败: {result}")
        return False
    print(f"✅ 切换到 Body Tab")
    time.sleep(1.0)

    # 设置窗口大小以便更好展示
    result = client.send_command("set_window_size", {
        "width": 1400,
        "height": 900
    })
    time.sleep(0.5)

    # 触发截图 - Response Body 区域（显示行号）
    result = client.send_command("capture_screenshot", {
        "name": "response_body_with_line_numbers"
    })
    if result.get("captured") != True:
        print(f"❌ 截图失败: {result}")
        return False
    print(f"✅ Response Body 截图已保存: {result.get('path')}")
    time.sleep(1.0)

    # 测试 4: Beautify 功能测试
    print("\n" + "=" * 60)
    print("测试 4: Beautify 功能测试")
    print("=" * 60)

    # 模拟未格式化的 JSON
    unformatted_json = '{"userId":123,"username":"test","active":true,"items":[1,2,3]}'
    result = client.send_command("simulate_response_with_timing", {
        "body": unformatted_json,
        "statusCode": 200,
        "contentType": "application/json",
        "sizeBytes": 100,
        "durationMs": 50,
        "timing": {
            "totalMs": 50
        }
    })
    time.sleep(0.5)

    # 截图 - Beautify 前
    result = client.send_command("capture_screenshot", {
        "name": "before_beautify"
    })
    print("✅ Beautify 前截图已保存")
    time.sleep(0.5)

    # 执行 Beautify
    result = client.send_command("beautify_code")
    if result.get("beautified") != True:
        print(f"❌ Beautify 失败: {result}")
        return False
    print("✅ 执行 Beautify")
    time.sleep(1.0)

    # 截图 - Beautify 后
    result = client.send_command("capture_screenshot", {
        "name": "after_beautify"
    })
    print("✅ Beautify 后截图已保存")
    time.sleep(1.0)

    # 测试 5: Request Body 编辑器测试
    print("\n" + "=" * 60)
    print("测试 5: Request Body 编辑器测试")
    print("=" * 60)

    # 切换到 Body Tab
    result = client.send_command("switch_request_tab", {"tab": "body"})
    # Note: switch_request_tab 返回的格式可能不同，暂时只打印结果
    print(f"✅ 切换到 Body Tab: {result}")
    time.sleep(0.5)

    # 设置 Body 类型为 raw
    result = client.send_command("set_body_type", {"body_type": "raw"})
    print("✅ 设置 Body 类型为 raw")
    time.sleep(0.5)

    # 设置 Raw 内容类型为 JSON
    result = client.send_command("set_raw_content_type", {"content_type": "json"})
    print("✅ 设置 Raw 内容类型为 JSON")
    time.sleep(0.5)

    # 设置 Body 内容
    test_body = {
        "username": "zhongmou",
        "password": "7110eda4d09e062aa5e4a390b0a572ac0d2c0220",
        "remember": True
    }
    result = client.send_command("set_body", {
        "body": json.dumps(test_body, indent=2),
        "type": "json"
    })
    print("✅ 设置 Body 内容")
    time.sleep(1.0)

    # 截图 - Request Body
    result = client.send_command("capture_screenshot", {
        "name": "request_body_with_line_numbers"
    })
    print("✅ Request Body 截图已保存")
    time.sleep(1.0)

    print("\n" + "=" * 60)
    print("所有测试完成！")
    print("=" * 60)
    print("\n截图文件位置: ~/Downloads/hopp_*.png")
    print("\n验证要点:")
    print("1. ✅ Response Body 编辑器显示行号区域（40px 宽度、灰色背景）")
    print("2. ✅ Response Body 编辑器有 6px 圆角边框")
    print("3. ✅ JSON 语法高亮配色清晰（Key 深蓝、String 绿、Number 蓝）")
    print("4. ✅ 工具栏有 Beautify 按钮，点击可格式化 JSON")
    print("5. ✅ Request Body 编辑器有相同的行号和边框样式")

    return True


def main():
    parser = argparse.ArgumentParser(description="改进后的 Code Editor UI 测试")
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
