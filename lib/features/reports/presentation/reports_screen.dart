import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/core/services/csv_export_service.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/reports/presentation/widgets/advisory_chip_selector.dart';
import 'package:asisten_keuangan/features/reports/presentation/widgets/wishlist_section_widget.dart';
import 'package:asisten_keuangan/features/reports/data/monthly_ai_analysis_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedIndex = -1;
  String _selectedPeriod = 'Bulan Ini';

  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Minggu Ini':
        return now.subtract(const Duration(days: 7));
      case 'Kuartal Ini':
        return now.subtract(const Duration(days: 90));
      default:
        return DateTime(now.year, now.month);
    }
  }

  int _periodDays() {
    switch (_selectedPeriod) {
      case 'Minggu Ini':
        return 7;
      case 'Kuartal Ini':
        return 90;
      default:
        return DateTime.now().day;
    }
  }

  List<TransactionModel> _transactionsForPeriod(
    List<TransactionModel> all,
  ) {
    final start = _periodStart();
    return all.where((t) => !t.date.isBefore(start)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);

    final periodTransactions = _transactionsForPeriod(txState.transactions);
    final expenses = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Grouping by category
    final Map<String, double> categoryTotals = {};
    for (final tx in expenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netCashflow = totalIncome - totalExpense;

    // Financial Metrics
    final savingsRate = totalIncome > 0
        ? (((totalIncome - totalExpense) / totalIncome) * 100).clamp(0, 100)
        : 0.0;

    final avgDailyExpense = totalExpense / _periodDays();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALISIS & LAPORAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Laporan Eksekutif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ekspor CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _handleExportCsv(context, txState.transactions),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Filter Chips
                Row(
                  children: [
                    _buildPeriodChip('Minggu Ini'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Bulan Ini'),
                    const SizedBox(width: 8),
                    _buildPeriodChip('Kuartal Ini'),
                  ],
                ),
                const SizedBox(height: 16),

                // Advisory Style Chip Selector
                const AdvisoryChipSelector(),
                const SizedBox(height: 16),

                // 1. Executive Summary Card (Private Wealth Banker Insights)
                _buildBankerExecutiveCard(
                  savingsRate: savingsRate.toDouble(),
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                  categoryTotals: categoryTotals,
                  isDataLoading: txState.isLoading,
                  hasNoData: periodTransactions.isEmpty,
                ),
                const SizedBox(height: 24),

                // Target Impian & Wishlist Section
                const WishlistSectionWidget(),
                const SizedBox(height: 20),

                // 2. Category Expense Breakdown (Pie / Donut Chart)
                _buildCategoryBreakdownCard(
                  categoryTotals: categoryTotals,
                  totalExpense: totalExpense,
                ),
                const SizedBox(height: 20),

                // 3. Key Financial Ratios Card
                _buildFinancialRatiosCard(
                  savingsRate: savingsRate.toDouble(),
                  avgDailyExpense: avgDailyExpense,
                  netCashflow: netCashflow,
                  transactionCount: periodTransactions.length,
                  periodDays: _periodDays(),
                  isDataLoading: txState.isLoading,
                  hasNoData: periodTransactions.isEmpty,
                ),
                const SizedBox(height: 20),
                _buildExportSection(context, txState.transactions),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedPeriod = label),
      selectedColor: AppTheme.accentPrimaryOf(context),
      backgroundColor: AppTheme.cardOf(context),
      side: BorderSide(
        color: isSelected
            ? AppTheme.accentPrimaryOf(context)
            : AppTheme.borderOf(context),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? AppTheme.onAccentPrimaryOf(context)
            : AppTheme.textPrimaryOf(context),
      ),
    );
  }

  Widget _buildBankerExecutiveCard({
    required double savingsRate,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryTotals,
    required bool isDataLoading,
    required bool hasNoData,
  }) {
    final aiState = ref.watch(monthlyAiAnalysisProvider);
    final aiResult = aiState.result;

    // Determine Top Category
    String topCategory = 'Operasional';
    double topCategoryAmount = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > topCategoryAmount) {
        topCategoryAmount = amt;
        topCategory = cat;
      }
    });

    final isHealthy = savingsRate >= 30;

    return Semantics(
      container: true,
      label:
          'Ringkasan eksekutif penasihat perbankan: Rasio tabungan ${savingsRate.toStringAsFixed(1)}%, total pemasukan ${CurrencyFormatter.format(totalIncome)}, total pengeluaran ${CurrencyFormatter.format(totalExpense)}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.accentEmerald,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ringkasan Penasihat Finansial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (aiState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentEmerald,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Segarkan Analisis AI',
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white70),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () {
                    ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            aiResult?.headline ??
                (isDataLoading
                    ? 'Memuat data transaksi...'
                    : (hasNoData
                        ? 'Belum Ada Data untuk Dianalisis'
                        : (isHealthy
                            ? 'Struktur Arus Kas Sehat & Stabil'
                            : 'Peringatan Penyerapan Arus Kas Tinggi'))),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            aiResult?.narrative ??
                (isDataLoading
                    ? 'Ringkasan penasihat akan tersedia setelah data transaksi selesai dimuat.'
                    : (hasNoData
                        ? 'Belum ada transaksi pada periode ini. Catat pemasukan atau pengeluaran Anda untuk mendapatkan ringkasan dan rekomendasi penasihat.'
                        : ('Rasio tabungan (*Savings Rate*) Anda saat ini berada di ${savingsRate.toStringAsFixed(1)}%. '
                            'Pos pengeluaran terbesar dialokasikan pada "$topCategory" senilai ${CurrencyFormatter.format(topCategoryAmount)}. '
                            '${isHealthy ? "Disiplin alokasi anggaran berada dalam koridor target surplus akhir bulan." : "Disarankan menahan belanja diskresioner untuk menjaga likuiditas darurat."}'))),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (aiResult?.strategicActionPoints.isNotEmpty ?? false) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REKOMENDASI TAKTIS BANKER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentEmerald,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...aiResult!.strategicActionPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Expanded(
                              child: Text(
                                point,
                                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekomendasi Plafon Harian:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                Text(
                  isDataLoading
                      ? 'Memuat...'
                      : (aiResult != null && aiResult.recommendedDailyBudget > 0
                          ? CurrencyFormatter.format(aiResult.recommendedDailyBudget)
                          : (totalIncome - totalExpense) > 0
                              ? CurrencyFormatter.format(
                                  (totalIncome - totalExpense) / 30)
                              : 'Menunggu surplus'),
                  style: const TextStyle(
                    color: AppTheme.accentEmerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCategoryBreakdownCard({
    required Map<String, double> categoryTotals,
    required double totalExpense,
  }) {
    if (categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        alignment: Alignment.center,
        child: Text(
          'Belum ada data pengeluaran untuk dianalisis.',
          style: TextStyle(
            color: AppTheme.textSecondaryOf(context),
            fontSize: 13,
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFFF59E0B), // Amber (Food)
      const Color(0xFF3B82F6), // Blue (Transport)
      const Color(0xFF8B5CF6), // Purple (Bills)
      const Color(0xFFEC4899), // Pink (Shopping)
      const Color(0xFF10B981), // Emerald
      const Color(0xFF64748B), // Slate
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF6366F1), // Indigo
    ];

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Alokasi Pengeluaran per Kategori',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${CurrencyFormatter.formatShort(totalExpense)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Donut Chart
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 45,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final amt = entries[i].value;
                  final pctVal = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;
                  final percentage = pctVal.toStringAsFixed(0);
                  final sliceColor = colors[i % colors.length];
                  final isLightSlice =
                      ThemeData.estimateBrightnessForColor(sliceColor) == Brightness.light;
                  final shouldShowTitle = pctVal >= 6.0;

                  return PieChartSectionData(
                    color: sliceColor,
                    value: amt,
                    title: shouldShowTitle ? '$percentage%' : '',
                    radius: isTouched ? 36.0 : 30.0,
                    titleStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLightSlice ? AppTheme.primaryNavy : Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Legend List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final cat = entries[i].key;
              final amt = entries[i].value;
              final percent = totalExpense > 0
                  ? ((amt / totalExpense) * 100).toStringAsFixed(1)
                  : '0';
              final color = colors[i % colors.length];

              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  Text(
                    '$percent% ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amt),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRatiosCard({
    required double savingsRate,
    required double avgDailyExpense,
    required double netCashflow,
    required int transactionCount,
    required int periodDays,
    required bool isDataLoading,
    required bool hasNoData,
  }) {
    final liquiditySubtext = isDataLoading
        ? 'Memuat...'
        : (netCashflow > 0
            ? 'Surplus terkelola'
            : (netCashflow < 0 ? 'Defisit - perlu atensi' : 'Netral'));
    final liquidityGood = isDataLoading || hasNoData
        ? null
        : (netCashflow > 0 ? true : (netCashflow < 0 ? false : null));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrik & Indikator Kunci',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Rasio Tabungan',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  subtext: isDataLoading
                      ? 'Memuat...'
                      : (hasNoData
                          ? 'Belum ada data'
                          : (savingsRate >= 30
                              ? 'Sehat Prima'
                              : 'Perlu Diwaspadai')),
                  isGood: isDataLoading || hasNoData
                      ? null
                      : savingsRate >= 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Rata-rata / Hari',
                  value: CurrencyFormatter.formatShort(avgDailyExpense),
                  subtext: 'Berdasarkan $periodDays hari terakhir',
                  isGood: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Aktivitas Catatan',
                  value: '$transactionCount Transaksi',
                  subtext: 'Periode: $_selectedPeriod',
                  isGood: null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Likuiditas Kas',
                  value: CurrencyFormatter.formatShort(netCashflow),
                  subtext: liquiditySubtext,
                  isGood: liquidityGood,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required bool? isGood,
  }) {
    final subtextColor = isGood == null
        ? AppTheme.textSecondaryOf(context)
        : (isGood
            ? (AppTheme.isDark(context)
                ? AppTheme.accentEmerald
                : AppTheme.accentEmeraldText)
            : AppTheme.accentRose);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.fillOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ekspor & Arsip Keuangan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unduh rekapan mutasi transaksi dalam format CSV standar (RFC 4180) untuk pembukuan eksternal.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _handleExportCsv(context, transactions),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text(
                'Ekspor Riwayat Mutasi (.CSV)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentPrimaryOf(context),
                side: BorderSide(color: AppTheme.accentPrimaryOf(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleExportCsv(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    const exporter = CsvExportService();
    final csvData = exporter.generateCsv(transactions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: AppTheme.accentPrimaryOf(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Pratinjau Ekspor CSV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total ${transactions.length} mutasi berhasil diformat ke CSV.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.fillOf(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvData,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: csvData));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data CSV berhasil disalin ke clipboard!'),
                      backgroundColor: AppTheme.accentEmerald,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimaryOf(context),
                  foregroundColor: AppTheme.onAccentPrimaryOf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Salin CSV ke Clipboard',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
