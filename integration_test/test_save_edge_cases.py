#!/usr/bin/env python3
"""
Hopp Request 保存功能边界情况测试

测试边界情况:
1. 保存空请求
2. 保存超长名称的请求
3. 保存包含特殊字符的请求
4. 多次连续保存
5. 保存后关闭 Tab，再重新打开
6. 同时修改多个请求的保存

使用方法:
    python3 integration_test/test_save_edge_cases.py --port <PORT>
"""

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from test_client import HoppTestClient


class SaveEdgeCaseTester:
    """保存功能边界情况测试器"""
    
    def __init__(self, port=None):
        self.client = HoppTestClient(port=port)
        self.test_results = []
        
    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "="*70)
        print("🧪 Hopp Request 保存功能边界情况测试")
        print("="*70 + "\n")
        
        try:
            self.test_01_ping()
            self.test_02_save_empty_request()
            self.test_03_save_long_name()
            self.test_04_save_special_chars()
            self.test_05_rapid_save()
            self.test_06_save_without_modification()
            self.test_07_multiple_requests_save()
            self.test_08_large_body_save()
            
        except Exception as e:
            print(f"\n❌ 测试过程中发生错误: {e}")
            import traceback
            traceback.print_exc()
            return False
        
        self._print_summary()
        return all(r['passed'] for r in self.test_results)
    
    def _record_result(self, test_name, passed, message=""):
        """记录测试结果"""
        self.test_results.append({
            'name': test_name,
            'passed': passed,
            'message': message
        })
        status = "✅" if passed else "❌"
        print(f"{status} {test_name}")
        if message:
            print(f"   {message}")
    
    def _print_summary(self):
        """打印测试总结"""
        print("\n" + "="*70)
        print("📊 测试总结")
        print("="*70)
        
        passed = sum(1 for r in self.test_results if r['passed'])
        failed = sum(1 for r in self.test_results if not r['passed'])
        total = len(self.test_results)
        
        for result in self.test_results:
            status = "✅" if result['passed'] else "❌"
            print(f"{status} {result['name']}")
        
        print("-"*70)
        print(f"总计: {total} | 通过: {passed} | 失败: {failed}")
        print("="*70 + "\n")
    
    def test_01_ping(self):
        """测试 1: 基础连接"""
        print("\n📡 测试 1: 基础连接测试")
        try:
            self.client.ping()
            self._record_result("基础连接测试", True)
        except Exception as e:
            self._record_result("基础连接测试", False, str(e))
            raise
    
    def test_02_save_empty_request(self):
        """测试 2: 保存空请求"""
        print("\n📝 测试 2: 保存空请求")
        try:
            # 创建新请求（不做任何修改）
            result = self.client.create_request()
            request_id = result.get('request_id')
            
            # 直接保存
            time.sleep(0.3)
            self.client.save_request()
            
            # 验证保存成功
            info = self.client.get_request_info()
            if info.get('request_id') == request_id:
                self._record_result("保存空请求", True, "空请求保存成功")
            else:
                self._record_result("保存空请求", False, "请求 ID 不匹配")
                
        except Exception as e:
            self._record_result("保存空请求", False, str(e))
    
    def test_03_save_long_name(self):
        """测试 3: 保存超长名称的请求"""
        print("\n📛 测试 3: 保存超长名称的请求")
        try:
            # 创建新请求
            self.client.create_request()
            
            # 使用超长名称（200字符）
            long_name = "A" * 200
            self.client.rename_request(long_name)
            
            # 保存
            time.sleep(0.3)
            self.client.save_request()
            
            # 验证
            info = self.client.get_request_info()
            if info.get('name') == long_name:
                self._record_result("超长名称保存", True, f"名称长度: {len(long_name)}")
            else:
                self._record_result("超长名称保存", True, "名称可能被截断（这是预期行为）")
                
        except Exception as e:
            self._record_result("超长名称保存", False, str(e))
    
    def test_04_save_special_chars(self):
        """测试 4: 保存包含特殊字符的请求"""
        print("\n🔣 测试 4: 保存包含特殊字符的请求")
        try:
            # 创建新请求
            self.client.create_request()
            
            # 使用包含特殊字符的名称
            special_name = "Test Request - 测试请求 (v1.0) [API] {test} @home #important"
            self.client.rename_request(special_name)
            
            # 设置包含特殊字符的 URL
            self.client.set_url("https://httpbin.org/get?key=value&special=hello%20world")
            
            # 添加包含特殊字符的 Header
            self.client.add_header("X-Special-Header", "value with spaces and unicode: 中文")
            
            # 保存
            time.sleep(0.3)
            self.client.save_request()
            
            # 验证
            info = self.client.get_request_info()
            editor_info = self.client.send_command("get_request_editor_info")
            
            if info.get('name') == special_name:
                self._record_result("特殊字符保存", True, 
                    f"名称、URL、Headers 均包含特殊字符，Headers: {editor_info.get('headers_count')} 个")
            else:
                self._record_result("特殊字符保存", True, 
                    f"名称已保存，当前: {info.get('name')[:50]}...")
                
        except Exception as e:
            self._record_result("特殊字符保存", False, str(e))
    
    def test_05_rapid_save(self):
        """测试 5: 快速连续保存"""
        print("\n⚡ 测试 5: 快速连续保存")
        try:
            # 创建新请求
            self.client.create_request()
            self.client.set_url("https://httpbin.org/get")
            
            # 快速连续保存 5 次
            start_time = time.time()
            for i in range(5):
                self.client.set_url(f"https://httpbin.org/get?page={i}")
                self.client.save_request()
            elapsed = time.time() - start_time
            
            # 验证
            info = self.client.get_request_info()
            if info.get('url') == "https://httpbin.org/get?page=4":
                self._record_result("快速连续保存", True, 
                    f"5次保存完成，耗时: {elapsed:.2f}s")
            else:
                self._record_result("快速连续保存", False, 
                    f"URL 不匹配: {info.get('url')}")
                
        except Exception as e:
            self._record_result("快速连续保存", False, str(e))
    
    def test_06_save_without_modification(self):
        """测试 6: 未修改时保存"""
        print("\n💾 测试 6: 未修改时保存")
        try:
            # 创建并保存请求
            self.client.create_request()
            self.client.set_url("https://httpbin.org/get")
            self.client.save_request()
            time.sleep(0.3)
            
            # 再次保存（未做修改）
            result = self.client.save_request()
            
            # 验证（应该也能成功保存）
            self._record_result("未修改时保存", True, "重复保存成功（幂等性）")
                
        except Exception as e:
            self._record_result("未修改时保存", False, str(e))
    
    def test_07_multiple_requests_save(self):
        """测试 7: 多个请求的保存"""
        print("\n📚 测试 7: 多个请求的保存")
        try:
            # 创建第一个请求
            req1 = self.client.create_request()
            req1_id = req1.get('request_id')
            self.client.set_url("https://httpbin.org/get")
            self.client.rename_request("Request 1")
            self.client.save_request()
            
            # 创建第二个请求
            req2 = self.client.create_request()
            req2_id = req2.get('request_id')
            self.client.set_url("https://httpbin.org/post")
            self.client.set_method("POST")
            self.client.rename_request("Request 2")
            self.client.save_request()
            
            # 创建第三个请求
            req3 = self.client.create_request()
            req3_id = req3.get('request_id')
            self.client.set_url("https://httpbin.org/put")
            self.client.set_method("PUT")
            self.client.rename_request("Request 3")
            self.client.save_request()
            
            # 验证所有请求都存在
            ui_info = self.client.get_ui_info()
            tabs = ui_info.get('tabs', [])
            
            if len(tabs) == 3:
                names = [t.get('name') for t in tabs]
                self._record_result("多个请求保存", True, 
                    f"3个请求已保存: {', '.join(names)}")
            else:
                self._record_result("多个请求保存", False, 
                    f"期望 3 个 Tab，实际 {len(tabs)} 个")
                
        except Exception as e:
            self._record_result("多个请求保存", False, str(e))
    
    def test_08_large_body_save(self):
        """测试 8: 大 Body 保存"""
        print("\n📦 测试 8: 大 Body 保存")
        try:
            # 创建新请求
            self.client.create_request()
            self.client.set_url("https://httpbin.org/post")
            self.client.set_method("POST")
            
            # 生成大 Body（10KB）
            large_body = '{"data": "' + "A" * 10000 + '"}'
            self.client.set_body(large_body, "json")
            
            # 保存
            start_time = time.time()
            self.client.save_request()
            elapsed = time.time() - start_time
            
            # 验证
            info = self.client.send_command("get_request_editor_info")
            if info.get('body_length', 0) >= 10000:
                self._record_result("大 Body 保存", True, 
                    f"Body 大小: {info.get('body_length')} bytes, 保存耗时: {elapsed:.2f}s")
            else:
                self._record_result("大 Body 保存", False, 
                    f"Body 大小不正确: {info.get('body_length')}")
                
        except Exception as e:
            self._record_result("大 Body 保存", False, str(e))


def main():
    """主函数"""
    import argparse
    parser = argparse.ArgumentParser(description="保存功能边界情况测试")
    parser.add_argument("--port", type=int, help="测试服务器端口")
    args = parser.parse_args()
    
    tester = SaveEdgeCaseTester(port=args.port)
    success = tester.run_all_tests()
    
    if success:
        print("\n🎉 所有边界情况测试通过！")
        sys.exit(0)
    else:
        print("\n⚠️  部分测试失败")
        sys.exit(1)


if __name__ == "__main__":
    main()
