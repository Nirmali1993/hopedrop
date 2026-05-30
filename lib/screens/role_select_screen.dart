import 'package:flutter/material.dart';
import 'package:hopedrop/l10n/app_localizations.dart';
import 'register_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(height: 36),

              // ✅ TRANSLATED Title
              Text(
                l10n.chooseYourRole,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 48),

              // ✅ TRANSLATED Donor card
              _RoleCard(
                imagePath: 'assets/images/img_woman_donate_bl.png',
                fallbackIcon: Icons.volunteer_activism,
                title: l10n.iAmDonor,
                subtitle: l10n.donorDescription,
                role: 'donor',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(role: 'donor'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ TRANSLATED Recipient card
              _RoleCard(
                imagePath: 'assets/images/img_woman_donate_bl.png',
                fallbackIcon: Icons.search,
                title: l10n.iAmRecipient,
                subtitle: l10n.recipientDescription,
                role: 'recipient',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(role: 'recipient'),
                  ),
                ),
              ),

              const Spacer(),

              // ✅ TRANSLATED Already have account
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text.rich(
                    TextSpan(
                      text: '${l10n.alreadyHaveAccount} ',
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 14),
                      children: [
                        TextSpan(
                          text: l10n.login,
                          style: const TextStyle(
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final String role;
  final VoidCallback onTap;

  const _RoleCard({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    size: 36,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E), height: 1.4)),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
