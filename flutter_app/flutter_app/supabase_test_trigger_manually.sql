-- Test trigger manually to see if it works
-- Run this in Supabase SQL Editor

-- Step 1: Check if trigger is enabled
SELECT 
  tgname as trigger_name,
  tgenabled as is_enabled,
  CASE tgenabled
    WHEN 'O' THEN 'origin'
    WHEN 'D' THEN 'disabled'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always'
    ELSE 'unknown'
  END as enabled_status
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- Step 2: Get a recent match_players entry to test with
SELECT 
  mp.id,
  mp.match_id,
  mp.player_id,
  mp.team_type,
  mp.added_at,
  m.team1_name,
  m.team2_name
FROM public.match_players mp
LEFT JOIN public.matches m ON m.id = mp.match_id
ORDER BY mp.added_at DESC
LIMIT 1;

-- Step 3: Test the function manually with actual data
-- Replace the UUIDs below with values from Step 2
/*
DO $$
DECLARE
  test_match_id UUID := 'PASTE_MATCH_ID_FROM_STEP_2';
  test_player_id UUID := 'PASTE_PLAYER_ID_FROM_STEP_2';
  test_team_type TEXT := 'PASTE_TEAM_TYPE_FROM_STEP_2';
  result RECORD;
BEGIN
  -- Simulate what the trigger does
  -- Create a fake NEW record
  PERFORM public.notify_player_added_to_match() FROM (
    SELECT 
      test_match_id as match_id,
      test_player_id as player_id,
      test_team_type as team_type,
      NULL::UUID as added_by
  ) AS fake_new;
  
  RAISE NOTICE 'Function executed';
END $$;
*/

-- Step 4: Check if notifications table is accessible
SELECT COUNT(*) as notification_count FROM public.notifications;

-- Step 5: Try to manually insert a notification (to test RLS)
-- Replace 'YOUR_USER_ID' with an actual user ID
/*
-- First, get a user ID:
SELECT id, email FROM auth.users LIMIT 1;

-- Then try to insert:
INSERT INTO public.notifications (
  user_id,
  type,
  title,
  message,
  action_url
) VALUES (
  'PASTE_USER_ID_HERE',
  'team_added',
  'Test Notification',
  'This is a manual test',
  '/match/test'
);

-- If this fails, RLS is blocking
-- If this works, the issue is with the trigger/function
*/

-- Step 6: Check if the function exists and its definition
SELECT 
  p.proname as function_name,
  pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_player_added_to_match';

-- Step 7: Enable logging for NOTICE messages
-- In Supabase, NOTICE messages might not show in regular logs
-- Check the function directly by calling it

-- Step 8: Direct function test (replace with actual values)
/*
SELECT public.notify_player_added_to_match() FROM (
  SELECT 
    'MATCH_ID_HERE'::UUID as match_id,
    'PLAYER_ID_HERE'::UUID as player_id,
    'team1'::TEXT as team_type,
    NULL::UUID as added_by
) AS NEW;
*/

