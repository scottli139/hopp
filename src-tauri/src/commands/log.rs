//! 日志相关命令
//! 提供前端访问日志功能的接口

use crate::utils::logger;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

/// 获取日志目录路径
#[tauri::command]
pub fn get_log_directory(app: AppHandle) -> Result<String, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    let log_dir = logger::get_log_dir(&app_dir);
    Ok(log_dir.to_string_lossy().to_string())
}

/// 列出所有日志文件
#[tauri::command]
pub fn list_log_files(app: AppHandle) -> Result<Vec<String>, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    let files = logger::list_log_files(&app_dir).map_err(|e| e.to_string())?;
    Ok(files
        .into_iter()
        .map(|p| p.to_string_lossy().to_string())
        .collect())
}

/// 读取日志文件内容
#[tauri::command]
pub fn read_log_file(path: String) -> Result<String, String> {
    let path = PathBuf::from(path);
    logger::read_log_file(&path).map_err(|e| e.to_string())
}

/// 获取当前日志文件内容
#[tauri::command]
pub fn get_current_log_content(app: AppHandle) -> Result<String, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    let log_file = logger::get_current_log_file(&app_dir);

    if !log_file.exists() {
        return Ok(String::new());
    }

    logger::read_log_file(&log_file).map_err(|e| e.to_string())
}

/// 清理旧日志文件
#[tauri::command]
pub fn cleanup_logs(app: AppHandle, keep_days: u32) -> Result<usize, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    logger::cleanup_old_logs(&app_dir, keep_days).map_err(|e| e.to_string())
}

/// 导出日志（返回日志文件路径列表）
#[tauri::command]
pub fn export_logs(app: AppHandle) -> Result<Vec<String>, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    let files = logger::list_log_files(&app_dir).map_err(|e| e.to_string())?;
    Ok(files
        .into_iter()
        .map(|p| p.to_string_lossy().to_string())
        .collect())
}

/// 获取日志统计信息
#[tauri::command]
pub fn get_log_stats(app: AppHandle) -> Result<LogStatsResponse, String> {
    let app_dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to get app dir: {}", e))?;

    let stats = logger::get_log_stats(&app_dir).map_err(|e| e.to_string())?;

    Ok(LogStatsResponse {
        total_files: stats.total_files,
        total_size_bytes: stats.total_size_bytes,
        total_size_mb: (stats.total_size_bytes as f64 / 1024.0 / 1024.0 * 100.0).round() / 100.0,
        oldest_file: stats.oldest_file.map(|p| p.to_string_lossy().to_string()),
        newest_file: stats.newest_file.map(|p| p.to_string_lossy().to_string()),
    })
}

/// 日志统计响应
#[derive(serde::Serialize)]
pub struct LogStatsResponse {
    pub total_files: usize,
    pub total_size_bytes: u64,
    pub total_size_mb: f64,
    pub oldest_file: Option<String>,
    pub newest_file: Option<String>,
}

/// 写入日志（从前端调用）
#[tauri::command]
pub fn write_log(level: String, message: String, target: Option<String>) {
    match level.as_str() {
        "TRACE" => crate::utils::logger::log_trace(&message, target.as_deref()),
        "DEBUG" => crate::utils::logger::log_debug(&message, target.as_deref()),
        "INFO" => crate::utils::logger::log_info(&message, target.as_deref()),
        "WARN" => crate::utils::logger::log_warn(&message, target.as_deref()),
        "ERROR" => crate::utils::logger::log_error(&message, target.as_deref()),
        _ => crate::utils::logger::log_info(&message, target.as_deref()),
    }
}
