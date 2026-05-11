import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  String? _selectedBloodType;
  final List<String> _bloodTypes = [
    'Any',
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
  ];

  final List<_DonorModel> _donors = [
    const _DonorModel('Kasun Perera', 'O+', 'Negombo', 1.2, true),
    const _DonorModel('Dilani Silva', 'A+', 'Colombo', 5.4, true),
    const _DonorModel('Ranjith Fernando', 'B−', 'Kandy', 12.0, false),
    const _DonorModel('Nadeesha Gunawardena', 'AB+', 'Gampaha', 3.8, true),
    const _DonorModel('Chamara Jayasinghe', 'O−', 'Negombo', 0.8, true),
    const _DonorModel('Thilini Wickramasinghe', 'A−', 'Colombo', 7.2, false),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _donors.where((d) {
      if (_selectedBloodType == null || _selectedBloodType == 'Any') {
        return true;
      }
      return d.bloodType == _selectedBloodType;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Find Donors'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or location...',
                prefixIcon: Icon(Icons.search_outlined),
                suffixIcon: Icon(Icons.tune_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Blood type filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bloodTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final bt = _bloodTypes[i];
                final isSelected =
                    _selectedBloodType == bt ||
                    (_selectedBloodType == null && bt == 'Any');
                return FilterChip(
                  label: Text(bt),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedBloodType = bt),
                  selectedColor: AppTheme.primaryRed,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: AppTheme.surfaceGrey,
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} donors found',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Donor list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DonorCard(donor: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final _DonorModel donor;
  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFFEBEE),
            child: Text(
              donor.name[0],
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      donor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (donor.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppTheme.textGrey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${donor.location} • ${donor.distance} km away',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Blood type + contact
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donor.bloodType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.phone_outlined,
                  color: AppTheme.primaryRed,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonorModel {
  final String name;
  final String bloodType;
  final String location;
  final double distance;
  final bool isAvailable;

  const _DonorModel(
    this.name,
    this.bloodType,
    this.location,
    this.distance,
    this.isAvailable,
  );
}
