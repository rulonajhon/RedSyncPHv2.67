import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get openAiApiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'your_openai_api_key_here') {
      throw Exception(
          'OPENAI_API_KEY not found or not configured in environment variables');
    }
    return apiKey;
  }

  static String get googleMapsApiKey {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in environment variables');
    }
    return apiKey;
  }

  static String get firebaseApiKey {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FIREBASE_API_KEY not found in environment variables');
    }
    return apiKey;
  }

  static String get firebaseAppId {
    final appId = dotenv.env['FIREBASE_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception('FIREBASE_APP_ID not found in environment variables');
    }
    return appId;
  }

  static String get firebaseMessagingSenderId {
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    if (senderId == null || senderId.isEmpty) {
      throw Exception(
          'FIREBASE_MESSAGING_SENDER_ID not found in environment variables');
    }
    return senderId;
  }

  static String get firebaseProjectId {
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw Exception('FIREBASE_PROJECT_ID not found in environment variables');
    }
    return projectId;
  }

  static String get firebaseStorageBucket {
    final bucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    if (bucket == null || bucket.isEmpty) {
      throw Exception(
          'FIREBASE_STORAGE_BUCKET not found in environment variables');
    }
    return bucket;
  }
}
