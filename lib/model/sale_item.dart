class SaleItem {
  final String id;
  final String itemId;
  final String hsnCode;
  final String description;
  final String descriptionAsPerHsn;
  final String uqc; // Unit Quantity Code
  final double quantity;
  final double rate;
  final double taxableValue;
  final double cgstRate;
  final double sgstRate;
  final double igstRate;
  final double cessRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double totalAmount;

  SaleItem({
    required this.id,
    required this.itemId,
    required this.hsnCode,
    required this.description,
    required this.descriptionAsPerHsn,
    required this.uqc,
    required this.quantity,
    required this.rate,
    required this.taxableValue,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cessRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.totalAmount,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      description: map['description'] ?? '',
      descriptionAsPerHsn: map['descriptionAsPerHsn'] ?? '',
      uqc: map['uqc'] ?? 'NOS',
      quantity: (map['quantity'] ?? 0).toDouble(),
      rate: (map['rate'] ?? 0).toDouble(),
      taxableValue: (map['taxableValue'] ?? 0).toDouble(),
      cgstRate: (map['cgstRate'] ?? 0).toDouble(),
      sgstRate: (map['sgstRate'] ?? 0).toDouble(),
      igstRate: (map['igstRate'] ?? 0).toDouble(),
      cessRate: (map['cessRate'] ?? 0).toDouble(),
      cgstAmount: (map['cgstAmount'] ?? 0).toDouble(),
      sgstAmount: (map['sgstAmount'] ?? 0).toDouble(),
      igstAmount: (map['igstAmount'] ?? 0).toDouble(),
      cessAmount: (map['cessAmount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'hsnCode': hsnCode,
      'description': description,
      'descriptionAsPerHsn': descriptionAsPerHsn,
      'uqc': uqc,
      'quantity': quantity,
      'rate': rate,
      'taxableValue': taxableValue,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'igstRate': igstRate,
      'cessRate': cessRate,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'cessAmount': cessAmount,
      'totalAmount': totalAmount,
    };
  }

  SaleItem copyWith({
    String? id,
    String? itemId,
    String? hsnCode,
    String? description,
    String? descriptionAsPerHsn,
    String? uqc,
    double? quantity,
    double? rate,
    double? taxableValue,
    double? cgstRate,
    double? sgstRate,
    double? igstRate,
    double? cessRate,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? cessAmount,
    double? totalAmount,
  }) {
    return SaleItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      hsnCode: hsnCode ?? this.hsnCode,
      description: description ?? this.description,
      descriptionAsPerHsn: descriptionAsPerHsn ?? this.descriptionAsPerHsn,
      uqc: uqc ?? this.uqc,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      taxableValue: taxableValue ?? this.taxableValue,
      cgstRate: cgstRate ?? this.cgstRate,
      sgstRate: sgstRate ?? this.sgstRate,
      igstRate: igstRate ?? this.igstRate,
      cessRate: cessRate ?? this.cessRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      cessAmount: cessAmount ?? this.cessAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
