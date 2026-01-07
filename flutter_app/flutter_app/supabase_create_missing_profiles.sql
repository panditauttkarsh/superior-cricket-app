-- Create missing profiles for users who exist in auth.users but not in profiles
-- This fixes the issue where Google login users don't have profiles

-- Step 1: Create profiles for all missing users
INSERT INTO public.profiles (id, email, full_name, username, avatar_url, created_at, updated_at)
SELECT 
  u.id,
  LOWER(TRIM(u.email)) as email,
  COALESCE(
    u.raw_user_meta_data->>'name',
    u.raw_user_meta_data->>'full_name',
    SPLIT_PART(u.email, '@', 1),
    'User'
  ) as full_name,
  -- Generate unique username using the function
  public.generate_unique_username(
    COALESCE(
      u.raw_user_meta_data->>'name',
      u.raw_user_meta_data->>'full_name',
      SPLIT_PART(u.email, '@', 1),
      'user'
    )
  ) as username,
  u.raw_user_meta_data->>'avatar_url' as avatar_url,
  u.created_at,
  NOW() as updated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Verify the profiles were created
SELECT 
  p.id,
  p.username,
  p.full_name,
  p.email,
  '✅ Profile created' as status
FROM public.profiles p
INNER JOIN auth.users u ON p.id = u.id
WHERE u.email IN ('uttkarshpandita@gmail.com', 'shivamganju@gmail.com')
ORDER BY p.created_at DESC;

-- Step 3: Check what username was generated for uttkarshpandita
SELECT 
  username,
  full_name,
  email
FROM public.profiles
WHERE email = 'uttkarshpandita@gmail.com';

