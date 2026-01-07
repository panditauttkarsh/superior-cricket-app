-- Commentary table for ball-by-ball commentary
-- This table stores live commentary entries generated from scoring events

CREATE TABLE IF NOT EXISTS public.commentary (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
  over NUMERIC(4,1) NOT NULL, -- e.g., 5.3 means 5th over, 3rd ball
  ball_type TEXT NOT NULL, -- 'normal', 'wide', 'noBall', 'wicket', 'bye', 'legBye'
  runs INTEGER NOT NULL DEFAULT 0,
  wicket_type TEXT, -- 'bowled', 'caught', 'lbw', 'runOut', 'stumped', etc.
  striker_name TEXT NOT NULL,
  bowler_name TEXT NOT NULL,
  non_striker_name TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  commentary_text TEXT NOT NULL, -- Human-readable sentence
  shot_direction TEXT, -- 'cover', 'midwicket', 'straight', etc.
  shot_type TEXT, -- 'drive', 'cut', 'pull', etc.a
  is_extra BOOLEAN DEFAULT FALSE,
  extra_type TEXT, -- 'WD', 'NB', 'B', 'LB'
  extra_runs INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_commentary_match_id ON public.commentary(match_id);
CREATE INDEX IF NOT EXISTS idx_commentary_timestamp ON public.commentary(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_commentary_over ON public.commentary(match_id, over DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.commentary ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read commentary (public data)
CREATE POLICY "Commentary is viewable by everyone"
  ON public.commentary
  FOR SELECT
  USING (true);

-- Policy: Authenticated users can insert commentary (scorers)
CREATE POLICY "Authenticated users can insert commentary"
  ON public.commentary
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Policy: Users can update their own commentary (if needed)
CREATE POLICY "Users can update commentary"
  ON public.commentary
  FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Policy: Users can delete commentary (for corrections)
CREATE POLICY "Users can delete commentary"
  ON public.commentary
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- Comments for documentation
COMMENT ON TABLE public.commentary IS 'Stores ball-by-ball commentary generated from scoring events';
COMMENT ON COLUMN public.commentary.over IS 'Over number with ball (e.g., 5.3 = 5th over, 3rd ball)';
COMMENT ON COLUMN public.commentary.ball_type IS 'Type of ball: normal, wide, noBall, wicket, bye, legBye';
COMMENT ON COLUMN public.commentary.commentary_text IS 'Auto-generated human-readable commentary text';

