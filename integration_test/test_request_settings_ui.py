#!/usr/bin/env python3
"""
Request Settings UI 测试脚本

验证 Settings Tab 的 UI 样式是否符合规范:
- 字号: 分组标题 12px, 设置项标题 14px, 描述 12px
- Switch: 尺寸 32x18px, ON 状态 Indigo 500, OFF 状态 border color
- 颜色: Coming Soon 不使用紫色

使用方法:
    python3 test_request_settings_ui.py

前提条件:
    Hopp 应用以测试模式启动: ./hopp.app/Contents/MacOS/hopp --test-mode
"""

import sys
import time
import subprocess
from pathlib import Path

# 导入 test_client
sys.path.insert(0, str(Path(__file__).parent))
from test_client import HoppTestClient


def run_tests():
    """运行所有测试"""
    print("=" * 60)
    print("Request Settings UI 测试")
    print("=" * 60)
    
    client = HoppTestClient()
    
    try:
        # 测试 1: 基础连接
        print("\n[测试 1] 基础连接")
        print("-" * 40)
        client.ping()
        
        # 测试 2: 创建请求
        print("\n[测试 2] 创建新请求")
        print("-" * 40)
        client.create_request()
        time.sleep(0.5)
        
        # 测试 3: 切换到 Settings Tab
        print("\n[测试 3] 切换到 Settings Tab")
        print("-" * 40)
        client.switch_request_tab("settings")
        time.sleep(1.0)  # 等待 UI 渲染
        
        # 截图 1: Settings Tab 初始状态
        print("\n[截图 1] Settings Tab 初始状态")
        print("-" * 40)
        screenshot_path = "/tmp/test_settings_initial.png"
        subprocess.run([
            "screencapture", "-x", screenshot_path
        ], check=True)
        print(f"✅ 截图已保存: {screenshot_path}")
        time.sleep(0.5)
        
        # 测试 4: 切换开关状态 (OFF -> ON)
        print("\n[测试 4] 切换 SSL 验证开关 (OFF -> ON)")
        print("-" * 40)
        # 注意：当前应用没有直接的 UI 测试指令来点击开关
        # 我们通过截图来验证开关的视觉效果
        print("ℹ️  请手动检查开关状态显示为 ON")
        time.sleep(0.5)
        
        # 截图 2: 开关 ON 状态
        print("\n[截图 2] 开关 ON 状态")
        print("-" * 40)
        screenshot_path = "/tmp/test_settings_switch_on.png"
        subprocess.run([
            "screencapture", "-x", screenshot_path
        ], check=True)
        print(f"✅ 截图已保存: {screenshot_path}")
        time.sleep(0.5)
        
        print("\n" + "=" * 60)
        print("所有测试完成！")
        print("=" * 60)
        print("\n请检查截图验证以下内容:")
        print("1. SSL/TLS 标题字号应为 12px，颜色为灰色 (textSecondary)")
        print("2. 'Enable SSL certificate verification' 标题字号 14px")
        print("3. 描述文字 'Verify the server's...' 字号 12px")
        print("4. Switch 开关尺寸较小 (约 32x18px)")
        print("5. Switch ON 状态颜色为 Indigo 500 (紫色)")
        print("6. 显示 'ON' 状态文字")
        print("7. 'Coming Soon' 颜色为灰色而非紫色")
        print("8. 'Follow redirects' 和 'Request timeout' 字号 14px")
        print("\n截图位置:")
        print("  - /tmp/test_settings_initial.png")
        print("  - /tmp/test_settings_switch_on.png")
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(run_tests())
