import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current user's business ID
  static Future<String?> getCurrentBusinessId() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['businessId'] ?? userId;
      }
      return userId;
    } catch (e) {
      print('Error getting business ID: $e');
      return userId;
    }
  }

  // Create user-specific query
  static Query getUserSpecificQuery(String collection) {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId);
  }

  // Create business-specific query
  static Future<Query> getBusinessSpecificQuery(String collection) async {
    final businessId = await getCurrentBusinessId();
    if (businessId == null) {
      throw Exception('Business ID not found');
    }
    return _firestore
        .collection(collection)
        .where('businessId', isEqualTo: businessId);
  }

  // Add user/business ID to data before saving
  static Future<Map<String, dynamic>> addUserContext(Map<String, dynamic> data) async {
    final userId = getCurrentUserId();
    final businessId = await getCurrentBusinessId();

    if (userId == null) throw Exception('User not authenticated');

    return {
      ...data,
      'userId': userId,
      'businessId': businessId ?? userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
