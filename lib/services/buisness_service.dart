import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/business_profile.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current business ID
  String? get currentBusinessId => _auth.currentUser?.uid;

  // Get business profile
  Future<BusinessProfile?> getBusinessProfile([String? businessId]) async {
    try {
      final id = businessId ?? currentBusinessId;
      if (id == null) return null;

      final doc = await _firestore.collection('business_profiles').doc(id).get();
      if (doc.exists) {
        return BusinessProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Update business profile
  Future<void> updateBusinessProfile(BusinessProfile profile) async {
    try {
      final data = profile.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('business_profiles')
          .doc(profile.businessId)
          .update(data);
    } catch (e) {
      throw e;
    }
  }

  // Create business profile
  Future<void> createBusinessProfile(BusinessProfile profile) async {
    try {
      await _firestore
          .collection('business_profiles')
          .doc(profile.businessId)
          .set(profile.toMap());
    } catch (e) {
      throw e;
    }
  }

  // Check if business setup is complete
  Future<bool> isSetupComplete([String? businessId]) async {
    try {
      final profile = await getBusinessProfile(businessId);
      if (profile == null) return false;

      return profile.gstin.isNotEmpty &&
          profile.address.isNotEmpty &&
          profile.city.isNotEmpty &&
          profile.state.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get business settings
  Future<Map<String, dynamic>?> getBusinessSettings([String? businessId]) async {
    try {
      final id = businessId ?? currentBusinessId;
      if (id == null) return null;

      final doc = await _firestore.collection('business_settings').doc(id).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Update business settings
  Future<void> updateBusinessSettings(Map<String, dynamic> settings, [String? businessId]) async {
    try {
      final id = businessId ?? currentBusinessId;
      if (id == null) throw Exception('No business ID available');

      settings['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('business_settings').doc(id).update(settings);
    } catch (e) {
      throw e;
    }
  }

  // Stream business profile changes
  Stream<BusinessProfile?> streamBusinessProfile([String? businessId]) {
    final id = businessId ?? currentBusinessId;
    if (id == null) return Stream.value(null);

    return _firestore
        .collection('business_profiles')
        .doc(id)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return BusinessProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Validate GSTIN
  bool validateGSTIN(String gstin) {
    if (gstin.length != 15) return false;
    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return gstinRegex.hasMatch(gstin);
  }

  // Get state code from GSTIN
  String getStateCodeFromGSTIN(String gstin) {
    if (gstin.length >= 2) {
      return gstin.substring(0, 2);
    }
    return '';
  }
}
