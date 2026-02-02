import 'package:cloud_firestore/cloud_firestore.dart';

class ItemMaster {
  final String id;
  final String businessId;
  final String userId;
  final String itemCode;
  final String description;
  final String hsnSacCode;
  final String unitOfMeasurement;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final double sellingPrice;
  final double costPrice;
  final double profitMargin;
  final bool isActive;
  final DateTime createdAt;

  ItemMaster({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.itemCode,
    required this.description,
    required this.hsnSacCode,
    required this.unitOfMeasurement,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cessRate,
    required this.sellingPrice,
    required this.costPrice,
    required this.profitMargin,
    required this.isActive,
    required this.createdAt,
  });

  factory ItemMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    return ItemMaster(
      id: doc.id,
      businessId: getStringValue(map, 'businessId'),
      userId: getStringValue(map, 'userId'),
      itemCode: getStringValue(map, 'itemCode'),
      description: getStringValue(map, 'description'),
      hsnSacCode: getStringValue(map, 'hsnSacCode'),
      unitOfMeasurement: getStringValue(map, 'unitOfMeasurement'),
      cgstRate: getDoubleValue(map, 'cgstRate'),
      sgstRate: getDoubleValue(map, 'sgstRate'),
      igstRate: getDoubleValue(map, 'igstRate'),
      cessRate: getDoubleValue(map, 'cessRate'),
      sellingPrice: getDoubleValue(map, 'sellingPrice'),
      costPrice: getDoubleValue(map, 'costPrice'),
      profitMargin: getDoubleValue(map, 'profitMargin'),
      isActive: getBoolValue(map, 'isActive'),
      createdAt: getDateTimeValue(map, 'createdAt'),
    );
  }

  static String getStringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return '';
    return value.toString();
  }

  static double getDoubleValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool getBoolValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return true;
  }

  static DateTime getDateTimeValue(Map<String, dynamic> map, String key) {
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
      'itemCode': itemCode,
      'description': description,
      'hsnSacCode': hsnSacCode,
      'unitOfMeasurement': unitOfMeasurement,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,
      'cessRate': cessRate,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'profitMargin': profitMargin,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}