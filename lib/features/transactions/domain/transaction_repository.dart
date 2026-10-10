import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

abstract class TransactionRepository {
  Stream<List<TransactionModel>> watchTransactions(String userId);
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<void> saveTransaction(String userId, TransactionModel transaction);
  Future<void> updateTransaction(String userId, TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
  Future<double> getMonthlyBudget(String userId);
  Future<void> setMonthlyBudget(String userId, double budget);
}
