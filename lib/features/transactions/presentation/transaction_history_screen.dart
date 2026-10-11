import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';
import 'package:asisten_keuangan/features/transactions/presentation/manual_transaction_bottom_sheet.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _query = '';
  String? _selectedMonth;

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(String key) {
    final parts = key.split('-');
    final monthIndex = int.parse(parts[1]) - 1;
    return '${_monthLabels[monthIndex]} ${parts[0]}';
  }

  void _deleteTransaction(TransactionModel tx) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);

    final monthKeys = txState.transactions
        .map((t) => _monthKey(t.date))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final filtered = txState.transactions.where((t) {
      final matchesQuery = _query.isEmpty ||
          t.title.toLowerCase().contains(_query.toLowerCase()) ||
          t.category.toLowerCase().contains(_query.toLowerCase());
      final matchesMonth = _selectedMonth == null ||
          _monthKey(t.date) == _selectedMonth;
      return matchesQuery && matchesMonth;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RIWAYAT LENGKAP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              'Semua Transaksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau kategori...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.borderOf(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppTheme.borderOf(context)),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (monthKeys.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('Semua'),
                          selected: _selectedMonth == null,
                          onSelected: (_) =>
                              setState(() => _selectedMonth = null),
                          selectedColor: AppTheme.accentPrimaryOf(context),
                          backgroundColor: AppTheme.cardOf(context),
                          side: BorderSide(color: AppTheme.borderOf(context)),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedMonth == null
                                ? AppTheme.onAccentPrimaryOf(context)
                                : AppTheme.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      ...monthKeys.map((key) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_monthLabel(key)),
                              selected: _selectedMonth == key,
                              onSelected: (_) =>
                                  setState(() => _selectedMonth = key),
                              selectedColor:
                                  AppTheme.accentPrimaryOf(context),
                              backgroundColor: AppTheme.cardOf(context),
                              side:
                                  BorderSide(color: AppTheme.borderOf(context)),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedMonth == key
                                    ? AppTheme.onAccentPrimaryOf(context)
                                    : AppTheme.textPrimaryOf(context),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              Divider(height: 1, color: AppTheme.borderOf(context)),
              Expanded(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Tidak ada transaksi yang cocok dengan pencarian atau filter bulan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          return _buildHistoryRow(context, ref, tx);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    final isExpense = tx.type == TransactionType.expense;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.date.day} ${_monthLabels[tx.date.month - 1]} ${tx.date.year} • ${tx.category} • ${tx.paymentMethod}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(tx.amount)}',
            style: TextStyle(
              fontSize: 13,
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
                _deleteTransaction(tx);
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
    );
  }
}
