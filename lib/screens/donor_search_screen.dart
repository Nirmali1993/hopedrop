import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../services/rating_service.dart';
import '../widgets/star_rating.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() =>
      _DonorSearchScreenState();
}

class _DonorSearchScreenState
    extends State<DonorSearchScreen> {
  String _selectedBloodType = 'Any';
  bool _showOnlyAvailable = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<QueryDocumentSnapshot> _cachedDonors = [];

  final List<String> _bloodTypes = [
    'Any', 'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Find Donors',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.search_outlined,
                    color: Color(0xFFBDBDBD)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFFBDBDBD)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFB71C1C), width: 1.5)),
              ),
            ),
          ),

          // Blood type filter
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bloodTypes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bt = _bloodTypes[i];
                final isSelected = _selectedBloodType == bt;
                return FilterChip(
                  label: Text(bt),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedBloodType = bt),
                  selectedColor: const Color(0xFFB71C1C),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: const Color(0xFFF5F5F5),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Available only toggle
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Available donors only',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                const Spacer(),
                Switch(
                  value: _showOnlyAvailable,
                  onChanged: (v) =>
                      setState(() => _showOnlyAvailable = v),
                  activeThumbColor: const Color(0xFFB71C1C),
                ),
              ],
            ),
          ),

          // Donor list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _showOnlyAvailable
                  ? DatabaseService.getAvailableDonors(
                      bloodType: _selectedBloodType)
                  : DatabaseService.getAllDonors(
                      bloodType: _selectedBloodType),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _cachedDonors = snapshot.data!.docs;
                }

                if (_cachedDonors.isEmpty &&
                    snapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFB71C1C)),
                  );
                }

                if (_cachedDonors.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: Color(0xFFB71C1C)),
                        SizedBox(height: 16),
                        Text('No donors found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('Try a different blood type',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  );
                }

                final filtered = _cachedDonors.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data =
                      doc.data() as Map<String, dynamic>;
                  return (data['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      (data['location'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} donor${filtered.length != 1 ? 's' : ''} found',
                            style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final data = filtered[i].data()
                              as Map<String, dynamic>;
                          return _DonorCard(data: data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donor Card with Rating ─────────────────────────────────────────────────────

class _DonorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DonorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final bloodType = data['bloodType'] ?? '?';
    final phone = data['phone'] ?? '';
    final isAvailable = data['isAvailable'] ?? false;
    final totalDonations = data['totalDonations'] ?? 0;
    final photoBase64 = data['photoBase64'];
    final daysLeft = DatabaseService.getDaysUntilEligible(
        data['nextEligibleDate']);
    final avgRating = RatingService.getAverageRating(data);
    final ratingCount = RatingService.getRatingCount(data);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: photoBase64 != null
                      ? Image.memory(
                          base64Decode(photoBase64),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) =>
                              _fallback(name, isAvailable),
                        )
                      : _fallback(name, isAvailable),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          color: isAvailable
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Star rating
                StarDisplay(
                    rating: avgRating, count: ratingCount),

                // Donations count
                Row(
                  children: [
                    const Icon(Icons.favorite_outline,
                        size: 11, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 2),
                    Text(
                        '$totalDonations donation${totalDonations != 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E))),
                  ],
                ),

                // Eligibility countdown
                if (!isAvailable && daysLeft > 0)
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 11, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text('Eligible in $daysLeft days',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ),

          // Blood type + call
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(bloodType,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              if (isAvailable && phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_outlined,
                        color: Color(0xFFB71C1C), size: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name, bool isAvailable) {
    return Container(
      color: isAvailable
          ? const Color(0xFFFFEBEE)
          : const Color(0xFFF5F5F5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isAvailable
                  ? const Color(0xFFB71C1C)
                  : Colors.grey),
        ),
      ),
    );
  }
}