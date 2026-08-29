import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:physioone/core/app_consts/app_consts.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Checks if the user is within the allowed check-in radius of the clinic.
  ///
  /// Returns a tuple:
  /// - bool: true if within radius, false otherwise.
  /// - String: A message indicating the status or error.
  Future<(bool, String)> isUserWithinClinicRadius() async {
    try {
      debugPrint(
        'Fetching user location to check radius against clinic coordinates...',
      );
      Position userPosition = await getCurrentPosition();

      final distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        AppConsts.clinicLatitude,
        AppConsts.clinicLongitude,
      );

      debugPrint(
        'User location coordinates: Lat=${userPosition.latitude}, Lng=${userPosition.longitude}',
      );
      debugPrint(
        'Distance to clinic: ${distanceInMeters.toStringAsFixed(2)} meters',
      );

      if (distanceInMeters <= AppConsts.clinicCheckInRadiusMeters) {
        return (true, 'User is within the clinic radius.');
      } else {
        return (
          false,
          'You are too far from the clinic to check in. Distance: ${distanceInMeters.toStringAsFixed(0)} meters.',
        );
      }
    } catch (e) {
      debugPrint('Error checking user clinic radius: $e');
      return (false, e.toString());
    }
  }

  /// Determines the current position of the device.
  ///
  /// When location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> getCurrentPosition() async {
    debugPrint('Fetching user position via Geolocator...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Location permissions are denied, requesting permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions were denied by user.');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    final position = await Geolocator.getCurrentPosition();
    debugPrint(
      'User location successfully fetched: Latitude=${position.latitude}, Longitude=${position.longitude}',
    );
    return position;
  }

  Future<String> getAddressFromPosition(Position position) async {
    try {
      debugPrint(
        'Reverse geocoding position: Lat=${position.latitude}, Lng=${position.longitude}',
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final address = placemarks.first.street ?? 'Unknown location';
      debugPrint('Geocoded address: $address');
      return address;
    } catch (e) {
      debugPrint('Could not get address from position: $e');
      return 'Could not get address';
    }
  }
}
