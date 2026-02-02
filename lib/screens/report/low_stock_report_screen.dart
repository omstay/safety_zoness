import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../inventory_management.dart';

class LowStockReportScreen extends StatelessWidget {
  final String businessId;

  const LowStockReportScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alert Report'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stock_inventory')
            .where('businessId', isEqualTo: businessId)
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
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All items are well stocked!',
                      style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          // Filter low stock items
          final lowStockDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
            final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
            return currentStock <= minStock;
          }).toList();

          if (lowStockDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All items are well stocked!',
                      style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Warning Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Low Stock Alert!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '${lowStockDocs.length} items need restocking',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Low Stock List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lowStockDocs.length,
                  itemBuilder: (context, index) {
                    final data = lowStockDocs[index].data() as Map<String, dynamic>;
                    return _buildLowStockCard(data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLowStockCard(Map<String, dynamic> data) {
    final itemId = ItemMaster.getStringValue(data, 'itemId');
    final location = ItemMaster.getStringValue(data, 'location');
    final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');
    final minStock = ItemMaster.getDoubleValue(data, 'minimumStockLevel');
    final deficit = minStock - currentStock;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('items').doc(itemId).get(),
      builder: (context, itemSnapshot) {
        String itemName = 'Loading...';
        if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
          try {
            final item = ItemMaster.fromFirestore(itemSnapshot.data!);
            itemName = item.description;
          } catch (e) {
            itemName = 'Error';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.orange.shade50,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Location: $location',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStockInfo('Current', currentStock.toStringAsFixed(1), Colors.orange),
                      _buildStockInfo('Minimum', minStock.toStringAsFixed(1), Colors.grey),
                      _buildStockInfo('Need', deficit.toStringAsFixed(1), Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}