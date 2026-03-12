#!/usr/bin/env python3
"""
Hopp UI 测试客户端

通过 HTTP 协议与测试模式下的 Hopp 应用通信，
发送测试指令并获取结果。

使用方法:
    python test_client.py --help

示例:
    # 测试连接
    python test_client.py ping
    
    # 创建新请求并发送
    python test_client.py create_request
    python test_client.py set_url --url https://httpbin.org/get
    python test_client.py send_request
    
    # 切换到 Certificate Tab
    python test_client.py switch_response_tab --tab certificate
    
    # 完整测试流程
    python test_client.py full_test
"""

import argparse
import json
import sys
import time
import subprocess
from pathlib import Path

import requests


class HoppTestClient:
    """Hopp UI 测试客户端"""
    
    def __init__(self, port=None):
        self.port = port
        self.base_url = None
        
        if port:
            self.base_url = f"http://localhost:{port}"
    
    def _get_port_from_log(self):
        """从日志文件读取端口号"""
        import glob
        import re
        
        # 查找最新的 Hopp 日志文件
        log_dir = Path.home() / "Library/Containers/com.example.hopp/Data/Library/Application Support/com.example.hopp/logs"
        log_files = list(log_dir.glob("hopp_*.log"))
        
        if log_files:
            # 按修改时间排序，取最新的
            log_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
            latest_log = log_files[0]
            
            # 读取日志查找端口
            content = latest_log.read_text()
            match = re.search(r'测试服务器启动在端口:\s*(\d+)', content)
            if match:
                return int(match.group(1))
        
        return None
    
    def _ensure_connection(self):
        """确保已连接到测试服务器"""
        if not self.base_url:
            port = self.port or self._get_port_from_log()
            if not port:
                raise Exception("无法获取测试服务器端口，请确保 Hopp 以 --test-mode 启动")
            self.port = port
            self.base_url = f"http://localhost:{port}"
    
    def send_command(self, action, params=None):
        """发送指令到 Hopp"""
        self._ensure_connection()
        
        data = {
            "action": action,
            "params": params or {}
        }
        
        try:
            response = requests.post(
                self.base_url,
                json=data,
                timeout=30
            )
            response.raise_for_status()
            resp_json = response.json()
            # 返回 result 字段的内容
            if resp_json.get('success'):
                return resp_json.get('result', {})
            else:
                raise Exception(f"服务器错误: {resp_json.get('error', '未知错误')}")
        except requests.exceptions.ConnectionError:
            raise Exception(f"无法连接到 Hopp 测试服务器 ({self.base_url})，请确认应用已启动")
        except requests.exceptions.Timeout:
            raise Exception("请求超时")
    
    def ping(self):
        """测试连接"""
        result = self.send_command("ping")
        print("✅ 连接成功")
        print(f"   服务器状态: {result}")
        return result
    
    def create_request(self):
        """创建新请求"""
        print("📝 创建新请求...")
        result = self.send_command("create_request")
        print(f"✅ 请求已创建: {result.get('name')}")
        print(f"   ID: {result.get('request_id')}")
        return result
    
    def set_url(self, url):
        """设置 URL"""
        print(f"🔗 设置 URL: {url}")
        result = self.send_command("set_url", {"url": url})
        print(f"✅ URL 已设置: {result.get('url')}")
        return result
    
    def set_method(self, method):
        """设置 HTTP 方法"""
        print(f"📡 设置 HTTP 方法: {method}")
        result = self.send_command("set_method", {"method": method})
        print(f"✅ 方法已设置: {result.get('method')}")
        return result
    
    def send_request(self):
        """发送请求"""
        print("🚀 发送请求...")
        result = self.send_command("send_request")
        print(f"✅ 请求已发送")
        return result
    
    def switch_response_tab(self, tab):
        """切换响应 Tab"""
        print(f"📑 切换到 {tab} Tab...")
        result = self.send_command("switch_response_tab", {"tab": tab})
        print(f"✅ 已切换到 {result.get('tab')} Tab")
        return result
    
    def add_header(self, key, value):
        """添加 Header"""
        print(f"📋 添加 Header: {key}: {value}")
        result = self.send_command("add_header", {"key": key, "value": value})
        print(f"✅ Header 已添加")
        return result
    
    def set_body(self, body, body_type="json"):
        """设置 Body"""
        print(f"📄 设置 Body (类型: {body_type})...")
        result = self.send_command("set_body", {"body": body, "type": body_type})
        print(f"✅ Body 已设置，长度: {result.get('body_length')}")
        return result
    
    def get_response_info(self):
        """获取响应信息"""
        result = self.send_command("get_response_info")
        if result.get("has_response"):
            print("📊 响应信息:")
            print(f"   状态码: {result.get('status_code')} {result.get('status_text')}")
            print(f"   耗时: {result.get('duration_ms')} ms")
            print(f"   大小: {result.get('size_bytes')} bytes")
            print(f"   内容类型: {result.get('content_type')}")
            print(f"   证书信息: {'有' if result.get('has_certificate') else '无'}")
        else:
            print("⚠️ 暂无响应")
        return result
    
    def wait(self, milliseconds):
        """等待指定时间"""
        print(f"⏳ 等待 {milliseconds}ms...")
        result = self.send_command("wait", {"ms": milliseconds})
        return result
    
    def close_tab(self):
        """关闭当前 Tab"""
        print("❌ 关闭当前 Tab...")
        result = self.send_command("close_tab")
        print("✅ Tab 已关闭")
        return result
    
    def save_request(self):
        """保存请求"""
        print("💾 保存请求...")
        result = self.send_command("save_request")
        print("✅ 请求已保存")
        return result
    
    def rename_request(self, new_name, request_id=None):
        """直接重命名请求（非交互式）"""
        print(f"✏️ 重命名请求为: {new_name}")
        params = {"new_name": new_name}
        if request_id:
            params["request_id"] = request_id
        result = self.send_command("rename_request", params)
        print(f"✅ 已重命名: {result.get('old_name')} → {result.get('new_name')}")
        return result
    
    def start_edit_request_name(self, request_id=None):
        """开始编辑请求名称（交互式）"""
        print("📝 开始编辑请求名称...")
        params = {}
        if request_id:
            params["request_id"] = request_id
        result = self.send_command("start_edit_request_name", params)
        print(f"✅ 正在编辑: {result.get('current_name')}")
        return result
    
    def set_request_name(self, name):
        """设置编辑中的名称文本"""
        print(f"⌨️ 输入名称: {name}")
        result = self.send_command("set_request_name", {"name": name})
        return result
    
    def confirm_edit_request_name(self):
        """确认编辑请求名称"""
        print("✅ 确认编辑...")
        result = self.send_command("confirm_edit_request_name")
        print(f"✅ 已确认: {result.get('old_name')} → {result.get('new_name')}")
        return result
    
    def cancel_edit_request_name(self):
        """取消编辑请求名称"""
        print("❌ 取消编辑...")
        result = self.send_command("cancel_edit_request_name")
        print("✅ 已取消")
        return result
    
    def get_request_info(self, request_id=None):
        """获取请求信息"""
        params = {}
        if request_id:
            params["request_id"] = request_id
        result = self.send_command("get_request_info", params)
        print(f"📋 请求信息:")
        print(f"   ID: {result.get('request_id')}")
        print(f"   名称: {result.get('name')}")
        print(f"   方法: {result.get('method')}")
        print(f"   URL: {result.get('url')}")
        print(f"   是否打开: {result.get('is_open_in_tab')}")
        return result
    
    def full_test(self):
        """执行完整测试流程"""
        print("\n" + "="*60)
        print("🧪 Hopp UI 自动化测试 - 完整流程")
        print("="*60 + "\n")
        
        # 1. 测试连接
        self.ping()
        
        # 2. 创建新请求
        self.create_request()
        
        # 3. 设置 HTTPS URL
        self.set_url("https://httpbin.org/get")
        
        # 4. 发送请求
        self.send_request()
        
        # 5. 等待响应
        print("\n⏳ 等待响应...")
        time.sleep(5)
        
        # 6. 获取响应信息
        self.get_response_info()
        
        # 7. 切换到 Certificate Tab
        self.switch_response_tab("certificate")
        
        # 8. 等待显示
        time.sleep(2)
        
        print("\n" + "="*60)
        print("✅ 测试完成!")
        print("="*60 + "\n")
        
        return {"success": True}


