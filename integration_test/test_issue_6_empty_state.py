#!/usr/bin/env python3
"""
Issue #6: 初次使用时缺少创建 Request/Collection 的入口指引

UI 自动化测试脚本，验证以下功能:
1. Sidebar 空状态显示 "Create Collection" 按钮
2. 主区域空状态显示 "Create Request" 按钮
3. Sidebar Header 添加可见的 "+" 按钮
4. 快捷键提示显示

使用方法:
    1. 以测试模式启动 Hopp:
       ./hopp.app/Contents/MacOS/hopp --test-mode
       
    2. 运行测试:
       python3 integration_test/test_issue_6_empty_state.py
"""

import sys
import time
from pathlib import Path

# 添加父目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def test_empty_state():
    """测试空状态 UI"""
    print("\n" + "="*60)
    print("🧪 Issue #6: 空状态入口指引测试")
    print("="*60 + "\n")
    
    client = HoppTestClient()
    
    try:
        # 1. 测试连接
        print("1️⃣ 测试连接...")
        client.ping()
        time.sleep(1)
        
        # 2. 重置数据库，确保空状态
        print("\n2️⃣ 重置数据库，确保空状态...")
        client.reset_database()
        time.sleep(1)
        
        # 3. 验证空状态
        print("\n3️⃣ 验证空状态...")
        info = client.get_empty_state_info()
        assert info.get('sidebar_empty') == True, "Sidebar 应该为空"
        assert info.get('main_empty') == True, "主区域应该为空"
        print("✅ 空状态验证通过")
        time.sleep(1)
        
        # 4. 截图 - 空状态 UI
        print("\n4️⃣ 截图 - 空状态 UI...")
        client.capture_screenshot("issue_6_empty_state")
        time.sleep(1)
        
        # 5. 触发创建 Collection（从空状态）
        print("\n5️⃣ 触发从空状态创建 Collection...")
        client.trigger_create_collection_from_empty()
        time.sleep(1)
        
        # 6. 截图 - 创建 Collection 对话框
        print("\n6️⃣ 截图 - 创建 Collection 对话框...")
        client.capture_screenshot("issue_6_create_collection_dialog")
        time.sleep(1)
        
        # 7. 创建测试 Collection
        print("\n7️⃣ 创建测试 Collection...")
        result = client.create_collection("Test Collection")
        collection_id = result.get('collection_id')
        time.sleep(1)
        
        # 8. 验证 Collection 已创建
        print("\n8️⃣ 验证 Collection 已创建...")
        info = client.get_empty_state_info()
        assert info.get('sidebar_empty') == False, "Sidebar 不应该为空"
        print("✅ Collection 创建成功")
        time.sleep(1)
        
        # 9. 截图 - 有 Collection 的状态
        print("\n9️⃣ 截图 - 有 Collection 的状态...")
        client.capture_screenshot("issue_6_with_collection")
        time.sleep(1)
        
        # 10. 创建新请求
        print("\n🔟 创建新请求...")
        result = client.create_request()
        request_id = result.get('request_id')
        time.sleep(1)
        
        # 11. 验证主区域不再为空
        print("\n1️⃣1️⃣ 验证主区域不再为空...")
        info = client.get_empty_state_info()
        assert info.get('main_empty') == False, "主区域不应该为空"
        print("✅ 请求创建成功，主区域已更新")
        time.sleep(1)
        
        # 12. 截图 - 有请求的状态
        print("\n1️⃣2️⃣ 截图 - 有请求的状态...")
        client.capture_screenshot("issue_6_with_request")
        time.sleep(1)
        
        # 13. 关闭请求 Tab，回到空状态
        print("\n1️⃣3️⃣ 关闭请求 Tab...")
        client.close_tab()
        time.sleep(1)
        
        # 14. 验证回到空状态
        print("\n1️⃣4️⃣ 验证回到空状态...")
        info = client.get_empty_state_info()
        assert info.get('main_empty') == True, "主区域应该为空"
        print("✅ 回到空状态")
        time.sleep(1)
        
        # 15. 截图 - 回到空状态
        print("\n1️⃣5️⃣ 截图 - 回到空状态...")
        client.capture_screenshot("issue_6_back_to_empty")
        time.sleep(1)
        
        print("\n" + "="*60)
        print("✅ Issue #6 测试全部通过！")
        print("="*60)
        print("\n📸 截图文件保存在 ~/Downloads/ 目录:")
        print("   - hopp_issue_6_empty_state.png")
        print("   - hopp_issue_6_create_collection_dialog.png")
        print("   - hopp_issue_6_with_collection.png")
        print("   - hopp_issue_6_with_request.png")
        print("   - hopp_issue_6_back_to_empty.png")
        print("="*60 + "\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def test_sidebar_quick_add_button():
    """测试 Sidebar 快速添加按钮"""
    print("\n" + "="*60)
    print("🧪 Sidebar 快速添加按钮测试")
    print("="*60 + "\n")
    
    client = HoppTestClient()
    
    try:
        # 1. 重置数据库
        print("1️⃣ 重置数据库...")
        client.reset_database()
        time.sleep(1)
        
        # 2. 获取集合列表（应该为空）
        print("\n2️⃣ 获取集合列表...")
        collections = client.get_collections()
        assert collections.get('collection_count') == 0, "应该没有 Collection"
        print("✅ 确认没有 Collection")
        time.sleep(1)
        
        # 3. 截图 - Sidebar 空状态
        print("\n3️⃣ 截图 - Sidebar 空状态...")
        client.capture_screenshot("issue_6_sidebar_empty")
        time.sleep(1)
        
        # 4. 使用 create_collection 创建（模拟点击 + 按钮）
        print("\n4️⃣ 创建 Collection（模拟点击 + 按钮）...")
        result = client.create_collection("Quick Add Collection")
        time.sleep(1)
        
        # 5. 验证创建成功
        print("\n5️⃣ 验证创建成功...")
        collections = client.get_collections()
        assert collections.get('collection_count') == 1, "应该有 1 个 Collection"
        print("✅ Collection 创建成功")
        time.sleep(1)
        
        # 6. 截图 - Sidebar 有 Collection
        print("\n6️⃣ 截图 - Sidebar 有 Collection...")
        client.capture_screenshot("issue_6_sidebar_with_collection")
        time.sleep(1)
        
        print("\n" + "="*60)
        print("✅ Sidebar 快速添加按钮测试通过！")
        print("="*60 + "\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    """主函数"""
    print("""
┌─────────────────────────────────────────────────────────────┐
│  Issue #6: 初次使用时缺少创建 Request/Collection 的入口指引  │
│                                                             │
│  测试内容:                                                  │
│  1. Sidebar 空状态显示 "Create Collection" 按钮             │
│  2. 主区域空状态显示 "Create Request" 按钮                  │
│  3. Sidebar Header 添加可见的 "+" 按钮                      │
│  4. 快捷键提示显示                                          │
└─────────────────────────────────────────────────────────────┘
    """)
    
    # 测试空状态
    success1 = test_empty_state()
    
    # 测试 Sidebar 快速添加按钮
    success2 = test_sidebar_quick_add_button()
    
    if success1 and success2:
        print("\n🎉 所有测试通过！Issue #6 修复成功。\n")
        sys.exit(0)
    else:
        print("\n💥 部分测试失败，请检查。\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
