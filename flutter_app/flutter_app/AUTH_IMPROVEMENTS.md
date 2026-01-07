# Authentication System Improvements

## Overview
Enhanced authentication system to support both Google OAuth and Email/Password authentication with proper account linking and unique username generation.

## Key Features

### 1. Email Uniqueness Across Auth Methods
- Email addresses are globally unique across all authentication providers
- Prevents duplicate accounts when using the same email with different auth methods
- Clear error messages guide users to use the correct authentication method

### 2. Unique Username Generation
- Auto-generated from user's name (no random words)
- Format: lowercase name with special characters removed
- If taken, appends number (name1, name2, etc.)
- Immutable once created
- Prevents race conditions with database-level functions

### 3. Account Linking
- Google login and Email/Password login point to the same account if email matches
- One user = one account, regardless of auth method
- Profile is shared across authentication methods

## Implementation Details

### Database Schema Updates

#### Profiles Table
```sql
-- Added username field with unique constraint
username TEXT UNIQUE

-- Added email uniqueness constraint
CONSTRAINT unique_email UNIQUE (email)
CONSTRAINT unique_username UNIQUE (username)
```

#### Helper Functions
1. **`generate_unique_username(base_name TEXT)`**
   - Generates unique username from name
   - Handles race conditions
   - Returns username that doesn't exist in database

2. **`email_exists(check_email TEXT)`**
   - Checks if email already exists
   - Case-insensitive check
   - Used to prevent duplicate registrations

3. **`username_exists(check_username TEXT)`**
   - Checks if username already exists
   - Case-insensitive check
   - Used during username generation

#### Indexes
- `idx_profiles_email` - Fast email lookups
- `idx_profiles_username` - Fast username lookups

### Authentication Flow

#### Email/Password Registration
1. Check if email exists
2. If exists and is Google user → Show error: "This email is already registered via Google login. Please sign in using Google."
3. Generate unique username from name
4. Create auth user
5. Create profile with username

#### Email/Password Login
1. Attempt login
2. If fails with "Invalid login credentials" and email exists → Check if it's a Google user
3. Show appropriate error message
4. Get or create profile (with username if missing)

#### Google OAuth Login
1. Initiate OAuth flow with `signInWithOAuth`
2. Handle redirect callback
3. Check if email exists in profiles
4. If exists, link to existing profile
5. If new, create profile with auto-generated username

### Error Messages

- **Duplicate Email (Google)**: "This email is already registered via Google login. Please sign in using Google."
- **Duplicate Email (Email/Password)**: "An account with this email already exists. Please login instead."
- **Invalid Credentials (Google User)**: "This email is already registered via Google login. Please sign in using Google."

## Setup Instructions

### 1. Run Database Schema Updates
Execute the updated `supabase_schema.sql` in your Supabase SQL Editor to:
- Add username field to profiles table
- Add unique constraints
- Create helper functions
- Create indexes

### 2. Configure Google OAuth in Supabase
1. Go to Supabase Dashboard > Authentication > Providers
2. Enable Google provider
3. Add Google OAuth credentials (Client ID, Client Secret)
4. Configure redirect URLs

### 3. Update App Configuration
- Ensure `SupabaseConfig.redirectUrl` is set correctly
- Handle OAuth redirects in your app (deep linking)

## Testing Checklist

- [ ] Email/Password registration with new email
- [ ] Email/Password registration with existing Google email (should fail)
- [ ] Email/Password login with correct credentials
- [ ] Email/Password login with Google user email (should show error)
- [ ] Google OAuth login with new email
- [ ] Google OAuth login with existing Email/Password email (should link)
- [ ] Username generation from various names
- [ ] Username uniqueness (multiple users with same name)
- [ ] Race condition handling (concurrent username generation)

## Security Considerations

1. **Email Normalization**: All emails are lowercased and trimmed before storage/checking
2. **Username Immutability**: Usernames cannot be changed after creation
3. **Database Constraints**: Unique constraints prevent duplicates at database level
4. **Race Condition Prevention**: Database functions handle concurrent username generation
5. **Indexes**: Fast lookups prevent performance issues

## Future Enhancements

- Account linking UI (allow users to link Google account to existing email/password account)
- Username change request system (admin approval)
- Additional OAuth providers (Apple, Facebook)
- Email verification for email/password accounts

