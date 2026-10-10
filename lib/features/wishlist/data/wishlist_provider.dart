import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:asisten_keuangan/core/services/firebase_auth_service.dart';
import 'package:asisten_keuangan/features/wishlist/domain/wishlist_model.dart';
import 'package:asisten_keuangan/features/wishlist/data/firestore_wishlist_repository.dart';

class WishlistState {
  final List<WishlistModel> items;
  final bool isLoading;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
  });

  WishlistState copyWith({
    List<WishlistModel>? items,
    bool? isLoading,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get totalTargetAmount =>
      items.fold(0.0, (acc, item) => acc + item.targetAmount);

  double get totalSavedAmount =>
      items.fold(0.0, (acc, item) => acc + item.savedAmount);

  double get overallProgressPercentage {
    if (totalTargetAmount <= 0) return 0.0;
    return (totalSavedAmount / totalTargetAmount).clamp(0.0, 1.0) * 100;
  }
}

class WishlistNotifier extends Notifier<WishlistState> {
  final _uuid = const Uuid();
  StreamSubscription<List<WishlistModel>>? _subscription;

  @override
  WishlistState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _initRepositorySync();

    if (stateOrNull != null) {
      return stateOrNull!;
    }

    return _buildInitialState();
  }

  WishlistState _buildInitialState() {
    final now = DateTime.now();
    return WishlistState(
      items: [
        WishlistModel(
          id: 'default-wishlist-1',
          title: 'Dana Darurat 3 Bulan',
          targetAmount: 15000000,
          savedAmount: 9000000,
          targetDate: now.add(const Duration(days: 90)),
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        WishlistModel(
          id: 'default-wishlist-2',
          title: 'Upgrade Laptop Kerja',
          targetAmount: 20000000,
          savedAmount: 5000000,
          targetDate: now.add(const Duration(days: 180)),
          createdAt: now.subtract(const Duration(days: 15)),
        ),
      ],
    );
  }

  void _initRepositorySync() {
    final repo = ref.read(wishlistRepositoryProvider);
    final userAsync = ref.watch(currentUserIdProvider);
    final userId = userAsync.value ?? 'local_user';

    _subscription?.cancel();
    _subscription = repo.watchWishlist(userId).listen((cloudItems) {
      if (cloudItems.isNotEmpty) {
        state = state.copyWith(items: cloudItems, isLoading: false);
      }
    });
  }

  Future<void> addWishlistItem({
    required String title,
    required double targetAmount,
    double savedAmount = 0.0,
    DateTime? targetDate,
  }) async {
    final newItem = WishlistModel(
      id: _uuid.v4(),
      title: title.trim(),
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );

    final updated = [newItem, ...state.items];
    state = state.copyWith(items: updated);

    final repo = ref.read(wishlistRepositoryProvider);
    final userId = ref.read(currentUserIdProvider).value ?? 'local_user';
    await repo.saveWishlistItem(userId, newItem);
  }

  Future<void> allocateSavings({
    required String itemId,
    required double additionalAmount,
  }) async {
    final updated = state.items.map((item) {
      if (item.id == itemId) {
        final newSaved = (item.savedAmount + additionalAmount)
            .clamp(0.0, item.targetAmount);
        final isAchieved = newSaved >= item.targetAmount;
        final updatedItem = item.copyWith(
          savedAmount: newSaved,
          isAchieved: isAchieved,
        );

        final repo = ref.read(wishlistRepositoryProvider);
        final userId = ref.read(currentUserIdProvider).value ?? 'local_user';
        repo.updateWishlistItem(userId, updatedItem);

        return updatedItem;
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  Future<void> toggleAchieved(String itemId) async {
    final updated = state.items.map((item) {
      if (item.id == itemId) {
        final updatedItem = item.copyWith(isAchieved: !item.isAchieved);

        final repo = ref.read(wishlistRepositoryProvider);
        final userId = ref.read(currentUserIdProvider).value ?? 'local_user';
        repo.updateWishlistItem(userId, updatedItem);

        return updatedItem;
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  Future<void> deleteWishlistItem(String itemId) async {
    final updated = state.items.where((i) => i.id != itemId).toList();
    state = state.copyWith(items: updated);

    final repo = ref.read(wishlistRepositoryProvider);
    final userId = ref.read(currentUserIdProvider).value ?? 'local_user';
    await repo.deleteWishlistItem(userId, itemId);
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);
