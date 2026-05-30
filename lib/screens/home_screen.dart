import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'donor_home_tab.dart';
import 'recipient_home_tab.dart';
import 'all_requests_screen.dart';
import 'blood_request_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await AuthService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW — get translations
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
        ),
      );
    }

    final role = _userData?['role'] ?? 'donor';
    final isDonor = role == 'donor';

    final List<Widget> screens = isDonor
        ? [
            DonorHomeTab(userData: _userData),
            AllRequestsScreen(
                isDonorEligible: _userData?['isAvailable'] ?? true),
            const MapScreen(),
            const ProfileScreen(),
          ]
        : [
            RecipientHomeTab(userData: _userData),
            const BloodRequestScreen(),
            const MapScreen(),
            const ProfileScreen(),
          ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        indicatorColor: const Color(0xFFB71C1C).withValues(alpha: 0.12),
        // ✅ UPDATED — using l10n translations
        destinations: isDonor
            ? [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon:
                      const Icon(Icons.home, color: Color(0xFFB71C1C)),
                  label: l10n.home, // ✅ Home / මුල් පිටුව / முகப்பு
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_border),
                  selectedIcon:
                      const Icon(Icons.favorite, color: Color(0xFFB71C1C)),
                  label: l10n.requests, // ✅ Requests / ඉල්ලීම් / கோரிக்கைகள்
                ),
                NavigationDestination(
                  icon: const Icon(Icons.location_on_outlined),
                  selectedIcon:
                      const Icon(Icons.location_on, color: Color(0xFFB71C1C)),
                  label: l10n.map, // ✅ Map / සản / வản
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon:
                      const Icon(Icons.person, color: Color(0xFFB71C1C)),
                  label: l10n.profile, // ✅ Profile / පැතිකඩ / சுயவிவரம்
                ),
              ]
            : [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon:
                      const Icon(Icons.home, color: Color(0xFFB71C1C)),
                  label: l10n.home, // ✅
                ),
                NavigationDestination(
                  icon: const Icon(Icons.add_circle_outline),
                  selectedIcon:
                      const Icon(Icons.add_circle, color: Color(0xFFB71C1C)),
                  label: l10n.requests, // ✅
                ),
                NavigationDestination(
                  icon: const Icon(Icons.location_on_outlined),
                  selectedIcon:
                      const Icon(Icons.location_on, color: Color(0xFFB71C1C)),
                  label: l10n.map, // ✅
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon:
                      const Icon(Icons.person, color: Color(0xFFB71C1C)),
                  label: l10n.profile, // ✅
                ),
              ],
      ),
    );
  }
}
