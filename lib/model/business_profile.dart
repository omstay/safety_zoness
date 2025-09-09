import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfile {
  final String businessId;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String gstin;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String stateCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusinessProfile({
    required this.businessId,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.stateCode,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gstin: map['gstin'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      stateCode: map['stateCode'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'stateCode': stateCode,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  BusinessProfile copyWith({
    String? businessId,
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? gstin,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? stateCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      stateCode: stateCode ?? this.stateCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
