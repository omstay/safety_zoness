import 'package:cloud_firestore/cloud_firestore.dart';

class StockInventory {
  final String id;
  final String businessId;
  final String userId;
  final String itemId;
  final String location;
  final double currentStock;
  final double minimumStockLevel;
  final DateTime lastUpdated;

  StockInventory({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.itemId,
    required this.location,
    required this.currentStock,
    required this.minimumStockLevel,
    required this.lastUpdated,
  });

  factory StockInventory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    return StockInventory(
      id: doc.id,
      businessId: _getStringValue(map, 'businessId'),
      userId: _getStringValue(map, 'userId'),
      itemId: _getStringValue(map, 'itemId'),
      location: _getStringValue(map, 'location'),
      currentStock: _getDoubleValue(map, 'currentStock'),
      minimumStockLevel: _getDoubleValue(map, 'minimumStockLevel'),
      lastUpdated: _getDateTimeValue(map, 'lastUpdated'),
    );
  }

  // Helper methods for safe data extraction
  static String _getStringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  static double _getDoubleValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _getDateTimeValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'userId': userId,
      'itemId': itemId,
      'location': location,
      'currentStock': currentStock,
      'minimumStockLevel': minimumStockLevel,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
