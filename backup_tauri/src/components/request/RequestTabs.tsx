import type { FC } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useRequestStore } from '@/stores/requestStore';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

const PlusIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
  </svg>
);

const CloseIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
  </svg>
);

/**
 * Request tabs component with modern design
 */
export const RequestTabs: FC = () => {
  const { t } = useTranslation();
  const { tabs, activeTabId, setActiveTab, closeTab, addTab } = useRequestStore();

  const handleAddTab = (): void => {
    addTab();
  };

  // Method badge colors
  const getMethodColor = (method: string): string => {
    switch (method) {
      case 'GET':
        return 'text-green-600 bg-green-50';
      case 'POST':
        return 'text-blue-600 bg-blue-50';
      case 'PUT':
        return 'text-amber-600 bg-amber-50';
      case 'DELETE':
        return 'text-red-600 bg-red-50';
      case 'PATCH':
        return 'text-purple-600 bg-purple-50';
      default:
        return 'text-slate-600 bg-slate-50';
    }
  };

  return (
    <div className="flex items-center bg-bg-secondary border-b border-border h-[41px]">
      {/* Tab List */}
      <div className="flex items-center flex-1 overflow-x-auto scrollbar-hide h-full">
        {tabs.map((tab) => (
          <div
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'group relative flex items-center gap-2 px-4 h-full min-w-[140px] max-w-[220px]',
              'border-r border-border cursor-pointer select-none',
              'transition-all duration-150',
              activeTabId === tab.id
                ? 'bg-bg-primary'
                : 'hover:bg-bg-tertiary'
            )}
          >
            {/* Active Indicator */}
            {activeTabId === tab.id && (
              <div className="absolute top-0 left-0 right-0 h-[2px] bg-primary" />
            )}

            {/* Method Badge */}
            <span
              className={cn(
                'flex-shrink-0 px-1.5 py-0 text-[10px] font-bold rounded leading-5',
                getMethodColor(tab.request.method)
              )}
            >
              {tab.request.method}
            </span>

            {/* Tab Name */}
            <span
              className={cn(
                'flex-1 text-[13px] truncate min-w-0 leading-5',
                activeTabId === tab.id ? 'text-text-primary font-medium' : 'text-text-secondary'
              )}
            >
              {tab.name}
            </span>

            {/* Unsaved Indicator */}
            {!tab.response && activeTabId === tab.id && (
              <span className="w-1.5 h-1.5 rounded-full bg-primary flex-shrink-0" />
            )}

            {/* Close Button */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                closeTab(tab.id);
              }}
              className={cn(
                'flex-shrink-0 p-1 rounded',
                'text-text-tertiary hover:text-error hover:bg-error/10',
                'opacity-0 group-hover:opacity-100',
                'transition-all duration-150'
              )}
            >
              <CloseIcon className="w-3.5 h-3.5" />
            </button>
          </div>
        ))}
      </div>

      {/* Add Tab Button */}
      <button
        onClick={handleAddTab}
        className={cn(
          'flex-shrink-0 mx-2 p-1.5 rounded-md',
          'text-text-tertiary hover:text-text-primary hover:bg-bg-tertiary',
          'transition-all duration-150'
        )}
        title={t('request.newRequest', 'New Request')}
      >
        <PlusIcon className="w-4 h-4" />
      </button>
    </div>
  );
};

export default RequestTabs;
