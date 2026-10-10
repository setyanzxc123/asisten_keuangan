import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/firestore_transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, List<TransactionModel>> _storage = {};
  final Map<String, double> _budgets = {};
  final StreamController<List<TransactionModel>> _controller =
      StreamController<List<TransactionModel>>.broadcast();

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _controller.stream;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    return _storage[userId] ?? [];
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    final list = _storage[userId] ?? [];
    list.insert(0, transaction);
    _storage[userId] = list;
    _controller.add(List.from(list));
  }

  @override
  Future<void> updateTransaction(String userId, TransactionModel transaction) async {
    final list = _storage[userId] ?? [];
    final idx = list.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      list[idx] = transaction;
      _storage[userId] = list;
      _controller.add(List.from(list));
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    final list = _storage[userId] ?? [];
    list.removeWhere((t) => t.id == transactionId);
    _storage[userId] = list;
    _controller.add(List.from(list));
  }

  @override
  Future<double> getMonthlyBudget(String userId) async {
    return _budgets[userId] ?? 5000000.0;
  }

  @override
  Future<void> setMonthlyBudget(String userId, double budget) async {
    _budgets[userId] = budget;
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('TransactionModel Serialization Tests', () {
    test('toMap converts model into expected dictionary', () {
      final tx = TransactionModel(
        id: 'tx_test_1',
        title: 'Beli Kopi',
        amount: 25000,
        type: TransactionType.expense,
        category: 'Makanan & Minuman',
        paymentMethod: 'QRIS',
        date: DateTime(2026, 10, 10, 12, 0),
        source: TransactionSource.text,
      );

      final map = tx.toMap();
      expect(map['id'], equals('tx_test_1'));
      expect(map['title'], equals('Beli Kopi'));
      expect(map['amount'], equals(25000));
      expect(map['type'], equals('expense'));
      expect(map['source'], equals('text'));
    });

    test('fromMap restores TransactionModel instance accurately', () {
      final map = {
        'id': 'tx_test_2',
        'title': 'Bonus Proyek',
        'amount': 2500000,
        'type': 'income',
        'category': 'Pendapatan',
        'paymentMethod': 'Transfer Bank',
        'date': '2026-10-10T12:00:00.000',
        'source': 'text',
      };

      final tx = TransactionModel.fromMap(map);
      expect(tx.id, equals('tx_test_2'));
      expect(tx.title, equals('Bonus Proyek'));
      expect(tx.amount, equals(2500000));
      expect(tx.type, equals(TransactionType.income));
    });
  });

  group('TransactionRepository & Notifier Sync Tests', () {
    late FakeTransactionRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTransactionRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('addTransaction notifies repository and modifies state', () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final newTx = TransactionModel(
        id: 'tx_sync_1',
        title: 'Investasi Saham',
        amount: 1000000,
        type: TransactionType.expense,
        category: 'Investasi',
        paymentMethod: 'RDI',
        date: DateTime.now(),
        source: TransactionSource.text,
      );

      container.read(transactionProvider.notifier).addTransaction(newTx);

      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.id == 'tx_sync_1'), isTrue);

      final repoStored = await fakeRepo.getTransactions('local_offline_user');
      expect(repoStored.any((t) => t.id == 'tx_sync_1'), isTrue);
    });

    test('deleteTransaction updates state and notifies repository', () async {
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(transactionProvider.notifier);
      final initialTx = container.read(transactionProvider).transactions.first;

      notifier.deleteTransaction(initialTx.id);

      final state = container.read(transactionProvider);
      expect(state.transactions.any((t) => t.id == initialTx.id), isFalse);
    });
  });
}
