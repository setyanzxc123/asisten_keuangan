import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

import 'package:asisten_keuangan/core/services/audio_recording_service.dart';
import 'package:asisten_keuangan/core/services/firebase_storage_service.dart';
import 'package:asisten_keuangan/core/services/firebase_auth_service.dart';
import 'package:asisten_keuangan/core/services/camera_receipt_service.dart';

class QuickAssistantBar extends ConsumerStatefulWidget {
  final VoidCallback onExpandChat;

  const QuickAssistantBar({
    super.key,
    required this.onExpandChat,
  });

  @override
  ConsumerState<QuickAssistantBar> createState() => _QuickAssistantBarState();
}

class _QuickAssistantBarState extends ConsumerState<QuickAssistantBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isVoiceRecording = false;

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(assistantProvider.notifier).sendUserMessage(
          text: text,
          source: TransactionSource.text,
        );
    _controller.clear();
    widget.onExpandChat();
  }

  void _handleVoiceInput() async {
    final audioService = ref.read(audioRecordingServiceProvider);
    final storageService = ref.read(firebaseStorageServiceProvider);
    final userAsync = ref.read(currentUserIdProvider);
    final userId = userAsync.value ?? 'local_offline_user';

    if (_isVoiceRecording) {
      setState(() => _isVoiceRecording = false);
      final recordedPath = await audioService.stopRecording();

      if (!mounted) return;

      if (recordedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perekaman gagal atau tidak tersedia di perangkat ini. Gunakan input teks atau input manual.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perekaman selesai. Mengunggah dan menganalisis rekaman...'),
          duration: Duration(seconds: 2),
        ),
      );

      String? storageUrl;
      try {
        storageUrl = await storageService.uploadAudioFile(
          userId: userId,
          localPath: recordedPath,
        );
      } catch (_) {
        storageUrl = null;
      }

      ref.read(assistantProvider.notifier).sendUserMessage(
            text: '',
            source: TransactionSource.voice,
            storagePath: storageUrl,
            mimeType: 'audio/m4a',
          );
      widget.onExpandChat();
      return;
    }

    final hasPerm = await audioService.hasPermission();
    if (!hasPerm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin mikrofon diperlukan untuk mendikte transaksi.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final startedPath = await audioService.startRecording();
    if (startedPath != null && mounted) {
      setState(() => _isVoiceRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merekam suara... Ketuk ikon mikrofon lagi untuk selesai.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleReceiptCapture() async {
    final cameraService = ref.read(cameraReceiptServiceProvider);
    final storageService = ref.read(firebaseStorageServiceProvider);
    final userAsync = ref.read(currentUserIdProvider);
    final userId = userAsync.value ?? 'local_offline_user';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka kamera struk...'),
        duration: Duration(seconds: 1),
      ),
    );

    final imagePath = await cameraService.captureReceiptFromCamera();
    if (!mounted) return;

    if (imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kamera tidak tersedia atau pengambilan gambar dibatalkan. Tidak ada struk yang dianalisis.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mengunggah dan menganalisis foto struk...'),
        duration: Duration(seconds: 2),
      ),
    );

    String? storageUrl;
    try {
      storageUrl = await storageService.uploadReceiptImage(
        userId: userId,
        localPath: imagePath,
      );
    } catch (_) {
      storageUrl = null;
    }

    ref.read(assistantProvider.notifier).sendUserMessage(
          text: '',
          source: TransactionSource.receipt,
          storagePath: storageUrl,
          mimeType: 'image/jpeg',
        );
    widget.onExpandChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Expand Chat Pill Button
                InkWell(
                  onTap: widget.onExpandChat,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.accentEmerald.withValues(alpha: 0.15)
                          : AppTheme.primaryNavy.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppTheme.accentPrimaryOf(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Asisten',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Distilled Input Capsule with Integrated Suffix Actions
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.fillOf(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitText(),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Belanja apa hari ini?',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryOf(context),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _handleReceiptCapture,
                          icon: const Icon(Icons.receipt_long_rounded, size: 20),
                          color: AppTheme.textSecondaryOf(context),
                          tooltip: 'Scan Struk',
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          padding: const EdgeInsets.all(5),
                        ),
                        GestureDetector(
                          onTap: _handleVoiceInput,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 2),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: _isVoiceRecording
                                  ? AppTheme.accentRose
                                  : AppTheme.accentPrimaryOf(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVoiceRecording ? Icons.mic : Icons.mic_none_rounded,
                              color: AppTheme.onAccentPrimaryOf(context),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
