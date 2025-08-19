import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyACs7QdWeo6T65-_znx83BvjoVIEI7GGiI'; // Your API key

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

      print('Making Directions API call: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timeout');
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode the polyline
          final String encodedPolyline = route['overview_polyline']['points'];
          final PolylinePoints polylinePoints = PolylinePoints();
          final List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
          
          // Convert to LatLng
          final List<LatLng> polylineCoordinates = result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          final String distance = leg['distance']['text'];
          final String duration = leg['duration']['text'];
          final String instructions = _generateInstructions(route);

          print('Successfully decoded route with ${polylineCoordinates.length} points');

          return RouteInfo(
            polylinePoints: polylineCoordinates,
            distance: distance,
            duration: duration,
            instructions: instructions,
            travelMode: travelMode,
          );
        } else {
          print('Directions API Error Status: ${data['status']}');
          if (data['error_message'] != null) {
            print('API Error Message: ${data['error_message']}');
          }
          
          // Fallback to straight line route
          return _createFallbackRoute(origin, destination, travelMode);
        }
      } else {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        // Fallback to straight line route
        return _createFallbackRoute(origin, destination, travelMode);
      }
    } catch (e) {
      print('Exception in getDirections: $e');
      // Fallback to straight line route
      return _createFallbackRoute(origin, destination, travelMode);
    }
  }

  // Create a fallback route using straight line
  RouteInfo _createFallbackRoute(LatLng origin, LatLng destination, TravelMode travelMode) {
    print('Creating fallback straight-line route');
    
    // Calculate straight-line distance
    final distanceMeters = _calculateDistance(origin, destination);
    final distanceKm = distanceMeters / 1000;
    
    // Estimate time based on travel mode
    final estimatedTime = _estimateTime(distanceKm, travelMode);
    
    return RouteInfo(
      polylinePoints: [origin, destination],
      distance: '${distanceKm.toStringAsFixed(1)} km',
      duration: estimatedTime,
      instructions: 'Straight line route (${_getTravelModeDisplayName(travelMode)})',
      travelMode: travelMode,
    );
  }

  // Generate basic instructions from route data
  String _generateInstructions(Map<String, dynamic> route) {
    try {
      final leg = route['legs'][0];
      final steps = leg['steps'] as List;
      
      if (steps.isNotEmpty) {
        // Get first few steps
        final firstSteps = steps.take(3).map((step) {
          String instruction = step['html_instructions'] ?? '';
          // Remove HTML tags
          instruction = instruction.replaceAll(RegExp(r'<[^>]*>'), '');
          return instruction;
        }).where((instruction) => instruction.isNotEmpty).join(' → ');
        
        return firstSteps.isNotEmpty ? firstSteps : 'Route found';
      }
    } catch (e) {
      print('Error generating instructions: $e');
    }
    return 'Route found';
  }

  // Calculate distance using Haversine formula
  double _calculateDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double lat1Rad = origin.latitude * (pi / 180);
    final double lat2Rad = destination.latitude * (pi / 180);
    final double deltaLatRad = (destination.latitude - origin.latitude) * (pi / 180);
    final double deltaLngRad = (destination.longitude - origin.longitude) * (pi / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Estimate travel time based on mode
  String _estimateTime(double distanceKm, TravelMode travelMode) {
    double speedKmh;
    switch (travelMode) {
      case TravelMode.driving:
      case TravelMode.motorcycle: // Motorcycles use same roads as cars
        speedKmh = 40; // Average city driving speed
        break;
      case TravelMode.walking:
        speedKmh = 5; // Average walking speed
        break;
      case TravelMode.bicycling:
        speedKmh = 15; // Average cycling speed
        break;
      case TravelMode.transit:
        speedKmh = 25; // Average transit speed
        break;
    }
    
    final double timeHours = distanceKm / speedKmh;
    final int totalMinutes = (timeHours * 60).round();
    
    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    } else {
      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
      case TravelMode.motorcycle: // Motorcycles use driving mode in Google API
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }

  String _getTravelModeDisplayName(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'cycling';
      case TravelMode.transit:
        return 'transit';
      case TravelMode.motorcycle:
        return 'motorcycle';
    }
  }
}
