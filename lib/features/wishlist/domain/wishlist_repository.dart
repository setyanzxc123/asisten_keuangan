import 'package:asisten_keuangan/features/wishlist/domain/wishlist_model.dart';

abstract class WishlistRepository {
  Stream<List<WishlistModel>> watchWishlist(String userId);
  Future<List<WishlistModel>> getWishlist(String userId);
  Future<void> saveWishlistItem(String userId, WishlistModel item);
  Future<void> updateWishlistItem(String userId, WishlistModel item);
  Future<void> deleteWishlistItem(String userId, String itemId);
}
