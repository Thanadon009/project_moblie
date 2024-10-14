import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:project2/screens/login_screen.dart';

class MockFirebasePlatform extends MockPlatformInterfaceMixin
    implements FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FirebaseAppPlatform(
        name,
        FirebaseOptions(
          apiKey: 'fake_api_key',
          appId: 'fake_app_id',
          messagingSenderId: 'fake_messaging_sender_id',
          projectId: 'fake_project_id',
        ));
  }

  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String? name, FirebaseOptions? options}) async {
    return FirebaseAppPlatform(
        name ?? defaultFirebaseAppName,
        options ??
            FirebaseOptions(
              apiKey: 'fake_api_key',
              appId: 'fake_app_id',
              messagingSenderId: 'fake_messaging_sender_id',
              projectId: 'fake_project_id',
            ));
  }

  @override
  List<FirebaseAppPlatform> get apps =>
      []; // ปรับให้เป็น List<FirebaseAppPlatform>
}

void main() {
  setUpAll(() async {
    // Mock the platform interface for Firebase
    FirebasePlatform.instance = MockFirebasePlatform();

    // เรียก Firebase.initializeApp() เพื่อเตรียมการใช้งาน Firebase ในการทดสอบ
    await Firebase.initializeApp();
  });

  testWidgets('LoginScreen has email, password fields and login button',
      (WidgetTester tester) async {
    final mockFirebaseAuth = FirebaseAuth.instance;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(firebaseAuth: mockFirebaseAuth),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account yet?"), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // เลื่อนหน้าจอให้ปุ่ม Login มองเห็นได้
    await tester.ensureVisible(find.text('Login'));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.textContaining('Please enter'), findsNothing);
  });
}
