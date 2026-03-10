/**
 * 日志工具模块
 * 提供前端日志记录功能，支持日志级别控制和持久化
 */

import log from 'loglevel';

// 日志级别枚举
export enum LogLevel {
  TRACE = 0,
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  SILENT = 5,
}

// 日志条目接口
export interface LogEntry {
  timestamp: string;
  level: string;
  message: string;
  context?: Record<string, unknown>;
  error?: Error;
}

// 日志配置接口
export interface LoggerConfig {
  level: LogLevel;
  enableConsole: boolean;
  enableStorage: boolean;
  maxStorageEntries: number;
  prefix?: string;
}

// 默认配置
const DEFAULT_CONFIG: LoggerConfig = {
  level: LogLevel.DEBUG,
  enableConsole: true,
  enableStorage: true,
  maxStorageEntries: 1000,
};

// 内存中的日志缓存
const logCache: LogEntry[] = [];

// 当前配置
let currentConfig: LoggerConfig = { ...DEFAULT_CONFIG };

// 初始化日志系统
export function initLogger(config: Partial<LoggerConfig> = {}): void {
  currentConfig = { ...DEFAULT_CONFIG, ...config };
  
  // 设置 loglevel
  const levelMap: Record<LogLevel, log.LogLevelDesc> = {
    [LogLevel.TRACE]: 'trace',
    [LogLevel.DEBUG]: 'debug',
    [LogLevel.INFO]: 'info',
    [LogLevel.WARN]: 'warn',
    [LogLevel.ERROR]: 'error',
    [LogLevel.SILENT]: 'silent',
  };
  
  log.setLevel(levelMap[currentConfig.level] || 'debug');
  
  // 添加前缀方法
  if (currentConfig.prefix) {
    log.setLevel(log.getLevel(), false);
  }
  
  info('Logger initialized', { config: currentConfig });
}

// 创建日志条目
function createLogEntry(
  level: string,
  message: string,
  context?: Record<string, unknown>,
  error?: Error
): LogEntry {
  return {
    timestamp: new Date().toISOString(),
    level,
    message,
    context,
    error: error ? {
      name: error.name,
      message: error.message,
      stack: error.stack,
    } as Error : undefined,
  };
}

// 存储日志到内存缓存
function storeLog(entry: LogEntry): void {
  if (!currentConfig.enableStorage) return;
  
  logCache.push(entry);
  
  // 限制缓存大小
  if (logCache.length > currentConfig.maxStorageEntries) {
    logCache.shift();
  }
  
  // 同时存储到 localStorage（可选）
  try {
    const key = 'hopp_logs';
    const existing = localStorage.getItem(key);
    const logs = existing ? JSON.parse(existing) : [];
    logs.push(entry);
    
    // 限制 localStorage 中的日志数量
    if (logs.length > currentConfig.maxStorageEntries) {
      logs.shift();
    }
    
    localStorage.setItem(key, JSON.stringify(logs));
  } catch {
    // localStorage 可能不可用或已满
  }
}

// 格式化日志消息
function formatMessage(message: string, context?: Record<string, unknown>): string {
  const prefix = currentConfig.prefix ? `[${currentConfig.prefix}] ` : '';
  const contextStr = context ? ` ${JSON.stringify(context)}` : '';
  return `${prefix}${message}${contextStr}`;
}

// 日志方法
export function trace(message: string, context?: Record<string, unknown>): void {
  const entry = createLogEntry('TRACE', message, context);
  storeLog(entry);
  log.trace(formatMessage(message, context));
}

export function debug(message: string, context?: Record<string, unknown>): void {
  const entry = createLogEntry('DEBUG', message, context);
  storeLog(entry);
  log.debug(formatMessage(message, context));
}

export function info(message: string, context?: Record<string, unknown>): void {
  const entry = createLogEntry('INFO', message, context);
  storeLog(entry);
  log.info(formatMessage(message, context));
}

export function warn(message: string, context?: Record<string, unknown>): void {
  const entry = createLogEntry('WARN', message, context);
  storeLog(entry);
  log.warn(formatMessage(message, context));
}

export function error(
  message: string,
  error?: Error,
  context?: Record<string, unknown>
): void {
  const entry = createLogEntry('ERROR', message, context, error);
  storeLog(entry);
  
  const errorContext = error ? { ...context, error: error.message, stack: error.stack } : context;
  log.error(formatMessage(message, errorContext));
}

// 获取所有日志
export function getLogs(): LogEntry[] {
  return [...logCache];
}

// 从 localStorage 获取日志
export function getStoredLogs(): LogEntry[] {
  try {
    const stored = localStorage.getItem('hopp_logs');
    return stored ? JSON.parse(stored) : [];
  } catch {
    return [];
  }
}

// 清空日志
export function clearLogs(): void {
  logCache.length = 0;
  try {
    localStorage.removeItem('hopp_logs');
  } catch {
    // ignore
  }
  info('Logs cleared');
}

// 导出日志为字符串
export function exportLogs(): string {
  const logs = getStoredLogs();
  return logs.map(entry => {
    const contextStr = entry.context ? ` | ${JSON.stringify(entry.context)}` : '';
    const errorStr = entry.error ? ` | ERROR: ${entry.error.message}` : '';
    return `[${entry.timestamp}] ${entry.level}: ${entry.message}${contextStr}${errorStr}`;
  }).join('\n');
}

// 导出日志为 JSON
export function exportLogsJSON(): string {
  return JSON.stringify(getStoredLogs(), null, 2);
}

// 下载日志文件
export function downloadLogs(filename?: string): void {
  const content = exportLogs();
  const blob = new Blob([content], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename || `hopp-logs-${new Date().toISOString().split('T')[0]}.txt`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
  
  info('Logs downloaded', { filename: link.download });
}

// 获取日志统计
export function getLogStats(): {
  total: number;
  byLevel: Record<string, number>;
  timeRange: { start: string | null; end: string | null };
} {
  const logs = getStoredLogs();
  const byLevel: Record<string, number> = {};
  
  logs.forEach(log => {
    byLevel[log.level] = (byLevel[log.level] || 0) + 1;
  });
  
  return {
    total: logs.length,
    byLevel,
    timeRange: {
      start: logs[0]?.timestamp || null,
      end: logs[logs.length - 1]?.timestamp || null,
    },
  };
}

// 重新初始化（用于配置变更）
export function setLogLevel(level: LogLevel): void {
  currentConfig.level = level;
  initLogger(currentConfig);
}

// 默认导出
export default {
  init: initLogger,
  trace,
  debug,
  info,
  warn,
  error,
  getLogs,
  getStoredLogs,
  clearLogs,
  exportLogs,
  exportLogsJSON,
  downloadLogs,
  getLogStats,
  setLogLevel,
  LogLevel,
};
