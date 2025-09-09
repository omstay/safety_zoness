import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // Create user with email and password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String businessName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;

      if (user != null) {
        // Create user profile with correct UserModel constructor
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          phone: phone,
          businessName: businessName,
          createdAt: DateTime.now(),
          isActive: true,
        );

        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

        // Create business profile
        await _firestore.collection('business_profiles').doc(user.uid).set({
          'businessId': user.uid,
          'businessName': businessName,
          'ownerName': username,
          'email': email,
          'phone': phone,
          'gstin': '', // Will be updated later
          'address': '', // Will be updated later
          'stateCode': '', // Will be updated later
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Create default business settings
        await _firestore.collection('business_settings').doc(user.uid).set({
          'businessId': user.uid,
          'companyName': businessName,
          'ownerName': username,
          'email': email,
          'phone': phone,
          'gstin': '',
          'address': '',
          'city': '',
          'state': '',
          'pincode': '',
          'bankDetails': {
            'bankName': '',
            'accountNumber': '',
            'ifscCode': '',
            'accountHolderName': '',
          },
          'invoiceSettings': {
            'invoicePrefix': 'INV',
            'startingNumber': 1,
            'termsAndConditions': 'Thank you for your business!',
          },
          'taxSettings': {
            'defaultCGST': 9.0,
            'defaultSGST': 9.0,
            'defaultIGST': 18.0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update display name
        await user.updateDisplayName(username);
      }
      return user;
    } catch (e) {
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw e;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw e;
    }
  }

  // Get business profile
  Future<Map<String, dynamic>?> getBusinessProfile(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('business_profiles').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Update business profile
  Future<void> updateBusinessProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('business_profiles').doc(uid).update(data);
    } catch (e) {
      throw e;
    }
  }

  // Get business settings
  Future<Map<String, dynamic>?> getBusinessSettings(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('business_settings').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw e;
    }
  }

  // Update business settings
  Future<void> updateBusinessSettings(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('business_settings').doc(uid).update(data);
    } catch (e) {
      throw e;
    }
  }

  // Check if user has completed business setup
  Future<bool> isBusinessSetupComplete(String uid) async {
    try {
      final businessProfile = await getBusinessProfile(uid);
      if (businessProfile == null) return false;

      // Check if essential business details are filled
      final gstin = businessProfile['gstin'] ?? '';
      final address = businessProfile['address'] ?? '';

      return gstin.isNotEmpty && address.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        // Update in Firestore as well
        await updateUserData(user.uid, {'email': newEmail});
      }
    } catch (e) {
      throw e;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw e;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        await _firestore.collection('business_profiles').doc(user.uid).delete();
        await _firestore.collection('business_settings').doc(user.uid).delete();

        // Delete Firebase Auth user
        await user.delete();
      }
    } catch (e) {
      throw e;
    }
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw e;
    }
  }

  // Check if email is verified
  bool get isEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      throw e;
    }
  }

  // Get current user's business ID
  String? get currentBusinessId {
    return _auth.currentUser?.uid;
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    return _auth.currentUser != null;
  }

  // Get user display name
  String get userDisplayName {
    return _auth.currentUser?.displayName ?? 'User';
  }

  // Get user email
  String get userEmail {
    return _auth.currentUser?.email ?? '';
  }
}
