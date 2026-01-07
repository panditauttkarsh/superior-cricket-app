-- FINAL FIX: Notification Trigger with Complete Error Handling
-- Run this in Supabase SQL Editor to fix notification creation

-- Step 1: Drop existing trigger and function
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

-- Step 2: Create improved function with comprehensive error handling
CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  v_user_id UUID;
  v_match_id UUID;
BEGIN
  -- Store values for logging
  v_user_id := NEW.player_id;
  v_match_id := NEW.match_id;
  
  -- Log that trigger fired (WARNING level shows in logs)
  RAISE WARNING 'NOTIFICATION_TRIGGER: Trigger fired for player % in match %', v_user_id, v_match_id;
  
  -- Get match information with error handling
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
    INTO STRICT match_data
    FROM public.matches m
    WHERE m.id = v_match_id;
    
    RAISE WARNING 'NOTIFICATION_TRIGGER: Match found: % - Team1: %, Team2: %', match_data.id, match_data.team1_name, match_data.team2_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Match % not found for player %', v_match_id, v_user_id;
      RETURN NEW; -- Don't fail the insert
    WHEN OTHERS THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Failed to fetch match %: %', v_match_id, SQLERRM;
      RETURN NEW; -- Don't fail the insert
  END;
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  RAISE WARNING 'NOTIFICATION_TRIGGER: Team name determined: % (team_type: %)', team_name, NEW.team_type;
  
  -- Insert notification with comprehensive error handling
  BEGIN
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      action_url,
      metadata
    ) VALUES (
      v_user_id,
      'team_added',
      'Added to Team',
      format('You have been added to %s for a match. Tap to view match details.', team_name),
      format('/match/%s', v_match_id),
      jsonb_build_object(
        'match_id', v_match_id,
        'team_name', team_name,
        'team_type', NEW.team_type,
        'added_by', NEW.added_by
      )
    );
    
    RAISE WARNING 'NOTIFICATION_SUCCESS: Notification created for user % in match %', v_user_id, v_match_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log detailed error information
      RAISE NOTICE 'FAILED: Could not create notification for user % in match %', v_user_id, v_match_id;
      RAISE NOTICE 'Error details: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
      RAISE NOTICE 'Error context: %', SQLCONTEXT;
      -- Don't fail the match_players insert - allow it to succeed
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Step 3: Recreate trigger
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- Step 4: Verify trigger was created
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_player_added_to_match';

-- Step 5: Verify RLS policies allow inserts
SELECT 
  policyname, 
  cmd, 
  roles,
  with_check
FROM pg_policies
WHERE tablename = 'notifications' AND cmd = 'INSERT';

-- Step 6: Test - Check recent match_players to see what was added
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
LIMIT 5;

-- Step 7: Check if any notifications exist
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 10;

-- IMPORTANT: After running this script:
-- 1. Check Supabase Logs (Dashboard → Logs → Postgres Logs)
-- 2. Look for RAISE NOTICE messages when you add a player
-- 3. The logs will show exactly what's happening and where it's failing

