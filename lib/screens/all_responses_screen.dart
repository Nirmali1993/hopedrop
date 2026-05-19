import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rating_service.dart';
import '../widgets/star_rating.dart';

class AllResponsesScreen extends StatefulWidget {
  const AllResponsesScreen({super.key});

  @override
  State<AllResponsesScreen> createState() => _AllResponsesScreenState();
}

class _AllResponsesScreenState extends State<AllResponsesScreen> {
  List<_ResponseItem> _cachedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final requestSnap = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('requestedBy', isEqualTo: uid)
          .get();

      final List<_ResponseItem> items = [];

      for (final doc in requestSnap.docs) {
        final data = doc.data();
        final respondedBy = List<String>.from(data['respondedBy'] ?? []);

        for (final donorId in respondedBy) {
          final donorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(donorId)
              .get();

          if (!donorDoc.exists) continue;
          final donorData = donorDoc.data();
          if (donorData == null) continue;
          if (donorData['role'] != 'donor') continue;

          // Check if already rated
          final alreadyRated = await RatingService.hasAlreadyRated(
            donorId: donorId,
            requestId: doc.id,
          );

          items.add(_ResponseItem(
            requestId: doc.id,
            donorId: donorId,
            donorName: donorData['name'] ?? 'Unknown',
            donorBlood: donorData['bloodType'] ?? data['bloodType'] ?? '?',
            donorPhone: donorData['phone'] ?? '',
            donorPhoto: donorData['photoBase64'],
            bloodType: data['bloodType'] ?? '?',
            hospital: data['hospital'] ?? '',
            urgency: data['urgency'] ?? 'Normal',
            status: data['status'] ?? 'active',
            averageRating: RatingService.getAverageRating(donorData),
            ratingCount: RatingService.getRatingCount(donorData),
            alreadyRated: alreadyRated,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _cachedItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Rating Dialog ──────────────────────────────────────────────────────────
  void _showRatingDialog(_ResponseItem item) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 24),
              SizedBox(width: 8),
              Text('Rate Donor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Donor info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFEBEE),
                    child: item.donorPhoto != null
                        ? ClipOval(
                            child: Image.memory(
                              base64Decode(item.donorPhoto!),
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                            ),
                          )
                        : Text(
                            item.donorName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.donorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Blood ${item.donorBlood}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'How was your experience?',
                style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 12),

              // Star rating
              StarRating(
                initialRating: selectedRating,
                size: 40,
                onRatingChanged: (r) {
                  setDialogState(() => selectedRating = r);
                },
              ),
              const SizedBox(height: 8),

              // Rating label
              Text(
                _getRatingLabel(selectedRating),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFB300),
                ),
              ),
              const SizedBox(height: 16),

              // Comment field
              TextField(
                controller: commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await RatingService.rateDonor(
                    donorId: item.donorId,
                    requestId: item.requestId,
                    rating: selectedRating,
                    comment: commentController.text.trim(),
                  );

                  // Reload responses
                  setState(() => _isLoading = true);
                  await _loadResponses();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '⭐ Rated ${item.donorName} $selectedRating stars!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C)),
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 5) return '⭐ Excellent!';
    if (rating == 4) return '😊 Very Good';
    if (rating == 3) return '👍 Good';
    if (rating == 2) return '😐 Fair';
    return '😞 Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Responses',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFB71C1C)),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadResponses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : _cachedItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top_outlined,
                          size: 64, color: Color(0xFFB71C1C)),
                      SizedBox(height: 16),
                      Text('No responses yet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('Donors will respond to your requests',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cachedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ResponseCard(
                    item: _cachedItems[i],
                    onRate: () => _showRatingDialog(_cachedItems[i]),
                  ),
                ),
    );
  }
}

// ── Response Card with Rating ──────────────────────────────────────────────────

class _ResponseCard extends StatelessWidget {
  final _ResponseItem item;
  final VoidCallback onRate;

  const _ResponseCard({required this.item, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFB71C1C), width: 2),
                    ),
                    child: ClipOval(
                      child: item.donorPhoto != null
                          ? Image.memory(
                              base64Decode(item.donorPhoto!),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) =>
                                  _avatar(item.donorName),
                            )
                          : _avatar(item.donorName),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Donor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.donorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    // Star rating display
                    StarDisplay(
                      rating: item.averageRating,
                      count: item.ratingCount,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Blood ${item.donorBlood}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB71C1C),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Call button
              GestureDetector(
                onTap: () async {
                  if (item.donorPhone.isNotEmpty) {
                    final uri = Uri.parse('tel:${item.donorPhone}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Hospital info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined,
                        size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 4),
                    Text(item.hospital,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),

                // Rate button or Already Rated
                item.alreadyRated
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Rated',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: onRate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFB300)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_outline_rounded,
                                  size: 12, color: Color(0xFFFFB300)),
                              SizedBox(width: 4),
                              Text('Rate Donor',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFFFB300),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      color: const Color(0xFFFFEBEE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C)),
        ),
      ),
    );
  }
}

// ── Data Model ─────────────────────────────────────────────────────────────────

class _ResponseItem {
  final String requestId;
  final String donorId;
  final String donorName;
  final String donorBlood;
  final String donorPhone;
  final String? donorPhoto;
  final String bloodType;
  final String hospital;
  final String urgency;
  final String status;
  final double averageRating;
  final int ratingCount;
  final bool alreadyRated;

  const _ResponseItem({
    required this.requestId,
    required this.donorId,
    required this.donorName,
    required this.donorBlood,
    required this.donorPhone,
    this.donorPhoto,
    required this.bloodType,
    required this.hospital,
    required this.urgency,
    required this.status,
    required this.averageRating,
    required this.ratingCount,
    required this.alreadyRated,
  });
}
