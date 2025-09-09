import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/stock_inventory.dart';

class StockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if sufficient stock is available
  static Future<bool> checkStockAvailability(String itemId, double requiredQuantity) async {
    try {
      final stockQuery = await _firestore
          .collection('stock_inventory')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (stockQuery.docs.isEmpty) return false;

      double totalStock = 0;
      for (var doc in stockQuery.docs) {
        final stock = StockInventory.fromFirestore(doc);
        totalStock += stock.currentStock;
      }

      return totalStock >= requiredQuantity;
    } catch (e) {
      print('Error checking stock availability: $e');
      return false;
    }
  }

  // Update stock after sale
  static Future<bool> updateStockAfterSale(String itemId, double soldQuantity) async {
    try {
      final stockQuery = await _firestore
          .collection('stock_inventory')
          .where('itemId', isEqualTo: itemId)
          .orderBy('currentStock', descending: true)
          .get();

      if (stockQuery.docs.isEmpty) return false;

      double remainingToDeduct = soldQuantity;

      for (var doc in stockQuery.docs) {
        if (remainingToDeduct <= 0) break;

        final stock = StockInventory.fromFirestore(doc);
        double deductFromThis = remainingToDeduct > stock.currentStock
            ? stock.currentStock
            : remainingToDeduct;

        await doc.reference.update({
          'currentStock': stock.currentStock - deductFromThis,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        remainingToDeduct -= deductFromThis;
      }

      // Log stock movement
      await _firestore.collection('stock_movements').add({
        'itemId': itemId,
        'movementType': 'OUT',
        'quantity': soldQuantity,
        'reason': 'Sale',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return remainingToDeduct <= 0;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // Get current stock level for an item
  static Future<double> getCurrentStockLevel(String itemId) async {
    try {
      final stockQuery = await _firestore
          .collection('stock_inventory')
          .where('itemId', isEqualTo: itemId)
          .get();

      double totalStock = 0;
      for (var doc in stockQuery.docs) {
        final stock = StockInventory.fromFirestore(doc);
        totalStock += stock.currentStock;
      }

      return totalStock;
    } catch (e) {
      print('Error getting stock level: $e');
      return 0;
    }
  }

  // Add stock (for purchases or adjustments)
  static Future<void> addStock(String businessId, String itemId, String location, double quantity) async {
    try {
      // Check if stock record exists for this item and location
      final existingStock = await _firestore
          .collection('stock_inventory')
          .where('businessId', isEqualTo: businessId)
          .where('itemId', isEqualTo: itemId)
          .where('location', isEqualTo: location)
          .limit(1)
          .get();

      if (existingStock.docs.isNotEmpty) {
        // Update existing stock
        final doc = existingStock.docs.first;
        final currentStock = (doc.data()['currentStock'] ?? 0.0).toDouble();

        await doc.reference.update({
          'currentStock': currentStock + quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new stock record
        await _firestore.collection('stock_inventory').add({
          'businessId': businessId,
          'itemId': itemId,
          'location': location,
          'currentStock': quantity,
          'minimumStockLevel': 0.0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Log stock movement
      await _firestore.collection('stock_movements').add({
        'businessId': businessId,
        'itemId': itemId,
        'movementType': 'IN',
        'quantity': quantity,
        'reason': 'Stock Addition',
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding stock: $e');
      throw e;
    }
  }
}
