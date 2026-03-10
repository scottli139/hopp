import type { FC, ReactNode } from 'react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { Header } from './Header';
import { StatusBar } from './StatusBar';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface MainContentProps {
  /** Additional CSS classes */
  className?: string;
  /** Content to render */
  children: ReactNode;
  /** Header title */
  headerTitle?: string;
  /** On header close */
  onHeaderClose?: () => void;
  /** On header save */
  onHeaderSave?: () => void;
  /** Connection status for status bar */
  connectionStatus?: 'idle' | 'connecting' | 'connected' | 'error';
  /** Response metrics */
  responseTime?: number | null;
  statusCode?: number | null;
  responseSize?: number | null;
  /** Hide header */
  hideHeader?: boolean;
  /** Hide status bar */
  hideStatusBar?: boolean;
}

/**
 * MainContent component
 *
 * Main content area with optional header and status bar.
 *
 * @example
 * ```tsx
 * <MainContent
 *   headerTitle="GET https://api.example.com"
 *   connectionStatus="connected"
 *   responseTime={245}
 * >
 *   <RequestEditor />
 * </MainContent>
 * ```
 */
export const MainContent: FC<MainContentProps> = ({
  className,
  children,
  headerTitle,
  onHeaderClose,
  onHeaderSave,
  connectionStatus = 'idle',
  responseTime = null,
  statusCode = null,
  responseSize = null,
  hideHeader = false,
  hideStatusBar = false,
}) => {
  return (
    <div className={cn('flex flex-col h-full bg-bg-primary', className)}>
      {!hideHeader && (
        <Header
          title={headerTitle}
          onClose={onHeaderClose}
          onSave={onHeaderSave}
        />
      )}

      <div className="flex-1 overflow-hidden">
        {children}
      </div>

      {!hideStatusBar && (
        <StatusBar
          connectionStatus={connectionStatus}
          responseTime={responseTime}
          statusCode={statusCode}
          responseSize={responseSize}
        />
      )}
    </div>
  );
};

export default MainContent;
