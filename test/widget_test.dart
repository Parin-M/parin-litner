import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parin_litner/features/home/home_page.dart';

void main() {
  testWidgets('Parin Litner home renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HomePage(
            decks: [],
            onChanged: () {},
            onImport: () async {},
            onExport: () async {},
                 themeIndex: 0,
                 onThemeChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Parin Litner'), findsOneWidget);
    expect(find.text('دسته‌های یادگیری'), findsOneWidget);
  });
}
