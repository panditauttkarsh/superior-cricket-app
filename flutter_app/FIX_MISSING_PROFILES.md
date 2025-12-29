# Fix Missing Profiles Issue

## Problem Identified
Users who logged in with Google OAuth exist in `auth.users` but are missing from `public.profiles`. This causes the username lookup to fail.

**Affected Users:**
- `uttkarshpandita@gmail.com` - Missing profile ❌
- `shivamganju@gmail.com` - Missing profile ❌

## Solution

### Step 1: Create Missing Profiles
Run `supabase_create_missing_profiles.sql` in Supabase SQL Editor.

This will:
1. Create profiles for all users in `auth.users` who don't have profiles
2. Generate unique usernames automatically
3. Copy name, email, and avatar from Google auth data

### Step 2: Verify Username Generation
After running the script, check what username was generated:

```sql
SELECT username, full_name, email
FROM public.profiles
WHERE email = 'uttkarshpandita@gmail.com';
```

The username will likely be something like:
- `uttkarshpandita` (if no conflicts)
- `uttkarshpandita1` (if conflict exists)
- Or similar variation

### Step 3: Ensure Trigger Exists for Future Users
Run `supabase_fix_google_auth.sql` to ensure the trigger is set up correctly for future Google logins.

## How to Use After Fix

1. **Find the actual username:**
   - Run the verification query above
   - Note the generated username

2. **Add player in app:**
   - Use the actual username (not email)
   - Example: If username is `uttkarshpandita`, enter `uttkarshpandita` or `@uttkarshpandita`

3. **If username doesn't match:**
   - The improved search in `ProfileRepository` will try:
     - Exact username match
     - Partial username match
     - Email match
     - Name match
   - So even if you enter `uttkarshpandita` and the username is `uttkarshpandita1`, it should still find them

## Prevention

The trigger `on_auth_user_created` should automatically create profiles for new Google login users. If it's not working:

1. Check if trigger exists:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

2. If missing, run `supabase_fix_google_auth.sql`

3. For existing users without profiles, run `supabase_create_missing_profiles.sql`

