# 🔐 RedSync Security Setup

## ⚠️ IMPORTANT SECURITY NOTICE

This project now uses environment variables to protect sensitive API keys from being exposed in the repository.

## 🚀 Quick Setup Instructions

### 1. Environment Variables Setup

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file with your actual API keys:**
   ```
   # OpenAI API Key for Chatbot
   OPENAI_API_KEY=sk-proj-your_actual_openai_api_key_here
   
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

#### 🤖 OpenAI API Key (for Chatbot)
- Go to [OpenAI Platform](https://platform.openai.com)
- Create account and verify phone number
- Generate API key from "View API keys" section
- **Important**: Add billing information (required for API usage)
- Add to your `.env` file
- See `OPENAI_SETUP.md` for detailed instructions

#### 🗺️ Google Maps API Key
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Enable the following APIs:
  - **Directions API**
  - **Maps SDK for Android/iOS**
  - **Places API** (if using location search)
- Create an API key and add it to your `.env` file

#### 🔥 Firebase Configuration
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create or select your project
- Get the configuration values from Project Settings
- Add them to your `.env` file

## 🔒 Security Features Implemented

### ✅ Environment Variable Protection
- API keys are stored in `.env` file (git-ignored)
- `AppConfig` service securely loads environment variables
- Proper error handling for missing keys

### ✅ Git Security
- `.env` file is automatically ignored by Git
- `.env.example` provides a template without real keys
- Enhanced `.gitignore` to prevent accidental key exposure

### ✅ Runtime Security
- Environment variables are loaded at app startup
- Secure access through `AppConfig` class
- Fail-fast approach if keys are missing

## 🛡️ Security Best Practices

- **NEVER** commit the `.env` file to version control
- **NEVER** share API keys in public repositories
- **ALWAYS** use the `.env.example` file as a template for team members
- **REGULARLY** rotate API keys for enhanced security
- **RESTRICT** API keys with appropriate usage limitations

## 📱 Development Setup

1. Clone the repository
2. Copy `.env.example` to `.env`
3. Fill in your actual API keys in `.env`
4. Run `flutter pub get`
5. Run `flutter run`

## 🚨 Migration from Hardcoded Keys

If you're migrating from a version with hardcoded API keys:
1. Follow the setup instructions above
2. The hardcoded keys have been replaced with environment variables
3. Use the `AppConfig` class to access API keys securely
4. Test thoroughly to ensure all functionality works

## 🔧 Troubleshooting

If you get errors about missing API keys:
1. Ensure `.env` file exists in the project root
2. Check that all required environment variables are set
3. Verify API keys are valid and have proper permissions
4. Restart your IDE after adding environment variables

## 📂 File Structure

```
├── .env                 # Your actual API keys (git-ignored)
├── .env.example         # Template file (committed)
├── lib/
│   └── config/
│       └── app_config.dart  # Secure config service
└── .gitignore           # Enhanced security rules
```

## 🤝 Team Collaboration

When sharing this project:
1. Share the `.env.example` file
2. Each team member creates their own `.env` file
3. Never commit or share actual `.env` files
4. Use the same API keys for development/testing

## 🏭 Production Deployment

For production:
- Set environment variables in your deployment platform
- Use build variants for different environments
- Never hardcode production keys in the codebase
