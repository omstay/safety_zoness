import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/item_master.dart';
import '../services/user_service.dart';

class ReportsTab extends StatefulWidget {
  final String businessId;

  const ReportsTab({super.key, required this.businessId});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get insights into your business performance',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Cards Row
          Row(
            children: [
              Expanded(child: _buildSummaryCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLowStockCard()),
            ],
          ),
          const SizedBox(height: 24),

          // Reports List
          Expanded(
            child: ListView(
              children: [
                _buildReportCard(
                  'Sales Performance',
                  'Track sales trends and revenue',
                  Icons.trending_up,
                  const Color(0xFF4CAF50),
                      () => _showSalesReport(context),
                ),
                _buildReportCard(
                  'Stock Summary',
                  'Overview of current stock levels',
                  Icons.inventory,
                  const Color(0xFF2196F3),
                      () => _showStockSummaryReport(context),
                ),
                _buildReportCard(
                  'Low Stock Alert',
                  'Items running low on stock',
                  Icons.warning,
                  const Color(0xFFFF9800),
                      () => _showLowStockReport(context),
                ),
                _buildReportCard(
                  'Profit Analysis',
                  'Analyze profit margins by item',
                  Icons.show_chart,
                  const Color(0xFFE91E63),
                      () => _showProfitAnalysisReport(context),
                ),
                _buildReportCard(
                  'Inventory Valuation',
                  'Total inventory value assessment',
                  Icons.account_balance,
                  const Color(0xFF9C27B0),
                      () => _showValuationReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .where('businessId', isEqualTo: widget.businessId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int totalItems = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Total Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                totalItems.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLowStockCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('stock_inventory')
          .where('businessId', isEqualTo: widget.businessId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildSummaryCardSkeleton();
        }

        int lowStockCount = 0;
        for (var doc in snapshot.data!.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
            final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
            if (currentStock <= minStock) {
              lowStockCount++;
            }
          } catch (e) {
            // Handle parsing errors
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: lowStockCount > 0
                  ? [const Color(0xFFFF9800), const Color(0xFFF57C00)]
                  : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (lowStockCount > 0 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    lowStockCount > 0 ? Icons.warning : Icons.check_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lowStockCount.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.grey.shade400, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '0',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_forward_ios, size: 18, color: color),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showSalesReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Sales Performance Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('sales')
                .where('businessId', isEqualTo: widget.businessId)
                .orderBy('date', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No sales data available'),
                    ],
                  ),
                );
              }

              double totalSales = 0;
              final salesData = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final total = ItemMaster.getDoubleValue(data, 'total');
                totalSales += total;
                return data;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Sales (Last 10):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${totalSales.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: salesData.length,
                      itemBuilder: (context, index) {
                        final sale = salesData[index];
                        final customerName = ItemMaster.getStringValue(sale, 'customerName');
                        final invoice = ItemMaster.getStringValue(sale, 'invoice');
                        final total = ItemMaster.getDoubleValue(sale, 'total');
                        final date = ItemMaster.getDateTimeValue(sale, 'date');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.receipt, color: Color(0xFF4CAF50)),
                            title: Text(customerName.isNotEmpty ? customerName : 'Unknown Customer'),
                            subtitle: Text('Invoice: $invoice\nDate: ${DateFormat('dd MMM yyyy').format(date)}'),
                            trailing: Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStockSummaryReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Stock Summary Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No stock data available'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = ItemMaster.getStringValue(data, 'itemId');
                  final location = ItemMaster.getStringValue(data, 'location');
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
                  final isLowStock = currentStock <= minStock;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('items').doc(itemId).get(),
                    builder: (context, itemSnapshot) {
                      String itemName = 'Unknown Item';
                      if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                        try {
                          final item = ItemMaster.fromFirestore(itemSnapshot.data!);
                          itemName = item.description.isNotEmpty ? item.description : 'Unnamed Item';
                        } catch (e) {
                          itemName = 'Error loading item';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.inventory,
                            color: isLowStock ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                          ),
                          title: Text(itemName),
                          subtitle: Text('Location: $location'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Stock: ${currentStock.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                                ),
                              ),
                              Text(
                                'Min: ${minStock.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLowStockReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFFF9800)),
            SizedBox(width: 8),
            Text('Low Stock Alert Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final lowStockItems = snapshot.data!.docs.where((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
                  return currentStock <= minStock;
                } catch (e) {
                  return false;
                }
              }).toList();

              if (lowStockItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Color(0xFF4CAF50)),
                      SizedBox(height: 16),
                      Text(
                        'All items are well stocked!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: lowStockItems.length,
                itemBuilder: (context, index) {
                  final doc = lowStockItems[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final itemId = ItemMaster.getStringValue(data, 'itemId');
                  final location = ItemMaster.getStringValue(data, 'location');
                  final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
                  final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('items').doc(itemId).get(),
                    builder: (context, itemSnapshot) {
                      String itemName = 'Unknown Item';
                      if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                        try {
                          final item = ItemMaster.fromFirestore(itemSnapshot.data!);
                          itemName = item.description.isNotEmpty ? item.description : 'Unnamed Item';
                        } catch (e) {
                          itemName = 'Error loading item';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: Color(0xFFFF9800),
                          ),
                          title: Text(itemName),
                          subtitle: Text('Location: $location'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Stock: ${currentStock.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                              Text(
                                'Min: ${minStock.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfitAnalysisReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.show_chart, color: Color(0xFFE91E63)),
            SizedBox(width: 8),
            Text('Profit Analysis Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('items')
                .where('businessId', isEqualTo: widget.businessId)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No items available for profit analysis'),
                    ],
                  ),
                );
              }

              final items = snapshot.data!.docs.map((doc) {
                try {
                  return ItemMaster.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              }).where((item) => item != null).cast<ItemMaster>().toList();

              items.sort((a, b) => b.profitMargin.compareTo(a.profitMargin));

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final profitPerUnit = item.sellingPrice - item.costPrice;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.show_chart,
                        color: item.profitMargin > 20 ? const Color(0xFF4CAF50) :
                        item.profitMargin > 10 ? const Color(0xFFFF9800) : Colors.red,
                      ),
                      title: Text(item.description.isNotEmpty ? item.description : 'Unnamed Item'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cost: ₹${item.costPrice.toStringAsFixed(2)} | Selling: ₹${item.sellingPrice.toStringAsFixed(2)}'),
                          Text('Profit per unit: ₹${profitPerUnit.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.profitMargin > 20 ? const Color(0xFF4CAF50).withOpacity(0.1) :
                          item.profitMargin > 10 ? const Color(0xFFFF9800).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.profitMargin > 20 ? const Color(0xFF4CAF50) :
                            item.profitMargin > 10 ? const Color(0xFFFF9800) : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showValuationReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('Inventory Valuation Report'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('stock_inventory')
                .where('businessId', isEqualTo: widget.businessId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storage_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No stock data available for valuation'),
                    ],
                  ),
                );
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _calculateInventoryValuation(snapshot.data!.docs),
                builder: (context, valuationSnapshot) {
                  if (!valuationSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final valuationData = valuationSnapshot.data!;
                  double totalValue = 0;
                  for (var item in valuationData) {
                    totalValue += item['totalValue'] as double;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Inventory Value:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9C27B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: valuationData.length,
                          itemBuilder: (context, index) {
                            final item = valuationData[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.account_balance, color: Color(0xFF9C27B0)),
                                title: Text(item['itemName']),
                                subtitle: Text(
                                  'Stock: ${item['stock']} × ₹${item['costPrice'].toStringAsFixed(2)}',
                                ),
                                trailing: Text(
                                  '₹${item['totalValue'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9C27B0),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _calculateInventoryValuation(List<QueryDocumentSnapshot> stockDocs) async {
    List<Map<String, dynamic>> valuationData = [];

    for (var doc in stockDocs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final itemId = ItemMaster.getStringValue(data, 'itemId');
        final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');

        final itemDoc = await _firestore.collection('items').doc(itemId).get();
        if (itemDoc.exists) {
          final item = ItemMaster.fromFirestore(itemDoc);
          final totalValue = currentStock * item.costPrice;

          valuationData.add({
            'itemName': item.description.isNotEmpty ? item.description : 'Unnamed Item',
            'stock': currentStock,
            'costPrice': item.costPrice,
            'totalValue': totalValue,
          });
        }
      } catch (e) {
        print('Error calculating valuation for item: $e');
      }
    }

    return valuationData;
  }
}
