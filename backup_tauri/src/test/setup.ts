import '@testing-library/jest-dom';
import { vi } from 'vitest';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Initialize i18n for tests
void i18n
  .use(initReactI18next)
  .init({
    lng: 'en',
    fallbackLng: 'en',
    ns: ['translation'],
    defaultNS: 'translation',
    resources: {
      en: {
        translation: {
          app: {
            name: 'Hopp',
            tagline: 'Lightweight, cross-platform API testing tool',
          },
          sidebar: {
            history: 'History',
            collections: 'Collections',
            favorites: 'Favorites',
            settings: 'Settings',
            help: 'Help',
          },
          header: {
            save: 'Save',
            share: 'Share',
            close: 'Close',
          },
          statusBar: {
            idle: 'Idle',
            connecting: 'Connecting...',
            ready: 'Ready',
            error: 'Error',
            status: 'Status',
            time: 'Time',
            size: 'Size',
          },
        },
      },
    },
    interpolation: {
      escapeValue: false,
    },
  });

// Mock Tauri API
(globalThis as Record<string, unknown>).__TAURI__ = {
  invoke: vi.fn(),
  event: {
    listen: vi.fn(() => Promise.resolve(() => {})),
    emit: vi.fn(),
  },
};

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

class MockIntersectionObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}

Object.defineProperty(window, 'IntersectionObserver', {
  writable: true,
  value: MockIntersectionObserver,
});

class MockResizeObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}

Object.defineProperty(window, 'ResizeObserver', {
  writable: true,
  value: MockResizeObserver,
});

window.alert = vi.fn();
window.confirm = vi.fn(() => true);
window.prompt = vi.fn(() => null);
