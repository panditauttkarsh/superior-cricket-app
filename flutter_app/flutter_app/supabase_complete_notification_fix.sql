-- COMPLETE NOTIFICATION FIX
-- This script fixes all notification issues including self-notification prevention
-- Run this in Supabase SQL Editor

-- ============================================================================
-- STEP 1: VERIFY TABLES EXIST
-- ============================================================================
SELECT 
  'match_players' as table_name,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'match_players') as exists
UNION ALL
SELECT 
  'notifications' as table_name,
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') as exists;

-- ============================================================================
-- STEP 2: VERIFY RLS POLICIES FOR match_players
-- ============================================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'match_players'
ORDER BY policyname;

-- ============================================================================
-- STEP 3: VERIFY RLS POLICIES FOR notifications
-- ============================================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'notifications'
ORDER BY policyname;

-- ============================================================================
-- STEP 4: DROP EXISTING TRIGGER AND FUNCTION
-- ============================================================================
DROP TRIGGER IF EXISTS on_player_added_to_match ON public.match_players;
DROP FUNCTION IF EXISTS public.notify_player_added_to_match();

-- ============================================================================
-- STEP 5: CREATE COMPLETE TRIGGER FUNCTION WITH SELF-NOTIFICATION CHECK
-- ============================================================================
CREATE OR REPLACE FUNCTION public.notify_player_added_to_match()
RETURNS TRIGGER AS $$
DECLARE
  match_data RECORD;
  team_name TEXT;
  v_user_id UUID;
  v_match_id UUID;
  v_added_by UUID;
BEGIN
  -- Store values for logging
  v_user_id := NEW.player_id;
  v_match_id := NEW.match_id;
  v_added_by := NEW.added_by;
  
  -- ========================================================================
  -- CRITICAL: PREVENT SELF-NOTIFICATIONS
  -- ========================================================================
  -- If player adds themselves, skip notification
  IF v_user_id = v_added_by THEN
    RAISE WARNING 'NOTIFICATION_SKIP: Player % added themselves, skipping notification', v_user_id;
    RETURN NEW; -- Allow the insert, but don't create notification
  END IF;
  
  -- Also skip if added_by is NULL (shouldn't happen, but be safe)
  IF v_added_by IS NULL THEN
    RAISE WARNING 'NOTIFICATION_SKIP: added_by is NULL for player % in match %, skipping notification', v_user_id, v_match_id;
    RETURN NEW;
  END IF;
  
  -- Log that trigger fired
  RAISE WARNING 'NOTIFICATION_TRIGGER: Fired for player % in match % (added by %)', v_user_id, v_match_id, v_added_by;
  
  -- ========================================================================
  -- GET MATCH INFORMATION
  -- ========================================================================
  BEGIN
    SELECT m.id, m.team1_name, m.team2_name, m.status, m.scheduled_at, m.created_by
    INTO STRICT match_data
    FROM public.matches m
    WHERE m.id = v_match_id;
    
    RAISE WARNING 'NOTIFICATION_TRIGGER: Match found - Team1: %, Team2: %, Created by: %', 
      match_data.team1_name, match_data.team2_name, match_data.created_by;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Match % not found for player %', v_match_id, v_user_id;
      RETURN NEW; -- Don't fail the insert
    WHEN OTHERS THEN
      RAISE WARNING 'NOTIFICATION_ERROR: Failed to fetch match %: %', v_match_id, SQLERRM;
      RETURN NEW; -- Don't fail the insert
  END;
  
  -- ========================================================================
  -- DETERMINE TEAM NAME
  -- ========================================================================
  IF NEW.team_type = 'team1' THEN
    team_name := COALESCE(match_data.team1_name, 'Your Team');
  ELSE
    team_name := COALESCE(match_data.team2_name, 'Opponent Team');
  END IF;
  
  RAISE WARNING 'NOTIFICATION_TRIGGER: Team name determined: % (team_type: %)', team_name, NEW.team_type;
  
  -- ========================================================================
  -- INSERT NOTIFICATION
  -- ========================================================================
  BEGIN
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      action_url,
      metadata
    ) VALUES (
      v_user_id, -- Notification goes to the player who was added
      'team_added',
      'Added to Team',
      format('You have been added to %s for a match. Tap to view match details.', team_name),
      format('/match/%s', v_match_id),
      jsonb_build_object(
        'match_id', v_match_id,
        'team_name', team_name,
        'team_type', NEW.team_type,
        'added_by', v_added_by,
        'match_created_by', match_data.created_by
      )
    );
    
    RAISE WARNING 'NOTIFICATION_SUCCESS: Created notification for user % in match % (added by %)', 
      v_user_id, v_match_id, v_added_by;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log detailed error information
      RAISE WARNING 'NOTIFICATION_ERROR: Could not create notification for user % in match %: % (SQLSTATE: %)', 
        v_user_id, v_match_id, SQLERRM, SQLSTATE;
      RAISE WARNING 'NOTIFICATION_ERROR: Error context: %', SQLCONTEXT;
      -- Don't fail the match_players insert - allow it to succeed
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- STEP 6: CREATE TRIGGER
-- ============================================================================
CREATE TRIGGER on_player_added_to_match
  AFTER INSERT ON public.match_players
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_player_added_to_match();

