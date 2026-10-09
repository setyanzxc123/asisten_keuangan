import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/presentation/manual_transaction_bottom_sheet.dart';

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

  void _simulateVoiceInput() async {
    setState(() => _isVoiceRecording = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mendengarkan suara... ("Tadi beli bensin 50 ribu tunai")'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isVoiceRecording = false);

    ref.read(assistantProvider.notifier).sendUserMessage(
          text: 'Tadi beli bensin 50 ribu tunai',
          source: TransactionSource.voice,
        );
    widget.onExpandChat();
  }

  void _simulateReceiptScan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memproses struk belanjaan dari kamera...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppTheme.primaryNavy,
                        ),
                        const SizedBox(width: 6),
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

                // Manual Input Button (Offline Fallback)
                IconButton(
                  onPressed: () => ManualTransactionBottomSheet.show(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppTheme.primaryNavy,
                  tooltip: 'Input Manual (Offline)',
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
                  onPressed: _simulateReceiptScan,
                  icon: const Icon(Icons.receipt_long_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: 'Scan Struk',
                ),

                // Mic Voice Memo Button
                GestureDetector(
                  onTap: _simulateVoiceInput,
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
