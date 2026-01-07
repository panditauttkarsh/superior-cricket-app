# Flutter App Setup Instructions

## Prerequisites

1. **Flutter SDK** (>=3.0.0)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio / Xcode**
   - Android Studio for Android development
   - Xcode for iOS development (macOS only)

3. **IDE** (Optional but recommended)
   - VS Code with Flutter extension
   - Android Studio with Flutter plugin

## Setup Steps

### 1. Navigate to Flutter App Directory

```bash
cd flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

#### For Android:
```bash
flutter run
```

#### For iOS (macOS only):
```bash
flutter run -d ios
```

#### For a specific device:
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### 4. Build for Production

#### Android APK:
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store):
```bash
flutter build appbundle --release
```

#### iOS (macOS only):
```bash
flutter build ios --release
```

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/                        # Core functionality
│   │   ├── providers/               # State management
│   │   ├── router/                  # Navigation
│   │   ├── theme/                   # App themes
│   │   └── widgets/                 # Shared widgets
│   └── features/                    # Feature modules
│       ├── auth/                    # Authentication
│       ├── dashboard/               # Dashboard
│       ├── player/                  # Player module
│       ├── coach/                   # Coach module
│       ├── tournament/              # Tournament module
│       ├── academy/                 # Academy module
│       ├── match/                   # Match features
│       ├── admin/                   # Admin panel
│       ├── profile/                 # Profile
│       └── settings/                # Settings
├── pubspec.yaml                     # Dependencies
└── README.md                        # Documentation
```

## Configuration

### API Endpoints

Update API base URLs in repository files:
- `lib/features/auth/data/repositories/auth_repository.dart`
- Other repository files as needed

### Firebase Setup (Optional)

1. Create a Firebase project
2. Add `google-services.json` (Android) to `android/app/`
3. Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`
4. Uncomment Firebase imports in `main.dart`

### Payment Gateways

Configure payment credentials:
- Stripe: Add publishable key
- Razorpay: Add key ID

## Troubleshooting

### Common Issues

1. **"SDK location not found"**
   - Set `ANDROID_HOME` environment variable
   - Or set `sdk.dir` in `android/local.properties`

2. **"CocoaPods not installed" (iOS)**
   ```bash
   sudo gem install cocoapods
   cd ios && pod install
   ```

3. **"Package not found"**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **Build errors**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Development Tips

1. **Hot Reload**: Press `r` in terminal while app is running
2. **Hot Restart**: Press `R` in terminal
3. **Widget Inspector**: Press `w` in terminal
4. **Performance Overlay**: Press `P` in terminal

## Next Steps

1. Connect to your backend API
2. Configure Firebase for push notifications
3. Set up payment gateway credentials
4. Add app icons and splash screens
5. Configure app signing for release builds

## Support

For issues or questions:
- Check Flutter documentation: https://flutter.dev/docs
- Check Dart documentation: https://dart.dev/guides

