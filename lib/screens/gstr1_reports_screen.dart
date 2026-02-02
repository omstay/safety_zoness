import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../model/SaleMaster.dart';
import '../screens/inventory_management.dart';

class PDFUtils {
  static Future<Uint8List> generateSalePdf(SaleMaster sale) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Fetch business details from Firebase
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final userId = _auth.currentUser?.uid ?? sale.userId;

    // Get business profile
    Map<String, dynamic>? businessProfile;
    Map<String, dynamic>? businessSettings;

    try {
      final businessDoc = await _firestore.collection('business_profiles').doc(userId).get();
      if (businessDoc.exists) {
        businessProfile = businessDoc.data();
      }

      final settingsDoc = await _firestore.collection('business_settings').doc(userId).get();
      if (settingsDoc.exists) {
        businessSettings = settingsDoc.data();
      }
    } catch (e) {
      print('Error fetching business details: $e');
    }

    // Extract business details with fallbacks
    final businessName = businessProfile?['businessName'] ?? businessSettings?['companyName'] ?? 'Your Business Name';
    final address = businessProfile?['address'] ?? businessSettings?['address'] ?? '';
    final city = businessSettings?['city'] ?? '';
    final state = businessSettings?['state'] ?? '';
    final pincode = businessSettings?['pincode'] ?? '';
    final gstin = businessProfile?['gstin'] ?? businessSettings?['gstin'] ?? '';
    final phone = businessProfile?['phone'] ?? businessSettings?['phone'] ?? '';
    final email = businessProfile?['email'] ?? businessSettings?['email'] ?? '';

    // Bank details
    final bankDetails = businessSettings?['bankDetails'] as Map<String, dynamic>?;
    final bankName = bankDetails?['bankName'] ?? '';
    final accountNumber = bankDetails?['accountNumber'] ?? '';
    final ifscCode = bankDetails?['ifscCode'] ?? '';
    final accountHolderName = bankDetails?['accountHolderName'] ?? '';

    // Format address
    String fullAddress = address;
    if (city.isNotEmpty) fullAddress += fullAddress.isEmpty ? city : ', $city';
    if (state.isNotEmpty) fullAddress += fullAddress.isEmpty ? state : ', $state';
    if (pincode.isNotEmpty) fullAddress += fullAddress.isEmpty ? ' - $pincode' : ' - $pincode';

