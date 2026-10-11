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
                    color: AppTheme.isDark(context)
                        ? AppTheme.accentEmerald
                        : AppTheme.accentEmeraldText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // Quick prompt chips
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickChip('Kopi 35rb QRIS'),
                    _buildQuickChip('Bensin 100rb debit'),
                    _buildQuickChip('Belanja bulanan 650rb'),
                    _buildQuickChip('Gaji freelance 3.5jt'),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.borderOf(context)),

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
                decoration: BoxDecoration(
                  color: AppTheme.cardOf(context),
                  border: Border(
                    top: BorderSide(color: AppTheme.borderOf(context)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.fillOf(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.borderOf(context)),
                          ),
                          child: TextField(
                            controller: _textController,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Belanja apa hari ini?',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _sendMessage(),
                        tooltip: 'Kirim pesan',
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimaryOf(context),
                          foregroundColor: AppTheme.onAccentPrimaryOf(context),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        backgroundColor: AppTheme.cardOf(context),
        side: BorderSide(color: AppTheme.borderOf(context)),
        onPressed: () => _sendMessage(customText: text),
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
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryNavy,
                  child: Icon(
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
                    color: isUser
                        ? AppTheme.primaryNavy
                        : AppTheme.cardOf(context),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight:
                          isUser ? const Radius.circular(0) : const Radius.circular(16),
                      bottomLeft:
                          !isUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.borderOf(context)),
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
                      if (!isUser && msg.viaLocalFallback) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'MODE LOKAL - AI TIDAK TERSEDIA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isUser
                              ? Colors.white
                              : AppTheme.textPrimaryOf(context),
                        ),
                      ),
                      if (msg.extractedTransaction != null) ...[
                        const SizedBox(height: 10),
                        _buildTransactionVoucher(msg),
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

  Widget _buildTransactionVoucher(ChatMessage msg) {
    final tx = msg.extractedTransaction!;
    final isCommitted = msg.status == MessageStatus.committed;
    final isPending = msg.status == MessageStatus.pendingClarification;

    final badgeLabel = isCommitted
        ? 'TERCATAT'
        : (isPending ? 'MENUNGGU KONFIRMASI' : 'DIURUNGKAN');
    final badgeColor = isCommitted
        ? AppTheme.accentEmeraldText
        : (isPending ? const Color(0xFFB45309) : AppTheme.textSecondary);
    final badgeBackground = isCommitted
        ? AppTheme.accentEmerald.withValues(alpha: 0.15)
        : (isPending
            ? AppTheme.accentGold.withValues(alpha: 0.15)
            : AppTheme.neutralSurfaceAlt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.fillOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondaryOf(context),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(tx.amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          Text(
            '${tx.title} • ${tx.paymentMethod}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          if (isCommitted &&
              tx.type == TransactionType.expense &&
              tx.paymentMethod == 'Belum Ditentukan') ...[
            const SizedBox(height: 6),
            const Text(
              'Metode pembayaran belum ditentukan. Urungkan lalu sebutkan metodenya agar laporan akurat.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ],
          if (isCommitted) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref
                    .read(assistantProvider.notifier)
                    .undoCommittedTransaction(msg.id),
                icon: const Icon(Icons.undo_rounded, size: 14),
                label: const Text(
                  'Urungkan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(44, 36),
                ),
              ),
            ),
          ],
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
              color: AppTheme.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderOf(context)),
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
                    color: AppTheme.textSecondaryOf(context),
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
