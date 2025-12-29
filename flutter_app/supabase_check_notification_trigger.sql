-- Check if notification trigger is working
-- Run this in Supabase SQL Editor to test

-- 1. Check if trigger exists
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table, 
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_player_added_to_match';

-- 2. Check if function exists
SELECT 
  routine_name, 
  routine_type, 
  security_type
FROM information_schema.routines
WHERE routine_name = 'notify_player_added_to_match';

-- 3. Test inserting a player (replace with actual match_id and player_id)
-- This should create a notification
-- INSERT INTO public.match_players (match_id, player_id, team_type)
-- VALUES ('YOUR_MATCH_ID', 'YOUR_PLAYER_ID', 'team1');

-- 4. Check if notification was created
-- SELECT * FROM public.notifications 
-- WHERE user_id = 'YOUR_PLAYER_ID' 
-- ORDER BY created_at DESC 
-- LIMIT 5;

-- 5. Check RLS policies on notifications table
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check
FROM pg_policies
WHERE tablename = 'notifications';

