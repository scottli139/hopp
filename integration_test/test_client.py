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


# 全局默认端口
DEFAULT_PORT = None

class HoppTestClient:
    """Hopp UI 测试客户端"""
    
    def __init__(self, port=None):
        self.port = port or DEFAULT_PORT
        self.base_url = None
        
        if self.port:
            self.base_url = f"http://localhost:{self.port}"
    
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
        valid_tabs = ["body", "headers", "cookies", "timing", "certificate", "request"]
        if tab.lower() not in valid_tabs:
            raise Exception(f"无效的 Tab: {tab}, 可选: {valid_tabs}")
        print(f"📑 切换到 {tab} Tab...")
        result = self.send_command("switch_response_tab", {"tab": tab})
        print(f"✅ 已切换到 {result.get('tab')} Tab")
        return result

    def switch_request_tab(self, tab):
        """切换 Request Editor Tab"""
        valid_tabs = ["params", "headers", "body", "auth", "settings"]
        if tab.lower() not in valid_tabs:
            raise Exception(f"无效的 Tab: {tab}, 可选: {valid_tabs}")
        print(f"📑 切换到 Request {tab} Tab...")
        result = self.send_command("switch_request_tab", {"tab": tab})
        print(f"✅ 已切换到 Request {result.get('tab')} Tab")
        return result

    def get_timing_info(self):
        """获取请求时间分析信息"""
        result = self.send_command("get_timing_info")
        if result.get("has_timing"):
            print("⏱️ 时间分析信息:")
            print(f"   DNS: {result.get('dns_formatted')} ({result.get('dns_ms')}ms)")
            print(f"   TCP: {result.get('tcp_formatted')} ({result.get('tcp_ms')}ms)")
            print(f"   TLS: {result.get('tls_formatted')} ({result.get('tls_ms')}ms)")
            print(f"   TTFB: {result.get('ttfb_formatted')} ({result.get('ttfb_ms')}ms)")
            print(f"   Download: {result.get('download_formatted')} ({result.get('download_ms')}ms)")
            print(f"   Total: {result.get('total_formatted')} ({result.get('total_ms')}ms)")
        else:
            print("⚠️ 暂无时间分析信息")
        return result

    def simulate_response_with_timing(self):
        """模拟带时间分析的响应"""
        print("🔧 模拟带时间分析的响应...")
        result = self.send_command("simulate_response_with_timing")
        print(f"✅ 模拟响应已创建，总时间: {result.get('total_ms')}ms")
        return result

    def get_request_details(self):
        """获取请求详情"""
        result = self.send_command("get_request_details")
        print("📤 请求详情:")
        print(f"   方法: {result.get('method')}")
        print(f"   URL: {result.get('url')}")
        print(f"   完整 URL: {result.get('full_url')}")
        
        # 如果有 requestInfo，显示更多详情
        if result.get('has_request_info'):
            print(f"   Scheme: {result.get('scheme')}")
            print(f"   Host: {result.get('host')}")
            print(f"   Path: {result.get('path')}")
            if result.get('port'):
                print(f"   Port: {result.get('port')}")
            print(f"   Query Params: {result.get('query_params_count')} 个")
            if result.get('user_agent'):
                print(f"   User-Agent: {result.get('user_agent')}")
            if result.get('content_type'):
                print(f"   Content-Type: {result.get('content_type')}")
        
        print(f"   Headers: {result.get('headers_count')} 个")
        for header in result.get('headers', []):
            print(f"     {header.get('key')}: {header.get('value')}")
        print(f"   Body: {'有' if result.get('has_body') else '无'} ({result.get('body_type')})")
        if result.get('has_body'):
            if result.get('body_size'):
                print(f"   Body 大小: {result.get('body_size')} bytes")
            if result.get('body_length'):
                print(f"   Body 长度: {result.get('body_length')} 字符")
            if result.get('body_preview'):
                preview = result.get('body_preview', '')
                if len(preview) > 100:
                    preview = preview[:100] + '...'
                print(f"   Body 预览: {preview}")
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
    
    def get_response_body_info(self):
        """获取响应体信息"""
        result = self.send_command("get_response_body_info")
        if result.get("has_body"):
            print(f"📄 响应体信息:")
            print(f"   大小: {result.get('size_kb')} KB ({result.get('size_bytes')} bytes)")
            print(f"   行数: {result.get('line_count')}")
            print(f"   预览: {result.get('preview')[:50]}...")
        else:
            print("⚠️ 暂无响应体")
        return result
    
    def set_response_display_mode(self, mode):
        """设置响应显示模式"""
        print(f"🎨 设置显示模式: {mode}")
        result = self.send_command("set_response_display_mode", {"mode": mode})
        print(f"✅ 显示模式已设置为: {result.get('mode')}")
        return result
    
    def simulate_large_response(self, size=100000):
        """模拟大响应（用于测试性能优化）"""
        print(f"🔧 模拟大响应 ({size} bytes)...")
        result = self.send_command("simulate_large_response", {"size": size})
        print(f"✅ 模拟响应已创建:")
        print(f"   大小: {result.get('size_kb')} KB ({result.get('size_bytes')} bytes)")
        print(f"   行数: {result.get('line_count')}")
        return result

    def click_new_tab_button(self):
        """点击新建标签按钮"""
        print("➕ 点击新建标签按钮...")
        result = self.send_command("click_new_tab_button")
        print(f"✅ 新标签已创建: {result.get('request_name')}")
        print(f"   ID: {result.get('request_id')}")
        return result

    def get_ui_info(self):
        """获取 UI 信息"""
        result = self.send_command("get_ui_info")
        print(f"📊 UI 信息:")
        print(f"   标签数量: {result.get('tab_count')}")
        print(f"   活动标签: {result.get('active_tab_id')}")
        if result.get('has_active_request'):
            print(f"   当前请求: {result.get('active_request_method')} {result.get('active_request_url')}")
        print(f"   标签列表:")
        for tab in result.get('tabs', []):
            dirty_mark = " ●" if tab.get('is_dirty') else ""
            active_mark = " 👈" if tab.get('is_active') else ""
            print(f"     [{tab.get('method')}] {tab.get('name')}{dirty_mark}{active_mark}")
        return result

    def expand_method_dropdown(self):
        """展开 Method 下拉菜单"""
        result = self.send_command("expand_method_dropdown")
        print(f"📋 Method 下拉菜单已展开")
        return result

    def expand_raw_content_type_dropdown(self):
        """展开 Raw 子类型下拉菜单"""
        result = self.send_command("expand_raw_content_type_dropdown")
        print(f"📋 Raw 子类型下拉菜单已展开")
        return result

    def switch_request_tab(self, tab):
        """切换 Request Editor Tab"""
        result = self.send_command("switch_request_tab", {"tab": tab})
        print(f"📑 切换到 {tab} Tab")
        return result

    def scroll_response(self, direction="down", amount=100):
        """滚动响应区域
        
        Args:
            direction: 滚动方向 ('up', 'down', 'left', 'right')
            amount: 滚动距离（像素）
        """
        result = self.send_command("scroll_response", {
            "direction": direction,
            "amount": amount
        })
        print(f"📜 响应区域向{direction}滚动 {amount}px")
        return result

    def set_window_size(self, width=None, height=None):
        """设置窗口大小
        
        Args:
            width: 窗口宽度（像素），None 表示不调整
            height: 窗口高度（像素），None 表示不调整
        """
        result = self.send_command("set_window_size", {
            "width": width,
            "height": height
        })
        print(f"🪟 窗口大小设置为 {width}x{height}")
        return result

    def set_divider_position(self, ratio=0.5):
        """设置分隔线位置（请求/响应区域的比例）
        
        Args:
            ratio: 分隔线位置（0.2 - 0.8），0.5 表示中间
        """
        result = self.send_command("set_divider_position", {
            "ratio": ratio
        })
        print(f"📏 分隔线位置设置为 {ratio}")
        return result

    def focus_url_input(self):
        """聚焦 URL 输入框（用于测试 focus 状态）"""
        print("🎯 聚焦 URL 输入框...")
        result = self.send_command("focus_url_input")
        print("✅ URL 输入框已聚焦")
        return result

    def get_request_editor_info(self):
        """获取 Request Editor 信息"""
        result = self.send_command("get_request_editor_info")
        print("📋 Request Editor 信息:")
        print(f"   Params: {result.get('params_count')} 个")
        print(f"   Headers: {result.get('headers_count')} 个")
        print(f"   Body: {'有' if result.get('has_body_content') else '无'} ({result.get('body_type')})")
        return result

    def add_param(self, key, value):
        """添加 Param"""
        print(f"📋 添加 Param: {key}={value}")
        result = self.send_command("add_param", {"key": key, "value": value})
        print(f"✅ Param 已添加，总共 {result.get('total_params')} 个")
        return result

    def add_header_with_description(self, key, value, description=None):
        """添加 Header（带描述）"""
        print(f"📋 添加 Header: {key}: {value}")
        params = {"key": key, "value": value}
        if description:
            params["description"] = description
        result = self.send_command("add_header_with_description", params)
        print(f"✅ Header 已添加，总共 {result.get('total_headers')} 个")
        return result

    def set_body_type(self, body_type):
        """设置 Body 类型
        
        Args:
            body_type: Body 类型 ('none', 'form-data', 'x-www-form-urlencoded', 'raw', 'binary', 'graphql')
        """
        valid_types = ['none', 'form-data', 'x-www-form-urlencoded', 'raw', 'binary', 'graphql']
        if body_type not in valid_types:
            raise Exception(f"无效的 body 类型: {body_type}, 可选: {valid_types}")
        print(f"📄 设置 Body 类型: {body_type}")
        result = self.send_command("set_body_type", {"body_type": body_type})
        print(f"✅ Body 类型已设置为: {result.get('body_type')}")
        return result

    def set_raw_content_type(self, content_type):
        """设置 Raw 子类型
        
        Args:
            content_type: 内容类型 ('text', 'javascript', 'json', 'html', 'xml')
        """
        valid_types = ['text', 'javascript', 'json', 'html', 'xml']
        if content_type.lower() not in valid_types:
            raise Exception(f"无效的 content 类型: {content_type}, 可选: {valid_types}")
        print(f"📄 设置 Raw 内容类型: {content_type}")
        result = self.send_command("set_raw_content_type", {"content_type": content_type.lower()})
        print(f"✅ Raw 内容类型已设置为: {result.get('raw_content_type')}")
        return result

    def get_body_info(self):
        """获取 Body 信息"""
        result = self.send_command("get_body_info")
        print("📋 Body 信息:")
        print(f"   Body 类型: {result.get('body_type')}")
        print(f"   Raw 内容类型: {result.get('raw_content_type')}")
        print(f"   Body 长度: {result.get('body_length')} 字符")
        print(f"   是否有 Body: {'是' if result.get('has_body') else '否'}")
        return result

    def beautify_code(self):
        """格式化代码"""
        print("✨ 格式化代码...")
        result = self.send_command("beautify_code")
        print("✅ 代码已格式化")
        return result

    def capture_screenshot(self, name="screenshot"):
        """截图"""
        print(f"📸 截图: {name}")
        result = self.send_command("capture_screenshot", {"name": name})
        print(f"✅ 截图已保存: {result.get('path')}")
        return result

    def get_collections(self):
        """获取所有集合"""
        print("📁 获取集合列表...")
        result = self.send_command("get_collections")
        print(f"✅ 找到 {result.get('collection_count')} 个集合")
        for collection in result.get('collections', []):
            print(f"   - {collection.get('name')} ({collection.get('request_count')} 请求)")
        return result
    
    def import_collection(self, file_path):
        """导入 Postman Collection"""
        print(f"📥 导入集合: {file_path}")
        result = self.send_command("import_collection", {"file_path": file_path})
        if result.get('imported'):
            print(f"✅ 导入成功: {result.get('request_count')} 个请求")
            if result.get('renamed'):
                print(f"   已重命名为: {result.get('new_name')}")
            if result.get('merged'):
                print("   已合并到现有集合")
        elif result.get('conflict'):
            print(f"⚠️  冲突: {result.get('collection_name')} 已存在")
        return result
    
    def get_imported_request_info(self, collection_index=0, request_index=0):
        """获取导入后的请求信息（用于验证 raw content type 映射）
        
        Args:
            collection_index: Collection 索引（默认 0）
            request_index: Request 索引（默认 0）
        """
        print(f"📋 获取导入请求信息: Collection[{collection_index}], Request[{request_index}]")
        result = self.send_command("get_imported_request_info", {
            "collection_index": collection_index,
            "request_index": request_index
        })
        print(f"✅ 请求信息:")
        print(f"   名称: {result.get('request_name')}")
        print(f"   方法: {result.get('method')}")
        print(f"   Body 类型: {result.get('body_type')}")
        print(f"   Raw Content Type: {result.get('raw_content_type')}")
        return result
    
    def trigger_import_dialog(self):
        """触发导入对话框"""
        print("📥 触发导入对话框...")
        result = self.send_command("trigger_import_dialog")
        print("✅ 导入对话框已触发")
        return result
    
    def trigger_export_dialog(self):
        """触发导出对话框"""
        print("📤 触发导出对话框...")
        result = self.send_command("trigger_export_dialog")
        print("✅ 导出对话框已触发")
        return result

    def trigger_delete_collection_dialog(self):
        """触发删除 Collection 对话框"""
        print("🗑️ 触发删除 Collection 对话框...")
        result = self.send_command("trigger_delete_collection_dialog")
        print("✅ 删除 Collection 对话框已触发")
        return result

    def simulate_4xx_response(self, status_code=400):
        """模拟 4XX 错误响应（带服务端返回的错误详情）
        
        Args:
            status_code: HTTP 状态码（默认 400）
        """
        print(f"🔴 模拟 4XX 错误响应: {status_code}")
        result = self.send_command("simulate_4xx_response", {"status_code": status_code})
        print(f"✅ 模拟响应已创建:")
        print(f"   状态码: {result.get('status_code')} {result.get('status_text')}")
        print(f"   Body 大小: {result.get('body_size')} bytes")
        print(f"   包含错误信息: {'是' if result.get('has_error_info') else '否'}")
        return result

    def simulate_5xx_response(self, status_code=500):
        """模拟 5XX 错误响应（带服务端返回的错误详情）
        
        Args:
            status_code: HTTP 状态码（默认 500）
        """
        print(f"🔴 模拟 5XX 错误响应: {status_code}")
        result = self.send_command("simulate_5xx_response", {"status_code": status_code})
        print(f"✅ 模拟响应已创建:")
        print(f"   状态码: {result.get('status_code')} {result.get('status_text')}")
        print(f"   Body 大小: {result.get('body_size')} bytes")
        print(f"   包含错误信息: {'是' if result.get('has_error_info') else '否'}")
        return result

    def get_certificate_info(self):
        """获取证书信息"""
        print("🔒 获取证书信息...")
        result = self.send_command("get_certificate_info")
        
        if result.get('has_certificate'):
            print("✅ 证书信息:")
            print(f"   主题 (Subject): {result.get('subject')}")
            print(f"   颁发者 (Issuer): {result.get('issuer')}")
            print(f"   有效期: {result.get('validity_period')}")
            print(f"   是否有效: {'是' if result.get('is_valid') else '否'}")
            print(f"   剩余天数: {result.get('remaining_days')} 天")
            print(f"   签名算法: {result.get('signature_algorithm')}")
            print(f"   序列号: {result.get('serial_number')}")
            print(f"   SHA-256 指纹: {result.get('sha256_fingerprint')}")
            if result.get('subject_alternative_names'):
                print(f"   主题备用名称 (SAN): {', '.join(result.get('subject_alternative_names', []))}")
            print(f"   公钥算法: {result.get('public_key_algorithm')} ({result.get('public_key_length')} 位)")
            print(f"   证书链长度: {result.get('chain_length')}")
        else:
            print(f"⚠️  {result.get('message')}")
        
        return result

    def simulate_certificate_response(self):
        """模拟带证书信息的 HTTPS 响应"""
        print("🔒 模拟带证书信息的 HTTPS 响应...")
        result = self.send_command("simulate_certificate_response")
        
        if result.get('simulated'):
            print("✅ 模拟响应已创建:")
            print(f"   状态码: {result.get('status_code')}")
            print(f"   包含证书: {'是' if result.get('has_certificate') else '否'}")
            if result.get('has_certificate'):
                print(f"   证书主题: {result.get('certificate_subject')}")
                print(f"   证书颁发者: {result.get('certificate_issuer')}")
                print(f"   有效期: {result.get('valid_from')} 至 {result.get('valid_to')}")
                print(f"   是否有效: {'是' if result.get('is_valid') else '否'}")
                print(f"   剩余天数: {result.get('remaining_days')} 天")
        
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

    # ==================== 数据库迁移测试方法 ====================

    def reset_database(self):
        """重置数据库（用于测试）"""
        print("\n🗑️  重置数据库...")
        result = self.send_command("reset_database")
        print(f"✅ 数据库已重置")
        return result

    def simulate_old_data(self, version=1):
        """模拟旧版本数据
        
        Args:
            version: 要模拟的旧版本号 (默认 1)
        """
        print(f"\n📦 模拟旧版本数据 (v{version})...")
        result = self.send_command("simulate_old_data", {"version": version})
        print(f"✅ 已创建旧版本测试数据")
        print(f"   Request ID: {result.get('request_id')}")
        print(f"   Collection ID: {result.get('collection_id')}")
        return result

    def verify_migration(self, expected_version=None):
        """验证迁移结果
        
        Args:
            expected_version: 期望的数据库版本号
        """
        print("\n🔍 验证迁移结果...")
        params = {}
        if expected_version is not None:
            params["expected_version"] = expected_version
        
        result = self.send_command("verify_migration", params)
        
        print(f"当前版本: {result.get('current_version')}")
        print(f"期望版本: {result.get('expected_version')}")
        print(f"版本匹配: {'✅' if result.get('version_matches') else '❌'}")
        print(f"请求数量: {result.get('request_count')}")
        print(f"所有字段有默认值: {'✅' if result.get('all_have_defaults') else '❌'}")
        
        # 显示每个请求的字段状态
        for req in result.get('requests', []):
            print(f"\n  Request: {req.get('name')} ({req.get('id')})")
            print(f"    validate_certificates: {req.get('validate_certificates')}")
            print(f"    follow_redirects: {req.get('follow_redirects')}")
            print(f"    max_redirects: {req.get('max_redirects')}")
            print(f"    默认值正确: {'✅' if req.get('has_valid_defaults') else '❌'}")
        
        return result

    def set_request_settings(self, validate_certificates=None, follow_redirects=None, max_redirects=None):
        """设置请求级别配置
        
        Args:
            validate_certificates: SSL 证书验证开关
            follow_redirects: 是否跟随重定向
            max_redirects: 最大重定向次数
        """
        print("\n⚙️  设置请求配置...")
        params = {}
        if validate_certificates is not None:
            params["validate_certificates"] = validate_certificates
        if follow_redirects is not None:
            params["follow_redirects"] = follow_redirects
        if max_redirects is not None:
            params["max_redirects"] = max_redirects
        
        result = self.send_command("set_request_settings", params)
        print(f"✅ 配置已更新")
        print(f"   validate_certificates: {result.get('validate_certificates')}")
        print(f"   follow_redirects: {result.get('follow_redirects')}")
        print(f"   max_redirects: {result.get('max_redirects')}")
        return result

    def get_request_settings(self):
        """获取请求级别配置"""
        print("\n📋 获取请求配置...")
        result = self.send_command("get_request_settings")
        print(f"Request: {result.get('request_name')} ({result.get('request_id')})")
        print(f"   validate_certificates: {result.get('validate_certificates')}")
        print(f"   follow_redirects: {result.get('follow_redirects')}")
        print(f"   max_redirects: {result.get('max_redirects')}")
        return result

    def verify_url_params_sync(self):
        """验证 URL 与 Params 双向同步功能"""
        print("\n🔗 验证 URL 与 Params 双向同步...")
        result = self.send_command("verify_url_params_sync")
        print(f"✅ URL 参数同步验证:")
        print(f"   URL: {result.get('full_url')}")
        print(f"   基础 URL: {result.get('url')}")
        print(f"   参数总数: {result.get('params_count')}")
        print(f"   启用参数数: {result.get('enabled_params_count')}")
        print(f"   包含查询参数: {'是' if result.get('has_query_params') else '否'}")
        if result.get('params'):
            print("   参数列表:")
            for param in result.get('params', []):
                enabled_mark = "✓" if param.get('enabled') else "✗"
                print(f"     [{enabled_mark}] {param.get('key')}: {param.get('value')}")
        return result


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
  
