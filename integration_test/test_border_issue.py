#!/usr/bin/env python3
"""
测试 Request Body 和 Response Body 边框问题
"""
import sys
import time
sys.path.insert(0, '/Volumes/hagibis1t/huicom/github/postman/integration_test')

from test_client import HoppTestClient


def test_border_issue():
    """测试边框问题"""
    # 连接到应用
    client = HoppTestClient(port=64358)
    
    print("=" * 60)
    print("测试 1: 创建请求并设置 Body")
    print("=" * 60)
    
    # 创建新请求
    result = client.send_command("create_request", {})
    print(f"创建请求: {result}")
    time.sleep(0.5)
    
    # 切换到 Body Tab
    result = client.send_command("switch_request_tab", {"tab": "body"})
    print(f"切换到 Body Tab: {result}")
    time.sleep(0.5)
    
    # 设置 Body 类型为 raw
    result = client.send_command("set_body_type", {"type": "raw"})
    print(f"设置 Body 类型: {result}")
    time.sleep(0.5)
    
    # 设置 Body 内容（让输入区域有内容）
    result = client.send_command("set_body_content", {
        "content": '{"test": "value", "number": 123}'
    })
    print(f"设置 Body 内容: {result}")
    time.sleep(1.0)
    
    # 截图 - Request Body 未聚焦状态
    print("\n" + "=" * 60)
    print("测试 2: 检查 Request Body 未聚焦时的边框")
    print("=" * 60)
    
    # 模拟响应以显示 Response Body
    result = client.send_command("simulate_response_with_timing", {
        "body": '{"ip": "1.2.3.4", "city": "Beijing"}',
        "contentType": "application/json",
        "totalMs": 150
    })
    print(f"模拟响应: {result}")
    time.sleep(1.0)
    
    # 点击 Headers tab 让 Body 区域失去焦点
    result = client.send_command("switch_response_tab", {"tab": "headers"})
    print(f"切换到 Headers Tab (Body 失去焦点): {result}")
    time.sleep(1.0)
    
    # 截图
    result = client.send_command("capture_screenshot", {
        "filename": "request_body_unfocused.png"
    })
    print(f"截图 (Request Body 未聚焦): {result}")
    time.sleep(0.5)
    
    # 回到 Body Tab
    result = client.send_command("switch_response_tab", {"tab": "body"})
    print(f"切换到 Body Tab: {result}")
    time.sleep(1.0)
    
    # 截图 - Response Body 聚焦状态
    result = client.send_command("capture_screenshot", {
        "filename": "response_body_focused.png"
    })
    print(f"截图 (Response Body 聚焦): {result}")
    time.sleep(0.5)
    
    print("\n" + "=" * 60)
    print("测试完成，请检查截图文件:")
    print("- request_body_unfocused.png")
    print("- response_body_focused.png")
    print("=" * 60)


if __name__ == "__main__":
    test_border_issue()
