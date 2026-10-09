import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';

class AssistantState {
  final List<ChatMessage> messages;
  final bool isThinking;
  final TransactionModel? pendingTransaction;

  const AssistantState({
    required this.messages,
    this.isThinking = false,
    this.pendingTransaction,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
    TransactionModel? pendingTransaction,
    bool clearPendingTransaction = false,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      pendingTransaction: clearPendingTransaction
          ? null
          : (pendingTransaction ?? this.pendingTransaction),
    );
  }
}

class AssistantNotifier extends Notifier<AssistantState> {
  final _uuid = const Uuid();

  @override
  AssistantState build() {
    return AssistantState(
      messages: [
        ChatMessage(
          id: 'init_banker_welcome',
          sender: MessageSender.banker,
          content:
              'Selamat datang. Saya asisten penasihat keuangan pribadi Anda. Anda dapat mendiktekan catatan transaksi, mengirimkan foto struk, atau memasukkan teks langsung. Saya akan mengelola pencatatan dan memantau rasio likuiditas Anda.',
          timestamp: DateTime.now(),
          status: MessageStatus.normal,
        ),
      ],
    );
  }

  Future<void> sendUserMessage({
    required String text,
    TransactionSource source = TransactionSource.text,
  }) async {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    // Simulasi jeda pemrosesan analitis cerdas (AI thinking latency)
    await Future.delayed(const Duration(milliseconds: 900));

    // Handle ongoing multi-turn clarification if pending
    if (state.pendingTransaction != null) {
      _resolvePendingClarification(text);
      return;
    }

    _processNewTransactionInput(text, source);
  }

  void _resolvePendingClarification(String userResponse) {
    final pending = state.pendingTransaction!;
    final lower = userResponse.toLowerCase();

    String paymentMethod = 'Debit / Tabungan';
    if (lower.contains('kredit') || lower.contains('cc')) {
      paymentMethod = 'Kartu Kredit';
    } else if (lower.contains('qris')) {
      paymentMethod = 'QRIS';
    } else if (lower.contains('tunai') || lower.contains('cash')) {
      paymentMethod = 'Tunai';
    }

    final finalTx = pending.copyWith(paymentMethod: paymentMethod);

    // Commit to transaction repository
    ref.read(transactionProvider.notifier).addTransaction(finalTx);

    final txState = ref.read(transactionProvider);
    final bankerReply = ChatMessage(
      id: _uuid.v4(),
      sender: MessageSender.banker,
      content:
          'Konfirmasi diterima. Pengeluaran "${finalTx.title}" senilai ${CurrencyFormatter.format(finalTx.amount)} telah dialokasikan ke metode $paymentMethod.\n\nSisa pagu anggaran bulan ini: ${CurrencyFormatter.format(txState.remainingBudget)} (${(txState.budgetUsedPercentage * 100).toStringAsFixed(1)}% terpakai).',
      timestamp: DateTime.now(),
      status: MessageStatus.committed,
      extractedTransaction: finalTx,
    );

    state = state.copyWith(
      messages: [...state.messages, bankerReply],
      isThinking: false,
      clearPendingTransaction: true,
    );
  }

  void _processNewTransactionInput(String input, TransactionSource source) {
    final lower = input.toLowerCase();

    final amount = _extractAmount(lower);
    final isIncome = lower.contains('gaji') ||
        lower.contains('transfer masuk') ||
        lower.contains('pendapatan') ||
        lower.contains('dapat uang') ||
        lower.contains('freelance');

    if (amount == null) {
      final bankerResponse = ChatMessage(
        id: _uuid.v4(),
        sender: MessageSender.banker,
        content:
            'Data nominal belum terdeteksi secara presisi. Mohon sebutkan nominal pengeluaran atau pemasukan Anda (misal: "Beli kopi 35rb" atau "Isi bensin 100 ribu").',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, bankerResponse],
        isThinking: false,
      );
      return;
    }

    final hasPaymentMethod = lower.contains('qris') ||
        lower.contains('bca') ||
        lower.contains('mandiri') ||
        lower.contains('tunai') ||
        lower.contains('cash') ||
        lower.contains('kredit');

    final category = _categorize(lower, isIncome);
    final title = _generateTitle(input, category);

