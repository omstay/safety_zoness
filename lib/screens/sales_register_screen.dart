// NEW FILE: sales_register_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/SaleMaster.dart';
import 'pdf_utils.dart';

class SalesRegisterScreen extends StatefulWidget {
  final String businessId;
  const SalesRegisterScreen({super.key, required this.businessId});

  @override
  State<SalesRegisterScreen> createState() => _SalesRegisterScreenState();
}

class _SalesRegisterScreenState extends State<SalesRegisterScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _selectedFilter = 'ALL';

  final List<Map<String, String>> _filterOptions = [
    {'value': 'ALL', 'label': 'All Sales'},
    {'value': 'B2B', 'label': 'B2B Only'},
    {'value': 'B2C_LARGE', 'label': 'B2C Large'},
    {'value': 'B2C_SMALL', 'label': 'B2C Small'},
    {'value': 'EXPORT', 'label': 'Exports'},
    {'value': 'INTRA', 'label': 'Intra State'},
    {'value': 'INTER', 'label': 'Inter State'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Register'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportSalesRegister,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Container
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Date Range Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectFromDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('From Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(DateFormat('dd/MM/yyyy').format(_fromDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectToDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('To Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(DateFormat('dd/MM/yyyy').format(_toDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _filterOptions.map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter['value'],
                      child: Text(filter['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'ALL';
                    });
                  },
                ),
              ],
            ),
          ),

          // Sales Data
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildSalesQuery(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sales = snapshot.data!.docs
                    .map((doc) => SaleMaster.fromFirestore(doc))
                    .where((sale) => _applyAdditionalFilters(sale))
                    .toList();

                if (sales.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    _buildSummaryHeader(sales),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildSalesTable(sales),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildSalesQuery() {
    Query query = _firestore
        .collection('sales')
        .where('businessId', isEqualTo: widget.businessId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_toDate))
        .orderBy('date', descending: true);

    if (_selectedFilter != 'ALL' && !['INTRA', 'INTER'].contains(_selectedFilter)) {
      query = query.where('gstr1Section', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  bool _applyAdditionalFilters(SaleMaster sale) {
    switch (_selectedFilter) {
      case 'INTRA':
        return sale.supplyType == 'INTRA';
      case 'INTER':
        return sale.supplyType == 'INTER';
      default:
        return true;
    }
  }

  Widget _buildSummaryHeader(List<SaleMaster> sales) {
    double totalTaxableValue = 0;
    double totalCGST = 0;
    double totalSGST = 0;
    double totalIGST = 0;
    double totalCess = 0;
    double grandTotal = 0;

    for (var sale in sales) {
      for (var item in sale.items) {
        totalTaxableValue += item.totalTaxableValue;
        totalCGST += item.centralTaxAmount;
        totalSGST += item.stateTaxAmount;
        totalIGST += item.integratedTaxAmount;
        totalCess += item.cessAmount;
      }
      grandTotal += sale.total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Sales Summary (${sales.length} invoices)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Taxable', totalTaxableValue),
              _buildSummaryItem('CGST', totalCGST),
              _buildSummaryItem('SGST', totalSGST),
              _buildSummaryItem('IGST', totalIGST),
              _buildSummaryItem('Total', grandTotal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('₹${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSalesTable(List<SaleMaster> sales) {
    return DataTable(
      columnSpacing: 16,
      horizontalMargin: 16,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
      columns: const [
        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('POS', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Taxable Value', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('CGST', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('SGST', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('IGST', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Cess', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: sales.map((sale) {
        double saleTaxableValue = 0;
        double saleCGST = 0;
        double saleSGST = 0;
        double saleIGST = 0;
        double saleCess = 0;

        for (var item in sale.items) {
          saleTaxableValue += item.totalTaxableValue;
          saleCGST += item.centralTaxAmount;
          saleSGST += item.stateTaxAmount;
          saleIGST += item.integratedTaxAmount;
          saleCess += item.cessAmount;
        }

        return DataRow(
          cells: [
            DataCell(Text(DateFormat('dd/MM/yy').format(sale.date))),
            DataCell(Text(sale.invoice)),
            DataCell(SizedBox(
              width: 120,
              child: Text(sale.customerName, overflow: TextOverflow.ellipsis),
            )),
            DataCell(Text(sale.recipientGSTIN.isEmpty ? 'N/A' : sale.recipientGSTIN)),
            DataCell(Text(sale.placeOfSupply)),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor(sale.gstr1Section).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sale.supplyType,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getTypeColor(sale.gstr1Section),
                ),
              ),
            )),
            DataCell(Text('₹${saleTaxableValue.toStringAsFixed(2)}')),
            DataCell(Text('₹${saleCGST.toStringAsFixed(2)}')),
            DataCell(Text('₹${saleSGST.toStringAsFixed(2)}')),
            DataCell(Text('₹${saleIGST.toStringAsFixed(2)}')),
            DataCell(Text('₹${saleCess.toStringAsFixed(2)}')),
            DataCell(Text('₹${sale.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                  onPressed: () => PDFUtils.generateAndDownloadPDF(sale),
                  tooltip: 'Download PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.info, size: 16, color: Colors.blue),
                  onPressed: () => _showSaleDetails(sale),
                  tooltip: 'View Details',
                ),
              ],
            )),
          ],
        );
      }).toList(),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'B2B':
        return Colors.blue;
      case 'B2C_LARGE':
        return Colors.green;
      case 'B2C_SMALL':
        return Colors.orange;
      case 'EXPORT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No sales found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('for the selected filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate, // Ensure from date can't be after to date
    );
    if (picked != null && picked != _fromDate) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate, // Ensure to date can't be before from date
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _toDate) {
      setState(() => _toDate = picked);
    }
  }

  void _showSaleDetails(SaleMaster sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice: ${sale.invoice}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Customer', sale.customerName),
                _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(sale.date)),
                _buildDetailRow('GSTIN', sale.recipientGSTIN.isEmpty ? 'N/A' : sale.recipientGSTIN),
                _buildDetailRow('POS', sale.placeOfSupply),
                _buildDetailRow('Supply Type', sale.supplyType),
                _buildDetailRow('Sale Type', sale.saleType),
                _buildDetailRow('Document Type', sale.documentType),
                if (sale.eWayBillNo != null) _buildDetailRow('E-Way Bill', sale.eWayBillNo!),
                const SizedBox(height: 16),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                // Items Table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    dataRowHeight: 40,
                    headingRowHeight: 35,
                    columns: const [
                      DataColumn(label: Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('HSN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Taxable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tax', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    rows: sale.items.map((item) {
                      final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
                      return DataRow(
                        cells: [
                          DataCell(SizedBox(width: 80, child: Text(item.description, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))),
                          DataCell(Text(item.hsnSacCode, style: const TextStyle(fontSize: 11))),
                          DataCell(Text(item.quantity.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                          DataCell(Text('₹${item.sellingPricePerUnit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                          DataCell(Text('₹${item.totalTaxableValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                          DataCell(Text('${totalTaxRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11))),
                          DataCell(Text('₹${item.itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total Amount: ₹${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              PDFUtils.generateAndDownloadPDF(sale);
            },
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _exportSalesRegister() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final salesSnapshot = await _firestore
          .collection('sales')
          .where('businessId', isEqualTo: widget.businessId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_fromDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_toDate))
          .get();

      // Dismiss loading dialog
      Navigator.of(context).pop();

      final sales = salesSnapshot.docs
          .map((doc) => SaleMaster.fromFirestore(doc))
          .where((sale) => _applyAdditionalFilters(sale))
          .toList();

      if (sales.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Sales Register',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    title: const Text('Download PDF'),
                    subtitle: const Text('Detailed sales register in PDF format'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.generateSalesRegisterPDF(sales, _fromDate, _toDate, _selectedFilter);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sales Register PDF downloaded!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.table_chart, color: Colors.green),
                    ),
                    title: const Text('Download Excel'),
                    subtitle: const Text('Spreadsheet format for analysis'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.generateSalesRegisterExcel(sales, _fromDate, _toDate, _selectedFilter);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sales Register Excel downloaded!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.code, color: Colors.blue),
                    ),
                    title: const Text('Download JSON (for GST Portal)'),
                    subtitle: const Text('GST return filing format'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.generateSalesRegisterJSON(sales, _fromDate, _toDate);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sales Register JSON downloaded!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Dismiss loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}