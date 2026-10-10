import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/features/assistant/presentation/assistant_chat_screen.dart';
import 'package:asisten_keuangan/features/assistant/presentation/widgets/quick_assistant_bar.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/reports/presentation/reports_screen.dart';
import 'package:asisten_keuangan/features/transactions/presentation/manual_transaction_bottom_sheet.dart';
import 'package:asisten_keuangan/core/services/biometric_service.dart';
import 'package:asisten_keuangan/core/services/network_connectivity_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RINGKASAN PORTOFOLIO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Asisten Keuangan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.pie_chart_outline_rounded),
            tooltip: 'Laporan Eksekutif',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssistantChatScreen(),
                ),
              );
            },
            icon: const Badge(
              smallSize: 8,
              backgroundColor: AppTheme.accentEmerald,
              child: Icon(Icons.forum_outlined),
            ),
            tooltip: 'Ruang Konsultasi Asisten',
          ),
          IconButton(
            tooltip: 'Kunci Biometrik',
            icon: const Icon(Icons.fingerprint_rounded),
            onPressed: () async {
              final bioService = ref.read(biometricServiceProvider);
              final isAvailable = await bioService.isBiometricAvailable();
              if (!context.mounted) return;

              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sensor biometrik tidak aktif atau tidak didukung di perangkat ini.',
                    ),
                    backgroundColor: AppTheme.accentRose,
                  ),
                );
                return;
              }

              final success = await bioService.authenticate();
              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verifikasi biometrik berhasil.'),
                    backgroundColor: AppTheme.accentEmerald,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOnline) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFC2410C)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mode Offline Aktif - Transaksi disimpan aman di penyimpanan lokal.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // 1. Executive Cashflow Card
                _buildCashflowCard(txState),
                const SizedBox(height: 16),

                // 2. Budget Absorption Gauge Card
                _buildBudgetGaugeCard(txState),
                const SizedBox(height: 16),

                // 3. Reports Banner Card
                _buildReportsBannerCard(context),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mutasi Terakhir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Geser untuk edit atau hapus',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          ManualTransactionBottomSheet.show(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Input Manual',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (txState.transactions.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txState.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = txState.transactions[index];
                      return _buildTransactionItem(context, ref, tx);
                    },
                  ),
              ],
            ),
          ),

          // Bottom Quick Assistant Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: QuickAssistantBar(
              onExpandChat: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AssistantChatScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowCard(TransactionState state) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Arus Kas Bersih (Net Cashflow)',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(state.netCashflow),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFlowItem(
                  label: 'Pemasukan',
                  amount: state.totalIncome,
                  color: AppTheme.accentEmerald,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                height: 32,
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _buildFlowItem(
                  label: 'Pengeluaran',
                  amount: state.totalExpense,
                  color: AppTheme.accentRose,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowItem({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                Text(
                  CurrencyFormatter.formatShort(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetGaugeCard(TransactionState state) {
    final percentage = (state.budgetUsedPercentage * 100).toInt();
    final isWarning = percentage >= 80;
    final isDanger = percentage >= 100;

    final progressColor = isDanger
        ? AppTheme.accentRose
        : (isWarning ? AppTheme.accentGold : AppTheme.accentEmerald);

    return Container(
      padding: const EdgeInsets.all(18),
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
                'Alokasi Anggaran Bulanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '$percentage% Terpakai',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.budgetUsedPercentage,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa: ${CurrencyFormatter.format(state.remainingBudget)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(state.monthlyBudget)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    final isExpense = tx.type == TransactionType.expense;

    return Dismissible(
      key: Key('tx_${tx.id}'),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentRose,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ManualTransactionBottomSheet.show(
            context,
            initialTransaction: tx,
          );
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Hapus Transaksi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Text('Apakah Anda yakin ingin menghapus "${tx.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ) ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaksi "${tx.title}" dihapus'),
              action: SnackBarAction(
                label: 'Urungkan',
                textColor: AppTheme.accentGold,
                onPressed: () {
                  ref.read(transactionProvider.notifier).addTransaction(tx);
                },
              ),
            ),
          );
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ManualTransactionBottomSheet.show(
            context,
            initialTransaction: tx,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isExpense
                      ? AppTheme.accentRose.withValues(alpha: 0.08)
                      : AppTheme.accentEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense
                      ? Icons.shopping_bag_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: isExpense ? AppTheme.accentRose : AppTheme.accentEmerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${tx.category} • ${tx.paymentMethod}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceBadge(tx.source),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(tx.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isExpense ? AppTheme.accentRose : AppTheme.accentEmerald,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(TransactionSource source) {
    IconData icon;
    String label;
    switch (source) {
      case TransactionSource.voice:
        icon = Icons.mic;
        label = 'Voice';
        break;
      case TransactionSource.receipt:
        icon = Icons.receipt;
        label = 'Struk';
        break;
      case TransactionSource.text:
        icon = Icons.edit_note;
        label = 'Teks';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.textSecondary),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsBannerCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pie_chart_rounded,
                color: AppTheme.primaryNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Eksekutif & Analisis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Komposisi pengeluaran & rekomendasi AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Text(
        'Belum ada transaksi. Coba diktekan pada bar asisten di bawah.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}
