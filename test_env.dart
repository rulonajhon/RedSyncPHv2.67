import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hemophilia_manager/config/app_config.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");

  try {
    print('Testing environment variable loading...');
    print(
        'Google Maps API Key loaded: ${AppConfig.googleMapsApiKey.isNotEmpty ? "YES" : "NO"}');
    print(
        'API Key (first 10 chars): ${AppConfig.googleMapsApiKey.substring(0, 10)}...');

    // Test the actual API call
    print('\nTesting Google Directions API call...');
    // We'll test this with a simple HTTP request
  } catch (e) {
    print('ERROR loading environment variables: $e');
  }
}
