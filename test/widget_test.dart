import 'package:flutter_test/flutter_test.dart';

import 'package:riwayat_belanjaku/main.dart';

void main() {
  testWidgets('tapping See More opens the full history screen', (tester) async {
    await tester.pumpWidget(const ReceiptApp());

    expect(find.text('Riwayat Terbaru'), findsOneWidget);

    await tester.tap(find.text('See More'));
    await tester.pumpAndSettle();

    expect(find.text('Semua Riwayat'), findsOneWidget);
    expect(find.text('Indomaret'), findsOneWidget);
  });

  testWidgets('tapping a history entry opens its detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ReceiptApp());

    await tester.tap(find.text('See More'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Indomaret'));
    await tester.pumpAndSettle();

    expect(find.text('Item'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Harga'), findsOneWidget);
  });
}
