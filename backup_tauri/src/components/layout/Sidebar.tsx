import type { FC, ReactNode } from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface SidebarProps {
  className?: string;
  width?: number;
}

// Icons
const FolderIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
  </svg>
);

const ClockIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
  </svg>
);

const StarIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
  </svg>
);

const SettingsIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
    <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
  </svg>
);

const HelpIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
  </svg>
);

const ChevronRightIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
  </svg>
);

const PlusIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
  </svg>
);

// Section Header Component
const SectionHeader: FC<{ title: string; action?: ReactNode }> = ({ title, action }) => (
  <div className="flex items-center justify-between px-3 py-1.5">
    <span className="text-[10px] font-semibold text-text-tertiary uppercase tracking-wider">
      {title}
    </span>
    {action}
  </div>
);

// Tree Item Component
interface TreeItemProps {
  icon?: ReactNode;
  label: string;
  active?: boolean;
  expanded?: boolean;
  hasChildren?: boolean;
  onClick?: () => void;
  onToggle?: () => void;
  level?: number;
}

const TreeItem: FC<TreeItemProps> = ({
  icon,
  label,
  active,
  expanded,
  hasChildren,
  onClick,
  onToggle,
  level = 0,
}) => {
  return (
    <div
      className={cn(
        'group flex items-center gap-2 px-3 py-1.5 rounded-md cursor-pointer transition-all',
        'text-[13px] leading-5 text-sidebar-text',
        active 
          ? 'bg-sidebar-active text-sidebar-text-active font-medium' 
          : 'hover:bg-sidebar-hover'
      )}
      style={{ paddingLeft: `${8 + level * 16}px` }}
      onClick={onClick}
    >
      {hasChildren && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            onToggle?.();
          }}
          className={cn(
            'flex-shrink-0 p-0.5 rounded transition-transform',
            expanded && 'rotate-90'
          )}
        >
          <ChevronRightIcon className="w-3.5 h-3.5 text-text-tertiary" />
        </button>
      )}
      {!hasChildren && <span className="w-5 flex-shrink-0" />}
      
      {icon && (
        <span className={cn(
          'flex-shrink-0 w-4 h-4',
          active ? 'text-sidebar-text-active' : 'text-text-tertiary'
        )}>
          {icon}
        </span>
      )}
      
      <span className="flex-1 truncate min-w-0">{label}</span>
    </div>
  );
};

export const Sidebar: FC<SidebarProps> = ({ className, width }) => {
  const { t } = useTranslation();
  const [activeItem, setActiveItem] = useState('history');
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set(['collections']));

  const toggleSection = (section: string) => {
    setExpandedSections((prev) => {
      const next = new Set(prev);
      if (next.has(section)) {
        next.delete(section);
      } else {
        next.add(section);
      }
      return next;
    });
  };

  return (
    <aside
      className={cn(
        'h-full flex flex-col bg-sidebar-bg border-r border-sidebar-border',
        className
      )}
      style={{ width: width ? `${width}px` : undefined }}
    >
      {/* Logo/Brand */}
      <div className="h-12 flex items-center px-4 border-b border-sidebar-border">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-lg bg-primary flex items-center justify-center">
            <span className="text-white font-bold text-sm">H</span>
          </div>
          <div className="flex flex-col">
            <span className="font-semibold text-[15px] text-text-primary leading-tight">{t('app.name')}</span>
            <span className="text-[10px] text-text-tertiary leading-tight">v0.1.0</span>
          </div>
        </div>
      </div>

      {/* Main Navigation */}
      <div className="flex-1 overflow-y-auto py-2">
        {/* Collections Section */}
        <div className="mb-1">
          <SectionHeader 
            title={t('sidebar.collections', 'Collections')}
            action={
              <button className="p-1 rounded hover:bg-bg-tertiary text-text-tertiary hover:text-text-primary transition-colors">
                <PlusIcon className="w-3.5 h-3.5" />
              </button>
            }
          />
          <div className="px-1">
            <TreeItem
              icon={<FolderIcon className="w-4 h-4" />}
              label={t('sidebar.defaultCollection', 'Default Collection')}
              active={activeItem === 'default'}
              expanded={expandedSections.has('collections')}
              hasChildren
              onClick={() => setActiveItem('default')}
              onToggle={() => toggleSection('collections')}
            />
            {expandedSections.has('collections') && (
              <>
                <TreeItem
                  label="GET Users"
                  active={activeItem === 'get-users'}
                  onClick={() => setActiveItem('get-users')}
                  level={1}
                />
                <TreeItem
                  label="POST Create User"
                  active={activeItem === 'create-user'}
                  onClick={() => setActiveItem('create-user')}
                  level={1}
                />
              </>
            )}
          </div>
        </div>

        {/* History Section */}
        <div className="mb-1">
          <SectionHeader title={t('sidebar.history', 'History')} />
          <div className="px-1">
            <TreeItem
              icon={<ClockIcon className="w-4 h-4" />}
              label="GET https://api.example.com/users"
              active={activeItem === 'history-1'}
              onClick={() => setActiveItem('history-1')}
            />
            <TreeItem
              icon={<ClockIcon className="w-4 h-4" />}
              label="POST https://api.example.com/login"
              active={activeItem === 'history-2'}
              onClick={() => setActiveItem('history-2')}
            />
          </div>
        </div>

        {/* Favorites Section */}
        <div className="mb-1">
          <SectionHeader title={t('sidebar.favorites', 'Favorites')} />
          <div className="px-1">
            <TreeItem
              icon={<StarIcon className="w-4 h-4" />}
              label={t('sidebar.starredRequests', 'Starred Requests')}
              active={activeItem === 'starred'}
              onClick={() => setActiveItem('starred')}
            />
          </div>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-1.5 border-t border-sidebar-border space-y-0.5">
        <TreeItem
          icon={<SettingsIcon className="w-4 h-4" />}
          label={t('sidebar.settings', 'Settings')}
          active={activeItem === 'settings'}
          onClick={() => setActiveItem('settings')}
        />
        <TreeItem
          icon={<HelpIcon className="w-4 h-4" />}
          label={t('sidebar.help', 'Help')}
          active={activeItem === 'help'}
          onClick={() => setActiveItem('help')}
        />
      </div>
    </aside>
  );
};

export default Sidebar;
