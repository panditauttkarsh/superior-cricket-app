-- Check ALL profiles in the database
-- This will help us see what users actually exist

-- Method 1: List all profiles with their usernames
SELECT 
  id,
  username,
  full_name,
  email,
  avatar_url,
  created_at,
  CASE 
    WHEN username IS NULL THEN '❌ NULL'
    WHEN username = '' THEN '❌ EMPTY'
    ELSE '✅ ' || username
  END as username_status
FROM public.profiles
ORDER BY created_at DESC;

-- Method 2: Count total profiles
SELECT 
  COUNT(*) as total_profiles,
  COUNT(username) as profiles_with_username,
  COUNT(*) - COUNT(username) as profiles_without_username
FROM public.profiles;

-- Method 3: Check if the Google login user exists
-- Replace with the actual email if you know it
SELECT 
  id,
  username,
  full_name,
  email,
  created_at
FROM public.profiles
WHERE email IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Method 4: Check auth.users to see if user exists there
-- (This requires proper permissions)
SELECT 
  id,
  email,
  raw_user_meta_data->>'name' as name_from_google,
  raw_user_meta_data->>'full_name' as full_name_from_google,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 10;

-- Method 5: Find profiles that exist in auth.users but NOT in profiles
-- (This indicates the trigger might not have fired)
SELECT 
  u.id,
  u.email,
  u.raw_user_meta_data->>'name' as name,
  u.created_at as auth_created_at,
  p.id as profile_exists
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC;

