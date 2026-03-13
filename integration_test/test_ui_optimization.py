#!/usr/bin/env python3
"""
UI 优化测试脚本

测试内容包括:
1. Request Tab 样式和 + 按钮功能
2. Response Tab 字体和高度
3. URL 输入框对齐
4. Method 下拉菜单
5. Sidebar 弹出菜单

使用方法:
    python test_ui_optimization.py [--port PORT]
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path

import requests


class UIOptimizationTest:
    """UI 优化测试类"""

    def __init__(self, port=None):
        self.port = port
        self.base_url = None
        self.screenshots = []

    def _get_port_from_log(self):
        """从日志文件读取端口号"""
        import glob
        import re

        # 查找最新的 Hopp 日志文件
        log_dir = Path.home() / "Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs"
        log_files = list(log_dir.glob("hopp_*.log"))

        if log_files:
            log_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
            latest_log = log_files[0]
            content = latest_log.read_text()
            match = re.search(r'测试服务器启动在端口:\s*(\d+)', content)
            if match:
                return int(match.group(1))

        return None

    def _ensure_connection(self):
        """确保已连接到测试服务器"""
        if not self.base_url:
            port = self.port or self._get_port_from_log()
            if not port:
                raise Exception("无法获取测试服务器端口，请确保 Hopp 以 --test-mode 启动")
            self.port = port
            self.base_url = f"http://localhost:{port}"

    def send_command(self, action, params=None):
        """发送指令到 Hopp"""
        self._ensure_connection()

        data = {
            "action": action,
            "params": params or {}
        }

        try:
            response = requests.post(
                self.base_url,
                json=data,
                timeout=30
            )
            response.raise_for_status()
            resp_json = response.json()
            if resp_json.get('success'):
                return resp_json.get('result', {})
            else:
                raise Exception(f"服务器错误: {resp_json.get('error', '未知错误')}")
        except requests.exceptions.ConnectionError:
            raise Exception(f"无法连接到 Hopp 测试服务器 ({self.base_url})")
        except requests.exceptions.Timeout:
            raise Exception("请求超时")

    def capture_screenshot(self, name):
        """捕获屏幕截图"""
        screenshot_path = Path.home() / f"Desktop/ui_test_{name}.png"
        subprocess.run([
            "screencapture",
            "-x",
            str(screenshot_path)
        ], check=True)
        self.screenshots.append(screenshot_path)
        print(f"   📸 截图已保存: {screenshot_path.name}")
        return screenshot_path

    def test_ping(self):
        """测试连接"""
        print("\n" + "="*60)
        print("测试 1: 基础连接")
        print("="*60)
        result = self.send_command("ping")
        print(f"✅ 连接成功: {result}")
        return True

    def test_new_tab_button(self):
        """测试 + 按钮功能"""
        print("\n" + "="*60)
        print("测试 2: + 按钮创建新请求")
        print("="*60)

        # 获取当前 Tab 数量
        initial_info = self.send_command("get_ui_info")
        initial_count = initial_info.get('tab_count', 0)
        print(f"   初始标签数量: {initial_count}")

        # 点击 + 按钮
        result = self.send_command("click_new_tab_button")
        print(f"✅ 新请求已创建: {result.get('request_name')}")

        # 等待 UI 更新
        time.sleep(0.5)

        # 验证 Tab 数量增加
        new_info = self.send_command("get_ui_info")
        new_count = new_info.get('tab_count', 0)
        print(f"   当前标签数量: {new_count}")

        if new_count != initial_count + 1:
            print(f"❌ 标签数量未增加: {initial_count} -> {new_count}")
            return False

        # 截图验证
        self.capture_screenshot("new_tab_created")

        print("✅ + 按钮功能正常")
        return True

    def test_request_tabs_visual(self):
        """测试 Request Tab 视觉样式"""
        print("\n" + "="*60)
        print("测试 3: Request Tab 视觉样式")
        print("="*60)

        # 创建多个请求以显示选中/非选中对比
        self.send_command("click_new_tab_button")
        time.sleep(0.3)
        self.send_command("click_new_tab_button")
        time.sleep(0.3)

        # 获取 UI 信息
        info = self.send_command("get_ui_info")
        print(f"   当前标签数量: {info.get('tab_count')}")
        print(f"   活动标签: {info.get('active_tab_id', 'None')}")

        # 截图验证 Tab 样式
        time.sleep(0.5)
        self.capture_screenshot("request_tabs_multiple")

        print("✅ Request Tab 样式验证完成")
        return True

    def test_response_tabs(self):
        """测试 Response Tab 样式"""
        print("\n" + "="*60)
        print("测试 4: Response Tab 样式")
        print("="*60)

        # 创建请求并发送
        self.send_command("create_request")
        time.sleep(0.3)
        self.send_command("set_url", {"url": "https://httpbin.org/get"})
        self.send_command("send_request")

        print("   等待响应...")
        time.sleep(5)

        # 截图验证 Response Tabs
        self.capture_screenshot("response_tabs_body")

        # 切换 Tab 并截图
        self.send_command("switch_response_tab", {"tab": "headers"})
        time.sleep(0.5)
        self.capture_screenshot("response_tabs_headers")

        print("✅ Response Tab 样式验证完成")
        return True

    def test_url_input_alignment(self):
        """测试 URL 输入框对齐"""
        print("\n" + "="*60)
        print("测试 5: URL 输入框对齐")
        print("="*60)

        # 创建请求并设置 URL
        self.send_command("create_request")
        time.sleep(0.3)
        self.send_command("set_url", {"url": "https://httpbin.org/get"})

        # 截图验证 URL 输入框
        time.sleep(0.5)
        self.capture_screenshot("url_input_alignment")

        print("✅ URL 输入框对齐验证完成")
        return True

    def test_method_dropdown(self):
        """测试 Method 下拉菜单"""
        print("\n" + "="*60)
        print("测试 6: Method 下拉菜单")
        print("="*60)

        # 创建请求
        self.send_command("create_request")
        time.sleep(0.3)

        # 设置不同的 HTTP 方法
        methods = ["GET", "POST", "PUT", "DELETE"]
        for method in methods:
            self.send_command("set_method", {"method": method})
            print(f"   设置方法: {method}")
            time.sleep(0.3)

        # 截图验证
        self.capture_screenshot("method_dropdown")

        print("✅ Method 下拉菜单验证完成")
        return True

    def test_ui_info_consistency(self):
        """测试 UI 信息一致性"""
        print("\n" + "="*60)
        print("测试 7: UI 信息一致性")
        print("="*60)

        info = self.send_command("get_ui_info")

        # 验证关键字段
        required_fields = ['tab_count', 'active_tab_id', 'tabs', 'has_active_request']
        for field in required_fields:
            if field not in info:
                print(f"❌ 缺少字段: {field}")
                return False
            print(f"   {field}: {info.get(field)}")

        # 验证 tabs 数组
        tabs = info.get('tabs', [])
        for tab in tabs:
            tab_fields = ['id', 'name', 'method', 'is_active', 'is_dirty']
            for field in tab_fields:
                if field not in tab:
                    print(f"❌ Tab 缺少字段: {field}")
                    return False

        print("✅ UI 信息一致性验证完成")
        return True

    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "="*60)
        print("🎨 Hopp UI 优化测试套件")
        print("="*60)

        tests = [
            ("基础连接", self.test_ping),
            ("+ 按钮功能", self.test_new_tab_button),
            ("Request Tab 视觉", self.test_request_tabs_visual),
            ("Response Tab 样式", self.test_response_tabs),
            ("URL 输入框对齐", self.test_url_input_alignment),
            ("Method 下拉菜单", self.test_method_dropdown),
            ("UI 信息一致性", self.test_ui_info_consistency),
        ]

        passed = 0
        failed = 0

        for name, test_func in tests:
            try:
                if test_func():
                    passed += 1
                else:
                    failed += 1
                    print(f"❌ {name} 测试失败")
            except Exception as e:
                failed += 1
                print(f"❌ {name} 测试异常: {e}")

        # 汇总结果
        print("\n" + "="*60)
        print("📊 测试结果汇总")
        print("="*60)
        print(f"   总计: {passed + failed} 个测试")
        print(f"   ✅ 通过: {passed} 个")
        print(f"   ❌ 失败: {failed} 个")

        if self.screenshots:
            print(f"\n   📸 截图文件:")
            for screenshot in self.screenshots:
                print(f"      - {screenshot.name}")

        print("="*60)

        return failed == 0


def main():
    parser = argparse.ArgumentParser(
        description="Hopp UI 优化测试脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 运行所有测试
  %(prog)s --port 8080        # 指定端口
        """
    )

    parser.add_argument("--port", type=int, help="测试服务器端口（可选，默认从文件读取）")

    args = parser.parse_args()

    try:
        tester = UIOptimizationTest(port=args.port)
        success = tester.run_all_tests()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
