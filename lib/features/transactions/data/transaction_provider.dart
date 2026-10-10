import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/firestore_transaction_repository.dart';
import 'package:asisten_keuangan/core/services/firebase_auth_service.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double monthlyBudget;

  const TransactionState({
    required this.transactions,
    this.monthlyBudget = 5000000,
  });

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netCashflow => totalIncome - totalExpense;

  double get remainingBudget => monthlyBudget - totalExpense;

  double get budgetUsedPercentage {
    if (monthlyBudget <= 0) return 0;
    final ratio = totalExpense / monthlyBudget;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    double? monthlyBudget,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  TransactionRepository? _repository;
  String? _userId;

  @override
  TransactionState build() {
    _repository = ref.watch(transactionRepositoryProvider);
    final userAsync = ref.watch(currentUserIdProvider);
    _userId = userAsync.value ?? 'local_offline_user';

    _syncFromRepository();

    return TransactionState(
      transactions: [
        TransactionModel(
          id: 'tx_init_1',
          title: 'Makan Siang Kopi & Salad',
          amount: 65000,
          type: TransactionType.expense,
          category: 'Makanan & Minuman',
          paymentMethod: 'BCA QRIS',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          source: TransactionSource.text,
        ),
        TransactionModel(
          id: 'tx_init_2',
          title: 'Bensin Pertamax',
          amount: 100000,
          type: TransactionType.expense,
          category: 'Transportasi',
          paymentMethod: 'Kartu Debit',
          date: DateTime.now().subtract(const Duration(days: 1)),
          source: TransactionSource.voice,
        ),
        TransactionModel(
          id: 'tx_init_3',
          title: 'Gaji Bulanan Masuk',
          amount: 15000000,
          type: TransactionType.income,
          category: 'Pendapatan',
          paymentMethod: 'Transfer Bank',
          date: DateTime.now().subtract(const Duration(days: 4)),
          source: TransactionSource.text,
        ),
      ],
    );
  }

  void _syncFromRepository() {
    final repo = _repository;
    final uid = _userId;
    if (repo == null || uid == null) return;

    repo.watchTransactions(uid).listen((cloudTransactions) {
      if (cloudTransactions.isNotEmpty) {
        state = state.copyWith(transactions: cloudTransactions);
      }
    });

    repo.getMonthlyBudget(uid).then((budget) {
      if (budget > 0) {
        state = state.copyWith(monthlyBudget: budget);
      }
    });
  }

  void addTransaction(TransactionModel transaction) {
    state = state.copyWith(
      transactions: [transaction, ...state.transactions],
    );
    if (_repository != null && _userId != null) {
      _repository!.saveTransaction(_userId!, transaction);
    }
  }

  void deleteTransaction(String id) {
    state = state.copyWith(
      transactions: state.transactions.where((t) => t.id != id).toList(),
    );
    if (_repository != null && _userId != null) {
      _repository!.deleteTransaction(_userId!, id);
    }
  }

  void updateTransaction(TransactionModel updatedTransaction) {
    state = state.copyWith(
      transactions: state.transactions
          .map((t) => t.id == updatedTransaction.id ? updatedTransaction : t)
          .toList(),
    );
    if (_repository != null && _userId != null) {
      _repository!.updateTransaction(_userId!, updatedTransaction);
    }
  }

  void updateBudget(double newBudget) {
    state = state.copyWith(monthlyBudget: newBudget);
    if (_repository != null && _userId != null) {
      _repository!.setMonthlyBudget(_userId!, newBudget);
    }
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
  TransactionNotifier.new,
);
