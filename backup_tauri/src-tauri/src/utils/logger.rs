//! 日志工具模块
//! 提供 Rust 后端的日志记录功能，支持文件滚动和级别过滤

use std::path::PathBuf;
use tracing::{debug, error, info, trace, warn, Level};
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::{
    fmt::{self, time::ChronoLocal},
    layer::SubscriberExt,
    util::SubscriberInitExt,
    EnvFilter,
};

/// 日志配置
#[derive(Debug, Clone)]
pub struct LoggerConfig {
    /// 日志级别
    pub level: Level,
    /// 日志目录
    pub log_dir: PathBuf,
    /// 是否输出到控制台
    pub enable_console: bool,
    /// 是否输出到文件
    pub enable_file: bool,
    /// 日志文件滚动策略
    pub rotation: Rotation,
    /// 是否包含线程 ID
    pub with_thread_ids: bool,
}

impl Default for LoggerConfig {
    fn default() -> Self {
        Self {
            level: Level::DEBUG,
            log_dir: PathBuf::from("logs"),
            enable_console: true,
            enable_file: true,
            rotation: Rotation::DAILY,
            with_thread_ids: false,
        }
    }
}

/// 初始化日志系统
pub fn init_logger(config: Option<LoggerConfig>) -> Result<(), Box<dyn std::error::Error>> {
    let config = config.unwrap_or_default();

    // 创建环境过滤器
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(config.level.to_string()));

    // 创建格式化层
    let fmt_layer = fmt::layer()
        .with_timer(ChronoLocal::rfc_3339())
        .with_thread_ids(config.with_thread_ids)
        .with_target(true)
        .with_file(true)
        .with_line_number(true);

    // 根据配置组合不同的输出层
    if config.enable_console && config.enable_file {
        // 同时输出到控制台和文件
        let file_appender =
            RollingFileAppender::new(config.rotation.clone(), &config.log_dir, "hopp.log");

        let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);
        // 保存 guard 防止被丢弃
        std::mem::forget(_guard);

        let file_layer = fmt::layer()
            .with_writer(non_blocking)
            .with_timer(ChronoLocal::rfc_3339())
            .with_ansi(false)
            .with_target(true)
            .with_file(true)
            .with_line_number(true);

        tracing_subscriber::registry()
            .with(filter)
            .with(fmt_layer)
            .with(file_layer)
            .init();
    } else if config.enable_file {
        // 只输出到文件
        let file_appender =
            RollingFileAppender::new(config.rotation.clone(), &config.log_dir, "hopp.log");

        let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);
        std::mem::forget(_guard);

        let file_layer = fmt::layer()
            .with_writer(non_blocking)
            .with_timer(ChronoLocal::rfc_3339())
            .with_ansi(false)
            .with_target(true)
            .with_file(true)
            .with_line_number(true);

        tracing_subscriber::registry()
            .with(filter)
            .with(file_layer)
            .init();
    } else {
        // 只输出到控制台
        tracing_subscriber::registry()
            .with(filter)
            .with(fmt_layer)
            .init();
    }

    info!("Logger initialized successfully");
    debug!(?config, "Logger configuration");

    Ok(())
}

/// 初始化日志系统（使用应用目录）
pub fn init_logger_with_app_dir(
    app_dir: &PathBuf,
    level: Option<Level>,
) -> Result<(), Box<dyn std::error::Error>> {
    let log_dir = app_dir.join("logs");
    std::fs::create_dir_all(&log_dir)?;

    let config = LoggerConfig {
        level: level.unwrap_or(Level::DEBUG),
        log_dir,
        enable_console: true,
        enable_file: true,
        rotation: Rotation::DAILY,
        with_thread_ids: false,
    };

    init_logger(Some(config))
}

/// 日志宏包装函数
pub fn log_trace(message: &str, _target: Option<&str>) {
    trace!("{}", message);
}

pub fn log_debug(message: &str, _target: Option<&str>) {
    debug!("{}", message);
}

pub fn log_info(message: &str, _target: Option<&str>) {
    info!("{}", message);
}

