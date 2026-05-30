import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hopedrop/l10n/app_localizations.dart';
import '../services/database_service.dart';

class AllRequestsScreen extends StatefulWidget {
  final bool isDonorEligible;
  const AllRequestsScreen({super.key, this.isDonorEligible = true});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  String _selectedBloodType = 'Any';
  String _selectedUrgency = 'All';

  final List<String> _bloodTypes = [
    'Any',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> _urgencies = ['All', 'Urgent', 'High', 'Normal'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.allRequests,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Blood type chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bloodTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bt = _bloodTypes[i];
                final isSelected = _selectedBloodType == bt;
                final label = bt == 'Any' ? l10n.all : bt;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedBloodType = bt),
                  selectedColor: const Color(0xFFB71C1C),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: const Color(0xFFF5F5F5),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Urgency chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _urgencies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final u = _urgencies[i];
                final isSelected = _selectedUrgency == u;
                final color = u == 'Urgent'
                    ? const Color(0xFFB71C1C)
                    : u == 'High'
                        ? Colors.orange
                        : u == 'Normal'
                            ? Colors.green
                            : const Color(0xFF1A1A1A);

                final label = u == 'Urgent'
                    ? l10n.urgent
                    : u == 'High'
                        ? l10n.high
                        : u == 'Normal'
                            ? l10n.normal
                            : l10n.all;

                return GestureDetector(
                  onTap: () => setState(() => _selectedUrgency = u),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                      ),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: isSelected ? color : const Color(0xFF9E9E9E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: DatabaseService.getActiveBloodRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop_outlined,
                            size: 64, color: Color(0xFFB71C1C)),
                        const SizedBox(height: 16),
                        Text(l10n.noRequestsYet,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A))),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final btMatch = _selectedBloodType == 'Any' ||
                      data['bloodType'] == _selectedBloodType;
                  final urgMatch = _selectedUrgency == 'All' ||
                      data['urgency'] == _selectedUrgency;
                  return btMatch && urgMatch;
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${docs.length} ${l10n.active}',
                            style: const TextStyle(
                                color: Color(0xFF9E9E9E), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          return _RequestCard(
                            requestId: doc.id,
                            data: data,
                            isDonorEligible: widget.isDonorEligible,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final bool isDonorEligible;

  const _RequestCard({
    required this.requestId,
    required this.data,
    this.isDonorEligible = true,
  });

  Color get _urgencyColor {
    switch (data['urgency']) {
      case 'Urgent':
        return const Color(0xFFB71C1C);
      case 'High':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bloodType = data['bloodType'] ?? '?';
    final hospital = data['hospital'] ?? 'Unknown';
    final location = data['location'] ?? '';
    final units = data['units'] ?? 1;
    final urgency = data['urgency'] ?? 'Normal';
    final patientName = data['patientName'] ?? '';

    final urgencyLabel = urgency == 'Urgent'
        ? l10n.urgent
        : urgency == 'High'
            ? l10n.high
            : l10n.normal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A))),
                if (patientName.isNotEmpty)
                  Text(patientName,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (location.isNotEmpty) ...[
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(location,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9E9E9E))),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text('$units ${l10n.unitNeeded}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(urgencyLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: _urgencyColor,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              if (isDonorEligible)
                ElevatedButton(
                  onPressed: () async {
                    await DatabaseService.respondToRequest(requestId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ ${l10n.responded}!'),
                          backgroundColor: const Color(0xFFB71C1C),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    minimumSize: const Size(56, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(l10n.respond),
                )
              else
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
