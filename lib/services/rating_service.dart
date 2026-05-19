import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Submit a rating for a donor ────────────────────────────────────────────
  static Future<void> rateDonor({
    required String donorId,
    required String requestId,
    required double rating,
    String comment = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Not logged in';

    // Save rating to ratings collection
    await _db.collection('ratings').add({
      'donorId': donorId,
      'recipientId': user.uid,
      'requestId': requestId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update donor's average rating
    await _updateDonorRating(donorId);
  }

  // ── Recalculate and update donor average rating ────────────────────────────
  static Future<void> _updateDonorRating(String donorId) async {
    final ratingsSnap = await _db
        .collection('ratings')
        .where('donorId', isEqualTo: donorId)
        .get();

    if (ratingsSnap.docs.isEmpty) return;

    double totalRating = 0;
    for (final doc in ratingsSnap.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final count = ratingsSnap.docs.length;
    final average = totalRating / count;

    await _db.collection('users').doc(donorId).update({
      'totalRating': totalRating,
      'ratingCount': count,
      'averageRating': double.parse(average.toStringAsFixed(1)),
    });
  }

  // ── Check if recipient already rated this donor for this request ───────────
  static Future<bool> hasAlreadyRated({
    required String donorId,
    required String requestId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await _db
        .collection('ratings')
        .where('donorId', isEqualTo: donorId)
        .where('requestId', isEqualTo: requestId)
        .where('recipientId', isEqualTo: user.uid)
        .get();

    return snap.docs.isNotEmpty;
  }

  // ── Get donor average rating ───────────────────────────────────────────────
  static double getAverageRating(Map<String, dynamic> userData) {
    return (userData['averageRating'] as num?)?.toDouble() ?? 0.0;
  }

  // ── Get rating count ───────────────────────────────────────────────────────
  static int getRatingCount(Map<String, dynamic> userData) {
    return (userData['ratingCount'] as num?)?.toInt() ?? 0;
  }
}
