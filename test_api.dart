import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test the Google Directions API directly
  const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE'; // Replace with actual key
  const String baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  // Test coordinates (example: from Manila to Quezon City)
  const String origin = '14.5995,120.9842';
  const String destination = '14.6760,121.0437';

  final String url = '$baseUrl?'
      'origin=$origin&'
      'destination=$destination&'
      'mode=driving&'
      'key=$apiKey';

  print('Testing Google Directions API...');
  print('URL: $url');

  try {
    final response = await http.get(Uri.parse(url));
    print('Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print('API Status: ${data['status']}');

      if (data['status'] == 'OK') {
        print('✅ API is working correctly!');
        print('Routes found: ${data['routes']?.length ?? 0}');

        if (data['routes']?.isNotEmpty == true) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          print('Distance: ${leg['distance']['text']}');
          print('Duration: ${leg['duration']['text']}');

          // Check if polyline is available
          if (route['overview_polyline']?['points'] != null) {
            print('✅ Polyline data available');
          } else {
            print('❌ No polyline data');
          }
        }
      } else {
        print('❌ API Error: ${data['status']}');
        print('Error message: ${data['error_message'] ?? 'No error message'}');
      }
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}
