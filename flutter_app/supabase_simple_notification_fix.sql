-- Simple fix for notification trigger
-- Run this in Supabase SQL Editor

-- Drop trigger and function
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

-- Create function with better error handling and logging
CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  v_user_id UUID;
BEGIN
  -- Store player_id
  v_user_id := NEW.player_id;
  
  -- Get match information with error handling
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
    INTO STRICT match_data
    FROM public.matches m
    WHERE m.id = NEW.match_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE NOTICE 'Match % not found for player %', NEW.match_id, v_user_id;
      RETURN NEW;
    WHEN OTHERS THEN
      RAISE NOTICE 'Error fetching match %: %', NEW.match_id, SQLERRM;
      RETURN NEW;
  END;
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  -- Insert notification with explicit error handling
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
      format('/match/%s', NEW.match_id),
      jsonb_build_object(
        'match_id', NEW.match_id,
        'team_name', team_name,
        'team_type', NEW.team_type,
        'added_by', NEW.added_by
      )
    );
    
    -- Log success (check Supabase logs to see this)
    RAISE NOTICE 'Notification created successfully for user % in match %', v_user_id, NEW.match_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log detailed error (check Supabase logs)
      RAISE NOTICE 'FAILED to create notification for user % in match %: Error: % (SQLSTATE: %)', 
        v_user_id, NEW.match_id, SQLERRM, SQLSTATE;
      -- Don't fail the match_players insert
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Recreate trigger
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- Verify it was created
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_player_added_to_match';

-- Test: Check if you can manually insert a notification
-- Replace 'YOUR_USER_ID' with an actual user ID
/*
SELECT id FROM auth.users LIMIT 1;
-- Use that ID in the test below

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
  'This is a test notification',
  '/match/test'
);

-- If this works, the RLS is fine and the issue is with the trigger
-- If this fails, there's an RLS issue
*/

