-- FINAL FIX: Update function to use WARNING level logging and ensure trigger is enabled
-- Run this in Supabase SQL Editor

-- Step 1: Check if trigger is enabled
SELECT 
  tgname as trigger_name,
  tgenabled as enabled_code,
  CASE tgenabled
    WHEN 'O' THEN 'origin (ENABLED)'
    WHEN 'D' THEN 'disabled (DISABLED - THIS IS THE PROBLEM!)'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always (ENABLED)'
    ELSE 'unknown'
  END as enabled_status
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- Step 2: Drop and recreate function with WARNING level logging (shows in logs)
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  v_user_id UUID;
  v_match_id UUID;
BEGIN
  -- Store values
  v_user_id := NEW.player_id;
  v_match_id := NEW.match_id;
  
  -- Log that trigger fired (WARNING shows in logs)
  RAISE WARNING 'NOTIFICATION_TRIGGER: Fired for player % in match %', v_user_id, v_match_id;
  
  -- Get match information
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
    INTO STRICT match_data
    FROM public.matches m
    WHERE m.id = v_match_id;
    
    RAISE WARNING 'NOTIFICATION_TRIGGER: Match found - Team1: %, Team2: %', match_data.team1_name, match_data.team2_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Match % not found for player %', v_match_id, v_user_id;
      RETURN NEW;
    WHEN OTHERS THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Failed to fetch match %: %', v_match_id, SQLERRM;
      RETURN NEW;
  END;
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  RAISE WARNING 'NOTIFICATION_TRIGGER: Team name: % (type: %)', team_name, NEW.team_type;
  
  -- Insert notification
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
    
    RAISE WARNING 'NOTIFICATION_SUCCESS: Created notification for user % in match %', v_user_id, v_match_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- WARNING level shows in logs
      RAISE WARNING 'NOTIFICATION_ERROR: Failed to create notification for user % in match %: % (SQLSTATE: %)', 
        v_user_id, v_match_id, SQLERRM, SQLSTATE;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Step 3: Recreate trigger and ENSURE it's enabled
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- Step 4: EXPLICITLY enable the trigger (in case it was disabled)
ALTER TABLE public.match_players ENABLE TRIGGER on_player_added_to_match;

-- Step 5: Verify trigger is enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN '✓ ENABLED'
    WHEN 'D' THEN '✗ DISABLED - RUN: ALTER TABLE public.match_players ENABLE TRIGGER on_player_added_to_match;'
    WHEN 'A' THEN '✓ ENABLED'
    ELSE 'UNKNOWN'
  END as status
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- Step 6: Check recent match_players and see if notifications exist
SELECT 
  mp.id,
  mp.match_id,
  mp.player_id,
  mp.team_type,
  mp.added_at,
  m.team1_name,
  m.team2_name,
  (SELECT COUNT(*) 
   FROM public.notifications n 
   WHERE n.user_id = mp.player_id 
   AND n.type = 'team_added' 
   AND n.created_at >= mp.added_at - INTERVAL '1 minute'
   AND n.created_at <= mp.added_at + INTERVAL '1 minute'
  ) as notification_count
FROM public.match_players mp
LEFT JOIN public.matches m ON m.id = mp.match_id
ORDER BY mp.added_at DESC
LIMIT 10;

