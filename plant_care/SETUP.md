# Plant Care App Setup Guide

## Environment Configuration

This app requires an OpenAI API key to function properly. Follow these steps to configure it:

### Option 1: Environment Variables (Recommended for Production)

Set the `OPENAI_API_KEY` environment variable:

**macOS/Linux:**
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
```

**Windows:**
```cmd
set OPENAI_API_KEY=your_actual_api_key_here
```

**For Flutter development:**
```bash
flutter run --dart-define=OPENAI_API_KEY=your_actual_api_key_here
```

### Option 2: .env File (Recommended for Development)

1. Create a `.env` file in the project root directory
2. Add your API key:
   ```
   OPENAI_API_KEY=your_actual_api_key_here
   ```
3. The `.env` file is already in `.gitignore` and won't be committed

### Option 3: Build-time Configuration

For production builds, you can pass the API key at build time:

```bash
flutter build apk --dart-define=OPENAI_API_KEY=your_actual_api_key_here
flutter build ios --dart-define=OPENAI_API_KEY=your_actual_api_key_here
```

## Getting an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and use it in your configuration

## Security Notes

- **Never commit API keys to version control**
- The `.env` file is automatically ignored by Git
- Use environment variables in production environments
- Rotate your API keys regularly
- Monitor your API usage to avoid unexpected charges

## Troubleshooting

If you see "API key not configured" errors:

1. Check that your `.env` file exists and contains the correct key
2. Verify the environment variable is set correctly
3. Restart your Flutter app after making changes
4. Check the console for configuration status logs

## Configuration Status

The app includes a configuration service that provides status information:

```dart
import 'package:plant_care/services/chatgpt_service.dart';

// Check if API key is configured
bool isConfigured = ChatGPTService.isApiKeyConfigured;

// Get detailed configuration status
Map<String, dynamic> status = ChatGPTService.configStatus;
``` 