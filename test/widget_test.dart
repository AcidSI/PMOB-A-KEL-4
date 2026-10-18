import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:find_it/main.dart';

void main() {
  testWidgets('Sign-in opens the integrated report list', (tester) async {
    await _openHome(tester);

    expect(find.text('LAPORAN TERBARU'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.byTooltip('Pencarian berbobot'), findsOneWidget);
  });

  testWidgets('A new report flows through detail and chat', (tester) async {
    await _openHome(tester);

    await tester.tap(find.byTooltip('Buat laporan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-lost-report')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('report-name')),
      'Kunci Cadangan',
    );
    await tester.tap(find.byKey(const Key('report-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elektronik').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Kunci dengan gantungan ungu.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-location')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.byKey(const Key('report-location')),
      'Gedung Kuliah',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-report')));
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali ke daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Kunci Cadangan'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kunci Cadangan'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Item'), findsOneWidget);
    await tester.tap(find.text('Chat Pelapor'));
    await tester.pumpAndSettle();
    expect(find.text('Chat untuk laporan Kunci Cadangan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pencarian berbobot'));
    await tester.pumpAndSettle();
    expect(find.text('Kunci Cadangan'), findsOneWidget);
  });
}

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const FindItApp());
  expect(find.byKey(const Key('login-identity')), findsOneWidget);
  expect(find.byKey(const Key('login-password')), findsOneWidget);

  await tester.enterText(
    find.byKey(const Key('login-identity')),
    'mahasiswa@student.unand.ac.id',
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'password123',
  );
  await tester.tap(find.text('Masuk Sivitas'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}
