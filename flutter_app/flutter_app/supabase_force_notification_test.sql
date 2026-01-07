-- Force test notification creation
-- This will help us see if the issue is with the trigger or the function itself

-- Step 1: Check if we can manually insert a notification
-- Replace 'YOUR_PLAYER_ID' with an actual user ID from auth.users or profiles
/*
INSERT INTO public.notifications (
  user_id,
  type,
  title,
  message,
  action_url,
  metadata
) VALUES (
  'YOUR_PLAYER_ID_HERE',
  'team_added',
  'Added to Team',
  'You have been added to Test Team for a match. Tap to view match details.',
  '/match/test-match-id',
  jsonb_build_object(
    'match_id', 'test-match-id',
    'team_name', 'Test Team'
  )
);
*/

-- Step 2: If manual insert works, the issue is with the trigger
-- Let's recreate the trigger with better error handling

-- Drop and recreate with explicit error logging
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;

-- Recreate function with better error handling
CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  notification_title TEXT;
  notification_message TEXT;
  v_user_id UUID;
BEGIN
  -- Set user_id from NEW
  v_user_id := NEW.player_id;
  
  -- Get match information
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
    INTO match_data
    FROM public.matches m
    WHERE m.id = NEW.match_id;
    
    IF NOT FOUND THEN
      RAISE NOTICE 'Match not found: %', NEW.match_id;
      RETURN NEW;
    END IF;
  EXCEPTION
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
  
  -- Create notification
  notification_title := 'Added to Team';
  notification_message := format('You have been added to %s for a match. Tap to view match details.', team_name);
  
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
      notification_title,
      notification_message,
      format('/match/%s', NEW.match_id),
      jsonb_build_object(
        'match_id', NEW.match_id,
        'team_name', team_name,
        'team_type', NEW.team_type,
        'added_by', NEW.added_by
      )
    );
    
    RAISE NOTICE 'Notification created for user % in match %', v_user_id, NEW.match_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log detailed error
      RAISE NOTICE 'Failed to create notification for user % in match %: % (SQLSTATE: %)', 
        v_user_id, NEW.match_id, SQLERRM, SQLSTATE;
      -- Don't fail the insert - allow match_players insert to succeed
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

-- Verify trigger was created
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table, 
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_player_added_to_match';

