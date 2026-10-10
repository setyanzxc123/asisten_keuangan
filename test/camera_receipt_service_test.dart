import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/camera_receipt_service.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/assistant/presentation/widgets/quick_assistant_bar.dart';

class FakeCameraReceiptService extends CameraReceiptService {
  bool cameraTriggered = false;

  @override
  Future<String?> captureReceiptFromCamera({
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    cameraTriggered = true;
    return '/tmp/mock_receipt.jpg';
  }

  @override
  Future<String?> pickReceiptFromGallery({
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    return '/tmp/mock_gallery_receipt.jpg';
  }
}

void main() {
  group('CameraReceiptService Tests', () {
    test('handles uninitialized picker gracefully', () async {
      final service = CameraReceiptService();
      final camPath = await service.captureReceiptFromCamera();
      expect(camPath, isNull);

      final galPath = await service.pickReceiptFromGallery();
      expect(galPath, isNull);
    });

    test('FakeCameraReceiptService returns mock photo paths', () async {
      final fake = FakeCameraReceiptService();
      final path = await fake.captureReceiptFromCamera();
      expect(path, equals('/tmp/mock_receipt.jpg'));
      expect(fake.cameraTriggered, isTrue);

      final galleryPath = await fake.pickReceiptFromGallery();
      expect(galleryPath, equals('/tmp/mock_gallery_receipt.jpg'));
    });
  });

  group('QuickAssistantBar Receipt Scan Widget Tests', () {
    testWidgets('triggers receipt capture and updates assistant state', (tester) async {
      final fakeCamera = FakeCameraReceiptService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraReceiptServiceProvider.overrideWithValue(fakeCamera),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: QuickAssistantBar(onExpandChat: () {}),
            ),
          ),
        ),
      );

      final receiptButton = find.byIcon(Icons.receipt_long_rounded);
      expect(receiptButton, findsOneWidget);

      await tester.tap(receiptButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(fakeCamera.cameraTriggered, isTrue);

      final element = tester.element(find.byType(QuickAssistantBar));
      final container = ProviderScope.containerOf(element);
      final messages = container.read(assistantProvider).messages;

      expect(
        messages.any((m) => m.sender == MessageSender.user && m.content.contains('Struk Belanja')),
        isTrue,
      );
    });
  });
}
