import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('TransactionNotifier mutation tests', () {
    test('updates transaction in state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialList = container.read(transactionProvider).transactions;
      final target = initialList.first;
      final updated = target.copyWith(title: 'Updated Title', amount: 99999);

      container.read(transactionProvider.notifier).updateTransaction(updated);

      final state = container.read(transactionProvider);
      final found = state.transactions.firstWhere((t) => t.id == target.id);
      expect(found.title, equals('Updated Title'));
      expect(found.amount, equals(99999));
    });

    test('deletes transaction from state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialList = container.read(transactionProvider).transactions;
      final target = initialList.first;

      container.read(transactionProvider.notifier).deleteTransaction(target.id);

      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.id == target.id), isFalse);
    });
  });

  group('Dashboard transaction card gestures tests', () {
    testWidgets('renders Dismissible with swipe backgrounds for each transaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsWidgets);
      expect(find.text('Mutasi Terakhir'), findsOneWidget);
      expect(find.text('Geser untuk edit atau hapus'), findsOneWidget);
    });
  });
}
