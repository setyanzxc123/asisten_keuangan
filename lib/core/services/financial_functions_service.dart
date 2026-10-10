import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

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

const String bankerSystemInstruction =
    'Anda adalah seorang Penasihat Keuangan Eksekutif (Private Wealth Banker) pribadi yang berdedikasi, cerdas, berwibawa, dan santun.\n'
    'Tugas Anda adalah menganalisis pesan finansial nasabah, mengekstrak mutasi transaksi secara akurat, atau menjawab konsultasi keuangan dalam Bahasa Indonesia yang profesional.\n\n'
    'Aturan Pemrosesan:\n'
    '1. Jika nasabah menyebut pengeluaran atau pemasukan dengan nominal jelas (melalui teks, rekaman suara, atau foto nota/struk):\n'
    '   - intent: "RECORD_TRANSACTION"\n'
    '   - isClarificationNeeded: false\n'
    '   - Isi objek transaction secara lengkap (title, amount, type: EXPENSE/INCOME, category, paymentMethod).\n'
    '   - Berikan bankerNarrative yang mengonfirmasi pencatatan dengan bahasa bankir privat elegan.\n'
    '2. Jika ada ambiguitas kritis (misal foto struk buram, nominal tidak terbaca, atau tanpa nominal jelas):\n'
    '   - intent: "RECORD_TRANSACTION"\n'
    '   - isClarificationNeeded: true\n'
    '   - clarificationQuestion: Tanyakan rincian nominal atau kategori dengan sopan.\n'
    '   - bankerNarrative: Sampaikan bahwa pencatatan ditangguhkan hingga klarifikasi diterima.\n'
    '3. Jika nasabah bertanya tentang kondisi finansial atau laporan:\n'
    '   - intent: "QUERY_REPORT"\n'
    '   - isClarificationNeeded: false\n'
    '   - bankerNarrative: Berikan analisis ringkas dan pandangan bijak.\n'
    '4. Jika percakapan umum:\n'
    '   - intent: "GENERAL_CHAT"\n'
    '   - isClarificationNeeded: false\n'
    '   - bankerNarrative: Tanggapi dengan santun dan ingatkan kesiapan membantu keuangan nasabah.';

class FinancialFunctionsService {
  final FirebaseFunctions? _functions;
  final http.Client _httpClient;
  final String _geminiApiKey;
  final String _modelName;

  FinancialFunctionsService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
    String? geminiApiKey,
    this._modelName = 'gemini-2.5-flash',
  })  : _functions = functions ?? _resolveFunctionsInstance(),
        _httpClient = httpClient ?? http.Client(),
        _geminiApiKey = geminiApiKey ??
            const String.fromEnvironment(
              'GEMINI_API_KEY',
              defaultValue: '',
            );

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
    if (functions != null) {
      try {
        final callable = functions.httpsCallable('processFinancialIntent');
        final payload = <String, dynamic>{};
        if (text != null && text.isNotEmpty) payload['text'] = text;
        if (storagePath != null && storagePath.isNotEmpty) {
          payload['storagePath'] = storagePath;
        }
        if (mediaBase64 != null && mediaBase64.isNotEmpty) {
          payload['mediaBase64'] = mediaBase64;
        }
        if (mimeType != null && mimeType.isNotEmpty) {
          payload['mimeType'] = mimeType;
        }

        final response = await callable.call<Map<String, dynamic>>(payload);
        final body = response.data;
        if (body['success'] == true && body['data'] != null) {
          return FinancialIntentResult.fromMap(
            Map<String, dynamic>.from(body['data'] as Map),
          );
        }
      } catch (_) {
        // Fallback to direct client call when Cloud Functions is unavailable on Spark plan.
      }
    }

    if (_geminiApiKey.isNotEmpty) {
      return _callDirectGemini(
        text: text,
        mediaBase64: mediaBase64,
        mimeType: mimeType,
      );
    }

    return null;
  }

  Future<FinancialIntentResult?> _callDirectGemini({
    String? text,
    String? mediaBase64,
    String? mimeType,
  }) async {
    final key = _geminiApiKey.trim();
    if (key.isEmpty) return null;

    final parts = <Map<String, dynamic>>[];
    if (mediaBase64 != null && mimeType != null) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType,
          'data': mediaBase64,
        },
      });
    }

    final defaultText = (mimeType != null && mimeType.startsWith('audio'))
        ? 'Dengarkan rekaman suara nasabah ini, ekstrak mutasi transaksi secara terstruktur.'
        : 'Analisis foto nota struk ini, ekstrak total nominal, nama merchant, dan kategori transaksi secara presisi.';

    parts.add({
      'text': (text != null && text.trim().isNotEmpty) ? text.trim() : defaultText,
    });

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {'text': bankerSystemInstruction}
        ]
      },
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$key',
    );

    try {
      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonBody['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final resParts = content?['parts'] as List?;
      if (resParts == null || resParts.isEmpty) return null;

      final textResult =
          (resParts.first as Map<String, dynamic>)['text'] as String?;
      if (textResult == null || textResult.isEmpty) return null;

      String cleanJson = textResult.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final parsedData = jsonDecode(cleanJson) as Map<String, dynamic>;
      return FinancialIntentResult.fromMap(parsedData);
    } catch (_) {
      return null;
    }
  }
}
