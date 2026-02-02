import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../inventory_management.dart';
import '../pdf_utils.dart';

class StockSummaryReportScreen extends StatefulWidget {
  final String businessId;

  const StockSummaryReportScreen({super.key, required this.businessId});

  @override
  State<StockSummaryReportScreen> createState() => _StockSummaryReportScreenState();
}

class _StockSummaryReportScreenState extends State<StockSummaryReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Summary Report'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportReport(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('stock_inventory')
            .where('userId', isEqualTo: widget.businessId)
            .snapshots(),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No stock data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add items to your inventory to see stock levels',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final stocks = snapshot.data!.docs;
          int lowStockCount = 0;

          // Calculate low stock count
          for (var doc in stocks) {
            try {
              final stock = StockInventory.fromFirestore(doc);
              if (stock.currentStock <= stock.minimumStockLevel) {
                lowStockCount++;
              }
            } catch (e) {
              debugPrint('Error parsing stock: $e');
            }
          }

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Items', '${stocks.length}', Icons.inventory_2),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white30,
                    ),
                    _buildSummaryItem('Low Stock', '$lowStockCount', Icons.warning_amber_rounded),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white30,
                    ),
                    _buildSummaryItem('Good Stock', '${stocks.length - lowStockCount}', Icons.check_circle),
                  ],
                ),
              ),

              // Filter/Sort Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Stock Items',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Stock List
              Expanded(
                child: stocks.isEmpty
                    ? const Center(
                  child: Text('No stock items found'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    try {
                      final stock = StockInventory.fromFirestore(stocks[index]);
                      return _buildStockCard(context, stock);
                    } catch (e) {
                      debugPrint('Error building stock card: $e');
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStockCard(BuildContext context, StockInventory stock) {
    final isLowStock = stock.currentStock <= stock.minimumStockLevel;
    final stockPercentage = stock.minimumStockLevel > 0
        ? (stock.currentStock / stock.minimumStockLevel * 100).clamp(0, 100)
        : 100.0;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('items').doc(stock.itemId).get(),
      builder: (context, itemSnapshot) {
        String itemName = 'Loading...';
        String itemCode = '';
        String unit = '';

        if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
          try {
            final item = ItemMaster.fromFirestore(itemSnapshot.data!);
            itemName = item.description.isNotEmpty ? item.description : 'Unnamed Item';
            itemCode = item.itemCode;
            unit = item.unitOfMeasurement;
          } catch (e) {
            itemName = 'Error loading item';
            debugPrint('Error loading item: $e');
          }
        } else if (itemSnapshot.hasError) {
          itemName = 'Error loading item';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isLowStock ? Colors.orange.shade200 : Colors.transparent,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isLowStock
                  ? LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory,
                          color: isLowStock ? Colors.orange : Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (itemCode.isNotEmpty)
                              Text(
                                'Code: $itemCode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLowStock ? Colors.orange : Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isLowStock ? 'LOW STOCK' : 'IN STOCK',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Location: ${stock.location}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Stock Quantity
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stock.currentStock.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.orange : Colors.green,
                            ),
                          ),
                          Text(
                            unit.isNotEmpty ? unit : 'units',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Min: ${stock.minimumStockLevel.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stock Level Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock Level',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${stockPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLowStock ? Colors.orange : Colors.green,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Fetch stock data
      final stockSnapshot = await _firestore
          .collection('stock_inventory')
          .where('userId', isEqualTo: widget.businessId)
          .get();

      if (stockSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No stock data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final stocks = stockSnapshot.docs
          .map((doc) {
        try {
          return StockInventory.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing stock: $e');
          return null;
        }
      })
          .where((stock) => stock != null)
          .cast<StockInventory>()
          .toList();

      // Fetch items
      final itemSnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: widget.businessId)
          .where('isActive', isEqualTo: true)
          .get();

      final items = itemSnapshot.docs
          .map((doc) {
        try {
          return ItemMaster.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing item: $e');
          return null;
        }
      })
          .where((item) => item != null)
          .cast<ItemMaster>()
          .toList();

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show export options
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Export Stock Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ),
                    title: const Text('Download PDF'),
                    subtitle: const Text('Save stock report as PDF'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.generateAndDownloadAllStockPDF(stocks, items);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stock Report PDF downloaded!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share, color: Colors.blue),
                    ),
                    title: const Text('Share PDF'),
                    subtitle: const Text('Share via email, WhatsApp, etc.'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.shareAllStockPDF(stocks, items);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stock Report PDF shared!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.print, color: Colors.orange),
                    ),
                    title: const Text('Print PDF'),
                    subtitle: const Text('Send to printer'),
                    onTap: () async {
                      Navigator.pop(bc);
                      await PDFUtils.printAllStockPDF(stocks, items);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stock Report sent to printer!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error exporting report: $e');
    }
  }
}