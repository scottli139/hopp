#!/usr/bin/env python3
"""
Collection 级联删除功能 UI 自动化测试

测试场景:
1. 创建父 Collection A
2. 在 A 下创建子 Collection B
3. 在 B 下创建子 Collection C
4. 删除 Collection A
5. 验证: B 和 C 也被级联删除，不会保留在根级别

使用方法:
    1. 以测试模式启动应用: ./hopp.app/Contents/MacOS/hopp --test-mode
    2. 从日志获取端口
    3. 运行测试: python3 test_collection_cascade_delete.py --port <PORT>
"""

import argparse
import sys
import time
from pathlib import Path

# 添加当前目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def test_collection_cascade_delete(client: HoppTestClient):
    """测试 Collection 级联删除功能"""
    print("\n" + "=" * 70)
    print("🧪 Collection 级联删除功能 UI 自动化测试")
    print("=" * 70 + "\n")

    # 步骤 1: 获取初始集合树状态
    print("📋 步骤 1: 获取初始集合树状态")
    initial_tree = client.get_collection_tree()
    initial_count = initial_tree.get('collection_count', 0)
    print(f"   初始根集合数量: {initial_count}\n")

    # 步骤 2: 创建父 Collection A
    print("📁 步骤 2: 创建父 Collection A")
    collection_a = client.create_collection("Collection A")
    collection_a_id = collection_a.get('collection_id')
    time.sleep(0.5)

    # 步骤 3: 在 A 下创建子 Collection B
    print("📁 步骤 3: 在 A 下创建子 Collection B")
    collection_b = client.create_collection("Collection B", parent_id=collection_a_id)
    collection_b_id = collection_b.get('collection_id')
    time.sleep(0.5)

    # 步骤 4: 在 B 下创建子 Collection C
    print("📁 步骤 4: 在 B 下创建子 Collection C")
    collection_c = client.create_collection("Collection C", parent_id=collection_b_id)
    collection_c_id = collection_c.get('collection_id')
    time.sleep(0.5)

    # 步骤 5: 验证创建后的集合树结构
    print("\n🌲 步骤 5: 验证创建后的集合树结构")
    tree_before = client.get_collection_tree()
    print(f"   当前根集合数量: {tree_before.get('collection_count', 0)}")

    # 截图记录创建后的状态
    print("\n📸 截图: 创建集合后的状态")
    client.capture_screenshot("collection_cascade_before_delete")
    time.sleep(1)

    # 步骤 6: 删除父 Collection A（应该级联删除 B 和 C）
    print("\n🗑️  步骤 6: 删除父 Collection A（应该级联删除 B 和 C）")
    delete_result = client.delete_collection(collection_a_id)
    time.sleep(0.5)

    # 步骤 7: 验证删除后的集合树结构
    print("\n🌲 步骤 7: 验证删除后的集合树结构")
    tree_after = client.get_collection_tree()
    final_count = tree_after.get('collection_count', 0)
    print(f"   删除后根集合数量: {final_count}")

    # 截图记录删除后的状态
    print("\n📸 截图: 删除集合后的状态")
    client.capture_screenshot("collection_cascade_after_delete")
    time.sleep(1)

    # 步骤 8: 验证结果
    print("\n" + "=" * 70)
    print("📊 测试结果验证")
    print("=" * 70)

    all_passed = True

    # 验证 1: 子集合已被删除
    if delete_result.get('children_deleted', False):
        print("✅ 验证 1: 子集合已正确级联删除")
    else:
        print("❌ 验证 1: 子集合未被级联删除")
        all_passed = False

    # 验证 2: 根集合数量恢复
    if final_count == initial_count:
        print(f"✅ 验证 2: 根集合数量正确 ({initial_count} -> {final_count})")
    else:
        print(f"❌ 验证 2: 根集合数量不正确 (期望 {initial_count}, 实际 {final_count})")
        all_passed = False

    # 验证 3: 删除的集合数量正确
    expected_deleted = 3  # A, B, C
    actual_deleted = delete_result.get('total_children', 0) + 1  # +1 for the parent
    if actual_deleted == expected_deleted:
        print(f"✅ 验证 3: 删除的集合总数正确 ({actual_deleted})")
    else:
        print(f"❌ 验证 3: 删除的集合总数不正确 (期望 {expected_deleted}, 实际 {actual_deleted})")
        all_passed = False

    # 验证 4: 集合树中不包含已删除的集合
    def find_collection_in_tree(tree, collection_id):
        """在集合树中查找指定 ID 的集合"""
        for node in tree:
            if node.get('id') == collection_id:
                return True
            children = node.get('children', [])
            if find_collection_in_tree(children, collection_id):
                return True
        return False

    tree_data = tree_after.get('tree', [])
    a_found = find_collection_in_tree(tree_data, collection_a_id)
    b_found = find_collection_in_tree(tree_data, collection_b_id)
    c_found = find_collection_in_tree(tree_data, collection_c_id)

    if not a_found and not b_found and not c_found:
        print("✅ 验证 4: 所有已删除集合都不在集合树中")
    else:
        print(f"❌ 验证 4: 部分已删除集合仍在集合树中 (A:{a_found}, B:{b_found}, C:{c_found})")
        all_passed = False

    # 总结
    print("\n" + "=" * 70)
    if all_passed:
        print("✅ 所有测试通过！Collection 级联删除功能正常工作")
    else:
        print("❌ 部分测试失败！请检查 Collection 级联删除功能")
    print("=" * 70 + "\n")

    return all_passed


def main():
    parser = argparse.ArgumentParser(
        description="Collection 级联删除功能 UI 自动化测试",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python3 %(prog)s --port 5000
  python3 %(prog)s --port 5000 --reset  # 先重置数据库再测试
        """
    )
    parser.add_argument("--port", type=int, required=True, help="测试服务器端口")
    parser.add_argument("--reset", action="store_true", help="测试前重置数据库")

    args = parser.parse_args()

    try:
        client = HoppTestClient(port=args.port)

        # 测试连接
        print("🔌 测试连接...")
        client.ping()

        # 可选: 重置数据库
        if args.reset:
            print("\n🗑️  重置数据库...")
            client.reset_database()
            time.sleep(1)

        # 执行测试
        success = test_collection_cascade_delete(client)

        sys.exit(0 if success else 1)

    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
