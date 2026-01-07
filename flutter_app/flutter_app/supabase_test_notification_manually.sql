-- MANUAL TEST: Test notification trigger
-- Run this AFTER running supabase_complete_notification_fix.sql
-- Replace the UUIDs with actual user IDs from your database

-- Step 1: Get some test user IDs
SELECT 
  id as user_id,
  email,
  raw_user_meta_data->>'username' as username
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Get a test match ID
SELECT 
  id as match_id,
  team1_name,
  team2_name,
  created_by
FROM public.matches
ORDER BY created_at DESC
LIMIT 5;

-- Step 3: Manually insert a match_player entry to test the trigger
-- Replace the UUIDs below with actual IDs from steps 1 and 2
/*
DO $$
DECLARE
  v_match_id UUID := 'REPLACE_WITH_MATCH_ID';
  v_player_id UUID := 'REPLACE_WITH_PLAYER_ID';  -- e.g., utkarshpandita's user ID
  v_added_by UUID := 'REPLACE_WITH_CREATOR_ID';  -- e.g., shivamganju's user ID
  v_notification_count INTEGER;
BEGIN
  -- Insert a match_player entry (this should trigger the notification)
  INSERT INTO public.match_players (
    match_id,
    player_id,
    team_type,
    role,
    added_by
  ) VALUES (
    v_match_id,
    v_player_id,
    'team1',
    'Player',
    v_added_by
  );
  
  RAISE NOTICE 'Inserted match_player entry';
  RAISE NOTICE 'Match ID: %', v_match_id;
  RAISE NOTICE 'Player ID: %', v_player_id;
  RAISE NOTICE 'Added by: %', v_added_by;
  
  -- Wait a moment for trigger to fire
  PERFORM pg_sleep(1);
  
  -- Check if notification was created
  SELECT COUNT(*) INTO v_notification_count
  FROM public.notifications
  WHERE user_id = v_player_id
  AND type = 'team_added'
  AND created_at > NOW() - INTERVAL '1 minute';
  
  IF v_notification_count > 0 THEN
    RAISE NOTICE '✓ SUCCESS: Notification created! Count: %', v_notification_count;
  ELSE
    RAISE WARNING '✗ FAILED: No notification created';
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error during test: %', SQLERRM;
END $$;
*/

-- Step 4: Check the logs for trigger messages
-- Go to Supabase Dashboard → Logs → Postgres Logs
-- Look for messages starting with:
--   NOTIFICATION_TRIGGER:
--   NOTIFICATION_SUCCESS:
--   NOTIFICATION_ERROR:
--   NOTIFICATION_SKIP:

-- Step 5: Verify notification was created
SELECT 
  n.id,
  n.user_id,
  n.type,
  n.title,
  n.message,
  n.created_at,
  n.metadata->>'match_id' as match_id,
  n.metadata->>'added_by' as added_by,
  u.email as user_email
FROM public.notifications n
LEFT JOIN auth.users u ON u.id = n.user_id
WHERE n.type = 'team_added'
ORDER BY n.created_at DESC
LIMIT 5;

