import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safetyzoness/screens/inventory_management.dart'; // To access ItemMaster's static helpers

/// Represents an individual item within a sale, including its quantity, price, and tax breakdown.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safetyzoness/screens/inventory_management.dart';

/// Updated SaleItem with GST-specific fields
class SaleItem {
  final String itemId;
  final String itemCode;
  final String description;
  final String hsnSacCode;
  final String unitOfMeasurement;
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
  final double itemTotal;

  // NEW GST FIELDS
  final String supplyType; // 'INTRA' or 'INTER'
  final bool isNilRated; // For GSTR-1 Section 8
  final bool isExempt; // For GSTR-1 Section 8
  final bool isNonGST; // For GSTR-1 Section 8

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
    // NEW FIELDS
    this.supplyType = 'INTRA',
    this.isNilRated = false,
    this.isExempt = false,
    this.isNonGST = false,
  });

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
      // NEW FIELDS
      supplyType: ItemMaster.getStringValue(map, 'supplyType').isEmpty ? 'INTRA' : ItemMaster.getStringValue(map, 'supplyType'),
      isNilRated: ItemMaster.getBoolValue(map, 'isNilRated'),
      isExempt: ItemMaster.getBoolValue(map, 'isExempt'),
      isNonGST: ItemMaster.getBoolValue(map, 'isNonGST'),
    );
  }

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
      // NEW FIELDS
      'supplyType': supplyType,
      'isNilRated': isNilRated,
      'isExempt': isExempt,
      'isNonGST': isNonGST,
    };
  }
}

/// Updated SaleMaster with GST-specific fields
class SaleMaster {
  final String id;
  final String businessId;
  final String invoice;
  final String customerName;
  final DateTime date;
  final double total;
  final List<SaleItem> items;

  // NEW GST FIELDS
  final String recipientGSTIN; // Customer GSTIN
  final String placeOfSupply; // POS - State code
  final String supplyType; // 'INTRA' or 'INTER' state
  final String saleType; // 'CASH' or 'CREDIT'
  final String gstr1Section; // B2B, B2C_LARGE, B2C_SMALL, EXPORT, etc.
  final String? eWayBillNo; // For goods transport
  final String? transportMode; // Road, Rail, Air, Ship
  final double? distance; // Transport distance
  final String documentType; // INV, DBN, CDN, etc.
  final bool isReverseCharge; // For B2B transactions
  final String? originalInvoiceNo; // For credit/debit notes
  final DateTime? originalInvoiceDate; // For credit/debit notes

  SaleMaster({
    required this.id,
    required this.businessId,
    required this.invoice,
    required this.customerName,
    required this.date,
    required this.total,
    required this.items,
    // NEW REQUIRED FIELDS
    this.recipientGSTIN = '',
    this.placeOfSupply = '',
    this.supplyType = 'INTRA',
    this.saleType = 'CASH',
    this.gstr1Section = 'B2C_SMALL',
    this.eWayBillNo,
    this.transportMode,
    this.distance,
    this.documentType = 'INV',
    this.isReverseCharge = false,
    this.originalInvoiceNo,
    this.originalInvoiceDate,
  });

