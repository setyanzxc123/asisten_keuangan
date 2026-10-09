import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage({String? customText}) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(assistantProvider.notifier).sendUserMessage(
          text: text,
          source: TransactionSource.text,
        );
    if (customText == null) _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(assistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private Banker AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Penasihat Keuangan Pribadi • Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick prompt chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickChip('☕ Kopi 35rb QRIS'),
                _buildQuickChip('⛽ Bensin 100rb debit'),
                _buildQuickChip('🛒 Belanja bulanan 650rb'),
                _buildQuickChip('💼 Gaji freelance 3.5jt'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: assistantState.messages.length +
                  (assistantState.isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == assistantState.messages.length &&
                    assistantState.isThinking) {
                  return _buildThinkingIndicator();
                }

                final msg = assistantState.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Bottom Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Diktekan transaksi atau tanyakan saran...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        onPressed: () {
          // Remove emoji from front
          final clean = text.substring(2).trim();
          _sendMessage(customText: clean);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryNavy,
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryNavy : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isUser ? const Radius.circular(0) : const Radius.circular(16),
                      bottomLeft:
                          !isUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (msg.extractedTransaction != null) ...[
                        const SizedBox(height: 10),
                        _buildTransactionVoucher(msg.extractedTransaction!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Clarification Quick Action Buttons (Multi-Turn Helper)
          if (msg.status == MessageStatus.pendingClarification) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.credit_card_rounded, size: 16),
                    label: const Text('Debit Rekening'),
                    onPressed: () => _sendMessage(customText: 'Pakai Debit Rekening'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Tunai'),
                    onPressed: () => _sendMessage(customText: 'Bayar Tunai'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.credit_score_rounded, size: 16),
                    label: const Text('Kartu Kredit'),
                    onPressed: () => _sendMessage(customText: 'Kartu Kredit'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionVoucher(TransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TERCATAT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(tx.amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          Text(
            '${tx.title} • ${tx.paymentMethod}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 40),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Private Banker menganalisis...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
