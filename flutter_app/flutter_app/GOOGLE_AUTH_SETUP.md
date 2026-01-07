# Google Authentication Setup Guide

## Supabase Configuration

### 1. Enable Google OAuth Provider

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Google** in the list
4. Click **Enable** or toggle it on
5. You'll need to provide:
   - **Client ID** (from Google Cloud Console)
   - **Client Secret** (from Google Cloud Console)

### 2. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **Google+ API** (if not already enabled)
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure OAuth consent screen (if not done)
6. Create OAuth 2.0 Client ID:
   - **Application type**: Web application
   - **Name**: Your app name
   - **Authorized redirect URIs**: 
     - `https://[your-project-ref].supabase.co/auth/v1/callback`
     - Add your app's deep link URL (e.g., `yourapp://auth-callback`)
7. Copy the **Client ID** and **Client Secret**
8. Paste them into Supabase Dashboard → Authentication → Providers → Google

### 3. Configure Redirect URLs

In Supabase Dashboard → Authentication → URL Configuration:
- Add your app's redirect URL (e.g., `yourapp://auth-callback`)
- For development: `http://localhost:3000/auth/callback`
- For production: Your production URL

### 4. Update App Configuration

Make sure `SupabaseConfig.redirectUrl` matches your redirect URL:

```dart
// In supabase_config.dart
static const String redirectUrl = 'yourapp://auth-callback';
// Or for web: 'https://yourdomain.com/auth/callback'
```

## Implementation Notes

### Automatic Profile Creation

The database trigger `on_auth_user_created` automatically:
- Creates a profile when a new auth user is created
- Generates a unique username from the user's name
- Handles both Google OAuth and Email/Password signups

### Username Generation

- Automatically generated from user's name
- Lowercase, alphanumeric only
- If taken, appends number (name1, name2, etc.)
- Immutable once created (cannot be changed)

### Account Linking

- Same email = same account across auth methods
- Google login and Email/Password login share the same profile
- Email uniqueness enforced at database level

## Testing

1. Test Google OAuth login
2. Test Email/Password registration with same email (should show error)
3. Test Email/Password login after Google login (should work)
4. Verify username is auto-generated and unique

