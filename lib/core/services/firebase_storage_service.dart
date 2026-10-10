import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseStorageService {
  final FirebaseStorage? _storage;

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? _resolveStorageInstance();

  static FirebaseStorage? _resolveStorageInstance() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadAudioFile({
    required String userId,
    required String localPath,
  }) async {
    final storage = _storage;
    if (storage == null) return null;

    final file = File(localPath);
    if (!file.existsSync()) return null;

    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = storage.ref().child('users/$userId/audio/$fileName');
      final metadata = SettableMetadata(contentType: 'audio/m4a');

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadReceiptImage({
    required String userId,
    required String localPath,
  }) async {
    final storage = _storage;
    if (storage == null) return null;

    final file = File(localPath);
    if (!file.existsSync()) return null;

    try {
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('users/$userId/receipts/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}

final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});
