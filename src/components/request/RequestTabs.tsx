import type { FC } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useRequestStore } from '@/stores/requestStore';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/**
 * Request tabs component
 */
export const RequestTabs: FC = () => {
  const { t } = useTranslation();
  const { tabs, activeTabId, setActiveTab, closeTab, addTab } = useRequestStore();

  const handleAddTab = (): void => {
    addTab();
  };

  return (
    <div className="flex items-center border-b border-border bg-bg-secondary overflow-x-auto">
      {/* Tab List */}
      <div className="flex items-center flex-1">
        {tabs.map((tab) => (
          <div
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'group flex items-center gap-2 px-4 py-2 min-w-[120px] max-w-[200px]',
              'border-r border-border cursor-pointer select-none',
              'transition-colors',
              activeTabId === tab.id
                ? 'bg-bg-primary text-text-primary'
                : 'bg-bg-secondary text-text-secondary hover:bg-bg-tertiary'
            )}
          >
            {/* Method Badge */}
            <span
              className={cn(
                'text-xs font-medium',
                tab.request.method === 'GET' && 'text-green-500',
                tab.request.method === 'POST' && 'text-blue-500',
                tab.request.method === 'PUT' && 'text-yellow-500',
                tab.request.method === 'DELETE' && 'text-red-500',
                tab.request.method === 'PATCH' && 'text-purple-500'
              )}
            >
              {tab.request.method}
            </span>

            {/* Tab Name */}
            <span className="flex-1 text-sm truncate">{tab.name}</span>

            {/* Close Button */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                closeTab(tab.id);
              }}
              className={cn(
                'opacity-0 group-hover:opacity-100 p-0.5 rounded',
                'hover:bg-error/10 hover:text-error',
                'transition-all'
              )}
            >
              <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        ))}
      </div>

      {/* Add Tab Button */}
      <button
        onClick={handleAddTab}
        className={cn(
          'flex-shrink-0 p-2 m-1 rounded-md',
          'text-text-secondary hover:text-text-primary hover:bg-bg-tertiary',
          'transition-colors'
        )}
        title={t('request.newRequest', 'New Request')}
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
        </svg>
      </button>
    </div>
  );
};

export default RequestTabs;