pub fn log_warn(message: &str, _target: Option<&str>) {
    warn!("{}", message);
}

pub fn log_error(message: &str, _target: Option<&str>) {
    error!("{}", message);
}

/// 获取日志目录路径
pub fn get_log_dir(app_dir: &PathBuf) -> PathBuf {
    app_dir.join("logs")
}

/// 获取当前日志文件路径
pub fn get_current_log_file(app_dir: &PathBuf) -> PathBuf {
    let log_dir = get_log_dir(app_dir);
    // 根据滚动策略，当前文件可能是 hopp.log 或带日期的文件
    log_dir.join("hopp.log")
}

/// 列出所有日志文件
pub fn list_log_files(app_dir: &PathBuf) -> Result<Vec<PathBuf>, std::io::Error> {
    let log_dir = get_log_dir(app_dir);
    if !log_dir.exists() {
        return Ok(vec![]);
    }

    let mut files: Vec<PathBuf> = std::fs::read_dir(&log_dir)?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry
                .path()
                .extension()
                .map(|ext| ext == "log")
                .unwrap_or(false)
        })
        .map(|entry| entry.path())
        .collect();

    // 按修改时间排序
    files.sort_by(|a, b| {
        let meta_a = std::fs::metadata(a).ok();
        let meta_b = std::fs::metadata(b).ok();
        match (meta_a, meta_b) {
            (Some(ma), Some(mb)) => {
                let time_a = ma.modified().ok();
                let time_b = mb.modified().ok();
                time_b.cmp(&time_a) // 最新的在前
            }
            _ => std::cmp::Ordering::Equal,
        }
    });

    Ok(files)
}

/// 读取日志文件内容
pub fn read_log_file(path: &PathBuf) -> Result<String, std::io::Error> {
    std::fs::read_to_string(path)
}

/// 清理旧日志文件
pub fn cleanup_old_logs(
    app_dir: &PathBuf,
    keep_days: u32,
) -> Result<usize, Box<dyn std::error::Error>> {
    let log_dir = get_log_dir(app_dir);
    if !log_dir.exists() {
        return Ok(0);
    }

    let cutoff = std::time::SystemTime::now()
        - std::time::Duration::from_secs(keep_days as u64 * 24 * 60 * 60);

    let mut removed_count = 0;

    for entry in std::fs::read_dir(&log_dir)? {
        let entry = entry?;
        let path = entry.path();

        if path.extension().map(|ext| ext == "log").unwrap_or(false) {
            let metadata = entry.metadata()?;
            if let Ok(modified) = metadata.modified() {
                if modified < cutoff {
                    std::fs::remove_file(&path)?;
                    removed_count += 1;
                    info!("Removed old log file: {:?}", path);
                }
            }
        }
    }

    Ok(removed_count)
}

/// 获取日志文件大小（字节）
pub fn get_log_file_size(path: &PathBuf) -> Result<u64, std::io::Error> {
    let metadata = std::fs::metadata(path)?;
    Ok(metadata.len())
}

/// 日志统计信息
#[derive(Debug)]
pub struct LogStats {
    pub total_files: usize,
    pub total_size_bytes: u64,
    pub oldest_file: Option<PathBuf>,
    pub newest_file: Option<PathBuf>,
}

/// 获取日志统计信息
pub fn get_log_stats(app_dir: &PathBuf) -> Result<LogStats, std::io::Error> {
    let files = list_log_files(app_dir)?;
    let total_files = files.len();

    let mut total_size = 0u64;
    for file in &files {
        if let Ok(size) = get_log_file_size(file) {
            total_size += size;
        }
    }

    Ok(LogStats {
        total_files,
        total_size_bytes: total_size,
        oldest_file: files.last().cloned(),
        newest_file: files.first().cloned(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_get_log_dir() {
        let temp_dir = TempDir::new().unwrap();
        let log_dir = get_log_dir(&temp_dir.path().to_path_buf());
        assert!(log_dir.to_string_lossy().contains("logs"));
    }
}
