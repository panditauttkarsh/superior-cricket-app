# Supabase Integration Setup Guide

This guide will help you set up Supabase as the backend for your CricPlay Flutter app.

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Project Name**: CricPlay (or your preferred name)
   - **Database Password**: Choose a strong password (save it!)
   - **Region**: Choose the closest region to your users
5. Click "Create new project"
6. Wait for the project to be set up (takes 1-2 minutes)

## Step 2: Get Your API Keys

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

## Step 3: Configure the App

1. Open `flutter_app/lib/core/config/supabase_config.dart`
2. Replace the placeholders:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
   With your actual values:
   ```dart
   static const String supabaseUrl = 'https://xxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

## Step 4: Set Up the Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `flutter_app/supabase_schema.sql`
4. Paste it into the SQL Editor
5. Click "Run" (or press Cmd/Ctrl + Enter)
6. Wait for all tables to be created

## Step 5: Install Dependencies

Run in your terminal:
```bash
cd flutter_app
flutter pub get
```

## Step 6: Test the Connection

1. Run your app: `flutter run`
2. Try to register a new user
3. Check Supabase dashboard → **Authentication** → **Users** to see if the user was created
4. Check **Table Editor** to see if a profile was created in the `profiles` table

## Database Tables Created

The schema creates the following tables:

- **profiles** - User profiles (extends auth.users)
- **players** - Player information and stats
- **teams** - Cricket teams
- **matches** - Cricket matches
- **tournaments** - Tournament information
- **tournament_registrations** - Team registrations for tournaments
- **academies** - Cricket academies
- **shop_items** - E-commerce products
- **posts** - Social feed posts
- **post_likes** - Post likes
- **post_comments** - Post comments
- **orders** - Shop orders

## Row Level Security (RLS)

The schema includes basic RLS policies:
- Users can read most data
- Users can only create/update/delete their own data
- Adjust policies in Supabase dashboard → **Authentication** → **Policies** as needed

## Next Steps

1. **Update Dashboard**: Replace static data with Supabase queries
2. **Update My Cricket Page**: Fetch matches, teams, tournaments from Supabase
3. **Update Match Creation**: Save matches to Supabase
4. **Update Scorecard**: Save scorecard data to Supabase in real-time
5. **Update Shop**: Fetch products from Supabase
6. **Update Feed**: Fetch and create posts from Supabase

## Example: Fetching Live Matches

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/match_repository.dart';
import '../../core/providers/repository_providers.dart';

// In your widget
final matchRepository = ref.watch(matchRepositoryProvider);
final liveMatches = await matchRepository.getMatches(status: 'live');
```

## Troubleshooting

### Error: "Failed to fetch matches"
- Check your Supabase URL and anon key are correct
- Verify the database schema was created successfully
- Check RLS policies allow your operations

### Error: "No user logged in"
- Make sure you've registered/logged in first
- Check Supabase Authentication → Users to see if user exists

### Error: "Table does not exist"
- Run the SQL schema again in Supabase SQL Editor
- Check table names match exactly (case-sensitive)

## Additional Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

