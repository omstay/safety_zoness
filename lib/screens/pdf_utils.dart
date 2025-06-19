import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../model/SaleMaster.dart';

class PDFUtils {
  // Generate PDF Document
  static Future<pw.Document> _buildPDF(SaleMaster sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sales Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Customer: ${sale.customerName}'),
                pw.Text('Phone: ${sale.phone}'),
                pw.Text('Invoice #: ${sale.invoice}'),
                pw.Text('Date: ${sale.date}'),
                pw.Text('Type: ${sale.type}'),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Total: ₹${sale.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// 📥 Download PDF to device
  static Future<void> generateAndDownloadPDF(SaleMaster sale) async {
    final pdf = await _buildPDF(sale);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sale_invoice_${sale.invoice}.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  /// 📤 Share PDF file
  static Future<void> shareSalePDF(SaleMaster sale) async {
    final pdf = await _buildPDF(sale);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sale_invoice_${sale.invoice}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Sales Invoice - ${sale.customerName}');
  }

  /// 🖨️ Print the PDF directly
  static Future<void> printSalePDF(SaleMaster sale) async {
    final pdf = await _buildPDF(sale);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
