import type { FC } from 'react';
import { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useActiveTab } from '@/stores/requestStore';
import { formatSize, formatBody } from '@/services/httpService';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

// Icons
const TerminalIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
  </svg>
);

const ClockIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
  </svg>
);

const DatabaseIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
  </svg>
);

const CopyIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
  </svg>
);

const CheckIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
  </svg>
);

const LoaderIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={cn("animate-spin", className)} viewBox="0 0 24 24" fill="none">
    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
  </svg>
);

/**
 * Response viewer component with modern design
 */
export const ResponseViewer: FC = () => {
  const { t: _t } = useTranslation();
  const activeTab = useActiveTab();
  const [activeSection, setActiveSection] = useState<'body' | 'headers'>('body');
  const [copied, setCopied] = useState(false);

  // Hooks must be called before any conditional returns
  const response = activeTab?.response ?? null;
  const isLoading = activeTab?.isLoading ?? false;

  const formattedBody = useMemo(() => {
    if (!response) return '';
    return formatBody(response.body, response.contentType);
  }, [response?.body, response?.contentType]);

  const handleCopy = () => {
    if (!response) return;
    void navigator.clipboard.writeText(response.body);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const getStatusColor = (status: number): string => {
    if (status >= 200 && status < 300) return 'bg-green-50 text-green-700 border-green-200';
    if (status >= 300 && status < 400) return 'bg-amber-50 text-amber-700 border-amber-200';
    if (status >= 400) return 'bg-red-50 text-red-700 border-red-200';
    return 'bg-slate-50 text-slate-700 border-slate-200';
  };

  // Conditional rendering after all hooks
  if (!activeTab) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="empty-state">
          <TerminalIcon className="empty-state-icon" />
          <p className="empty-state-title">No Active Request</p>
          <p className="empty-state-description">Select a request from the sidebar or create a new one</p>
        </div>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="h-full flex flex-col items-center justify-center bg-bg-primary">
        <div className="text-center px-8">
          <LoaderIcon className="w-10 h-10 text-primary mb-4" />
          <h3 className="text-[15px] font-semibold text-text-primary mb-2">Sending Request...</h3>
          <p className="text-[13px] text-text-muted">Waiting for server response</p>
        </div>
      </div>
    );
  }

  if (!response) {
    return (
      <div className="h-full flex flex-col items-center justify-center bg-bg-primary">
        <div className="text-center px-8">
          <div className="w-16 h-16 mx-auto mb-5 rounded-2xl bg-bg-tertiary flex items-center justify-center">
            <TerminalIcon className="w-8 h-8 text-text-tertiary" />
          </div>
          <h3 className="text-[15px] font-semibold text-text-primary mb-2">No Response Yet</h3>
          <p className="text-[13px] text-text-muted max-w-[260px] leading-relaxed">
            Click the Send button to execute the request and see the response
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-bg-primary">
      {/* Response Info Bar */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-bg-secondary">
        <div className="flex items-center gap-6">
          {/* Status */}
          <div className="flex items-center gap-2">
            <span
              className={cn(
                'px-2.5 py-1 rounded-md text-[13px] font-bold border',
                getStatusColor(response.status)
              )}
            >
              {response.status}
            </span>
            <span className="text-[13px] text-text-secondary">{response.statusText}</span>
          </div>

          {/* Divider */}
          <div className="w-px h-4 bg-border-dark" />

          {/* Time */}
          <div className="flex items-center gap-1.5 text-[13px] text-text-secondary">
            <ClockIcon className="w-4 h-4 text-text-tertiary" />
            <span className="font-medium text-text-primary">{response.time} ms</span>
          </div>

          {/* Size */}
          <div className="flex items-center gap-1.5 text-[13px] text-text-secondary">
            <DatabaseIcon className="w-4 h-4 text-text-tertiary" />
            <span className="font-medium text-text-primary">{formatSize(response.size)}</span>
          </div>
        </div>

        {/* Copy Button */}
        <button
          onClick={handleCopy}
          className={cn(
            'flex items-center gap-2 px-3 py-1.5 rounded-md text-[13px] font-medium',
            'border border-border-dark',
            copied 
              ? 'bg-green-50 text-green-700 border-green-200' 
              : 'bg-bg-primary text-text-secondary hover:text-text-primary hover:border-text-tertiary',
            'transition-all duration-150'
          )}
        >
          {copied ? (
            <>
              <CheckIcon className="w-4 h-4" />
              <span>Copied!</span>
            </>
          ) : (
            <>
              <CopyIcon className="w-4 h-4" />
              <span>Copy</span>
            </>
          )}
        </button>
      </div>

      {/* Section Tabs */}
      <div className="flex items-center gap-1 px-4 border-b border-border bg-bg-secondary">
        {(['body', 'headers'] as const).map((section) => (
          <button
            key={section}
            onClick={() => setActiveSection(section)}
            className={cn(
              'relative px-4 py-2.5 text-[13px] font-medium',
              'transition-all duration-150',
              activeSection === section
                ? 'text-primary'
                : 'text-text-secondary hover:text-text-primary'
            )}
          >
            <span className="flex items-center gap-2">
              {section.charAt(0).toUpperCase() + section.slice(1)}
              {section === 'headers' && (
                <span className="px-1.5 py-0.5 text-[10px] font-semibold rounded-full bg-primary/10 text-primary">
                  {Object.keys(response.headers).length}
                </span>
              )}
            </span>
            {activeSection === section && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-t-full" />
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
                'font-mono text-[13px] leading-relaxed whitespace-pre-wrap break-all',
                'text-text-primary'
              )}
            >
              {formattedBody}
            </pre>
          </div>
        )}

        {activeSection === 'headers' && (
          <div className="p-4">
            <div className="border border-border rounded-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-bg-secondary">
                  <tr>
                    <th className="text-left py-2.5 px-4 text-[11px] font-semibold text-text-tertiary uppercase tracking-wider border-b border-border">
                      Header Name
                    </th>
                    <th className="text-left py-2.5 px-4 text-[11px] font-semibold text-text-tertiary uppercase tracking-wider border-b border-border">
                      Value
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(response.headers).map(([key, value], index) => (
                    <tr 
                      key={key} 
                      className={cn(
                        'border-b border-border last:border-b-0',
                        index % 2 === 0 ? 'bg-bg-primary' : 'bg-bg-secondary/50'
                      )}
                    >
                      <td className="py-2.5 px-4 text-[13px] font-medium text-text-primary">{key}</td>
                      <td className="py-2.5 px-4 text-[13px] text-text-secondary break-all">{value}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ResponseViewer;
