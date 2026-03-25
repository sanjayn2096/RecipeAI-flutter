// Basic Flutter widget test for RecipeAI app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_ai/main.dart';

void main() {
  testWidgets('RecipeAiApp builds with minimal router', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(RecipeAiApp(router: router));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
