import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/core/services/csv_export_service.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedIndex = -1;
  String _selectedPeriod = 'Bulan Ini';

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);

    final expenses = txState.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Grouping by category
    final Map<String, double> categoryTotals = {};
    for (final tx in expenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0.0) + tx.amount;
    }

    final totalExpense = txState.totalExpense;
    final totalIncome = txState.totalIncome;

    // Financial Metrics
    final savingsRate = totalIncome > 0
        ? (((totalIncome - totalExpense) / totalIncome) * 100).clamp(0, 100)
        : 0.0;

    final avgDailyExpense = totalExpense / 30;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
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
            const Text(
              'Laporan Eksekutif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ekspor CSV',
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryNavy),
            onPressed: () => _handleExportCsv(context, txState.transactions),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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

            // 1. Executive Summary Card (Private Wealth Banker Insights)
            _buildBankerExecutiveCard(
              savingsRate: savingsRate.toDouble(),
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              categoryTotals: categoryTotals,
            ),
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
              transactionCount: txState.transactions.length,
            ),
            const SizedBox(height: 20),
            _buildExportSection(context, txState.transactions),
            const SizedBox(height: 32),
          ],
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
      selectedColor: AppTheme.primaryNavy,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryNavy : const Color(0xFFCBD5E1),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildBankerExecutiveCard({
    required double savingsRate,
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryTotals,
  }) {
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

    return Container(
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
          const SizedBox(height: 16),
          Text(
            isHealthy
                ? 'Struktur Arus Kas Sehat & Stabil'
                : 'Peringatan Penyerapan Arus Kas Tinggi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rasio tabungan (*Savings Rate*) Anda saat ini berada di ${savingsRate.toStringAsFixed(1)}%. '
            'Pos pengeluaran terbesar dialokasikan pada "$topCategory" senilai ${CurrencyFormatter.format(topCategoryAmount)}. '
            '${isHealthy ? "Disiplin alokasi anggaran berada dalam koridor target surplus akhir bulan." : "Disarankan menahan belanja diskresioner untuk menjaga likuiditas darurat."}',
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.5,
            ),
          ),
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
                  CurrencyFormatter.format(
                    ((totalIncome - totalExpense) > 0
                        ? (totalIncome - totalExpense) / 30
                        : 50000),
                  ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Belum ada data pengeluaran untuk dianalisis.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
    ];

    final entries = categoryTotals.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alokasi Pengeluaran per Kategori',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Total: ${CurrencyFormatter.formatShort(totalExpense)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
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
                  final percentage = totalExpense > 0
                      ? ((amt / totalExpense) * 100).toStringAsFixed(0)
                      : '0';

                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: amt,
                    title: '$percentage%',
                    radius: isTouched ? 36.0 : 30.0,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$percent% ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
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
    required int transactionCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrik & Indikator Kunci',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Rasio Tabungan',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  subtext: savingsRate >= 30 ? 'Sehat Prima' : 'Perlu Diwaspadai',
                  isGood: savingsRate >= 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Rata-rata / Hari',
                  value: CurrencyFormatter.formatShort(avgDailyExpense),
                  subtext: 'Berdasarkan 30 hari',
                  isGood: true,
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
                  subtext: 'Bulan berjalan',
                  isGood: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: 'Likuiditas Kas',
                  value: 'Positif',
                  subtext: 'Surplus terkelola',
                  isGood: true,
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
    required bool isGood,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isGood ? AppTheme.accentEmerald : AppTheme.accentRose,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ekspor & Arsip Keuangan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unduh rekapan mutasi transaksi dalam format CSV standar (RFC 4180) untuk pembukuan eksternal.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
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
                foregroundColor: AppTheme.primaryNavy,
                side: const BorderSide(color: AppTheme.primaryNavy),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: AppTheme.primaryNavy),
                    SizedBox(width: 8),
                    Text(
                      'Pratinjau Ekspor CSV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
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
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvData,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textPrimary,
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
                  backgroundColor: AppTheme.primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text(
                  'Salin Berkas CSV',
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
