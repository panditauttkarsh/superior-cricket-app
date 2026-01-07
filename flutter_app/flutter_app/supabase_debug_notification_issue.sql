-- Debug notification trigger issue
-- Run this in Supabase SQL Editor to check what's happening

-- 1. Check if trigger exists and is enabled
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table, 
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_player_added_to_match';

-- 2. Check recent match_players inserts (to see if data is being inserted)
SELECT 
  id,
  match_id,
  player_id,
  team_type,
  added_at,
  added_by
FROM public.match_players
ORDER BY added_at DESC
LIMIT 10;

-- 3. Check if any notifications were created
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

-- 4. Test the function manually (replace with actual match_id and player_id from step 2)
-- First, get a recent match_players entry:
/*
SELECT match_id, player_id, team_type 
FROM public.match_players 
ORDER BY added_at DESC 
LIMIT 1;
*/

-- Then test the function logic manually:
/*
DO $$
DECLARE
  test_match_id UUID;
  test_player_id UUID;
  test_team_type TEXT;
  match_data RECORD;
  team_name TEXT;
BEGIN
  -- Get the most recent match_players entry
  SELECT match_id, player_id, team_type 
  INTO test_match_id, test_player_id, test_team_type
  FROM public.match_players 
  ORDER BY added_at DESC 
  LIMIT 1;
  
  IF test_match_id IS NULL THEN
    RAISE NOTICE 'No match_players entries found';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Testing with match_id: %, player_id: %, team_type: %', test_match_id, test_player_id, test_team_type;
  
  -- Get match information
  SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
  INTO match_data
  FROM public.matches m
  WHERE m.id = test_match_id;
  
  IF match_data.id IS NULL THEN
    RAISE NOTICE 'Match not found: %', test_match_id;
    RETURN;
  END IF;
  
  -- Determine team name
  IF test_team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  RAISE NOTICE 'Team name: %', team_name;
  
  -- Try to insert notification
  BEGIN
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      action_url,
      metadata
    ) VALUES (
      test_player_id,
      'team_added',
      'Added to Team',
      format('You have been added to %s for a match. Tap to view match details.', team_name),
      format('/match/%s', test_match_id),
      jsonb_build_object(
        'match_id', test_match_id,
        'team_name', team_name,
        'team_type', test_team_type
      )
    );
    RAISE NOTICE 'Notification created successfully';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error creating notification: %', SQLERRM;
  END;
END $$;
*/

-- 5. Check RLS policies on notifications table
SELECT 
  policyname, 
  cmd, 
  roles,
  qual, 
  with_check
FROM pg_policies
WHERE tablename = 'notifications';

-- 6. Check if the function has the right permissions
SELECT 
  p.proname as function_name,
  p.prosecdef as is_security_definer,
  pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_player_added_to_match';

