#!/usr/bin/env python3
"""
测试 Postman 导入时 Raw Content Type 映射修复

验证:
1. Postman Collection 中 body.options.raw.language = "json" 的请求
2. 导入后 rawContentType 应正确映射为 "json" 而非 "text"
"""

import sys
import time
import argparse
from pathlib import Path

# 添加当前目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


def test_raw_content_type_mapping(port=None):
    """测试 Raw Content Type 映射"""
    
    print("=" * 70)
    print("Postman 导入 - Raw Content Type 映射测试")
    print("=" * 70)
    
    # 创建客户端
    client = HoppTestClient(port=port)
    
    # 从日志获取端口（如果没有指定）
    if port is None:
        print("\n1. 从日志获取测试服务器端口...")
        if not client._get_port_from_log():
            print("❌ 无法获取端口，请确保应用以 --test-mode 启动")
            return False
        print(f"✅ 使用端口: {client.port}")
    else:
        print(f"\n1. 使用指定端口: {port}")
    
    # 测试连接
    print("\n2. 测试连接...")
    if not client.ping():
        print("❌ 连接失败")
        return False
    print("✅ 连接成功")
    
    # 获取测试文件路径
    test_file = Path(__file__).parent / "fixtures" / "test_raw_content_type.json"
    if not test_file.exists():
        print(f"❌ 测试文件不存在: {test_file}")
        return False
    
    # 导入测试 Collection
    print(f"\n3. 导入测试 Collection: {test_file}")
    result = client.import_collection(str(test_file))
    if not result.get('imported'):
        print("❌ 导入失败")
        return False
    print(f"✅ 导入成功，请求数: {result.get('request_count')}")
    
    # 等待导入完成
    time.sleep(1)
    
    # 测试 1: JSON Request (有 language: json)
    print("\n4. 测试 1: JSON Request (body.options.raw.language = json)")
    info = client.get_imported_request_info(collection_index=0, request_index=0)
    if info.get('raw_content_type') != 'json':
        print(f"❌ 失败: raw_content_type = {info.get('raw_content_type')}, 期望: json")
        print(f"   Body 类型: {info.get('body_type')}")
        print(f"   Body 内容: {info.get('body')[:50]}...")
        return False
    print(f"✅ 通过: raw_content_type = {info.get('raw_content_type')}")
    print(f"   请求名称: {info.get('request_name')}")
    print(f"   Body 类型: {info.get('body_type')}")
    
    # 测试 2: XML Request (有 language: xml)
    print("\n5. 测试 2: XML Request (body.options.raw.language = xml)")
    info = client.get_imported_request_info(collection_index=0, request_index=1)
    if info.get('raw_content_type') != 'xml':
        print(f"❌ 失败: raw_content_type = {info.get('raw_content_type')}, 期望: xml")
        return False
    print(f"✅ 通过: raw_content_type = {info.get('raw_content_type')}")
    print(f"   请求名称: {info.get('request_name')}")
    
    # 测试 3: Text Request (无 language，有 Content-Type: text/plain)
    print("\n6. 测试 3: Text Request (无 language，从 Content-Type 推断)")
    info = client.get_imported_request_info(collection_index=0, request_index=2)
    if info.get('raw_content_type') != 'text':
        print(f"❌ 失败: raw_content_type = {info.get('raw_content_type')}, 期望: text")
        return False
    print(f"✅ 通过: raw_content_type = {info.get('raw_content_type')}")
    print(f"   请求名称: {info.get('request_name')}")
    
    # 测试 4: JSON Request (无 language，只有 Content-Type: application/json)
    print("\n7. 测试 4: JSON Request (无 language，从 Content-Type: application/json 推断)")
    info = client.get_imported_request_info(collection_index=0, request_index=3)
    if info.get('raw_content_type') != 'json':
        print(f"❌ 失败: raw_content_type = {info.get('raw_content_type')}, 期望: json")
        print(f"   Headers: {info.get('headers')}")
        return False
    print(f"✅ 通过: raw_content_type = {info.get('raw_content_type')}")
    print(f"   请求名称: {info.get('request_name')}")
    print(f"   从 Content-Type header 正确推断")
    
    print("\n" + "=" * 70)
    print("所有测试通过! ✅")
    print("=" * 70)
    return True


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="测试 Raw Content Type 映射")
    parser.add_argument("--port", type=int, help="测试服务器端口")
    args = parser.parse_args()
    
    success = test_raw_content_type_mapping(port=args.port)
    
    if success:
        print("\n🎉 所有测试通过!")
        sys.exit(0)
    else:
        print("\n❌ 测试失败!")
        sys.exit(1)
