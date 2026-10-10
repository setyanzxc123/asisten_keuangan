import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/core/utils/currency_formatter.dart';
import 'package:asisten_keuangan/features/wishlist/domain/wishlist_model.dart';
import 'package:asisten_keuangan/features/wishlist/data/wishlist_provider.dart';
import 'package:asisten_keuangan/features/reports/data/monthly_ai_analysis_provider.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';

class WishlistSectionWidget extends ConsumerWidget {
  const WishlistSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TARGET IMPIAN & WISHLIST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddWishlistBottomSheet(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryNavy,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (wishlistState.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'Belum ada target wishlist. Ketuk "+ Tambah" untuk memulai.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...wishlistState.items.map((item) => _buildWishlistCard(context, ref, item)),
      ],
    );
  }

  Widget _buildWishlistCard(
    BuildContext context,
    WidgetRef ref,
    WishlistModel item,
  ) {
    final progress = item.progressRatio;
    final isDone = item.isAchieved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppTheme.accentEmerald : const Color(0xFFE2E8F0),
          width: isDone ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(wishlistProvider.notifier).toggleAchieved(item.id);
                  ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isDone ? AppTheme.accentEmerald : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terkumpul: ${CurrencyFormatter.format(item.savedAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentEmeraldText,
                ),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(item.targetAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppTheme.accentEmerald : AppTheme.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone
                    ? 'Target Tercapai!'
                    : 'Sisa: ${CurrencyFormatter.format(item.remainingAmount)} (${item.progressPercentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppTheme.accentEmeraldText : AppTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  if (!isDone)
                    TextButton.icon(
                      onPressed: () => _showAllocateBottomSheet(context, ref, item),
                      icon: const Icon(Icons.savings_outlined, size: 14),
                      label: const Text(
                        'Alokasikan',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _confirmDeleteWishlist(context, ref, item),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'Hapus Target',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWishlist(
    BuildContext context,
    WidgetRef ref,
    WishlistModel item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target Tabungan?'),
        content: Text(
          'Target "${item.title}" dan riwayat tabungannya akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(wishlistProvider.notifier).deleteWishlistItem(item.id);
              ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Target "${item.title}" dihapus'),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Urungkan',
                    onPressed: () {
                      ref.read(wishlistProvider.notifier).addWishlistItem(
                            title: item.title,
                            targetAmount: item.targetAmount,
                            savedAmount: item.savedAmount,
                            targetDate: item.targetDate,
                          );
                      ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
                    },
                  ),
                ),
              );
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppTheme.accentRose, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWishlistBottomSheet(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final savedController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Target Wishlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Nama Barang / Impian',
                    hintText: 'Contoh: MacBook Pro M3',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama target tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Nominal (Rp)',
                    hintText: 'Contoh: 20000000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    final num = double.tryParse(val?.trim() ?? '');
                    if (num == null || num <= 0) {
                      return 'Nominal target harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: savedController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Dana Tersimpan Awal (Opsional)',
                    hintText: 'Contoh: 5000000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final title = titleController.text.trim();
                      final target = double.tryParse(amountController.text.trim()) ?? 0;
                      final saved = double.tryParse(savedController.text.trim()) ?? 0;

                      ref.read(wishlistProvider.notifier).addWishlistItem(
                            title: title,
                            targetAmount: target,
                            savedAmount: saved,
                          );
                      ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Target',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllocateBottomSheet(
    BuildContext context,
    WidgetRef ref,
    WishlistModel item,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final txState = ref.read(transactionProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tabung ke "${item.title}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sisa target yang dibutuhkan: ${CurrencyFormatter.format(item.remainingAmount)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sisa Anggaran Bulan Ini:',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(txState.remainingBudget),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: txState.remainingBudget >= 0
                              ? AppTheme.accentEmeraldText
                              : AppTheme.accentRose,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nominal yang Ditabung (Rp)',
                    hintText: 'Contoh: 500000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    final num = double.tryParse(val?.trim() ?? '');
                    if (num == null || num <= 0) {
                      return 'Nominal yang ditabung harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final add = double.tryParse(amountController.text.trim()) ?? 0;

                      ref.read(wishlistProvider.notifier).allocateSavings(
                            itemId: item.id,
                            additionalAmount: add,
                          );
                      ref.read(monthlyAiAnalysisProvider.notifier).generateAnalysis();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tambahkan Tabungan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
