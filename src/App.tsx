import type { FC } from 'react';
import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import logger from '@/utils/logger';
import { ResizablePanel, Sidebar, MainContent } from '@/components/layout';
import { RequestEditor, ResponseViewer, RequestTabs } from '@/components/request';
import { useRequestStore } from '@/stores/requestStore';

const App: FC = () => {
  const { t, i18n } = useTranslation();
  const { tabs, addTab, getActiveTab } = useRequestStore();

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

  // Add initial tab if none exists
  useEffect(() => {
    if (tabs.length === 0) {
      addTab({
        url: 'https://httpbin.org/get',
      });
    }
  }, [tabs.length, addTab]);

  const activeTab = getActiveTab();

  return (
    <div className="h-full w-full flex">
      {/* Resizable Sidebar */}
      <ResizablePanel
        minWidth={200}
        maxWidth={400}
        defaultWidth={260}
        storageKey="hopp-sidebar-width"
        className="flex-shrink-0"
      >
        <Sidebar />
      </ResizablePanel>

      {/* Main Content Area */}
      <div className="flex-1 min-w-0 flex flex-col">
        <MainContent
          headerTitle={activeTab?.name || t('app.name')}
          connectionStatus={activeTab?.isLoading ? 'connecting' : activeTab?.response ? 'connected' : 'idle'}
          responseTime={activeTab?.response?.time ?? null}
          statusCode={activeTab?.response?.status ?? null}
          responseSize={activeTab?.response?.size ?? null}
          hideHeader={true}
          hideStatusBar={false}
        >
          {/* Request Tabs */}
          <RequestTabs />

          {/* Split View: Request Editor + Response Viewer */}
          <div className="flex-1 flex overflow-hidden">
            {/* Request Editor */}
            <div className="flex-1 border-r border-border overflow-auto">
              <RequestEditor />
            </div>

            {/* Response Viewer */}
            <div className="flex-1 overflow-auto">
              <ResponseViewer />
            </div>
          </div>
        </MainContent>
      </div>
    </div>
  );
};

export default App;
