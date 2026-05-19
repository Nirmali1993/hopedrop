import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _bloodRequestAlerts = true;
  bool _nearbyRequests = true;
  bool _myBloodTypeOnly = false;
  bool _donorResponses = true;
  bool _appSounds = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        final settings = data?['notificationSettings'] as Map<String, dynamic>?;

        if (settings != null && mounted) {
          setState(() {
            _bloodRequestAlerts = settings['bloodRequestAlerts'] ?? true;
            _nearbyRequests = settings['nearbyRequests'] ?? true;
            _myBloodTypeOnly = settings['myBloodTypeOnly'] ?? false;
            _donorResponses = settings['donorResponses'] ?? true;
            _appSounds = settings['appSounds'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationSettings': {
            'bloodRequestAlerts': _bloodRequestAlerts,
            'nearbyRequests': _nearbyRequests,
            'myBloodTypeOnly': _myBloodTypeOnly,
            'donorResponses': _donorResponses,
            'appSounds': _appSounds,
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Settings saved!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFB71C1C),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFFB71C1C).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            color: Color(0xFFB71C1C), size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Manage how you receive alerts for blood requests and donations.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB71C1C),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Blood Requests section
                  _SectionTitle(title: 'Blood Requests'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _ToggleItem(
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFFB71C1C),
                        title: 'Blood Request Alerts',
                        subtitle: 'Get notified when someone needs blood',
                        value: _bloodRequestAlerts,
                        onChanged: (val) =>
                            setState(() => _bloodRequestAlerts = val),
                      ),
                      const Divider(height: 1, indent: 60),
                      _ToggleItem(
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.orange,
                        title: 'Nearby Requests',
                        subtitle: 'Requests in your area only',
                        value: _nearbyRequests,
                        onChanged: _bloodRequestAlerts
                            ? (val) => setState(() => _nearbyRequests = val)
                            : null,
                      ),
                      const Divider(height: 1, indent: 60),
                      _ToggleItem(
                        icon: Icons.bloodtype_outlined,
                        iconColor: Colors.purple,
                        title: 'My Blood Type Only',
                        subtitle: 'Only show matching blood type requests',
                        value: _myBloodTypeOnly,
                        onChanged: _bloodRequestAlerts
                            ? (val) => setState(() => _myBloodTypeOnly = val)
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Donor Activity section
                  _SectionTitle(title: 'Donor Activity'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _ToggleItem(
                        icon: Icons.people_outline,
                        iconColor: Colors.green,
                        title: 'Donor Responses',
                        subtitle: 'When a donor responds to your request',
                        value: _donorResponses,
                        onChanged: (val) =>
                            setState(() => _donorResponses = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // App Settings section
                  _SectionTitle(title: 'App Settings'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _ToggleItem(
                        icon: Icons.volume_up_outlined,
                        iconColor: Colors.blue,
                        title: 'App Sounds',
                        subtitle: 'Play sound for notifications',
                        value: _appSounds,
                        onChanged: (val) => setState(() => _appSounds = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFB71C1C),
            ),
          ],
        ),
      ),
    );
  }
}
