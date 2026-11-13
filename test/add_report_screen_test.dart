import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_it/features/report/models/report.dart';
import 'package:find_it/features/report/screens/add_report_screen.dart';

void main() {
  testWidgets('optional item details are retained on the report', (
    tester,
  ) async {
    Item? submittedItem;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  submittedItem = await Navigator.push<Item>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddReportScreen(isFound: false),
                    ),
                  );
                },
                child: const Text('Open report'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('report-name')), 'Dompet');
    await tester.tap(find.text('Elektronik'));
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Dompet beritsleting.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-location')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('report-location')),
      'Perpustakaan',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-color')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('report-color')), 'Hitam');
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-brand')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('report-brand')), 'Eiger');
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-secret-detail')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('report-secret-detail')),
      'Ada stiker kecil di bagian dalam.',
    );
    await tester.tap(find.byKey(const Key('submit-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali ke daftar'));
    await tester.pumpAndSettle();

    expect(submittedItem, isNotNull);
    expect(submittedItem!.color, 'Hitam');
    expect(submittedItem!.brand, 'Eiger');
    expect(submittedItem!.secretDetail, 'Ada stiker kecil di bagian dalam.');
    expect(submittedItem!.isFound, isFalse);
  });
}
