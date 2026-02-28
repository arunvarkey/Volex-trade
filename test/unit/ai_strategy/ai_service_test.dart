// test/unit/ai_strategy/ai_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:volex_terminal/features/simulator/ai_strategy/models/generated_strategy.dart';
import 'package:volex_terminal/core/services/secure_key_storage.dart';
import 'package:volex_terminal/features/simulator/ai_strategy/services/ai_service.dart';

@GenerateMocks([http.Client, SecureKeyStorage])
import 'ai_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late MockSecureKeyStorage mockStorage;
  late AIService service;

  setUp(() {
    mockClient = MockClient();
    mockStorage = MockSecureKeyStorage();
    service = AIService(allowDelay: false);

    // Default: Return a key from storage
    when(mockStorage.getApiKey()).thenAnswer((_) async => 'sk-test-key');
  });

  const validStrategyJson = '''
  {
    "name": "Test Strat",
    "description": "Desc",
    "entryConditions": [{"indicator": "RSI", "comparator": "<", "value": 30}],
    "exitConditions": [],
    "riskParams": {"stopLossPercent": 2.0, "takeProfitPercent": 4.0, "positionSizePercent": 10.0},
    "educationalExplanation": "Valid",
    "confidenceScore": 0.8
  }
  ''';

  // Mock successful response wrapper
  http.Response successResponse(String body) => http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'content': body}
          }
        ]
      }),
      200);

  http.Response errorResponse(int code) => http.Response('Error', code);

  group('AIService.generateStrategy',
      skip: 'Requires mocked Firebase App initialization for Cloud Functions',
      () {
    test('succeeds with valid key and response', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse(validStrategyJson));

      final strategy = await service.generateStrategy(userPrompt: 'Test');

      expect(strategy.name, 'Test Strat');
      verify(mockStorage.getApiKey()).called(1);
    });

    test('throws missingKey if storage returns null', () async {
      when(mockStorage.getApiKey()).thenAnswer((_) async => null);

      await expectLater(
        () => service.generateStrategy(userPrompt: 'Test'),
        throwsA(isA<AiStrategyError>()
            .having((e) => e.type, 'type', AiErrorType.missingKey)),
      );
    });

    test('throws invalidKey on 401 response', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => errorResponse(401));

      await expectLater(
        () => service.generateStrategy(userPrompt: 'Test'),
        throwsA(isA<AiStrategyError>()
            .having((e) => e.type, 'type', AiErrorType.invalidKey)),
      );
    });

    test('throws rateLimit on 429 response', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => errorResponse(429));

      await expectLater(
        () => service.generateStrategy(userPrompt: 'Test'),
        throwsA(isA<AiStrategyError>()
            .having((e) => e.type, 'type', AiErrorType.rateLimit)),
      );
    });

    test('throws validation error if parsing fails logic check', () async {
      const invalidBoundsJson = '''
      {
        "name": "Bad parameters",
        "description": "Desc",
        "entryConditions": [{"indicator": "RSI", "comparator": "<", "value": 150}],
        "exitConditions": [],
        "riskParams": {"stopLossPercent": 1, "takeProfitPercent": 1, "positionSizePercent": 1},
        "educationalExplanation": "",
        "confidenceScore": 1.0
      }
      ''';

      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => successResponse(invalidBoundsJson));

      await expectLater(
        () => service.generateStrategy(userPrompt: 'Test'),
        throwsA(isA<StrategyValidationException>()),
      );
    });

    test('retries on 429 and eventually succeeds', () async {
      // First call returns 429, Second returns 200
      int callCount = 0;
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return errorResponse(429);
        return successResponse(validStrategyJson);
      });

      final strategy = await service.generateStrategy(userPrompt: 'Test');

      expect(strategy.name, 'Test Strat');
      expect(callCount, 2); // Should have called twice
    });

    test('retries 3 times then fails on persistent 500', () async {
      when(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => errorResponse(500));

      await expectLater(
        () => service.generateStrategy(userPrompt: 'Test'),
        throwsA(isA<AiStrategyError>()
            .having((e) => e.type, 'type', AiErrorType.networkError)),
      );

      verify(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .called(3);
    });
  });
}
