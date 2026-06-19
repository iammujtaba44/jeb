import 'dart:io';

import 'package:intl/intl.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Generates and shares CSV / PDF exports of a set of transactions.
class ExportService {
  const ExportService();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final NumberFormat _decimal = NumberFormat('#,##0.00');

  /// Glyph-safe money string for the PDF (built-in PDF fonts can't render most
  /// currency symbols), e.g. "1,500.00 EUR".
  static String _money(double amount, String code) =>
      '${_decimal.format(amount)} $code';

  /// Builds a CSV file and opens the share sheet.
  Future<void> shareCsv({
    required List<Transaction> transactions,
    required Map<String, Category> categoriesById,
    required String label,
  }) async {
    final StringBuffer csv = StringBuffer()
      ..writeln('Date,Type,Category,Amount,Currency,Note');
    for (final Transaction t in transactions) {
      final String category =
          categoriesById[t.categoryId]?.name ?? 'Uncategorized';
      csv.writeln(<String>[
        _isoDate.format(t.date),
        t.type.name,
        _csv(category),
        t.amount.toStringAsFixed(2),
        t.currencyCode,
        _csv(t.note ?? ''),
      ].join(','));
    }

    final Directory dir = await getTemporaryDirectory();
    final File file = File(p.join(dir.path, 'jeb-$label.csv'));
    await file.writeAsString(csv.toString());

    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'text/csv', name: 'jeb-$label.csv')],
      subject: 'Jeb transactions — $label',
    );
  }

  /// Builds a PDF statement and opens the share sheet.
  Future<void> sharePdf({
    required List<Transaction> transactions,
    required Map<String, Category> categoriesById,
    required String currency,
    required String label,
  }) async {
    double income = 0;
    double expense = 0;
    for (final Transaction t in transactions) {
      final double inHome = CurrencyConverter.convert(
        amount: t.amount,
        from: t.currencyCode,
        to: currency,
      );
      if (t.type == TransactionType.income) {
        income += inHome;
      } else {
        expense += inHome;
      }
    }

    final pw.Document doc = pw.Document();
    final String generated = _isoDate.format(DateTime.now());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'Jeb Transactions',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '$label  -  generated $generated',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              _summary('Income', _money(income, currency), PdfColors.green800),
              _summary('Expense', _money(expense, currency), PdfColors.red800),
              _summary('Net', _money(income - expense, currency),
                  PdfColors.blueGrey800),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: <String>['Date', 'Type', 'Category', 'Amount', 'Note'],
            border: null,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 22,
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            columnWidths: <int, pw.TableColumnWidth>{
              0: const pw.FixedColumnWidth(60),
              1: const pw.FixedColumnWidth(48),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(90),
              4: const pw.FlexColumnWidth(2.4),
            },
            cellAlignments: <int, pw.Alignment>{
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerLeft,
            },
            data: <List<String>>[
              for (final Transaction t in transactions)
                <String>[
                  _isoDate.format(t.date),
                  t.type.name,
                  categoriesById[t.categoryId]?.name ?? 'Uncategorized',
                  '${t.type == TransactionType.expense ? '-' : '+'}'
                      '${_money(t.amount, t.currencyCode)}',
                  t.note ?? '',
                ],
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'jeb-$label.pdf');
  }

  static pw.Widget _summary(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  /// Escapes a CSV field if it contains a delimiter, quote, or newline.
  static String _csv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
