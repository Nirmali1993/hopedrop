import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart'; // âœ… NEW
import '../services/auth_service.dart';
import 'donor_search_screen.dart';
import 'blood_request_screen.dart';
import 'all_responses_screen.dart';

class RecipientHomeTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const RecipientHomeTab({super.key, this.userData});

  @override
  State<RecipientHomeTab> createState() => _RecipientHomeTabState();
}

class _RecipientHomeTabState extends State<RecipientHomeTab> {
  String? _cachedPhotoBase64;
  String? _cachedName;
  String? _cachedBloodType;
  bool _profileLoaded = false;
  List<_ResponseData> _cachedResponses = [];
  bool _responsesLoaded = false;

  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  final List<String> _bannerImages = [
    'assets/images/bloodd1.png',
    'assets/images/bloodd2.png',
    'assets/images/bloddd3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileOnce();
    _loadResponsesOnce();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBanner + 1) % _bannerImages.length;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _loadProfileOnce() async {
    if (_profileLoaded) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await AuthService.getUserProfile(user.uid);
        if (mounted && data != null) {
          setState(() {
            _cachedPhotoBase64 = data['photoBase64'];
            _cachedName = data['name'] ?? 'Hero';
            _cachedBloodType = data['bloodType'] ?? '';
            _profileLoaded = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadResponsesOnce() async {
    if (_responsesLoaded) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final requestSnap = await FirebaseFirestore.instance
          .collection('blood_requests')
          .where('requestedBy', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .get();

      final List<_ResponseData> items = [];

      for (final doc in requestSnap.docs) {
        if (items.length >= 2) break;
        final data = doc.data();
        final respondedBy = List<String>.from(data['respondedBy'] ?? []);

        for (final donorId in respondedBy) {
          if (items.length >= 2) break;
          final donorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(donorId)
              .get();
          if (!donorDoc.exists) continue;
          final donorData = donorDoc.data();
          if (donorData == null) continue;
          if (donorData['role'] != 'donor') continue;

          items.add(_ResponseData(
            donorId: donorId,
            donorName: donorData['name'] ?? 'Unknown',
            donorBlood: donorData['bloodType'] ?? data['bloodType'] ?? '?',
            donorPhone: donorData['phone'] ?? '',
            donorPhoto: donorData['photoBase64'],
            hospital: data['hospital'] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _cachedResponses = items;
          _responsesLoaded = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    final name = _cachedName ?? widget.userData?['name'] ?? 'Hero';
    final firstName = name.split(' ')[0];
    final bloodType = _cachedBloodType ?? widget.userData?['bloodType'] ?? '';
    final photoBase64 = _cachedPhotoBase64 ?? widget.userData?['photoBase64'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: () async {
          _profileLoaded = false;
          _responsesLoaded = false;
          await _loadProfileOnce();
          await _loadResponsesOnce();
        },
        color: const Color(0xFFB71C1C),
        child: CustomScrollView(
          slivers: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 170,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB71C1C),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: CustomPaint(
                      painter: _HexPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  // âœ… TRANSLATED
                                  Text(
                                    "${l10n.iAmRecipient} ðŸŽ¯",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Hope is on the way!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            // âœ… TRANSLATED
                            Text('${l10n.hello}, $firstName!',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13)),
                          ],
                        ),

                        // Profile photo
                        Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: ClipOval(
                                child: photoBase64 != null
                                    ? Image.memory(
                                        base64Decode(photoBase64),
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        errorBuilder: (_, __, ___) =>
                                            _avatar(name),
                                      )
                                    : _avatar(name),
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (bloodType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(bloodType,
                                    style: const TextStyle(
                                        color: Color(0xFFB71C1C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Banner Slider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _bannerImages.length,
                        onPageChanged: (i) =>
                            setState(() => _currentBanner = i),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              _bannerImages[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(Icons.water_drop_outlined,
                                      size: 40, color: Color(0xFFB71C1C)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _bannerImages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBanner == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentBanner == i
                                ? const Color(0xFFB71C1C)
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Quick Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.search,
                        // âœ… TRANSLATED
                        title: l10n.findDonors,
                        subtitle: 'Search nearby',
                        color: const Color(0xFFFFEBEE),
                        iconColor: const Color(0xFFB71C1C),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DonorSearchScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle_outline,
                        // âœ… TRANSLATED
                        title: l10n.postRequest,
                        subtitle: 'Post urgent request',
                        color: const Color(0xFFE8F5E9),
                        iconColor: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BloodRequestScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Responses Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // âœ… TRANSLATED
                    Text(l10n.donorsResponded,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllResponsesScreen(),
                        ),
                      ),
                      // âœ… TRANSLATED
                      child: Text(l10n.seeAll,
                          style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Response Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!_responsesLoaded)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                  ),
                ),
              )
            else if (_cachedResponses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      const Icon(Icons.hourglass_top_outlined,
                          size: 40, color: Color(0xFFB71C1C)),
                      const SizedBox(height: 8),
                      // âœ… TRANSLATED
                      Text(l10n.waitingForDonors,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      const Text('Post a request and donors will respond',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF9E9E9E))),
                    ]),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SmallResponseCard(response: _cachedResponses[i]),
                    ),
                    childCount: _cachedResponses.length,
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'R',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// â”€â”€ Small Response Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SmallResponseCard extends StatelessWidget {
  final _ResponseData response;
  const _SmallResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // âœ… NEW

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB71C1C), width: 2),
            ),
            child: ClipOval(
              child: response.donorPhoto != null
                  ? Image.memory(
                      base64Decode(response.donorPhoto!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          _fallback(response.donorName),
                    )
                  : _fallback(response.donorName),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I would like to help you!',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic)),
                Text(response.donorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                // âœ… TRANSLATED
                Text(
                    '${l10n.bloodType} ${response.donorBlood} â€¢ ${response.donorPhone}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (response.donorPhone.isNotEmpty) {
                final uri = Uri.parse('tel:${response.donorPhone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name) {
    return Container(
      color: const Color(0xFFFFEBEE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C)),
        ),
      ),
    );
  }
}

// â”€â”€ Action Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Data Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ResponseData {
  final String donorId;
  final String donorName;
  final String donorBlood;
  final String donorPhone;
  final String? donorPhoto;
  final String hospital;

  const _ResponseData({
    required this.donorId,
    required this.donorName,
    required this.donorBlood,
    required this.donorPhone,
    this.donorPhoto,
    required this.hospital,
  });
}

// â”€â”€ Hex Painter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final positions = [
      [0.05, 0.1, 28.0],
      [0.88, 0.08, 24.0],
      [0.02, 0.6, 20.0],
      [0.92, 0.55, 26.0],
      [0.5, 0.05, 16.0],
    ];

    for (final p in positions) {
      _drawHex(canvas, paint, size.width * p[0], size.height * p[1], p[2]);
    }
  }

  void _drawHex(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = 3.14159265 / 3 * i - 3.14159265 / 6;
      final x = cx + r * _cos(angle);
      final y = cy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double r) {
    double t = 1, s = 1;
    for (int i = 1; i <= 8; i++) {
      t *= -r * r / ((2 * i - 1) * (2 * i));
      s += t;
    }
    return s;
  }

  double _sin(double r) {
    double t = r, s = r;
    for (int i = 1; i <= 8; i++) {
      t *= -r * r / ((2 * i) * (2 * i + 1));
      s += t;
    }
    return s;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
