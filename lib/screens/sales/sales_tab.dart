import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../model/SaleMaster.dart';
import '../add_edit_sale_screen.dart';
import '../pdf_utils.dart';

class SalesScreen extends StatefulWidget {
  final String userId;
  const SalesScreen({super.key, required this.userId});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Sales',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sales by customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Sales List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('sales')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('SalesScreen Error: ${snapshot.error}');
                  return const Center(child: Text("Error loading sales"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sales = snapshot.data!.docs
                    .map((doc) {
                  try {
                    return SaleMaster.fromFirestore(doc);
                  } catch (e) {
                    debugPrint('Error parsing sale: $e');
                    return null;
                  }
                })
                    .where((sale) => sale != null)
                    .cast<SaleMaster>()
                    .where((sale) => _searchQuery.isEmpty || sale.customerName.toLowerCase().contains(_searchQuery))
                    .toList();

                // Manual sorting by date
                sales.sort((a, b) => b.date.compareTo(a.date));

                if (sales.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    return _buildSaleCard(sales[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSaleDialog,
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ),
    );
  }

  void _showAddSaleDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSaleScreen(userId: widget.userId),
      ),
    );
  }

  void _showEditSaleDialog(SaleMaster sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSaleScreen(
          userId: widget.userId,
          saleId: sale.id,
          saleDoc: null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No sales yet' : 'No matching sales',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSaleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Sale'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleMaster sale) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sale.customerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${sale.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Invoice #: ${sale.invoice}'),
            Text('Date: ${DateFormat('dd MMM yyyy').format(sale.date)}'),
            const SizedBox(height: 12),
            // Display items
            if (sale.items.isNotEmpty) ...[
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                      child: DataTable(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFF667eea).withOpacity(0.1)),
                        columns: [
                          DataColumn(label: Text('Sr No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('HSN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('UQC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Taxable Value (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('IGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('CGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('SGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Cess (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          DataColumn(label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        ],
                        rows: List<DataRow>.generate(
                          sale.items.length,
                              (index) {
                            final item = sale.items[index];
                            final totalTaxRate = item.igstRate > 0 ? item.igstRate : (item.cgstRate + item.sgstRate);
                            return DataRow(
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(Text(item.hsnSacCode)),
                                DataCell(Text(item.description)),
                                DataCell(Text(item.unitOfMeasurement)),
                                DataCell(Text(item.quantity.toStringAsFixed(1))),
                                DataCell(Text(item.totalTaxableValue.toStringAsFixed(2))),
                                DataCell(Text('${totalTaxRate.toStringAsFixed(1)}%')),
                                DataCell(Text(item.integratedTaxAmount.toStringAsFixed(2))),
                                DataCell(Text(item.centralTaxAmount.toStringAsFixed(2))),
                                DataCell(Text(item.stateTaxAmount.toStringAsFixed(2))),
                                DataCell(Text(item.cessAmount.toStringAsFixed(2))),
                                DataCell(Text(item.itemTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generatePDF(sale),
                  tooltip: 'Download PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () => _shareSale(sale),
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.black),
                  onPressed: () => _printSale(sale),
                  tooltip: 'Print',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditSaleDialog(sale),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteSale(sale.id),
                  tooltip: 'Delete',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSale(String saleId) async {
    try {
      await _firestore.collection('sales').doc(saleId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale deleted'), backgroundColor: Colors.green),
      );
      debugPrint('Sale deleted: $saleId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      debugPrint('Error deleting sale: $e');
    }
  }

  Future<void> _generatePDF(SaleMaster sale) async {
    try {
      await PDFUtils.generateAndDownloadPDF(sale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareSale(SaleMaster sale) async {
    try {
      await PDFUtils.shareSalePDF(sale);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printSale(SaleMaster sale) async {
    try {
      await PDFUtils.printSalePDF(sale);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}