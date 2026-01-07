-- Check if a profile exists and what their username is
-- Replace 'uttkarshpandita' with the username you're searching for

-- Check by username (case-insensitive)
SELECT id, username, name, full_name, email, profile_image_url, avatar_url
FROM public.profiles
WHERE LOWER(username) = LOWER('uttkarshpandita');

-- Check by partial username match
SELECT id, username, name, full_name, email
FROM public.profiles
WHERE LOWER(username) LIKE LOWER('%uttkarsh%');

-- Check by email (if you know the email)
-- SELECT id, username, name, full_name, email
-- FROM public.profiles
-- WHERE LOWER(email) = LOWER('user@example.com');

-- List all profiles to see what usernames exist
SELECT id, username, name, full_name, email, created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 20;

-- Check if username column has any NULL values
SELECT COUNT(*) as total_profiles,
       COUNT(username) as profiles_with_username,
       COUNT(*) - COUNT(username) as profiles_without_username
FROM public.profiles;

