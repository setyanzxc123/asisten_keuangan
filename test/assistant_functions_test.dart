import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/financial_functions_service.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/assistant/domain/chat_message.dart';
import 'package:asisten_keuangan/features/transactions/data/firestore_transaction_repository.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_repository.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final Map<String, List<TransactionModel>> _storage = {};
  final Map<String, double> _budgets = {};
  final StreamController<List<TransactionModel>> _controller =
      StreamController<List<TransactionModel>>.broadcast();

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _controller.stream;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    return _storage[userId] ?? [];
  }

  @override
  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    final list = _storage[userId] ?? [];
    list.insert(0, transaction);
    _storage[userId] = list;
    _controller.add(List.from(list));
  }

  @override
  Future<void> updateTransaction(String userId, TransactionModel transaction) async {
    final list = _storage[userId] ?? [];
    final idx = list.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      list[idx] = transaction;
      _storage[userId] = list;
      _controller.add(List.from(list));
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    final list = _storage[userId] ?? [];
    list.removeWhere((t) => t.id == transactionId);
    _storage[userId] = list;
    _controller.add(List.from(list));
  }

  @override
  Future<double> getMonthlyBudget(String userId) async {
    return _budgets[userId] ?? 15000000.0;
  }

  @override
  Future<void> setMonthlyBudget(String userId, double budget) async {
    _budgets[userId] = budget;
  }

  void dispose() {
    _controller.close();
  }
}

class FakeSuccessFunctionsService extends FinancialFunctionsService {
  final FinancialIntentResult result;

  FakeSuccessFunctionsService(this.result);

  @override
  Future<FinancialIntentResult?> processFinancialIntent({
    String? text,
    String? storagePath,
    String? mediaBase64,
    String? mimeType,
  }) async {
    return result;
  }
}

