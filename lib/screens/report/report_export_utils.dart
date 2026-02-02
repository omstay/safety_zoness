import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart' as xml;

class ReportExportUtils {
  // ==================== HSN SALES REPORT ====================

  static Future<void> exportHsnSalesPDF(
      Map<String, Map<String, dynamic>> hsnData,
      String filterPeriod,
      String businessName,
      ) async {
    final pdf = pw.Document();

    // Calculate totals
    double grandTotal = 0;
    double totalTaxable = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalCess = 0;

    final sortedHsns = hsnData.entries.toList()
      ..sort((a, b) => b.value['totalValue'].compareTo(a.value['totalValue']));

    for (var entry in sortedHsns) {
      grandTotal += entry.value['totalValue'];
      totalTaxable += entry.value['taxableValue'];
      totalCgst += entry.value['cgst'];
      totalSgst += entry.value['sgst'];
      totalIgst += entry.value['igst'];
      totalCess += entry.value['cess'];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Sales by HSN/SAC Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Period: $filterPeriod'),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
            ],
          ),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Sales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('₹${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Taxable Value:'),
                    pw.Text('₹${totalTaxable.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST:'),
                    pw.Text('₹${totalCgst.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST:'),
                    pw.Text('₹${totalSgst.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IGST:'),
                    pw.Text('₹${totalIgst.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cess:'),
                    pw.Text('₹${totalCess.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // HSN Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('HSN/SAC', isHeader: true),
                  _buildTableCell('Qty', isHeader: true),
                  _buildTableCell('GST %', isHeader: true),
                  _buildTableCell('Taxable', isHeader: true),
                  _buildTableCell('Total', isHeader: true),
                ],
              ),
              // Data Rows
              ...sortedHsns.map((entry) {
                final hsn = entry.key;
                final data = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell(hsn.isEmpty ? 'N/A' : hsn),
                    _buildTableCell(data['quantity'].toStringAsFixed(1)),
                    _buildTableCell(data['gstRate'].toStringAsFixed(1)),
                    _buildTableCell('₹${data['taxableValue'].toStringAsFixed(2)}'),
                    _buildTableCell('₹${data['totalValue'].toStringAsFixed(2)}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'HSN_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> exportHsnSalesXML(
      Map<String, Map<String, dynamic>> hsnData,
      String filterPeriod,
      String businessName,
      ) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('HsnSalesReport', nest: () {
      builder.element('BusinessName', nest: businessName);
      builder.element('ReportType', nest: 'Sales by HSN/SAC');
      builder.element('Period', nest: filterPeriod);
      builder.element('GeneratedOn', nest: DateTime.now().toIso8601String());

      final sortedHsns = hsnData.entries.toList()
        ..sort((a, b) => b.value['totalValue'].compareTo(a.value['totalValue']));

      builder.element('Summary', nest: () {
        double grandTotal = 0;
        double totalTaxable = 0;
        double totalCgst = 0;
        double totalSgst = 0;
        double totalIgst = 0;
        double totalCess = 0;

        for (var entry in sortedHsns) {
          grandTotal += entry.value['totalValue'];
          totalTaxable += entry.value['taxableValue'];
          totalCgst += entry.value['cgst'];
          totalSgst += entry.value['sgst'];
          totalIgst += entry.value['igst'];
          totalCess += entry.value['cess'];
        }

        builder.element('TotalSales', nest: grandTotal.toStringAsFixed(2));
        builder.element('TotalTaxable', nest: totalTaxable.toStringAsFixed(2));
        builder.element('TotalCGST', nest: totalCgst.toStringAsFixed(2));
        builder.element('TotalSGST', nest: totalSgst.toStringAsFixed(2));
        builder.element('TotalIGST', nest: totalIgst.toStringAsFixed(2));
        builder.element('TotalCess', nest: totalCess.toStringAsFixed(2));
      });

      builder.element('HsnItems', nest: () {
        for (var entry in sortedHsns) {
          final hsn = entry.key;
          final data = entry.value;

          builder.element('HsnItem', nest: () {
            builder.element('HsnCode', nest: hsn.isEmpty ? 'N/A' : hsn);
            builder.element('Quantity', nest: data['quantity'].toStringAsFixed(2));
            builder.element('GstRate', nest: data['gstRate'].toStringAsFixed(2));
            builder.element('TaxableValue', nest: data['taxableValue'].toStringAsFixed(2));
            builder.element('CGST', nest: data['cgst'].toStringAsFixed(2));
            builder.element('SGST', nest: data['sgst'].toStringAsFixed(2));
            builder.element('IGST', nest: data['igst'].toStringAsFixed(2));
            builder.element('Cess', nest: data['cess'].toStringAsFixed(2));
            builder.element('TotalValue', nest: data['totalValue'].toStringAsFixed(2));
            builder.element('InvoiceCount', nest: data['invoiceCount'].toString());
          });
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    await _saveXml(xmlDocument.toXmlString(pretty: true, indent: '  '),
        'HSN_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xml');
  }

  // ==================== PROFIT ANALYSIS REPORT ====================

  static Future<void> exportProfitAnalysisPDF(
      List<dynamic> items,
      String businessName,
      ) async {
    final pdf = pw.Document();

    // Calculate stats
    double avgProfitMargin = items.fold(0.0, (sum, item) => sum + item.profitMargin) / items.length;
    int highMarginCount = items.where((item) => item.profitMargin > 20).length;
    int mediumMarginCount = items.where((item) => item.profitMargin > 10 && item.profitMargin <= 20).length;
    int lowMarginCount = items.where((item) => item.profitMargin <= 10).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Profit Analysis Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
            ],
          ),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Average Profit Margin:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${avgProfitMargin.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('High Margin (>20%):'),
                    pw.Text('$highMarginCount items'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Medium Margin (10-20%):'),
                    pw.Text('$mediumMarginCount items'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Low Margin (<10%):'),
                    pw.Text('$lowMarginCount items'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Item', isHeader: true),
                  _buildTableCell('Cost', isHeader: true),
                  _buildTableCell('Selling', isHeader: true),
                  _buildTableCell('Profit', isHeader: true),
                  _buildTableCell('Margin %', isHeader: true),
                ],
              ),
              // Data Rows
              ...items.map((item) {
                final profit = item.sellingPrice - item.costPrice;
                return pw.TableRow(
                  children: [
                    _buildTableCell(item.description),
                    _buildTableCell('₹${item.costPrice.toStringAsFixed(2)}'),
                    _buildTableCell('₹${item.sellingPrice.toStringAsFixed(2)}'),
                    _buildTableCell('₹${profit.toStringAsFixed(2)}'),
                    _buildTableCell('${item.profitMargin.toStringAsFixed(1)}%'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'Profit_Analysis_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> exportProfitAnalysisXML(
      List<dynamic> items,
      String businessName,
      ) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ProfitAnalysisReport', nest: () {
      builder.element('BusinessName', nest: businessName);
      builder.element('ReportType', nest: 'Profit Analysis');
      builder.element('GeneratedOn', nest: DateTime.now().toIso8601String());

      double avgProfitMargin = items.fold(0.0, (sum, item) => sum + item.profitMargin) / items.length;

      builder.element('Summary', nest: () {
        builder.element('AverageProfitMargin', nest: avgProfitMargin.toStringAsFixed(2));
        builder.element('TotalItems', nest: items.length.toString());
        builder.element('HighMarginCount', nest: items.where((item) => item.profitMargin > 20).length.toString());
        builder.element('MediumMarginCount', nest: items.where((item) => item.profitMargin > 10 && item.profitMargin <= 20).length.toString());
        builder.element('LowMarginCount', nest: items.where((item) => item.profitMargin <= 10).length.toString());
      });

      builder.element('Items', nest: () {
        for (var item in items) {
          final profit = item.sellingPrice - item.costPrice;
          builder.element('Item', nest: () {
            builder.element('ItemCode', nest: item.itemCode);
            builder.element('Description', nest: item.description);
            builder.element('CostPrice', nest: item.costPrice.toStringAsFixed(2));
            builder.element('SellingPrice', nest: item.sellingPrice.toStringAsFixed(2));
            builder.element('ProfitPerUnit', nest: profit.toStringAsFixed(2));
            builder.element('ProfitMargin', nest: item.profitMargin.toStringAsFixed(2));
          });
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    await _saveXml(xmlDocument.toXmlString(pretty: true, indent: '  '),
        'Profit_Analysis_Report_${DateTime.now().millisecondsSinceEpoch}.xml');
  }

  // ==================== VALUATION REPORT ====================

  static Future<void> exportValuationPDF(
      List<Map<String, dynamic>> valuationData,
      double totalValue,
      String businessName,
      ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Inventory Valuation Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}'),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
            ],
          ),

          // Total Value
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Inventory Value:',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('₹${totalValue.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Item Name', isHeader: true),
                  _buildTableCell('Stock', isHeader: true),
                  _buildTableCell('Cost Price', isHeader: true),
                  _buildTableCell('Total Value', isHeader: true),
                ],
              ),
              // Data Rows
              ...valuationData.map((item) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(item['itemName']),
                    _buildTableCell(item['stock'].toStringAsFixed(1)),
                    _buildTableCell('₹${item['costPrice'].toStringAsFixed(2)}'),
                    _buildTableCell('₹${item['totalValue'].toStringAsFixed(2)}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'Valuation_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> exportValuationXML(
      List<Map<String, dynamic>> valuationData,
      double totalValue,
      String businessName,
      ) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ValuationReport', nest: () {
      builder.element('BusinessName', nest: businessName);
      builder.element('ReportType', nest: 'Inventory Valuation');
      builder.element('GeneratedOn', nest: DateTime.now().toIso8601String());
      builder.element('TotalInventoryValue', nest: totalValue.toStringAsFixed(2));
      builder.element('TotalItems', nest: valuationData.length.toString());

      builder.element('Items', nest: () {
        for (var item in valuationData) {
          builder.element('Item', nest: () {
            builder.element('ItemName', nest: item['itemName']);
            builder.element('Stock', nest: item['stock'].toStringAsFixed(2));
            builder.element('CostPrice', nest: item['costPrice'].toStringAsFixed(2));
            builder.element('TotalValue', nest: item['totalValue'].toStringAsFixed(2));
          });
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    await _saveXml(xmlDocument.toXmlString(pretty: true, indent: '  '),
        'Valuation_Report_${DateTime.now().millisecondsSinceEpoch}.xml');
  }

  // ==================== LOW STOCK REPORT ====================

  static Future<void> exportLowStockPDF(
      List<Map<String, dynamic>> lowStockItems,
      String businessName,
      ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Low Stock Alert Report',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
              ),
              pw.Text('Generated: ${DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())}'),
              pw.Text('${lowStockItems.length} items need restocking',
                  style: const pw.TextStyle(color: PdfColors.red)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),
            ],
          ),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Item', isHeader: true),
                  _buildTableCell('Location', isHeader: true),
                  _buildTableCell('Current', isHeader: true),
                  _buildTableCell('Minimum', isHeader: true),
                  _buildTableCell('Need', isHeader: true),
                ],
              ),
              // Data Rows
              ...lowStockItems.map((item) {
                return pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                  children: [
                    _buildTableCell(item['itemName']),
                    _buildTableCell(item['location']),
                    _buildTableCell(item['currentStock'].toStringAsFixed(1)),
                    _buildTableCell(item['minStock'].toStringAsFixed(1)),
                    _buildTableCell(item['deficit'].toStringAsFixed(1)),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    await _savePdf(pdf, 'Low_Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> exportLowStockXML(
      List<Map<String, dynamic>> lowStockItems,
      String businessName,
      ) async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('LowStockReport', nest: () {
      builder.element('BusinessName', nest: businessName);
      builder.element('ReportType', nest: 'Low Stock Alert');
      builder.element('GeneratedOn', nest: DateTime.now().toIso8601String());
      builder.element('TotalLowStockItems', nest: lowStockItems.length.toString());

      builder.element('Items', nest: () {
        for (var item in lowStockItems) {
          builder.element('Item', nest: () {
            builder.element('ItemName', nest: item['itemName']);
            builder.element('Location', nest: item['location']);
            builder.element('CurrentStock', nest: item['currentStock'].toStringAsFixed(2));
            builder.element('MinimumStock', nest: item['minStock'].toStringAsFixed(2));
            builder.element('Deficit', nest: item['deficit'].toStringAsFixed(2));
          });
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    await _saveXml(xmlDocument.toXmlString(pretty: true, indent: '  '),
        'Low_Stock_Report_${DateTime.now().millisecondsSinceEpoch}.xml');
  }

  // ==================== HELPER METHODS ====================

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> _savePdf(pw.Document pdf, String fileName) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Report PDF');
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  static Future<void> _saveXml(String xmlContent, String fileName) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsString(xmlContent);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Report XML');
    } catch (e) {
      print('Error saving XML: $e');
      rethrow;
    }
  }

  static Future<void> printPdf(pw.Document pdf) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }
}