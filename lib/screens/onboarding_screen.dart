import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hopedrop/l10n/app_localizations.dart';
import '../services/language_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showLanguagePicker() {
    final langService = Provider.of<LanguageService>(context, listen: false);

    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'name': 'Sinhala', 'native': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇱🇰'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  // ✅ TRANSLATED
                  Text(l10n.selectLanguageTitle,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A))),
                ],
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected =
                    langService.currentLocale.languageCode == lang['code'];
                return GestureDetector(
                  onTap: () async {
                    await langService.changeLanguage(lang['code']!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFB71C1C)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang['native']!,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A))),
                              Text(lang['name']!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9E9E9E))),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: Color(0xFFB71C1C), size: 24),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW
    final langService = Provider.of<LanguageService>(context);
    final currentLang =
        langService.getLanguageName(langService.currentLocale.languageCode);
    final currentFlag =
        langService.getFlagEmoji(langService.currentLocale.languageCode);

    // ✅ TRANSLATED pages — built dynamically from l10n
    final pages = [
      _OnboardData(
        imagePath: 'assets/images/img_woman_donate_bl.png',
        fallbackIcon: Icons.local_hospital_outlined,
        title: l10n.onboard1Title,
        subtitle: l10n.onboard1Subtitle,
      ),
      _OnboardData(
        imagePath: 'assets/images/needblood2.jpg',
        fallbackIcon: Icons.water_drop_outlined,
        title: l10n.onboard2Title,
        subtitle: l10n.onboard2Subtitle,
      ),
      _OnboardData(
        imagePath: 'assets/images/findblood3.jpg',
        fallbackIcon: Icons.favorite_outline,
        title: l10n.onboard3Title,
        subtitle: l10n.onboard3Subtitle,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — Language + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language selector button
                  GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentFlag,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(currentLang,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Color(0xFF9E9E9E)),
                        ],
                      ),
                    ),
                  ),

                  // ✅ TRANSLATED Skip button
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages — ✅ now uses translated data
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardPage(data: pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? const Color(0xFFB71C1C)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToLogin();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      // ✅ TRANSLATED Next/Get Started
                      child: Text(
                        _currentPage == pages.length - 1
                            ? l10n.getStarted
                            : l10n.next,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  const _OnboardPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    data.fallbackIcon,
                    size: 100,
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // ✅ Now shows translated title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          // ✅ Now shows translated subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  final String imagePath;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;

  // ✅ No longer const — titles come from l10n
  const _OnboardData({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
  });
}
