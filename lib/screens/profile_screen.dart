import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/rating_service.dart';
import '../widgets/star_rating.dart';
import 'donation_history_screen.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _isAvailable = true;
  bool _isUpdatingLocation = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkEligibilityAndLoad();
  }

  Future<void> _checkEligibilityAndLoad() async {
    await DatabaseService.checkAndUpdateEligibility();
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = await AuthService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _isAvailable = data?['isAvailable'] ?? true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Pick & Upload Photo ────────────────────────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70, // Compress to keep base64 small
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      // Read file and convert to base64
      final File file = File(image.path);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoBase64': base64String});

        await _loadUserData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Show photo picker options ──────────────────────────────────────────────
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
            const Text(
              'Update Profile Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),

            // Camera option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFFB71C1C)),
              ),
              title: const Text('Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Use your camera', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Color(0xFF9E9E9E)),
            ),

            // Gallery option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Colors.blue),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Pick from your photos',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Color(0xFF9E9E9E)),
            ),

            // Remove photo option
            if (_userData?['photoBase64'] != null)
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'photoBase64': null});
                    await _loadUserData();
                  }
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.grey),
                ),
                title: const Text('Remove Photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Toggle availability ────────────────────────────────────────────────────
  // ── Update Location ────────────────────────────────────────────────────────
  Future<void> _updateLocation() async {
    setState(() => _isUpdatingLocation = true);

    final success = await LocationService.saveLocationToFirestore();

    if (mounted) {
      setState(() => _isUpdatingLocation = false);
      if (success) {
        await _loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '❌ Could not get location. Please allow location permission.'),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isAvailable': value});
    }
  }

  // ── Record donation dialog ─────────────────────────────────────────────────
  void _showRecordDonationDialog() {
    final hospitalController = TextEditingController();
    final bloodType = _userData?['bloodType'] ?? 'O+';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Color(0xFFB71C1C)),
            SizedBox(width: 8),
            Text('Record Donation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Recording a donation will mark you unavailable for 90 days.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hospitalController,
              decoration: InputDecoration(
                labelText: 'Hospital Name',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.local_hospital_outlined,
                    color: Color(0xFFBDBDBD)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFB71C1C), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Blood type: $bloodType',
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (hospitalController.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await DatabaseService.recordDonation(
                  hospital: hospitalController.text.trim(),
                  bloodType: bloodType,
                );
                await _checkEligibilityAndLoad();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '✅ Donation recorded! Eligible again in 90 days.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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

    final name = _userData?['name'] ?? 'User';
    final phone = _userData?['phone'] ?? '';
    final bloodType = _userData?['bloodType'] ?? '?';
    final role = _userData?['role'] ?? 'donor';
    final totalDonations = _userData?['totalDonations'] ?? 0;
    final isDonor = role == 'donor';
    final nextEligibleDate = _userData?['nextEligibleDate'];
    final daysLeft = DatabaseService.getDaysUntilEligible(nextEligibleDate);
    final photoBase64 = _userData?['photoBase64'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A1A1A)),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkEligibilityAndLoad,
        color: const Color(0xFFB71C1C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Profile Header ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFEBEE), Colors.white],
                  ),
                ),
                child: Column(
                  children: [
                    // ── Profile Photo ──────────────────────────────
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Avatar / Photo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFB71C1C),
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFFB71C1C)))
                                  : photoBase64 != null
                                      ? Image.memory(
                                          base64Decode(photoBase64),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _defaultAvatar(name),
                                        )
                                      : _defaultAvatar(name),
                            ),
                          ),

                          // Camera icon overlay
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB71C1C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),

                          // Blood type badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bloodType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to change photo',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isDonor ? 'Donor' : 'Recipient'} • $phone',
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF9E9E9E)),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(
                            value: totalDonations.toString(),
                            label: 'Donations'),
                        _divider(),
                        _StatItem(
                            value: (totalDonations * 3).toString(),
                            label: 'Lives\nImpacted'),
                        _divider(),
                        _StatItem(value: bloodType, label: 'Blood\nType'),
                      ],
                    ),

                    // Rating display for donors
                    if (isDonor) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFB300)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFB300), size: 22),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  RatingService.getAverageRating(
                                              _userData ?? {}) ==
                                          0
                                      ? 'No ratings yet'
                                      : RatingService.getAverageRating(
                                              _userData ?? {})
                                          .toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                                Text(
                                  '${RatingService.getRatingCount(_userData ?? {})} rating${RatingService.getRatingCount(_userData ?? {}) != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF9E9E9E)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            StarDisplay(
                              rating: RatingService.getAverageRating(
                                  _userData ?? {}),
                              count:
                                  RatingService.getRatingCount(_userData ?? {}),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Donor eligibility section
                    if (isDonor) ...[
                      const SizedBox(height: 16),
                      if (_isAvailable)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Available to Donate',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isAvailable,
                                onChanged: _toggleAvailability,
                                activeThumbColor: Colors.green,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.timer_outlined,
                                      color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Not Eligible Yet',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$daysLeft days remaining',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${90 - daysLeft}/90 days',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.orange),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      daysLeft > 0 ? (90 - daysLeft) / 90 : 1.0,
                                  backgroundColor:
                                      Colors.orange.withValues(alpha: 0.2),
                                  color: Colors.orange,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (_isAvailable)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showRecordDonationDialog,
                              icon: const Icon(Icons.water_drop,
                                  color: Colors.white),
                              label: const Text('Record a Donation',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Info Card ───────────────────────────────────────────
              _SectionCard(
                title: 'Personal Information',
                children: [
                  _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: name),
                  _InfoRow(
                      icon: Icons.phone_outlined, label: 'Phone', value: phone),
                  _InfoRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Blood Type',
                      value: bloodType),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: _userData?['location'] ?? 'Not set'),
                  _InfoRow(
                      icon: Icons.volunteer_activism_outlined,
                      label: 'Role',
                      value: isDonor ? 'Blood Donor' : 'Blood Recipient'),
                ],
              ),

              _SectionCard(
                title: 'Account',
                children: [
                  _MenuItem(
                    icon: Icons.history_outlined,
                    title: 'Donation History',
                    subtitle: '$totalDonations donations made',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DonationHistoryScreen()),
                    ),
                  ),
                  _LocationMenuItem(
                    isUpdating: _isUpdatingLocation,
                    location: _userData?['location'] ?? 'Not set',
                    onTap: _updateLocation,
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage alerts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen()),
                    ),
                  ),
                ],
              ),

              _SectionCard(
                title: 'More',
                children: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help anytime',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About HopeDrop',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                ],
              ),

              // ── Logout ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_outlined,
                        color: Color(0xFFB71C1C)),
                    label: const Text('Logout',
                        style: TextStyle(
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFB71C1C), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Default avatar widget ──────────────────────────────────────────────────
  Widget _defaultAvatar(String name) {
    return Container(
      color: const Color(0xFFFFEBEE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: const Color(0xFFE0E0E0),
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  // ── Edit dialog ────────────────────────────────────────────────────────────
  void _showEditDialog() {
    final nameController =
        TextEditingController(text: _userData?['name'] ?? '');
    final phoneController =
        TextEditingController(text: _userData?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon:
                    const Icon(Icons.person_outline, color: Color(0xFFBDBDBD)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon:
                    const Icon(Icons.phone_outlined, color: Color(0xFFBDBDBD)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                });
                await _loadUserData();
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C))),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9E9E9E), height: 1.3)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                    letterSpacing: 0.5)),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFB71C1C), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationMenuItem extends StatelessWidget {
  final bool isUpdating;
  final String location;
  final VoidCallback onTap;

  const _LocationMenuItem({
    required this.isUpdating,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isUpdating ? null : onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isUpdating
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    color: Color(0xFFB71C1C), strokeWidth: 2),
              )
            : const Icon(Icons.location_on_outlined,
                color: Color(0xFFB71C1C), size: 20),
      ),
      title: const Text('My Location',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A))),
      subtitle: Text(
        isUpdating ? 'Getting location...' : location,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
      ),
      trailing: isUpdating
          ? null
          : const Icon(Icons.my_location, color: Color(0xFFB71C1C), size: 18),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFB71C1C), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A))),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
    );
  }
}
