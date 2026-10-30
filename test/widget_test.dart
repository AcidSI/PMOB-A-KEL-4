// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:findit/data/item_repository.dart';
import 'package:findit/main.dart';
import 'package:findit/models/item.dart';
import 'package:findit/routes/app_routes.dart';
import 'package:findit/screens/add_report_screen.dart';
import 'package:findit/screens/home_screen.dart';

void main() {
  // Uji alur login serta navigasi detail ke halaman chat pelapor.
  testWidgets('login validates and opens chat from item detail', (
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

    await tester.enterText(
      find.byKey(const Key('login-identity')),
      'user@unand.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password1',
    );
    await tester.tap(find.text('Masuk Sivitas'));
    await tester.pumpAndSettle();

    expect(find.text('LAPORAN TERBARU'), findsOneWidget);
    await tester.tap(find.text('Earphone Bluetooth').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Item'), findsOneWidget);
    expect(find.text('Ditemukan di dekat Masjid Unand'), findsOneWidget);

    await tester.tap(find.text('Chat Pelapor'));
    await tester.pumpAndSettle();
    expect(find.text('Chat untuk laporan Earphone Bluetooth'), findsOneWidget);
  });

  testWidgets('login validates only the field the user has edited', (
    tester,
  ) async {
    await tester.pumpWidget(const FindItApp());

    await tester.enterText(find.byKey(const Key('login-identity')), 'invalid');
    await tester.pump();
    expect(
      find.text('Masukkan email institusi atau NIP yang valid'),
      findsOneWidget,
    );
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

  testWidgets('report form validates and returns a new report to Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: HomeScreen(
          repository: const ItemRepository(fetchDelay: Duration.zero),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-create-report')));
    await tester.pumpAndSettle();

    expect(find.byType(AddReportScreen), findsOneWidget);
    expect(find.text('Buat Laporan Barang Hilang'), findsOneWidget);
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submit-report')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('report-name')), 'Kunci motor');
    await tester.pump();
    expect(find.text('Nama barang wajib diisi'), findsNothing);
    expect(find.text('Kategori wajib diisi'), findsNothing);
    expect(find.text('Deskripsi wajib diisi'), findsNothing);
    expect(find.text('Lokasi wajib diisi'), findsNothing);
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pumpAndSettle();
    expect(find.text('Nama barang wajib diisi'), findsNothing);
    expect(find.text('Kategori wajib diisi'), findsOneWidget);
    expect(find.text('Deskripsi wajib diisi'), findsOneWidget);
    expect(find.text('Lokasi wajib diisi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('report-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aksesori').last);
    await tester.pumpAndSettle();
    expect(find.text('Kategori wajib diisi'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('report-description')));
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Gantungan kunci merah.',
    );
    await tester.pump();
    expect(find.text('Deskripsi wajib diisi'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('report-location')));
    await tester.enterText(
      find.byKey(const Key('report-location')),
      'Perpustakaan Unand',
    );
    await tester.pump();
    expect(find.text('Lokasi wajib diisi'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('submit-report')));
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pump();
    expect(find.text('Mengirim laporan...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Laporan berhasil dikirim'), findsOneWidget);
    await tester.tap(find.text('Kembali ke daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Kunci motor'), findsOneWidget);
    expect(find.text('Aksesori'), findsWidgets);
    await tester.tap(find.text('Kunci motor').first);
    await tester.pumpAndSettle();
    expect(find.text('Aksesori'), findsOneWidget);
    expect(find.text('Gantungan kunci merah.'), findsOneWidget);
    await tester.tap(find.text('Chat Pelapor'));
    await tester.pumpAndSettle();
    expect(find.text('Chat untuk laporan Kunci motor'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Laporan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(find.text('Kunci motor'), findsNothing);
  });

  testWidgets('found-item report opens its own fixed form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddReportScreen(isFound: true)),
    );

    expect(find.text('Buat Laporan Barang Ditemukan'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Lokasi Ditemukan'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SegmentedButton<bool>), findsNothing);
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
