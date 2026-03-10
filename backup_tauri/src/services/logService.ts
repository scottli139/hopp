/**
 * 日志服务
 * 与 Rust 后端日志系统交互
 */

import { invoke } from '@tauri-apps/api/core';

// 日志统计响应接口
export interface LogStats {
  total_files: number;
  total_size_bytes: number;
  total_size_mb: number;
  oldest_file: string | null;
  newest_file: string | null;
}

/**
 * 获取日志目录路径
 */
export async function getLogDirectory(): Promise<string> {
  return invoke<string>('get_log_directory');
}

/**
 * 列出所有日志文件
 */
export async function listLogFiles(): Promise<string[]> {
  return invoke<string[]>('list_log_files');
}

/**
 * 读取日志文件内容
 */
export async function readLogFile(path: string): Promise<string> {
  return invoke<string>('read_log_file', { path });
}

/**
 * 获取当前日志文件内容
 */
export async function getCurrentLogContent(): Promise<string> {
  return invoke<string>('get_current_log_content');
}

/**
 * 清理旧日志文件
 * @param keepDays 保留最近几天的日志
 */
export async function cleanupLogs(keepDays: number): Promise<number> {
  return invoke<number>('cleanup_logs', { keep_days: keepDays });
}

/**
 * 导出日志（获取日志文件路径列表）
 */
export async function exportLogs(): Promise<string[]> {
  return invoke<string[]>('export_logs');
}

/**
 * 获取日志统计信息
 */
export async function getLogStats(): Promise<LogStats> {
  return invoke<LogStats>('get_log_stats');
}

/**
 * 写入日志到后端
 */
export async function writeLog(
  level: 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR',
  message: string,
  target?: string
): Promise<void> {
  return invoke('write_log', { level, message, target });
}

/**
 * 下载日志文件
 */
export async function downloadLogFile(path: string): Promise<Blob> {
  const content = await readLogFile(path);
  return new Blob([content], { type: 'text/plain' });
}

/**
 * 格式化文件大小
 */
export function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
}

/**
 * 格式化日期
 */
export function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleString();
}

// 默认导出
export default {
  getLogDirectory,
  listLogFiles,
  readLogFile,
  getCurrentLogContent,
  cleanupLogs,
  exportLogs,
  getLogStats,
  writeLog,
  downloadLogFile,
  formatFileSize,
  formatDate,
};
