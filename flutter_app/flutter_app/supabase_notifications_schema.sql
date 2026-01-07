-- Notifications and Match Players Schema
-- Run this in Supabase SQL Editor

-- Match Players Table (tracks which players are in which matches/teams)
CREATE TABLE IF NOT EXISTS public.match_players (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
  player_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  team_type TEXT NOT NULL, -- 'team1' or 'team2' (my team or opponent)
  role TEXT, -- 'batsman', 'bowler', 'all-rounder', 'wicket-keeper', etc.
  is_captain BOOLEAN DEFAULT FALSE,
  is_wicket_keeper BOOLEAN DEFAULT FALSE,
  added_by UUID REFERENCES auth.users(id), -- Who added this player
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id, player_id, team_type) -- Prevent duplicate entries
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL, -- 'team_added', 'match_invite', 'match_update', 'achievement', etc.
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  action_url TEXT, -- Deep link to relevant screen (e.g., '/match/:matchId')
  metadata JSONB DEFAULT '{}', -- Additional data (match_id, team_name, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_match_players_match_id ON public.match_players(match_id);
CREATE INDEX IF NOT EXISTS idx_match_players_player_id ON public.match_players(player_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.match_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for match_players
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view match players" ON public.match_players;
DROP POLICY IF EXISTS "Match creators can add players" ON public.match_players;

-- Users can read match_players for matches they're part of or created
CREATE POLICY "Users can view match players"
  ON public.match_players
  FOR SELECT
  USING (
    auth.uid() = player_id OR
    auth.uid() = added_by OR
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_players.match_id
      AND m.created_by = auth.uid()
    )
  );

-- Users can insert match_players if they created the match
CREATE POLICY "Match creators can add players"
  ON public.match_players
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id AND m.created_by = auth.uid()
    )
  );

-- RLS Policies for notifications
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

-- Users can only read their own notifications
CREATE POLICY "Users can view own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- System can create notifications for any user
-- This policy allows the trigger function (SECURITY DEFINER) to insert notifications
CREATE POLICY "System can create notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true); -- Allow any insert (trigger function uses SECURITY DEFINER)

-- Additional policy: Allow service role to insert (for triggers)
-- This ensures the SECURITY DEFINER function can insert
CREATE POLICY "Service role can create notifications"
  ON public.notifications
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Enable Realtime for notifications (so users get instant updates)
-- Only add if not already in publication (handles case where table already exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'notifications' 
    AND schemaname = 'public'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

-- Function to create notification when player is added to match
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
  
  -- Determine team name
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  -- Create notification
  notification_title := 'Added to Team';
  notification_message := format('You have been added to %s for a match. Tap to view match details.', team_name);
  
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
    RAISE WARNING 'Error creating notification: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Trigger to create notification when player is added
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- Comments for documentation
COMMENT ON TABLE public.match_players IS 'Tracks which players are assigned to which matches and teams';
COMMENT ON TABLE public.notifications IS 'In-app notifications for users';
COMMENT ON FUNCTION public.notify_player_added_to_match() IS 'Automatically creates notification when a player is added to a match';

