-- Tournament Module Database Schema
-- Run this in Supabase SQL Editor

-- Tournaments table
CREATE TABLE IF NOT EXISTS public.tournaments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  ground TEXT NOT NULL,
  banner_url TEXT,
  logo_url TEXT,
  organizer_name TEXT NOT NULL,
  organizer_mobile TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('open', 'corporate', 'community', 'school', 'college', 'series', 'other')),
  ball_type TEXT NOT NULL CHECK (ball_type IN ('leather', 'tennis', 'other')),
  pitch_type TEXT NOT NULL CHECK (pitch_type IN ('matting', 'rough', 'cemented', 'astro-turf')),
  invite_link_enabled BOOLEAN DEFAULT TRUE,
  invite_link_token TEXT UNIQUE, -- Unique token for invite link
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT end_date_after_start CHECK (end_date >= start_date),
  CONSTRAINT valid_mobile CHECK (char_length(organizer_mobile) = 10 AND organizer_mobile ~ '^[0-9]+$')
);

-- Tournament Teams table
CREATE TABLE IF NOT EXISTS public.tournament_teams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE NOT NULL,
  team_name TEXT NOT NULL,
  team_logo TEXT,
  join_type TEXT NOT NULL CHECK (join_type IN ('manual', 'invite')),
  captain_id UUID REFERENCES auth.users(id), -- Optional: captain user ID
  captain_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, team_name) -- Prevent duplicate team names in same tournament
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournaments_created_by ON public.tournaments(created_by);
CREATE INDEX IF NOT EXISTS idx_tournaments_start_date ON public.tournaments(start_date);
CREATE INDEX IF NOT EXISTS idx_tournaments_invite_token ON public.tournaments(invite_link_token);
CREATE INDEX IF NOT EXISTS idx_tournament_teams_tournament_id ON public.tournament_teams(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_teams_captain_id ON public.tournament_teams(captain_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_teams ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tournaments
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Users can create tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Users can update own tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Users can delete own tournaments" ON public.tournaments;

-- Users can view all tournaments
CREATE POLICY "Users can view all tournaments"
  ON public.tournaments
  FOR SELECT
  USING (true);

-- Users can create tournaments
CREATE POLICY "Users can create tournaments"
  ON public.tournaments
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Users can update their own tournaments (only before start date)
CREATE POLICY "Users can update own tournaments"
  ON public.tournaments
  FOR UPDATE
  USING (auth.uid() = created_by AND start_date > CURRENT_DATE)
  WITH CHECK (auth.uid() = created_by AND start_date > CURRENT_DATE);

-- Users can delete their own tournaments (only before start date)
CREATE POLICY "Users can delete own tournaments"
  ON public.tournaments
  FOR DELETE
  USING (auth.uid() = created_by AND start_date > CURRENT_DATE);

-- RLS Policies for tournament_teams
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view tournament teams" ON public.tournament_teams;
DROP POLICY IF EXISTS "Users can add teams to tournaments" ON public.tournament_teams;
DROP POLICY IF EXISTS "Users can update own tournament teams" ON public.tournament_teams;
DROP POLICY IF EXISTS "Users can delete own tournament teams" ON public.tournament_teams;

-- Users can view all tournament teams
CREATE POLICY "Users can view tournament teams"
  ON public.tournament_teams
  FOR SELECT
  USING (true);

-- Users can add teams if they created the tournament OR via invite link
-- For invite link: We'll handle this in the application layer
CREATE POLICY "Users can add teams to tournaments"
  ON public.tournament_teams
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tournaments t
      WHERE t.id = tournament_id
      AND (t.created_by = auth.uid() OR t.invite_link_enabled = TRUE)
    )
  );

-- Users can update teams if they created the tournament (only before start date)
CREATE POLICY "Users can update own tournament teams"
  ON public.tournament_teams
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.tournaments t
      WHERE t.id = tournament_id
      AND t.created_by = auth.uid()
      AND t.start_date > CURRENT_DATE
    )
  );

-- Users can delete teams if they created the tournament (only before start date)
CREATE POLICY "Users can delete own tournament teams"
  ON public.tournament_teams
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.tournaments t
      WHERE t.id = tournament_id
      AND t.created_by = auth.uid()
      AND t.start_date > CURRENT_DATE
    )
  );

-- Function to generate unique invite link token
CREATE OR REPLACE FUNCTION generate_invite_token()
RETURNS TEXT AS $$
BEGIN
  RETURN encode(gen_random_bytes(16), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Function to auto-generate invite token on tournament creation
CREATE OR REPLACE FUNCTION set_tournament_invite_token()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invite_link_token IS NULL THEN
    NEW.invite_link_token := generate_invite_token();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate invite token
DROP TRIGGER IF EXISTS trigger_set_tournament_invite_token ON public.tournaments;
CREATE TRIGGER trigger_set_tournament_invite_token
  BEFORE INSERT ON public.tournaments
  FOR EACH ROW
  EXECUTE FUNCTION set_tournament_invite_token();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS trigger_update_tournaments_updated_at ON public.tournaments;
CREATE TRIGGER trigger_update_tournaments_updated_at
  BEFORE UPDATE ON public.tournaments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE public.tournaments IS 'Tournament information and settings';
COMMENT ON TABLE public.tournament_teams IS 'Teams registered for tournaments';
COMMENT ON COLUMN public.tournaments.invite_link_token IS 'Unique token for tournament invite link';
COMMENT ON COLUMN public.tournament_teams.join_type IS 'How the team joined: manual (added by organizer) or invite (joined via invite link)';

