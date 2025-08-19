# RedSync Security Setup

## Important Security Notice

This project now uses environment variables to protect sensitive API keys from being exposed in the repository.

## Setup Instructions

### 1. Environment Variables Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your actual API keys:
   ```
   # Google Maps API Key for Directions
   GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key_here
   
   # Firebase Configuration  
   FIREBASE_API_KEY=your_actual_firebase_api_key_here
   FIREBASE_APP_ID=your_actual_firebase_app_id_here
   FIREBASE_MESSAGING_SENDER_ID=your_actual_messaging_sender_id_here
   FIREBASE_PROJECT_ID=your_actual_project_id_here
   FIREBASE_STORAGE_BUCKET=your_actual_storage_bucket_here
   ```

### 2. Required API Keys

#### Google Maps API Key
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Enable the following APIs:
  - Directions API
  - Maps SDK for Android/iOS
  - Places API (if using location search)
- Create an API key and add it to your `.env` file

#### Firebase Configuration
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create or select your project
- Get the configuration values from Project Settings
- Add them to your `.env` file

### 3. Security Best Practices

- **NEVER** commit the `.env` file to version control
- **NEVER** share API keys in public repositories
- The `.env` file is already added to `.gitignore`
- Use the `.env.example` file as a template for team members
- Restrict API keys with appropriate usage limitations
- Regularly rotate API keys for enhanced security

### 4. Deployment

For production deployment, ensure environment variables are properly set in your deployment environment:
- Android: Use build variants or environment-specific configs
- iOS: Use build configurations
- CI/CD: Set environment variables in your pipeline secrets

## Development Setup

1. Clone the repository
2. Copy `.env.example` to `.env`
3. Fill in your actual API keys in `.env`
4. Run `flutter pub get`
5. Run `flutter run`

## Troubleshooting

If you get errors about missing API keys:
1. Ensure `.env` file exists in the project root
2. Check that all required environment variables are set
3. Verify API keys are valid and have proper permissions
4. Restart your IDE after adding environment variables

## Migration from Hardcoded Keys

If you're migrating from a version with hardcoded API keys:
1. Follow the setup instructions above
2. Remove any hardcoded API keys from your codebase
3. Use the `AppConfig` class to access environment variables
4. Test thoroughly to ensure all functionality works

## Support

If you encounter issues with the security setup, please check:
1. That all environment variables are properly set
2. That your API keys have the correct permissions
3. That the `.env` file is in the correct location (project root)
