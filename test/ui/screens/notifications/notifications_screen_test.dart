import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:volex_terminal/ui/screens/notifications/notifications_screen.dart';
import 'package:volex_terminal/engine/notifications/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../test_helper.dart';

void main() {
  late MockNotificationBus mockNotificationBus;
  late MockAuthService mockAuthService;
  late StreamController<List<VolexNotification>> notificationStreamController;

  setUp(() {
    mockNotificationBus = MockNotificationBus();
    mockAuthService = MockAuthService();
    notificationStreamController = StreamController<List<VolexNotification>>();

    // Setup Locator
    setupServiceLocator(
      notificationBus: mockNotificationBus,
      authService: mockAuthService,
    );

    // Default Stubs
    when(mockNotificationBus.historyStream)
        .thenAnswer((_) => notificationStreamController.stream);
    when(mockNotificationBus.history).thenReturn([]);

    // Mock user
    MockUser mockUser = MockUser();
    when(mockUser.uid).thenReturn('test_user_id');
    when(mockAuthService.currentUser).thenReturn(mockUser);
  });

  tearDown(() {
    notificationStreamController.close();
  });

  testWidgets('NotificationsScreen shows empty state when no notifications',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    // Initial state is empty list
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('NotificationsScreen shows list of notifications',
      (WidgetTester tester) async {
    final notification = VolexNotification(
      id: '1',
      title: 'Test Title',
      message: 'Test Message',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      severity: NotificationSeverity.info,
      userId: 'test_user_id',
      isRead: false,
    );

    when(mockNotificationBus.history).thenReturn([notification]);

    // Emit list
    notificationStreamController.add([notification]);

    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pump(); // Process stream event

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Message'), findsOneWidget);
  });

  testWidgets('Tapping notification marks as read',
      (WidgetTester tester) async {
    final notification = VolexNotification(
      id: '1',
      title: 'Test Title',
      message: 'Test Message',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      severity: NotificationSeverity.info,
      userId: 'test_user_id',
      isRead: false,
    );

    when(mockNotificationBus.history).thenReturn([notification]);
    notificationStreamController.add([notification]);

    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pump();

    await tester.tap(find.text('Test Title'));

    verify(mockNotificationBus.markAsRead('1')).called(1);
  });

  testWidgets('Mark all as read uses current user id',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    // Tap mark all read button
    await tester.tap(find.byIcon(Icons.done_all));

    // Corrected expectation: verify markAllAsRead is called with the user ID 'test_user_id'
    verify(mockNotificationBus.markAllAsRead('test_user_id')).called(1);
  });
}

// Mock User class since it's difficult to mock FirebaseAuth User directly sometimes
class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_id';
}
