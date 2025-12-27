# Supabase Email Verification Setup

## Problem
Email verification links are redirecting to `localhost:3000` instead of opening the Flutter app.

## Solution

### Step 1: Update Supabase Dashboard Settings

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `nhiyuosjiiabxxwpkpdi`
3. Navigate to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add:
   ```
   cricplay://login-callback
   ```
5. Also add (for web fallback):
   ```
   https://nhiyuosjiiabxxwpkpdi.supabase.co/auth/v1/callback
   ```
6. Click **Save**

### Step 2: Disable Email Confirmation (Development Only)

If you want to skip email verification during development:

1. Go to **Authentication** → **Settings**
2. Under **Email Auth**, find **Enable email confirmations**
3. **Disable** it (toggle off)
4. Click **Save**

**Note:** Re-enable this in production for security.

### Step 3: Manual Email Verification (Alternative)

If you don't want to configure redirect URLs:

1. Go to **Authentication** → **Users**
2. Find the user who needs verification
3. Click the three dots (⋮) next to the user
4. Select **Confirm email**

## Testing

After updating the settings:

1. Sign up with a new email
2. Check your email for the verification link
3. Click the link - it should now open the Flutter app instead of showing localhost error
4. The app should automatically verify the email and log you in

## Troubleshooting

- **Still seeing localhost error?** Make sure you saved the redirect URL in Supabase dashboard
- **Link doesn't open app?** Make sure the app is installed and the deep link is configured in AndroidManifest.xml and Info.plist
- **App opens but doesn't verify?** Check the app logs for any errors

