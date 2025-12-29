-- Test the notification trigger function
-- Run this in Supabase SQL Editor

-- 1. Check if function exists and its definition
SELECT 
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_player_added_to_match';

-- 2. Check RLS policies on notifications table
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check
FROM pg_policies
WHERE tablename = 'notifications';

-- 3. Check if notifications table has RLS enabled
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'notifications';

-- 4. Test the function directly (replace with actual values)
-- This simulates what the trigger does
/*
DO $$
DECLARE
  test_match_id UUID := 'YOUR_MATCH_ID_HERE';
  test_player_id UUID := 'YOUR_PLAYER_ID_HERE';
  test_team_type TEXT := 'team1';
BEGIN
  -- Simulate the trigger by calling the function logic
  PERFORM public.notify_player_added_to_match() FROM (
    SELECT 
      test_match_id as match_id,
      test_player_id as player_id,
      test_team_type as team_type,
      NULL::UUID as added_by
  ) AS NEW;
END $$;
*/

-- 5. Check recent notifications to see if any were created
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  is_read,
  created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 10;

-- 6. Check recent match_players inserts
SELECT 
  id,
  match_id,
  player_id,
  team_type,
  added_at
FROM public.match_players
ORDER BY added_at DESC
LIMIT 10;

