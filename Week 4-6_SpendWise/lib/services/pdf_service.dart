import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> exportAndShare({
    required String userName,
    required List<Map<String, dynamic>> expenses,
    required double cashIn,
    required double cashOut,
    required double balance,
  }) async {
    final pdf = pw.Document();

    final sorted = List<Map<String, dynamic>>.from(expenses);
    sorted.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    double running = 0;
    final rows = <List<String>>[];
    for (final e in sorted) {
      final isCashIn = e['type'] == 'cash_in';
      final amount = e['amount'] as double;
      running += isCashIn ? amount : -amount;
      rows.add([
        DateFormat('dd MMM yyyy').format(DateTime.parse(e['date'] as String)),
        e['description'] as String,
        (e['contactName'] as String?)?.isNotEmpty == true ? e['contactName'] as String : '-',
        e['category'] as String,
        e['paymentMode'] as String,
        isCashIn ? 'Rs. ${amount.toStringAsFixed(0)}' : '-',
        !isCashIn ? 'Rs. ${amount.toStringAsFixed(0)}' : '-',
        'Rs. ${running.toStringAsFixed(0)}',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('$userName\'s Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('Total Cash In', cashIn, PdfColors.green700),
              _summaryBox('Total Cash Out', cashOut, PdfColors.red700),
              _summaryBox('Net Balance', balance, PdfColors.indigo700),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Total entries: ${rows.length}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Contact', 'Category', 'Mode', 'Cash In', 'Cash Out', 'Balance'],
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${userName.replaceAll(' ', '_')}_report.pdf');
  }

  static pw.Widget _summaryBox(String label, double amount, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text('Rs. ${amount.toStringAsFixed(0)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}