    final candidateTx = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      category: category,
      paymentMethod: hasPaymentMethod ? _extractMethod(lower) : 'Belum Ditentukan',
      date: DateTime.now(),
      source: source,
    );

    if (!isIncome && amount >= 500000 && !hasPaymentMethod) {
      final clarificationMsg = ChatMessage(
        id: _uuid.v4(),
        sender: MessageSender.banker,
        content:
            'Tercatat pengeluaran signifikan: "${candidateTx.title}" senilai ${CurrencyFormatter.format(amount)}.\n\nUntuk menjaga akurasi laporan likuiditas, mohon konfirmasi metode pembayaran yang digunakan: apakah melalui Debit Rekening Utama, Tunai, atau Fasilitas Kartu Kredit?',
        timestamp: DateTime.now(),
        status: MessageStatus.pendingClarification,
        extractedTransaction: candidateTx,
      );

      state = state.copyWith(
        messages: [...state.messages, clarificationMsg],
        isThinking: false,
        pendingTransaction: candidateTx,
      );
      return;
    }

    ref.read(transactionProvider.notifier).addTransaction(candidateTx);
    final txState = ref.read(transactionProvider);

    final responseContent = isIncome
        ? 'Penerimaan dana "${candidateTx.title}" senilai ${CurrencyFormatter.format(amount)} telah dibukukan. Posisi likuiditas kas bertambah positif.'
        : 'Pengeluaran "${candidateTx.title}" senilai ${CurrencyFormatter.format(amount)} (${candidateTx.category}) telah tercatat.\n\nSisa anggaran bulan ini: ${CurrencyFormatter.format(txState.remainingBudget)} (${(txState.budgetUsedPercentage * 100).toStringAsFixed(1)}% terpakai). Arus kas tetap terkendali.';

    final committedMsg = ChatMessage(
      id: _uuid.v4(),
      sender: MessageSender.banker,
      content: responseContent,
      timestamp: DateTime.now(),
      status: MessageStatus.committed,
      extractedTransaction: candidateTx,
    );

    state = state.copyWith(
      messages: [...state.messages, committedMsg],
      isThinking: false,
    );
  }

  double? _extractAmount(String text) {
    final jtMatch = RegExp(r'(\d+([.,]\d+)?)\s*(juta|jt)').firstMatch(text);
    if (jtMatch != null) {
      final numStr = jtMatch.group(1)!.replaceAll(',', '.');
      return (double.tryParse(numStr) ?? 0) * 1000000;
    }

    final rbMatch = RegExp(r'(\d+([.,]\d+)?)\s*(ribu|rb|k)').firstMatch(text);
    if (rbMatch != null) {
      final numStr = rbMatch.group(1)!.replaceAll(',', '.');
      return (double.tryParse(numStr) ?? 0) * 1000;
    }

    final plainNumber = RegExp(r'(\d[\d.,]*)').firstMatch(text);
    if (plainNumber != null) {
      final clean = plainNumber.group(1)!.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(clean);
      if (val != null && val >= 1000) return val;
    }

    return null;
  }

  String _categorize(String text, bool isIncome) {
    if (isIncome) return 'Pendapatan';
    if (text.contains('kopi') ||
        text.contains('makan') ||
        text.contains('resto') ||
        text.contains('soto') ||
        text.contains('nasi')) {
      return 'Makanan & Minuman';
    }
    if (text.contains('bensin') ||
        text.contains('gojek') ||
        text.contains('grab') ||
        text.contains('tol') ||
        text.contains('parkir')) {
      return 'Transportasi';
    }
    if (text.contains('listrik') ||
        text.contains('wifi') ||
        text.contains('air') ||
        text.contains('pulsa') ||
        text.contains('paket')) {
      return 'Tagihan & Utilitas';
    }
    if (text.contains('sepatu') ||
        text.contains('baju') ||
        text.contains('belanja') ||
        text.contains('shopee')) {
      return 'Belanja Pribadi';
    }
    return 'Lainnya';
  }

  String _generateTitle(String text, String category) {
    if (text.length <= 35) {
      return text[0].toUpperCase() + text.substring(1);
    }
    return 'Pengeluaran $category';
  }

  String _extractMethod(String text) {
    if (text.contains('qris')) return 'QRIS';
    if (text.contains('bca')) return 'BCA';
    if (text.contains('mandiri')) return 'Mandiri';
    if (text.contains('tunai') || text.contains('cash')) return 'Tunai';
    if (text.contains('kredit') || text.contains('cc')) return 'Kartu Kredit';
    return 'Debit';
  }
}

final assistantProvider =
    NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);
