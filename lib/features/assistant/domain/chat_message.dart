import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

enum MessageSender { user, banker }

enum MessageStatus {
  normal,
  pendingClarification,
  committed,
  processing,
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final TransactionModel? extractedTransaction;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.normal,
    this.extractedTransaction,
  });

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    TransactionModel? extractedTransaction,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      extractedTransaction: extractedTransaction ?? this.extractedTransaction,
    );
  }
}
