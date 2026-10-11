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
  String? _userId;

  @override
  WishlistState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    final userAsync = ref.watch(currentUserIdProvider);
    final userId = userAsync.value ?? 'local_offline_user';

    final previous = stateOrNull;
    final sameUser = previous != null && _userId == userId;
    _userId = userId;

    if (sameUser) {
      _initRepositorySync();
      return previous;
    }

    _initRepositorySync();

    return const WishlistState(items: [], isLoading: true);
  }

  void _initRepositorySync() {
    final repo = ref.read(wishlistRepositoryProvider);
    final userAsync = ref.watch(currentUserIdProvider);
    final userId = userAsync.value ?? 'local_offline_user';

    _subscription?.cancel();
    _subscription = repo.watchWishlist(userId).listen(
      (cloudItems) {
        if (!ref.mounted) return;
        _mergeCloudItems(cloudItems);
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
  }

  void _mergeCloudItems(List<WishlistModel> cloudItems) {
    final cloudIds = cloudItems.map((i) => i.id).toSet();
    final localOnly = state.items
        .where((i) => !cloudIds.contains(i.id))
        .toList();
    state = state.copyWith(
      items: [...cloudItems, ...localOnly],
      isLoading: false,
    );
  }

  void loadSampleData() {
    final now = DateTime.now();
    final samples = [
      WishlistModel(
        id: 'sample-wishlist-1',
        title: 'Dana Darurat 3 Bulan',
        targetAmount: 15000000,
        savedAmount: 9000000,
        targetDate: now.add(const Duration(days: 90)),
        createdAt: now,
      ),
      WishlistModel(
        id: 'sample-wishlist-2',
        title: 'Upgrade Laptop Kerja',
        targetAmount: 20000000,
        savedAmount: 5000000,
        targetDate: now.add(const Duration(days: 180)),
        createdAt: now,
      ),
    ];

    final existingIds = state.items.map((i) => i.id).toSet();
    final newSamples = samples
        .where((s) => !existingIds.contains(s.id))
        .toList();
    if (newSamples.isEmpty) return;

    state = state.copyWith(
      items: [...newSamples, ...state.items],
      isLoading: false,
    );

    final repo = ref.read(wishlistRepositoryProvider);
    final userId = ref.read(currentUserIdProvider).value ?? 'local_offline_user';
    for (final item in newSamples) {
      repo.saveWishlistItem(userId, item);
    }
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
    state = state.copyWith(items: updated, isLoading: false);

    final repo = ref.read(wishlistRepositoryProvider);
    final userId = ref.read(currentUserIdProvider).value ?? 'local_offline_user';
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
        final userId = ref.read(currentUserIdProvider).value ?? 'local_offline_user';
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
        final userId = ref.read(currentUserIdProvider).value ?? 'local_offline_user';
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
    final userId = ref.read(currentUserIdProvider).value ?? 'local_offline_user';
    await repo.deleteWishlistItem(userId, itemId);
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, WishlistState>(WishlistNotifier.new);
