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

class MonthlyAnalysisResult {
  final String headline;
  final String narrative;
  final String portfolioRating;
  final double recommendedDailyBudget;
  final List<String> strategicActionPoints;
  final String usedModel;

  const MonthlyAnalysisResult({
    required this.headline,
    required this.narrative,
    required this.portfolioRating,
    required this.recommendedDailyBudget,
    required this.strategicActionPoints,
    required this.usedModel,
  });

  factory MonthlyAnalysisResult.fromMap(
    Map<String, dynamic> map, {
    String usedModel = 'gemini-3.5-flash',
  }) {
    final actionsList = (map['strategicActionPoints'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return MonthlyAnalysisResult(
      headline: (map['headline'] as String?) ?? 'Analisis Arus Kas Bulanan',
      narrative: (map['narrative'] as String?) ?? '',
      portfolioRating: (map['portfolioRating'] as String?) ?? 'PRUDENT',
      recommendedDailyBudget:
          ((map['recommendedDailyBudget'] as num?) ?? 0).toDouble(),
      strategicActionPoints: actionsList,
      usedModel: usedModel,
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

const List<String> defaultMonthlyRollingModels = [
  'gemini-3.5-flash',
  'gemini-3.6-flash',
  'gemini-3.7-flash',
  'gemini-3.8-flash',
];

class FinancialFunctionsService {
  final FirebaseFunctions? _functions;
  final http.Client _httpClient;
  final String _geminiApiKey;
  final String _commandModelName;

  FinancialFunctionsService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
    String? geminiApiKey,
    this._commandModelName = 'gemini-3.5-flash-lite',
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
        'thinkingConfig': {
          'thinkingLevel': 'HIGH',
        },
      }
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_commandModelName:generateContent?key=$key',
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

  Future<MonthlyAnalysisResult?> analyzeMonthlyFinancials({
    required double totalIncome,
    required double totalExpense,
    required double savingsRate,
    required double burnRate,
    required Map<String, double> categoryBreakdown,
    String advisoryStyle = 'balanced',
    List<Map<String, dynamic>> wishlists = const [],
    List<String> rollingModels = defaultMonthlyRollingModels,
  }) async {
    final key = _geminiApiKey.trim();
    if (key.isEmpty) {
      return null;
    }

    final netCashflow = totalIncome - totalExpense;
    final promptPayload = {
      'metrics': {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netCashflow': netCashflow,
        'savingsRate': savingsRate,
        'dailyBurnRate': burnRate,
        'categoryBreakdown': categoryBreakdown,
      },
      'advisoryStyle': advisoryStyle,
      'wishlists': wishlists,
    };

    final systemInstructionText =
        'Anda adalah Penasihat Keuangan Eksekutif (Private Wealth Banker) pribadi kelas dunia.\n'
        'Analisis data keuangan bulanan nasabah dengan gaya penasihat: "$advisoryStyle".\n'
        'Evaluasi arus kas, stabilitas simpanan, dan integrasikan proyeksi ketercapaian target Wishlist nasabah secara konkret.\n'
        'Kembalikan respons HANYA dalam format JSON valid dengan skema:\n'
        '{\n'
        '  "headline": "Judul tajuk eksekutif ringkas",\n'
        '  "narrative": "Paragraf evaluasi mendalam dan proyeksi target belanja",\n'
        '  "portfolioRating": "EXCELLENT | PRUDENT | NEUTRAL | VULNERABLE",\n'
        '  "recommendedDailyBudget": 250000,\n'
        '  "strategicActionPoints": ["Poin aksi konkret 1", "Poin aksi konkret 2"]\n'
        '}';

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstructionText}
        ]
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Berikut data performa portofolio keuangan dan wishlist nasabah bulan ini:\n${jsonEncode(promptPayload)}'
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.3,
      }
    };

    for (final model in rollingModels) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
      );

      try {
        final response = await _httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = jsonBody['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) continue;

          final firstCandidate = candidates.first as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final resParts = content?['parts'] as List?;
          if (resParts == null || resParts.isEmpty) continue;

          final textResult =
              (resParts.first as Map<String, dynamic>)['text'] as String?;
          if (textResult == null || textResult.isEmpty) continue;

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
          return MonthlyAnalysisResult.fromMap(parsedData, usedModel: model);
        }

        // On 429, 500, or 503, roll to next model in the pool.
        if (response.statusCode == 429 ||
            response.statusCode == 503 ||
            response.statusCode == 500) {
          continue;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}
