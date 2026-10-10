import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthService {
  final FirebaseAuth? _auth;

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? _resolveAuthInstance();

  static FirebaseAuth? _resolveAuthInstance() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<String?> getOrCreateUserId() async {
    try {
      final auth = _auth;
      if (auth == null) return 'local_offline_user';

      final current = currentUser;
      if (current != null) {
        return current.uid;
      }
      final credential = await auth.signInAnonymously();
      return credential.user?.uid;
    } catch (e) {
      developer.log('Firebase Auth fallback: $e');
      return 'local_offline_user';
    }
  }
}

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final currentUserIdProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final uid = await authService.getOrCreateUserId();
  return uid ?? 'local_offline_user';
});
