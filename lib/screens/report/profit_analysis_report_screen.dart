import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safetyzoness/screens/report/report_export_utils.dart';
import '../inventory_management.dart';

class ProfitAnalysisReportScreen extends StatefulWidget {
  final String businessId;

  const ProfitAnalysisReportScreen({super.key, required this.businessId});

  @override
  State<ProfitAnalysisReportScreen> createState() => _ProfitAnalysisReportScreenState();
}

class _ProfitAnalysisReportScreenState extends State<ProfitAnalysisReportScreen> {
  List<ItemMaster>? _cachedItems;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Analysis Report'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .where('businessId', isEqualTo: widget.businessId)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No items available',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final items = snapshot.data!.docs
              .map((doc) => ItemMaster.fromFirestore(doc))
              .toList();

          // Cache items for export
          _cachedItems = items;

          // Sort by profit margin descending
          items.sort((a, b) => b.profitMargin.compareTo(a.profitMargin));

          // Calculate averages
          double avgProfitMargin = items.fold(0.0, (sum, item) => sum + item.profitMargin) / items.length;
          int highMarginCount = items.where((item) => item.profitMargin > 20).length;
          int mediumMarginCount = items.where((item) => item.profitMargin > 10 && item.profitMargin <= 20).length;
          int lowMarginCount = items.where((item) => item.profitMargin <= 10).length;

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade600, Colors.pink.shade400],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Average Profit Margin',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avgProfitMargin.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMarginCategory('High (>20%)', highMarginCount, Colors.green),
                        _buildMarginCategory('Medium (10-20%)', mediumMarginCount, Colors.orange),
                        _buildMarginCategory('Low (<10%)', lowMarginCount, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildProfitCard(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarginCategory(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 40,
          height: 3,
          color: color,
        ),
      ],
    );
  }

  Widget _buildProfitCard(ItemMaster item) {
    final profitPerUnit = item.sellingPrice - item.costPrice;
    final marginColor = item.profitMargin > 20
        ? Colors.green
        : item.profitMargin > 10
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: marginColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.show_chart, color: marginColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Code: ${item.itemCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: marginColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: marginColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriceInfo('Cost', '₹${item.costPrice.toStringAsFixed(2)}', Colors.red),
                  _buildPriceInfo('Selling', '₹${item.sellingPrice.toStringAsFixed(2)}', Colors.green),
                  _buildPriceInfo('Profit', '₹${profitPerUnit.toStringAsFixed(2)}', marginColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showExportOptions() {
    if (_cachedItems == null || _cachedItems!.isEmpty) {
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
                    await ReportExportUtils.exportProfitAnalysisPDF(
                      _cachedItems!,
                      'Your Business Name',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF exported successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error exporting PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.blue),
                title: const Text('Export as XML'),
                onTap: () async {
                  Navigator.pop(bc);
                  try {
                    await ReportExportUtils.exportProfitAnalysisXML(
                      _cachedItems!,
                      'Your Business Name',
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
}