import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../inventory_management.dart';

class ValuationReportScreen extends StatelessWidget {
  final String businessId;

  const ValuationReportScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Valuation Report'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _calculateInventoryValuation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final valuationData = snapshot.data ?? [];

          if (valuationData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No inventory data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          double totalValue = valuationData.fold(0, (sum, item) => sum + item['totalValue']);

          return Column(
            children: [
              // Total Value Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Inventory Value',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${valuationData.length} items',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Valuation List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: valuationData.length,
                  itemBuilder: (context, index) {
                    final item = valuationData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance, color: Colors.purple),
                        ),
                        title: Text(
                          item['itemName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Stock: ${item['stock'].toStringAsFixed(1)} × ₹${item['costPrice'].toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Text(
                          '₹${item['totalValue'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple,
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
    );
  }

  Future<List<Map<String, dynamic>>> _calculateInventoryValuation() async {
    final stockSnapshot = await FirebaseFirestore.instance
        .collection('stock_inventory')
        .where('businessId', isEqualTo: businessId)
        .get();

    List<Map<String, dynamic>> valuationData = [];

    for (var doc in stockSnapshot.docs) {
      try {
        final data = doc.data();
        final itemId = ItemMaster.getStringValue(data, 'itemId');
        final currentStock = ItemMaster.getDoubleValue(data, 'currentStock');

        final itemDoc = await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .get();

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
        debugPrint('Error calculating valuation: $e');
      }
    }

    // Sort by total value descending
    valuationData.sort((a, b) => b['totalValue'].compareTo(a['totalValue']));

    return valuationData;
  }
}