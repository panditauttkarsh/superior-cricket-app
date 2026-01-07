-- Find a user by username (case-insensitive)
-- Replace 'uttkarshpandita' with the username you're searching for

-- Method 1: Exact match (case-insensitive)
SELECT 
  id,
  username,
  full_name,
  name,  -- In case it exists
  email,
  avatar_url,
  created_at
FROM public.profiles
WHERE LOWER(TRIM(username)) = LOWER(TRIM('uttkarshpandita'));

-- Method 2: Partial match (contains)
SELECT 
  id,
  username,
  full_name,
  email,
  avatar_url
FROM public.profiles
WHERE LOWER(username) LIKE LOWER('%uttkarsh%');

-- Method 3: Check all profiles to see what usernames exist
SELECT 
  id,
  username,
  full_name,
  email,
  CASE 
    WHEN username IS NULL THEN '❌ NULL'
    WHEN username = '' THEN '❌ EMPTY'
    ELSE '✅ ' || username
  END as username_status,
  created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 50;

-- Method 4: Find profiles without username (these need to be fixed)
SELECT 
  id,
  full_name,
  email,
  'Missing username' as issue
FROM public.profiles
WHERE username IS NULL OR username = '';

-- Method 5: Generate username for profiles missing it
-- (Run this to fix profiles without username)
/*
UPDATE public.profiles
SET username = LOWER(REGEXP_REPLACE(
  COALESCE(full_name, name, SPLIT_PART(email, '@', 1)), 
  '[^a-z0-9]', '', 'g'
))
WHERE username IS NULL OR username = '';
*/

