import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/csv_export_service.dart';
import 'package:asisten_keuangan/core/services/biometric_service.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/reports/presentation/reports_screen.dart';

void main() {
  group('CsvExportService Tests', () {
    const service = CsvExportService();

    test('generates valid header row for empty transaction list', () {
      final csv = service.generateCsv([]);
      expect(csv, contains('ID Transaksi'));
      expect(csv, contains('Nominal'));
      expect(csv, contains('Metode Pembayaran'));
    });

    test('generates valid formatted rows for transactions', () {
      final sampleTx = [
        TransactionModel(
          id: 'test_tx_1',
          title: 'Belanja Sayur',
          amount: 45000,
          type: TransactionType.expense,
          category: 'Makanan & Minuman',
          paymentMethod: 'Tunai',
          date: DateTime(2026, 10, 10, 10, 30),
          source: TransactionSource.text,
          notes: 'Pasar Pagi',
        ),
      ];

      final csv = service.generateCsv(sampleTx);
      expect(csv, contains('test_tx_1'));
      expect(csv, contains('Belanja Sayur'));
      expect(csv, contains('Pengeluaran'));
      expect(csv, contains('45000'));
      expect(csv, contains('Pasar Pagi'));
    });
  });

  group('BiometricService Tests', () {
    test('handles availability check gracefully', () async {
      final service = BiometricService();
      final available = await service.isBiometricAvailable();
      expect(available, isA<bool>());
    });
  });

  group('ReportsScreen CSV Export Widget Tests', () {
    testWidgets('renders CSV export action and opens preview modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportIcon = find.byTooltip('Ekspor CSV');
      expect(exportIcon, findsOneWidget);

      await tester.tap(exportIcon);
      await tester.pumpAndSettle();

      expect(find.text('Pratinjau Ekspor CSV'), findsOneWidget);
      expect(find.text('Salin Berkas CSV'), findsOneWidget);
    });
  });
}
