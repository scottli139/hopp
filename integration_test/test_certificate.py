#!/usr/bin/env python3
"""
Hopp Certificate Tab 功能测试脚本

测试 SSL/TLS 证书获取和显示功能

使用方法:
    1. 启动 Hopp 应用（测试模式）:
       ./hopp.app/Contents/MacOS/hopp --test-mode
    
    2. 运行测试:
       python3 test_certificate.py
"""

import sys
import time
import subprocess
from pathlib import Path

# 导入测试客户端
from test_client import HoppTestClient


def run_certificate_tests():
    """运行证书功能测试"""
    print("\n" + "=" * 70)
    print("🔒 Hopp Certificate Tab 功能测试")
    print("=" * 70 + "\n")
    
    client = HoppTestClient()
    
    try:
        # 测试 1: 基础连接
        print("\n" + "=" * 70)
        print("测试 1: 基础连接")
        print("=" * 70)
        client.ping()
        time.sleep(0.5)
        
        # 测试 2: 模拟带证书信息的响应
        print("\n" + "=" * 70)
        print("测试 2: 模拟带证书信息的 HTTPS 响应")
        print("=" * 70)
        client.create_request()
        client.set_url("https://httpbin.org/get")
        cert_result = client.simulate_certificate_response()
        time.sleep(1.0)
        
        # 测试 3: 获取证书信息
        print("\n" + "=" * 70)
        print("测试 3: 获取证书信息")
        print("=" * 70)
        info_result = client.get_certificate_info()
        time.sleep(0.5)
        
        # 测试 4: 切换到 Certificate Tab
        print("\n" + "=" * 70)
        print("测试 4: 切换到 Certificate Tab")
        print("=" * 70)
        client.switch_response_tab("certificate")
        time.sleep(1.0)
        
        # 测试 5: 截图验证 Certificate Tab
        print("\n" + "=" * 70)
        print("测试 5: 截图验证 Certificate Tab")
        print("=" * 70)
        screenshot_result = client.capture_screenshot("certificate_tab_test")
        time.sleep(0.5)
        
        # 测试 6: 验证真实 HTTPS 请求证书获取（可选）
        print("\n" + "=" * 70)
        print("测试 6: 真实 HTTPS 请求证书获取测试")
        print("=" * 70)
        client.create_request()
        client.set_url("https://www.google.com")
        client.send_request()
        
        print("\n⏳ 等待响应...")
        time.sleep(5)
        
        # 获取响应信息
        response_info = client.get_response_info()
        
        # 获取证书信息
        cert_info = client.get_certificate_info()
        
        if cert_info.get('has_certificate'):
            print("✅ 成功获取真实证书信息！")
        else:
            print("⚠️  未获取到证书信息（可能网络问题或目标服务器配置）")
        
        # 切换到 Certificate Tab 并截图
        client.switch_response_tab("certificate")
        time.sleep(1.0)
        client.capture_screenshot("real_certificate_test")
        
        # 测试 7: 测试证书过期警告（模拟过期证书）
        print("\n" + "=" * 70)
        print("测试 7: 证书过期警告测试")
        print("=" * 70)
        # 注：实际过期证书测试需要特殊服务器，这里只验证 UI 可以显示过期状态
        print("ℹ️  证书过期警告 UI 测试需要特殊配置的服务器")
        print("   当前实现：证书过期时在 Certificate Tab 显示警告图标")
        
        print("\n" + "=" * 70)
        print("✅ 所有测试完成！")
        print("=" * 70 + "\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def take_screenshot(name):
    """使用 screencapture 截图（macOS）"""
    try:
        screenshot_path = Path.home() / f"Desktop/{name}.png"
        subprocess.run(
            ["screencapture", "-x", str(screenshot_path)],
            check=True
        )
        print(f"📸 截图已保存: {screenshot_path}")
        return str(screenshot_path)
    except Exception as e:
        print(f"⚠️  截图失败: {e}")
        return None


if __name__ == "__main__":
    success = run_certificate_tests()
    sys.exit(0 if success else 1)
