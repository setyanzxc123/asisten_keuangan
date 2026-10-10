import 'package:cloud_functions/cloud_functions.dart';

class FinancialIntentResult {
  final String intent;
  final bool isClarificationNeeded;
  final String? clarificationQuestion;
  final String bankerNarrative;
  final Map<String, dynamic>? transaction;

  const FinancialIntentResult({
    required this.intent,
    required this.isClarificationNeeded,
    this.clarificationQuestion,
    required this.bankerNarrative,
    this.transaction,
  });

  factory FinancialIntentResult.fromMap(Map<String, dynamic> map) {
    return FinancialIntentResult(
      intent: (map['intent'] as String?) ?? 'GENERAL_CHAT',
      isClarificationNeeded: (map['isClarificationNeeded'] as bool?) ?? false,
      clarificationQuestion: map['clarificationQuestion'] as String?,
      bankerNarrative: (map['bankerNarrative'] as String?) ?? '',
      transaction: map['transaction'] != null
          ? Map<String, dynamic>.from(map['transaction'] as Map)
          : null,
    );
  }
}

class FinancialFunctionsService {
  final FirebaseFunctions? _functions;

  FinancialFunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? _resolveFunctionsInstance();

  static FirebaseFunctions? _resolveFunctionsInstance() {
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

  Future<FinancialIntentResult?> processFinancialIntent({
    String? text,
    String? storagePath,
    String? mediaBase64,
    String? mimeType,
  }) async {
    final functions = _functions ?? _resolveFunctionsInstance();
    if (functions == null) {
      return null;
    }

    try {
      final callable = functions.httpsCallable('processFinancialIntent');
      final payload = <String, dynamic>{};
      if (text != null && text.isNotEmpty) payload['text'] = text;
      if (storagePath != null && storagePath.isNotEmpty) payload['storagePath'] = storagePath;
      if (mediaBase64 != null && mediaBase64.isNotEmpty) payload['mediaBase64'] = mediaBase64;
      if (mimeType != null && mimeType.isNotEmpty) payload['mimeType'] = mimeType;

      final response = await callable.call<Map<String, dynamic>>(payload);

      final body = response.data;
      if (body['success'] == true && body['data'] != null) {
        return FinancialIntentResult.fromMap(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
