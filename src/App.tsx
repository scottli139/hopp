import { FC, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { invoke } from "@tauri-apps/api/core";
import type { Language } from './i18n';
import logger from './utils/logger';
import { LogViewer } from './components/LogViewer';

const App: FC = () => {
  const { t, i18n } = useTranslation();
  const [showLogs, setShowLogs] = useState(false);

  // 初始化日志系统
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

  const greet = async (): Promise<void> => {
    try {
      logger.debug('Calling greet command');
      const response = await invoke<string>("greet", { name: "Hopp" });
      logger.info('Greet command succeeded', { response });
    } catch (err) {
      logger.error('Greet command failed', err as Error);
    }
  };

  const toggleLanguage = (): void => {
    const newLang: Language = i18n.language === 'zh-CN' ? 'en' : 'zh-CN';
    logger.info('Switching language', { from: i18n.language, to: newLang });
    i18n.changeLanguage(newLang);
  };

  return (
    <main className="container">
      <h1>Welcome to {t('app.name')} 🐰</h1>
      <p>{t('app.tagline')}</p>
      <div style={{ marginTop: '1rem', display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
        <button onClick={greet}>Test Tauri</button>
        <button onClick={toggleLanguage}>
          {t('language.zhCN')} / {t('language.en')}
        </button>
        <button onClick={() => setShowLogs(!showLogs)}>
          {showLogs ? 'Hide Logs' : 'Show Logs'}
        </button>
      </div>
      
      {showLogs && (
        <div style={{ marginTop: '2rem', textAlign: 'left' }}>
          <LogViewer />
        </div>
      )}
    </main>
  );
};

export default App;
