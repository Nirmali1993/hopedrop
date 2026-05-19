import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart'; // ✅ NEW

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Requests'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFB71C1C),
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: const Color(0xFFB71C1C),
          tabs: const [
            Tab(text: 'Post Request'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PostRequestTab(),
          _MyRequestsTab(),
        ],
      ),
    );
  }
}

// ── Post Request Tab ───────────────────────────────────────────────────────────

class _PostRequestTab extends StatefulWidget {
  const _PostRequestTab();

  @override
  State<_PostRequestTab> createState() => _PostRequestTabState();
}

class _PostRequestTabState extends State<_PostRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _locationController = TextEditingController();
  final _unitsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedBloodType;
  String _urgency = 'Urgent';
  bool _isLoading = false;

  final List<String> _bloodTypes = [
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−'
  ];
  final List<String> _urgencyLevels = ['Urgent', 'High', 'Normal'];

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalController.dispose();
    _locationController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ✅ NEW — Send notifications to matching donors
  Future<void> _notifyMatchingDonors(
      String bloodType, String hospital, String location) async {
    try {
      // Get all available donors with matching blood type
      final QuerySnapshot donors = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'donor')
          .where('bloodType', isEqualTo: bloodType)
          .where('isAvailable', isEqualTo: true)
          .get();

      print('📢 Found ${donors.docs.length} matching donors to notify');

      // Send notification to each donor
      for (final doc in donors.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final token = data['fcmToken'] as String?;

        if (token != null && token.isNotEmpty) {
          await NotificationService.sendNotificationToToken(
            token: token,
            title: '🩸 Urgent Blood Needed! ($bloodType)',
            body: '$hospital · $location needs $bloodType blood donors',
          );
          print('✅ Notified donor: ${data['name']}');
        }
      }
    } catch (e) {
      print('❌ Notification error: $e');
    }
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await DatabaseService.createBloodRequest(
        patientName: _patientNameController.text.trim(),
        bloodType: _selectedBloodType!,
        hospital: _hospitalController.text.trim(),
        location: _locationController.text.trim(),
        units: int.parse(_unitsController.text.trim()),
        urgency: _urgency,
        notes: _notesController.text.trim(),
      );

      // ✅ NEW — Automatically notify matching donors
      await _notifyMatchingDonors(
        _selectedBloodType!,
        _hospitalController.text.trim(),
        _locationController.text.trim(),
      );

      if (mounted) {
        _patientNameController.clear();
        _hospitalController.clear();
        _locationController.clear();
        _unitsController.clear();
        _notesController.clear();
        setState(() => _selectedBloodType = null);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Request Posted!'),
              ],
            ),
            content: const Text(
              'Your blood request has been posted. '
              'Nearby donors have been notified! '
              'Check "My Requests" tab to see who responds!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C)),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Urgency Level',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: _urgencyLevels.map((level) {
                final colors = {
                  'Urgent': const Color(0xFFB71C1C),
                  'High': Colors.orange,
                  'Normal': Colors.green,
                };
                final isSelected = _urgency == level;
                final color = colors[level]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _urgency = level),
                    child: Container(
                      margin: EdgeInsets.only(right: level != 'Normal' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        level,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? color : const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildField(
                controller: _patientNameController,
                hint: 'Patient Name',
                icon: Icons.person_outline),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              decoration: _inputDecoration(
                  hint: 'Blood Type Needed', icon: Icons.water_drop_outlined),
              items: _bloodTypes
                  .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBloodType = v),
              validator: (v) => v == null ? 'Please select blood type' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
                controller: _hospitalController,
                hint: 'Hospital Name',
                icon: Icons.local_hospital_outlined),
            const SizedBox(height: 14),
            _buildField(
                controller: _locationController,
                hint: 'Location (City)',
                icon: Icons.location_on_outlined),
            const SizedBox(height: 14),
            _buildField(
                controller: _unitsController,
                hint: 'Units Required',
                icon: Icons.science_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: _inputDecoration(
                hint: 'Additional Notes (optional)',
                icon: Icons.notes_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Post Blood Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint, icon: icon),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: const Color(0xFFBDBDBD)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5)),
    );
  }
}

// ── My Requests Tab ────────────────────────────────────────────────────────────

class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('blood_requests')
          .where('requestedBy', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop_outlined,
                    size: 64, color: Color(0xFFB71C1C)),
                SizedBox(height: 16),
                Text(
                  'No requests yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                SizedBox(height: 8),
                Text(
                  'Post a blood request\nfrom the first tab',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final respondedBy = List<String>.from(data['respondedBy'] ?? []);

            return _MyRequestCard(
              requestId: doc.id,
              data: data,
              respondedBy: respondedBy,
            );
          },
        );
      },
    );
  }
}

// ── My Request Card ────────────────────────────────────────────────────────────

class _MyRequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final List<String> respondedBy;

  const _MyRequestCard({
    required this.requestId,
    required this.data,
    required this.respondedBy,
  });

  @override
  Widget build(BuildContext context) {
    final bloodType = data['bloodType'] ?? '?';
    final hospital = data['hospital'] ?? '';
    final location = data['location'] ?? '';
    final units = data['units'] ?? 1;
    final urgency = data['urgency'] ?? 'Normal';
    final status = data['status'] ?? 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
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
                  child: Text(
                    bloodType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '$location • $units units • $urgency',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'active'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'active' ? 'Active' : 'Fulfilled',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == 'active' ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: Color(0xFFB71C1C)),
                    const SizedBox(width: 6),
                    Text(
                      '${respondedBy.length} donor${respondedBy.length != 1 ? 's' : ''} responded',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFFB71C1C),
                      ),
                    ),
                  ],
                ),
                if (respondedBy.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No responses yet. Waiting for donors...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  )
                else
                  Column(
                    children: respondedBy
                        .map((uid) => _DonorResponseItem(uid: uid))
                        .toList(),
                  ),
                if (status == 'active' && respondedBy.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await DatabaseService.fulfillRequest(requestId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Request marked as fulfilled!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        label: const Text('Mark as Fulfilled',
                            style: TextStyle(color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Donor Response Item ────────────────────────────────────────────────────────

class _DonorResponseItem extends StatelessWidget {
  final String uid;
  const _DonorResponseItem({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: LinearProgressIndicator(color: Color(0xFFB71C1C)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? 'Unknown Donor';
        final phone = data?['phone'] ?? '';
        final bloodType = data?['bloodType'] ?? '?';

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Blood: $bloodType • $phone',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📞 Call $name: $phone'),
                      backgroundColor: const Color(0xFFB71C1C),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
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
      },
    );
  }
}
