import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/audio_recording_service.dart';
import 'package:asisten_keuangan/core/services/firebase_storage_service.dart';
import 'package:asisten_keuangan/features/assistant/presentation/widgets/quick_assistant_bar.dart';

class FakeAudioRecordingService extends AudioRecordingService {
  bool recordingActive = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<String?> startRecording({String? targetPath}) async {
    recordingActive = true;
    return targetPath ?? '/tmp/test_voice.m4a';
  }

  @override
  Future<String?> stopRecording() async {
    recordingActive = false;
    return '/tmp/test_voice.m4a';
  }

  @override
  Future<bool> isRecording() async => recordingActive;
}

void main() {
  group('AudioRecordingService Baseline Tests', () {
    test('handles uninitialized recorder platform gracefully', () async {
      final service = AudioRecordingService();
      final hasPerm = await service.hasPermission();
      expect(hasPerm, isFalse);

      final isRec = await service.isRecording();
      expect(isRec, isFalse);

      await service.cancelRecording();
      await service.dispose();
    });

    test('FakeAudioRecordingService tracks lifecycle states', () async {
      final fake = FakeAudioRecordingService();
      expect(await fake.hasPermission(), isTrue);

      final path = await fake.startRecording();
      expect(path, isNotNull);
      expect(await fake.isRecording(), isTrue);

      final stoppedPath = await fake.stopRecording();
      expect(stoppedPath, equals(path));
      expect(await fake.isRecording(), isFalse);
    });
  });

  group('FirebaseStorageService Tests', () {
    test('handles uninitialized storage gracefully without throwing', () async {
      final service = FirebaseStorageService();
      final audioUrl = await service.uploadAudioFile(
        userId: 'test_user',
        localPath: '/tmp/nonexistent.m4a',
      );
      expect(audioUrl, isNull);

      final receiptUrl = await service.uploadReceiptImage(
        userId: 'test_user',
        localPath: '/tmp/nonexistent.jpg',
      );
      expect(receiptUrl, isNull);
    });
  });

  group('QuickAssistantBar Widget Audio Tap Tests', () {
    testWidgets('renders mic button and triggers voice recording flow', (tester) async {
      final fakeAudio = FakeAudioRecordingService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecordingServiceProvider.overrideWithValue(fakeAudio),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: QuickAssistantBar(onExpandChat: () {}),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pump();

      expect(fakeAudio.recordingActive, isTrue);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(fakeAudio.recordingActive, isFalse);
    });
  });
}
