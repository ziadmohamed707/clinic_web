import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  // Define your clinic's location coordinates
  // Example: Cairo Festival City, you should update this to your actual clinic location.
  static const double clinicLatitude = 30.0568;
  static const double clinicLongitude = 31.4086;

  // Define the maximum allowed distance in meters.
  static const double maxAllowedDistanceMeters =
      50; // 50 meters radius as requested

  /// Checks for location permission and requests it if not granted.
  /// Returns `true` if permission is granted, otherwise `false`.
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, we cannot continue.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, we cannot continue.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    return true;
  }

  /// Gets the current position and validates if it's within the clinic's radius.
  /// Returns the `Position` if valid, otherwise throws an exception.
  Future<Position> validateLocationAndGetPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      throw Exception(
        'Location permissions are denied. Please enable them in your device settings.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
      forceAndroidLocationManager: true, // Helps on some Android devices
    );

    final double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      clinicLatitude,
      clinicLongitude,
    );

    if (distanceInMeters > maxAllowedDistanceMeters) {
      throw Exception(
        'You are too far from the clinic to check in. Distance: ${distanceInMeters.toStringAsFixed(0)}m',
      );
    }

    return position;
  }

  /// Gets the current position without validating the distance from the clinic.
  /// Returns the `Position` if successful, otherwise throws an exception.
  Future<Position> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      throw Exception(
        'Location permissions are denied. Please enable them in your device settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
      forceAndroidLocationManager: true, // Helps on some Android devices
    );
  }

  /// Converts a Position (latitude and longitude) into a human-readable address string.
  Future<String> getAddressFromPosition(Position position) async {
    if (kIsWeb) {
      // Use Nominatim for web, as it doesn't require an API key.
      return _getAddressFromNominatim(position);
    } else {
      // Use the geocoding package for mobile.
      return _getAddressFromGeocodingPackage(position);
    }
  }

  /// Reverse geocoding using the geocoding package (for mobile).
  Future<String> _getAddressFromGeocodingPackage(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
      } else {
        return 'No address found for the current location.';
      }
    } catch (e) {
      print('Geocoding Error: $e');
      return 'Could not get address. Please check network and API setup.';
    }
  }

  /// Reverse geocoding using OpenStreetMap's Nominatim API (for web).
  Future<String> _getAddressFromNominatim(Position position) async {
    final url = Uri.parse(
      // Added 'addressdetails=1' to get more structured address data
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'PhysioOne/1.0',
        }, // Nominatim requires a User-Agent
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          // Construct a more relevant address from detailed parts
          final road = address['road'] ?? '';
          final suburb = address['suburb'] ?? '';
          final city =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          final country = address['country'] ?? '';

          // Combine parts into a cleaner address string
          String fullAddress = [
            road,
            suburb,
            city,
            country,
          ].where((s) => s.isNotEmpty).join(', ');
          return fullAddress.isNotEmpty
              ? fullAddress
              : (data['display_name'] ?? 'Address not found');
        } else {
          return 'No address found for the current location.';
        }
      } else {
        return 'Failed to fetch address. Status: ${response.statusCode}';
      }
    } catch (e) {
      print('Nominatim Geocoding Error: $e');
      return 'Could not get address. Please check your network connection.';
    }
  }
}
