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

  Future<FinancialIntentResult?> processFinancialIntent(String text) async {
    final functions = _functions ?? _resolveFunctionsInstance();
    if (functions == null) {
      return null;
    }

    try {
      final callable = functions.httpsCallable('processFinancialIntent');
      final response = await callable.call<Map<String, dynamic>>({
        'text': text,
      });

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
