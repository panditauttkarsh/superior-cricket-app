<<<<<<< HEAD
This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
=======
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

>>>>>>> 077073f (new scoreboard)
