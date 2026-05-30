import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ NEW
import '../services/auth_service.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng _currentLocation =
      const LatLng(7.8731, 80.7718);
  bool _isLocating = true;
  bool _locationPermissionDenied = false;
  String? _userRole;
  bool _isDonorEligible = false;
  String _searchQuery = '';
  String _selectedBloodType = 'Any';
  List<Marker> _markers = [];

  final List<String> _bloodTypes = [
    'Any', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndLocation() async {
    await _loadUserRole();
    await _getCurrentLocation();
    await _loadMarkers();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await AuthService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userRole = data?['role'] ?? 'donor';
          _isDonorEligible = data?['isAvailable'] ?? false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
            _isLocating = false;
          });
        }
        return;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _currentLocation =
                LatLng(position.latitude, position.longitude);
            _isLocating = false;
          });
          _mapController.move(_currentLocation, 13);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _loadMarkers() async {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW
    final isDonor = _userRole == 'donor';
    final List<Marker> markers = [];

    // ✅ TRANSLATED "You" marker
    markers.add(
      Marker(
        point: _currentLocation,
        width: 60, height: 60,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location,
                  color: Colors.white, size: 18),
            ),
            // ✅ TRANSLATED
            Text(l10n.you,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
          ],
        ),
      ),
    );

    if (isDonor) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('blood_requests')
            .where('status', isEqualTo: 'active')
            .get();

        for (int i = 0; i < snapshot.docs.length; i++) {
          final data = snapshot.docs[i].data();
          final bloodType = data['bloodType'] ?? '?';
          final hospital = data['hospital'] ?? '';
          final urgency = data['urgency'] ?? 'Normal';

          final color = urgency == 'Urgent'
              ? const Color(0xFFB71C1C)
              : urgency == 'High'
                  ? Colors.orange
                  : Colors.green;

          final lat =
              _currentLocation.latitude + (i * 0.008) - 0.02;
          final lng =
              _currentLocation.longitude + (i * 0.008) - 0.02;

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 70, height: 70,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(bloodType,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    hospital.length > 8
                        ? '${hospital.substring(0, 8)}..'
                        : hospital,
                    style: TextStyle(
                        fontSize: 8,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {}
    } else {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'donor')
            .where('isAvailable', isEqualTo: true)
            .get();

        for (int i = 0; i < snapshot.docs.length; i++) {
          final data = snapshot.docs[i].data();
          final name = data['name'] ?? l10n.donor;
          final bloodType = data['bloodType'] ?? '?';

          final lat =
              _currentLocation.latitude + (i * 0.008) - 0.02;
          final lng =
              _currentLocation.longitude + (i * 0.008) - 0.02;

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 70, height: 70,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB71C1C)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(bloodType,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    name.split(' ')[0],
                    style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW
    final isDonor = _userRole == 'donor';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ✅ TRANSLATED
        title: Text(
          isDonor
              ? l10n.nearbyBloodRequests
              : l10n.findDonorsNearby,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location,
                color: Color(0xFFB71C1C)),
            onPressed: () =>
                _mapController.move(_currentLocation, 14),
          ),
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Color(0xFFB71C1C)),
            onPressed: _loadMarkers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ TRANSLATED Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                // ✅ TRANSLATED
                hintText: isDonor
                    ? l10n.searchByHospital
                    : l10n.searchDonorsByName,
                hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.search_outlined,
                    color: Color(0xFFBDBDBD)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFFBDBDBD)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        })
                    : const Icon(Icons.location_on_outlined,
                        color: Color(0xFFB71C1C)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFB71C1C), width: 1.5)),
              ),
            ),
          ),

          // Blood type filter
          if (!isDonor) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _bloodTypes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final bt = _bloodTypes[i];
                  final isSelected = _selectedBloodType == bt;
                  // ✅ TRANSLATED "Any"
                  final label = bt == 'Any' ? l10n.all : bt;
                  return GestureDetector(
                    onTap: () {
                      setState(
                          () => _selectedBloodType = bt);
                      _loadMarkers();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFFF5F5F5),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ✅ TRANSLATED Not eligible warning
          if (isDonor && !_isDonorEligible)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  // ✅ TRANSLATED
                  Expanded(
                    child: Text(l10n.notEligibleYetShort,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

          // ✅ TRANSLATED Location denied warning
          if (_locationPermissionDenied)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFB71C1C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: Color(0xFFB71C1C), size: 18),
                  const SizedBox(width: 8),
                  // ✅ TRANSLATED
                  Expanded(
                    child: Text(l10n.locationDenied,
                        style: const TextStyle(
                            color: Color(0xFFB71C1C),
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Stack(
              children: [
                _isLocating
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFFB71C1C)),
                            const SizedBox(height: 16),
                            // ✅ TRANSLATED
                            Text(l10n.gettingLocation,
                                style: const TextStyle(
                                    color: Color(0xFF9E9E9E))),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation,
                          initialZoom: 13,
                          minZoom: 5,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.hopedrop',
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),

                // ✅ TRANSLATED Map legend
                if (!_isLocating)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: isDonor
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _LegendItem(
                                    color: const Color(
                                        0xFFB71C1C),
                                    // ✅ TRANSLATED
                                    label: l10n.urgent),
                                const SizedBox(height: 4),
                                _LegendItem(
                                    color: Colors.orange,
                                    label: l10n.high),
                                const SizedBox(height: 4),
                                _LegendItem(
                                    color: Colors.green,
                                    label: l10n.normal),
                                const SizedBox(height: 4),
                                _LegendItem(
                                    color: Colors.blue,
                                    label: l10n.you),
                              ],
                            )
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _LegendItem(
                                    color: const Color(
                                        0xFFB71C1C),
                                    label: l10n.donor),
                                const SizedBox(height: 4),
                                _LegendItem(
                                    color: Colors.blue,
                                    label: l10n.you),
                              ],
                            ),
                    ),
                  ),

                // ✅ TRANSLATED Bottom sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.12,
                  maxChildSize: 0.75,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 16,
                              offset: Offset(0, -4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin:
                                const EdgeInsets.only(top: 10),
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius:
                                  BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  isDonor
                                      ? Icons
                                          .water_drop_outlined
                                      : Icons.people_outline,
                                  color: const Color(0xFFB71C1C),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                // ✅ TRANSLATED
                                Text(
                                  isDonor
                                      ? l10n.nearbyBloodRequests
                                      : l10n.nearbyDonors,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: isDonor
                                ? _RequestsList(
                                    scrollController:
                                        scrollController,
                                    searchQuery: _searchQuery,
                                    isDonorEligible:
                                        _isDonorEligible,
                                  )
                                : _DonorsList(
                                    scrollController:
                                        scrollController,
                                    searchQuery: _searchQuery,
                                    selectedBloodType:
                                        _selectedBloodType,
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend Item ────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(
      {required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF1A1A1A))),
      ],
    );
  }
}

