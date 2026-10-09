import 'dart:developer' as developer;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (e) {
      developer.log('Biometric availability check failed: $e');
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Konfirmasi identitas Anda untuk mengakses data keuangan',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } catch (e) {
      developer.log('Biometric authentication failed: $e');
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
