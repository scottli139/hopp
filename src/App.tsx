import type { FC } from 'react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Language } from './i18n';
import logger from './utils/logger';
import { LogViewer } from './components/LogViewer';
import { ResizablePanel, Sidebar, MainContent } from './components/layout';

const App: FC = () => {
  const { t, i18n } = useTranslation();
  const [showLogs, setShowLogs] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<'idle' | 'connecting' | 'connected' | 'error'>('idle');

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

  const toggleLanguage = (): void => {
    const newLang: Language = i18n.language === 'zh-CN' ? 'en' : 'zh-CN';
    logger.info('Switching language', { from: i18n.language, to: newLang });
    void i18n.changeLanguage(newLang);
  };

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
      <div className="flex-1 min-w-0">
        <MainContent
          headerTitle={t('app.welcome', 'Welcome to Hopp')}
          connectionStatus={connectionStatus}
          onHeaderClose={() => logger.info('Close tab clicked')}
          onHeaderSave={() => logger.info('Save request clicked')}
        >
          <div className="h-full flex flex-col p-4 overflow-auto">
            {/* Welcome Content */}
            <div className="flex-1 flex flex-col items-center justify-center gap-4">
              <h1 className="text-3xl font-bold text-text-primary">
                {t('app.name')} 🐰
              </h1>
              <p className="text-text-secondary text-lg">
                {t('app.tagline')}
              </p>

              <div className="flex gap-3 mt-4">
                <button
                  onClick={toggleLanguage}
                  className="px-4 py-2 text-sm font-medium rounded-md bg-bg-secondary text-text-primary hover:bg-bg-tertiary transition-colors"
                >
                  {t('language.zhCN')} / {t('language.en')}
                </button>

                <button
                  onClick={() => setShowLogs(!showLogs)}
                  className="px-4 py-2 text-sm font-medium rounded-md bg-bg-secondary text-text-primary hover:bg-bg-tertiary transition-colors"
                >
                  {showLogs ? t('logs.hide', 'Hide Logs') : t('logs.show', 'Show Logs')}
                </button>

                <button
                  onClick={() => {
                    setConnectionStatus('connecting');
                    setTimeout(() => {
                      setConnectionStatus('connected');
                    }, 1000);
                  }}
                  className="px-4 py-2 text-sm font-medium rounded-md bg-primary text-white hover:bg-primary-hover transition-colors"
                >
                  {t('app.testConnection', 'Test Connection')}
                </button>
              </div>

              {showLogs && (
                <div className="w-full max-w-3xl mt-6">
                  <LogViewer />
                </div>
              )}
            </div>
          </div>
        </MainContent>
      </div>
    </div>
  );
};

export default App;
