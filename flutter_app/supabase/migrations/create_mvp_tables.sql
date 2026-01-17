-- MVP (Most Valuable Player) System Database Schema
-- Superior Cricket App

-- =====================================================
-- 1. Player MVP Table
-- =====================================================
CREATE TABLE IF NOT EXISTS player_mvp (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player_id UUID NOT NULL,
  player_name TEXT NOT NULL,
  player_avatar TEXT,
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
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
  UNIQUE(player_id, match_id),
  CHECK (batting_mvp >= 0),
  CHECK (bowling_mvp >= 0),
  CHECK (fielding_mvp >= 0),
  CHECK (total_mvp >= 0)
);

-- =====================================================
-- 2. Indexes for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_player_mvp_match ON player_mvp(match_id);
CREATE INDEX IF NOT EXISTS idx_player_mvp_player ON player_mvp(player_id);
CREATE INDEX IF NOT EXISTS idx_player_mvp_total_desc ON player_mvp(total_mvp DESC);
CREATE INDEX IF NOT EXISTS idx_player_mvp_potm ON player_mvp(is_player_of_the_match) WHERE is_player_of_the_match = TRUE;
CREATE INDEX IF NOT EXISTS idx_player_mvp_team ON player_mvp(team_id);
CREATE INDEX IF NOT EXISTS idx_player_mvp_calculated_at ON player_mvp(calculated_at DESC);

-- =====================================================
-- 3. Tournament MVP Leaderboard View
-- =====================================================
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

-- =====================================================
-- 4. Player MVP Stats View (All Time)
-- =====================================================
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

-- =====================================================
-- 5. Function to Update Player of the Match
-- =====================================================
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

-- =====================================================
-- 6. Trigger to Auto-update timestamps
-- =====================================================
CREATE OR REPLACE FUNCTION update_player_mvp_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER player_mvp_update_timestamp
BEFORE UPDATE ON player_mvp
FOR EACH ROW
EXECUTE FUNCTION update_player_mvp_timestamp();

-- =====================================================
-- 7. RLS (Row Level Security) Policies
-- =====================================================
ALTER TABLE player_mvp ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read MVP data
CREATE POLICY "Allow read access to all authenticated users"
ON player_mvp FOR SELECT
TO authenticated
USING (true);

-- Allow insert for authenticated users (match scorers)
CREATE POLICY "Allow insert for authenticated users"
ON player_mvp FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow update for authenticated users (match scorers)
CREATE POLICY "Allow update for authenticated users"
ON player_mvp FOR UPDATE
TO authenticated
USING (true);

-- =====================================================
-- 8. Sample Data for Testing (Optional)
-- =====================================================
-- Uncomment to insert sample data
/*
INSERT INTO player_mvp (
  player_id, player_name, match_id, team_id, team_name,
  batting_mvp, bowling_mvp, fielding_mvp, total_mvp,
  runs_scored, balls_faced, wickets_taken, runs_conceded, balls_bowled,
  catches, run_outs, stumpings, batting_order,
  strike_rate, bowling_economy, performance_grade, is_player_of_the_match
) VALUES (
  'sample-player-1', 'Virat Kohli', 'sample-match-1', 'team-1', 'Royal Challengers',
  7.5, 0, 0.4, 7.9,
  75, 50, 0, 0, 0,
  2, 0, 0, 3,
  150.0, NULL, 'Very Good 🔥', TRUE
);
*/

-- =====================================================
-- 9. Helpful Queries for Testing
-- =====================================================

-- Get top 10 MVP performers (all time)
-- SELECT * FROM player_mvp_stats ORDER BY total_mvp_points DESC LIMIT 10;

-- Get tournament MVP leaderboard
-- SELECT * FROM tournament_mvp_leaderboard 
-- WHERE tournament_id = 'your-tournament-id' 
-- ORDER BY total_mvp_points DESC;

-- Get Player of the Match for a specific match
-- SELECT * FROM player_mvp WHERE match_id = 'your-match-id' AND is_player_of_the_match = TRUE;

-- Get player's MVP history
-- SELECT * FROM player_mvp WHERE player_id = 'your-player-id' ORDER BY calculated_at DESC;

COMMIT;
