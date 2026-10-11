import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/features/assistant/presentation/assistant_chat_screen.dart';
import 'package:asisten_keuangan/features/assistant/presentation/widgets/quick_assistant_bar.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/reports/presentation/reports_screen.dart';
import 'package:asisten_keuangan/features/reports/presentation/widgets/wishlist_section_widget.dart';
import 'package:asisten_keuangan/features/settings/presentation/settings_screen.dart';
import 'package:asisten_keuangan/features/transactions/presentation/transaction_history_screen.dart';
import 'package:asisten_keuangan/features/wishlist/data/wishlist_provider.dart';
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RINGKASAN PORTOFOLIO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 1.2,
              ),
            ),
            const Text(
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
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Ruang Konsultasi Asisten',
          ),
          FutureBuilder<bool>(
            future: ref.read(biometricServiceProvider).isBiometricAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Verifikasi Biometrik',
                icon: const Icon(Icons.fingerprint_rounded),
                onPressed: () async {
                  final bioService = ref.read(biometricServiceProvider);
                  final success = await bioService.authenticate();
                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verifikasi biometrik berhasil.'),
                        backgroundColor: AppTheme.accentEmerald,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verifikasi biometrik tidak berhasil.'),
                      ),
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
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
                          color: AppTheme.warningBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.warningBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 18, color: AppTheme.warningText),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mode Offline Aktif - Transaksi disimpan aman di penyimpanan lokal.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.warningText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                // 1. Executive Cashflow Card
                _buildCashflowCard(context, txState),
                const SizedBox(height: 16),

                // 2. Budget Absorption Gauge Card
                _buildBudgetGaugeCard(context, txState),
                const SizedBox(height: 16),

                // 3. Reports Banner Card
                _buildReportsBannerCard(context),
                const SizedBox(height: 20),

                // 4. Savings Targets & Wishlist
                const WishlistSectionWidget(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mutasi Terakhir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Geser atau buka menu untuk mengelola',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        foregroundColor: AppTheme.accentPrimaryOf(context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (txState.isLoading)
                  _buildLoadingState(context)
                else if (txState.transactions.isEmpty)
                  _buildEmptyState(context, ref)
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txState.transactions.length > 15
                        ? 15
                        : txState.transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = txState.transactions[index];
                      return _buildTransactionItem(context, ref, tx);
                    },
                  ),
                  if (txState.transactions.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text(
                          txState.transactions.length > 15
                              ? 'Lihat Semua (${txState.transactions.length} transaksi)'
                              : 'Lihat Semua Transaksi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondaryOf(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),

          // Bottom Quick Assistant Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowCard(BuildContext context, TransactionState state) {
    return Semantics(
      container: true,
      label:
          'Arus kas bersih bulan ini: ${CurrencyFormatter.format(state.netCashflow)}. Pemasukan: ${CurrencyFormatter.format(state.totalIncome)}, Pengeluaran: ${CurrencyFormatter.format(state.totalExpense)}.',
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
              state.isLoading ? 'Memuat...' : CurrencyFormatter.format(state.netCashflow),
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
                    context: context,
                    label: 'Pemasukan',
                    valueText: state.isLoading
                        ? '—'
                        : CurrencyFormatter.formatShort(state.totalIncome),
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
                    context: context,
                    label: 'Pengeluaran',
                    valueText: state.isLoading
                        ? '—'
                        : CurrencyFormatter.formatShort(state.totalExpense),
                    color: AppTheme.accentRose,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowItem({
    required BuildContext context,
    required String label,
    required String valueText,
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
                  valueText,
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

  Widget _buildBudgetGaugeCard(
    BuildContext context,
    TransactionState state,
  ) {
    final percentage = (state.budgetUsedPercentage * 100).toInt();
    final isWarning = percentage >= 80;
    final isDanger = percentage >= 100;
    final isLoading = state.isLoading;

    final progressColor = isDanger
        ? AppTheme.accentRose
        : (isWarning ? AppTheme.accentGold : AppTheme.accentEmerald);

    return Semantics(
      container: true,
      label:
          'Alokasi anggaran bulanan: $percentage% terpakai. Sisa anggaran: ${CurrencyFormatter.format(state.remainingBudget)} dari target ${CurrencyFormatter.format(state.monthlyBudget)}.',
      child: Container(
        padding: const EdgeInsets.all(18),
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
                Text(
                  'Alokasi Anggaran Bulanan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                Text(
                  isLoading ? 'Memuat...' : '$percentage% Terpakai',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isLoading
                        ? AppTheme.textSecondaryOf(context)
                        : progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: isLoading ? null : state.budgetUsedPercentage,
                minHeight: 10,
                backgroundColor: AppTheme.trackOf(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLoading ? AppTheme.textSecondaryOf(context) : progressColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLoading
                      ? 'Memuat data anggaran...'
                      : 'Sisa: ${CurrencyFormatter.format(state.remainingBudget)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
                Text(
                  isLoading
                      ? ''
                      : 'Target: ${CurrencyFormatter.format(state.monthlyBudget)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          return await _confirmDelete(context, tx) ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteTransaction(context, ref, tx);
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
            color: AppTheme.cardOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderOf(context)),
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
                        Flexible(
                          child: Text(
                            '${tx.category} • ${tx.paymentMethod}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceBadge(context, tx.source),
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
                  color: isExpense
                      ? AppTheme.accentRose
                      : (AppTheme.isDark(context)
                          ? AppTheme.accentEmerald
                          : AppTheme.accentEmeraldText),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppTheme.textSecondaryOf(context),
                ),
                tooltip: 'Aksi transaksi',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    ManualTransactionBottomSheet.show(
                      context,
                      initialTransaction: tx,
                    );
                  } else if (action == 'delete') {
                    _confirmDelete(context, tx).then((confirmed) {
                      if (confirmed != true || !context.mounted) return;
                      _deleteTransaction(context, ref, tx);
                    });
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'edit',
                    height: 44,
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    height: 44,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, TransactionModel tx) {
    return showDialog<bool>(
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
            child: Text(
              'Batal',
              style: TextStyle(color: AppTheme.textSecondaryOf(context)),
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
    );
  }

  void _deleteTransaction(BuildContext context, WidgetRef ref, TransactionModel tx) {
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

  Widget _buildSourceBadge(
    BuildContext context,
    TransactionSource source,
  ) {
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.trackOf(context),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondaryOf(context)),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryOf(context),
            ),
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
          color: AppTheme.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimaryOf(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.pie_chart_rounded,
                color: AppTheme.accentPrimaryOf(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan Eksekutif & Analisis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Komposisi pengeluaran & rekomendasi AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textSecondaryOf(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: AppTheme.textSecondaryOf(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi tercatat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dikte lewat bar asisten di bawah, unggah foto struk, atau gunakan input manual.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(transactionProvider.notifier).loadSampleData();
              ref.read(wishlistProvider.notifier).loadSampleData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Contoh data dimuat. Semua data contoh dapat dihapus kapan saja.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_stories_outlined, size: 18),
            label: const Text('Coba Contoh Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentPrimaryOf(context),
              side: BorderSide(color: AppTheme.accentPrimaryOf(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            'Memuat data portofolio...',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
