#!/usr/bin/env python3
"""
Postman 导入/导出功能 UI 测试

测试内容:
1. 基础连接测试
2. 导入简单 Collection
3. 导入复杂 Collection (嵌套文件夹)
4. 获取集合列表验证
5. 截图验证 UI

使用方法:
    python test_postman_import.py [--port PORT]
"""

import argparse
import sys
import time
from pathlib import Path

from test_client import HoppTestClient


def test_basic_connection(client):
    """测试基础连接"""
    print("\n" + "="*60)
    print("测试 1: 基础连接")
    print("="*60)
    
    result = client.ping()
    assert result.get('status') == 'ok', "连接失败"
    print("✅ 连接成功")
    return True


def test_import_simple_collection(client):
    """测试导入简单 Collection"""
    print("\n" + "="*60)
    print("测试 2: 导入简单 Collection")
    print("="*60)
    
    # 使用测试文件
    test_file = "/tmp/test_simple_collection.json"
    
    # 确保文件存在
    if not Path(test_file).exists():
        print(f"❌ 测试文件不存在: {test_file}")
        return False
    
    # 导入集合
    result = client.import_collection(test_file)
    
    # 等待导入完成
    time.sleep(1)
    
    if result.get('imported'):
        print(f"✅ 导入成功")
        print(f"   请求数量: {result.get('request_count')}")
        if result.get('renamed'):
            print(f"   重命名为: {result.get('new_name')}")
        return True
    elif result.get('conflict'):
        print(f"⚠️  集合已存在，跳过")
        return True
    else:
        print(f"❌ 导入失败: {result}")
        return False


def test_import_complex_collection(client):
    """测试导入复杂 Collection"""
    print("\n" + "="*60)
    print("测试 3: 导入复杂 Collection (嵌套文件夹)")
    print("="*60)
    
    test_file = "/tmp/test_complex_collection.json"
    
    if not Path(test_file).exists():
        print(f"❌ 测试文件不存在: {test_file}")
        return False
    
    result = client.import_collection(test_file)
    time.sleep(1)
    
    if result.get('imported'):
        print(f"✅ 导入成功")
        print(f"   请求数量: {result.get('request_count')}")
        return True
    elif result.get('conflict'):
        print(f"⚠️  集合已存在，跳过")
        return True
    else:
        print(f"❌ 导入失败: {result}")
        return False


def test_get_collections(client):
    """测试获取集合列表"""
    print("\n" + "="*60)
    print("测试 4: 获取集合列表")
    print("="*60)
    
    result = client.get_collections()
    
    collection_count = result.get('collection_count', 0)
    print(f"✅ 找到 {collection_count} 个集合")
    
    for collection in result.get('collections', []):
        print(f"   - {collection.get('name')}: {collection.get('request_count')} 请求")
    
    # 验证至少有一个集合
    assert collection_count > 0, "没有找到任何集合"
    return True


def test_trigger_import_dialog(client):
    """测试触发导入对话框"""
    print("\n" + "="*60)
    print("测试 5: 触发导入对话框")
    print("="*60)
    
    result = client.trigger_import_dialog()
    assert result.get('triggered'), "触发失败"
    
    print("✅ 导入对话框已触发")
    time.sleep(1)
    
    # 截图
    client.capture_screenshot("import_dialog")
    return True


def test_trigger_export_dialog(client):
    """测试触发导出对话框"""
    print("\n" + "="*60)
    print("测试 6: 触发导出对话框")
    print("="*60)
    
    result = client.trigger_export_dialog()
    assert result.get('triggered'), "触发失败"
    
    print("✅ 导出对话框已触发")
    time.sleep(1)
    
    # 截图
    client.capture_screenshot("export_dialog")
    return True


def run_all_tests(client):
    """运行所有测试"""
    print("\n" + "="*60)
    print("🧪 Postman 导入/导出功能 UI 测试")
    print("="*60)
    
    tests = [
        ("基础连接", test_basic_connection),
        ("导入简单 Collection", test_import_simple_collection),
        ("导入复杂 Collection", test_import_complex_collection),
        ("获取集合列表", test_get_collections),
        ("触发导入对话框", test_trigger_import_dialog),
        ("触发导出对话框", test_trigger_export_dialog),
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        try:
            if test_func(client):
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ 测试失败: {e}")
            failed += 1
    
    print("\n" + "="*60)
    print("测试结果")
    print("="*60)
    print(f"总计: {passed + failed} 个测试")
    print(f"通过: {passed} 个")
    print(f"失败: {failed} 个")
    
    return failed == 0


def main():
    parser = argparse.ArgumentParser(
        description="Postman 导入/导出功能 UI 测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python test_postman_import.py              # 运行所有测试
  python test_postman_import.py --port 8080  # 指定端口
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口")
    
    args = parser.parse_args()
    
    client = HoppTestClient(port=args.port)
    
    try:
        success = run_all_tests(client)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ 测试执行失败: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
