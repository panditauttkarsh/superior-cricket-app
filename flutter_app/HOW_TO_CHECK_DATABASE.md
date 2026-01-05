# How to Check Database Schema in Supabase

## Step 1: Open Supabase Dashboard

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project
3. Click on **"SQL Editor"** in the left sidebar

## Step 2: Run the Column Check Query

Copy and paste this query into the SQL Editor:

```sql
-- Check what columns actually exist in the profiles table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;
```

Click **"Run"** to execute the query.

## Step 3: Check Column Existence

Run this query to see which specific columns exist:

```sql
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'name'
    ) THEN '✅ name exists' ELSE '❌ name does NOT exist' END as name_column,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'full_name'
    ) THEN '✅ full_name exists' ELSE '❌ full_name does NOT exist' END as full_name_column,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'avatar_url'
    ) THEN '✅ avatar_url exists' ELSE '❌ avatar_url does NOT exist' END as avatar_url_column,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'profile_image_url'
    ) THEN '✅ profile_image_url exists' ELSE '❌ profile_image_url does NOT exist' END as profile_image_url_column;
```

## Step 4: Check Match Players Data

Run this to see if match_players have valid profiles:

```sql
SELECT 
    mp.id,
    mp.match_id,
    mp.player_id,
    mp.team_type,
    CASE WHEN p.id IS NOT NULL THEN '✅ Profile exists' ELSE '❌ Profile missing' END as profile_status,
    p.username,
    p.full_name,
    p.email
FROM public.match_players mp
LEFT JOIN public.profiles p ON mp.player_id = p.id
ORDER BY mp.added_at DESC
LIMIT 20;
```

## Step 5: Alternative - Use Table Editor

1. In Supabase Dashboard, go to **"Table Editor"**
2. Click on the **"profiles"** table
3. Look at the column headers - these are the actual columns that exist
4. Check if you see:
   - `name` or `full_name`?
   - `avatar_url` or `profile_image_url`?

## What to Look For

After running the queries, check:

1. **Does `name` column exist?**
   - If YES: Keep it in the query
   - If NO: Remove it from the query

2. **Does `full_name` column exist?**
   - If YES: Use it in the query
   - If NO: Use `name` instead

3. **Does `avatar_url` column exist?**
   - If YES: Use it in the query
   - If NO: Use `profile_image_url` instead

4. **Does `profile_image_url` column exist?**
   - If YES: You can use either
   - If NO: Only use `avatar_url`

## After Checking

Once you know which columns exist, we can update the query in:
- `flutter_app/lib/core/repositories/match_player_repository.dart`

Let me know what the queries return and I'll update the code accordingly!

