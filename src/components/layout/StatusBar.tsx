import { FC } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface StatusBarProps {
  /** Additional CSS classes */
  className?: string;
  /** Connection status */
  connectionStatus?: 'idle' | 'connecting' | 'connected' | 'error';
  /** Response time in ms */
  responseTime?: number | null;
  /** Response status code */
  statusCode?: number | null;
  /** Response size in bytes */
  responseSize?: number | null;
}

/**
 * Format bytes to human readable string
 */
function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / k ** i).toFixed(2))} ${sizes[i]}`;
}

/**
 * StatusBar component
 *
 * Bottom status bar showing connection info and response metrics.
 *
 * @example
 * ```tsx
 * <StatusBar
 *   connectionStatus="connected"
 *   responseTime={245}
 *   statusCode={200}
 *   responseSize={1024}
 * />
 * ```
 */
export const StatusBar: FC<StatusBarProps> = ({
  className,
  connectionStatus = 'idle',
  responseTime = null,
  statusCode = null,
  responseSize = null,
}) => {
  const { t } = useTranslation();

  const getStatusColor = (status: number): string => {
    if (status >= 200 && status < 300) return 'text-success';
    if (status >= 300 && status < 400) return 'text-warning';
    if (status >= 400) return 'text-error';
    return 'text-text-secondary';
  };

  const getConnectionStatusText = (): string => {
    switch (connectionStatus) {
      case 'idle':
        return t('statusBar.idle', 'Idle');
      case 'connecting':
        return t('statusBar.connecting', 'Connecting...');
      case 'connected':
        return t('statusBar.ready', 'Ready');
      case 'error':
        return t('statusBar.error', 'Error');
      default:
        return '';
    }
  };

  return (
    <footer
      className={cn(
        'h-[28px] flex items-center justify-between px-3 text-xs',
        'bg-statusbar-bg border-t border-border',
        className
      )}
    >
      {/* Left: Connection status */}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-1.5">
          <span
            className={cn(
              'w-2 h-2 rounded-full',
              connectionStatus === 'idle' && 'bg-text-tertiary',
              connectionStatus === 'connecting' && 'bg-warning animate-pulse',
              connectionStatus === 'connected' && 'bg-success',
              connectionStatus === 'error' && 'bg-error'
            )}
          />
          <span className="text-text-secondary">{getConnectionStatusText()}</span>
        </div>

        {connectionStatus === 'connected' && (
          <>
            {statusCode !== null && (
              <div className="flex items-center gap-1">
                <span className="text-text-tertiary">{t('statusBar.status', 'Status')}:</span>
                <span className={cn('font-medium', getStatusColor(statusCode))}>
                  {statusCode}
                </span>
              </div>
            )}

            {responseTime !== null && (
              <div className="flex items-center gap-1">
                <span className="text-text-tertiary">{t('statusBar.time', 'Time')}:</span>
                <span className="font-medium text-text-primary">{responseTime} ms</span>
              </div>
            )}

            {responseSize !== null && (
              <div className="flex items-center gap-1">
                <span className="text-text-tertiary">{t('statusBar.size', 'Size')}:</span>
                <span className="font-medium text-text-primary">{formatBytes(responseSize)}</span>
              </div>
            )}
          </>
        )}
      </div>

      {/* Right: Info */}
      <div className="flex items-center gap-3 text-text-tertiary">
        <span>Hopp v0.1.0</span>
        <span className="w-px h-3 bg-border" />
        <span>Tauri 2.x</span>
        <span className="w-px h-3 bg-border" />
        <span>React 18</span>
      </div>
    </footer>
  );
};

export default StatusBar;
