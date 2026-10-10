import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/presentation/manual_transaction_bottom_sheet.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perekaman selesai. Mengirim rekaman suara...'),
          duration: Duration(seconds: 2),
        ),
      );

      if (recordedPath != null) {
        await storageService.uploadAudioFile(
          userId: userId,
          localPath: recordedPath,
        );
      }

      ref.read(assistantProvider.notifier).sendUserMessage(
            text: 'Tadi beli bensin 50 ribu tunai',
            source: TransactionSource.voice,
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

    if (imagePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengunggah dan menganalisis foto struk...'),
          duration: Duration(seconds: 2),
        ),
      );

      await storageService.uploadReceiptImage(
        userId: userId,
        localPath: imagePath,
      );
    }

    ref.read(assistantProvider.notifier).sendUserMessage(
          text: 'Struk Belanja Supermarket 275.000 QRIS',
          source: TransactionSource.receipt,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppTheme.primaryNavy,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Asisten',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Manual Input Button
                IconButton(
                  onPressed: () => ManualTransactionBottomSheet.show(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppTheme.primaryNavy,
                  tooltip: 'Catat Manual',
                ),
                const SizedBox(width: 4),

                // Text Input Bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitText(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ketik santai, misal: "Kopi 35rb qris"',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Receipt Camera Button
                IconButton(
                  onPressed: _handleReceiptCapture,
                  icon: const Icon(Icons.receipt_long_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: 'Scan Struk',
                ),

                // Mic Voice Memo Button
                GestureDetector(
                  onTap: _handleVoiceInput,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isVoiceRecording
                          ? AppTheme.accentRose
                          : AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVoiceRecording ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 20,
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
