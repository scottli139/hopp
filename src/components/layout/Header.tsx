import { FC } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

export interface HeaderProps {
  /** Additional CSS classes */
  className?: string;
  /** Tab title */
  title?: string;
  /** On tab close */
  onClose?: () => void;
  /** On save */
  onSave?: () => void;
}

/**
 * Header component
 *
 * Top header bar with tab management and actions.
 *
 * @example
 * ```tsx
 * <Header
 *   title="GET https://api.example.com/users"
 *   onClose={() => console.log('close')}
 *   onSave={() => console.log('save')}
 * />
 * ```
 */
export const Header: FC<HeaderProps> = ({
  className,
  title = 'Untitled Request',
  onClose,
  onSave,
}) => {
  const { t } = useTranslation();

  return (
    <header
      className={cn(
        'h-[48px] flex items-center justify-between px-4',
        'bg-header-bg border-b border-border',
        className
      )}
    >
      {/* Left: Tab info */}
      <div className="flex items-center gap-2 flex-1 min-w-0">
        <span className="px-2 py-1 text-xs font-medium rounded bg-primary/10 text-primary">
          GET
        </span>
        <span className="text-sm truncate text-text-primary" title={title}>
          {title}
        </span>
        <span className="text-text-tertiary text-sm">*</span>
      </div>

      {/* Right: Actions */}
      <div className="flex items-center gap-2">
        <button
          onClick={onSave}
          className={cn(
            'flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-md',
            'bg-primary text-white hover:bg-primary-hover transition-colors',
            'disabled:opacity-50 disabled:cursor-not-allowed'
          )}
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
          {t('header.save', 'Save')}
        </button>

        <div className="w-px h-6 bg-border mx-1" />

        <button
          className={cn(
            'p-2 rounded-md text-text-secondary',
            'hover:bg-bg-secondary hover:text-text-primary transition-colors'
          )}
          title={t('header.share', 'Share')}
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
          </svg>
        </button>

        <button
          onClick={onClose}
          className={cn(
            'p-2 rounded-md text-text-secondary',
            'hover:bg-error/10 hover:text-error transition-colors'
          )}
          title={t('header.close', 'Close')}
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </header>
  );
};

export default Header;
