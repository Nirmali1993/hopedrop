import 'dart:math';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart'; // Change to your next screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _taglineController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _taglineController.forward();
    });

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Hexagonal background pattern
          const HexagonBackground(),

          // Main content
          Column(
            children: [
              // Logo centered
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(),
                    ),
                  ),
                ),
              ),

              // Bottom tagline with heart
              FadeTransition(
                opacity: _taglineFade,
                child: SlideTransition(
                  position: _taglineSlide,
                  child: _buildTagline(),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Hope" in black
        const Text(
          'Hope',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -1,
          ),
        ),
        // "Dr" in dark red
        const Text(
          'Dr',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
            letterSpacing: -1,
          ),
        ),
        // Blood drop replacing 'o'
        Stack(
          alignment: Alignment.center,
          children: [
            // Drop shape
            CustomPaint(
              size: const Size(36, 48),
              painter: BloodDropPainter(),
            ),
            // Plus icon inside drop
            const Positioned(
              top: 12,
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ],
        ),
        // "p" in dark red
        const Text(
          'p',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red line above text
                Container(
                  height: 1.5,
                  color: const Color(0xFFB71C1C),
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                const Text(
                  'Donate\nSave Life.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB71C1C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Heart ECG image
          Image.asset(
            'assets/images/img_line_heart_1.png',
            width: 120,
            height: 70,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// ── Hexagonal Background Painter ──────────────────────────────────────────────

class HexagonBackground extends StatelessWidget {
  const HexagonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HexBackgroundPainter(),
      size: Size.infinite,
    );
  }
}

class HexBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCDD).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Scatter hexagons across the screen at different sizes
    final hexagons = [
      // top-left cluster
      _HexDef(size.width * 0.08, size.height * 0.06, 30),
      _HexDef(size.width * 0.14, size.height * 0.11, 20),
      _HexDef(size.width * 0.04, size.height * 0.16, 40),
      // top-right cluster
      _HexDef(size.width * 0.75, size.height * 0.04, 35),
      _HexDef(size.width * 0.88, size.height * 0.08, 22),
      _HexDef(size.width * 0.93, size.height * 0.18, 38),
      _HexDef(size.width * 0.82, size.height * 0.22, 18),
      // mid-left
      _HexDef(size.width * 0.05, size.height * 0.38, 42),
      _HexDef(size.width * 0.15, size.height * 0.45, 25),
      // mid-right
      _HexDef(size.width * 0.90, size.height * 0.40, 30),
      _HexDef(size.width * 0.78, size.height * 0.48, 20),
      // lower-left
      _HexDef(size.width * 0.08, size.height * 0.62, 36),
      _HexDef(size.width * 0.20, size.height * 0.68, 22),
      _HexDef(size.width * 0.06, size.height * 0.76, 16),
      // lower-right
      _HexDef(size.width * 0.85, size.height * 0.65, 40),
      _HexDef(size.width * 0.72, size.height * 0.72, 24),
      _HexDef(size.width * 0.90, size.height * 0.80, 18),
      // scattered center-edge
      _HexDef(size.width * 0.35, size.height * 0.08, 16),
      _HexDef(size.width * 0.60, size.height * 0.88, 22),
      _HexDef(size.width * 0.15, size.height * 0.55, 14),
      _HexDef(size.width * 0.88, size.height * 0.55, 14),
    ];

    for (final h in hexagons) {
      _drawHex(canvas, paint, h.x, h.y, h.radius);
    }
  }

  void _drawHex(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexDef {
  final double x, y, radius;
  const _HexDef(this.x, this.y, this.radius);
}

// ── Blood Drop Painter ─────────────────────────────────────────────────────────

class BloodDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Classic teardrop: pointed top, round bottom
    path.moveTo(w / 2, 0); // tip at top
    path.cubicTo(w * 0.9, h * 0.35, w, h * 0.6, w / 2, h * 0.92);
    path.cubicTo(0, h * 0.6, 0, h * 0.35, w / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
