-- Check what columns actually exist in the profiles table
-- Run this in Supabase SQL Editor

-- Method 1: Get all column names from information_schema
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Method 2: Try to select all columns and see what works
-- This will show you what columns exist
SELECT * 
FROM public.profiles 
LIMIT 1;

-- Method 3: Check if specific columns exist
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

