mod commands;
mod utils;

use tauri::Manager;
use tracing::info;

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // 初始化日志系统
            let app_handle = app.handle();
            let app_dir = app_handle.path().app_data_dir()?;
            std::fs::create_dir_all(&app_dir)?;

            if let Err(e) = utils::logger::init_logger_with_app_dir(&app_dir, None) {
                eprintln!("Failed to initialize logger: {}", e);
            } else {
                info!("Hopp application started");
                info!("App directory: {:?}", app_dir);
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::greet,
            commands::log::get_log_directory,
            commands::log::list_log_files,
            commands::log::read_log_file,
            commands::log::get_current_log_content,
            commands::log::cleanup_logs,
            commands::log::export_logs,
            commands::log::get_log_stats,
            commands::log::write_log,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
