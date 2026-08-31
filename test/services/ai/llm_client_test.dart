import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/services/ai/llm_client.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/dio.mocks.mocks.dart';

void main() {
  group('LlmClient', () {
    late MockDio mockDio;
    late LlmClient client;

    setUp(() {
      mockDio = MockDio();
      client = LlmClient(dio: mockDio, logger: Logger(level: Level.off));
    });

    Map<String, dynamic> okData({
      String content = '你好，这是解释',
      List<dynamic>? choices,
      Map<String, dynamic>? usage,
    }) =>
        {
          'choices': choices ??
              [
                {
                  'message': {'role': 'assistant', 'content': content},
                },
              ],
          if (usage != null) 'usage': usage,
        };

    void stubChat(Map<String, dynamic> data, {int statusCode = 200}) {
      when(mockDio.request<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      ),).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(),
            statusCode: statusCode,
            data: data,
          ),);
    }

    void stubChatError(DioException error) {
      when(mockDio.request<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
        options: anyNamed('options'),
      ),).thenAnswer((_) async => throw error);
    }

    test('成功返回 choices[0].message.content（含 usage 记录不报错）', () async {
      stubChat(okData(usage: {
        'prompt_tokens': 12,
        'completion_tokens': 34,
        'total_tokens': 46,
      },),);

      final result = await client.chat(
        baseUrl: 'http://localhost:11434/v1',
        model: 'qwen2.5:7b',
        apiKey: '',
        messages: const [LlmMessage.user('hi')],
      );

      expect(result, equals('你好，这是解释'));
    });

    test('baseUrl 带末尾斜杠时归一为单个 /chat/completions', () async {
      stubChat(okData());

      await client.chat(
        baseUrl: 'http://localhost:11434/v1/',
        model: 'm',
        apiKey: '',
        messages: const [LlmMessage.user('hi')],
      );

      final captured = verify(mockDio.request<Map<String, dynamic>>(
        captureAny,
        data: anyNamed('data'),
        options: anyNamed('options'),
      ),).captured;
      expect(captured.first,
          equals('http://localhost:11434/v1/chat/completions'),);
    });

    test('请求体包含 model/messages/temperature=0/stream=false', () async {
      stubChat(okData());

      await client.chat(
        baseUrl: 'http://x/v1',
        model: 'qwen2.5:7b',
        apiKey: '',
        messages: const [
          LlmMessage.system('sys'),
          LlmMessage.user('hi'),
        ],
      );

      final captured = verify(mockDio.request<Map<String, dynamic>>(
        any,
        data: captureAnyNamed('data'),
        options: anyNamed('options'),
      ),).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['model'], equals('qwen2.5:7b'));
      expect(body['temperature'], equals(0));
      expect(body['stream'], isFalse);
      final messages = body['messages'] as List<dynamic>;
      expect(messages.length, equals(2));
      expect(messages.first,
          equals({'role': 'system', 'content': 'sys'}),);
    });

    test('apiKey 为空时不带 Authorization 头', () async {
      stubChat(okData());

      await client.chat(
        baseUrl: 'http://x/v1',
        model: 'm',
        apiKey: '',
        messages: const [LlmMessage.user('hi')],
      );

      final captured = verify(mockDio.request<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
        options: captureAnyNamed('options'),
      ),).captured;
      final options = captured.first as Options;
      expect(options.headers, isNot(contains('Authorization')));
    });

    test('apiKey 非空时带 Bearer Authorization 头', () async {
      stubChat(okData());

      await client.chat(
        baseUrl: 'http://x/v1',
        model: 'm',
        apiKey: 'sk-test',
        messages: const [LlmMessage.user('hi')],
      );

      final captured = verify(mockDio.request<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
        options: captureAnyNamed('options'),
      ),).captured;
      final options = captured.first as Options;
      expect(options.headers!['Authorization'], equals('Bearer sk-test'));
    });

    test('connectionError → LlmConnectionException（未检测到本地模型服务）',
        () async {
      stubChatError(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        message: 'SocketException: Connection refused',
      ),);

      expect(
        () => client.chat(
          baseUrl: 'http://localhost:11434/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmConnectionException>().having(
          (e) => e.message,
          'message',
          contains('未检测到本地模型服务'),
        ),),
      );
    });

    test('receiveTimeout → LlmConnectionException（响应超时提示）', () async {
      stubChatError(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout,
        message: 'Receiving data timeout',
      ),);

      expect(
        () => client.chat(
          baseUrl: 'http://localhost:11434/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmConnectionException>().having(
          (e) => e.message,
          'message',
          contains('响应超时'),
        ),),
      );
    });

    test('400 带 OpenAI 风格 error.message → LlmHttpException 且消息透传',
        () async {
      stubChatError(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(),
          statusCode: 400,
          data: {
            'error': {'message': 'model "m" not found'},
          },
        ),
      ),);

      expect(
        () => client.chat(
          baseUrl: 'http://x/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', equals(400))
            .having((e) => e.message, 'message',
                contains('model "m" not found'),),),
      );
    });

    test('非 2xx 直接返回（无 DioException）也归并为 LlmHttpException', () async {
      stubChat(
        {'error': {'message': 'internal boom'}},
        statusCode: 500,
      );

      expect(
        () => client.chat(
          baseUrl: 'http://x/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', equals(500))
            .having(
                (e) => e.message, 'message', contains('internal boom'),),),
      );
    });

    test('choices 为空 → LlmResponseException', () async {
      stubChat(okData(choices: const []));

      expect(
        () => client.chat(
          baseUrl: 'http://x/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmResponseException>()),
      );
    });

    test('message.content 缺失 → LlmResponseException', () async {
      stubChat({
        'choices': [
          {'message': {}},
        ],
      });

      expect(
        () => client.chat(
          baseUrl: 'http://x/v1',
          model: 'm',
          apiKey: '',
          messages: const [LlmMessage.user('hi')],
        ),
        throwsA(isA<LlmResponseException>()),
      );
    });
  });
}
