import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:safetyzoness/screens/report/report_export_utils.dart';
import '../../model/SaleMaster.dart';


class SalesByHsnReportScreen extends StatefulWidget {
  final String businessId;

  const SalesByHsnReportScreen({super.key, required this.businessId});

  @override
  State<SalesByHsnReportScreen> createState() => _SalesByHsnReportScreenState();
}

class _SalesByHsnReportScreenState extends State<SalesByHsnReportScreen> {
  DateTimeRange? _dateRange;
  String _selectedFilter = 'All Time';
  Map<String, Map<String, dynamic>>? _cachedHsnData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales by HSN/SAC Report'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Period',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFilter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                        _selectedFilter = 'All Time';
                      });
                    },
                  ),
              ],
            ),
          ),

          // HSN Sales List
          Expanded(
            child: FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _calculateHsnSales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final hsnData = snapshot.data ?? {};

                // Cache the data for export
                _cachedHsnData = hsnData;

                if (hsnData.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No sales data available',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Sort by total value descending
                final sortedHsns = hsnData.entries.toList()
                  ..sort((a, b) => b.value['totalValue'].compareTo(a.value['totalValue']));

                // Calculate totals
                double grandTotal = 0;
                double totalTaxable = 0;
                double totalCgst = 0;
                double totalSgst = 0;
                double totalIgst = 0;

                for (var entry in sortedHsns) {
                  grandTotal += entry.value['totalValue'];
                  totalTaxable += entry.value['taxableValue'];
                  totalCgst += entry.value['cgst'];
                  totalSgst += entry.value['sgst'];
                  totalIgst += entry.value['igst'];
                }

                return Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Sales',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '₹${grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTaxSummary('Taxable', totalTaxable),
                              _buildTaxSummary('CGST', totalCgst),
                              _buildTaxSummary('SGST', totalSgst),
                              _buildTaxSummary('IGST', totalIgst),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // HSN List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${sortedHsns.length} HSN/SAC Codes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // HSN Cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedHsns.length,
                        itemBuilder: (context, index) {
                          final entry = sortedHsns[index];
                          return _buildHsnCard(entry.key, entry.value);
                        },
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

  void _showExportOptions() {
    if (_cachedHsnData == null || _cachedHsnData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                onTap: () async {
                  Navigator.pop(bc);
                  try {
                    await ReportExportUtils.exportHsnSalesPDF(
                      _cachedHsnData!,
                      _selectedFilter,
                      'Your Business Name', // Replace with actual business name
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF exported successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error exporting PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.blue),
                title: const Text('Export as XML'),
                onTap: () async {
                  Navigator.pop(bc);
                  try {
                    await ReportExportUtils.exportHsnSalesXML(
                      _cachedHsnData!,
                      _selectedFilter,
                      'Your Business Name', // Replace with actual business name
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('XML exported successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error exporting XML: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxSummary(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHsnCard(String hsn, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.trending_up, color: Colors.blue, size: 24),
        ),
        title: Text(
          'HSN/SAC: ${hsn.isEmpty ? "N/A" : hsn}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Qty: ${data['quantity'].toStringAsFixed(1)} | GST Rate: ${data['gstRate'].toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${data['totalValue'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              '${data['invoiceCount']} inv.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                _buildDetailRow('Taxable Amount', '₹${data['taxableValue'].toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildDetailRow('CGST', '₹${data['cgst'].toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildDetailRow('SGST', '₹${data['sgst'].toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildDetailRow('IGST', '₹${data['igst'].toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Cess', '₹${data['cess'].toStringAsFixed(2)}'),
                const Divider(height: 20),
                _buildDetailRow('Total Tax', '₹${(data['cgst'] + data['sgst'] + data['igst'] + data['cess']).toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 8),
                _buildDetailRow('Grand Total', '₹${data['totalValue'].toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<Map<String, Map<String, dynamic>>> _calculateHsnSales() async {
    Query query = FirebaseFirestore.instance
        .collection('sales')
        .where('businessId', isEqualTo: widget.businessId);

    // Apply date filter if selected
    if (_dateRange != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange!.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange!.end));
    }

    final snapshot = await query.get();

    Map<String, Map<String, dynamic>> hsnData = {};
    double totalQuantity = 0;

    for (var doc in snapshot.docs) {
      try {
        final sale = SaleMaster.fromFirestore(doc);

        for (var item in sale.items) {
          // Use hsnSacCode instead of hsnCode
          final hsn = item.hsnSacCode.isEmpty ? 'N/A' : item.hsnSacCode;

          // Calculate GST rate (cgst + sgst for intra-state, or igst for inter-state)
          final gstRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);

          if (!hsnData.containsKey(hsn)) {
            hsnData[hsn] = {
              'quantity': 0.0,
              'taxableValue': 0.0,
              'cgst': 0.0,
              'sgst': 0.0,
              'igst': 0.0,
              'cess': 0.0,
              'totalValue': 0.0,
              'invoiceCount': 0,
              'gstRate': gstRate,
              'totalQuantity': 0.0,
            };
          }

          // Use the correct property names from SaleItem model
          hsnData[hsn]!['quantity'] += item.quantity;
          hsnData[hsn]!['taxableValue'] += item.totalTaxableValue;
          hsnData[hsn]!['cgst'] += item.centralTaxAmount;
          hsnData[hsn]!['sgst'] += item.stateTaxAmount;
          hsnData[hsn]!['igst'] += item.integratedTaxAmount;
          hsnData[hsn]!['cess'] += item.cessAmount;
          hsnData[hsn]!['totalValue'] += item.itemTotal;
          hsnData[hsn]!['invoiceCount']++;

          totalQuantity += item.quantity;
        }
      } catch (e) {
        debugPrint('Error processing sale: $e');
      }
    }

    // Add total quantity to each HSN for percentage calculation
    for (var key in hsnData.keys) {
      hsnData[key]!['totalQuantity'] = totalQuantity;
    }

    return hsnData;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 7 Days'),
              onTap: () {
                setState(() {
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  );
                  _selectedFilter = 'Last 7 Days';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last 30 Days'),
              onTap: () {
                setState(() {
                  _dateRange = DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 30)),
                    end: DateTime.now(),
                  );
                  _selectedFilter = 'Last 30 Days';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _dateRange = DateTimeRange(
                    start: DateTime(now.year, now.month, 1),
                    end: DateTime(now.year, now.month + 1, 0),
                  );
                  _selectedFilter = 'This Month';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Range'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _dateRange = picked;
                    _selectedFilter =
                    '${DateFormat('dd/MM/yy').format(picked.start)} - ${DateFormat('dd/MM/yy').format(picked.end)}';
                  });
                }
              },
            ),
            ListTile(
              title: const Text('All Time'),
              onTap: () {
                setState(() {
                  _dateRange = null;
                  _selectedFilter = 'All Time';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}