import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import type { HttpRequest, HttpResponse, KeyValue, HttpMethod, BodyType } from '@/services/httpService';
import { defaultRequest, createKeyValue } from '@/services/httpService';

/**
 * Request tab interface
 */
export interface RequestTab {
  id: string;
  name: string;
  request: HttpRequest;
  response: HttpResponse | null;
  isLoading: boolean;
  error: string | null;
}

/**
 * Request store state
 */
interface RequestState {
  // Tabs
  tabs: RequestTab[];
  activeTabId: string | null;
  
  // Actions
  addTab: (request?: Partial<HttpRequest>) => string;
  closeTab: (id: string) => void;
  setActiveTab: (id: string) => void;
  updateTabRequest: (id: string, request: Partial<HttpRequest>) => void;
  updateTabResponse: (id: string, response: HttpResponse | null) => void;
  setTabLoading: (id: string, isLoading: boolean) => void;
  setTabError: (id: string, error: string | null) => void;
  renameTab: (id: string, name: string) => void;
  
  // Request manipulation
  setMethod: (tabId: string, method: HttpMethod) => void;
  setUrl: (tabId: string, url: string) => void;
  setBody: (tabId: string, body: string) => void;
  setBodyType: (tabId: string, bodyType: BodyType) => void;
  addHeader: (tabId: string, key?: string, value?: string) => void;
  updateHeader: (tabId: string, index: number, updates: Partial<KeyValue>) => void;
  removeHeader: (tabId: string, index: number) => void;
  addParam: (tabId: string, key?: string, value?: string) => void;
  updateParam: (tabId: string, index: number, updates: Partial<KeyValue>) => void;
  removeParam: (tabId: string, index: number) => void;
  
  // Getters
  getActiveTab: () => RequestTab | undefined;
  getActiveRequest: () => HttpRequest | undefined;
}

/**
 * Generate unique tab ID
 */
function generateTabId(): string {
  return `tab-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Request store with immer and devtools
 */
export const useRequestStore = create<RequestState>()(
  devtools(
    immer((set, get) => ({
      // Initial state
      tabs: [],
      activeTabId: null,

      // Actions
      addTab: (request) => {
        const id = generateTabId();
        const newTab: RequestTab = {
          id,
          name: 'New Request',
          request: {
            ...defaultRequest,
            id,
            ...request,
          },
          response: null,
          isLoading: false,
          error: null,
        };

        set((state) => {
          state.tabs.push(newTab);
          state.activeTabId = id;
        });

        return id;
      },

      closeTab: (id) => {
        set((state) => {
          const index = state.tabs.findIndex((t) => t.id === id);
          if (index === -1) return;

          state.tabs.splice(index, 1);

          // If we closed the active tab, switch to another one
          if (state.activeTabId === id) {
            if (state.tabs.length > 0) {
              // Try to select the tab before, or the first one
              const newIndex = Math.max(0, index - 1);
              state.activeTabId = state.tabs[newIndex]?.id ?? null;
            } else {
              state.activeTabId = null;
            }
          }
        });
      },

      setActiveTab: (id) => {
        set((state) => {
          state.activeTabId = id;
        });
      },

      updateTabRequest: (id, requestUpdate) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === id);
          if (tab) {
            Object.assign(tab.request, requestUpdate);
          }
        });
      },

      updateTabResponse: (id, response) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === id);
          if (tab) {
            tab.response = response;
            // Clear error when we get a response
            tab.error = null;
          }
        });
      },

      setTabLoading: (id, isLoading) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === id);
          if (tab) {
            tab.isLoading = isLoading;
          }
        });
      },

      setTabError: (id, error) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === id);
          if (tab) {
            tab.error = error;
            tab.isLoading = false;
          }
        });
      },

      renameTab: (id, name) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === id);
          if (tab) {
            tab.name = name;
          }
        });
      },

      // Request manipulation
      setMethod: (tabId, method) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.method = method;
          }
        });
      },

      setUrl: (tabId, url) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.url = url;
          }
        });
      },

      setBody: (tabId, body) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.body = body;
          }
        });
      },

      setBodyType: (tabId, bodyType) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.bodyType = bodyType;
          }
        });
      },

      addHeader: (tabId, key = '', value = '') => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.headers.push(createKeyValue(key, value, true));
          }
        });
      },

      updateHeader: (tabId, index, updates) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab && tab.request.headers[index]) {
            Object.assign(tab.request.headers[index], updates);
          }
        });
      },

      removeHeader: (tabId, index) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.headers.splice(index, 1);
          }
        });
      },

      addParam: (tabId, key = '', value = '') => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.params.push(createKeyValue(key, value, true));
          }
        });
      },

      updateParam: (tabId, index, updates) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab && tab.request.params[index]) {
            Object.assign(tab.request.params[index], updates);
          }
        });
      },

      removeParam: (tabId, index) => {
        set((state) => {
          const tab = state.tabs.find((t) => t.id === tabId);
          if (tab) {
            tab.request.params.splice(index, 1);
          }
        });
      },

      // Getters
      getActiveTab: () => {
        const { tabs, activeTabId } = get();
        return tabs.find((t) => t.id === activeTabId);
      },

      getActiveRequest: () => {
        const { tabs, activeTabId } = get();
        return tabs.find((t) => t.id === activeTabId)?.request;
      },
    })),
    { name: 'RequestStore' }
  )
);

/**
 * Hook to get active tab
 */
export function useActiveTab(): RequestTab | undefined {
  return useRequestStore((state) => state.getActiveTab());
}

/**
 * Hook to get active request
 */
export function useActiveRequest(): HttpRequest | undefined {
  return useRequestStore((state) => state.getActiveRequest());
}
