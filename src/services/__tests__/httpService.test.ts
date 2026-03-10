import { describe, it, expect, vi } from 'vitest';
import {
  createKeyValue,
  keyValueToObject,
  buildUrl,
  parseUrl,
  formatSize,
  isSuccessStatus,
  formatBody,
} from '../httpService';

describe('httpService', () => {
  describe('createKeyValue', () => {
    it('creates key-value pair with default values', () => {
      const result = createKeyValue();
      expect(result).toEqual({ key: '', value: '', enabled: true });
    });

    it('creates key-value pair with provided values', () => {
      const result = createKeyValue('Content-Type', 'application/json', false);
      expect(result).toEqual({ key: 'Content-Type', value: 'application/json', enabled: false });
    });
  });

  describe('keyValueToObject', () => {
    it('converts enabled key-value pairs to object', () => {
      const items = [
        { key: 'Content-Type', value: 'application/json', enabled: true },
        { key: 'Authorization', value: 'Bearer token', enabled: true },
        { key: 'X-Disabled', value: 'value', enabled: false },
      ];
      const result = keyValueToObject(items);
      expect(result).toEqual({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer token',
      });
    });

    it('filters out empty keys', () => {
      const items = [
        { key: 'Content-Type', value: 'application/json', enabled: true },
        { key: '', value: 'value', enabled: true },
        { key: '  ', value: 'value', enabled: true },
      ];
      const result = keyValueToObject(items);
      expect(result).toEqual({
        'Content-Type': 'application/json',
      });
    });

    it('returns empty object for empty array', () => {
      const result = keyValueToObject([]);
      expect(result).toEqual({});
    });
  });

  describe('buildUrl', () => {
    it('returns base URL when no params', () => {
      const result = buildUrl('https://api.example.com/users', []);
      expect(result).toBe('https://api.example.com/users');
    });

    it('appends query params to URL', () => {
      const params = [
        { key: 'page', value: '1', enabled: true },
        { key: 'limit', value: '10', enabled: true },
      ];
      const result = buildUrl('https://api.example.com/users', params);
      expect(result).toBe('https://api.example.com/users?page=1&limit=10');
    });

    it('handles existing query string', () => {
      const params = [{ key: 'sort', value: 'desc', enabled: true }];
      const result = buildUrl('https://api.example.com/users?page=1', params);
      expect(result).toBe('https://api.example.com/users?page=1&sort=desc');
    });

    it('filters out disabled params', () => {
      const params = [
        { key: 'page', value: '1', enabled: true },
        { key: 'limit', value: '10', enabled: false },
      ];
      const result = buildUrl('https://api.example.com/users', params);
      expect(result).toBe('https://api.example.com/users?page=1');
    });

    it('encodes special characters in params', () => {
      const params = [{ key: 'search', value: 'hello world', enabled: true }];
      const result = buildUrl('https://api.example.com/search', params);
      expect(result).toBe('https://api.example.com/search?search=hello%20world');
    });

    it('returns empty string for empty URL', () => {
      const result = buildUrl('', [{ key: 'test', value: 'value', enabled: true }]);
      expect(result).toBe('');
    });
  });

  describe('parseUrl', () => {
    it('parses URL without query params', () => {
      const result = parseUrl('https://api.example.com/users');
      expect(result).toEqual({
        baseUrl: 'https://api.example.com/users',
        params: [],
      });
    });

    it('parses URL with query params', () => {
      const result = parseUrl('https://api.example.com/users?page=1&limit=10');
      expect(result.baseUrl).toBe('https://api.example.com/users');
      expect(result.params).toHaveLength(2);
      expect(result.params).toContainEqual({ key: 'page', value: '1', enabled: true });
      expect(result.params).toContainEqual({ key: 'limit', value: '10', enabled: true });
    });

    it('returns original URL for invalid URL', () => {
      const result = parseUrl('not-a-valid-url');
      expect(result.baseUrl).toBe('not-a-valid-url');
      expect(result.params).toEqual([]);
    });
  });

  describe('formatSize', () => {
    it('formats bytes', () => {
      expect(formatSize(0)).toBe('0 B');
      expect(formatSize(100)).toBe('100 B');
      expect(formatSize(1024)).toBe('1 KB');
      expect(formatSize(1024 * 1024)).toBe('1 MB');
      expect(formatSize(1024 * 1024 * 1024)).toBe('1 GB');
    });

    it('formats with decimal places', () => {
      expect(formatSize(1536)).toBe('1.5 KB');
      expect(formatSize(2560)).toBe('2.5 KB');
    });
  });

  describe('isSuccessStatus', () => {
    it('returns true for 2xx status codes', () => {
      expect(isSuccessStatus(200)).toBe(true);
      expect(isSuccessStatus(201)).toBe(true);
      expect(isSuccessStatus(204)).toBe(true);
      expect(isSuccessStatus(299)).toBe(true);
    });

    it('returns false for non-2xx status codes', () => {
      expect(isSuccessStatus(199)).toBe(false);
      expect(isSuccessStatus(300)).toBe(false);
      expect(isSuccessStatus(400)).toBe(false);
      expect(isSuccessStatus(500)).toBe(false);
    });
  });

  describe('formatBody', () => {
    it('returns empty string for empty body', () => {
      expect(formatBody('', 'application/json')).toBe('');
      expect(formatBody('', undefined)).toBe('');
    });

    it('formats JSON with indentation', () => {
      const json = '{"key":"value","num":123}';
      const result = formatBody(json, 'application/json');
      expect(result).toContain('"key": "value"');
      expect(result).toContain('"num": 123');
    });

    it('returns original body for invalid JSON', () => {
      const invalid = '{"invalid json';
      const result = formatBody(invalid, 'application/json');
      expect(result).toBe(invalid);
    });

    it('formats XML', () => {
      const xml = '<root><item>value</item></root>';
      const result = formatBody(xml, 'application/xml');
      expect(result).toContain('<root>');
    });

    it('returns plain text as-is', () => {
      const text = 'Hello World';
      const result = formatBody(text, 'text/plain');
      expect(result).toBe(text);
    });
  });
});
