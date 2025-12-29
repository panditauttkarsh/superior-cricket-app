# Username-Based Player Addition Feature

## Overview
Players can now be added to matches (My Team or Opponent Team) by entering their **username** instead of internal user IDs. This provides a better user experience where users only need to know public usernames.

## Implementation Details

### 1. Profile Repository (`lib/core/repositories/profile_repository.dart`)
- **`getProfileByUsername(String username)`**: Fetches a profile by username (case-insensitive)
  - Automatically removes `@` prefix if present
  - Returns `null` if user not found
- **`searchProfilesByUsername(String query)`**: Searches profiles for autocomplete (optional feature)

### 2. Updated UI Pages

#### My Team Squad Page (`lib/features/mycricket/presentation/pages/my_team_squad_page.dart`)
- Changed from `StatefulWidget` to `ConsumerStatefulWidget` (Riverpod)
- Updated `_addPlayer()` to show username input dialog
- Added duplicate player validation using `_addedPlayerIds` Set
- Shows loading indicator while fetching profile
- Displays error messages for:
  - Username not found
  - Player already added
- Shows success message when player is added

#### Opponent Team Squad Page (`lib/features/mycricket/presentation/pages/opponent_team_squad_page.dart`)
- Same updates as My Team Squad Page
- Maintains opponent team styling

### 3. Player Data Structure
Each player in the squad now stores:
```dart
{
  'id': profile.id,           // Internal UUID (hidden from UI)
  'name': profile.name,        // Display name
  'username': profile.username, // Public username
  'role': 'Player',           // Optional role
  'avatar': profile.profileImageUrl, // Profile image
  // ... other fields
}
```

### 4. Database Setup

#### Run SQL Migration
Execute `supabase_username_index.sql` in Supabase SQL Editor:
- Creates unique index on `profiles.username` (case-insensitive)
- Updates RLS policies to allow public SELECT on profiles
- Ensures username column exists

#### RLS Policies
- **SELECT**: Public (anyone can search by username)
- **INSERT/UPDATE**: Authenticated users only (own profile)
- **DELETE**: Not typically needed (cascade from auth.users)

## Usage Flow

1. **User clicks "Add Player"**
   - Dialog opens with username input field
   - Placeholder: `@utkarsh_pandita or utkarsh_pandita`

2. **User enters username**
   - Can include or omit `@` prefix
   - App removes `@` before querying

3. **App fetches profile**
   - Shows loading indicator
   - Queries Supabase: `SELECT * FROM profiles WHERE LOWER(username) = LOWER(:input)`

4. **Validation**
   - If username not found → Error: "Player with this username does not exist"
   - If player already added → Error: "Player already added to this team"
   - If valid → Player added to squad

5. **Success**
   - Player appears in squad list
   - Success message: "{Name} added to {Team Name}"
   - Internal ID stored but never displayed

## Security

- **Internal IDs Hidden**: User IDs are never exposed in UI
- **Public Usernames Only**: Users only see/share usernames
- **RLS Protection**: Database policies ensure proper access control
- **Duplicate Prevention**: Server-side validation prevents duplicate entries

## Error Handling

- **Network Errors**: Caught and displayed to user
- **Invalid Username**: Clear error message
- **Duplicate Player**: Prevents adding same player twice
- **Loading States**: UI shows loading indicator during fetch

## Future Enhancements (Optional)

1. **Autocomplete**: Use `searchProfilesByUsername()` for username suggestions
2. **Profile Preview**: Show avatar + name before confirming add
3. **Fuzzy Matching**: Suggest similar usernames if exact match not found
4. **Match Players Table**: Store player assignments in dedicated `match_players` table

## Testing

1. Ensure Supabase has profiles with usernames
2. Test adding player by username (with and without `@`)
3. Test duplicate prevention
4. Test error handling (invalid username)
5. Verify internal IDs are never displayed in UI

## Files Modified

- `lib/core/repositories/profile_repository.dart` (NEW)
- `lib/core/providers/repository_providers.dart`
- `lib/features/mycricket/presentation/pages/my_team_squad_page.dart`
- `lib/features/mycricket/presentation/pages/opponent_team_squad_page.dart`
- `supabase_username_index.sql` (NEW)

