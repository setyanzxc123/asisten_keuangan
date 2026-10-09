import 'package:flutter_test/flutter_test.dart';
import 'package:asisten_keuangan/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions Tests', () {
    test('provides configured options for android', () {
      final options = DefaultFirebaseOptions.android;
      expect(options.projectId, equals('asisten-keuangan-dev'));
      expect(options.apiKey.isNotEmpty, isTrue);
    });

    test('provides configured options for web', () {
      final options = DefaultFirebaseOptions.web;
      expect(options.projectId, equals('asisten-keuangan-dev'));
      expect(options.authDomain, isNotNull);
    });

    test('provides configured options for ios', () {
      final options = DefaultFirebaseOptions.ios;
      expect(options.projectId, equals('asisten-keuangan-dev'));
      expect(options.iosBundleId, equals('com.novantho.asistenKeuangan'));
    });
  });
}
