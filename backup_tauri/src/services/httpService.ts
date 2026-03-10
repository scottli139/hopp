import { invoke } from '@tauri-apps/api/core';
import logger from '@/utils/logger';

/**
 * HTTP methods supported by Hopp
 */
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

/**
 * HTTP body types
 */
export type BodyType = 'none' | 'json' | 'text' | 'form' | 'formData';

/**
 * Key-value pair for headers, params, etc.
 */
export interface KeyValue {
  key: string;
  value: string;
  enabled: boolean;
}

/**
 * HTTP request definition
 */
export interface HttpRequest {
  /** Request ID */
  id?: string;
  /** HTTP method */
  method: HttpMethod;
  /** Request URL */
  url: string;
  /** Query parameters */
  params: KeyValue[];
  /** Request headers */
  headers: KeyValue[];
  /** Body type */
  bodyType: BodyType;
  /** Request body content */
  body: string;
  /** Request timeout in seconds */
  timeout: number;
}

/**
 * HTTP response definition
 */
export interface HttpResponse {
  /** Request ID */
  requestId?: string;
  /** HTTP status code */
  status: number;
  /** HTTP status text */
  statusText: string;
  /** Response headers */
  headers: Record<string, string>;
  /** Response body */
  body: string;
  /** Response size in bytes */
  size: number;
  /** Response time in milliseconds */
  time: number;
  /** Content type */
  contentType?: string;
}

/**
 * HTTP error types
 */
export interface HttpError {
  message: string;
  type: string;
}

/**
 * Default request template
 */
export const defaultRequest: HttpRequest = {
  method: 'GET',
  url: '',
  params: [],
  headers: [
    { key: 'Accept', value: '*/*', enabled: true },
    { key: 'User-Agent', value: 'Hopp/0.1.0', enabled: true },
  ],
  bodyType: 'none',
  body: '',
  timeout: 30,
};

/**
 * Send HTTP request via Tauri command
 */
export async function sendHttpRequest(request: HttpRequest): Promise<HttpResponse> {
  logger.info('Sending HTTP request', { 
    method: request.method, 
    url: request.url,
    hasBody: !!request.body && request.bodyType !== 'none'
  });

  try {
    const response = await invoke<HttpResponse>('send_http_request', { request });
    logger.info('HTTP request completed', { 
      status: response.status, 
      time: response.time,
      size: response.size
    });
    return response;
  } catch (error) {
    logger.error('HTTP request failed', error as Error);
    throw error;
  }
}

/**
 * Send simple GET request
 */
export async function httpGet(url: string): Promise<HttpResponse> {
  logger.info('Sending GET request', { url });
  
  try {
    const response = await invoke<HttpResponse>('http_get', { url });
    logger.info('GET request completed', { status: response.status, time: response.time });
    return response;
  } catch (error) {
    logger.error('GET request failed', error as Error);
    throw error;
  }
}

/**
 * Send POST request with JSON body
 */
export async function httpPost(url: string, body: unknown): Promise<HttpResponse> {
  logger.info('Sending POST request', { url });
  
  try {
    const bodyString = typeof body === 'string' ? body : JSON.stringify(body);
    const response = await invoke<HttpResponse>('http_post', { url, body: bodyString });
    logger.info('POST request completed', { status: response.status, time: response.time });
    return response;
  } catch (error) {
    logger.error('POST request failed', error as Error);
    throw error;
  }
}

/**
 * Create a new empty key-value pair
 */
export function createKeyValue(key = '', value = '', enabled = true): KeyValue {
  return { key, value, enabled };
}

/**
 * Convert KeyValue array to object (only enabled items)
 */
export function keyValueToObject(items: KeyValue[]): Record<string, string> {
  return items
    .filter(item => item.enabled && item.key.trim() !== '')
    .reduce((acc, item) => {
      acc[item.key] = item.value;
      return acc;
    }, {} as Record<string, string>);
}

/**
 * Build full URL with query parameters
 */
export function buildUrl(baseUrl: string, params: KeyValue[]): string {
  if (!baseUrl.trim()) return '';
  
  const enabledParams = params.filter(p => p.enabled && p.key.trim() !== '');
  if (enabledParams.length === 0) return baseUrl;
  
  const separator = baseUrl.includes('?') ? '&' : '?';
  const queryString = enabledParams
    .map(p => `${encodeURIComponent(p.key)}=${encodeURIComponent(p.value)}`)
    .join('&');
  
  return `${baseUrl}${separator}${queryString}`;
}

/**
 * Parse URL to extract base URL and query parameters
 */
export function parseUrl(url: string): { baseUrl: string; params: KeyValue[] } {
  try {
    const urlObj = new URL(url);
    const baseUrl = `${urlObj.protocol}//${urlObj.host}${urlObj.pathname}`;
    
    const params: KeyValue[] = [];
    urlObj.searchParams.forEach((value, key) => {
      params.push(createKeyValue(key, value, true));
    });
    
    return { baseUrl, params };
  } catch {
    // Invalid URL, return as-is
    return { baseUrl: url, params: [] };
  }
}

/**
 * Format body based on content type
 */
export function formatBody(body: string, contentType?: string): string {
  if (!body) return '';
  
  const type = contentType?.toLowerCase() || '';
  
  if (type.includes('application/json')) {
    try {
      const parsed = JSON.parse(body);
      return JSON.stringify(parsed, null, 2);
    } catch {
      return body;
    }
  }
  
  if (type.includes('application/xml') || type.includes('text/xml')) {
    // Simple XML formatting - could be improved with a proper XML formatter
    return body
      .replace(/>/g, '>\n')
      .replace(/</g, '\n<')
      .replace(/\n\n/g, '\n')
      .trim();
  }
  
  return body;
}

/**
 * Get response size in human-readable format
 */
export function formatSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / k ** i).toFixed(2))} ${sizes[i]}`;
}

/**
 * Check if status code is successful (2xx)
 */
export function isSuccessStatus(status: number): boolean {
  return status >= 200 && status < 300;
}

/**
 * Get status code color
 */
export function getStatusColor(status: number): string {
  if (status >= 200 && status < 300) return 'text-green-500';
  if (status >= 300 && status < 400) return 'text-yellow-500';
  if (status >= 400) return 'text-red-500';
  return 'text-gray-500';
}

/**
 * Common HTTP methods with descriptions
 */
export const httpMethods: { value: HttpMethod; label: string; color: string }[] = [
  { value: 'GET', label: 'GET', color: 'text-green-500' },
  { value: 'POST', label: 'POST', color: 'text-blue-500' },
  { value: 'PUT', label: 'PUT', color: 'text-yellow-500' },
  { value: 'DELETE', label: 'DELETE', color: 'text-red-500' },
  { value: 'PATCH', label: 'PATCH', color: 'text-purple-500' },
  { value: 'HEAD', label: 'HEAD', color: 'text-gray-500' },
  { value: 'OPTIONS', label: 'OPTIONS', color: 'text-gray-500' },
];

/**
 * Common content types
 */
export const contentTypes = [
  { value: 'application/json', label: 'JSON' },
  { value: 'application/xml', label: 'XML' },
  { value: 'text/plain', label: 'Text' },
  { value: 'text/html', label: 'HTML' },
  { value: 'application/x-www-form-urlencoded', label: 'Form URL Encoded' },
  { value: 'multipart/form-data', label: 'Form Data' },
];
