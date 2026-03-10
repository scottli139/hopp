use tauri::command;

// 日志命令子模块
pub mod log;

// HTTP 命令子模块
pub mod http;

#[command]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}
