import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  static User? get currentUser => auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
}