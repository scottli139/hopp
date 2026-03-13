#!/usr/bin/env python3
"""
Hopp 响应优化功能 UI 自动化测试

测试场景:
1. 模拟大响应并验证性能模式自动切换
2. 测试显示模式切换功能
3. 测试大响应加载更多功能
4. 测试响应体信息获取

使用方法:
    # 1. 以测试模式启动 Hopp
    ./hopp.app/Contents/MacOS/hopp --test-mode
    
    # 2. 运行测试
    python3 integration_test/test_response_optimization.py
    
    # 或指定端口
    python3 integration_test/test_response_optimization.py --port 8080
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path

from test_client import HoppTestClient


def run_response_optimization_test(port=None):
    """运行响应优化功能测试"""
    client = HoppTestClient(port=port)
    
    passed = 0
    failed = 0
    
    def run_test(name, test_func):
        nonlocal passed, failed
        print(f"\n{'='*60}")
        print(f"🧪 测试: {name}")
        print(f"{'='*60}")
        try:
            test_func()
            print(f"✅ 通过: {name}")
            passed += 1
        except Exception as e:
            print(f"❌ 失败: {name}")
            print(f"   错误: {e}")
            failed += 1
    
    # 测试 1: 基础连接
    def test_ping():
        client.ping()
    
    # 测试 2: 创建请求并模拟大响应
    def test_large_response_simulation():
        client.create_request()
        result = client.simulate_large_response(size=100000)  # 100KB
        assert result.get('size_bytes', 0) > 50000, "模拟响应大小不足"
        print(f"   ✅ 大响应模拟成功: {result.get('size_kb')} KB")
    
    # 测试 3: 获取响应体信息
    def test_get_response_body_info():
        result = client.get_response_body_info()
        assert result.get('has_body'), "响应体不存在"
        assert result.get('size_bytes', 0) > 0, "响应体大小为0"
        print(f"   ✅ 响应体信息获取成功")
    
    # 测试 4: 切换显示模式 - Performance
    def test_switch_to_performance_mode():
        result = client.set_response_display_mode("performance")
        assert result.get('mode') == 'performance', "模式切换失败"
        time.sleep(1)  # 等待 UI 更新
        print(f"   ✅ 切换到 Performance 模式成功")
    
    # 测试 5: 切换显示模式 - Full
    def test_switch_to_full_mode():
        result = client.set_response_display_mode("full")
        assert result.get('mode') == 'full', "模式切换失败"
        time.sleep(1)
        print(f"   ✅ 切换到 Full 模式成功")
    
    # 测试 6: 切换显示模式 - Auto
    def test_switch_to_auto_mode():
        result = client.set_response_display_mode("auto")
        assert result.get('mode') == 'auto', "模式切换失败"
        time.sleep(1)
        print(f"   ✅ 切换到 Auto 模式成功")
    
    # 测试 7: 测试超大响应 (> 200KB)
    def test_very_large_response():
        result = client.simulate_large_response(size=500000)  # 请求 500KB，实际生成约 250KB+
        assert result.get('size_bytes', 0) > 200000, "超大响应生成失败"
        body_info = client.get_response_body_info()
        assert body_info.get('size_bytes', 0) > 200000, "响应体信息不匹配"
        print(f"   ✅ 超大响应 ({result.get('size_kb')} KB) 处理成功")
    
    # 测试 8: 验证 Tab 切换正常
    def test_tab_switching():
        client.switch_response_tab("body")
        time.sleep(0.5)
        client.switch_response_tab("headers")
        time.sleep(0.5)
        client.switch_response_tab("body")
        time.sleep(0.5)
        print(f"   ✅ Tab 切换正常")
    
    # 执行所有测试
    print("\n" + "="*60)
    print("🚀 Hopp 响应优化功能 UI 自动化测试")
    print("="*60)
    
    run_test("基础连接", test_ping)
    run_test("大响应模拟", test_large_response_simulation)
    run_test("获取响应体信息", test_get_response_body_info)
    run_test("Tab 切换", test_tab_switching)
    run_test("切换到 Performance 模式", test_switch_to_performance_mode)
    run_test("切换到 Full 模式", test_switch_to_full_mode)
    run_test("切换到 Auto 模式", test_switch_to_auto_mode)
    run_test("超大响应处理", test_very_large_response)
    
    # 打印测试结果
    print("\n" + "="*60)
    print("📊 测试结果汇总")
    print("="*60)
    print(f"总计: {passed + failed} 个测试")
    print(f"通过: {passed} 个")
    print(f"失败: {failed} 个")
    
    if failed == 0:
        print("\n✅ 所有测试通过!")
        return True
    else:
        print(f"\n❌ {failed} 个测试失败")
        return False


def capture_screenshot(output_path=None):
    """捕获屏幕截图"""
    if output_path is None:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        output_path = f"/tmp/hopp_response_test_{timestamp}.png"
    
    try:
        subprocess.run(
            ["screencapture", "-x", output_path],
            check=True,
            capture_output=True
        )
        print(f"📸 截图已保存: {output_path}")
        return output_path
    except Exception as e:
        print(f"⚠️ 截图失败: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(
        description="Hopp 响应优化功能 UI 自动化测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                          # 自动获取端口运行测试
  %(prog)s --port 8080              # 指定端口
  %(prog)s --screenshot             # 测试后截图
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口")
    parser.add_argument("--screenshot", action="store_true", help="测试后截图")
    parser.add_argument("--output", help="截图输出路径")
    
    args = parser.parse_args()
    
    try:
        success = run_response_optimization_test(port=args.port)
        
        # 截图
        if args.screenshot or args.output:
            time.sleep(2)  # 等待 UI 稳定
            capture_screenshot(args.output)
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
