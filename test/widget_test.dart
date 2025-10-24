// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pihole_client/main.dart';

void main() {
  testWidgets('Pi-hole app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the default category 'Groups'.
    expect(find.text('Groups'), findsAtLeastNWidgets(1));
    
    // Verify that the master-detail structure is present.
    expect(find.byType(ListView), findsWidgets);
    
    // Verify that some category items are present in the left panel.
    expect(find.text('Clients'), findsOneWidget);
    expect(find.text('Domains'), findsOneWidget);
  });
}
