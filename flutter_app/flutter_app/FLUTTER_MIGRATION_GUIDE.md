# Flutter Migration Guide

## Overview
This guide documents the migration from Next.js web application to Flutter mobile app, maintaining all functionality while adapting to mobile-first design.

## Architecture Comparison

### Web (Next.js) → Mobile (Flutter)

| Web Component | Flutter Equivalent |
|---------------|-------------------|
| React Components | Flutter Widgets |
| Zustand State | Riverpod/Provider |
| Next.js Router | GoRouter |
| API Routes | Repository Pattern |
| CSS/Tailwind | Flutter Theme |
| localStorage | SharedPreferences |

## Key Features Migrated

### ✅ Authentication
- Login page with email/password
- Google & Apple OAuth (structure ready)
- Onboarding wizard
- Protected routes with GoRouter

### ✅ Dashboard
- Main dashboard with stats cards
- Bottom navigation bar
- Quick actions
- Recent activity

### ✅ Player Module
- Player dashboard with statistics
- Scorecards view
- Leaderboards with tabs

### ✅ Coach Module
- Coach dashboard
- Team management
- Player monitoring

### ✅ Tournament Module
- Tournament listing
- Tournament details with tabs
- Fixtures management
- Points table

### ✅ Academy Module
- Academy dashboard
- Training programs

### ✅ Match Center
- Live matches display
- Match details with tabs

### ✅ Admin Panel
- Admin dashboard
- Statistics overview

### ✅ Profile & Settings
- Profile page
- Settings with sections

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── providers/      # State management
│   │   ├── router/         # Navigation
│   │   ├── theme/           # App themes
│   │   └── widgets/         # Shared widgets
│   └── features/
│       ├── auth/            # Authentication
│       ├── dashboard/       # Dashboard
│       ├── player/          # Player module
│       ├── coach/           # Coach module
│       ├── tournament/      # Tournament module
│       ├── academy/         # Academy module
│       ├── match/           # Match features
│       ├── admin/           # Admin panel
│       ├── profile/         # Profile
│       └── settings/        # Settings
├── pubspec.yaml
└── README.md
```

## State Management

Using **Riverpod** for state management:
- `AuthNotifier` - Authentication state
- `ThemeModeProvider` - Theme management
- Additional providers for each feature module

## Navigation

Using **GoRouter** for navigation:
- Declarative routing
- Route guards for authentication
- Deep linking support
- Navigation state management

## API Integration

Repository pattern for API calls:
- `AuthRepository` - Authentication
- `PlayerRepository` - Player data
- `CoachRepository` - Coach data
- `TournamentRepository` - Tournament data
- `AcademyRepository` - Academy data

## UI/UX Adaptations

### Mobile-First Design
- Bottom navigation bar for main sections
- Tab bars for sub-sections
- Card-based layouts
- Scrollable lists
- Floating action buttons for quick actions

### Responsive Layouts
- Flexible layouts using `Expanded` and `Flexible`
- Grid layouts with `GridView`
- List views with `ListView.builder`

## Next Steps

1. **Complete Remaining Screens**
   - Tournament leaderboards
   - Academy training sessions
   - Academy health metrics
   - Academy video analytics
   - Match details (all tabs)

2. **Implement State Management**
   - Add providers for all modules
   - Connect to API services
   - Implement caching

3. **Add Animations**
   - Page transitions
   - Loading states
   - Success/error animations

4. **Integrate Services**
   - Payment gateways (Stripe, Razorpay)
   - Push notifications (Firebase)
   - Video streaming
   - Social sharing

5. **Testing**
   - Unit tests
   - Widget tests
   - Integration tests

6. **Build & Deploy**
   - Android APK/AAB
   - iOS IPA
   - App Store/Play Store setup

## Running the App

```bash
cd flutter_app
flutter pub get
flutter run
```

## Notes

- All functionality from the web app is preserved
- UI adapted for mobile screens
- Navigation structure matches web routes
- Ready for API integration
- Theme supports light/dark mode