-- ============================================================================
-- STEP 7: EXPLICITLY ENABLE TRIGGER
-- ============================================================================
ALTER TABLE public.match_players ENABLE TRIGGER on_player_added_to_match;

-- ============================================================================
-- STEP 8: VERIFY TRIGGER STATUS
-- ============================================================================
SELECT 
  tgname as trigger_name,
  tgenabled as enabled_code,
  CASE tgenabled
    WHEN 'O' THEN '✓ ENABLED (origin)'
    WHEN 'D' THEN '✗ DISABLED - RUN: ALTER TABLE public.match_players ENABLE TRIGGER on_player_added_to_match;'
    WHEN 'R' THEN '✓ ENABLED (replica)'
    WHEN 'A' THEN '✓ ENABLED (always)'
    ELSE 'UNKNOWN'
  END as enabled_status,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_player_added_to_match';

-- ============================================================================
-- STEP 9: VERIFY FUNCTION EXISTS AND IS CORRECT
-- ============================================================================
SELECT 
  proname as function_name,
  prosrc as function_source
FROM pg_proc
WHERE proname = 'notify_player_added_to_match';

-- ============================================================================
-- STEP 10: CHECK RECENT match_players ENTRIES
-- ============================================================================
SELECT 
  mp.id,
  mp.match_id,
  mp.player_id,
  mp.added_by,
  mp.team_type,
  mp.added_at,
  m.team1_name,
  m.team2_name,
  m.created_by as match_created_by,
  CASE 
    WHEN mp.player_id = mp.added_by THEN '⚠️ SELF-ADDED (notification skipped)'
    WHEN mp.added_by IS NULL THEN '⚠️ NO ADDED_BY (notification skipped)'
    ELSE '✓ Should have notification'
  END as notification_status,
  (SELECT COUNT(*) 
   FROM public.notifications n 
   WHERE n.user_id = mp.player_id 
   AND n.type = 'team_added' 
   AND n.created_at >= mp.added_at - INTERVAL '5 minutes'
   AND n.created_at <= mp.added_at + INTERVAL '5 minutes'
  ) as notification_count
FROM public.match_players mp
LEFT JOIN public.matches m ON m.id = mp.match_id
ORDER BY mp.added_at DESC
LIMIT 10;

-- ============================================================================
-- STEP 11: CHECK RECENT NOTIFICATIONS
-- ============================================================================
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  created_at,
  metadata->>'added_by' as added_by_from_metadata,
  metadata->>'match_id' as match_id_from_metadata
FROM public.notifications
WHERE type = 'team_added'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- STEP 12: VERIFY RLS ALLOWS TRIGGER FUNCTION TO INSERT
-- ============================================================================
-- The function uses SECURITY DEFINER, so it runs with the privileges of the function owner
-- This should bypass RLS, but let's verify the policy exists
SELECT 
  'RLS Policy Check' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE tablename = 'notifications' 
      AND cmd = 'INSERT' 
      AND (with_check = 'true' OR with_check LIKE '%true%')
    ) THEN '✓ INSERT policy exists'
    ELSE '✗ No INSERT policy found'
  END as status;

-- ============================================================================
-- STEP 13: TEST QUERY - Check if we can manually insert a notification
-- ============================================================================
-- This is just a test to verify the function can insert
-- Don't actually run this, it's just for reference:
/*
DO $$
DECLARE
  test_user_id UUID := (SELECT id FROM auth.users LIMIT 1);
BEGIN
  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    action_url,
    metadata
  ) VALUES (
    test_user_id,
    'team_added',
    'Test Notification',
    'This is a test notification',
    '/test',
    jsonb_build_object('test', true)
  );
  RAISE NOTICE 'Test notification inserted successfully';
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to insert test notification: %', SQLERRM;
END $$;
*/

