import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safetyzoness/screens/inventory_management.dart'; // To access ItemMaster's static helpers

/// Represents an individual item within a sale, including its quantity, price, and tax breakdown.
class SaleItem {
  final String itemId;
  final String itemCode;
  final String description; // Item description
  final String hsnSacCode; // HSN/SAC Code
  final String unitOfMeasurement; // UQC
  final double quantity;
  final double sellingPricePerUnit;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final double totalTaxableValue;
  final double integratedTaxAmount;
  final double centralTaxAmount;
  final double stateTaxAmount;
  final double cessAmount;
  final double itemTotal; // total including tax for this item

  SaleItem({
    required this.itemId,
    required this.itemCode,
    required this.description,
    required this.hsnSacCode,
    required this.unitOfMeasurement,
    required this.quantity,
    required this.sellingPricePerUnit,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cessRate,
    required this.totalTaxableValue,
    required this.integratedTaxAmount,
    required this.centralTaxAmount,
    required this.stateTaxAmount,
    required this.cessAmount,
    required this.itemTotal,
  });

  /// Creates a SaleItem instance from a map (e.g., from Firestore).
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      itemId: ItemMaster.getStringValue(map, 'itemId'),
      itemCode: ItemMaster.getStringValue(map, 'itemCode'),
      description: ItemMaster.getStringValue(map, 'description'),
      hsnSacCode: ItemMaster.getStringValue(map, 'hsnSacCode'),
      unitOfMeasurement: ItemMaster.getStringValue(map, 'unitOfMeasurement'),
      quantity: ItemMaster.getDoubleValue(map, 'quantity'),
      sellingPricePerUnit: ItemMaster.getDoubleValue(map, 'sellingPricePerUnit'),
      cgstRate: ItemMaster.getDoubleValue(map, 'cgstRate'),
      sgstRate: ItemMaster.getDoubleValue(map, 'sgstRate'),
      igstRate: ItemMaster.getDoubleValue(map, 'igstRate'),
      cessRate: ItemMaster.getDoubleValue(map, 'cessRate'),
      totalTaxableValue: ItemMaster.getDoubleValue(map, 'totalTaxableValue'),
      integratedTaxAmount: ItemMaster.getDoubleValue(map, 'integratedTaxAmount'),
      centralTaxAmount: ItemMaster.getDoubleValue(map, 'centralTaxAmount'),
      stateTaxAmount: ItemMaster.getDoubleValue(map, 'stateTaxAmount'),
      cessAmount: ItemMaster.getDoubleValue(map, 'cessAmount'),
      itemTotal: ItemMaster.getDoubleValue(map, 'itemTotal'),
    );
  }

  /// Converts the SaleItem instance to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'description': description,
      'hsnSacCode': hsnSacCode,
      'unitOfMeasurement': unitOfMeasurement,
      'quantity': quantity,
      'sellingPricePerUnit': sellingPricePerUnit,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,
      'cessRate': cessRate,
      'totalTaxableValue': totalTaxableValue,
      'integratedTaxAmount': integratedTaxAmount,
      'centralTaxAmount': centralTaxAmount,
      'stateTaxAmount': stateTaxAmount,
      'cessAmount': cessAmount,
      'itemTotal': itemTotal,
    };
  }
}

/// Represents a complete sale transaction.
class SaleMaster {
  final String id;
  final String businessId;
  final String invoice;
  final String customerName;
  final DateTime date;
  final double total;
  final List<SaleItem> items; // New field: list of items included in this sale

  SaleMaster({
    required this.id,
    required this.businessId,
    required this.invoice,
    required this.customerName,
    required this.date,
    required this.total,
    required this.items,
  });

  /// Creates a SaleMaster instance from a Firestore DocumentSnapshot.
  factory SaleMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    // Parse the list of items from the Firestore map
    final List<dynamic> itemsData = map['items'] as List<dynamic>? ?? [];
    final List<SaleItem> parsedItems = itemsData
        .map((itemMap) => SaleItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return SaleMaster(
      id: doc.id,
      businessId: ItemMaster.getStringValue(map, 'businessId'),
      invoice: ItemMaster.getStringValue(map, 'invoice'),
      customerName: ItemMaster.getStringValue(map, 'customerName'),
      date: ItemMaster.getDateTimeValue(map, 'date'),
      total: ItemMaster.getDoubleValue(map, 'total'),
      items: parsedItems, // Assign the parsed items
    );
  }

  /// Converts the SaleMaster instance to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'invoice': invoice,
      'customerName': customerName,
      'date': Timestamp.fromDate(date),
      'total': total,
      'items': items.map((item) => item.toMap()).toList(), // Convert items to map list
    };
  }
}
