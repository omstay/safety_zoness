import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Models (same as before)
class Business {
  final String? id;
  final String businessName;
  final String? logoPath;
  final String address;
  final String gstin;
  final String stateCode;
  final String businessType;
  final String turnoverCategory;
  final String? digitalSignaturePath;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankBranch;
  final DateTime createdAt;
  final String userId; // Add userId field

  Business({
    this.id,
    required this.businessName,
    this.logoPath,
    required this.address,
    required this.gstin,
    required this.stateCode,
    required this.businessType,
    required this.turnoverCategory,
    this.digitalSignaturePath,
    this.bankAccountNumber,
    this.bankName,
    this.bankBranch,
    DateTime? createdAt,
    required this.userId, // Required userId
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logoPath': logoPath,
      'address': address,
      'gstin': gstin,
      'stateCode': stateCode,
      'businessType': businessType,
      'turnoverCategory': turnoverCategory,
      'digitalSignaturePath': digitalSignaturePath,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'bankBranch': bankBranch,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId, // Include userId in map
    };
  }

  factory Business.fromMap(Map<String, dynamic> map, String id) {
    return Business(
      id: id,
      businessName: map['businessName'] ?? '',
      logoPath: map['logoPath'],
      address: map['address'] ?? '',
      gstin: map['gstin'] ?? '',
      stateCode: map['stateCode'] ?? '',
      businessType: map['businessType'] ?? '',
      turnoverCategory: map['turnoverCategory'] ?? '',
      digitalSignaturePath: map['digitalSignaturePath'],
      bankAccountNumber: map['bankAccountNumber'],
      bankName: map['bankName'],
      bankBranch: map['bankBranch'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      userId: map['userId'] ?? '', // Include userId from map
    );
  }
}

class Customer {
  final String? id;
  final String businessId;
  final String name;
  final String contactNumber;
  final String email;
  final String address;
  final String? gstin;
  final String? stateCode;
  final String customerType;
  final double? creditLimit;
  final String? creditTerms;
  final String? taxTreatment;
  final String userId; // Add userId field

  Customer({
    this.id,
    required this.businessId,
    required this.name,
    required this.contactNumber,
    required this.email,
    required this.address,
    this.gstin,
    this.stateCode,
    required this.customerType,
    this.creditLimit,
    this.creditTerms,
    this.taxTreatment,
    required this.userId, // Required userId
  });

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'gstin': gstin,
      'stateCode': stateCode,
      'customerType': customerType,
      'creditLimit': creditLimit,
      'creditTerms': creditTerms,
      'taxTreatment': taxTreatment,
      'userId': userId, // Include userId in map
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      gstin: map['gstin'],
      stateCode: map['stateCode'],
      customerType: map['customerType'] ?? 'B2C',
      creditLimit: map['creditLimit']?.toDouble(),
      creditTerms: map['creditTerms'],
      taxTreatment: map['taxTreatment'],
      userId: map['userId'] ?? '', // Include userId from map
    );
  }
}

// Enhanced Firebase Service with proper authentication
class GSTFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is authenticated
  static User? get currentUser => _auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // Sign in anonymously for testing (replace with proper auth)
  static Future<void> signInAnonymously() async {
    try {
      if (!isAuthenticated) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Business CRUD operations with user filtering
  static Future<String> addBusiness(Business business) async {
    try {
      await signInAnonymously(); // Ensure user is authenticated

      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      // Create business with current user ID
      final businessWithUserId = Business(
        businessName: business.businessName,
        address: business.address,
        gstin: business.gstin,
        stateCode: business.stateCode,
        businessType: business.businessType,
        turnoverCategory: business.turnoverCategory,
        logoPath: business.logoPath,
        digitalSignaturePath: business.digitalSignaturePath,
        bankAccountNumber: business.bankAccountNumber,
        bankName: business.bankName,
        bankBranch: business.bankBranch,
        userId: currentUser!.uid,
        createdAt: business.createdAt,
      );

      DocumentReference docRef = await _firestore
          .collection('businesses')
          .add(businessWithUserId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add business: $e');
    }
  }

  static Future<void> updateBusiness(String id, Business business) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('businesses')
          .doc(id)
          .update(business.toMap());
    } catch (e) {
      throw Exception('Failed to update business: $e');
    }
  }

  static Future<void> deleteBusiness(String id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _firestore.collection('businesses').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete business: $e');
    }
  }

  static Stream<List<Business>> getBusinesses() {
    return _firestore
        .collection('businesses')
        .where('userId', isEqualTo: currentUser?.uid ?? '')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Business.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Customer CRUD operations with user filtering
  static Future<String> addCustomer(Customer customer) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      // Create customer with current user ID
      final customerWithUserId = Customer(
        businessId: customer.businessId,
        name: customer.name,
        contactNumber: customer.contactNumber,
        email: customer.email,
        address: customer.address,
        gstin: customer.gstin,
        stateCode: customer.stateCode,
        customerType: customer.customerType,
        creditLimit: customer.creditLimit,
        creditTerms: customer.creditTerms,
        taxTreatment: customer.taxTreatment,
        userId: currentUser!.uid,
      );

      DocumentReference docRef = await _firestore
          .collection('customers')
          .add(customerWithUserId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  static Stream<List<Customer>> getCustomers(String businessId) {
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .where('userId', isEqualTo: currentUser?.uid ?? '')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  static Future<void> updateCustomer(String id, Customer customer) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('customers')
          .doc(id)
          .update(customer.toMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  static Future<void> deleteCustomer(String id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      await _firestore.collection('customers').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }
}