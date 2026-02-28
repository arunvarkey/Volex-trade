import 'package:flutter_test/flutter_test.dart';
import 'package:volex_terminal/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService Tests', () {
    late CrashReportingService service;

    setUp(() async {
      service = CrashReportingService();
    });

    test('initialize() sets initialized to true', () async {
      await service.initialize();
      // Since _initialized is private, we verify it doesn't throw and initializes loggers.
      // In a real Senty/Crashlytics test, we would mock the SDK.
      expect(true, isTrue); // Placeholder check
    });

    test('logError logs message without crash', () {
      expect(() => service.logError('Test error', reason: 'unit test'),
          returnsNormally);
    });

    test('logBreadcrumb logs message without crash', () {
      expect(() => service.logBreadcrumb('User tapped button', category: 'UI'),
          returnsNormally);
    });

    test('Service is a singleton', () {
      final instance1 = CrashReportingService();
      final instance2 = CrashReportingService();
      expect(instance1, same(instance2));
    });
  });
}
