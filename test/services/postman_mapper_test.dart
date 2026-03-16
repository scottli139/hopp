import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/services/import_export/postman_mapper.dart';
import 'package:hopp/services/import_export/postman_schema.dart';

void main() {
  group('PostmanMapper', () {
    group('toHoppCollection', () {
      test('should map simple collection', () {
        // Arrange
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test Collection'),
          item: [
            PostmanItem(
              name: 'GET Request',
              request: PostmanRequest(
                method: 'GET',
                url: const PostmanUrl(raw: 'https://example.com/api'),
              ),
            ),
          ],
        );

        // Act
        final hoppCollection =
            PostmanMapper.toHoppCollection(postmanCollection);

        // Assert
        expect(hoppCollection.name, 'Test Collection');
        expect(hoppCollection.requests.length, 1);
        expect(hoppCollection.requests.first.name, 'GET Request');
        expect(hoppCollection.requests.first.method, HttpMethod.get);
      });

      test('should map nested folders', () {
        // Arrange
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test Collection'),
          item: [
            PostmanItem(
              name: 'Folder',
              item: [
                PostmanItem(
                  name: 'Nested Request',
                  request: PostmanRequest(
                    method: 'POST',
                    url: const PostmanUrl(raw: 'https://example.com/post'),
                  ),
                ),
              ],
            ),
          ],
        );

        // Act
        final hoppCollection =
            PostmanMapper.toHoppCollection(postmanCollection);

        // Assert
        expect(hoppCollection.children.length, 1);
        expect(hoppCollection.children.first.name, 'Folder');
        expect(hoppCollection.children.first.requests.length, 1);
      });

      test('should map all HTTP methods', () {
        final methods = [
          'GET',
          'POST',
          'PUT',
          'DELETE',
          'PATCH',
          'HEAD',
          'OPTIONS'
        ];
        final expectedMethods = [
          HttpMethod.get,
          HttpMethod.post,
          HttpMethod.put,
          HttpMethod.delete,
          HttpMethod.patch,
          HttpMethod.head,
          HttpMethod.options,
        ];

        for (var i = 0; i < methods.length; i++) {
          final postmanCollection = PostmanCollection(
            info: PostmanInfo(name: 'Test ${methods[i]}'),
            item: [
              PostmanItem(
                name: '${methods[i]} Request',
                request: PostmanRequest(
                  method: methods[i],
                  url: const PostmanUrl(raw: 'https://example.com'),
                ),
              ),
            ],
          );

          final hoppCollection =
              PostmanMapper.toHoppCollection(postmanCollection);
          expect(hoppCollection.requests.first.method, expectedMethods[i]);
        }
      });
    });

    group('toPostmanCollection', () {
      test('should map simple collection back to Postman format', () {
        // Arrange
        final hoppCollection = Collection.empty().copyWith(
          name: 'Test Collection',
          requests: [
            HttpRequest.empty().copyWith(
              name: 'GET Request',
              method: HttpMethod.get,
              url: 'https://example.com/api',
            ),
          ],
        );

        // Act
        final postmanCollection =
            PostmanMapper.toPostmanCollection(hoppCollection);

        // Assert
        expect(postmanCollection.info.name, 'Test Collection');
        expect(postmanCollection.item.length, 1);
        expect(postmanCollection.item.first.name, 'GET Request');
      });
    });

    group('Body type mapping', () {
      test('should map raw body type correctly', () {
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test'),
          item: [
            PostmanItem(
              name: 'Raw Request',
              request: PostmanRequest(
                method: 'POST',
                url: const PostmanUrl(raw: 'https://example.com'),
                body: PostmanBody(
                  mode: 'raw',
                  raw: '{"key": "value"}',
                  options: PostmanBodyOptions(
                    raw: PostmanRawOptions(language: 'json'),
                  ),
                ),
              ),
            ),
          ],
        );

        final hoppCollection =
            PostmanMapper.toHoppCollection(postmanCollection);
        expect(hoppCollection.requests.first.bodyType, 'raw');
        expect(hoppCollection.requests.first.rawContentType, 'json');
        expect(hoppCollection.requests.first.body, '{"key": "value"}');
      });

      test('should map formdata body type correctly', () {
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test'),
          item: [
            PostmanItem(
              name: 'Form Request',
              request: PostmanRequest(
                method: 'POST',
                url: const PostmanUrl(raw: 'https://example.com'),
                body: PostmanBody(
                  mode: 'formdata',
                  formdata: [
                    const PostmanFormData(
                        key: 'name', value: 'John', type: 'text'),
                  ],
                ),
              ),
            ),
          ],
        );

        final hoppCollection =
            PostmanMapper.toHoppCollection(postmanCollection);
        expect(hoppCollection.requests.first.bodyType, 'form-data');
      });

      test('should map urlencoded body type correctly', () {
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test'),
          item: [
            PostmanItem(
              name: 'URLEncoded Request',
              request: PostmanRequest(
                method: 'POST',
                url: const PostmanUrl(raw: 'https://example.com'),
                body: PostmanBody(
                  mode: 'urlencoded',
                  urlencoded: [
                    const PostmanUrlEncoded(key: 'key', value: 'value'),
                  ],
                ),
              ),
            ),
          ],
        );

        final hoppCollection =
            PostmanMapper.toHoppCollection(postmanCollection);
        expect(hoppCollection.requests.first.bodyType, 'x-www-form-urlencoded');
      });
    });
  });
}
