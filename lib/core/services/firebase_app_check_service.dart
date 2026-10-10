import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAppCheckService {
  final FirebaseAppCheck? _appCheck;

  FirebaseAppCheckService({FirebaseAppCheck? appCheck})
      : _appCheck = appCheck ?? _resolveAppCheckInstance();

  static FirebaseAppCheck? _resolveAppCheckInstance() {
    try {
      return FirebaseAppCheck.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> activate() async {
    final appCheck = _appCheck;
    if (appCheck == null) return false;

    try {
      await appCheck.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
        providerApple: const AppleAppAttestProvider(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final appCheckServiceProvider = Provider<FirebaseAppCheckService>((ref) {
  return FirebaseAppCheckService();
});
