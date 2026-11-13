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

  testWidgets('Matching claim is reviewed and resolved by both users', (
    tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.byTooltip('Matching, klaim & notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Matching & Klaim'), findsOneWidget);
    expect(find.textContaining('Laptop ASUS'), findsWidgets);

    await tester.tap(find.text('Ajukan klaim').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('claim-answers')),
      'Stiker dekat engsel kiri',
    );
    await tester.enterText(
      find.byKey(const Key('claim-reason')),
      'Laptop saya hilang setelah kelas.',
    );
    await tester.enterText(
      find.byKey(const Key('claim-evidence')),
      'Saya memiliki bukti pembelian.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-claim')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('submit-claim')));
    await tester.pumpAndSettle();
    expect(find.text('Buka klaim'), findsOneWidget);

    await tester.tap(find.text('Buka klaim'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('claim-comment')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.byKey(const Key('claim-comment')),
      'Saya dapat menunjukkan bukti pembelian.',
    );
    await tester.tap(find.byTooltip('Kirim komentar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Saya dapat menunjukkan bukti pembelian.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();
    await _signIn(tester, 'founder@student.unand.ac.id');

    await tester.tap(find.byTooltip('Matching, klaim & notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klaim masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop ASUS').first);
    await tester.pumpAndSettle();
    expect(find.text('Ada stiker kecil di dekat engsel kiri.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Saya setuju membagikan WhatsApp setelah disetujui'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Saya setuju membagikan WhatsApp setelah disetujui'),
    );
    await tester.scrollUntilVisible(
      find.text('Setujui klaim'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Setujui klaim'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();
    await _signIn(tester, 'mahasiswa@student.unand.ac.id');
    await tester.tap(find.byTooltip('Matching, klaim & notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka klaim').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Disetujui'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Konfirmasi barang diserahkan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Konfirmasi barang diserahkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi barang diserahkan'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();
    await _signIn(tester, 'founder@student.unand.ac.id');
    await tester.tap(find.byTooltip('Matching, klaim & notifikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Klaim masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop ASUS').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Konfirmasi barang diserahkan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Konfirmasi barang diserahkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi barang diserahkan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Laporan selesai'), findsOneWidget);
  });
}

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const FindItApp());
  await _signIn(tester, 'mahasiswa@student.unand.ac.id');
}

Future<void> _signIn(WidgetTester tester, String email) async {
  expect(find.byKey(const Key('login-identity')), findsOneWidget);
  expect(find.byKey(const Key('login-password')), findsOneWidget);

  await tester.enterText(find.byKey(const Key('login-identity')), email);
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'password123',
  );
  await tester.tap(find.text('Masuk Sivitas'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}
