import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/book/domain/models/book_model.dart';
import '../../features/category/domain/models/category_model.dart';
import '../../features/transaction/domain/models/transaction_model.dart';
import '../database/local_storage_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class PdfExportService {
  static Future<Uint8List> generateReportPdf({
    required BookModel book,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    String periodTitle = 'Laporan Keuangan',
  }) async {
    final pdf = pw.Document();

    final catMap = {for (var c in categories) c.id: c.name};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CASHBOOK',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    'Buku: ${book.name}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Periode: $periodTitle', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Dicetak: ${DateFormatter.formatWithTime(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 16),

          // Summary Boxes
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Pemasukan', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyFormatter.format(totalIncome),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.red200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Pengeluaran', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyFormatter.format(totalExpense),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Selisih Bersih', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyFormatter.format(netBalance),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Transaction Table
          pw.Text('Rincian Transaksi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Keterangan', 'Deskripsi', 'Tipe', 'Nominal'],
            data: transactions.map((t) {
              final isIncome = t.type == TransactionType.income;
              return [
                DateFormatter.format(t.date),
                t.title,
                catMap[t.categoryId] ?? 'Lainnya',
                isIncome ? 'Pemasukan' : 'Pengeluaran',
                CurrencyFormatter.format(t.amount, showSign: true, isExpense: !isIncome),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),

          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Dikeluarkan oleh Cashbook Mobile App', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrSharePdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }

  Future<void> exportReportPdf({
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
    final bytes = await generateReportPdf(
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
    await printOrSharePdf(pdfBytes: bytes, fileName: 'Laporan_$bookTitle');
  }
}
