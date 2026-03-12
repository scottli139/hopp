#!/usr/bin/env python3
"""
Hopp 请求名称编辑功能自动化测试

测试场景:
1. 直接重命名请求 (非交互式)
2. 交互式编辑请求名称
3. 取消编辑请求名称

使用方法:
    python test_rename_request.py [--port PORT]

前置条件:
    Hopp 应用必须以 --test-mode 启动
"""

import argparse
import sys
import time
from pathlib import Path

# 导入 test_client
sys.path.insert(0, str(Path(__file__).parent))
from test_client import HoppTestClient


class RenameRequestTester:
    """请求名称编辑功能测试器"""

    def __init__(self, port=None):
        self.client = HoppTestClient(port=port)
        self.test_results = []

    def log(self, message):
        """打印日志"""
        print(f"  {message}")

    def test_1_direct_rename(self):
        """测试 1: 直接重命名请求"""
        print("\n" + "=" * 60)
        print("🧪 测试 1: 直接重命名请求 (非交互式)")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            request_id = result.get('request_id')
            self.log(f"原始名称: {original_name}")
            self.log(f"请求 ID: {request_id}")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 2. 直接重命名
            print("\n📌 步骤 2: 直接重命名请求")
            new_name = "Test API - Direct Rename"
            result = self.client.rename_request(new_name)
            self.log(f"重命名结果: {result.get('old_name')} → {result.get('new_name')}")

            # 等待 UI 渲染
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

    def test_2_interactive_edit(self):
        """测试 2: 交互式编辑请求名称"""
        print("\n" + "=" * 60)
        print("🧪 测试 2: 交互式编辑请求名称")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            request_id = result.get('request_id')
            self.log(f"原始名称: {original_name}")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 2. 开始编辑
            print("\n📌 步骤 2: 开始编辑模式")
            result = self.client.start_edit_request_name()
            self.log(f"进入编辑模式，当前名称: {result.get('current_name')}")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 3. 输入新名称
            print("\n📌 步骤 3: 输入新名称")
            new_name = "Test API - Interactive Edit"
            self.client.set_request_name(new_name)
            self.log(f"输入名称: {new_name}")

            # 等待 UI 渲染
            time.sleep(0.3)

            # 4. 确认编辑
            print("\n📌 步骤 4: 确认编辑")
            result = self.client.confirm_edit_request_name()
            self.log(f"编辑确认: {result.get('old_name')} → {result.get('new_name')}")

            # 等待 UI 渲染
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

    def test_3_cancel_edit(self):
        """测试 3: 取消编辑请求名称"""
        print("\n" + "=" * 60)
        print("🧪 测试 3: 取消编辑请求名称")
        print("=" * 60)

        try:
            # 1. 创建新请求
            print("\n📌 步骤 1: 创建新请求")
            result = self.client.create_request()
            original_name = result.get('name')
            request_id = result.get('request_id')
            self.log(f"原始名称: {original_name}")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 2. 开始编辑
            print("\n📌 步骤 2: 开始编辑模式")
            self.client.start_edit_request_name()
            self.log("进入编辑模式")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 3. 输入新名称
            print("\n📌 步骤 3: 输入新名称（将被取消）")
            temp_name = "This Name Will Be Cancelled"
            self.client.set_request_name(temp_name)
            self.log(f"输入名称: {temp_name}")

            # 等待 UI 渲染
            time.sleep(0.3)

            # 4. 取消编辑
            print("\n📌 步骤 4: 取消编辑")
            result = self.client.cancel_edit_request_name()
            self.log("编辑已取消")

            # 等待 UI 渲染
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

    def test_4_rename_existing_request(self):
        """测试 4: 重命名已存在的请求（从 Collection 中）"""
        print("\n" + "=" * 60)
        print("🧪 测试 4: 重命名已存在的请求")
        print("=" * 60)

        try:
            # 注意：这个测试需要有一个已存在的 Collection 和请求
            # 我们先创建一个新的 Collection 和请求

            # 1. 检查当前请求
            print("\n📌 步骤 1: 获取当前活动请求信息")
            try:
                info = self.client.get_request_info()
                if info.get('request_id'):
                    request_id = info.get('request_id')
                    old_name = info.get('name')
                    self.log(f"找到请求: {old_name} ({request_id})")
                else:
                    print("⚠️ 没有活动请求，创建新请求")
                    result = self.client.create_request()
                    request_id = result.get('request_id')
                    old_name = result.get('name')
            except Exception as e:
                print(f"⚠️ 获取请求信息失败，创建新请求: {e}")
                result = self.client.create_request()
                request_id = result.get('request_id')
                old_name = result.get('name')

            # 2. 重命名
            print("\n📌 步骤 2: 重命名请求")
            new_name = "Renamed Existing Request"
            result = self.client.rename_request(new_name, request_id)
            self.log(f"重命名: {result.get('old_name')} → {result.get('new_name')}")

            # 等待 UI 渲染
            time.sleep(0.5)

            # 3. 验证
            print("\n📌 步骤 3: 验证名称更新")
            info = self.client.get_request_info(request_id)
            actual_name = info.get('name')
            self.log(f"当前名称: {actual_name}")

            if actual_name == new_name:
                print("\n✅ 测试 4 通过: 重命名已存在请求成功")
                self.test_results.append(("测试 4: 重命名已存在请求", True, None))
                return True
            else:
                raise AssertionError(f"名称不匹配: 期望 '{new_name}', 实际 '{actual_name}'")

        except Exception as e:
            print(f"\n❌ 测试 4 失败: {e}")
            self.test_results.append(("测试 4: 重命名已存在请求", False, str(e)))
            return False

    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "🚀" * 30)
        print("🚀 Hopp 请求名称编辑功能自动化测试套件")
        print("🚀" * 30)

        # 测试连接
        print("\n📡 测试连接...")
        try:
            self.client.ping()
        except Exception as e:
            print(f"❌ 无法连接到 Hopp 测试服务器: {e}")
            print("请确保 Hopp 应用以 --test-mode 启动")
            sys.exit(1)

        # 运行测试
        self.test_1_direct_rename()
        self.test_2_interactive_edit()
        self.test_3_cancel_edit()
        self.test_4_rename_existing_request()

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

        if failed == 0:
            print("\n🎉 所有测试通过！")
            return 0
        else:
            print(f"\n⚠️ {failed} 个测试失败")
            return 1


def main():
    parser = argparse.ArgumentParser(
        description="Hopp 请求名称编辑功能自动化测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python test_rename_request.py              # 运行所有测试
  python test_rename_request.py --port 8080  # 指定端口

前置条件:
  1. 启动 Hopp 应用: ./hopp.app/Contents/MacOS/hopp --test-mode
  2. 等待应用启动完成
  3. 运行测试脚本
        """,
    )

    parser.add_argument("--port", type=int, help="测试服务器端口（可选）")

    args = parser.parse_args()

    try:
        tester = RenameRequestTester(port=args.port)
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
