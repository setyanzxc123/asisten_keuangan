import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:asisten_keuangan/features/transactions/domain/transaction_model.dart';

class CsvExportService {
  const CsvExportService();

  String generateCsv(List<TransactionModel> transactions) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final rows = <List<dynamic>>[
      [
        'ID Transaksi',
        'Tanggal',
        'Judul',
        'Tipe',
        'Kategori',
        'Metode Pembayaran',
        'Nominal',
        'Sumber Input',
        'Catatan',
      ],
      ...transactions.map((t) => [
            t.id,
            dateFormat.format(t.date),
            t.title,
            t.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran',
            t.category,
            t.paymentMethod,
            t.amount,
            t.source.name,
            t.notes ?? '',
          ]),
    ];

    return csv.encode(rows);
  }
}
