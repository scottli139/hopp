#!/usr/bin/env python3
"""
Hopp 数据库迁移测试脚本

测试数据库版本控制和向后兼容性：
1. 旧数据兼容启动
2. 自动迁移验证
3. 新字段默认值验证
4. 新数据正常存储

使用方法:
    # 1. 以测试模式启动 Hopp 应用
    ./hopp.app/Contents/MacOS/hopp --test-mode

    # 2. 运行测试脚本
    python3 test_database_migration.py [--port PORT]
"""

import argparse
import sys
import subprocess
from pathlib import Path

# 导入 test_client
try:
    from test_client import HoppTestClient
except ImportError:
    sys.path.insert(0, str(Path(__file__).parent))
    from test_client import HoppTestClient


def test_basic_connection(client):
    """测试 1: 基础连接"""
    print("\n" + "="*60)
    print("测试 1: 基础连接")
    print("="*60)
    
    result = client.ping()
    print(f"✅ 连接成功: {result}")
    return True


def test_old_data_migration(client):
    """测试 2: 旧数据兼容启动和自动迁移"""
    print("\n" + "="*60)
    print("测试 2: 旧数据兼容启动和自动迁移")
    print("="*60)
    
    # 重置数据库
    print("\n步骤 1: 重置数据库")
    client.reset_database()
    
    # 模拟旧版本数据
    print("\n步骤 2: 模拟旧版本数据 (v1)")
    client.simulate_old_data(version=1)
    
    # 验证迁移结果（注意：实际迁移在应用启动时触发，这里验证字段默认值）
    print("\n步骤 3: 验证迁移结果")
    result = client.verify_migration(expected_version=1)  # 当前版本应为 1
    
    # 关键验证：旧数据能正常读取，且新增字段有正确默认值
    if not result.get('all_have_defaults'):
        print("❌ 不是所有请求都有正确的默认值")
        return False
    
    print("✅ 旧数据已成功读取，所有新增字段有正确默认值")
    print("   (注：完整迁移在应用启动时触发)")
    return True


def test_field_defaults(client):
    """测试 3: 字段默认值验证"""
    print("\n" + "="*60)
    print("测试 3: 字段默认值验证")
    print("="*60)
    
    # 创建新请求
    print("\n步骤 1: 创建新请求")
    result = client.create_request()
    request_id = result.get('request_id')
    
    # 获取请求配置
    print("\n步骤 2: 获取请求配置")
    settings = client.get_request_settings()
    
    # 验证默认值
    print("\n步骤 3: 验证默认值")
    defaults_correct = True
    
    expected_defaults = {
        'validate_certificates': True,
        'follow_redirects': True,
        'max_redirects': 10,
    }
    
    for field, expected in expected_defaults.items():
        actual = settings.get(field)
        if actual == expected:
            print(f"  ✅ {field}: {actual} (预期: {expected})")
        else:
            print(f"  ❌ {field}: {actual} (预期: {expected})")
            defaults_correct = False
    
    if defaults_correct:
        print("\n✅ 所有字段默认值正确")
        return True
    else:
        print("\n❌ 部分字段默认值不正确")
        return False


def test_new_data_storage(client):
    """测试 4: 新数据正常存储和读取"""
    print("\n" + "="*60)
    print("测试 4: 新数据正常存储和读取")
    print("="*60)
    
    # 创建新请求
    print("\n步骤 1: 创建新请求")
    result = client.create_request()
    request_id = result.get('request_id')
    
    # 设置非默认配置
    print("\n步骤 2: 设置非默认配置")
    client.set_request_settings(
        validate_certificates=False,
        follow_redirects=False,
        max_redirects=5,
    )
    
    # 获取配置验证
    print("\n步骤 3: 验证配置已保存")
    settings = client.get_request_settings()
    
    checks = [
        ('validate_certificates', False),
        ('follow_redirects', False),
        ('max_redirects', 5),
    ]
    
    all_correct = True
    for field, expected in checks:
        actual = settings.get(field)
        if actual == expected:
            print(f"  ✅ {field}: {actual}")
        else:
            print(f"  ❌ {field}: {actual} (预期: {expected})")
            all_correct = False
    
    if all_correct:
        print("\n✅ 新数据存储和读取正常")
        return True
    else:
        print("\n❌ 新数据存储或读取异常")
        return False


