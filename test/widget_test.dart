// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nama_project/data/item_repository.dart';
import 'package:nama_project/main.dart';
import 'package:nama_project/models/item.dart';
import 'package:nama_project/routes/app_routes.dart';
import 'package:nama_project/screens/home_screen.dart';

void main() {
  // Uji alur validasi login, kirim item, dan terima hasil catatan.
  testWidgets('login validates and saves a note from item detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FindItApp());

    await tester.tap(find.text('Masuk Sivitas'));
    await tester.pump();
    expect(find.text('Email Institusi / NIP wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-identity')), 'user@unand.ac.id');
    await tester.enterText(find.byKey(const Key('login-password')), 'password1');
    await tester.tap(find.text('Masuk Sivitas'));
    await tester.pumpAndSettle();

    expect(find.text('LAPORAN TERBARU'), findsOneWidget);
    await tester.tap(find.text('Earphone Bluetooth').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Item'), findsOneWidget);
    expect(find.text('Ditemukan di dekat Masjid Unand'), findsOneWidget);

    await tester.tap(find.text('Tulis Catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Cek lokasi barang');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan: Cek lokasi barang'), findsOneWidget);
  });

  testWidgets('login validates only the field the user has edited', (
    tester,
  ) async {
    await tester.pumpWidget(const FindItApp());

    await tester.enterText(find.byKey(const Key('login-identity')), 'invalid');
    await tester.pump();
    expect(find.text('Masukkan email institusi atau NIP yang valid'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsNothing);

    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tester.pump();
    expect(find.text('Password minimal 8 karakter'), findsOneWidget);
  });

  testWidgets('error screen retries and loads the report list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _FailOnceRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laporan belum dapat dimuat'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('LAPORAN TERBARU'), findsOneWidget);
    expect(find.text('Earphone Bluetooth'), findsOneWidget);
  });

  testWidgets('empty repository displays the empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          repository: ItemRepository(items: [], fetchDelay: Duration.zero),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada laporan yang cocok.'), findsOneWidget);
  });

  testWidgets('unknown named route displays the 404 screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onUnknownRoute: AppRoutes.onUnknownRoute,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/route-404'),
              child: const Text('Buka route'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka route'));
    await tester.pumpAndSettle();

    expect(find.text('Halaman Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Route /route-404 tidak tersedia.'), findsOneWidget);
  });
}

class _FailOnceRepository extends ItemRepository {
  int _requestCount = 0;

  @override
  Future<List<Item>> fetchItems({bool simulateError = false}) async {
    _requestCount++;
    if (_requestCount == 1) {
      throw Exception('Gagal memuat data. Periksa koneksi internet.');
    }
    return const ItemRepository(fetchDelay: Duration.zero).fetchItems();
  }
}
