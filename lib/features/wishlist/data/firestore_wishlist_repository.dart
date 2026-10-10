import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/features/wishlist/domain/wishlist_model.dart';
import 'package:asisten_keuangan/features/wishlist/domain/wishlist_repository.dart';

class FirestoreWishlistRepository implements WishlistRepository {
  final FirebaseFirestore? _firestore;

  FirestoreWishlistRepository({FirebaseFirestore? firestore})
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

  CollectionReference<Map<String, dynamic>>? _userWishlistRef(String userId) {
    return _firestore?.collection('users').doc(userId).collection('wishlist');
  }

  @override
  Stream<List<WishlistModel>> watchWishlist(String userId) {
    final ref = _userWishlistRef(userId);
    if (ref == null) return const Stream.empty();

    try {
      return ref
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return WishlistModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<List<WishlistModel>> getWishlist(String userId) async {
    final ref = _userWishlistRef(userId);
    if (ref == null) return const [];

    try {
      final snapshot = await ref.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        return WishlistModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveWishlistItem(String userId, WishlistModel item) async {
    final ref = _userWishlistRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(item.id).set(item.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> updateWishlistItem(String userId, WishlistModel item) async {
    final ref = _userWishlistRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(item.id).update(item.toMap());
    } catch (_) {}
  }

  @override
  Future<void> deleteWishlistItem(String userId, String itemId) async {
    final ref = _userWishlistRef(userId);
    if (ref == null) return;

    try {
      await ref.doc(itemId).delete();
    } catch (_) {}
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return FirestoreWishlistRepository();
});
