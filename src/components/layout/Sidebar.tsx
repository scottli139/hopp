import React, { FC, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface SidebarProps {
  /** Additional CSS classes */
  className?: string;
  /** Sidebar width */
  width?: number;
}

/**
 * SidebarItem interface
 */
interface SidebarItemProps {
  icon?: React.ReactNode;
  label: string;
  active?: boolean;
  onClick?: () => void;
  children?: React.ReactNode;
}

/**
 * SidebarItem component
 */
const SidebarItem: FC<SidebarItemProps> = ({ icon, label, active, onClick, children }) => {
  const [expanded, setExpanded] = useState(false);
  const hasChildren = Boolean(children);

  return (
    <div className="select-none">
      <button
        onClick={() => {
          if (hasChildren) {
            setExpanded(!expanded);
          }
          onClick?.();
        }}
        className={cn(
          'w-full flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors',
          'hover:bg-bg-tertiary',
          active ? 'bg-bg-tertiary text-primary font-medium' : 'text-text-secondary'
        )}
      >
        {icon && <span className="flex-shrink-0 w-4 h-4">{icon}</span>}
        <span className="flex-1 text-left truncate">{label}</span>
        {hasChildren && (
          <svg
            className={cn(
              'w-4 h-4 transition-transform',
              expanded && 'rotate-90'
            )}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        )}
      </button>
      {hasChildren && expanded && (
        <div className="ml-4 mt-1 space-y-1">
          {children}
        </div>
      )}
    </div>
  );
};

/**
 * SidebarSection component
 */
interface SidebarSectionProps {
  title?: string;
  children: React.ReactNode;
}

const SidebarSection: FC<SidebarSectionProps> = ({ title, children }) => (
  <div className="mb-4">
    {title && (
      <h3 className="px-3 py-2 text-xs font-semibold text-text-tertiary uppercase tracking-wider">
        {title}
      </h3>
    )}
    <div className="space-y-1">
      {children}
    </div>
  </div>
);

/**
 * Sidebar component
 *
 * Main navigation sidebar for the application.
 *
 * @example
 * ```tsx
 * <Sidebar width={260} />
 * ```
 */
export const Sidebar: FC<SidebarProps> = ({ className, width }) => {
  const { t } = useTranslation();
  const [activeItem, setActiveItem] = useState('history');

  return (
    <aside
      className={cn(
        'h-full flex flex-col bg-sidebar-bg border-r border-sidebar-border',
        className
      )}
      style={{ width: width ? `${width}px` : undefined }}
    >
      {/* Logo/Brand */}
      <div className="h-[48px] flex items-center px-4 border-b border-sidebar-border">
        <h1 className="text-lg font-bold text-primary">{t('app.name')}</h1>
        <span className="ml-2 text-xs text-text-tertiary">v0.1.0</span>
      </div>

      {/* Main Navigation */}
      <div className="flex-1 overflow-y-auto p-3">
        <SidebarSection title={t('sidebar.collections', 'Collections')}>
          <SidebarItem
            icon={
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
              </svg>
            }
            label={t('sidebar.defaultCollection', 'Default Collection')}
            active={activeItem === 'default'}
            onClick={() => setActiveItem('default')}
          >
            <SidebarItem
              label={t('sidebar.getUsers', 'GET Users')}
              active={activeItem === 'get-users'}
              onClick={() => setActiveItem('get-users')}
            />
            <SidebarItem
              label={t('sidebar.createUser', 'POST Create User')}
              active={activeItem === 'create-user'}
              onClick={() => setActiveItem('create-user')}
            />
          </SidebarItem>
        </SidebarSection>

        <SidebarSection title={t('sidebar.history', 'History')}>
          <SidebarItem
            icon={
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            }
            label="GET https://api.example.com/users"
            active={activeItem === 'history-1'}
            onClick={() => setActiveItem('history-1')}
          />
          <SidebarItem
            icon={
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            }
            label="POST https://api.example.com/login"
            active={activeItem === 'history-2'}
            onClick={() => setActiveItem('history-2')}
          />
        </SidebarSection>

        <SidebarSection title={t('sidebar.favorites', 'Favorites')}>
          <SidebarItem
            icon={
              <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
              </svg>
            }
            label={t('sidebar.starredRequests', 'Starred Requests')}
            active={activeItem === 'starred'}
            onClick={() => setActiveItem('starred')}
          />
        </SidebarSection>
      </div>

      {/* Bottom Actions */}
      <div className="p-3 border-t border-sidebar-border space-y-1">
        <SidebarItem
          icon={
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          }
          label={t('sidebar.settings', 'Settings')}
          active={activeItem === 'settings'}
          onClick={() => setActiveItem('settings')}
        />
        <SidebarItem
          icon={
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          label={t('sidebar.help', 'Help')}
          active={activeItem === 'help'}
          onClick={() => setActiveItem('help')}
        />
      </div>
    </aside>
  );
};

export default Sidebar;
