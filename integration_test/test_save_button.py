#!/usr/bin/env python3
"""
测试保存按钮的 UI 测试
"""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def test_save_button():
    """测试保存按钮功能"""
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=None)
    args = parser.parse_args()
    
    client = HoppTestClient(port=args.port)
    
    print("\n" + "="*60)
    print("🧪 保存按钮功能测试")
    print("="*60 + "\n")
    
    # 1. 测试连接
    print("1. 测试连接...")
    client.ping()
    print("✅ 连接成功\n")
    
    # 2. 创建新请求
    print("2. 创建新请求...")
    result = client.create_request()
    request_id = result.get('request_id')
    print(f"✅ 请求创建成功: {request_id}\n")
    
    # 3. 检查初始 UI 状态
    print("3. 检查初始 UI 状态...")
    ui_info = client.get_ui_info()
    print(f"   当前请求: {ui_info.get('active_request_method')} {ui_info.get('active_request_url')}")
    print(f"   是否 dirty: {ui_info.get('tabs', [{}])[0].get('is_dirty')}")
    print()
    
    # 4. 修改请求内容
    print("4. 修改请求内容...")
    client.set_url("https://httpbin.org/post")
    time.sleep(0.3)
    client.set_method("POST")
    time.sleep(0.3)
    print("✅ URL 和方法已修改\n")
    
    # 5. 检查修改后的状态
    print("5. 检查修改后的状态...")
    ui_info = client.get_ui_info()
    is_dirty = ui_info.get('tabs', [{}])[0].get('is_dirty')
    print(f"   是否 dirty: {is_dirty}")
    print()
    
    # 6. 尝试保存
    print("6. 尝试保存请求...")
    try:
        result = client.save_request()
        print(f"✅ 保存结果: {result}\n")
    except Exception as e:
        print(f"❌ 保存失败: {e}\n")
    
    # 7. 检查保存后的状态
    print("7. 检查保存后的状态...")
    time.sleep(0.5)
    ui_info = client.get_ui_info()
    is_dirty_after = ui_info.get('tabs', [{}])[0].get('is_dirty')
    print(f"   是否 dirty: {is_dirty_after}")
    print(f"   Tab 列表:")
    for tab in ui_info.get('tabs', []):
        dirty_mark = " ●" if tab.get('is_dirty') else ""
        print(f"     [{tab.get('method')}] {tab.get('name')}{dirty_mark}")
    print()
    
    # 8. 再试一次保存（应该提示无修改）
    print("8. 再次保存（应该提示无修改）...")
    try:
        result = client.save_request()
        print(f"✅ 第二次保存结果: {result}\n")
    except Exception as e:
        print(f"❌ 第二次保存失败: {e}\n")
    
    print("="*60)
    print("测试完成")
    print("="*60)


if __name__ == "__main__":
    test_save_button()
