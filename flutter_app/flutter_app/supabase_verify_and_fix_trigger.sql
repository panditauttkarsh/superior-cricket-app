-- Verify and Fix Notification Trigger
-- Run this in Supabase SQL Editor

-- Step 1: Check if trigger exists and is ENABLED
SELECT 
  tgname as trigger_name,
  tgenabled as enabled_code,
  CASE tgenabled
    WHEN 'O' THEN 'origin (ENABLED)'
    WHEN 'D' THEN 'disabled (DISABLED!)'
    WHEN 'R' THEN 'replica'
    WHEN 'A' THEN 'always (ENABLED)'
    ELSE 'unknown'
  END as enabled_status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- Step 2: If trigger is disabled, enable it
-- If the above shows 'disabled', run this:
/*
ALTER TABLE public.match_players ENABLE TRIGGER on_player_added_to_match;
*/

-- Step 3: Recreate function with ERROR logging (errors always show in logs)
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  v_user_id UUID;
  v_match_id UUID;
  notification_count INTEGER;
BEGIN
  -- Store values
  v_user_id := NEW.player_id;
  v_match_id := NEW.match_id;
  
  -- Get match information
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
    INTO STRICT match_data
    FROM public.matches m
    WHERE m.id = v_match_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Log as ERROR so it shows in logs
      RAISE EXCEPTION 'NOTIFICATION_ERROR: Match % not found for player %', v_match_id, v_user_id;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'NOTIFICATION_ERROR: Failed to fetch match %: %', v_match_id, SQLERRM;
  END;
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
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
    
    -- Verify it was created
    SELECT COUNT(*) INTO notification_count
    FROM public.notifications
    WHERE user_id = v_user_id
    AND type = 'team_added'
    AND created_at > NOW() - INTERVAL '1 minute';
    
    -- If notification wasn't created, raise error
    IF notification_count = 0 THEN
      RAISE EXCEPTION 'NOTIFICATION_ERROR: Notification insert appeared to succeed but notification not found for user %', v_user_id;
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log as ERROR so it definitely shows in logs
      RAISE EXCEPTION 'NOTIFICATION_ERROR: Failed to create notification for user % in match %: % (SQLSTATE: %)', 
        v_user_id, v_match_id, SQLERRM, SQLSTATE;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Step 4: Recreate trigger and ensure it's enabled
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- Step 5: Verify trigger is enabled
SELECT 
  tgname as trigger_name,
  CASE tgenabled
    WHEN 'O' THEN 'ENABLED'
    WHEN 'D' THEN 'DISABLED - NEEDS TO BE ENABLED!'
    WHEN 'A' THEN 'ENABLED'
    ELSE 'UNKNOWN'
  END as status
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- Step 6: Check recent match_players entries
SELECT 
  mp.id,
  mp.match_id,
  mp.player_id,
  mp.team_type,
  mp.added_at,
  m.team1_name,
  m.team2_name,
  (SELECT COUNT(*) FROM public.notifications n WHERE n.user_id = mp.player_id AND n.type = 'team_added' AND n.created_at >= mp.added_at) as notification_count
FROM public.match_players mp
LEFT JOIN public.matches m ON m.id = mp.match_id
ORDER BY mp.added_at DESC
LIMIT 10;

-- Step 7: Check all notifications
SELECT 
  id,
  user_id,
  type,
  title,
  created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 20;

