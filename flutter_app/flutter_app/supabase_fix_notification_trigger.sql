-- Fix notification trigger - ensure it can insert notifications
-- Run this in Supabase SQL Editor

-- 1. Drop trigger first (since it depends on the function)
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;

-- 2. Drop and recreate the function with explicit search_path
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  notification_title TEXT;
  notification_message TEXT;
BEGIN
  -- Get match information
  SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at
  INTO match_data
  FROM public.matches m
  WHERE m.id = NEW.match_id;
  
  -- Check if match exists
  IF NOT FOUND OR match_data.id IS NULL THEN
    RAISE NOTICE 'Match not found: %', NEW.match_id;
    RETURN NEW;
  END IF;
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  -- Create notification
  notification_title := 'Added to Team';
  notification_message := format('You have been added to %s for a match. Tap to view match details.', team_name);
  
  -- Insert notification (this should work with SECURITY DEFINER)
  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    action_url,
    metadata
  ) VALUES (
    NEW.player_id,
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
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the insert
    -- Use RAISE NOTICE so it shows in logs
    RAISE NOTICE 'Error creating notification for player % in match %: %', NEW.player_id, NEW.match_id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- 3. Recreate trigger
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- 4. Verify RLS allows inserts (should already be set, but ensure it)
-- The function uses SECURITY DEFINER, so it should bypass RLS
-- But we need to ensure the policy exists
DROP POLICY IF EXISTS "Service role can create notifications" ON public.notifications;

-- The existing "System can create notifications" policy should be enough
-- But let's verify it exists
SELECT 
  policyname, 
  cmd, 
  with_check
FROM pg_policies
WHERE tablename = 'notifications' AND cmd = 'INSERT';

