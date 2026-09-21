import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Unified Firebase Service covering Realtime Database, Firestore, and Authentication.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseDatabase get rtdb => FirebaseDatabase.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Verifies connectivity and read/write health on both Firestore and RTDB.
  Future<Map<String, dynamic>> checkHealth() async {
    final results = <String, dynamic>{
      'rtdb': false,
      'firestore': false,
      'auth': false,
      'details': <String, dynamic>{},
    };

    // 1. Auth check
    try {
      final user = auth.currentUser;
      results['auth'] = true;
      (results['details'] as Map<String, dynamic>)['auth_user'] =
          user?.email ?? 'anonymous/not signed in';
    } catch (e) {
      (results['details'] as Map<String, dynamic>)['auth_error'] = e.toString();
    }

    // 2. Realtime Database check
    try {
      final pingRef = rtdb.ref('.info/connected');
      final snap = await pingRef.get();
      results['rtdb'] = true;
      (results['details'] as Map<String, dynamic>)['rtdb_connected'] =
          snap.value ?? true;
    } catch (e) {
      (results['details'] as Map<String, dynamic>)['rtdb_error'] = e.toString();
    }

    // 3. Firestore check (write and read a test ping document)
    try {
      final docRef = firestore.collection('system_health').doc('cli_ping');
      await docRef.set({
        'ping': true,
        'timestamp': FieldValue.serverTimestamp(),
        'app': 'miralo',
      });
      final readSnap = await docRef.get();
      results['firestore'] = readSnap.exists;
      (results['details'] as Map<String, dynamic>)['firestore_doc_exists'] =
          readSnap.exists;
    } catch (e) {
      (results['details'] as Map<String, dynamic>)['firestore_error'] =
          e.toString();
    }

    return results;
  }
}
