// This is a basic Flutter widget test for the Fire Alarm Monitoring app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/auth/auth_navigation.dart';

void main() {
  group('Fire Alarm App Tests', () {
    testWidgets('App builds without crashing', (WidgetTester tester) async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      
      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });
    
    testWidgets('App shows AuthNavigation initially', (WidgetTester tester) async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      
      // Verify that AuthNavigation is shown (initial screen)
      expect(find.byType(AuthNavigation), findsOneWidget);
    });
  });
}
