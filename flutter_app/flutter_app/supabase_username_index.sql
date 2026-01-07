-- Add unique index on username for profiles table
-- This ensures usernames are unique and enables fast lookups

-- Create unique index on username (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_unique 
ON public.profiles (LOWER(username));

-- Ensure username column exists (should already exist from schema)
-- If not, this will fail gracefully
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'username'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN username TEXT;
    END IF;
END $$;

-- Update RLS policies to allow public SELECT on profiles for username lookup
-- This allows anyone to search for players by username (public data)

-- Drop existing SELECT policy if it exists
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;

-- Create new SELECT policy that allows public read access
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles
  FOR SELECT
  USING (true);

-- Ensure INSERT/UPDATE/DELETE policies exist for authenticated users
-- (These should already exist, but adding for completeness)

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Note: DELETE policy typically not needed for profiles (cascade from auth.users)

-- Add comment for documentation
COMMENT ON INDEX idx_profiles_username_unique IS 'Ensures usernames are unique (case-insensitive) for player lookup';

