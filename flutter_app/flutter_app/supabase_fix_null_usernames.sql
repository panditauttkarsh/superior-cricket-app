-- Fix NULL usernames in existing profiles
-- This will generate usernames for profiles that have NULL username

-- Step 1: Update profiles with NULL username
UPDATE public.profiles
SET username = public.generate_unique_username(
  COALESCE(full_name, SPLIT_PART(email, '@', 1), 'user')
)
WHERE username IS NULL OR username = '';

-- Step 2: Verify the fix for uttkarshpandita
SELECT 
  username,
  full_name,
  email,
  CASE 
    WHEN username IS NULL THEN '❌ Still NULL'
    WHEN username = '' THEN '❌ Still EMPTY'
    ELSE '✅ Username: ' || username
  END as status
FROM public.profiles
WHERE email = 'uttkarshpandita@gmail.com';

-- Step 3: Check all profiles to see if any still have NULL usernames
SELECT 
  COUNT(*) as total_profiles,
  COUNT(username) as profiles_with_username,
  COUNT(*) - COUNT(username) as profiles_without_username
FROM public.profiles;

-- Step 4: List all profiles with their usernames (to see what was generated)
SELECT 
  username,
  full_name,
  email,
  created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 20;

