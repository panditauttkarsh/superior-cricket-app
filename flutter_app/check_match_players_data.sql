-- Check match_players data and verify player_ids exist in profiles
-- Run this in Supabase SQL Editor

-- Method 1: Check match_players records for a specific match
-- Replace 'YOUR_MATCH_ID' with an actual match ID
SELECT 
    mp.id,
    mp.match_id,
    mp.player_id,
    mp.team_type,
    mp.role,
    mp.is_captain,
    mp.is_wicket_keeper,
    mp.added_at,
    -- Check if profile exists
    CASE WHEN p.id IS NOT NULL THEN '✅ Profile exists' ELSE '❌ Profile missing' END as profile_status,
    p.username,
    p.full_name,
    p.email,
    p.avatar_url
FROM public.match_players mp
LEFT JOIN public.profiles p ON mp.player_id = p.id
ORDER BY mp.added_at DESC
LIMIT 20;

-- Method 2: Check all match_players and see which ones have profiles
SELECT 
    COUNT(*) as total_match_players,
    COUNT(p.id) as players_with_profiles,
    COUNT(*) - COUNT(p.id) as players_without_profiles
FROM public.match_players mp
LEFT JOIN public.profiles p ON mp.player_id = p.id;

-- Method 3: Find match_players without profiles (these will cause errors)
SELECT 
    mp.match_id,
    mp.player_id,
    mp.team_type,
    'Missing profile' as issue
FROM public.match_players mp
LEFT JOIN public.profiles p ON mp.player_id = p.id
WHERE p.id IS NULL;

