import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/transactions/data/transaction_provider.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

class ManualTransactionBottomSheet extends ConsumerStatefulWidget {
  final TransactionModel? initialTransaction;

  const ManualTransactionBottomSheet({
    super.key,
    this.initialTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionModel? initialTransaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualTransactionBottomSheet(
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  ConsumerState<ManualTransactionBottomSheet> createState() =>
      _ManualTransactionBottomSheetState();
}

class _ManualTransactionBottomSheetState
    extends ConsumerState<ManualTransactionBottomSheet> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Makanan & Minuman';
  String _selectedPaymentMethod = 'QRIS';
  DateTime _selectedDate = DateTime.now();

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

  final List<String> _expenseCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja Pribadi',
    'Tagihan & Utilitas',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
  ];

  final List<String> _incomeCategories = [
    'Gaji & Upah',
    'Freelance',
    'Investasi',
    'Hadiah / Transfer',
    'Lainnya',
  ];

  final List<String> _paymentMethods = [
    'QRIS',
    'Tunai',
    'BCA Debit',
    'Mandiri Debit',
    'Kartu Kredit',
    'GoPay / OVO',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    if (initial != null) {
      _amountController.text = initial.amount.toInt().toString();
      _titleController.text = initial.title;
      _selectedType = initial.type;
      _selectedCategory = initial.category;
      _selectedPaymentMethod = initial.paymentMethod;
      _selectedDate = initial.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final rawAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal harus diisi dengan angka yang valid.'),
          backgroundColor: AppTheme.accentRose,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? (_selectedType == TransactionType.expense
            ? 'Pengeluaran $_selectedCategory'
            : 'Pemasukan $_selectedCategory')
        : _titleController.text.trim();

    final initial = widget.initialTransaction;
    if (initial != null) {
      final updated = initial.copyWith(
        title: title,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        date: _selectedDate,
      );
      ref.read(transactionProvider.notifier).updateTransaction(updated);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perubahan transaksi "$title" berhasil disimpan!'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
    } else {
      final tx = TransactionModel(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        date: _selectedDate,
        source: TransactionSource.text,
      );

      ref.read(transactionProvider.notifier).addTransaction(tx);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi "$title" berhasil dicatat!'),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = _selectedType == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppTheme.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.trackOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.accentPrimaryOf(context),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.initialTransaction != null
                          ? 'Edit Transaksi'
                          : 'Input Transaksi Manual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Button: Pengeluaran vs Pemasukan
            Container(
              decoration: BoxDecoration(
                color: AppTheme.trackOf(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeSegment(
                      title: 'Pengeluaran',
                      type: TransactionType.expense,
                      activeColor: AppTheme.accentRose,
                    ),
                  ),
                  Expanded(
                    child: _buildTypeSegment(
                      title: 'Pemasukan',
                      type: TransactionType.income,
                      activeColor: AppTheme.accentEmeraldText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nominal Input (Besar & Jelas)
            Text(
              'Nominal (Rp)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.fillOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryOf(context),
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  hintText: '0',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Judul / Keterangan (Opsional)
            Text(
              'Catatan / Nama Transaksi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.fillOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimaryOf(context)),
                decoration: InputDecoration(
                  hintText: 'Contoh: Nasi Padang, Bensin, Gaji Pokok',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal Transaksi
            Text(
              'Tanggal Transaksi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.fillOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderOf(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day} ${_monthLabels[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 16,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori (Horizontal Chips)
            Text(
              'Kategori',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
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
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Metode Pembayaran (Horizontal Chips)
            Text(
              'Metode Pembayaran / Sumber Dana',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedPaymentMethod = method),
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
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saveTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimaryOf(context),
                  foregroundColor: AppTheme.onAccentPrimaryOf(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.initialTransaction != null
                      ? 'Simpan Perubahan'
                      : 'Simpan Transaksi Langsung',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String title,
    required TransactionType type,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategory = type == TransactionType.expense
              ? _expenseCategories.first
              : _incomeCategories.first;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? AppTheme.onAccentPrimaryOf(context)
                  : AppTheme.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}