// ── Blood Requests List ────────────────────────────────────────────────────────

class _RequestsList extends StatefulWidget {
  final ScrollController scrollController;
  final String searchQuery;
  final bool isDonorEligible;

  const _RequestsList({
    required this.scrollController,
    required this.searchQuery,
    required this.isDonorEligible,
  });

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  List<QueryDocumentSnapshot> _cached = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService.getActiveBloodRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasData) _cached = snapshot.data!.docs;

        if (_cached.isEmpty &&
            snapshot.connectionState ==
                ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFB71C1C)));
        }

        if (_cached.isEmpty) {
          // ✅ TRANSLATED
          return Center(
              child: Text(l10n.noRequestsNearby,
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E))));
        }

        var filtered = _cached;
        if (widget.searchQuery.isNotEmpty) {
          filtered = _cached.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['hospital'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(widget.searchQuery) ||
                (data['location'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(widget.searchQuery);
          }).toList();
        }

        return ListView.separated(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data =
                filtered[i].data() as Map<String, dynamic>;
            return _RequestCard(
              requestId: filtered[i].id,
              data: data,
              isDonorEligible: widget.isDonorEligible,
            );
          },
        );
      },
    );
  }
}

// ── Request Card ───────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final bool isDonorEligible;

  const _RequestCard({
    required this.requestId,
    required this.data,
    required this.isDonorEligible,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    final bloodType = data['bloodType'] ?? '?';
    final hospital = data['hospital'] ?? '';
    final location = data['location'] ?? '';
    final units = data['units'] ?? 1;
    final urgency = data['urgency'] ?? 'Normal';
    final urgencyColor = urgency == 'Urgent'
        ? const Color(0xFFB71C1C)
        : urgency == 'High'
            ? Colors.orange
            : Colors.green;

    // ✅ TRANSLATED urgency label
    final urgencyLabel = urgency == 'Urgent'
        ? l10n.urgent
        : urgency == 'High'
            ? l10n.high
            : l10n.normal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(bloodType,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hospital,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 11, color: Color(0xFF9E9E9E)),
                  Flexible(
                    child: Text(location,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E))),
                  ),
                  const SizedBox(width: 4),
                  // ✅ TRANSLATED
                  Text('• $units ${l10n.unitNeeded}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                // ✅ TRANSLATED
                child: Text(urgencyLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: urgencyColor,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              if (isDonorEligible)
                ElevatedButton(
                  onPressed: () async {
                    await DatabaseService.respondToRequest(
                        requestId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text('✅ ${l10n.responded}!'),
                          backgroundColor:
                              const Color(0xFFB71C1C),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    minimumSize: const Size(48, 28),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8),
                    textStyle:
                        const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(7)),
                    elevation: 0,
                  ),
                  // ✅ TRANSLATED
                  child: Text(l10n.respond),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: Colors.orange, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donors List ────────────────────────────────────────────────────────────────

class _DonorsList extends StatefulWidget {
  final ScrollController scrollController;
  final String searchQuery;
  final String selectedBloodType;

  const _DonorsList({
    required this.scrollController,
    required this.searchQuery,
    required this.selectedBloodType,
  });

  @override
  State<_DonorsList> createState() => _DonorsListState();
}

class _DonorsListState extends State<_DonorsList> {
  List<QueryDocumentSnapshot> _cached = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    return StreamBuilder<QuerySnapshot>(
      stream: widget.selectedBloodType == 'Any'
          ? FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'donor')
              .snapshots()
          : FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'donor')
              .where('bloodType',
                  isEqualTo: widget.selectedBloodType)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) _cached = snapshot.data!.docs;

        if (_cached.isEmpty &&
            snapshot.connectionState ==
                ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFB71C1C)));
        }

        if (_cached.isEmpty) {
          // ✅ TRANSLATED
          return Center(
              child: Text(l10n.noDonorsFound,
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E))));
        }

        var filtered = _cached;
        if (widget.searchQuery.isNotEmpty) {
          filtered = _cached.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(widget.searchQuery);
          }).toList();
        }

        return ListView.separated(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data =
                filtered[i].data() as Map<String, dynamic>;
            return _DonorCard(data: data);
          },
        );
      },
    );
  }
}

