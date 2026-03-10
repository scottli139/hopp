import type { FC } from 'react';
import { useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import logger from '@/utils/logger';
import { ResizablePanel, Sidebar } from '@/components/layout';
import { RequestEditor, ResponseViewer, RequestTabs } from '@/components/request';
import { useRequestStore } from '@/stores/requestStore';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

const App: FC = () => {
  const { i18n } = useTranslation();
  const { tabs, addTab, getActiveTab } = useRequestStore();
  const initialized = useRef(false);

  // Initialize logging system
  useEffect(() => {
    logger.init({
      level: logger.LogLevel.DEBUG,
      enableConsole: true,
      enableStorage: true,
      maxStorageEntries: 500,
      prefix: 'Hopp',
    });

    logger.info('Application initialized', {
      version: '0.1.0',
      language: i18n.language,
    });
  }, [i18n.language]);

  // Add initial tab if none exists (only once)
  useEffect(() => {
    if (!initialized.current && tabs.length === 0) {
      initialized.current = true;
      addTab({
        url: 'https://httpbin.org/get',
      });
    }
  }, [tabs.length, addTab]);

  const activeTab = getActiveTab();

  return (
    <div className="h-full w-full flex bg-bg-primary">
      {/* Resizable Sidebar */}
      <ResizablePanel
        minWidth={200}
        maxWidth={320}
        defaultWidth={240}
        storageKey="hopp-sidebar-width"
        className="flex-shrink-0"
      >
        <Sidebar />
      </ResizablePanel>

      {/* Main Content Area */}
      <div className="flex-1 min-w-0 flex flex-col">
        {/* Request Tabs */}
        <RequestTabs />

        {/* Split View: Request Editor + Response Viewer */}
        <div className="flex-1 flex overflow-hidden">
          {/* Request Editor */}
          <div className="w-1/2 min-w-0 border-r border-border">
            <RequestEditor />
          </div>

          {/* Response Viewer */}
          <div className="w-1/2 min-w-0">
            <ResponseViewer />
          </div>
        </div>

        {/* Status Bar */}
        <div className="h-7 flex items-center justify-between px-4 border-t border-border bg-bg-secondary">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2 text-[11px] text-text-muted">
              <span className={cn(
                'w-1.5 h-1.5 rounded-full',
                activeTab?.isLoading ? 'bg-amber-400 animate-pulse' : 
                activeTab?.response ? 'bg-green-500' : 'bg-slate-400'
              )} />
              <span className="font-medium">
                {activeTab?.isLoading ? 'Sending...' : activeTab?.response ? 'Ready' : 'Idle'}
              </span>
            </span>
            {activeTab?.response && (
              <>
                <span className="text-[11px] text-text-muted">
                  <span className="font-medium text-text-secondary">{activeTab.response.status}</span>
                  {' '}{activeTab.response.statusText}
                </span>
                <span className="text-[11px] text-text-muted">
                  <span className="font-medium text-text-secondary">{activeTab.response.time}ms</span>
                </span>
              </>
            )}
          </div>
          <div className="flex items-center gap-3 text-[11px] text-text-muted">
            <span>Hopp v0.1.0</span>
            <span className="text-border-dark">|</span>
            <span>Tauri 2.x</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