  factory SaleMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    final Map<String, dynamic> map = data as Map<String, dynamic>;

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
      items: parsedItems,
      // NEW FIELDS
      recipientGSTIN: ItemMaster.getStringValue(map, 'recipientGSTIN'),
      placeOfSupply: ItemMaster.getStringValue(map, 'placeOfSupply'),
      supplyType: ItemMaster.getStringValue(map, 'supplyType').isEmpty ? 'INTRA' : ItemMaster.getStringValue(map, 'supplyType'),
      saleType: ItemMaster.getStringValue(map, 'saleType').isEmpty ? 'CASH' : ItemMaster.getStringValue(map, 'saleType'),
      gstr1Section: ItemMaster.getStringValue(map, 'gstr1Section').isEmpty ? 'B2C_SMALL' : ItemMaster.getStringValue(map, 'gstr1Section'),
      eWayBillNo: map['eWayBillNo'] as String?,
      transportMode: map['transportMode'] as String?,
      distance: ItemMaster.getDoubleValue(map, 'distance') == 0 ? null : ItemMaster.getDoubleValue(map, 'distance'),
      documentType: ItemMaster.getStringValue(map, 'documentType').isEmpty ? 'INV' : ItemMaster.getStringValue(map, 'documentType'),
      isReverseCharge: ItemMaster.getBoolValue(map, 'isReverseCharge'),
      originalInvoiceNo: map['originalInvoiceNo'] as String?,
      originalInvoiceDate: map['originalInvoiceDate'] != null ? ItemMaster.getDateTimeValue(map, 'originalInvoiceDate') : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'invoice': invoice,
      'customerName': customerName,
      'date': Timestamp.fromDate(date),
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
      // NEW FIELDS
      'recipientGSTIN': recipientGSTIN,
      'placeOfSupply': placeOfSupply,
      'supplyType': supplyType,
      'saleType': saleType,
      'gstr1Section': gstr1Section,
      'eWayBillNo': eWayBillNo,
      'transportMode': transportMode,
      'distance': distance,
      'documentType': documentType,
      'isReverseCharge': isReverseCharge,
      'originalInvoiceNo': originalInvoiceNo,
      'originalInvoiceDate': originalInvoiceDate != null ? Timestamp.fromDate(originalInvoiceDate!) : null,
    };
  }

  // Helper method to determine GSTR-1 section based on sale data
  String determineGSTR1Section() {
    if (recipientGSTIN.isNotEmpty) {
      return 'B2B'; // Section 4A, 4B, 6B, 6C
    } else if (total > 250000) {
      return 'B2C_LARGE'; // Section 5
    } else {
      return 'B2C_SMALL'; // Section 7
    }
  }
}

/// Represents a complete sale transaction.
// class SaleMaster {
//   final String id;
//   final String businessId;
//   final String invoice;
//   final String customerName;
//   final DateTime date;
//   final double total;
//   final List<SaleItem> items; // New field: list of items included in this sale
//
//   SaleMaster({
//     required this.id,
//     required this.businessId,
//     required this.invoice,
//     required this.customerName,
//     required this.date,
//     required this.total,
//     required this.items,
//   });
//
//   /// Creates a SaleMaster instance from a Firestore DocumentSnapshot.
//   factory SaleMaster.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data();
//     if (data == null) {
//       throw Exception('Document data is null');
//     }
//     final Map<String, dynamic> map = data as Map<String, dynamic>;
//
//     // Parse the list of items from the Firestore map
//     final List<dynamic> itemsData = map['items'] as List<dynamic>? ?? [];
//     final List<SaleItem> parsedItems = itemsData
//         .map((itemMap) => SaleItem.fromMap(itemMap as Map<String, dynamic>))
//         .toList();
//
//     return SaleMaster(
//       id: doc.id,
//       businessId: ItemMaster.getStringValue(map, 'businessId'),
//       invoice: ItemMaster.getStringValue(map, 'invoice'),
//       customerName: ItemMaster.getStringValue(map, 'customerName'),
//       date: ItemMaster.getDateTimeValue(map, 'date'),
//       total: ItemMaster.getDoubleValue(map, 'total'),
//       items: parsedItems, // Assign the parsed items
//     );
//   }
//
//   /// Converts the SaleMaster instance to a map for Firestore storage.
//   Map<String, dynamic> toFirestore() {
//     return {
//       'businessId': businessId,
//       'invoice': invoice,
//       'customerName': customerName,
//       'date': Timestamp.fromDate(date),
//       'total': total,
//       'items': items.map((item) => item.toMap()).toList(), // Convert items to map list
//     };
//   }
// }
