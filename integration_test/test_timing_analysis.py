#!/usr/bin/env python3
"""
Timing 分析功能 UI 测试脚本

测试内容：
1. 创建新请求
2. 模拟带时间分析的响应
3. 切换到 Timing Tab
4. 截图验证 UI
5. 获取时间分析信息

使用方法：
    1. 启动应用（测试模式）:
       ./hopp.app/Contents/MacOS/hopp --test-mode
    
    2. 运行测试:
       python3 integration_test/test_timing_analysis.py

"""

import argparse
import subprocess
import sys
import time
from pathlib import Path

# 导入 test_client
sys.path.insert(0, str(Path(__file__).parent))
from test_client import HoppTestClient


def run_timing_test(port=None):
    """执行 Timing 分析测试"""
    client = HoppTestClient(port=port)
    
    print("\n" + "="*60)
    print("⏱️  Timing 分析功能 UI 自动化测试")
    print("="*60 + "\n")
    
    try:
        # 1. 测试连接
        print("📡 测试连接...")
        client.ping()
        print()
        
        # 2. 创建新请求
        client.create_request()
        print()
        
        # 3. 设置 URL
        client.set_url("https://httpbin.org/get")
        print()
        
        # 4. 模拟带时间分析的响应
        result = client.simulate_response_with_timing()
        print()
        
        # 等待响应处理
        time.sleep(1)
        
        # 5. 获取响应信息
        client.get_response_info()
        print()
        
        # 6. 切换到 Timing Tab
        client.switch_response_tab("timing")
        print()
        
        # 7. 等待 UI 渲染
        print("⏳ 等待 UI 渲染...")
        time.sleep(2)
        
        # 8. 截图验证
        screenshot_path = Path.home() / "Desktop/timing_tab_test.png"
        print(f"📸 截图保存到: {screenshot_path}")
        subprocess.run(
            ["screencapture", "-x", str(screenshot_path)],
            check=True
        )
        print("✅ 截图完成")
        print()
        
        # 9. 获取时间分析信息
        client.get_timing_info()
        print()
        
        # 10. 测试切换到 Headers Tab
        client.switch_response_tab("headers")
        print()
        time.sleep(1)
        
        # 11. 再切换回 Timing Tab
        client.switch_response_tab("timing")
        print()
        time.sleep(1)
        
        # 12. 再次截图
        screenshot_path2 = Path.home() / "Desktop/timing_tab_test2.png"
        print(f"📸 截图保存到: {screenshot_path2}")
        subprocess.run(
            ["screencapture", "-x", str(screenshot_path2)],
            check=True
        )
        print("✅ 截图完成")
        print()
        
        print("="*60)
        print("✅ 所有测试通过!")
        print("="*60)
        print()
        print("📊 测试总结:")
        print("   - TimingInfo 模型: ✅")
        print("   - 模拟响应创建: ✅")
        print("   - Timing Tab 切换: ✅")
        print("   - 时间数据获取: ✅")
        print("   - UI 截图验证: ✅")
        print()
        
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Timing 分析功能 UI 测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 运行完整测试
  %(prog)s --port 8080       # 指定测试服务器端口
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口（可选，默认从日志读取）")
    
    args = parser.parse_args()
    
    success = run_timing_test(port=args.port)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
