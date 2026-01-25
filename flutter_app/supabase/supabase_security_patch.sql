-- SECURITY PATCH: Remove sensitive data from public profiles table
-- Date: 2026-01-24

-- 1. Drop sensitive columns if they exist
ALTER TABLE public.profiles 
DROP COLUMN IF EXISTS email,
DROP COLUMN IF EXISTS phone;

-- 2. Update RLS Policies to be strictly based on remaining public data
-- Existing policy: "Users can view all profiles" -> USING (true)
-- We keep this policy because "profiles" now only contains PUBLIC data (username, name, avatar).
-- This means anyone can view names/usernames (required for social features), but the sensitive data is physically GONE from this table.

-- 3. Cleanup any old indexes involving stripped columns
DROP INDEX IF EXISTS idx_profiles_email;

-- 4. Verify Policy (just to be sure)
DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
CREATE POLICY "Users can view all public info" ON public.profiles FOR SELECT USING (true);

-- 5. Fix Insert Policy (Users insert their own profile)
DROP POLICY IF EXISTS "Users can create own profile" ON public.profiles;
CREATE POLICY "Users can create own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- 6. Fix Update Policy
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