证书测试:
  %(prog)s simulate_certificate_response            # 模拟带证书的响应
  %(prog)s get_certificate_info                     # 获取证书信息

数据库迁移测试:
  %(prog)s reset_database                            # 重置数据库
  %(prog)s simulate_old_data --version 1             # 模拟旧版本数据
  %(prog)s verify_migration --expected-version 2     # 验证迁移结果
  
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
    switch_tab_parser.add_argument("--tab", required=True, choices=["body", "headers", "cookies", "timing", "certificate", "request"])
    
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
    
    # get_response_body_info
    subparsers.add_parser("get_response_body_info", help="获取响应体信息")
    
    # set_response_display_mode
    mode_parser = subparsers.add_parser("set_response_display_mode", help="设置响应显示模式")
    mode_parser.add_argument("--mode", required=True, 
                             choices=["auto", "performance", "full", "raw"],
                             help="显示模式")
    
    # simulate_large_response
    simulate_parser = subparsers.add_parser("simulate_large_response", help="模拟大响应")
    simulate_parser.add_argument("--size", type=int, default=100000, help="响应大小（字节）")

    # click_new_tab_button
    subparsers.add_parser("click_new_tab_button", help="点击新建标签按钮")

    # get_ui_info
    subparsers.add_parser("get_ui_info", help="获取 UI 信息")

    # expand_method_dropdown
    subparsers.add_parser("expand_method_dropdown", help="展开 Method 下拉菜单")

    # expand_raw_content_type_dropdown
    subparsers.add_parser("expand_raw_content_type_dropdown", help="展开 Raw 子类型下拉菜单")

    # switch_request_tab
    switch_request_tab_parser = subparsers.add_parser("switch_request_tab", help="切换 Request Editor Tab")
    switch_request_tab_parser.add_argument("--tab", required=True, choices=["params", "headers", "body", "auth"], help="目标 Tab")

    # scroll_response
    scroll_parser = subparsers.add_parser("scroll_response", help="滚动响应区域")
    scroll_parser.add_argument("--direction", default="down", choices=["up", "down", "left", "right"], help="滚动方向")
    scroll_parser.add_argument("--amount", type=int, default=100, help="滚动距离（像素）")

    # set_window_size
    window_parser = subparsers.add_parser("set_window_size", help="设置窗口大小")
    window_parser.add_argument("--width", type=int, help="窗口宽度（像素）")
    window_parser.add_argument("--height", type=int, help="窗口高度（像素）")

    # set_divider_position
    divider_parser = subparsers.add_parser("set_divider_position", help="设置分隔线位置")
    divider_parser.add_argument("--ratio", type=float, default=0.5, help="分隔线位置（0.2-0.8）")

    # focus_url_input
    subparsers.add_parser("focus_url_input", help="聚焦 URL 输入框（用于测试 focus 状态）")

    # get_request_editor_info
    subparsers.add_parser("get_request_editor_info", help="获取 Request Editor 信息")

    # add_param
    add_param_parser = subparsers.add_parser("add_param", help="添加 Param")
    add_param_parser.add_argument("--key", required=True, help="Param 名称")
    add_param_parser.add_argument("--value", required=True, help="Param 值")

    # add_header_with_description
    add_header_desc_parser = subparsers.add_parser("add_header_with_description", help="添加 Header（带描述）")
    add_header_desc_parser.add_argument("--key", required=True, help="Header 名称")
    add_header_desc_parser.add_argument("--value", required=True, help="Header 值")
    add_header_desc_parser.add_argument("--description", help="Header 描述")

    # set_body_type
    set_body_type_parser = subparsers.add_parser("set_body_type", help="设置 Body 类型")
    set_body_type_parser.add_argument("--type", required=True, 
                                       choices=["none", "form-data", "x-www-form-urlencoded", "raw", "binary", "graphql"],
                                       help="Body 类型")

    # set_raw_content_type
    set_raw_content_parser = subparsers.add_parser("set_raw_content_type", help="设置 Raw 内容类型")
    set_raw_content_parser.add_argument("--content", required=True,
                                        choices=["text", "javascript", "json", "html", "xml"],
                                        help="Raw 内容类型")

    # get_body_info
    subparsers.add_parser("get_body_info", help="获取 Body 信息")

    # get_timing_info
    subparsers.add_parser("get_timing_info", help="获取请求时间分析信息")

    # simulate_response_with_timing
    subparsers.add_parser("simulate_response_with_timing", help="模拟带时间分析的响应")
    
    # get_collections
    subparsers.add_parser("get_collections", help="获取所有集合")
    
    # import_collection
    import_parser = subparsers.add_parser("import_collection", help="导入 Postman Collection")
    import_parser.add_argument("--file", required=True, help="文件路径")
    
    # get_imported_request_info
    get_imported_parser = subparsers.add_parser("get_imported_request_info", help="获取导入后的请求信息")
    get_imported_parser.add_argument("--collection-index", type=int, default=0, help="Collection 索引")
    get_imported_parser.add_argument("--request-index", type=int, default=0, help="Request 索引")
    
    # trigger_import_dialog
    subparsers.add_parser("trigger_import_dialog", help="触发导入对话框")
    
    # trigger_export_dialog
    subparsers.add_parser("trigger_export_dialog", help="触发导出对话框")

    # simulate_4xx_response
    simulate_4xx_parser = subparsers.add_parser("simulate_4xx_response", help="模拟 4XX 错误响应")
    simulate_4xx_parser.add_argument("--status", type=int, default=400, 
                                     help="HTTP 状态码（默认 400）")

    # simulate_5xx_response
    simulate_5xx_parser = subparsers.add_parser("simulate_5xx_response", help="模拟 5XX 错误响应")
    simulate_5xx_parser.add_argument("--status", type=int, default=500,
                                     help="HTTP 状态码（默认 500）")

    # get_certificate_info
    subparsers.add_parser("get_certificate_info", help="获取证书信息")

    # simulate_certificate_response
    subparsers.add_parser("simulate_certificate_response", help="模拟带证书信息的 HTTPS 响应")

    # ==================== 数据库迁移测试命令 ====================

    # reset_database
    subparsers.add_parser("reset_database", help="重置数据库（用于测试）")

    # simulate_old_data
    simulate_old_parser = subparsers.add_parser("simulate_old_data", help="模拟旧版本数据")
    simulate_old_parser.add_argument("--version", type=int, default=1, help="旧版本号")

    # verify_migration
    verify_migration_parser = subparsers.add_parser("verify_migration", help="验证迁移结果")
    verify_migration_parser.add_argument("--expected-version", type=int, help="期望的数据库版本")

    # set_request_settings
    set_settings_parser = subparsers.add_parser("set_request_settings", help="设置请求级别配置")
    set_settings_parser.add_argument("--validate-certificates", type=lambda x: x.lower() == 'true',
                                     help="SSL 证书验证开关 (true/false)")
    set_settings_parser.add_argument("--follow-redirects", type=lambda x: x.lower() == 'true',
                                     help="是否跟随重定向 (true/false)")
    set_settings_parser.add_argument("--max-redirects", type=int,
                                     help="最大重定向次数")

    # get_request_settings
    subparsers.add_parser("get_request_settings", help="获取请求级别配置")

    # verify_url_params_sync
    subparsers.add_parser("verify_url_params_sync", help="验证 URL 与 Params 双向同步功能")

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
        elif args.command == "get_response_body_info":
            client.get_response_body_info()
        elif args.command == "set_response_display_mode":
            client.set_response_display_mode(args.mode)
        elif args.command == "simulate_large_response":
            client.simulate_large_response(args.size)
        elif args.command == "click_new_tab_button":
            client.click_new_tab_button()
        elif args.command == "get_ui_info":
            client.get_ui_info()
        elif args.command == "expand_method_dropdown":
            client.expand_method_dropdown()
        elif args.command == "expand_raw_content_type_dropdown":
            client.expand_raw_content_type_dropdown()
        elif args.command == "switch_request_tab":
            client.switch_request_tab(args.tab)
        elif args.command == "scroll_response":
            client.scroll_response(args.direction, args.amount)
        elif args.command == "set_window_size":
            client.set_window_size(args.width, args.height)
        elif args.command == "set_divider_position":
            client.set_divider_position(args.ratio)
        elif args.command == "focus_url_input":
            client.focus_url_input()
        elif args.command == "get_request_editor_info":
            client.get_request_editor_info()
        elif args.command == "add_param":
            client.add_param(args.key, args.value)
        elif args.command == "add_header_with_description":
            client.add_header_with_description(args.key, args.value, args.description)
        elif args.command == "set_body_type":
            client.set_body_type(args.type)
        elif args.command == "set_raw_content_type":
            client.set_raw_content_type(args.content)
        elif args.command == "get_body_info":
            client.get_body_info()
        elif args.command == "get_timing_info":
            client.get_timing_info()
        elif args.command == "simulate_response_with_timing":
            client.simulate_response_with_timing()
        elif args.command == "get_request_details":
            client.get_request_details()
        elif args.command == "get_collections":
            client.get_collections()
        elif args.command == "import_collection":
            client.import_collection(args.file)
        elif args.command == "get_imported_request_info":
            client.get_imported_request_info(args.collection_index, args.request_index)
        elif args.command == "trigger_import_dialog":
            client.trigger_import_dialog()
        elif args.command == "trigger_export_dialog":
            client.trigger_export_dialog()
        elif args.command == "simulate_4xx_response":
            client.simulate_4xx_response(args.status)
        elif args.command == "simulate_5xx_response":
            client.simulate_5xx_response(args.status)
        elif args.command == "get_certificate_info":
            client.get_certificate_info()
        elif args.command == "simulate_certificate_response":
            client.simulate_certificate_response()

        # ==================== 数据库迁移测试命令 ====================
        elif args.command == "reset_database":
            client.reset_database()
        elif args.command == "simulate_old_data":
            client.simulate_old_data(args.version)
        elif args.command == "verify_migration":
            client.verify_migration(args.expected_version)
        elif args.command == "set_request_settings":
            client.set_request_settings(
                validate_certificates=args.validate_certificates,
                follow_redirects=args.follow_redirects,
                max_redirects=args.max_redirects,
            )
        elif args.command == "get_request_settings":
            client.get_request_settings()

        elif args.command == "verify_url_params_sync":
            client.verify_url_params_sync()

        elif args.command == "full_test":
            client.full_test()
        
    except Exception as e:
        print(f"❌ 错误: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

    def parse_curl(self, command):
        """解析 cURL 命令（不导入）"""
        print(f"🔍 解析 cURL 命令...")
        result = self.send_command("parse_curl", {"command": command})
        if result.get("success"):
            print(f"✅ 解析成功:")
            print(f"   名称: {result['request']['name']}")
            print(f"   方法: {result['request']['method'].upper()}")
            print(f"   URL: {result['request']['url']}")
            print(f"   Headers: {result['request']['headers_count']} 个")
            print(f"   Body 类型: {result['request']['body_type']}")
            if result.get("warnings"):
                print(f"   警告: {len(result['warnings'])} 个")
                for warning in result["warnings"]:
                    print(f"     - {warning}")
        else:
            print(f"❌ 解析失败: {result.get('error')}")
        return result

    def import_curl(self, command, open_tab=True):
        """导入 cURL 命令并创建请求"""
        print(f"📥 导入 cURL 命令...")
        result = self.send_command("import_curl", {
            "command": command,
            "open_tab": open_tab
        })
        if result.get("success"):
            print(f"✅ 导入成功:")
            print(f"   请求 ID: {result['request_id']}")
            print(f"   名称: {result['name']}")
            print(f"   方法: {result['method'].upper()}")
            print(f"   URL: {result['url']}")
            if result.get("warnings"):
                print(f"   警告: {len(result['warnings'])} 个")
        else:
            print(f"❌ 导入失败: {result.get('error')}")
        return result

    def trigger_curl_import_dialog(self):
        """触发 cURL 导入对话框"""
        print(f"📂 触发 cURL 导入对话框...")
        result = self.send_command("trigger_curl_import_dialog")
        print(f"✅ 对话框已触发")
        return result
