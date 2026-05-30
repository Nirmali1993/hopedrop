import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart'; // âœ… NEW

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<Map<String, dynamic>> _donations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: uid)
          .orderBy('donatedAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _donations = snap.docs.map((d) => d.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final date = (timestamp as Timestamp).toDate();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Unknown date';
    }
  }

  String _formatNextEligible(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // âœ… TRANSLATED
        title: Text(l10n.donationHistory,
            style: const TextStyle(
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
              _loadDonations();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : _donations.isEmpty
              ? _EmptyState()
              : Column(
                  children: [
                    _StatsBanner(totalDonations: _donations.length),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _donations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final d = _donations[i];
                          return _DonationCard(
                            index: _donations.length - i,
                            bloodType: d['bloodType'] ?? '?',
                            hospital: d['hospital'] ?? 'Unknown',
                            date: _formatDate(d['donatedAt']),
                            nextEligible:
                                _formatNextEligible(d['nextEligibleDate']),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// â”€â”€ Stats Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatsBanner extends StatelessWidget {
  final int totalDonations;
  const _StatsBanner({required this.totalDonations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // âœ… TRANSLATED
          _BannerStat(
            value: totalDonations.toString(),
            label: l10n.totalDonations,
            icon: Icons.water_drop_outlined,
          ),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _BannerStat(
            value: (totalDonations * 3).toString(),
            label: l10n.livesImpacted,
            icon: Icons.favorite_outline,
          ),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _BannerStat(
            value: '${totalDonations * 450}ml',
            label: 'Blood\nDonated',
            icon: Icons.opacity_outlined,
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _BannerStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.3)),
      ],
    );
  }
}

// â”€â”€ Donation Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DonationCard extends StatelessWidget {
  final int index;
  final String bloodType;
  final String hospital;
  final String date;
  final String nextEligible;

  const _DonationCard({
    required this.index,
    required this.bloodType,
    required this.hospital,
    required this.date,
    required this.nextEligible,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(bloodType,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text('#$index',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hospital,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 4),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
                if (nextEligible.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      // âœ… TRANSLATED
                      Text('Next ${l10n.eligibleToDonate}: $nextEligible',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite, color: Color(0xFFB71C1C), size: 12),
                    SizedBox(width: 4),
                    Text('3 lives',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Empty State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.water_drop_outlined,
                  size: 48, color: Color(0xFFB71C1C)),
            ),
            const SizedBox(height: 20),
            // âœ… TRANSLATED
            Text(l10n.noRequestsYet,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text(
              'Your donation history will appear here after you record your first donation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              // âœ… TRANSLATED
              label: Text(l10n.profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
