#!/usr/bin/env python3
"""
Hopp 请求名称编辑功能自动化测试（带截图验证）

测试场景:
1. 直接重命名请求 (非交互式) + 截图验证
2. 交互式编辑请求名称 + 截图验证
3. 取消编辑请求名称 + 截图验证

使用方法:
    python test_rename_request_with_screenshot.py [--port PORT]

前置条件:
    Hopp 应用必须以 --test-mode 启动
"""

import argparse
import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime

# 导入 test_client
sys.path.insert(0, str(Path(__file__).parent))
from test_client import HoppTestClient


class RenameRequestTesterWithScreenshot:
    """请求名称编辑功能测试器（带截图）"""

    def __init__(self, port=None, screenshot_dir=None):
        self.client = HoppTestClient(port=port)
        self.test_results = []
        
        # 截图保存目录
        if screenshot_dir is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            self.screenshot_dir = Path(__file__).parent / f"screenshots_{timestamp}"
        else:
            self.screenshot_dir = Path(screenshot_dir)
        
        self.screenshot_dir.mkdir(exist_ok=True)
        self.screenshot_count = 0

    def log(self, message):
        """打印日志"""
        print(f"  {message}")

    def screenshot(self, name):
        """截取屏幕截图"""
        self.screenshot_count += 1
        filename = self.screenshot_dir / f"{self.screenshot_count:02d}_{name}.png"
        
        try:
            # 使用 macOS screencapture 命令截图
            subprocess.run(
                ["screencapture", "-C", str(filename)],
                check=True,
                capture_output=True
            )
            print(f"  📸 截图已保存: {filename}")
            return filename
        except Exception as e:
            print(f"  ⚠️ 截图失败: {e}")
            return None

    def test_1_direct_rename_with_screenshot(self):
        """测试 1: 直接重命名请求（带截图）"""
        print("\n" + "=" * 60)
        print("🧪 测试 1: 直接重命名请求（带截图验证）")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            self.log(f"原始名称: {original_name}")
            time.sleep(1)
            
            # 截图：创建后的初始状态
            self.screenshot("test1_01_initial_state")
            time.sleep(0.5)

            # 2. 直接重命名
            print("\n📌 步骤 2: 直接重命名请求")
            new_name = "Test API - Direct Rename"
            result = self.client.rename_request(new_name)
            self.log(f"重命名结果: {result.get('old_name')} → {result.get('new_name')}")
            time.sleep(1)
            
            # 截图：重命名后的状态
            self.screenshot("test1_02_after_rename")
            time.sleep(0.5)

            # 3. 验证名称已更新
            print("\n📌 步骤 3: 验证名称更新")
            info = self.client.get_request_info()
            actual_name = info.get('name')
            self.log(f"当前名称: {actual_name}")

            if actual_name == new_name:
                print("\n✅ 测试 1 通过: 直接重命名成功")
                self.test_results.append(("测试 1: 直接重命名", True, None))
                return True
            else:
                raise AssertionError(f"名称不匹配: 期望 '{new_name}', 实际 '{actual_name}'")

        except Exception as e:
            print(f"\n❌ 测试 1 失败: {e}")
            self.test_results.append(("测试 1: 直接重命名", False, str(e)))
            return False

    def test_2_interactive_edit_with_screenshot(self):
        """测试 2: 交互式编辑请求名称（带截图）"""
        print("\n" + "=" * 60)
        print("🧪 测试 2: 交互式编辑请求名称（带截图验证）")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            self.log(f"原始名称: {original_name}")
            time.sleep(1)
            
            # 截图：创建后的初始状态
            self.screenshot("test2_01_initial_state")
            time.sleep(0.5)

            # 2. 开始编辑
            print("\n📌 步骤 2: 开始编辑模式")
            result = self.client.start_edit_request_name()
            self.log(f"进入编辑模式，当前名称: {result.get('current_name')}")
            time.sleep(1)
            
            # 截图：编辑模式开启
            self.screenshot("test2_02_edit_mode_started")
            time.sleep(0.5)

            # 3. 输入新名称
            print("\n📌 步骤 3: 输入新名称")
            new_name = "Test API - Interactive Edit"
            self.client.set_request_name(new_name)
            self.log(f"输入名称: {new_name}")
            time.sleep(0.5)
            
            # 截图：输入新名称后
            self.screenshot("test2_03_name_entered")
            time.sleep(0.5)

            # 4. 确认编辑
            print("\n📌 步骤 4: 确认编辑")
            result = self.client.confirm_edit_request_name()
            self.log(f"编辑确认: {result.get('old_name')} → {result.get('new_name')}")
            time.sleep(1)
            
            # 截图：确认后的状态
            self.screenshot("test2_04_after_confirm")
            time.sleep(0.5)

            # 5. 验证名称已更新
            print("\n📌 步骤 5: 验证名称更新")
            info = self.client.get_request_info()
            actual_name = info.get('name')
            self.log(f"当前名称: {actual_name}")

            if actual_name == new_name:
                print("\n✅ 测试 2 通过: 交互式编辑成功")
                self.test_results.append(("测试 2: 交互式编辑", True, None))
                return True
            else:
                raise AssertionError(f"名称不匹配: 期望 '{new_name}', 实际 '{actual_name}'")

        except Exception as e:
            print(f"\n❌ 测试 2 失败: {e}")
            self.test_results.append(("测试 2: 交互式编辑", False, str(e)))
            return False

    def test_3_cancel_edit_with_screenshot(self):
        """测试 3: 取消编辑请求名称（带截图）"""
        print("\n" + "=" * 60)
        print("🧪 测试 3: 取消编辑请求名称（带截图验证）")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            self.log(f"原始名称: {original_name}")
            time.sleep(1)
            
            # 截图：创建后的初始状态
            self.screenshot("test3_01_initial_state")
            time.sleep(0.5)

            # 2. 开始编辑
            print("\n📌 步骤 2: 开始编辑模式")
            self.client.start_edit_request_name()
            self.log("进入编辑模式")
            time.sleep(1)
            
            # 截图：编辑模式开启
            self.screenshot("test3_02_edit_mode_started")
            time.sleep(0.5)

            # 3. 输入新名称
            print("\n📌 步骤 3: 输入新名称（将被取消）")
            temp_name = "This Name Will Be Cancelled"
            self.client.set_request_name(temp_name)
            self.log(f"输入名称: {temp_name}")
            time.sleep(0.5)
            
            # 截图：输入新名称后
            self.screenshot("test3_03_name_entered")
            time.sleep(0.5)

            # 4. 取消编辑
            print("\n📌 步骤 4: 取消编辑")
            self.client.cancel_edit_request_name()
            self.log("编辑已取消")
            time.sleep(1)
            
            # 截图：取消后的状态
            self.screenshot("test3_04_after_cancel")
            time.sleep(0.5)

            # 5. 验证名称未改变
            print("\n📌 步骤 5: 验证名称未改变")
            info = self.client.get_request_info()
            actual_name = info.get('name')
            self.log(f"当前名称: {actual_name}")

            if actual_name == original_name:
                print("\n✅ 测试 3 通过: 取消编辑成功，名称未改变")
                self.test_results.append(("测试 3: 取消编辑", True, None))
                return True
            else:
                raise AssertionError(f"名称不应改变: 期望 '{original_name}', 实际 '{actual_name}'")

        except Exception as e:
            print(f"\n❌ 测试 3 失败: {e}")
            self.test_results.append(("测试 3: 取消编辑", False, str(e)))
            return False

    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "🚀" * 30)
        print("🚀 Hopp 请求名称编辑功能自动化测试（带截图）")
        print("🚀" * 30)
        print(f"\n📁 截图保存目录: {self.screenshot_dir}")

        # 测试连接
        print("\n📡 测试连接...")
        try:
            self.client.ping()
        except Exception as e:
            print(f"❌ 无法连接到 Hopp 测试服务器: {e}")
            print("请确保 Hopp 应用以 --test-mode 启动")
            sys.exit(1)

        # 运行测试
        self.test_1_direct_rename_with_screenshot()
        self.test_2_interactive_edit_with_screenshot()
        self.test_3_cancel_edit_with_screenshot()

        # 打印测试报告
        self.print_report()

    def print_report(self):
        """打印测试报告"""
        print("\n" + "=" * 60)
        print("📊 测试报告")
        print("=" * 60)

        passed = 0
        failed = 0

        for name, success, error in self.test_results:
            status = "✅ 通过" if success else "❌ 失败"
            print(f"\n{status}: {name}")
            if error:
                print(f"   错误: {error}")

            if success:
                passed += 1
            else:
                failed += 1

        total = len(self.test_results)
        print("\n" + "-" * 60)
        print(f"总计: {total} 个测试")
        print(f"通过: {passed} 个")
        print(f"失败: {failed} 个")
        print(f"\n📁 截图保存目录: {self.screenshot_dir}")
        print(f"📸 共截取 {self.screenshot_count} 张截图")

        if failed == 0:
            print("\n🎉 所有测试通过！")
            return 0
        else:
            print(f"\n⚠️ {failed} 个测试失败")
            return 1


def main():
    parser = argparse.ArgumentParser(
        description="Hopp 请求名称编辑功能自动化测试（带截图验证）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python test_rename_request_with_screenshot.py              # 运行所有测试
  python test_rename_request_with_screenshot.py --port 8080  # 指定端口

前置条件:
  1. 启动 Hopp 应用: ./hopp.app/Contents/MacOS/hopp --test-mode
  2. 等待应用启动完成
  3. 运行测试脚本
        """,
    )

    parser.add_argument("--port", type=int, help="测试服务器端口（可选）")
    parser.add_argument("--screenshot-dir", type=str, help="截图保存目录（可选）")

    args = parser.parse_args()

    try:
        tester = RenameRequestTesterWithScreenshot(
            port=args.port,
            screenshot_dir=args.screenshot_dir
        )
        exit_code = tester.run_all_tests()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\n⚠️ 测试被用户中断")
        sys.exit(130)
    except Exception as e:
        print(f"\n❌ 测试套件执行失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
