use tauri::command;

// 日志命令子模块
pub mod log;

#[command]
pub fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}
