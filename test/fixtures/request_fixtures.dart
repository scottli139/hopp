import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/models/key_value_pair.dart';

/// HttpRequest fixtures for testing
class RequestFixtures {
  RequestFixtures._();

  /// Simple GET request without body
  static HttpRequest simpleGetRequest() => HttpRequest(
        id: 'req-001',
        name: 'Test GET Request',
        method: HttpMethod.get,
        url: 'https://api.example.com/users',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

  /// GET request with query parameters
  static HttpRequest getWithParams() => HttpRequest(
        id: 'req-002',
        name: 'Test GET with Params',
        method: HttpMethod.get,
        url: 'https://api.example.com/search',
        params: [
          KeyValuePair(
            id: 'param-1',
            key: 'q',
            value: 'flutter',
            enabled: true,
          ),
          KeyValuePair(
            id: 'param-2',
            key: 'page',
            value: '1',
            enabled: true,
          ),
        ],
        headers: [],
        body: '',
        bodyType: 'none',
      );

  /// POST request with JSON body
  static HttpRequest postWithJson() => HttpRequest(
        id: 'req-003',
        name: 'Test POST JSON',
        method: HttpMethod.post,
        url: 'https://api.example.com/users',
        params: [],
        headers: [
          KeyValuePair(
            id: 'header-1',
            key: 'Content-Type',
            value: 'application/json',
            enabled: true,
          ),
        ],
        body: '{"name":"John","email":"john@example.com"}',
        bodyType: 'json',
      );

  /// POST request with form body
  static HttpRequest postWithForm() => HttpRequest(
        id: 'req-004',
        name: 'Test POST Form',
        method: HttpMethod.post,
        url: 'https://api.example.com/login',
        params: [],
        headers: [
          KeyValuePair(
            id: 'header-1',
            key: 'Content-Type',
            value: 'application/x-www-form-urlencoded',
            enabled: true,
          ),
        ],
        body: 'username=admin\npassword=secret',
        bodyType: 'form',
      );

  /// POST request with text body
  static HttpRequest postWithText() => HttpRequest(
        id: 'req-005',
        name: 'Test POST Text',
        method: HttpMethod.post,
        url: 'https://api.example.com/webhook',
        params: [],
        headers: [
          KeyValuePair(
            id: 'header-1',
            key: 'Content-Type',
            value: 'text/plain',
            enabled: true,
          ),
        ],
        body: 'Plain text body',
        bodyType: 'text',
      );

  /// Request with disabled parameters
  static HttpRequest requestWithDisabledParams() => HttpRequest(
        id: 'req-006',
        name: 'Test with Disabled Params',
        method: HttpMethod.get,
        url: 'https://api.example.com/search',
        params: [
          KeyValuePair(
            id: 'param-1',
            key: 'enabled',
            value: 'yes',
            enabled: true,
          ),
          KeyValuePair(
            id: 'param-2',
            key: 'disabled',
            value: 'no',
            enabled: false,
          ),
        ],
        headers: [],
        body: '',
        bodyType: 'none',
      );

  /// Request with disabled headers
  static HttpRequest requestWithDisabledHeaders() => HttpRequest(
        id: 'req-007',
        name: 'Test with Disabled Headers',
        method: HttpMethod.get,
        url: 'https://api.example.com/test',
        params: [],
        headers: [
          KeyValuePair(
            id: 'header-1',
            key: 'Authorization',
            value: 'Bearer token123',
            enabled: true,
          ),
          KeyValuePair(
            id: 'header-2',
            key: 'X-Disabled',
            value: 'disabled',
            enabled: false,
          ),
        ],
        body: '',
        bodyType: 'none',
      );

  /// Request with empty URL
  static HttpRequest requestWithEmptyUrl() => HttpRequest(
        id: 'req-008',
        name: 'Test Empty URL',
        method: HttpMethod.get,
        url: '',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

  /// PUT request
  static HttpRequest putRequest() => HttpRequest(
        id: 'req-009',
        name: 'Test PUT',
        method: HttpMethod.put,
        url: 'https://api.example.com/users/1',
        params: [],
        headers: [],
        body: '{"name":"Updated Name"}',
        bodyType: 'json',
      );

  /// DELETE request
  static HttpRequest deleteRequest() => HttpRequest(
        id: 'req-010',
        name: 'Test DELETE',
        method: HttpMethod.delete,
        url: 'https://api.example.com/users/1',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
      );

  /// Request with parent collection
  static HttpRequest requestWithParentId() => HttpRequest(
        id: 'req-011',
        name: 'Test with Parent',
        method: HttpMethod.get,
        url: 'https://api.example.com/test',
        params: [],
        headers: [],
        body: '',
        bodyType: 'none',
        parentId: 'collection-001',
      );
}