void main() {
  group('FinancialIntentResult Tests', () {
    test('parses json map into structured response', () {
      final map = {
        'intent': 'RECORD_TRANSACTION',
        'isClarificationNeeded': false,
        'clarificationQuestion': null,
        'bankerNarrative': 'Transaksi kopi dicatat dengan aman.',
        'transaction': {
          'title': 'Kopi Cold Brew',
          'amount': 45000,
          'type': 'EXPENSE',
          'category': 'Makanan & Minuman',
          'paymentMethod': 'QRIS',
        },
      };

      final parsed = FinancialIntentResult.fromMap(map);
      expect(parsed.intent, equals('RECORD_TRANSACTION'));
      expect(parsed.isClarificationNeeded, isFalse);
      expect(parsed.bankerNarrative, equals('Transaksi kopi dicatat dengan aman.'));
      expect(parsed.transaction?['title'], equals('Kopi Cold Brew'));
      expect(parsed.transaction?['amount'], equals(45000));
    });

    test('FinancialFunctionsService handles uninitialized Firebase gracefully', () async {
      final service = FinancialFunctionsService();
      final result = await service.processFinancialIntent(text: 'test intent');
      expect(result, isNull);
    });
  });

  group('Direct Gemini Client (Spark Plan Mode) Tests', () {
    test('direct call parses successful gemini json payload accurately', () async {
      final mockClient = MockHttpClient((request) async {
        expect(request.url.toString(), contains('models/gemini-3.5-flash-lite:generateContent'));
        expect(request.url.queryParameters['key'], equals('test-spark-key'));

        final requestJson = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(requestJson['generationConfig']['thinkingConfig']['thinkingLevel'], equals('HIGH'));

        final body = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'intent': 'RECORD_TRANSACTION',
                      'isClarificationNeeded': false,
                      'bankerNarrative': 'Makan siang sebesar Rp 35.000 telah kami bukukan.',
                      'transaction': {
                        'title': 'Makan Siang',
                        'amount': 35000,
                        'type': 'EXPENSE',
                        'category': 'Makanan & Minuman',
                        'paymentMethod': 'QRIS',
                      },
                    })
                  }
                ]
              }
            }
          ]
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.processFinancialIntent(text: 'makan siang 35rb qris');
      expect(result, isNotNull);
      expect(result!.intent, equals('RECORD_TRANSACTION'));
      expect(result.transaction?['title'], equals('Makan Siang'));
      expect(result.transaction?['amount'], equals(35000));
      expect(result.bankerNarrative, equals('Makan siang sebesar Rp 35.000 telah kami bukukan.'));
    });

    test('direct call parses markdown code-fenced json response', () async {
      final mockClient = MockHttpClient((request) async {
        final innerJson = jsonEncode({
          'intent': 'RECORD_TRANSACTION',
          'isClarificationNeeded': false,
          'bankerNarrative': 'Pembelian bensin dibukukan.',
          'transaction': {
            'title': 'Bensin',
            'amount': 50000,
            'type': 'EXPENSE',
            'category': 'Transportasi',
            'paymentMethod': 'Tunai',
          },
        });

        final body = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '```json\n$innerJson\n```'}
                ]
              }
            }
          ]
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.processFinancialIntent(text: 'beli bensin 50rb tunai');
      expect(result, isNotNull);
      expect(result!.transaction?['title'], equals('Bensin'));
      expect(result.transaction?['amount'], equals(50000));
    });

    test('direct call handles multimodal input in request body', () async {
      late Map<String, dynamic> capturedBody;
      final mockClient = MockHttpClient((request) async {
        final req = request as http.Request;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;

        final body = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'intent': 'RECORD_TRANSACTION',
                      'isClarificationNeeded': false,
                      'bankerNarrative': 'Foto struk berhasil diproses.',
                      'transaction': {
                        'title': 'Supermarket',
                        'amount': 120000,
                        'type': 'EXPENSE',
                        'category': 'Belanja',
                        'paymentMethod': 'Kartu Debit',
                      },
                    })
                  }
                ]
              }
            }
          ]
        });

        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.processFinancialIntent(
        mediaBase64: 'fake-base64-image-bytes',
        mimeType: 'image/jpeg',
      );

      expect(result, isNotNull);
      expect(result!.transaction?['amount'], equals(120000));
      expect(capturedBody['contents'][0]['parts'].length, equals(2));
      expect(capturedBody['contents'][0]['parts'][0]['inline_data']['mime_type'], equals('image/jpeg'));
    });

    test('direct call handles http error gracefully', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.processFinancialIntent(text: 'test failure');
      expect(result, isNull);
    });
  });

  group('Monthly Financials Rolling Models Engine Tests', () {
    test('rolls to next model when earlier model returns 429 rate limit', () async {
      final requestedModels = <String>[];
      final mockClient = MockHttpClient((request) async {
        final url = request.url.toString();
        if (url.contains('gemini-3.5-flash:generateContent')) {
          requestedModels.add('gemini-3.5-flash');
          return http.Response('{"error":{"code":429,"message":"Resource exhausted"}}', 429);
        } else if (url.contains('gemini-3.6-flash:generateContent')) {
          requestedModels.add('gemini-3.6-flash');
          final body = jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'headline': 'Kinerja Arus Kas Solid',
                        'narrative': 'Surplus bulanan Anda mendukung percepatan target wishlist.',
                        'portfolioRating': 'PRUDENT',
                        'recommendedDailyBudget': 300000,
                        'strategicActionPoints': [
                          'Alokasikan surplus ke tabungan wishlist',
                          'Pertahankan batas belanja harian',
                        ],
                      })
                    }
                  ]
                }
              }
            ]
          });
          return http.Response(body, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not found', 404);
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.analyzeMonthlyFinancials(
        totalIncome: 15000000,
        totalExpense: 9000000,
        savingsRate: 40.0,
        burnRate: 300000,
        categoryBreakdown: {'Makanan': 3000000, 'Tagihan': 2000000},
        advisoryStyle: 'frugal',
        wishlists: [
          {'title': 'MacBook Pro', 'targetAmount': 20000000, 'savedAmount': 6000000}
        ],
      );

      expect(result, isNotNull);
      expect(result!.usedModel, equals('gemini-3.6-flash'));
      expect(result.headline, equals('Kinerja Arus Kas Solid'));
      expect(result.portfolioRating, equals('PRUDENT'));
      expect(result.recommendedDailyBudget, equals(300000));
      expect(result.strategicActionPoints.length, equals(2));
      expect(requestedModels, equals(['gemini-3.5-flash', 'gemini-3.6-flash']));
    });

    test('returns null when all rolling models fail with errors', () async {
      final mockClient = MockHttpClient((request) async {
        return http.Response('High demand overload', 503);
      });

      final service = FinancialFunctionsService(
        httpClient: mockClient,
        geminiApiKey: 'test-spark-key',
      );

      final result = await service.analyzeMonthlyFinancials(
        totalIncome: 10000000,
        totalExpense: 5000000,
        savingsRate: 50.0,
        burnRate: 160000,
        categoryBreakdown: {'Operasional': 5000000},
      );

      expect(result, isNull);
    });
  });

  group('AssistantNotifier with Cloud Functions Integration Tests', () {
    test('processes RECORD_TRANSACTION from cloud callable and commits transaction', () async {
      final fakeRepo = FakeTransactionRepository();
      const fakeResult = FinancialIntentResult(
        intent: 'RECORD_TRANSACTION',
        isClarificationNeeded: false,
        bankerNarrative: 'Pembelian laptop berhasil dibukukan dalam portofolio Anda.',
        transaction: {
          'title': 'Laptop Kerja',
          'amount': 15000000,
          'type': 'EXPENSE',
          'category': 'Peralatan Kantor',
          'paymentMethod': 'Transfer Bank',
        },
      );

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
          financialFunctionsServiceProvider.overrideWithValue(
            FakeSuccessFunctionsService(fakeResult),
          ),
        ],
      );
      addTearDown(() {
        fakeRepo.dispose();
        container.dispose();
      });

      final notifier = container.read(assistantProvider.notifier);
      await notifier.sendUserMessage(text: 'Beli laptop 15 juta transfer');

      final assistantState = container.read(assistantProvider);
      expect(assistantState.isThinking, isFalse);
      expect(assistantState.messages.length, greaterThanOrEqualTo(2));

      final lastMessage = assistantState.messages.last;
      expect(lastMessage.sender, equals(MessageSender.banker));
      expect(lastMessage.status, equals(MessageStatus.committed));
      expect(lastMessage.extractedTransaction?.title, equals('Laptop Kerja'));

      final txState = container.read(transactionProvider);
      expect(txState.transactions.any((tx) => tx.title == 'Laptop Kerja'), isTrue);
    });

    test('handles clarification required status from cloud intent', () async {
      final fakeRepo = FakeTransactionRepository();
      const fakeClarifyResult = FinancialIntentResult(
        intent: 'RECORD_TRANSACTION',
        isClarificationNeeded: true,
        clarificationQuestion: 'Mohon konfirmasi metode pembayaran pengeluaran ini.',
        bankerNarrative: 'Pencatatan ditangguhkan menunggu metode pembayaran.',
        transaction: {
          'title': 'Langganan Server',
          'amount': 2500000,
          'type': 'EXPENSE',
          'category': 'Teknologi',
          'paymentMethod': 'Belum Ditentukan',
        },
      );

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeRepo),
          financialFunctionsServiceProvider.overrideWithValue(
            FakeSuccessFunctionsService(fakeClarifyResult),
          ),
        ],
      );
      addTearDown(() {
        fakeRepo.dispose();
        container.dispose();
      });

      final notifier = container.read(assistantProvider.notifier);
      await notifier.sendUserMessage(text: 'Langganan server 2.5 juta');

      final assistantState = container.read(assistantProvider);
      expect(assistantState.pendingTransaction, isNotNull);

      final lastMessage = assistantState.messages.last;
      expect(lastMessage.status, equals(MessageStatus.pendingClarification));

      await notifier.sendUserMessage(text: 'Bayar pakai kartu kredit');

      final updatedState = container.read(assistantProvider);
      expect(updatedState.pendingTransaction, isNull);
      expect(updatedState.messages.last.status, equals(MessageStatus.committed));

      final txState = container.read(transactionProvider);
      expect(txState.transactions.any((tx) => tx.paymentMethod == 'Kartu Kredit'), isTrue);
    });
  });
}
