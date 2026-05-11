import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // BLOOD REQUESTS
  // ════════════════════════════════════════════════════════════════════════════

  /// Post a new blood request
  static Future<void> createBloodRequest({
    required String patientName,
    required String bloodType,
    required String hospital,
    required String location,
    required int units,
    required String urgency,
    String notes = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not logged in';

    await _db.collection('blood_requests').add({
      'patientName': patientName,
      'bloodType': bloodType,
      'hospital': hospital,
      'location': location,
      'units': units,
      'urgency': urgency,
      'notes': notes,
      'requestedBy': user.uid,
      'status': 'active', // active | fulfilled | cancelled
      'respondedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all active blood requests (real-time)
  static Stream<QuerySnapshot> getActiveBloodRequests() {
    return _db
        .collection('blood_requests')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  /// Get blood requests by blood type
  static Stream<QuerySnapshot> getBloodRequestsByType(String bloodType) {
    return _db
        .collection('blood_requests')
        .where('status', isEqualTo: 'active')
        .where('bloodType', isEqualTo: bloodType)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Respond to a blood request
  static Future<void> respondToRequest(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not logged in';

    await _db.collection('blood_requests').doc(requestId).update({
      'respondedBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  /// Mark request as fulfilled
  static Future<void> fulfillRequest(String requestId) async {
    await _db.collection('blood_requests').doc(requestId).update({
      'status': 'fulfilled',
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DONORS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get all available donors
  static Stream<QuerySnapshot> getAvailableDonors({String? bloodType}) {
    Query query = _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .where('isAvailable', isEqualTo: true);

    if (bloodType != null && bloodType != 'Any') {
      query = query.where('bloodType', isEqualTo: bloodType);
    }

    return query.snapshots();
  }

  /// Search donors by name
  static Future<QuerySnapshot> searchDonors(String query) async {
    return await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
  }

  /// Toggle donor availability
  static Future<void> toggleAvailability(bool isAvailable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'isAvailable': isAvailable,
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DONATIONS HISTORY
  // ════════════════════════════════════════════════════════════════════════════

  /// Record a completed donation
  static Future<void> recordDonation({
    required String donorId,
    required String recipientId,
    required String bloodType,
    required String hospital,
  }) async {
    // Add to donations collection
    await _db.collection('donations').add({
      'donorId': donorId,
      'recipientId': recipientId,
      'bloodType': bloodType,
      'hospital': hospital,
      'donatedAt': FieldValue.serverTimestamp(),
    });

    // Increment donor's total donations
    await _db.collection('users').doc(donorId).update({
      'totalDonations': FieldValue.increment(1),
    });
  }

  /// Get donation history for current user
  static Stream<QuerySnapshot> getDonationHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('donations')
        .where('donorId', isEqualTo: user.uid)
        .orderBy('donatedAt', descending: true)
        .snapshots();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get app stats (donors count, donations count)
  static Future<Map<String, int>> getAppStats() async {
    final donors = await _db
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .count()
        .get();

    final donations = await _db.collection('donations').count().get();

    return {
      'donors': donors.count ?? 0,
      'donations': donations.count ?? 0,
      'livesSaved': ((donations.count ?? 0) * 3), // 1 donation = 3 lives
    };
  }
}
