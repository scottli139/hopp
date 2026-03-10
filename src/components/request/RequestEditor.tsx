import type { FC, ChangeEvent } from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useRequestStore, useActiveTab } from '@/stores/requestStore';
import { sendHttpRequest, httpMethods, buildUrl, type HttpMethod, type BodyType } from '@/services/httpService';
import logger from '@/utils/logger';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

/**
 * Request editor component
 */
export const RequestEditor: FC = () => {
  const { t } = useTranslation();
  const activeTab = useActiveTab();
  const { 
    setMethod, 
    setUrl, 
    setBody, 
    setBodyType,
    addHeader, 
    updateHeader, 
    removeHeader,
    addParam,
    updateParam,
    removeParam,
    updateTabResponse,
    setTabLoading,
    setTabError,
  } = useRequestStore();

  const [activeSection, setActiveSection] = useState<'params' | 'headers' | 'body'>('params');

  if (!activeTab) {
    return (
      <div className="h-full flex items-center justify-center text-text-secondary">
        {t('request.noActiveTab', 'No active request')}
      </div>
    );
  }

  const { request, isLoading } = activeTab;

  const handleSendRequest = async (): Promise<void> => {
    if (!request.url.trim()) {
      setTabError(activeTab.id, 'URL is required');
      return;
    }

    setTabLoading(activeTab.id, true);
    setTabError(activeTab.id, null);

    try {
      const response = await sendHttpRequest(request);
      updateTabResponse(activeTab.id, response);
    } catch (error) {
      logger.error('Request failed', error as Error);
      setTabError(activeTab.id, (error as Error).message || 'Request failed');
      updateTabResponse(activeTab.id, null);
    } finally {
      setTabLoading(activeTab.id, false);
    }
  };

  const handleUrlChange = (e: ChangeEvent<HTMLInputElement>): void => {
    setUrl(activeTab.id, e.target.value);
  };

  const handleMethodChange = (e: ChangeEvent<HTMLSelectElement>): void => {
    setMethod(activeTab.id, e.target.value as HttpMethod);
  };

  const handleBodyChange = (e: ChangeEvent<HTMLTextAreaElement>): void => {
    setBody(activeTab.id, e.target.value);
  };

  const handleBodyTypeChange = (e: ChangeEvent<HTMLSelectElement>): void => {
    setBodyType(activeTab.id, e.target.value as BodyType);
  };

  return (
    <div className="h-full flex flex-col">
      {/* URL Bar */}
      <div className="flex items-center gap-2 p-3 border-b border-border bg-bg-secondary">
        {/* Method Selector */}
        <select
          value={request.method}
          onChange={handleMethodChange}
          className={cn(
            'px-3 py-2 rounded-md font-medium text-sm',
            'bg-bg-primary border border-border-dark',
            'focus:outline-none focus:ring-2 focus:ring-primary',
            httpMethods.find(m => m.value === request.method)?.color || 'text-text-primary'
          )}
          disabled={isLoading}
        >
          {httpMethods.map((method) => (
            <option key={method.value} value={method.value} className={method.color}>
              {method.label}
            </option>
          ))}
        </select>

        {/* URL Input */}
        <input
          type="text"
          value={request.url}
          onChange={handleUrlChange}
          placeholder={t('request.urlPlaceholder', 'Enter request URL')}
          className={cn(
            'flex-1 px-3 py-2 rounded-md text-sm',
            'bg-bg-primary border border-border-dark',
            'focus:outline-none focus:ring-2 focus:ring-primary',
            'text-text-primary placeholder:text-text-tertiary'
          )}
          disabled={isLoading}
        />

        {/* Send Button */}
        <button
          onClick={handleSendRequest}
          disabled={isLoading || !request.url.trim()}
          className={cn(
            'px-6 py-2 rounded-md font-medium text-sm',
            'bg-primary text-white',
            'hover:bg-primary-hover',
            'disabled:opacity-50 disabled:cursor-not-allowed',
            'flex items-center gap-2'
          )}
        >
          {isLoading ? (
            <>
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                  fill="none"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              {t('request.sending', 'Sending...')}
            </>
          ) : (
            t('request.send', 'Send')
          )}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex items-center border-b border-border">
        {(['params', 'headers', 'body'] as const).map((section) => (
          <button
            key={section}
            onClick={() => setActiveSection(section)}
            className={cn(
              'px-4 py-2 text-sm font-medium',
              'border-b-2 transition-colors',
              activeSection === section
                ? 'border-primary text-primary'
                : 'border-transparent text-text-secondary hover:text-text-primary'
            )}
          >
            {t(`request.${section}`, section.charAt(0).toUpperCase() + section.slice(1))}
            {section === 'params' && request.params.filter(p => p.enabled).length > 0 && (
              <span className="ml-1 px-1.5 py-0.5 text-xs bg-primary/10 text-primary rounded-full">
                {request.params.filter(p => p.enabled).length}
              </span>
            )}
            {section === 'headers' && request.headers.filter(h => h.enabled).length > 0 && (
              <span className="ml-1 px-1.5 py-0.5 text-xs bg-primary/10 text-primary rounded-full">
                {request.headers.filter(h => h.enabled).length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        {/* Error Message */}
        {activeTab.error && (
          <div className="mb-4 p-3 rounded-md bg-error/10 text-error text-sm">
            {activeTab.error}
          </div>
        )}

        {/* Params Section */}
        {activeSection === 'params' && (
          <KeyValueEditor
            items={request.params}
            onAdd={() => addParam(activeTab.id)}
            onUpdate={(index, updates) => updateParam(activeTab.id, index, updates)}
            onRemove={(index) => removeParam(activeTab.id, index)}
            placeholderKey="Key"
            placeholderValue="Value"
          />
        )}

        {/* Headers Section */}
        {activeSection === 'headers' && (
          <KeyValueEditor
            items={request.headers}
            onAdd={() => addHeader(activeTab.id)}
            onUpdate={(index, updates) => updateHeader(activeTab.id, index, updates)}
            onRemove={(index) => removeHeader(activeTab.id, index)}
            placeholderKey="Header"
            placeholderValue="Value"
          />
        )}

        {/* Body Section */}
        {activeSection === 'body' && (
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <label className="text-sm text-text-secondary">{t('request.bodyType', 'Body Type')}:</label>
              <select
                value={request.bodyType}
                onChange={handleBodyTypeChange}
                className={cn(
                  'px-3 py-1.5 rounded-md text-sm',
                  'bg-bg-primary border border-border-dark',
                  'focus:outline-none focus:ring-2 focus:ring-primary'
                )}
              >
                <option value="none">None</option>
                <option value="json">JSON</option>
                <option value="text">Text</option>
                <option value="form">Form</option>
                <option value="formData">Form Data</option>
              </select>
            </div>

            {request.bodyType !== 'none' && (
              <textarea
                value={request.body}
                onChange={handleBodyChange}
                placeholder={t('request.bodyPlaceholder', 'Request body...')}
                className={cn(
                  'w-full h-64 px-3 py-2 rounded-md text-sm font-mono',
                  'bg-bg-primary border border-border-dark',
                  'focus:outline-none focus:ring-2 focus:ring-primary',
                  'text-text-primary placeholder:text-text-tertiary',
                  'resize-none'
                )}
                spellCheck={false}
              />
            )}
          </div>
        )}
      </div>

      {/* URL Preview */}
      <div className="px-3 py-2 border-t border-border bg-bg-secondary text-xs text-text-secondary truncate">
        <span className="font-medium">{t('request.preview', 'Preview')}:</span>{' '}
        {buildUrl(request.url, request.params) || t('request.noUrl', 'No URL')}
      </div>
    </div>
  );
};

/**
 * Key-value editor component
 */
interface KeyValueEditorProps {
  items: { key: string; value: string; enabled: boolean }[];
  onAdd: () => void;
  onUpdate: (index: number, updates: Partial<{ key: string; value: string; enabled: boolean }>) => void;
  onRemove: (index: number) => void;
  placeholderKey?: string;
  placeholderValue?: string;
}

const KeyValueEditor: FC<KeyValueEditorProps> = ({
  items,
  onAdd,
  onUpdate,
  onRemove,
  placeholderKey = 'Key',
  placeholderValue = 'Value',
}) => {
  return (
    <div className="space-y-2">
      {items.map((item, index) => (
        <div key={index} className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={item.enabled}
            onChange={(e) => onUpdate(index, { enabled: e.target.checked })}
            className="w-4 h-4 rounded border-border-dark text-primary focus:ring-primary"
          />
          <input
            type="text"
            value={item.key}
            onChange={(e) => onUpdate(index, { key: e.target.value })}
            placeholder={placeholderKey}
            className={cn(
              'flex-1 px-3 py-2 rounded-md text-sm',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary',
              'text-text-primary placeholder:text-text-tertiary',
              !item.enabled && 'opacity-50'
            )}
          />
          <input
            type="text"
            value={item.value}
            onChange={(e) => onUpdate(index, { value: e.target.value })}
            placeholder={placeholderValue}
            className={cn(
              'flex-1 px-3 py-2 rounded-md text-sm',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary',
              'text-text-primary placeholder:text-text-tertiary',
              !item.enabled && 'opacity-50'
            )}
          />
          <button
            onClick={() => onRemove(index)}
            className="p-2 text-text-tertiary hover:text-error transition-colors"
            title="Remove"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      ))}

      <button
        onClick={onAdd}
        className={cn(
          'w-full py-2 px-4 rounded-md text-sm',
          'border border-dashed border-border-dark',
          'text-text-secondary hover:text-text-primary hover:border-text-tertiary',
          'transition-colors'
        )}
      >
        + Add
      </button>
    </div>
  );
};

export default RequestEditor;
