import type { FC, ChangeEvent } from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useRequestStore, useActiveTab } from '@/stores/requestStore';
import { sendHttpRequest, httpMethods, buildUrl, type HttpMethod, type BodyType, type KeyValue } from '@/services/httpService';
import logger from '@/utils/logger';

function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}

// Icons
const SendIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
  </svg>
);

const PlusIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
  </svg>
);

const TrashIcon: FC<{ className?: string }> = ({ className }) => (
  <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
  </svg>
);

/**
 * Request editor component with modern design
 */
export const RequestEditor: FC = () => {
  const { t: _t } = useTranslation();
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
      <div className="h-full flex items-center justify-center text-text-muted">
        <div className="text-center">
          <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-bg-tertiary flex items-center justify-center">
            <SendIcon className="w-8 h-8 text-text-tertiary" />
          </div>
          <p className="text-sm">No active request</p>
        </div>
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
      logger.info('Sending HTTP request', { method: request.method, url: request.url });
      const response = await sendHttpRequest(request);
      updateTabResponse(activeTab.id, response);
      logger.info('Request completed', { status: response.status, time: response.time });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Request failed';
      setTabError(activeTab.id, errorMessage);
      logger.error('Request failed', { error: errorMessage });
    } finally {
      setTabLoading(activeTab.id, false);
    }
  };

  const handleMethodChange = (e: ChangeEvent<HTMLSelectElement>): void => {
    setMethod(activeTab.id, e.target.value as HttpMethod);
  };

  const handleUrlChange = (e: ChangeEvent<HTMLInputElement>): void => {
    setUrl(activeTab.id, e.target.value);
  };

  const handleBodyChange = (e: ChangeEvent<HTMLTextAreaElement>): void => {
    setBody(activeTab.id, e.target.value);
  };

  const handleBodyTypeChange = (e: ChangeEvent<HTMLSelectElement>): void => {
    setBodyType(activeTab.id, e.target.value as BodyType);
  };

  const previewUrl = buildUrl(request.url, request.params);

  return (
    <div className="h-full flex flex-col bg-bg-primary">
      {/* URL Bar */}
      <div className="flex items-center gap-2.5 px-5 py-3.5 border-b border-border bg-bg-secondary">
        {/* Method Selector */}
        <div className="relative flex-shrink-0">
          <select
            value={request.method}
            onChange={handleMethodChange}
            disabled={isLoading}
            className={cn(
              'appearance-none h-10 pl-4 pr-10 rounded-lg font-semibold text-[13px] min-w-[100px]',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
              'transition-all cursor-pointer',
              httpMethods.find(m => m.value === request.method)?.color || 'text-text-primary'
            )}
          >
            {httpMethods.map((method) => (
              <option key={method.value} value={method.value}>
                {method.label}
              </option>
            ))}
          </select>
          <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none">
            <svg className="w-4 h-4 text-text-tertiary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>

        {/* URL Input */}
        <div className="flex-1 relative min-w-0">
          <input
            type="text"
            value={request.url}
            onChange={handleUrlChange}
            placeholder="Enter request URL"
            disabled={isLoading}
            className={cn(
              'w-full h-10 px-4 rounded-lg text-[13px]',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
              'text-text-primary placeholder:text-text-tertiary',
              'transition-all'
            )}
          />
        </div>

        {/* Send Button */}
        <button
          onClick={handleSendRequest}
          disabled={isLoading || !request.url.trim()}
          className={cn(
            'h-10 px-6 rounded-lg font-semibold text-[13px] flex-shrink-0',
            'bg-primary text-white',
            'hover:bg-primary-hover',
            'disabled:opacity-50 disabled:cursor-not-allowed',
            'flex items-center gap-2',
            'transition-all shadow-sm hover:shadow',
            'active:translate-y-px'
          )}
        >
          {isLoading ? (
            <>
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
              <span>Sending...</span>
            </>
          ) : (
            <>
              <SendIcon className="w-4 h-4" />
              <span>Send</span>
            </>
          )}
        </button>
      </div>

      {/* Section Tabs */}
      <div className="flex items-center px-5 border-b border-border bg-bg-secondary gap-1">
        {(['params', 'headers', 'body'] as const).map((section) => {
          const count = section === 'params' 
            ? request.params.filter(p => p.enabled).length 
            : section === 'headers' 
              ? request.headers.filter(h => h.enabled).length 
              : 0;
          
          return (
            <button
              key={section}
              onClick={() => setActiveSection(section)}
              className={cn(
                'relative px-4 py-3 text-[13px] font-medium -mb-px rounded-t-md',
                'transition-all duration-150',
                activeSection === section
                  ? 'text-primary bg-bg-primary'
                  : 'text-text-secondary hover:text-text-primary hover:bg-bg-tertiary/50'
              )}
            >
              <span className="flex items-center gap-2">
                {section.charAt(0).toUpperCase() + section.slice(1)}
                {count > 0 && (
                  <span className="px-1.5 py-0 text-[10px] font-semibold rounded-full bg-primary/10 text-primary min-w-[18px] text-center leading-4">
                    {count}
                  </span>
                )}
              </span>
              {activeSection === section && (
                <div className="absolute bottom-0 left-0 right-0 h-[2px] bg-primary" />
              )}
            </button>
          );
        })}
      </div>

      {/* Content Area */}
      <div className="flex-1 overflow-auto">
        {/* Error Message */}
        {activeTab.error && (
          <div className="m-4 p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm">
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
          <div className="p-4 space-y-4">
            <div className="flex items-center gap-3">
              <label className="text-sm font-medium text-text-secondary">Content Type</label>
              <select
                value={request.bodyType}
                onChange={handleBodyTypeChange}
                className={cn(
                  'h-8 px-3 rounded-md text-sm',
                  'bg-bg-primary border border-border-dark',
                  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
                  'text-text-primary'
                )}
              >
                <option value="none">None</option>
                <option value="json">JSON</option>
                <option value="text">Text</option>
                <option value="form">Form URL Encoded</option>
                <option value="formData">Multipart Form</option>
              </select>
            </div>

            {request.bodyType !== 'none' && (
              <textarea
                value={request.body}
                onChange={handleBodyChange}
                placeholder="Request body..."
                className={cn(
                  'w-full h-[300px] p-3 rounded-lg text-sm font-mono',
                  'bg-bg-primary border border-border-dark',
                  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
                  'text-text-primary placeholder:text-text-tertiary',
                  'resize-none'
                )}
              />
            )}
          </div>
        )}

        {/* URL Preview */}
        {previewUrl !== request.url && (
          <div className="px-4 py-2 border-t border-border bg-bg-secondary">
            <p className="text-xs text-text-muted">
              <span className="font-medium">Preview:</span>{' '}
              <span className="text-text-secondary">{previewUrl}</span>
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

// KeyValue Editor Component
interface KeyValueEditorProps {
  items: KeyValue[];
  onAdd: () => void;
  onUpdate: (index: number, updates: Partial<KeyValue>) => void;
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
    <div className="p-5 space-y-1">
      {/* Header Row */}
      <div className="grid grid-cols-[32px_1fr_1fr_36px] gap-2 px-0 mb-2">
        <span></span>
        <span className="text-[11px] font-semibold text-text-tertiary uppercase tracking-wider pl-3">{placeholderKey}</span>
        <span className="text-[11px] font-semibold text-text-tertiary uppercase tracking-wider pl-3">{placeholderValue}</span>
        <span></span>
      </div>

      {/* Items */}
      {items.map((item, index) => (
        <div 
          key={index} 
          className="grid grid-cols-[32px_1fr_1fr_36px] gap-2 items-center group"
        >
          <div className="flex justify-center">
            <input
              type="checkbox"
              checked={item.enabled}
              onChange={(e) => onUpdate(index, { enabled: e.target.checked })}
              className="w-4 h-4 rounded border-border-dark text-primary focus:ring-primary/30 cursor-pointer"
            />
          </div>
          <input
            type="text"
            value={item.key}
            onChange={(e) => onUpdate(index, { key: e.target.value })}
            placeholder={placeholderKey}
            className={cn(
              'h-9 px-3 rounded-md text-[13px]',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
              'text-text-primary placeholder:text-text-tertiary',
              'transition-all',
              !item.enabled && 'opacity-40'
            )}
          />
          <input
            type="text"
            value={item.value}
            onChange={(e) => onUpdate(index, { value: e.target.value })}
            placeholder={placeholderValue}
            className={cn(
              'h-9 px-3 rounded-md text-[13px]',
              'bg-bg-primary border border-border-dark',
              'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
              'text-text-primary placeholder:text-text-tertiary',
              'transition-all',
              !item.enabled && 'opacity-40'
            )}
          />
          <button
            onClick={() => onRemove(index)}
            className={cn(
              'flex items-center justify-center w-9 h-9 rounded-md',
              'text-text-tertiary hover:text-error hover:bg-error/10',
              'opacity-0 group-hover:opacity-100',
              'transition-all duration-150'
            )}
          >
            <TrashIcon className="w-4 h-4" />
          </button>
        </div>
      ))}

      {/* Add Button */}
      <button
        onClick={onAdd}
        className={cn(
          'w-full h-10 mt-3 rounded-lg',
          'border border-dashed border-border-dark',
          'text-text-muted hover:text-primary hover:border-primary/40 hover:bg-primary/[0.03]',
          'flex items-center justify-center gap-2',
          'transition-all duration-150'
        )}
      >
        <PlusIcon className="w-4 h-4" />
        <span className="text-[13px] font-medium">Add {placeholderKey}</span>
      </button>
    </div>
  );
};

export default RequestEditor;
