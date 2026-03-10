import type { FC } from 'react';
import { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useActiveTab } from '@/stores/requestStore';
import { formatSize, isSuccessStatus, formatBody } from '@/services/httpService';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/**
 * Response viewer component
 */
export const ResponseViewer: FC = () => {
  const { t } = useTranslation();
  const activeTab = useActiveTab();
  const [activeSection, setActiveSection] = useState<'body' | 'headers'>('body');

  if (!activeTab) {
    return (
      <div className="h-full flex items-center justify-center text-text-secondary">
        {t('response.noActiveTab', 'No active request')}
      </div>
    );
  }

  const { response, isLoading } = activeTab;

  if (isLoading) {
    return (
      <div className="h-full flex flex-col items-center justify-center text-text-secondary">
        <svg className="animate-spin h-8 w-8 mb-4" viewBox="0 0 24 24">
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
            fill="none"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
        <p>{t('response.loading', 'Loading...')}</p>
      </div>
    );
  }

  if (!response) {
    return (
      <div className="h-full flex flex-col items-center justify-center text-text-secondary">
        <svg
          className="w-16 h-16 mb-4 text-text-tertiary"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1}
            d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          />
        </svg>
        <p>{t('response.noResponse', 'Click Send to get a response')}</p>
      </div>
    );
  }

  const formattedBody = useMemo(() => {
    return formatBody(response.body, response.contentType);
  }, [response.body, response.contentType]);

  return (
    <div className="h-full flex flex-col">
      {/* Response Info Bar */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-border bg-bg-secondary">
        <div className="flex items-center gap-4">
          {/* Status */}
          <div className="flex items-center gap-2">
            <span
              className={cn(
                'px-2 py-1 rounded text-sm font-medium',
                isSuccessStatus(response.status)
                  ? 'bg-success/10 text-success'
                  : response.status >= 400
                  ? 'bg-error/10 text-error'
                  : 'bg-warning/10 text-warning'
              )}
            >
              {response.status} {response.statusText}
            </span>
          </div>

          {/* Time */}
          <div className="flex items-center gap-1 text-sm text-text-secondary">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span>{response.time} ms</span>
          </div>

          {/* Size */}
          <div className="flex items-center gap-1 text-sm text-text-secondary">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4"
              />
            </svg>
            <span>{formatSize(response.size)}</span>
          </div>
        </div>

        {/* Copy Button */}
        <button
          onClick={() => navigator.clipboard.writeText(response.body)}
          className={cn(
            'px-3 py-1.5 rounded-md text-sm',
            'bg-bg-primary border border-border-dark',
            'text-text-secondary hover:text-text-primary',
            'transition-colors'
          )}
        >
          {t('common.copy', 'Copy')}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex items-center border-b border-border">
        {(['body', 'headers'] as const).map((section) => (
          <button
            key={section}
            onClick={() => setActiveSection(section)}
            className={cn(
              'px-4 py-2 text-sm font-medium',
              'border-b-2 transition-colors',
              activeSection === section
                ? 'border-primary text-primary'
                : 'border-transparent text-text-secondary hover:text-text-primary'
            )}
          >
            {t(`response.${section}`, section.charAt(0).toUpperCase() + section.slice(1))}
            {section === 'headers' && (
              <span className="ml-1 px-1.5 py-0.5 text-xs bg-primary/10 text-primary rounded-full">
                {Object.keys(response.headers).length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto">
        {activeSection === 'body' && (
          <div className="p-4">
            <pre
              className={cn(
                'font-mono text-sm whitespace-pre-wrap break-all',
                'text-text-primary'
              )}
            >
              {formattedBody}
            </pre>
          </div>
        )}

        {activeSection === 'headers' && (
          <div className="p-4">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-2 px-3 text-sm font-medium text-text-secondary">
                    {t('response.headerName', 'Header Name')}
                  </th>
                  <th className="text-left py-2 px-3 text-sm font-medium text-text-secondary">
                    {t('response.headerValue', 'Value')}
                  </th>
                </tr>
              </thead>
              <tbody>
                {Object.entries(response.headers).map(([key, value]) => (
                  <tr key={key} className="border-b border-border hover:bg-bg-secondary">
                    <td className="py-2 px-3 text-sm font-medium text-text-primary">{key}</td>
                    <td className="py-2 px-3 text-sm text-text-secondary break-all">{value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default ResponseViewer;
