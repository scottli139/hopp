#!/usr/bin/env python3
"""
Hopp 字体更新 UI 测试

验证 Request Body 和 Response Body 编辑器的字体规范：
- 使用等宽字体 JetBrains Mono
- 代码字号 12px
- 行号字号 11px
- 行高 1.5

使用方法:
    python test_font_update.py

截图验证:
    - test_request_body_font.png - Request Body 区域字体
    - test_response_body_font.png - Response Body 区域字体
"""

import argparse
import sys
import time
from pathlib import Path

# 导入 test_client
sys.path.insert(0, str(Path(__file__).parent))
from test_client import HoppTestClient


def run_font_tests(client: HoppTestClient):
    """运行字体测试"""
    print("=" * 60)
    print("字体规范验证测试")
    print("=" * 60)
    
    # 测试 1: 基础连接
    print("\n测试 1: 基础连接")
    try:
        result = client.send_command('ping')
        print(f"✅ 连接成功: {result}")
    except Exception as e:
        print(f"❌ 连接失败: {e}")
        return False
    
    # 测试 2: 创建请求并设置 JSON Body
    print("\n测试 2: 创建请求并设置 JSON Body")
    try:
        result = client.send_command('create_request')
        print(f"✅ 创建新请求: {result.get('name')} ({result.get('request_id')})")
        
        # 设置 URL
        client.send_command('set_url', {'url': 'https://httpbin.org/post'})
        print("✅ 设置 URL: https://httpbin.org/post")
        
        # 切换到 Body Tab
        client.send_command('switch_request_tab', {'tab': 'body'})
        print("✅ 切换到 Body Tab")
        time.sleep(0.5)
        
        # 设置 Body 类型为 raw
        client.send_command('set_body_type', {'body_type': 'raw'})
        print("✅ 设置 Body 类型为 raw")
        time.sleep(0.3)
        
        # 设置 Raw 内容类型为 JSON
        client.send_command('set_raw_content_type', {'content_type': 'json'})
        print("✅ 设置 Raw 内容类型为 JSON")
        time.sleep(0.3)
        
        # 设置 Body 内容
        test_body = '''{
  "username": "test_user",
  "email": "test@example.com",
  "settings": {
    "theme": "dark",
    "notifications": true
  }
}'''
        client.send_command('set_body', {'body': test_body, 'type': 'json'})
        print(f"✅ 设置 Body 内容 ({len(test_body)} 字符)")
        time.sleep(0.5)
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False
    
    # 测试 3: Request Body 截图
    print("\n测试 3: Request Body 字体截图")
    try:
        result = client.send_command('capture_screenshot', {'name': 'request_body_font'})
        print(f"✅ Request Body 截图: {result.get('path')}")
        time.sleep(0.5)
    except Exception as e:
        print(f"⚠️ 截图失败: {e}")
    
    # 测试 4: 发送请求并验证 Response Body 字体
    print("\n测试 4: 模拟响应并验证 Response Body 字体")
    try:
        # 使用模拟响应
        client.send_command('simulate_response_with_timing')
        print("✅ 模拟响应已设置")
        time.sleep(0.5)
        
        # 切换到 Body Tab
        client.send_command('switch_response_tab', {'tab': 'body'})
        print("✅ 切换到 Response Body Tab")
        time.sleep(0.5)
        
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False
    
    # 测试 5: Response Body 截图
    print("\n测试 5: Response Body 字体截图")
    try:
        result = client.send_command('capture_screenshot', {'name': 'response_body_font'})
        print(f"✅ Response Body 截图: {result.get('path')}")
        time.sleep(0.5)
    except Exception as e:
        print(f"⚠️ 截图失败: {e}")
    
    print("\n" + "=" * 60)
    print("字体规范验证完成")
    print("=" * 60)
    print("""
字体规范:
- 字体: JetBrains Mono (等宽字体)
- 代码字号: 12px
- 行号字号: 11px
- 行高: 1.5

请检查截图验证:
1. test_request_body_font.png - Request Body 区域
2. test_response_body_font.png - Response Body 区域

验证要点:
- 字体应为等宽字体（字符宽度一致）
- 代码文字大小适中（12px）
- 行号略小于代码（11px）
- 行间距舒适（1.5 倍行高）
""")
    
    return True


def main():
    parser = argparse.ArgumentParser(description='Hopp 字体更新 UI 测试')
    parser.add_argument('--port', type=int, help='测试服务器端口（自动检测）')
    args = parser.parse_args()
    
    try:
        client = HoppTestClient(port=args.port)
        success = run_font_tests(client)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
