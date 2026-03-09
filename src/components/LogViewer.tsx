/**
 * 日志查看器组件
 * 用于查看和管理应用日志
 */

import React, { FC, useEffect, useState, useCallback } from 'react';
import * as logService from '../services/logService';
import type { LogStats } from '../services/logService';

interface LogFile {
  path: string;
  name: string;
}

export const LogViewer: FC = () => {
  const [logs, setLogs] = useState<string>('');
  const [files, setFiles] = useState<LogFile[]>([]);
  const [stats, setStats] = useState<LogStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [selectedFile, setSelectedFile] = useState<string>('');
  const [logDir, setLogDir] = useState<string>('');

  // 加载日志统计
  const loadStats = useCallback(async () => {
    try {
      const data = await logService.getLogStats();
      setStats(data);
    } catch (err) {
      console.error('Failed to load log stats:', err);
    }
  }, []);

  // 加载日志文件列表
  const loadFiles = useCallback(async () => {
    try {
      const [filePaths, dir] = await Promise.all([
        logService.listLogFiles(),
        logService.getLogDirectory(),
      ]);
      setLogDir(dir);
      setFiles(
        filePaths.map((path) => ({
          path,
          name: path.split(/[/\\]/).pop() || path,
        }))
      );
    } catch (err) {
      console.error('Failed to load log files:', err);
    }
  }, []);

  // 加载当前日志内容
  const loadCurrentLogs = useCallback(async () => {
    setLoading(true);
    try {
      const content = await logService.getCurrentLogContent();
      setLogs(content);
    } catch (err) {
      console.error('Failed to load logs:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // 加载指定日志文件
  const loadLogFile = async (path: string) => {
    setLoading(true);
    try {
      const content = await logService.readLogFile(path);
      setLogs(content);
      setSelectedFile(path);
    } catch (err) {
      console.error('Failed to read log file:', err);
    } finally {
      setLoading(false);
    }
  };

  // 清理旧日志
  const handleCleanup = async () => {
    if (!window.confirm('Keep logs from the last 7 days and delete the rest?')) {
      return;
    }
    try {
      const removed = await logService.cleanupLogs(7);
      alert(`Cleaned up ${removed} old log files`);
      void loadFiles();
      void loadStats();
    } catch (err) {
      console.error('Failed to cleanup logs:', err);
    }
  };

  // 导出日志
  const handleExport = async () => {
    try {
      const content = logs || (await logService.getCurrentLogContent());
      const blob = new Blob([content], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `hopp-export-${new Date().toISOString().split('T')[0]}.log`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Failed to export logs:', err);
    }
  };

  useEffect(() => {
    void loadStats();
    void loadFiles();
    void loadCurrentLogs();
  }, [loadStats, loadFiles, loadCurrentLogs]);

  // 解析日志条目用于显示
  const logLines = logs
    .split('\n')
    .filter((line) => line.trim())
    .slice(-100); // 只显示最后100行

  return (
    <div
      style={{
        padding: '20px',
        fontFamily: 'monospace',
        fontSize: '12px',
        backgroundColor: '#1a1a1a',
        color: '#e0e0e0',
        borderRadius: '8px',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '16px',
          flexWrap: 'wrap',
          gap: '8px',
        }}
      >
        <h3 style={{ margin: 0, color: '#fff' }}>📋 Application Logs</h3>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button
            onClick={loadCurrentLogs}
            style={buttonStyle}
            disabled={loading}
          >
            🔄 Refresh
          </button>
          <button onClick={handleExport} style={buttonStyle}>
            ⬇️ Export
          </button>
          <button onClick={handleCleanup} style={{ ...buttonStyle, backgroundColor: '#d32f2f' }}>
            🧹 Cleanup
          </button>
        </div>
      </div>

      {/* 统计信息 */}
      {stats && (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
            gap: '12px',
            marginBottom: '16px',
            padding: '12px',
            backgroundColor: '#2a2a2a',
            borderRadius: '4px',
          }}
        >
          <div>
            <div style={{ color: '#888', fontSize: '11px' }}>Total Files</div>
            <div style={{ fontSize: '16px', fontWeight: 'bold' }}>{stats.total_files}</div>
          </div>
          <div>
            <div style={{ color: '#888', fontSize: '11px' }}>Total Size</div>
            <div style={{ fontSize: '16px', fontWeight: 'bold' }}>
              {logService.formatFileSize(stats.total_size_bytes)}
            </div>
          </div>
          <div>
            <div style={{ color: '#888', fontSize: '11px' }}>Log Directory</div>
            <div style={{ fontSize: '11px', wordBreak: 'break-all' }}>{logDir}</div>
          </div>
        </div>
      )}

      {/* 日志文件列表 */}
      {files.length > 0 && (
        <div style={{ marginBottom: '16px' }}>
          <div style={{ color: '#888', marginBottom: '8px', fontSize: '11px' }}>Log Files:</div>
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            {files.map((file) => (
              <button
                key={file.path}
                onClick={() => loadLogFile(file.path)}
                style={{
                  ...fileButtonStyle,
                  backgroundColor: selectedFile === file.path ? '#1976d2' : '#3a3a3a',
                }}
              >
                {file.name}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* 日志内容 */}
      <div
        style={{
          backgroundColor: '#0a0a0a',
          padding: '12px',
          borderRadius: '4px',
          maxHeight: '400px',
          overflow: 'auto',
          whiteSpace: 'pre-wrap',
          wordBreak: 'break-all',
        }}
      >
        {loading ? (
          <div style={{ color: '#888', textAlign: 'center', padding: '40px' }}>Loading...</div>
        ) : logLines.length > 0 ? (
          logLines.map((line, index) => (
            <div
              key={index}
              style={{
                padding: '2px 0',
                borderBottom: '1px solid #222',
                color: getLogLineColor(line),
              }}
            >
              {highlightLogLevel(line)}
            </div>
          ))
        ) : (
          <div style={{ color: '#888', textAlign: 'center', padding: '40px' }}>No logs available</div>
        )}
      </div>
    </div>
  );
};

// 按钮样式
const buttonStyle: React.CSSProperties = {
  padding: '6px 12px',
  fontSize: '12px',
  backgroundColor: '#424242',
  color: '#fff',
  border: 'none',
  borderRadius: '4px',
  cursor: 'pointer',
};

// 文件按钮样式
const fileButtonStyle: React.CSSProperties = {
  padding: '4px 10px',
  fontSize: '11px',
  color: '#fff',
  border: 'none',
  borderRadius: '4px',
  cursor: 'pointer',
};

// 根据日志级别获取颜色
function getLogLineColor(line: string): string {
  if (line.includes('ERROR')) return '#ff5252';
  if (line.includes('WARN')) return '#ffb74d';
  if (line.includes('INFO')) return '#81c784';
  if (line.includes('DEBUG')) return '#64b5f6';
  if (line.includes('TRACE')) return '#90a4ae';
  return '#e0e0e0';
}

// 高亮日志级别
function highlightLogLevel(line: string): React.ReactNode {
  const levelMatch = line.match(/\s(ERROR|WARN|INFO|DEBUG|TRACE)\s/);
  if (!levelMatch) return line;

  const parts = line.split(levelMatch[1]);
  return (
    <>
      {parts[0]}
      <span
        style={{
          fontWeight: 'bold',
          backgroundColor: getLevelBackgroundColor(levelMatch[1]),
          padding: '0 4px',
          borderRadius: '2px',
        }}
      >
        {levelMatch[1]}
      </span>
      {parts[1]}
    </>
  );
}

function getLevelBackgroundColor(level: string): string {
  switch (level) {
    case 'ERROR':
      return '#d32f2f';
    case 'WARN':
      return '#f57c00';
    case 'INFO':
      return '#388e3c';
    case 'DEBUG':
      return '#1976d2';
    case 'TRACE':
      return '#616161';
    default:
      return '#424242';
  }
}

export default LogViewer;
