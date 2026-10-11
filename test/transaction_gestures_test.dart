import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/presentation/transaction_history_screen.dart';
import 'package:asisten_keuangan/features/dashboard/presentation/dashboard_screen.dart';

TransactionModel buildSampleTx() {
  return TransactionModel(
    id: 'tx-test-1',
    title: 'Kopi Pagi',
    amount: 20000,
    type: TransactionType.expense,
    category: 'Makanan & Minuman',
    paymentMethod: 'QRIS',
    date: DateTime.now(),
    source: TransactionSource.text,
  );
}

void main() {
  group('TransactionNotifier mutation tests', () {
    test('updates transaction in state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sample = buildSampleTx();
      container.read(transactionProvider.notifier).addTransaction(sample);
      final updated = sample.copyWith(title: 'Updated Title', amount: 99999);

      container.read(transactionProvider.notifier).updateTransaction(updated);

      final state = container.read(transactionProvider);
      final found = state.transactions.firstWhere((t) => t.id == sample.id);
      expect(found.title, equals('Updated Title'));
      expect(found.amount, equals(99999));
    });

    test('deletes transaction from state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sample = buildSampleTx();
      container.read(transactionProvider.notifier).addTransaction(sample);

      container.read(transactionProvider.notifier).deleteTransaction(sample.id);

      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.id == sample.id), isFalse);
    });

    test('starts in loading state and exposes empty data without seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(transactionProvider);
      expect(state.transactions, isEmpty);
    });
  });

  group('Dashboard transaction card gestures tests', () {
    testWidgets('renders Dismissible with swipe backgrounds for each transaction',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(transactionProvider.notifier)
          .addTransaction(buildSampleTx());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsWidgets);
      expect(find.text('Mutasi Terakhir'), findsOneWidget);
      expect(find.text('Geser atau buka menu untuk mengelola'), findsOneWidget);
      expect(find.text('Lihat Semua Transaksi'), findsOneWidget);
    });

    testWidgets('renders row overflow menu as swipe alternative',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(transactionProvider.notifier)
          .addTransaction(buildSampleTx());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Aksi transaksi'), findsOneWidget);
    });
  });

  group('Transaction history screen tests', () {
    testWidgets('renders search field, month filter, and rows', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(transactionProvider.notifier)
          .addTransaction(buildSampleTx());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TransactionHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Semua Transaksi'), findsOneWidget);
      expect(find.text('Cari judul atau kategori...'), findsOneWidget);
      expect(find.text('Kopi Pagi'), findsOneWidget);
      expect(find.byTooltip('Aksi transaksi'), findsOneWidget);
    });
  });
}
