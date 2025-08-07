import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../model/SaleMaster.dart';
import '../inventory_management.dart'; // To access ItemMaster static helpers
import '../pdf_utils.dart'; // Assuming this file exists and has PDF generation logic

class SalesByHsnReportScreen extends StatefulWidget {
  final String businessId;
  const SalesByHsnReportScreen({super.key, required this.businessId});

  @override
  State<SalesByHsnReportScreen> createState() => _SalesByHsnReportScreenState();
}

class _SalesByHsnReportScreenState extends State<SalesByHsnReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _hsnSearchController = TextEditingController();
  String _hsnSearchQuery = '';

  @override
  void dispose() {
    _hsnSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales by HSN Report'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _hsnSearchController,
              decoration: InputDecoration(
                labelText: 'Search by HSN/SAC Code',
                hintText: 'Enter HSN/SAC code',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _hsnSearchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final List<SaleItem> filteredItems = await _getFilteredSaleItems();
                  if (filteredItems.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No data to export for this HSN.'), backgroundColor: Colors.orange),
                      );
                    }
                    return;
                  }
                  // Show options to download, share, or print
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return SafeArea(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text('Download PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.generateAndDownloadHsnSummaryPDF(filteredItems, _hsnSearchQuery.toUpperCase());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('HSN Report PDF downloaded!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Share PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.shareHsnSummaryPDF(filteredItems, _hsnSearchQuery.toUpperCase());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('HSN Report PDF shared!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.print),
                              title: const Text('Print PDF'),
                              onTap: () async {
                                Navigator.pop(bc);
                                await PDFUtils.printHsnSummaryPDF(filteredItems, _hsnSearchQuery.toUpperCase());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('HSN Report PDF sent to printer!'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Report PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('sales')
                  .where('businessId', isEqualTo: widget.businessId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<SaleMaster> allSales = snapshot.data!.docs
                    .map((doc) => SaleMaster.fromFirestore(doc))
                    .toList();

                // Filter sale items based on HSN query
                final List<Map<String, dynamic>> filteredSaleItems = [];
                for (var sale in allSales) {
                  for (var item in sale.items) {
                    if (_hsnSearchQuery.isEmpty ||
                        item.hsnSacCode.toLowerCase().contains(_hsnSearchQuery)) {
                      filteredSaleItems.add({
                        'sale': sale,
                        'item': item,
                      });
                    }
                  }
                }

                if (filteredSaleItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredSaleItems.length,
                  itemBuilder: (context, index) {
                    final sale = filteredSaleItems[index]['sale'] as SaleMaster;
                    final item = filteredSaleItems[index]['item'] as SaleItem;
                    return _buildSaleItemCard(sale, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<SaleItem>> _getFilteredSaleItems() async {
    final QuerySnapshot salesSnapshot = await _firestore
        .collection('sales')
        .where('businessId', isEqualTo: widget.businessId)
        .orderBy('date', descending: true)
        .get();

    final List<SaleItem> items = [];
    for (var doc in salesSnapshot.docs) {
      final sale = SaleMaster.fromFirestore(doc);
      for (var item in sale.items) {
        if (_hsnSearchQuery.isEmpty ||
            item.hsnSacCode.toLowerCase().contains(_hsnSearchQuery)) {
          items.add(item);
        }
      }
    }
    return items;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _hsnSearchQuery.isEmpty ? 'No sales items found' : 'No items match your HSN search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hsnSearchQuery.isEmpty
                ? 'Sales items will appear here'
                : 'Try a different HSN/SAC code',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemCard(SaleMaster sale, SaleItem item) {
    final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹${item.itemTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('HSN: ${item.hsnSacCode}', style: TextStyle(color: Colors.grey.shade700)),
            Text('Qty: ${item.quantity.toStringAsFixed(1)} ${item.unitOfMeasurement}', style: TextStyle(color: Colors.grey.shade700)),
            Text('Taxable Value: ₹${item.totalTaxableValue.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
            Text('Tax Rate: ${totalTaxRate.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 20),
            Text('Invoice: ${sale.invoice} (Customer: ${sale.customerName})', style: TextStyle(color: Colors.grey.shade600)),
            Text('Sale Date: ${DateFormat('dd MMM yyyy').format(sale.date)}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Generate PDF for this specific sale (bill format)
                  await PDFUtils.generateAndDownloadPDF(sale);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bill for Invoice ${sale.invoice} generated!'), backgroundColor: Colors.green),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Bill PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
