// ─────────────────────────────────────────────────────────────────────────────
// services/firestore_service.dart  —  Cloud Database (Firestore)
//
// HOW DATA IS STORED:
//   Firestore is like a tree of folders:
//   users/
//     {userId}/
//       medicines/
//         {medicineId}  ← each medicine is a document
//       vitals/
//         {vitalId}     ← each health reading is a document
//
// Each user only sees their own data because we use their UID in the path.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine.dart';
import '../models/vital.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  /// Shortcut to get the current user's ID
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Medicine References ──────────────────────────────────────────────────

  static CollectionReference get _medicines =>
      _db.collection('users').doc(_uid).collection('medicines');

  /// Add a new medicine to Firestore
  static Future<void> addMedicine(Medicine medicine) async {
    await _medicines.doc(medicine.id).set(medicine.toMap());
  }

  /// Update an existing medicine (e.g., toggle active/inactive)
  static Future<void> updateMedicine(Medicine medicine) async {
    await _medicines.doc(medicine.id).update(medicine.toMap());
  }

  /// Delete a medicine permanently
  static Future<void> deleteMedicine(String id) async {
    await _medicines.doc(id).delete();
  }

  /// Stream of medicines — UI auto-updates when data changes in Firestore
  /// Stream<> means it keeps watching and pushes new data every time something changes
  static Stream<List<Medicine>> getMedicines() {
    return _medicines
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Medicine.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Vital References ─────────────────────────────────────────────────────

  static CollectionReference get _vitals =>
      _db.collection('users').doc(_uid).collection('vitals');

  /// Add a new health reading
  static Future<void> addVital(Vital vital) async {
    await _vitals.doc(vital.id).set(vital.toMap());
  }

  /// Delete a health reading
  static Future<void> deleteVital(String id) async {
    await _vitals.doc(id).delete();
  }

  /// Stream of vitals, optionally filtered by type
  /// e.g. getVitals(type: 'blood_pressure') only returns BP readings
  static Stream<List<Vital>> getVitals({String? type}) {
    Query query = _vitals.orderBy('recordedAt', descending: true);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => Vital.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }
}
