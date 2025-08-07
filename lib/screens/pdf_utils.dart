import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../model/SaleMaster.dart'; // Import SaleMaster
import '../screens/inventory_management.dart'; // Import ItemMaster and StockInventory

class PDFUtils {
  static Future<Uint8List> generateSalePdf(SaleMaster sale) async {
    final pdf = pw.Document();
    // Load a font that supports Indian Rupee symbol and other characters
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Business Header (Placeholder)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Your Business Name', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.Text('123, Business Street, City, State - 123456', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                    pw.Text('GSTIN: ABCDE12345FGHIJ', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('TAX INVOICE', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      pw.Text(sale.customerName, style: pw.TextStyle(font: ttf)),
                      // Removed sale.phone and sale.type as they are no longer in SaleMaster
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${sale.invoice}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(sale.date)}', style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Items:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildSaleItemsTable(sale.items, ttf), // Use the updated _buildSaleItemsTable
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total Sale Amount: ₹${sale.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                ),
              ),
              pw.Spacer(), // Pushes content to top, footer to bottom
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // NEW: Method to generate HSN Summary PDF
  static Future<Uint8List> generateHsnSummaryPDF(List<SaleItem> items, String hsnCode) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    double totalTaxableValue = 0;
    double totalIntegratedTax = 0;
    double totalCentralTax = 0;
    double totalStateTax = 0;
    double totalCess = 0;
    double overallTotal = 0;

    for (var item in items) {
      totalTaxableValue += item.totalTaxableValue;
      totalIntegratedTax += item.integratedTaxAmount;
      totalCentralTax += item.centralTaxAmount;
      totalStateTax += item.stateTaxAmount;
      totalCess += item.cessAmount;
      overallTotal += item.itemTotal;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Your Business Name', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.Text('HSN/SAC Sales Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                    pw.SizedBox(height: 10),
                    pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                    if (hsnCode.isNotEmpty)
                      pw.Text('Filtered HSN/SAC: $hsnCode', style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Sales Items for HSN/SAC: ${hsnCode.isNotEmpty ? hsnCode : 'All'}', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildSaleItemsTable(items, ttf), // Re-use the item table builder
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Summary:', style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Taxable Value:', style: pw.TextStyle(font: ttf)),
                        pw.Text('₹${totalTaxableValue.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total IGST:', style: pw.TextStyle(font: ttf)),
                        pw.Text('₹${totalIntegratedTax.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total CGST:', style: pw.TextStyle(font: ttf)),
                        pw.Text('₹${totalCentralTax.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total SGST:', style: pw.TextStyle(font: ttf)),
                        pw.Text('₹${totalStateTax.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Cess:', style: pw.TextStyle(font: ttf)),
                        pw.Text('₹${totalCess.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Overall Total:', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        pw.Text('₹${overallTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'Report generated by Inventory Management System',
                  style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // NEW: Method to generate a PDF for all sales
  static Future<Uint8List> generateAllSalesPdf(List<SaleMaster> sales) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Your Business Name', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text('All Sales Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 10),
                  pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Sales Overview:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Invoice #', 'Customer Name', 'Date', 'Total (₹)'],
              data: List<List<String>>.generate(
                sales.length,
                    (index) {
                  final sale = sales[index];
                  return [
                    sale.invoice,
                    sale.customerName,
                    DateFormat('dd MMM yyyy').format(sale.date),
                    sale.total.toStringAsFixed(2),
                  ];
                },
              ),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1),
              },
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Grand Total Sales: ₹${sales.fold(0.0, (sum, sale) => sum + sale.total).toStringAsFixed(2)}',
                style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Report generated by Inventory Management System',
                style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // NEW: Method to generate a PDF for all items
  static Future<Uint8List> generateAllItemsPdf(List<ItemMaster> items) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Your Business Name', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text('All Items Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 10),
                  pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Item Details:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Code', 'Description', 'HSN', 'Unit', 'Cost (₹)', 'Selling (₹)', 'Profit %'],
              data: List<List<String>>.generate(
                items.length,
                    (index) {
                  final item = items[index];
                  return [
                    item.itemCode,
                    item.description,
                    item.hsnSacCode,
                    item.unitOfMeasurement,
                    item.costPrice.toStringAsFixed(2),
                    item.sellingPrice.toStringAsFixed(2),
                    item.profitMargin.toStringAsFixed(1),
                  ];
                },
              ),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
              rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(0.8),
              },
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Report generated by Inventory Management System',
                style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // NEW: Method to generate a PDF for all stock inventory
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
                  pw.Text('Your Business Name', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text('All Stock Inventory Report', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                  pw.SizedBox(height: 10),
                  pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey700)),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Stock Levels:', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Item Description', 'Location', 'Current Stock', 'Min Level', 'Status'],
              data: List<List<String>>.generate(
                stocks.length,
                    (index) {
                  final stock = stocks[index];
                  final item = itemMap[stock.itemId];
                  final itemName = item?.description.isNotEmpty == true ? item!.description : 'Unknown Item';
                  final status = stock.currentStock <= stock.minimumStockLevel ? 'Low Stock' : 'Good';
                  return [
                    itemName,
                    stock.location,
                    stock.currentStock.toStringAsFixed(1),
                    stock.minimumStockLevel.toStringAsFixed(1),
                    status,
                  ];
                },
              ),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Report generated by Inventory Management System',
                style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  // Renamed for clarity: this is for individual sale items within a sale or HSN report
  static pw.Widget _buildSaleItemsTable(List<SaleItem> items, pw.Font font) {
    return pw.Table.fromTextArray(
      headers: [
        'Sr No.', 'HSN', 'Description', 'UQC', 'Qty', 'Taxable Value (₹)',
        'Rate (%)', 'IGST (₹)', 'CGST (₹)', 'SGST (₹)', 'Cess (₹)', 'Total (₹)'
      ],
      data: List<List<String>>.generate(
        items.length,
            (index) {
          final item = items[index];
          final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
          return [
            (index + 1).toString(),
            item.hsnSacCode,
            item.description,
            item.unitOfMeasurement,
            item.quantity.toStringAsFixed(1),
            item.totalTaxableValue.toStringAsFixed(2),
            '${totalTaxRate.toStringAsFixed(1)}%',
            item.integratedTaxAmount.toStringAsFixed(2),
            item.centralTaxAmount.toStringAsFixed(2),
            item.stateTaxAmount.toStringAsFixed(2),
            item.cessAmount.toStringAsFixed(2),
            item.itemTotal.toStringAsFixed(2),
          ];
        },
      ),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: pw.TextStyle(font: font, fontSize: 9), // Smaller font for cells
      rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))), // Row separators
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700), // Darker header
      cellAlignment: pw.Alignment.centerLeft, // Align cell content
      headerAlignment: pw.Alignment.centerLeft, // Align header content
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5), // Overall table border
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // Sr No.
        1: const pw.FlexColumnWidth(0.8), // HSN
        2: const pw.FlexColumnWidth(2),   // Description
        3: const pw.FlexColumnWidth(0.8), // UQC
        4: const pw.FlexColumnWidth(0.7), // Qty
        5: const pw.FlexColumnWidth(1.2), // Taxable Value
        6: const pw.FlexColumnWidth(0.8), // Rate
        7: const pw.FlexColumnWidth(1),   // IGST
        8: const pw.FlexColumnWidth(1),   // CGST
        9: const pw.FlexColumnWidth(1),   // SGST
        10: const pw.FlexColumnWidth(0.8), // Cess
        11: const pw.FlexColumnWidth(1.2), // Total
      },
    );
  }

  static Future<void> generateAndDownloadPDF(SaleMaster sale) async {
    try {
      final pdfBytes = await generateSalePdf(sale);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/invoice_${sale.invoice}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('PDF saved to: ${file.path}');
      }
      // For web, you might need a different approach to download
      // For mobile, you can open the file or share it
      // This example just prints the path in debug mode.
      // In a real app, you'd use `OpenFile.open(file.path)` or similar.
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving PDF: $e');
      }
    }
  }

  // NEW: Helper to generate and download HSN Summary PDF
  static Future<void> generateAndDownloadHsnSummaryPDF(List<SaleItem> items, String hsnCode) async {
    try {
      final pdfBytes = await generateHsnSummaryPDF(items, hsnCode);
      final output = await getTemporaryDirectory();
      final fileName = hsnCode.isNotEmpty ? "hsn_report_${hsnCode.replaceAll('/', '_')}.pdf" : "hsn_report_all.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('HSN Report PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving HSN Report PDF: $e');
      }
    }
  }

  // NEW: Helper to generate and download All Sales PDF
  static Future<void> generateAndDownloadAllSalesPDF(List<SaleMaster> sales) async {
    try {
      final pdfBytes = await generateAllSalesPdf(sales);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('All Sales Report PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving All Sales Report PDF: $e');
      }
    }
  }

  // NEW: Helper to generate and download All Items PDF
  static Future<void> generateAndDownloadAllItemsPDF(List<ItemMaster> items) async {
    try {
      final pdfBytes = await generateAllItemsPdf(items);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_items_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('All Items Report PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving All Items Report PDF: $e');
      }
    }
  }

  // NEW: Helper to generate and download All Stock PDF
  static Future<void> generateAndDownloadAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_stock_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      if (kDebugMode) {
        print('All Stock Report PDF saved to: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating or saving All Stock Report PDF: $e');
      }
    }
  }

  static Future<void> shareHsnSummaryPDF(List<SaleItem> items, String hsnCode) async {
    try {
      final pdfBytes = await generateHsnSummaryPDF(items, hsnCode);
      final output = await getTemporaryDirectory();
      final fileName = hsnCode.isNotEmpty ? "hsn_report_${hsnCode.replaceAll('/', '_')}.pdf" : "hsn_report_all.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your HSN Sales Report for ${hsnCode.isNotEmpty ? hsnCode : 'All HSNs'}');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing HSN Report PDF: $e');
      }
    }
  }

  static Future<void> printHsnSummaryPDF(List<SaleItem> items, String hsnCode) async {
    try {
      final pdfBytes = await generateHsnSummaryPDF(items, hsnCode);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing HSN Report PDF: $e');
      }
    }
  }

  static Future<void> shareAllSalesPDF(List<SaleMaster> sales) async {
    try {
      final pdfBytes = await generateAllSalesPdf(sales);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_sales_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your All Sales Report');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing All Sales Report PDF: $e');
      }
    }
  }

  static Future<void> printAllSalesPDF(List<SaleMaster> sales) async {
    try {
      final pdfBytes = await generateAllSalesPdf(sales);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing All Sales Report PDF: $e');
      }
    }
  }

  static Future<void> shareAllItemsPDF(List<ItemMaster> items) async {
    try {
      final pdfBytes = await generateAllItemsPdf(items);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_items_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your All Items Report');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing All Items Report PDF: $e');
      }
    }
  }

  static Future<void> printAllItemsPDF(List<ItemMaster> items) async {
    try {
      final pdfBytes = await generateAllItemsPdf(items);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing All Items Report PDF: $e');
      }
    }
  }

  static Future<void> shareAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/all_stock_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf");
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your All Stock Report');
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing All Stock Report PDF: $e');
      }
    }
  }

  static Future<void> printAllStockPDF(List<StockInventory> stocks, List<ItemMaster> allItems) async {
    try {
      final pdfBytes = await generateAllStockPdf(stocks, allItems);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error printing All Stock Report PDF: $e');
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
}
