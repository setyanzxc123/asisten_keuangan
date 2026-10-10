import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/services/financial_functions_service.dart';
import 'package:asisten_keuangan/features/assistant/data/assistant_provider.dart';
import 'package:asisten_keuangan/features/reports/domain/advisory_preference.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/wishlist/data/wishlist_provider.dart';

class AdvisoryStyleNotifier extends Notifier<AdvisoryStyle> {
  @override
  AdvisoryStyle build() => AdvisoryStyle.balanced;

  void selectStyle(AdvisoryStyle newStyle) {
    state = newStyle;
  }
}

final advisoryStyleProvider =
    NotifierProvider<AdvisoryStyleNotifier, AdvisoryStyle>(
        AdvisoryStyleNotifier.new);

class MonthlyAiAnalysisState {
  final MonthlyAnalysisResult? result;
  final bool isLoading;
  final String? errorMessage;

  const MonthlyAiAnalysisState({
    this.result,
    this.isLoading = false,
    this.errorMessage,
  });

  MonthlyAiAnalysisState copyWith({
    MonthlyAnalysisResult? result,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MonthlyAiAnalysisState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MonthlyAiAnalysisNotifier extends Notifier<MonthlyAiAnalysisState> {
  @override
  MonthlyAiAnalysisState build() {
    return const MonthlyAiAnalysisState();
  }

  Future<void> generateAnalysis() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final txState = ref.read(transactionProvider);
    final currentStyle = ref.read(advisoryStyleProvider);
    final wishlistState = ref.read(wishlistProvider);
    final aiService = ref.read(financialFunctionsServiceProvider);

    final totalIncome = txState.totalIncome;
    final totalExpense = txState.totalExpense;
    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome) * 100
        : 0.0;
    final burnRate = totalExpense / 30;

    final categoryBreakdown = <String, double>{};
    for (final tx in txState.transactions) {
      if (tx.type == TransactionType.expense) {
        categoryBreakdown[tx.category] =
            (categoryBreakdown[tx.category] ?? 0.0) + tx.amount;
      }
    }

    final activeWishlists = wishlistState.items
        .where((w) => !w.isAchieved)
        .map((w) => {
              'title': w.title,
              'targetAmount': w.targetAmount,
              'savedAmount': w.savedAmount,
              'remaining': w.remainingAmount,
            })
        .toList();

    try {
      final analysisResult = await aiService.analyzeMonthlyFinancials(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        savingsRate: savingsRate,
        burnRate: burnRate,
        categoryBreakdown: categoryBreakdown,
        advisoryStyle: currentStyle.promptKey,
        wishlists: activeWishlists,
      );

      if (analysisResult != null) {
        state = MonthlyAiAnalysisState(
          result: analysisResult,
          isLoading: false,
        );
      } else {
        // Fallback local Banker analysis when AI is offline or without API key.
        final fallback = _buildLocalFallbackAnalysis(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          savingsRate: savingsRate,
          style: currentStyle,
          activeWishlistsCount: activeWishlists.length,
        );
        state = MonthlyAiAnalysisState(
          result: fallback,
          isLoading: false,
        );
      }
    } catch (e) {
      final fallback = _buildLocalFallbackAnalysis(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        savingsRate: savingsRate,
        style: currentStyle,
        activeWishlistsCount: activeWishlists.length,
      );
      state = MonthlyAiAnalysisState(
        result: fallback,
        isLoading: false,
      );
    }
  }

  MonthlyAnalysisResult _buildLocalFallbackAnalysis({
    required double totalIncome,
    required double totalExpense,
    required double savingsRate,
    required AdvisoryStyle style,
    required int activeWishlistsCount,
  }) {
    final netCashflow = totalIncome - totalExpense;
    final isHealthy = savingsRate >= 30;

    String headline;
    String narrative;
    String rating = isHealthy ? 'PRUDENT' : 'VULNERABLE';

    switch (style) {
      case AdvisoryStyle.frugal:
        headline = isHealthy
            ? 'Pola Disiplin Arus Kas Terkendali'
            : 'Perlu Pengetatan Pengeluaran Diskresioner';
        narrative =
            'Tingkat tabungan berada pada ${savingsRate.toStringAsFixed(1)}%. '
            'Untuk mempercepat $activeWishlistsCount target wishlist aktif, disarankan menekan pos belanja impulsif dan mengalihkan minimal Rp ${(netCashflow * 0.4).clamp(0, double.infinity).toStringAsFixed(0)} ke pos tabungan prioritas.';
        break;
      case AdvisoryStyle.growth:
        headline = 'Peluang Ekspansi & Akumulasi Aset';
        narrative =
            'Arus kas bersih saat ini menghasilkan surplus modal. '
            'Rekomendasi private banker adalah memisahkan dana likuiditas operasional dan mempercepat pencapaian wishlist target dengan alokasi terstruktur.';
        break;
      case AdvisoryStyle.concise:
        headline = 'Ikhtisar Arus Kas Bulanan';
        narrative =
            '1. Rasio Simpanan: ${savingsRate.toStringAsFixed(1)}%.\n'
            '2. Wishlist Aktif: $activeWishlistsCount sasaran.\n'
            '3. Tindakan: Pertahankan batas harian agar surplus tetap terjaga.';
        break;
      case AdvisoryStyle.balanced:
        headline = isHealthy
            ? 'Struktur Arus Kas Sehat & Seimbang'
            : 'Evaluasi Penyerapan Belanja Bulanan';
        narrative =
            'Alokasi arus kas berada dalam koridor stabil dengan tingkat tabungan ${savingsRate.toStringAsFixed(1)}%. '
            'Keseimbangan antara belanja harian dan pemenuhan wishlist sasaran berjalan proporsional.';
        break;
    }

    return MonthlyAnalysisResult(
      headline: headline,
      narrative: narrative,
      portfolioRating: rating,
      recommendedDailyBudget: (totalExpense / 30).clamp(50000, 1000000),
      strategicActionPoints: const [
        'Disiplin pencatatan harian pos pengeluaran',
        'Sisihkan tabungan di awal sebelum belanja sekunder',
      ],
      usedModel: 'private-banker-local-engine',
    );
  }
}

final monthlyAiAnalysisProvider = NotifierProvider<MonthlyAiAnalysisNotifier,
    MonthlyAiAnalysisState>(MonthlyAiAnalysisNotifier.new);
