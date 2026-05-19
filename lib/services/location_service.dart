import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  // ── Get current location and convert to city name ──────────────────────────
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get GPS coordinates
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Convert coordinates to address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Unknown';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Build location string: area, city
        final parts = [
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((p) => p != null && p.isNotEmpty).toList();

        locationName = parts.isNotEmpty ? parts.take(2).join(', ') : 'Unknown';
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': locationName,
      };
    } catch (e) {
      return null;
    }
  }

  // ── Save location to Firestore ─────────────────────────────────────────────
  static Future<bool> saveLocationToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final locationData = await getCurrentLocation();
    if (locationData == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'location': locationData['locationName'],
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'locationUpdatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
