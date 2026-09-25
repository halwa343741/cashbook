import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/book/domain/models/book_model.dart';
import '../../features/category/domain/models/category_model.dart';
import '../../features/transaction/domain/models/transaction_model.dart';
import '../database/local_storage_service.dart';
import '../utils/date_formatter.dart';

class ExcelExportService {
  static Future<File> generateReportExcel({
    required BookModel book,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    String periodTitle = 'Laporan Keuangan',
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Transaksi'];
    excel.delete('Sheet1');

    final catMap = {for (var c in categories) c.id: c.name};

    // Header Info
    sheet.appendRow([TextCellValue('CASHBOOK - LAPORAN KEUANGAN')]);
    sheet.appendRow([TextCellValue('Buku Kas: ${book.name}')]);
    sheet.appendRow([TextCellValue('Periode: $periodTitle')]);
    sheet.appendRow([TextCellValue('Total Pemasukan: Rp $totalIncome')]);
    sheet.appendRow([TextCellValue('Total Pengeluaran: Rp $totalExpense')]);
    sheet.appendRow([TextCellValue('Selisih Bersih: Rp $netBalance')]);
    sheet.appendRow([TextCellValue('')]); // empty row

    // Table Headers
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Tanggal'),
      TextCellValue('Tipe'),
      TextCellValue('Deskripsi'),
      TextCellValue('Keterangan'),
      TextCellValue('Nominal (Rp)'),
      TextCellValue('Catatan'),
    ]);

    // Rows
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(DateFormatter.format(t.date)),
        TextCellValue(t.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran'),
        TextCellValue(catMap[t.categoryId] ?? 'Lainnya'),
        TextCellValue(t.title),
        DoubleCellValue(t.amount),
        TextCellValue(t.note.isNotEmpty ? t.note : '-'),
      ]);
    }

    final bytes = excel.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${book.name.replaceAll(' ', '_')}_report.xlsx');
    await file.writeAsBytes(bytes!);

    return file;
  }

  static Future<void> shareExcelFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path,
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
        ],
        subject: 'Laporan Keuangan Cashbook',
      ),
    );
  }

  Future<void> exportReportExcel({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required String bookTitle,
  }) async {
    double income = 0;
    double expense = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final file = await generateReportExcel(
      book: BookModel(
        id: 'export',
        name: bookTitle,
        icon: 'wallet',
        colorValue: 0xFF15803D,
        createdAt: DateTime.now(),
      ),
      transactions: transactions,
      categories: LocalStorageService.instance.getCategories(),
      totalIncome: income,
      totalExpense: expense,
      netBalance: income - expense,
      periodTitle: '${DateFormatter.format(startDate)} - ${DateFormatter.format(endDate)}',
    );
    await shareExcelFile(file);
  }
}
