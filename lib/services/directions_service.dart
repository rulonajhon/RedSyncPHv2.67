import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hemophilia_manager/config/app_config.dart';

enum TravelMode { driving, walking, bicycling, transit, motorcycle }

class RouteInfo {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String instructions;
  final TravelMode travelMode;

  RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.instructions,
    required this.travelMode,
  });
}

class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  
  // Use environment variable instead of hardcoded API key
  String get _apiKey => AppConfig.googleMapsApiKey;

  Future<RouteInfo?> getDirections({
    required LatLng origin,
    required LatLng destination,
    required TravelMode travelMode,
  }) async {
    try {
      final String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=${_getTravelModeString(travelMode)}&'
          'key=$_apiKey';

      print('Directions API URL: $url');

      final response = await http.get(Uri.parse(url));
      print('Directions API Response Status: ${response.statusCode}');
      print('Directions API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Get polyline points
          final polylinePoints = <LatLng>[];
          if (route['overview_polyline'] != null &&
              route['overview_polyline']['points'] != null) {
            final encodedPoints = route['overview_polyline']['points'];
            final decodedPoints =
                PolylinePoints().decodePolyline(encodedPoints);

            for (var point in decodedPoints) {
              polylinePoints.add(LatLng(point.latitude, point.longitude));
            }
          }

          // If no polyline points, create a fallback route
          if (polylinePoints.isEmpty) {
            print('No polyline points from API, creating fallback route');
            return _createFallbackRoute(origin, destination, travelMode);
          }

          return RouteInfo(
            polylinePoints: polylinePoints,
            distance: leg['distance']['text'] ?? 'N/A',
            duration: leg['duration']['text'] ?? 'N/A',
            instructions: leg['steps']?.isNotEmpty == true
                ? leg['steps'][0]['html_instructions']
                        ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                    'Navigate to destination'
                : 'Navigate to destination',
            travelMode: travelMode,
          );
        } else {
          print('Directions API error or no routes: ${data['status']}');
          // Return fallback route for any API issues
          return _createFallbackRoute(origin, destination, travelMode);
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return _createFallbackRoute(origin, destination, travelMode);
      }
    } catch (e) {
      print('Exception in getDirections: $e');
      return _createFallbackRoute(origin, destination, travelMode);
    }
  }

  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
      case TravelMode.motorcycle:
        // Use driving mode for motorcycle since Google doesn't have specific motorcycle routing
        return 'driving';
    }
  }

  RouteInfo _createFallbackRoute(
      LatLng origin, LatLng destination, TravelMode travelMode) {
    // Calculate straight-line distance using Haversine formula
    final distance = _calculateDistance(origin, destination);

    // Estimate duration based on travel mode
    final duration = _estimateDuration(distance, travelMode);

    return RouteInfo(
      polylinePoints: [origin, destination],
      distance: '${distance.toStringAsFixed(1)} km',
      duration: duration,
      instructions:
          'Head ${_getDirection(origin, destination)} toward destination',
      travelMode: travelMode,
    );
  }

  double _calculateDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double lat1Rad = origin.latitude * (pi / 180);
    final double lat2Rad = destination.latitude * (pi / 180);
    final double deltaLatRad =
        (destination.latitude - origin.latitude) * (pi / 180);
    final double deltaLonRad =
        (destination.longitude - origin.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  String _estimateDuration(double distanceKm, TravelMode travelMode) {
    double speedKmh;

    switch (travelMode) {
      case TravelMode.walking:
        speedKmh = 5; // 5 km/h average walking speed
        break;
      case TravelMode.bicycling:
        speedKmh = 15; // 15 km/h average cycling speed
        break;
      case TravelMode.driving:
      case TravelMode.motorcycle:
        speedKmh = 40; // 40 km/h average city driving speed
        break;
      case TravelMode.transit:
        speedKmh = 25; // 25 km/h average transit speed
        break;
    }

    final double durationHours = distanceKm / speedKmh;
    final int totalMinutes = (durationHours * 60).round();

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    } else {
      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $minutes min';
      }
    }
  }

  String _getDirection(LatLng origin, LatLng destination) {
    final double deltaLat = destination.latitude - origin.latitude;
    final double deltaLon = destination.longitude - origin.longitude;

    if (deltaLat.abs() > deltaLon.abs()) {
      return deltaLat > 0 ? 'north' : 'south';
    } else {
      return deltaLon > 0 ? 'east' : 'west';
    }
  }
}
