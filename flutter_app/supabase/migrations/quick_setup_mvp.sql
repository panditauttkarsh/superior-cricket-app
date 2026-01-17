-- Quick Setup: MVP Tables for Superior Cricket App
-- Copy and paste this entire file into Supabase SQL Editor

-- 1. Create player_mvp table
CREATE TABLE IF NOT EXISTS player_mvp (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player_id UUID NOT NULL,
  player_name TEXT NOT NULL,
  player_avatar TEXT,
  match_id UUID NOT NULL,
  team_id UUID NOT NULL,
  team_name TEXT NOT NULL,
  
  -- MVP Scores
  batting_mvp DECIMAL(10, 2) DEFAULT 0 NOT NULL,
  bowling_mvp DECIMAL(10, 2) DEFAULT 0 NOT NULL,
  fielding_mvp DECIMAL(10, 2) DEFAULT 0 NOT NULL,
  total_mvp DECIMAL(10, 2) DEFAULT 0 NOT NULL,
  
  -- Performance Stats
  runs_scored INTEGER DEFAULT 0 NOT NULL,
  balls_faced INTEGER DEFAULT 0 NOT NULL,
  wickets_taken INTEGER DEFAULT 0 NOT NULL,
  runs_conceded INTEGER DEFAULT 0 NOT NULL,
  balls_bowled INTEGER DEFAULT 0 NOT NULL,
  catches INTEGER DEFAULT 0 NOT NULL,
  run_outs INTEGER DEFAULT 0 NOT NULL,
  stumpings INTEGER DEFAULT 0 NOT NULL,
  
  -- Additional Info
  batting_order INTEGER NOT NULL,
  strike_rate DECIMAL(10, 2),
  bowling_economy DECIMAL(10, 2),
  performance_grade VARCHAR(50) NOT NULL,
  is_player_of_the_match BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  calculated_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(player_id, match_id)
);

-- 2. Create indexes
CREATE INDEX IF NOT EXISTS idx_player_mvp_match ON player_mvp(match_id);
CREATE INDEX IF NOT EXISTS idx_player_mvp_player ON player_mvp(player_id);
CREATE INDEX IF NOT EXISTS idx_player_mvp_total_desc ON player_mvp(total_mvp DESC);
CREATE INDEX IF NOT EXISTS idx_player_mvp_potm ON player_mvp(is_player_of_the_match) WHERE is_player_of_the_match = TRUE;

-- 3. Enable RLS
ALTER TABLE player_mvp ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
CREATE POLICY "Allow read access to all authenticated users"
ON player_mvp FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow insert for authenticated users"
ON player_mvp FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow update for authenticated users"
ON player_mvp FOR UPDATE
TO authenticated
USING (true);

-- 5. Create views for leaderboards
CREATE OR REPLACE VIEW tournament_mvp_leaderboard AS
SELECT 
  pm.player_id,
  pm.player_name,
  pm.player_avatar,
  pm.team_id,
  pm.team_name,
  m.tournament_id,
  COUNT(pm.id) as matches_played,
  SUM(pm.total_mvp) as total_mvp_points,
  AVG(pm.total_mvp) as avg_mvp_per_match,
  SUM(pm.batting_mvp) as total_batting_mvp,
  SUM(pm.bowling_mvp) as total_bowling_mvp,
  SUM(pm.fielding_mvp) as total_fielding_mvp,
  COUNT(CASE WHEN pm.is_player_of_the_match THEN 1 END) as potm_count,
  MAX(pm.total_mvp) as best_mvp_score,
  SUM(pm.runs_scored) as total_runs,
  SUM(pm.wickets_taken) as total_wickets,
  SUM(pm.catches) as total_catches
FROM player_mvp pm
JOIN matches m ON pm.match_id = m.id
WHERE m.tournament_id IS NOT NULL
GROUP BY 
  pm.player_id,
  pm.player_name,
  pm.player_avatar,
  pm.team_id,
  pm.team_name,
  m.tournament_id;

CREATE OR REPLACE VIEW player_mvp_stats AS
SELECT 
  player_id,
  player_name,
  player_avatar,
  COUNT(id) as total_matches,
  SUM(total_mvp) as total_mvp_points,
  AVG(total_mvp) as avg_mvp_per_match,
  MAX(total_mvp) as best_mvp_score,
  COUNT(CASE WHEN is_player_of_the_match THEN 1 END) as potm_count,
  SUM(runs_scored) as total_runs,
  SUM(wickets_taken) as total_wickets,
  SUM(catches) as total_catches,
  SUM(run_outs) as total_run_outs,
  SUM(stumpings) as total_stumpings
FROM player_mvp
GROUP BY player_id, player_name, player_avatar;

-- 6. Create function to update Player of the Match
CREATE OR REPLACE FUNCTION update_player_of_the_match(match_uuid UUID)
RETURNS VOID AS $$
DECLARE
  winning_team UUID;
  potm_player UUID;
BEGIN
  -- Get winning team
  SELECT winner_id INTO winning_team FROM matches WHERE id = match_uuid;
  
  -- Reset all POTM flags for this match
  UPDATE player_mvp 
  SET is_player_of_the_match = FALSE 
  WHERE match_id = match_uuid;
  
  -- Find POTM (winning team player in top 3, or highest scorer)
  SELECT player_id INTO potm_player
  FROM player_mvp
  WHERE match_id = match_uuid
    AND (team_id = winning_team OR player_id IN (
      SELECT player_id FROM player_mvp 
      WHERE match_id = match_uuid 
      ORDER BY total_mvp DESC 
      LIMIT 3
    ))
  ORDER BY 
    CASE WHEN team_id = winning_team THEN 0 ELSE 1 END,
    total_mvp DESC
  LIMIT 1;
  
  -- Set POTM flag
  IF potm_player IS NOT NULL THEN
    UPDATE player_mvp 
    SET is_player_of_the_match = TRUE 
    WHERE match_id = match_uuid AND player_id = potm_player;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. Success message
DO $$
BEGIN
  RAISE NOTICE '✅ MVP tables created successfully!';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '✅ RLS policies enabled';
  RAISE NOTICE '✅ Views created';
  RAISE NOTICE '✅ Functions created';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 MVP System is ready to use!';
END $$;