def main():
    parser = argparse.ArgumentParser(
        description="Hopp UI 测试客户端",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s ping                          # 测试连接
  %(prog)s create_request                # 创建新请求
  %(prog)s set_url --url https://...     # 设置 URL
  %(prog)s send_request                  # 发送请求
  %(prog)s switch_response_tab --tab certificate  # 切换 Tab
  %(prog)s full_test                     # 执行完整测试
  
请求名称编辑:
  %(prog)s rename_request --name "New Name"          # 直接重命名
  %(prog)s start_edit_request_name                   # 开始编辑
  %(prog)s set_request_name --name "New Name"        # 输入名称
  %(prog)s confirm_edit_request_name                 # 确认编辑
  %(prog)s cancel_edit_request_name                  # 取消编辑
        """
    )
    
    parser.add_argument("--port", type=int, help="测试服务器端口（可选，默认从文件读取）")
    
    subparsers = parser.add_subparsers(dest="command", help="可用指令")
    
    # ping
    subparsers.add_parser("ping", help="测试连接")
    
    # create_request
    subparsers.add_parser("create_request", help="创建新请求")
    
    # set_url
    set_url_parser = subparsers.add_parser("set_url", help="设置 URL")
    set_url_parser.add_argument("--url", required=True, help="URL 地址")
    
    # set_method
    set_method_parser = subparsers.add_parser("set_method", help="设置 HTTP 方法")
    set_method_parser.add_argument("--method", required=True, choices=["GET", "POST", "PUT", "DELETE", "PATCH"])
    
    # send_request
    subparsers.add_parser("send_request", help="发送请求")
    
    # switch_response_tab
    switch_tab_parser = subparsers.add_parser("switch_response_tab", help="切换响应 Tab")
    switch_tab_parser.add_argument("--tab", required=True, choices=["body", "headers", "cookies", "certificate"])
    
    # add_header
    add_header_parser = subparsers.add_parser("add_header", help="添加 Header")
    add_header_parser.add_argument("--key", required=True, help="Header 名称")
    add_header_parser.add_argument("--value", required=True, help="Header 值")
    
    # set_body
    set_body_parser = subparsers.add_parser("set_body", help="设置 Body")
    set_body_parser.add_argument("--body", required=True, help="Body 内容")
    set_body_parser.add_argument("--type", default="json", choices=["json", "text", "form"])
    
    # get_response_info
    subparsers.add_parser("get_response_info", help="获取响应信息")
    
    # wait
    wait_parser = subparsers.add_parser("wait", help="等待指定时间")
    wait_parser.add_argument("--ms", type=int, default=1000, help="等待毫秒数")
    
    # close_tab
    subparsers.add_parser("close_tab", help="关闭当前 Tab")
    
    # save_request
    subparsers.add_parser("save_request", help="保存请求")
    
    # rename_request
    rename_parser = subparsers.add_parser("rename_request", help="直接重命名请求")
    rename_parser.add_argument("--name", required=True, help="新名称")
    rename_parser.add_argument("--id", help="请求 ID（默认当前活动请求）")
    
    # start_edit_request_name
    start_edit_parser = subparsers.add_parser("start_edit_request_name", help="开始编辑请求名称")
    start_edit_parser.add_argument("--id", help="请求 ID（默认当前活动请求）")
    
    # set_request_name
    set_name_parser = subparsers.add_parser("set_request_name", help="设置编辑中的名称")
    set_name_parser.add_argument("--name", required=True, help="名称")
    
    # confirm_edit_request_name
    subparsers.add_parser("confirm_edit_request_name", help="确认编辑")
    
    # cancel_edit_request_name
    subparsers.add_parser("cancel_edit_request_name", help="取消编辑")
    
    # get_request_info
    get_info_parser = subparsers.add_parser("get_request_info", help="获取请求信息")
    get_info_parser.add_argument("--id", help="请求 ID（默认当前活动请求）")
    
    # full_test
    subparsers.add_parser("full_test", help="执行完整测试流程")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    try:
        client = HoppTestClient(port=args.port)
        
        # 执行对应命令
        if args.command == "ping":
            client.ping()
        elif args.command == "create_request":
            client.create_request()
        elif args.command == "set_url":
            client.set_url(args.url)
        elif args.command == "set_method":
            client.set_method(args.method)
        elif args.command == "send_request":
            client.send_request()
        elif args.command == "switch_response_tab":
            client.switch_response_tab(args.tab)
        elif args.command == "add_header":
            client.add_header(args.key, args.value)
        elif args.command == "set_body":
            client.set_body(args.body, args.type)
        elif args.command == "get_response_info":
            client.get_response_info()
        elif args.command == "wait":
            client.wait(args.ms)
        elif args.command == "close_tab":
            client.close_tab()
        elif args.command == "save_request":
            client.save_request()
        elif args.command == "rename_request":
            client.rename_request(args.name, args.id)
        elif args.command == "start_edit_request_name":
            client.start_edit_request_name(args.id)
        elif args.command == "set_request_name":
            client.set_request_name(args.name)
        elif args.command == "confirm_edit_request_name":
            client.confirm_edit_request_name()
        elif args.command == "cancel_edit_request_name":
            client.cancel_edit_request_name()
        elif args.command == "get_request_info":
            client.get_request_info(args.id)
        elif args.command == "full_test":
            client.full_test()
        
    except Exception as e:
        print(f"❌ 错误: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
