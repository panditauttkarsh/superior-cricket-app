-- Fix for Google OAuth: Add missing trigger function and update schema
-- Run this in Supabase SQL Editor

-- First, update the profiles table to use full_name instead of name
ALTER TABLE public.profiles 
  DROP COLUMN IF EXISTS name,
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the trigger function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_name TEXT;
  user_email TEXT;
  user_username TEXT;
  user_avatar_url TEXT;
BEGIN
  -- Get user data from metadata or email
  user_name := COALESCE(
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1),
    'User'
  );
  
  user_email := LOWER(TRIM(NEW.email));
  user_avatar_url := NEW.raw_user_meta_data->>'avatar_url';
  
  -- Generate unique username
  user_username := public.generate_unique_username(user_name);
  
  -- Insert profile (ignore if already exists to prevent errors)
  INSERT INTO public.profiles (id, email, full_name, username, avatar_url, created_at, updated_at)
  VALUES (
    NEW.id,
    user_email,
    user_name,
    user_username,
    user_avatar_url,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the auth user creation
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to run on new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO anon, authenticated;

