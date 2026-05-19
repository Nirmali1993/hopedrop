import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // BLOOD REQUESTS
  // ════════════════════════════════════════════════════════════════════════════

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
      'status': 'active',
      'respondedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getActiveBloodRequests() {
    return _db
        .collection('blood_requests')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  static Future<void> respondToRequest(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not logged in';

    await _db.collection('blood_requests').doc(requestId).update({
      'respondedBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  static Future<void> fulfillRequest(String requestId) async {
    await _db.collection('blood_requests').doc(requestId).update({
      'status': 'fulfilled',
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DONORS
  // ════════════════════════════════════════════════════════════════════════════

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

  static Stream<QuerySnapshot> getAllDonors({String? bloodType}) {
    Query query = _db.collection('users').where('role', isEqualTo: 'donor');

    if (bloodType != null && bloodType != 'Any') {
      query = query.where('bloodType', isEqualTo: bloodType);
    }

    return query.snapshots();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DONOR ELIGIBILITY — 3 month rule
  // ════════════════════════════════════════════════════════════════════════════

  /// Record a donation — donor becomes unavailable for 90 days
  static Future<void> recordDonation({
    required String hospital,
    required String bloodType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not logged in';

    final now = DateTime.now();
    final nextEligibleDate = now.add(const Duration(days: 90));

    // Save donation record
    await _db.collection('donations').add({
      'donorId': user.uid,
      'bloodType': bloodType,
      'hospital': hospital,
      'donatedAt': FieldValue.serverTimestamp(),
      'nextEligibleDate': Timestamp.fromDate(nextEligibleDate),
    });

    // Update donor profile
    await _db.collection('users').doc(user.uid).update({
      'isAvailable': false,
      'lastDonationDate': FieldValue.serverTimestamp(),
      'nextEligibleDate': Timestamp.fromDate(nextEligibleDate),
      'totalDonations': FieldValue.increment(1),
    });
  }

  /// Check if 3 months passed → make donor available again
  static Future<void> checkAndUpdateEligibility() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null || data['role'] != 'donor') return;

      final nextEligibleTimestamp = data['nextEligibleDate'];
      if (nextEligibleTimestamp == null) return;

      final nextEligibleDate = (nextEligibleTimestamp as Timestamp).toDate();

      if (DateTime.now().isAfter(nextEligibleDate) &&
          data['isAvailable'] == false) {
        await _db.collection('users').doc(user.uid).update({
          'isAvailable': true,
          'nextEligibleDate': null,
        });
      }
    } catch (_) {}
  }

  /// Returns days remaining until eligible to donate again
  static int getDaysUntilEligible(dynamic nextEligibleDate) {
    if (nextEligibleDate == null) return 0;
    try {
      final date = (nextEligibleDate as Timestamp).toDate();
      final diff = date.difference(DateTime.now()).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, int>> getAppStats() async {
    try {
      final donors = await _db
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .count()
          .get();
      final donations = await _db.collection('donations').count().get();
      return {
        'donors': donors.count ?? 0,
        'donations': donations.count ?? 0,
        'livesSaved': (donations.count ?? 0) * 3,
      };
    } catch (_) {
      return {'donors': 0, 'donations': 0, 'livesSaved': 0};
    }
  }
}
