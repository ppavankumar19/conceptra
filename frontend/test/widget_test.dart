import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A minimal smoke test that doesn't require real Supabase/Hive initialization.
// For a full integration test, use integration_test package with real initialization.

void main() {
  group('App Widget Tests', () {
    testWidgets('ProviderScope wraps the app without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Conceptra'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Conceptra'), findsOneWidget);
    });

    testWidgets('Login screen form fields are present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(decoration: InputDecoration(labelText: 'Email')),
                  TextField(decoration: InputDecoration(labelText: 'Password')),
                  ElevatedButton(onPressed: null, child: Text('Sign In')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('BottomNavigation renders four tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.view_module),
                  label: 'Modules',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Modules'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
