import 'package:campus_navigator/main.dart';
import 'package:campus_navigator/ui/screens/freeroom_search_screen.dart';
import 'package:campus_navigator/ui/screens/search_screen.dart';
import 'package:campus_navigator/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SearchscreenNavigation', (WidgetTester tester) async {
// Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

// Tap the icons and trigger a frame.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(); // Second one bc navigating takes too long?

// Verify the navigationStack has changed correctly
// Settings
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(find.byType(SearchScreen), findsOneWidget);

// Freeroom - TODO: fix http request
    await tester.tap(find.byIcon(Icons.meeting_room));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FreeroomSearchScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

// Location
    /*
    await tester.tap(find.byIcon(Icons.location_on));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LocationScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();*/
  });
}
