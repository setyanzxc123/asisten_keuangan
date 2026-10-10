import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore? _firestore;

  FirestoreTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? _resolveFirestoreInstance() {
    _configurePersistence();
  }

  static FirebaseFirestore? _resolveFirestoreInstance() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  void _configurePersistence() {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>>? _userTransactionsRef(String userId) {
    return _firestore?.collection('users').doc(userId).collection('transactions');
  }

  DocumentReference<Map<String, dynamic>>? _userBudgetDoc(String userId) {
    return _firestore
        ?.collection('users')
        .doc(userId)
        .collection('settings')
        .doc('budget');
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return const Stream.empty();

    try {
      return ref
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return TransactionModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      developer.log('Firestore watchTransactions warning: $e');
      return const Stream.empty();
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return [];

    try {
      final snapshot = await ref.orderBy('date', descending: true).get();
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      developer.log('Firestore getTransactions warning: $e');
      return [];
    }
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(transaction.id).set(transaction.toMap());
    } catch (e) {
      developer.log('Firestore saveTransaction warning: $e');
    }
  }

  @override
  Future<void> updateTransaction(String userId, TransactionModel transaction) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(transaction.id).set(
            transaction.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Firestore updateTransaction warning: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    final ref = _userTransactionsRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(transactionId).delete();
    } catch (e) {
      developer.log('Firestore deleteTransaction warning: $e');
    }
  }

  @override
  Future<double> getMonthlyBudget(String userId) async {
    final docRef = _userBudgetDoc(userId);
    if (docRef == null) return 5000000.0;

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final amount = doc.data()!['monthlyBudget'];
        if (amount is num) return amount.toDouble();
      }
    } catch (e) {
      developer.log('Firestore getMonthlyBudget warning: $e');
    }
    return 5000000.0;
  }

  @override
  Future<void> setMonthlyBudget(String userId, double budget) async {
    final docRef = _userBudgetDoc(userId);
    if (docRef == null) return;

    try {
      await docRef.set(
        {'monthlyBudget': budget},
        SetOptions(merge: true),
      );
    } catch (e) {
      developer.log('Firestore setMonthlyBudget warning: $e');
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirestoreTransactionRepository();
});
