import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/firestore_transaction_repository.dart';
import 'package:asisten_keuangan/core/services/firebase_auth_service.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double monthlyBudget;
  final bool isLoading;

  const TransactionState({
    required this.transactions,
    this.monthlyBudget = 5000000,
    this.isLoading = true,
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
    bool? isLoading,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isLoading: isLoading ?? this.isLoading,
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
    final userId = userAsync.value ?? 'local_offline_user';

    final previous = stateOrNull;
    final sameUser = previous != null && _userId == userId;
    _userId = userId;

    if (sameUser) {
      // Rebuild from a watched dependency change (e.g. repository swap);
      // keep accumulated data and re-subscribe with the same identity.
      _syncFromRepository();
      return previous;
    }

    _syncFromRepository();

    return const TransactionState(transactions: []);
  }

  void _syncFromRepository() {
    final repo = _repository;
    final uid = _userId;
    if (repo == null || uid == null) return;

    final sub = repo.watchTransactions(uid).listen(
      (cloudTransactions) {
        if (!ref.mounted) return;
        _mergeCloudTransactions(cloudTransactions);
      },
      onError: (_) {
        if (ref.mounted) state = state.copyWith(isLoading: false);
      },
      onDone: () {
        // Backend without an active stream (uninitialized Firestore) emits
        // nothing; resolve the loading state instead of waiting forever.
        if (ref.mounted) state = state.copyWith(isLoading: false);
      },
    );

    ref.onDispose(() {
      sub.cancel();
    });

    repo.getMonthlyBudget(uid).then((budget) {
      if (ref.mounted && budget > 0) {
        state = state.copyWith(monthlyBudget: budget);
      }
    });
  }

  void _mergeCloudTransactions(List<TransactionModel> cloudTransactions) {
    final cloudIds = cloudTransactions.map((t) => t.id).toSet();
    final localOnly = state.transactions
        .where((t) => !cloudIds.contains(t.id))
        .toList();
    state = state.copyWith(
      transactions: [...cloudTransactions, ...localOnly],
      isLoading: false,
    );
  }

  void addTransaction(TransactionModel transaction) {
    state = state.copyWith(
      transactions: [transaction, ...state.transactions],
      isLoading: false,
    );
    if (_repository != null && _userId != null) {
      _repository!.saveTransaction(_userId!, transaction);
    }
  }

  void loadSampleData() {
    if (state.transactions.any((t) => t.id == 'sample-tx-1')) return;
    final now = DateTime.now();
    final samples = [
      TransactionModel(
        id: 'sample-tx-1',
        title: 'Makan Siang Kopi & Salad',
        amount: 65000,
        type: TransactionType.expense,
        category: 'Makanan & Minuman',
        paymentMethod: 'BCA QRIS',
        date: now.subtract(const Duration(hours: 3)),
        source: TransactionSource.text,
      ),
      TransactionModel(
        id: 'sample-tx-2',
        title: 'Bensin Pertamax',
        amount: 100000,
        type: TransactionType.expense,
        category: 'Transportasi',
        paymentMethod: 'Kartu Debit',
        date: now.subtract(const Duration(days: 1)),
        source: TransactionSource.voice,
      ),
      TransactionModel(
        id: 'sample-tx-3',
        title: 'Gaji Bulanan Masuk',
        amount: 15000000,
        type: TransactionType.income,
        category: 'Pendapatan',
        paymentMethod: 'Transfer Bank',
        date: now.subtract(const Duration(days: 4)),
        source: TransactionSource.text,
      ),
    ];
    for (final tx in samples) {
      addTransaction(tx);
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
