import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/models/collection.dart';
import 'package:hopp/models/http_method.dart';
import 'package:hopp/models/http_request.dart';
import 'package:hopp/services/import_export/postman_mapper.dart';
import 'package:hopp/services/import_export/postman_schema.dart';

void main() {
  group('PostmanMapper', () {
    group('toHoppCollectionFlat', () {
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
        final (root, children, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);

        // Assert
        expect(root.name, 'Test Collection');
        expect(children.length, 0);
        expect(requests.length, 1);
        expect(requests.first.name, 'GET Request');
        expect(requests.first.method, HttpMethod.get);
        expect(requests.first.parentId, root.id);
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
        final (root, children, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);

        // Assert
        expect(root.name, 'Test Collection');
        expect(children.length, 1);
        expect(children.first.name, 'Folder');
        expect(children.first.parentId, root.id);
        expect(requests.length, 1);
        expect(requests.first.name, 'Nested Request');
        expect(requests.first.parentId, children.first.id);
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

          final (_, __, requests) =
              PostmanMapper.toHoppCollectionFlat(postmanCollection);
          expect(requests.first.method, expectedMethods[i]);
        }
      });
    });

    group('toPostmanCollection', () {
      test('should map simple collection back to Postman format', () {
        // Arrange
        final rootId = 'root-id';
        final hoppCollection = Collection.empty().copyWith(
          id: rootId,
          name: 'Test Collection',
          requests: [],
        );
        final allRequests = [
          HttpRequest.empty().copyWith(
            name: 'GET Request',
            method: HttpMethod.get,
            url: 'https://example.com/api',
            parentId: rootId,
          ),
        ];

        // Act
        final postmanCollection = PostmanMapper.toPostmanCollection(
          hoppCollection,
          allRequests: allRequests,
        );

        // Assert
        expect(postmanCollection.info.name, 'Test Collection');
        expect(postmanCollection.item.length, 1);
        expect(postmanCollection.item.first.name, 'GET Request');
      });

      test('should map nested folders to Postman format', () {
        // Arrange
        final rootId = 'root-id';
        final folderId = 'folder-id';
        final hoppCollection = Collection.empty().copyWith(
          id: rootId,
          name: 'Test Collection',
          requests: [],
        );
        final allCollections = [
          Collection.empty().copyWith(
            id: folderId,
            name: 'Folder',
            parentId: rootId,
          ),
        ];
        final allRequests = [
          HttpRequest.empty().copyWith(
            name: 'Nested Request',
            method: HttpMethod.post,
            url: 'https://example.com/post',
            parentId: folderId,
          ),
        ];

        // Act
        final postmanCollection = PostmanMapper.toPostmanCollection(
          hoppCollection,
          allCollections: allCollections,
          allRequests: allRequests,
        );

        // Assert
        expect(postmanCollection.info.name, 'Test Collection');
        expect(postmanCollection.item.length, 1);
        expect(postmanCollection.item.first.name, 'Folder');
        expect(postmanCollection.item.first.item?.length, 1);
        expect(postmanCollection.item.first.item?.first.name, 'Nested Request');
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

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'raw');
        expect(requests.first.rawContentType, 'json');
        expect(requests.first.body, '{"key": "value"}');
      });

      test('should map raw body type with uppercase JSON language', () {
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
                    raw: PostmanRawOptions(language: 'JSON'),
                  ),
                ),
              ),
            ),
          ],
        );

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'raw');
        expect(requests.first.rawContentType, 'json');
      });

      test('should infer json from Content-Type header when language is null',
          () {
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test'),
          item: [
            PostmanItem(
              name: 'Raw Request',
              request: PostmanRequest(
                method: 'POST',
                url: const PostmanUrl(raw: 'https://example.com'),
                header: [
                  const PostmanHeader(
                    key: 'Content-Type',
                    value: 'application/json',
                  ),
                ],
                body: PostmanBody(
                  mode: 'raw',
                  raw: '{"key": "value"}',
                  // No options.raw.language
                ),
              ),
            ),
          ],
        );

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'raw');
        expect(requests.first.rawContentType, 'json');
      });

      test('should infer xml from Content-Type header', () {
        final postmanCollection = PostmanCollection(
          info: const PostmanInfo(name: 'Test'),
          item: [
            PostmanItem(
              name: 'Raw Request',
              request: PostmanRequest(
                method: 'POST',
                url: const PostmanUrl(raw: 'https://example.com'),
                header: [
                  const PostmanHeader(
                    key: 'Content-Type',
                    value: 'application/xml',
                  ),
                ],
                body: PostmanBody(
                  mode: 'raw',
                  raw: '<user>test</user>',
                ),
              ),
            ),
          ],
        );

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'raw');
        expect(requests.first.rawContentType, 'xml');
      });

      test('should default to text when no language and no Content-Type', () {
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
                  raw: 'plain text',
                  // No options.raw.language and no Content-Type header
                ),
              ),
            ),
          ],
        );

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'raw');
        expect(requests.first.rawContentType, 'text');
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

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'form-data');
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

        final (_, __, requests) =
            PostmanMapper.toHoppCollectionFlat(postmanCollection);
        expect(requests.first.bodyType, 'x-www-form-urlencoded');
      });
    });
  });
}
