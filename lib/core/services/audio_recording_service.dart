import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecorder? _recorder;
  String? _currentRecordingPath;

  AudioRecordingService({AudioRecorder? recorder}) {
    if (recorder != null) {
      _recorder = recorder;
    }
  }

  AudioRecorder? _resolveRecorder() {
    if (_recorder != null) return _recorder;
    try {
      _recorder = AudioRecorder();
      return _recorder;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasPermission() async {
    final rec = _resolveRecorder();
    if (rec == null) return false;
    try {
      return await rec.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<String?> startRecording({String? targetPath}) async {
    final rec = _resolveRecorder();
    if (rec == null) return null;
    try {
      final permitted = await hasPermission();
      if (!permitted) return null;

      final path = targetPath ??
          '${Directory.systemTemp.path}/financial_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _currentRecordingPath = path;
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> stopRecording() async {
    final rec = _resolveRecorder();
    if (rec == null) return _currentRecordingPath;
    try {
      final path = await rec.stop();
      final finalPath = path ?? _currentRecordingPath;
      _currentRecordingPath = null;
      return finalPath;
    } catch (_) {
      return _currentRecordingPath;
    }
  }

  Future<void> cancelRecording() async {
    final rec = _resolveRecorder();
    if (rec != null) {
      try {
        await rec.cancel();
      } catch (_) {}
    }
    _currentRecordingPath = null;
  }

  Future<bool> isRecording() async {
    final rec = _resolveRecorder();
    if (rec == null) return false;
    try {
      return await rec.isRecording();
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    final rec = _recorder;
    if (rec != null) {
      try {
        await rec.dispose();
      } catch (_) {}
    }
  }
}

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
