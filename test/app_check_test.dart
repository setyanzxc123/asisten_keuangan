import 'package:flutter_test/flutter_test.dart';
import 'package:asisten_keuangan/core/services/firebase_app_check_service.dart';

class FakeAppCheckService extends FirebaseAppCheckService {
  bool isActivated = false;

  @override
  Future<bool> activate() async {
    isActivated = true;
    return true;
  }
}

void main() {
  group('FirebaseAppCheckService Tests', () {
    test('handles uninitialized app check gracefully', () async {
      final service = FirebaseAppCheckService();
      final result = await service.activate();
      expect(result, isFalse);
    });

    test('FakeAppCheckService simulates successful activation', () async {
      final fake = FakeAppCheckService();
      final result = await fake.activate();
      expect(result, isTrue);
      expect(fake.isActivated, isTrue);
    });
  });
}
