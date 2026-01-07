-- Check commentary entries for a specific match
-- Replace 'YOUR_MATCH_ID' with your actual match ID

-- View all commentary entries
SELECT 
  id,
  match_id,
  over,
  ball_type,
  runs,
  commentary_text,
  striker_name,
  bowler_name,
  timestamp,
  created_at
FROM public.commentary
WHERE match_id = 'YOUR_MATCH_ID'  -- Replace with your match ID
ORDER BY over DESC, timestamp DESC;

-- Count entries per match
SELECT 
  match_id,
  COUNT(*) as total_entries,
  MIN(timestamp) as first_entry,
  MAX(timestamp) as last_entry
FROM public.commentary
GROUP BY match_id;

-- Check RLS policies are working
-- This should return all entries if RLS is configured correctly
SELECT COUNT(*) as total_commentary_entries FROM public.commentary;

-- Check if realtime is enabled (run in Supabase dashboard)
-- Go to Database > Replication > Enable for 'commentary' table

