# KidsCar

Kids Car Project - A Flutter application for real-time vehicle tracking and live video streaming.

## 🔐 Important Security Notice

**NEVER commit API keys, credentials, or secrets to version control.**

This project uses WebRTC with TURN/STUN servers that require API credentials. All sensitive credentials have been removed from the source code and must be configured via environment variables.

## 📋 Prerequisites

- Flutter SDK (^3.8.1)
- Firebase project configured
- API credentials for:
  - Metered.ca (for TURN servers)
  - Twilio (optional, for additional TURN servers)

## ⚙️ Configuration Setup

### 1. Environment Variables

Copy the `.env.example` file to `.env`:

```bash
cp .env.example .env
```

### 2. Configure Credentials

Edit the `.env` file and add your actual credentials:

```env
# Metered.ca Configuration
METERED_API_KEY=your_actual_api_key_here
METERED_TURN_USERNAME=your_metered_username_here
METERED_TURN_CREDENTIAL=your_metered_credential_here

# Twilio Configuration (Optional)
TWILIO_ACCOUNT_SID=your_twilio_account_sid_here
TWILIO_AUTH_TOKEN=your_twilio_auth_token_here
TWILIO_TURN_USERNAME=your_twilio_turn_username_here
TWILIO_TURN_CREDENTIAL=your_twilio_turn_credential_here
```

### 3. Get Your API Keys

#### Metered.ca
1. Sign up at [https://www.metered.ca/](https://www.metered.ca/)
2. Get your API key from the dashboard
3. Get TURN server credentials from the ICE Servers section

#### Twilio (Optional)
1. Sign up at [https://www.twilio.com/](https://www.twilio.com/)
2. Get your Account SID and Auth Token from the console
3. Generate TURN credentials via their API

### 4. Running the App

When running the app, pass the environment variables:

```bash
# Development
flutter run --dart-define=METERED_API_KEY=your_key_here

# Or use a script to load from .env file
# Note: Flutter doesn't natively support .env files, consider using flutter_dotenv package
```

## 🚀 Getting Started

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure your credentials (see Configuration Setup above)
4. Run the app:
   ```bash
   flutter run
   ```

## 📱 Features

- Real-time GPS tracking
- Live video streaming (WebRTC)
- Firebase integration
- Parent and Driver roles
- Trip management

## 🛠️ Project Structure

```
lib/
├── core/
│   └── services/
│       └── rtc_streaming_service.dart  # WebRTC service
├── features/
└── ...
```

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Setup](https://firebase.google.com/docs/flutter/setup)
- [WebRTC Documentation](https://webrtc.org/)

## ⚠️ Notes

- The `.env` file is gitignored and will not be committed
- Never hardcode API keys in source code
- Use environment variables or secure configuration management
- The default TURN configuration requires credentials to be set
