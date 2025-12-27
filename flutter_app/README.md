# CricPlay - Flutter Mobile App

Flutter mobile application for CricPlay - The ultimate cricket community platform.

## Features

- ✅ Authentication (Email/Password, Google, Apple)
- ✅ Player Dashboard with Statistics
- ✅ Coach Module (Team Management, Player Monitoring)
- ✅ Tournament Management
- ✅ Academy Module (Training Programs, Attendance, Health Metrics)
- ✅ Match Center with Live Updates
- ✅ Admin Panel
- ✅ Payments Integration
- ✅ Notifications System

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Navigate to the Flutter app directory:
```bash
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── providers/      # State management providers
│   ├── router/         # Navigation routing
│   ├── theme/          # App themes
│   └── widgets/        # Shared widgets
├── features/
│   ├── auth/           # Authentication feature
│   ├── dashboard/      # Dashboard feature
│   ├── player/         # Player module
│   ├── coach/          # Coach module
│   ├── tournament/     # Tournament module
│   ├── academy/        # Academy module
│   ├── match/          # Match features
│   └── admin/          # Admin features
└── main.dart           # App entry point
```

## State Management

The app uses Riverpod for state management, providing:
- Reactive state updates
- Dependency injection
- Easy testing

## Navigation

Uses GoRouter for declarative routing with:
- Deep linking support
- Route guards
- Navigation state management

## API Integration

All API calls are handled through repository pattern:
- `AuthRepository` - Authentication
- `PlayerRepository` - Player data
- `CoachRepository` - Coach data
- `TournamentRepository` - Tournament data
- `AcademyRepository` - Academy data

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Notes

- Replace mock API URLs with actual backend endpoints
- Configure Firebase for push notifications
- Set up payment gateway credentials
- Add proper error handling and loading states