// ── Donor Card ─────────────────────────────────────────────────────────────────

class _DonorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DonorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ NEW

    final name = data['name'] ?? 'Unknown';
    final bloodType = data['bloodType'] ?? '?';
    final isAvailable = data['isAvailable'] ?? false;
    final totalDonations = data['totalDonations'] ?? 0;
    final photoBase64 = data['photoBase64'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isAvailable
                          ? const Color(0xFFB71C1C)
                          : const Color(0xFFE0E0E0),
                      width: 2),
                ),
                child: ClipOval(
                  child: photoBase64 != null
                      ? Image.memory(
                          base64Decode(photoBase64),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) =>
                              _fallback(name, isAvailable),
                        )
                      : _fallback(name, isAvailable),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    // ✅ TRANSLATED
                    child: Text(
                        isAvailable
                            ? l10n.available
                            : l10n.unavailable,
                        style: TextStyle(
                            fontSize: 10,
                            color: isAvailable
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  // ✅ TRANSLATED
                  Text(
                      '$totalDonations ${l10n.donations}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E))),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(bloodType,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name, bool isAvailable) {
    return Container(
      color: isAvailable
          ? const Color(0xFFFFEBEE)
          : const Color(0xFFF5F5F5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isAvailable
                  ? const Color(0xFFB71C1C)
                  : Colors.grey),
        ),
      ),
    );
  }
}