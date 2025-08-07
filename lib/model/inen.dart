// // Data Models with improved dynamic data handling
// import 'package:cloud_firestore/cloud_firestore.dart';
//
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ItemMaster {
//   final String id;
//   final String businessId;
//   final String userId;
//   final String itemCode;
//   final String description;
//   final String hsnSacCode;
//   final String unitOfMeasurement;
//   final double cgstRate;
//   final double sgstRate;
//   final double igstRate;
//   final double cessRate;
//   final double sellingPrice;
//   final double costPrice;
//   final double profitMargin;
//   final bool isActive;
//   final DateTime createdAt;
//
//   ItemMaster({
//     required this.id,
//     required this.businessId,
//     required this.userId,
//     required this.itemCode,
//     required this.description,
//     required this.hsnSacCode,
//     required this.unitOfMeasurement,
//     required this.cgstRate,
//     required this.sgstRate,
//     required this.igstRate,
//     required this.cessRate,
//     required this.sellingPrice,
//     required this.costPrice,
//     required this.profitMargin,
//     required this.isActive,
//     required this.createdAt,
//   });
//
//   factory ItemMaster.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data();
//     if (data == null) {
//       throw Exception('Document data is null');
//     }
//     final Map<String, dynamic> map = data as Map<String, dynamic>;
//
//     return ItemMaster(
//       id: doc.id,
//       businessId: _getStringValue(map, 'businessId'),
//       userId: _getStringValue(map, 'userId'),
//       itemCode: _getStringValue(map, 'itemCode'),
//       description: _getStringValue(map, 'description'),
//       hsnSacCode: _getStringValue(map, 'hsnSacCode'),
//       unitOfMeasurement: _getStringValue(map, 'unitOfMeasurement'),
//       cgstRate: _getDoubleValue(map, 'cgstRate'),
//       sgstRate: _getDoubleValue(map, 'sgstRate'),
//       igstRate: _getDoubleValue(map, 'igstRate'),
//       cessRate: _getDoubleValue(map, 'cessRate'),
//       sellingPrice: _getDoubleValue(map, 'sellingPrice'),
//       costPrice: _getDoubleValue(map, 'costPrice'),
//       profitMargin: _getDoubleValue(map, 'profitMargin'),
//       isActive: _getBoolValue(map, 'isActive'),
//       createdAt: _getDateTimeValue(map, 'createdAt'),
//     );
//   }
//
//   static String _getStringValue(Map<String, dynamic> map, String key) {
//     final value = map[key];
//     if (value == null) return '';
//     return value.toString();
//   }
//
//   static double _getDoubleValue(Map<String, dynamic> map, String key) {
//     final value = map[key];
//     if (value == null) return 0.0;
//     if (value is num) return value.toDouble();
//     if (value is String) return double.tryParse(value) ?? 0.0;
//     return 0.0;
//   }
//
//   static bool _getBoolValue(Map<String, dynamic> map, String key) {
//     final value = map[key];
//     if (value == null) return true;
//     if (value is bool) return value;
//     if (value is String) return value.toLowerCase() == 'true';
//     return true;
//   }
//
//   static DateTime _getDateTimeValue(Map<String, dynamic> map, String key) {
//     final value = map[key];
//     if (value == null) return DateTime.now();
//     if (value is Timestamp) return value.toDate();
//     if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
//     return DateTime.now();
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'businessId': businessId,
//       'userId': userId,
//       'itemCode': itemCode,
//       'description': description,
//       'hsnSacCode': hsnSacCode,
//       'unitOfMeasurement': unitOfMeasurement,
//       'cgstRate': cgstRate,
//       'sgstRate': sgstRate,
//       'igstRate': igstRate,
//       'cessRate': cessRate,
//       'sellingPrice': sellingPrice,
//       'costPrice': costPrice,
//       'profitMargin': profitMargin,
//       'isActive': isActive,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': FieldValue.serverTimestamp(),
//     };
//   }
// }
//
//
//
// class StockInventory {
//   final String id;
//   final String businessId;
//   final String itemId;
//   final String location;
//   final double currentStock;
//   final double minimumStockLevel;
//   final DateTime lastUpdated;
//
//   StockInventory({
//     required this.id,
//     required this.businessId,
//     required this.itemId,
//     required this.location,
//     required this.currentStock,
//     required this.minimumStockLevel,
//     required this.lastUpdated,
//   });
//
//   factory StockInventory.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data();
//     if (data == null) {
//       throw Exception('Document data is null');
//     }
//
//     final Map<String, dynamic> map = data as Map<String, dynamic>;
//
//     return StockInventory(
//       id: doc.id,
//       businessId: ItemMaster._getStringValue(map, 'businessId'),
//       itemId: ItemMaster._getStringValue(map, 'itemId'),
//       location: ItemMaster._getStringValue(map, 'location'),
//       currentStock: ItemMaster._getDoubleValue(map, 'currentStock'),
//       minimumStockLevel: ItemMaster._getDoubleValue(map, 'minimumStockLevel'),
//       lastUpdated: ItemMaster._getDateTimeValue(map, 'lastUpdated'),
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'businessId': businessId,
//       'itemId': itemId,
//       'location': location,
//       'currentStock': currentStock,
//       'minimumStockLevel': minimumStockLevel,
//       'lastUpdated': Timestamp.fromDate(lastUpdated),
//     };
//   }
// }