import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
        ),
      );
    }

    final role = _userData?['role'] ?? 'donor';
    final isDonor = role == 'donor';

    // ── Donor tabs: Home | All Requests | Map | Profile ────────────────
    // ── Recipient tabs: Home | Request Blood | Map | Profile ───────────
    final List<Widget> screens = isDonor
        ? [
            DonorHomeTab(userData: _userData),
            AllRequestsScreen(isDonorEligible: _userData?['isAvailable'] ?? true),
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Bottom Nav ──────────────────────────────────────────────
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) =>
                setState(() => _selectedIndex = i),
            backgroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.black12,
            indicatorColor:
                const Color(0xFFB71C1C).withValues(alpha: 0.12),
            destinations: isDonor
                ? const [
                    // Donor: Home | Requests | Map | Profile
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon:
                          Icon(Icons.home, color: Color(0xFFB71C1C)),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite,
                          color: Color(0xFFB71C1C)),
                      label: 'Requests',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.location_on_outlined),
                      selectedIcon: Icon(Icons.location_on,
                          color: Color(0xFFB71C1C)),
                      label: 'Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person,
                          color: Color(0xFFB71C1C)),
                      label: 'Profile',
                    ),
                  ]
                : const [
                    // Recipient: Home | Request Blood | Map | Profile
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon:
                          Icon(Icons.home, color: Color(0xFFB71C1C)),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon: Icon(Icons.add_circle,
                          color: Color(0xFFB71C1C)),
                      label: 'Request',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.location_on_outlined),
                      selectedIcon: Icon(Icons.location_on,
                          color: Color(0xFFB71C1C)),
                      label: 'Map',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person,
                          color: Color(0xFFB71C1C)),
                      label: 'Profile',
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

// ── Ad Banner ──────────────────────────────────────────────────────────────────

class _AdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F8),
        border: Border(
          top: BorderSide(color: Color(0xFFFFE0E0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '🩸 Join HopeDrop Blood Drive — Save 3 lives with one donation!',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Learn More',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }
}