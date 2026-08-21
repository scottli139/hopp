#!/usr/bin/env python3
"""环境变量系统（M8.1）UI 自动化验收测试

测试流程：
1. 创建/删除环境（test-mode 指令）
2. 全局变量与作用域优先级（环境覆盖全局）
3. {{variable}} 替换引擎（含动态变量）
4. 请求级替换（URL/Params/Headers）
5. 环境切换实时生效
6. 环境管理对话框 UI（截图）
7. 未定义变量提示

运行方式：
    # 先启动应用（test mode）
    ./build/macos/Build/Products/Debug/hopp.app/Contents/MacOS/hopp --test-mode &
    # 运行测试
    python3 integration_test/test_environment_variables.py
"""

import argparse
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


class EnvironmentVariablesTest:
    def __init__(self, port=None):
        self.client = HoppTestClient(port=port)
        self.results = []
        self.created_env_ids = []

    def record(self, name, passed, error=None):
        status = "✅ PASS" if passed else "❌ FAIL"
        self.results.append((name, passed, error))
        print(f"{status}: {name}" + (f" - {error}" if error else ""))

    def run(self):
        print("=" * 60)
        print("环境变量系统（M8.1）UI 自动化验收测试")
        print("=" * 60)

        try:
            self.client.ping()

            self.test_create_and_list_environments()
            self.test_scope_precedence()
            self.test_dynamic_variables()
            self.test_unresolved_reporting()
            self.test_request_resolution()
            self.test_environment_switch_live()
            self.test_globals_fallback()
            self.test_environment_dialog_ui()
            self.test_delete_environment()
        finally:
            self.cleanup()

        self.print_report()

    # ==================== 测试用例 ====================

    def test_create_and_list_environments(self):
        """创建两个环境并验证列表"""
        try:
            dev = self.client.create_environment("Development", [
                {"key": "baseUrl", "value": "https://dev.api.example.com"},
                {"key": "token", "value": "dev-secret-token", "type": "secret"},
                {"key": "disabledVar", "value": "x", "enabled": False},
            ])
            prod = self.client.create_environment("Production", [
                {"key": "baseUrl", "value": "https://api.example.com"},
            ])
            self.created_env_ids = [dev["id"], prod["id"]]

            envs = self.client.get_environments()
            names = [e["name"] for e in envs["environments"]]
            assert "Development" in names and "Production" in names, \
                f"环境列表不完整: {names}"
            assert envs["count"] >= 2, f"环境数量异常: {envs['count']}"

            # 验证变量内容（secret 类型、disabled 标记）
            dev_env = next(e for e in envs["environments"]
                           if e["id"] == dev["id"])
            assert dev_env["variable_count"] == 3
            token_var = next(v for v in dev_env["variables"]
                             if v["key"] == "token")
            assert token_var["type"] == "secret", "secret 类型未保存"
            disabled_var = next(v for v in dev_env["variables"]
                                if v["key"] == "disabledVar")
            assert disabled_var["enabled"] is False, "enabled=false 未保存"

            self.record("创建环境并验证列表", True)
        except Exception as e:
            self.record("创建环境并验证列表", False, str(e))

    def test_scope_precedence(self):
        """作用域优先级：环境变量覆盖同名全局变量"""
        try:
            self.client.set_global_variables([
                {"key": "baseUrl", "value": "https://global.override"},
                {"key": "version", "value": "v1"},
            ])
            self.client.set_active_environment(name="Development")

            result = self.client.resolve_text("{{baseUrl}}|{{version}}")
            resolved = result["resolved"]
            assert resolved == "https://dev.api.example.com|v1", \
                f"作用域优先级错误: {resolved}"

            self.record("作用域优先级（环境 > 全局）", True)
        except Exception as e:
            self.record("作用域优先级（环境 > 全局）", False, str(e))

    def test_dynamic_variables(self):
        """动态变量：$timestamp / $randomUUID"""
        try:
            result = self.client.resolve_text(
                "{{$timestamp}}|{{$randomUUID}}")
            resolved = result["resolved"]
            ts, uuid_val = resolved.split("|")
            assert ts.isdigit() and len(ts) >= 9, f"$timestamp 异常: {ts}"
            uuid_pattern = re.compile(
                r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-"
                r"[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
            assert uuid_pattern.match(uuid_val), f"$randomUUID 异常: {uuid_val}"
            assert result["unresolved"] == [], \
                f"动态变量被误报为未定义: {result['unresolved']}"

            self.record("动态变量解析", True)
        except Exception as e:
            self.record("动态变量解析", False, str(e))

    def test_unresolved_reporting(self):
        """未定义变量保留原样并如实报告"""
        try:
            result = self.client.resolve_text(
                "{{baseUrl}}/{{no_such_var}}")
            assert result["resolved"].endswith("/{{no_such_var}}"), \
                f"未定义变量未保留原样: {result['resolved']}"
            assert result["unresolved"] == ["no_such_var"], \
                f"未定义变量报告错误: {result['unresolved']}"

            self.record("未定义变量标记", True)
        except Exception as e:
            self.record("未定义变量标记", False, str(e))

    def test_request_resolution(self):
        """请求级替换：URL / Params / Headers"""
        try:
            self.client.set_active_environment(name="Development")
            self.client.create_request()
            self.client.set_url("{{baseUrl}}/users/list?q=test")
            self.client.add_header("Authorization", "Bearer {{token}}")

            resolved = self.client.get_resolved_request()
            assert resolved["url"] == \
                "https://dev.api.example.com/users/list", \
                f"URL 替换错误: {resolved['url']}"
            # set_url 会把 ?q=test 解析进 params
            params = {p["key"]: p["value"] for p in resolved["params"]}
            assert params.get("q") == "test", f"Params 错误: {params}"
            headers = {h["key"]: h["value"] for h in resolved["headers"]}
            assert headers.get("Authorization") == "Bearer dev-secret-token", \
                f"Header 替换错误: {headers}"

            self.record("请求级变量替换（URL/Params/Headers）", True)
        except Exception as e:
            self.record("请求级变量替换（URL/Params/Headers）", False, str(e))

    def test_environment_switch_live(self):
        """切换激活环境后，替换结果实时变化"""
        try:
            self.client.set_active_environment(name="Production")
            resolved = self.client.get_resolved_request()
            assert resolved["url"].startswith("https://api.example.com/"), \
                f"切换环境未生效: {resolved['url']}"
            headers = {h["key"]: h["value"] for h in resolved["headers"]}
            # Production 无 token 变量 → 保留原样并报告未定义
            assert headers.get("Authorization") == "Bearer {{token}}"
            assert "token" in resolved["unresolved"], \
                f"未定义变量未报告: {resolved['unresolved']}"

            self.client.set_active_environment(name="Development")
            resolved = self.client.get_resolved_request()
            assert resolved["url"].startswith(
                "https://dev.api.example.com/"), "切回环境未生效"

            self.record("环境切换实时生效", True)
        except Exception as e:
            self.record("环境切换实时生效", False, str(e))

    def test_globals_fallback(self):
        """无激活环境时回退到全局变量"""
        try:
            self.client.set_active_environment()
            active = self.client.get_active_environment()
            assert active.get("active") is False, "取消激活失败"

            result = self.client.resolve_text("{{baseUrl}}|{{version}}")
            assert result["resolved"] == "https://global.override|v1", \
                f"全局变量回退失败: {result['resolved']}"

            self.record("全局变量回退", True)
        except Exception as e:
            self.record("全局变量回退", False, str(e))

    def test_environment_dialog_ui(self):
        """环境管理对话框 UI（截图存档）"""
        try:
            self.client.set_active_environment(name="Development")
            time.sleep(0.5)
            self.client.capture_screenshot("env_switcher_active")

            self.client.trigger_environment_dialog()
            time.sleep(1.0)
            self.client.capture_screenshot("env_manager_dialog")

            self.record("环境管理对话框 UI（截图）", True)
        except Exception as e:
            self.record("环境管理对话框 UI（截图）", False, str(e))

    def test_delete_environment(self):
        """删除环境（含激活环境自动取消）"""
        try:
            # 删除非激活环境
            prod_id = next(
                e["id"] for e in self.client.get_environments()["environments"]
                if e["name"] == "Production")
            self.client.delete_environment(prod_id)
            if prod_id in self.created_env_ids:
                self.created_env_ids.remove(prod_id)

            envs = self.client.get_environments()
            names = [e["name"] for e in envs["environments"]]
            assert "Production" not in names, f"删除失败: {names}"
            assert "Development" in names

            # 删除激活环境 → 激活状态应自动清除
            self.client.set_active_environment(name="Development")
            dev_id = next(
                e["id"] for e in self.client.get_environments()["environments"]
                if e["name"] == "Development")
            self.client.delete_environment(dev_id)
            if dev_id in self.created_env_ids:
                self.created_env_ids.remove(dev_id)

            active = self.client.get_active_environment()
            assert active.get("active") is False, \
                "删除激活环境后激活状态未清除"

            self.record("删除环境（含激活自动取消）", True)
        except Exception as e:
            self.record("删除环境（含激活自动取消）", False, str(e))

    # ==================== 清理与报告 ====================

    def cleanup(self):
        """清理测试产生的数据"""
        print("\n🧹 清理测试数据...")
        try:
            self.client.set_active_environment()
            self.client.set_global_variables([])
            for env_id in self.created_env_ids:
                try:
                    self.client.delete_environment(env_id)
                except Exception:
                    pass
            self.client.close_tab()
        except Exception as e:
            print(f"⚠️  清理时出现异常: {e}")

    def print_report(self):
        print("\n" + "=" * 60)
        print("测试报告")
        print("=" * 60)
        passed = sum(1 for _, p, _ in self.results if p)
        total = len(self.results)
        print(f"总计: {passed}/{total} 通过")
        if passed < total:
            print("\n失败用例:")
            for name, p, error in self.results:
                if not p:
                    print(f"  ❌ {name}: {error}")
        print("=" * 60)
        return passed == total


def main():
    parser = argparse.ArgumentParser(description="环境变量系统 UI 自动化验收测试")
    parser.add_argument("--port", type=int, default=None,
                        help="Hopp 测试服务器端口（默认自动发现）")
    args = parser.parse_args()

    test = EnvironmentVariablesTest(port=args.port)
    success = test.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