    // Calculate totals
    double totalTaxableValue = sale.items.fold(0, (sum, item) => sum + item.totalTaxableValue);
    double totalCGST = sale.items.fold(0, (sum, item) => sum + item.centralTaxAmount);
    double totalSGST = sale.items.fold(0, (sum, item) => sum + item.stateTaxAmount);
    double totalIGST = sale.items.fold(0, (sum, item) => sum + item.integratedTaxAmount);
    double totalCess = sale.items.fold(0, (sum, item) => sum + item.cessAmount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Business Header with Logo placeholder
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Business Details
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          businessName.toUpperCase(),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'GSTIN: $gstin',
                          style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          phone,
                          style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          email,
                          style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  // Right: Logo and Generated By
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 90,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text('LOGO', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated by Safety Zoness App',
                        style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Invoice Details Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  children: [
                    // Left Column - Invoice Details
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRowPDF('Invoice #', sale.invoice, ttf),
                          _buildDetailRowPDF('Invoice Date', DateFormat('dd/MM/yyyy').format(sale.date), ttf),
                          _buildDetailRowPDF('Terms', 'Net 30', ttf),
                        ],
                      ),
                    ),
                    // Right Column - Place of Supply
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRowPDF('Place of Supply', sale.placeOfSupply, ttf),
                          _buildDetailRowPDF('Payment Type', sale.saleType, ttf),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Bill To Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Bill To',
                        style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      sale.customerName,
                      style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    if (sale.recipientGSTIN.isNotEmpty)
                      pw.Text(
                        'GSTIN: ${sale.recipientGSTIN}',
                        style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Text(
                'Items',
                style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(25),
                    1: const pw.FixedColumnWidth(40),
                    2: const pw.FlexColumnWidth(2.5),
                    3: const pw.FixedColumnWidth(30),
                    4: const pw.FixedColumnWidth(30),
                    5: const pw.FixedColumnWidth(50),
                    6: const pw.FixedColumnWidth(35),
                    7: const pw.FixedColumnWidth(40),
                    8: const pw.FixedColumnWidth(40),
                    9: const pw.FixedColumnWidth(40),
                    10: const pw.FixedColumnWidth(35),
                    11: const pw.FixedColumnWidth(50),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                      ),
                      children: [
                        _buildTableHeaderPDF('Sr\nNo.', ttf),
                        _buildTableHeaderPDF('HSN', ttf),
                        _buildTableHeaderPDF('Description', ttf),
                        _buildTableHeaderPDF('UQC', ttf),
                        _buildTableHeaderPDF('Qty', ttf),
                        _buildTableHeaderPDF('Taxable\nValue (₹)', ttf),
                        _buildTableHeaderPDF('Rate\n(%)', ttf),
                        _buildTableHeaderPDF('IGST\n(₹)', ttf),
                        _buildTableHeaderPDF('CGST\n(₹)', ttf),
                        _buildTableHeaderPDF('SGST\n(₹)', ttf),
                        _buildTableHeaderPDF('Cess\n(₹)', ttf),
                        _buildTableHeaderPDF('Total\n(₹)', ttf),
                      ],
                    ),
                    // Data Rows
                    ...List<pw.TableRow>.generate(sale.items.length, (index) {
                      final item = sale.items[index];
                      final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
                      return pw.TableRow(
                        children: [
                          _buildTableCellPDF((index + 1).toString(), ttf),
                          _buildTableCellPDF(item.hsnSacCode, ttf),
                          _buildTableCellPDF(item.description, ttf),
                          _buildTableCellPDF(item.unitOfMeasurement, ttf),
                          _buildTableCellPDF(item.quantity.toStringAsFixed(1), ttf),
                          _buildTableCellPDF(item.totalTaxableValue.toStringAsFixed(2), ttf, align: pw.TextAlign.right),
                          _buildTableCellPDF('${totalTaxRate.toStringAsFixed(1)}%', ttf),
                          _buildTableCellPDF(item.integratedTaxAmount.toStringAsFixed(2), ttf, align: pw.TextAlign.right),
                          _buildTableCellPDF(item.centralTaxAmount.toStringAsFixed(2), ttf, align: pw.TextAlign.right),
                          _buildTableCellPDF(item.stateTaxAmount.toStringAsFixed(2), ttf, align: pw.TextAlign.right),
                          _buildTableCellPDF(item.cessAmount.toStringAsFixed(2), ttf, align: pw.TextAlign.right),
                          _buildTableCellPDF(item.itemTotal.toStringAsFixed(2), ttf, align: pw.TextAlign.right, bold: true),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Total Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRowPDF('Sub Total:', totalTaxableValue, ttf),
                    if (sale.supplyType == 'INTRA') ...[
                      _buildTotalRowPDF('CGST:', totalCGST, ttf, isSubtotal: true),
                      _buildTotalRowPDF('SGST:', totalSGST, ttf, isSubtotal: true),
                    ] else ...[
                      _buildTotalRowPDF('IGST:', totalIGST, ttf, isSubtotal: true),
                    ],
                    pw.Divider(color: PdfColors.grey400),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total:', style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '₹${sale.total.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Bank Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Bank Details',
                        style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (bankName.isNotEmpty) pw.Text('Bank: $bankName', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    if (accountNumber.isNotEmpty) pw.Text('A/C No: $accountNumber', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    if (ifscCode.isNotEmpty) pw.Text('IFSC: $ifscCode', style: pw.TextStyle(font: ttf, fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'THANKS FOR YOUR BUSINESS.',
                      style: pw.TextStyle(font: ttf, fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signature', style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // Helper methods
  static pw.Widget _buildDetailRowPDF(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.normal),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderPDF(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCellPDF(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRowPDF(String label, double value, pw.Font font, {bool isSubtotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: isSubtotal ? 11 : 12,
              color: isSubtotal ? PdfColors.grey700 : PdfColors.black,
            ),
          ),
          pw.Text(
            '₹${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              font: font,
              fontSize: isSubtotal ? 11 : 12,
              color: isSubtotal ? PdfColors.grey700 : PdfColors.black,
              fontWeight: isSubtotal ? pw.FontWeight.normal : pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Keep all existing methods (generateAndDownloadPDF, shareSalePDF, printSalePDF, etc.)
  static Future<void> generateAndDownloadPDF(SaleMaster sale) async {
    try {
      final pdfBytes = await generateSalePdf(sale);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/invoice_${sale.invoice}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving PDF: $e');
      }
    }
  }

  static Future<void> shareSalePDF(SaleMaster sale) async {
    try {
      final pdfBytes = await generateSalePdf(sale);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/invoice_${sale.invoice}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your invoice for sale ${sale.invoice}');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing PDF: $e');
      }
    }
  }

  static Future<void> printSalePDF(SaleMaster sale) async {
    try {
      final pdfBytes = await generateSalePdf(sale);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing PDF: $e');
      }
    }
  }

  // GSTR-1 Generation Methods
  static Future<void> generateGSTR1JSON(
      List<Map<String, dynamic>> sales,
      DateTime fromDate,
      DateTime toDate,
      ) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/GSTR1_${DateFormat('MMyyyy').format(fromDate)}.json");

      // Create GST-compliant JSON structure
      Map<String, dynamic> gstJson = {
        'gstin': 'YOUR_GSTIN_HERE',
        'ret_period': DateFormat('MMyyyy').format(fromDate),
        'b2b': [],
        'b2cl': [],
        'b2cs': [],
        'exp': [],
        'summary': {
          'total_invoices': sales.length,
          'total_taxable_value': 0.0,
          'total_igst': 0.0,
          'total_cgst': 0.0,
          'total_sgst': 0.0,
        }
      };

      // Process sales and group by category
      for (var sale in sales) {
        final gstr1Section = sale['gstr1Section'] ?? 'B2C_SMALL';

        if (gstr1Section == 'B2B') {
          // Add to B2B section
          gstJson['b2b'].add({
            'ctin': sale['recipientGSTIN'] ?? '',
            'inv': [{
              'inum': sale['invoice'],
              'idt': DateFormat('dd-MM-yyyy').format((sale['date'] as Timestamp).toDate()),
              'val': sale['total'],
              'pos': sale['placeOfSupply'],
              'rchrg': 'N',
            }]
          });
        }
      }

      await file.writeAsString(jsonEncode(gstJson));
      if (kDebugMode) {
        print('GSTR-1 JSON saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating GSTR-1 JSON: $e');
      }
    }
  }

  static Future<void> generateGSTR1PDF(
      List<Map<String, dynamic>> sales,
      DateTime fromDate,
      DateTime toDate,
      ) async {
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      // Group sales by section
      final b2bSales = sales.where((s) => s['gstr1Section'] == 'B2B').toList();
      final b2cLargeSales = sales.where((s) => s['gstr1Section'] == 'B2C_LARGE').toList();
      final b2cSmallSales = sales.where((s) => s['gstr1Section'] == 'B2C_SMALL').toList();
      final exportSales = sales.where((s) => s['gstr1Section'] == 'EXPORT').toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('GSTR-1 Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Period: ${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(children: [
                        pw.Text('B2B', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('${b2bSales.length}', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.Column(children: [
                        pw.Text('B2C Large', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('${b2cLargeSales.length}', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.Column(children: [
                        pw.Text('B2C Small', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('${b2cSmallSales.length}', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.Column(children: [
                        pw.Text('Exports', style: pw.TextStyle(font: ttf, fontSize: 10)),
                        pw.Text('${exportSales.length}', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // B2B Section
            if (b2bSales.isNotEmpty) ...[
              pw.Text('B2B Supplies', style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Invoice', 'Date', 'Customer', 'GSTIN', 'Amount'],
                data: b2bSales.map((s) => [
                  s['invoice'],
                  DateFormat('dd/MM/yy').format((s['date'] as Timestamp).toDate()),
                  s['customerName'],
                  s['recipientGSTIN'] ?? 'N/A',
                  '₹${s['total'].toStringAsFixed(2)}',
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              ),
              pw.SizedBox(height: 20),
            ],
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/GSTR1_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);

      if (kDebugMode) {
        print('GSTR-1 PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating GSTR-1 PDF: $e');
      }
    }
  }

  static Future<void> generateGSTR1Excel(
      List<Map<String, dynamic>> sales,
      DateTime fromDate,
      DateTime toDate,
      ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['GSTR-1 Report'];

      // Headers
      sheet.appendRow([
        TextCellValue('Invoice'),
        TextCellValue('Date'),
        TextCellValue('Customer'),
        TextCellValue('GSTIN'),
        TextCellValue('Type'),
        TextCellValue('Amount'),
      ]);

      // Data
      for (var sale in sales) {
        sheet.appendRow([
          TextCellValue(sale['invoice'] ?? ''),
          TextCellValue(DateFormat('dd/MM/yyyy').format((sale['date'] as Timestamp).toDate())),
          TextCellValue(sale['customerName'] ?? ''),
          TextCellValue(sale['recipientGSTIN'] ?? 'N/A'),
          TextCellValue(sale['gstr1Section'] ?? 'B2C_SMALL'),
          TextCellValue('₹${sale['total']}'),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/GSTR1_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
      final file = File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      if (kDebugMode) {
        print('GSTR-1 Excel saved to: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating GSTR-1 Excel: $e');
      }
    }
  }

  // Stock Summary Report Methods
  static Future<Uint8List> generateAllStockPdf(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Create a map for quick item lookup
    final Map<String, ItemMaster> itemMap = {for (var item in allItems) item.id: item};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Stock Summary Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Item', 'Location', 'Current Stock', 'Min Level', 'Status'],
              data: stocks.map((stock) {
                final item = itemMap[stock.itemId];
                final itemName = item?.description ?? 'Unknown Item';
                final status = stock.currentStock <= stock.minimumStockLevel ? 'Low Stock' : 'Good';
                return [
                  itemName,
                  stock.location,
                  stock.currentStock.toStringAsFixed(1),
                  stock.minimumStockLevel.toStringAsFixed(1),
                  status,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  static Future<void> generateAndDownloadAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/stock_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('Stock Report PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating stock report: $e');
      }
    }
  }

  static Future<void> shareAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/stock_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Stock Summary Report');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing stock report: $e');
      }
    }
  }

  static Future<void> printAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing stock report: $e');
      }
    }
  }
}