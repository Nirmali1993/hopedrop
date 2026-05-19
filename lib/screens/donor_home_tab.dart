import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'all_requests_screen.dart';

class DonorHomeTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const DonorHomeTab({super.key, this.userData});

  @override
  State<DonorHomeTab> createState() => _DonorHomeTabState();
}

class _DonorHomeTabState extends State<DonorHomeTab> {
  Map<String, int> _stats = {'donors': 0, 'donations': 0};

  // Profile cache — no blinking
  String? _cachedPhotoBase64;
  String? _cachedName;
  String? _cachedBloodType;
  bool _cachedIsAvailable = true;
  bool _profileLoaded = false;

  // Requests cache — no blinking
  List<QueryDocumentSnapshot> _cachedRequests = [];

  // Banner
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
    _loadStats();
    _loadProfileOnce();
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
            _cachedIsAvailable = data['isAvailable'] ?? true;
            _profileLoaded = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseService.getAppStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final name = _cachedName ?? widget.userData?['name'] ?? 'Hero';
    final firstName = name.split(' ')[0];
    final bloodType = _cachedBloodType ?? widget.userData?['bloodType'] ?? '';
    final isAvailable = _cachedIsAvailable;
    final photoBase64 = _cachedPhotoBase64 ?? widget.userData?['photoBase64'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: () async {
          _profileLoaded = false;
          await _loadProfileOnce();
          await _loadStats();
        },
        color: const Color(0xFFB71C1C),
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 215,
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
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  child: const Row(
                                    children: [
                                      Icon(Icons.volunteer_activism,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text("I'm a Donor 🩸",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Ready to save a life?',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text('Hello, $firstName!',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 13)),
                              ],
                            ),

                            // Profile photo
                            Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2.5),
                                      ),
                                      child: ClipOval(
                                        child: photoBase64 != null
                                            ? Image.memory(
                                                base64Decode(photoBase64),
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                                errorBuilder: (_, __, ___) =>
                                                    _avatar(name))
                                            : _avatar(name),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: const Color(0xFFB71C1C),
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatBox(
                                value: _stats['donors'].toString(),
                                label: 'Donors',
                                icon: Icons.people_outline),
                            const SizedBox(width: 12),
                            _StatBox(
                                value: _stats['donations'].toString(),
                                label: 'Donations',
                                icon: Icons.water_drop_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Not eligible warning
            if (!isAvailable)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are not eligible to donate yet. Help button is hidden until you are eligible.',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Banner Slider ────────────────────────────────────────
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

            // ── Urgent Requests ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Urgent Requests',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AllRequestsScreen(
                                  isDonorEligible: isAvailable))),
                      child: const Text('See All',
                          style: TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: DatabaseService.getActiveBloodRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _cachedRequests = snapshot.data!.docs.take(2).toList();
                }

                if (_cachedRequests.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: Color(0xFFB71C1C)))),
                  );
                }

                if (_cachedRequests.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Column(children: [
                          Icon(Icons.favorite_outline,
                              size: 40, color: Color(0xFFB71C1C)),
                          SizedBox(height: 8),
                          Text('No urgent requests right now',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final data =
                            _cachedRequests[i].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequestCard(
                            requestId: _cachedRequests[i].id,
                            data: data,
                            // Pass eligibility to each card
                            isDonorEligible: isAvailable,
                          ),
                        );
                      },
                      childCount: _cachedRequests.length,
                    ),
                  ),
                );
              },
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
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Request Card ───────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final bool isDonorEligible;

  const _RequestCard({
    required this.requestId,
    required this.data,
    required this.isDonorEligible,
  });

  @override
  Widget build(BuildContext context) {
    final bloodType = data['bloodType'] ?? '?';
    final hospital = data['hospital'] ?? '';
    final location = data['location'] ?? '';
    final units = data['units'] ?? 1;
    final urgency = data['urgency'] ?? 'Normal';
    final urgencyColor = urgency == 'Urgent'
        ? const Color(0xFFB71C1C)
        : urgency == 'High'
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(bloodType,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hospital,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                if (location.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: Color(0xFF9E9E9E)),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                  ]),
                Text('$units Unit Needed',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(urgency,
                    style: TextStyle(
                        fontSize: 10,
                        color: urgencyColor,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),

              // ── Show Help only if eligible ──
              if (isDonorEligible)
                ElevatedButton(
                  onPressed: () async {
                    await DatabaseService.respondToRequest(requestId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Response sent!'),
                          backgroundColor: Color(0xFFB71C1C),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    minimumSize: const Size(56, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Help'),
                )
              else
                // Not eligible — show timer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: Colors.orange, size: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Box ───────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatBox(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hex Painter ────────────────────────────────────────────────────────────────

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final positions = [
      [0.05, 0.08, 28.0],
      [0.15, 0.15, 18.0],
      [0.82, 0.05, 32.0],
      [0.93, 0.18, 20.0],
      [0.02, 0.45, 22.0],
      [0.90, 0.42, 24.0],
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
