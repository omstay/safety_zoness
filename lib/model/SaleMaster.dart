import 'package:cloud_firestore/cloud_firestore.dart';

class SaleMaster {
  final String id;
  final String customerName;
  final int invoice;
  final DateTime date;
  final double total;
  final String phone;
  final String type;

  SaleMaster({
    required this.id,
    required this.customerName,
    required this.invoice,
    required this.date,
    required this.total,
    required this.phone,
    required this.type,
  });

  factory SaleMaster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SaleMaster(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      invoice: data['invoice'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      total: (data['total'] as num).toDouble(),
      phone: data['phone'] ?? '',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'invoice': invoice,
      'date': Timestamp.fromDate(date),
      'total': total,
      'phone': phone,
      'type': type,
    };
  }
}