def test_settings_change(client):
    """测试 5: 配置变更测试"""
    print("\n" + "="*60)
    print("测试 5: 配置变更测试")
    print("="*60)
    
    # 创建新请求
    print("\n步骤 1: 创建新请求")
    client.create_request()
    
    # 测试 followRedirects 开关
    print("\n步骤 2: 测试 followRedirects 开关")
    
    # 关闭
    client.set_request_settings(follow_redirects=False)
    settings = client.get_request_settings()
    if settings.get('follow_redirects') == False:
        print("  ✅ followRedirects 已关闭")
    else:
        print("  ❌ followRedirects 关闭失败")
        return False
    
    # 开启
    client.set_request_settings(follow_redirects=True)
    settings = client.get_request_settings()
    if settings.get('follow_redirects') == True:
        print("  ✅ followRedirects 已开启")
    else:
        print("  ❌ followRedirects 开启失败")
        return False
    
    # 测试 maxRedirects 调整
    print("\n步骤 3: 测试 maxRedirects 调整")
    
    for value in [0, 5, 10, 20]:
        client.set_request_settings(max_redirects=value)
        settings = client.get_request_settings()
        if settings.get('max_redirects') == value:
            print(f"  ✅ maxRedirects 设置为 {value}")
        else:
            print(f"  ❌ maxRedirects 设置失败 (实际: {settings.get('max_redirects')})")
            return False
    
    print("\n✅ 配置变更测试通过")
    return True


def capture_screenshot(name):
    """捕获屏幕截图"""
    try:
        screenshot_path = f"~/Desktop/{name}.png"
        subprocess.run(
            ["screencapture", "-x", Path(screenshot_path).expanduser()],
            check=True,
        )
        print(f"📸 截图已保存: {screenshot_path}")
    except Exception as e:
        print(f"⚠️  截图失败: {e}")


def run_all_tests(port=None):
    """运行所有测试"""
    print("\n" + "="*60)
    print("🧪 Hopp 数据库迁移测试")
    print("="*60)
    
    client = HoppTestClient(port)
    
    tests = [
        ("基础连接", test_basic_connection),
        ("旧数据兼容启动", test_old_data_migration),
        ("字段默认值验证", test_field_defaults),
        ("新数据存储", test_new_data_storage),
        ("配置变更测试", test_settings_change),
    ]
    
    results = []
    
    for name, test_func in tests:
        try:
            success = test_func(client)
            results.append((name, success))
        except Exception as e:
            print(f"\n❌ 测试 '{name}' 失败: {e}")
            results.append((name, False))
    
    # 测试总结
    print("\n" + "="*60)
    print("📊 测试结果总结")
    print("="*60)
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    
    for name, success in results:
        status = "✅ 通过" if success else "❌ 失败"
        print(f"  {status}: {name}")
    
    print(f"\n总计: {passed}/{total} 通过")
    
    if passed == total:
        print("\n🎉 所有测试通过!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} 个测试失败")
        return 1


def main():
    parser = argparse.ArgumentParser(
        description="Hopp 数据库迁移测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
测试流程:
  1. 基础连接测试
  2. 旧数据兼容启动和自动迁移
  3. 字段默认值验证
  4. 新数据正常存储和读取
  5. 配置变更测试

使用方法:
  # 1. 先以测试模式启动 Hopp
  ./hopp.app/Contents/MacOS/hopp --test-mode

  # 2. 运行测试
  python3 test_database_migration.py

  # 或指定端口
  python3 test_database_migration.py --port 54321
        """,
    )
    
    parser.add_argument(
        "--port",
        type=int,
        help="测试服务器端口（可选，默认从日志读取）",
    )
    
    args = parser.parse_args()
    
    try:
        exit_code = run_all_tests(args.port)
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
