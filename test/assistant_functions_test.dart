import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/financial_functions_service.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/transactions/data/firestore_transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';

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
    return _budgets[userId] ?? 15000000.0;
  }

  @override
  Future<void> setMonthlyBudget(String userId, double budget) async {
    _budgets[userId] = budget;
  }

  void dispose() {
    _controller.close();
  }
}

class FakeSuccessFunctionsService extends FinancialFunctionsService {
  final FinancialIntentResult result;

  FakeSuccessFunctionsService(this.result);

  @override
  Future<FinancialIntentResult?> processFinancialIntent(String text) async {
    return result;
  }
}

void main() {
  group('FinancialIntentResult Tests', () {
    test('parses json map into structured response', () {
      final map = {
        'intent': 'RECORD_TRANSACTION',
        'isClarificationNeeded': false,
        'clarificationQuestion': null,
        'bankerNarrative': 'Transaksi kopi dicatat dengan aman.',
        'transaction': {
          'title': 'Kopi Cold Brew',
          'amount': 45000,
          'type': 'EXPENSE',
          'category': 'Makanan & Minuman',
          'paymentMethod': 'QRIS',
        },
      };

      final parsed = FinancialIntentResult.fromMap(map);
      expect(parsed.intent, equals('RECORD_TRANSACTION'));
      expect(parsed.isClarificationNeeded, isFalse);
      expect(parsed.bankerNarrative, equals('Transaksi kopi dicatat dengan aman.'));
      expect(parsed.transaction?['title'], equals('Kopi Cold Brew'));
      expect(parsed.transaction?['amount'], equals(45000));
    });

    test('FinancialFunctionsService handles uninitialized Firebase gracefully', () async {
      final service = FinancialFunctionsService();
      final result = await service.processFinancialIntent('test intent');
      expect(result, isNull);
    });
  });

  group('AssistantNotifier with Cloud Functions Integration Tests', () {
    test('processes RECORD_TRANSACTION from cloud callable and commits transaction', () async {
      final fakeRepo = FakeTransactionRepository();
      final fakeResult = FinancialIntentResult(
        intent: 'RECORD_TRANSACTION',
        isClarificationNeeded: false,
        bankerNarrative: 'Pembelian laptop berhasil dibukukan dalam portofolio Anda.',
        transaction: {
          'title': 'Laptop Kerja',
          'amount': 15000000,
          'type': 'EXPENSE',
          'category': 'Peralatan Kantor',
          'paymentMethod': 'Transfer Bank',
        },
      );

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
          financialFunctionsServiceProvider.overrideWithValue(
            FakeSuccessFunctionsService(fakeResult),
          ),
        ],
      );
      addTearDown(() {
        fakeRepo.dispose();
        container.dispose();
      });

      final notifier = container.read(assistantProvider.notifier);
      await notifier.sendUserMessage(text: 'Beli laptop 15 juta transfer');

      final assistantState = container.read(assistantProvider);
      expect(assistantState.isThinking, isFalse);
      expect(assistantState.messages.length, greaterThanOrEqualTo(2));

      final lastMessage = assistantState.messages.last;
      expect(lastMessage.sender, equals(MessageSender.banker));
      expect(lastMessage.status, equals(MessageStatus.committed));
      expect(lastMessage.extractedTransaction?.title, equals('Laptop Kerja'));

      final txState = container.read(transactionProvider);
      expect(txState.transactions.any((tx) => tx.title == 'Laptop Kerja'), isTrue);
    });

    test('handles clarification required status from cloud intent', () async {
      final fakeRepo = FakeTransactionRepository();
      final fakeClarifyResult = FinancialIntentResult(
        intent: 'RECORD_TRANSACTION',
        isClarificationNeeded: true,
        clarificationQuestion: 'Mohon konfirmasi metode pembayaran pengeluaran ini.',
        bankerNarrative: 'Pencatatan ditangguhkan menunggu metode pembayaran.',
        transaction: {
          'title': 'Langganan Server',
          'amount': 2500000,
          'type': 'EXPENSE',
          'category': 'Teknologi',
          'paymentMethod': 'Belum Ditentukan',
        },
      );

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
          financialFunctionsServiceProvider.overrideWithValue(
            FakeSuccessFunctionsService(fakeClarifyResult),
          ),
        ],
      );
      addTearDown(() {
        fakeRepo.dispose();
        container.dispose();
      });

      final notifier = container.read(assistantProvider.notifier);
      await notifier.sendUserMessage(text: 'Langganan server 2.5 juta');

      final assistantState = container.read(assistantProvider);
      expect(assistantState.pendingTransaction, isNotNull);

      final lastMessage = assistantState.messages.last;
      expect(lastMessage.status, equals(MessageStatus.pendingClarification));

      await notifier.sendUserMessage(text: 'Bayar pakai kartu kredit');

      final updatedState = container.read(assistantProvider);
      expect(updatedState.pendingTransaction, isNull);
      expect(updatedState.messages.last.status, equals(MessageStatus.committed));

      final txState = container.read(transactionProvider);
      expect(txState.transactions.any((tx) => tx.paymentMethod == 'Kartu Kredit'), isTrue);
    });
  });
}
