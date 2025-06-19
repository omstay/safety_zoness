import 'package:cloud_firestore/cloud_firestore.dart';

class SaleMaster {
  final String id;
  final String businessId;
  final String customerName;
  final String invoiceNumber;
  final DateTime saleDate;
  final double totalAmount;
  final bool isActive;

  SaleMaster({
    required this.id,
    required this.businessId,
    required this.customerName,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    this.isActive = true,
  });

  // Factory method to create from Firestore
  factory SaleMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleMaster(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      customerName: data['customerName'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'customerName': customerName,
      'invoiceNumber': invoiceNumber,
      'saleDate': Timestamp.fromDate(saleDate),
      'totalAmount': totalAmount,
      'isActive': isActive,
    };
  }
}
