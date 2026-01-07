# Testing Notification System

## Prerequisites

1. **Run SQL Migration First:**
   - Open Supabase Dashboard → SQL Editor
   - Run `supabase_notifications_schema.sql` (the fixed version)
   - Verify tables are created: `match_players` and `notifications`

2. **Ensure Users Have Profiles:**
   - Make sure both users (the one creating match and the one being added) have profiles with usernames
   - If usernames are NULL, run `supabase_fix_null_usernames.sql`

## Testing Steps

### Step 1: Create a Match and Add Players

1. **Login as User 1** (Match Creator):
   - Open the app
   - Go to "My Cricket" → "Create Match"
   - Fill in match details:
     - My Team Name: e.g., "Brave Hearts"
     - Opponent Team Name: e.g., "Royal Strikers"
     - Select overs, ground type, ball type
   - Click "Next" to go to squad selection

2. **Add Players to My Team:**
   - Tap "Add New Player"
   - Enter username: `@uttkarshpandita` (or the actual username)
   - Enter role (optional): e.g., "Batsman"
   - Tap "Add"
   - Repeat for more players if needed
   - Tap the checkmark (✓) to save squad

3. **Add Players to Opponent Team:**
   - Similar process for opponent team
   - Add at least one player

4. **Complete Match Creation:**
   - Continue through match settings
   - Complete toss (if applicable)
   - Match will be created in Supabase

### Step 2: Verify Notification Created

1. **Check Supabase Database:**
   - Open Supabase Dashboard → Table Editor
   - Go to `notifications` table
   - You should see a new notification with:
     - `type`: 'team_added'
     - `title`: 'Added to Team'
     - `message`: 'You have been added to {Team Name} for a match...'
     - `user_id`: The ID of the player who was added
     - `is_read`: false

2. **Check match_players Table:**
   - Go to `match_players` table
   - Verify entries exist with:
     - `match_id`: The match ID
     - `player_id`: The added player's user ID
     - `team_type`: 'team1' or 'team2'

### Step 3: Test as Added Player

1. **Login as User 2** (The player who was added):
   - Logout from User 1
   - Login with the account that was added (e.g., uttkarshpandita@gmail.com)

2. **Check for Notification:**
   - The notification should appear (once we implement the UI)
   - For now, check Supabase `notifications` table to confirm it exists

3. **Verify Match Access:**
   - The player should be able to see the match they were added to
   - They should see team info, match details, etc.

## Current Status

### ✅ What Works Now:
- Database schema is created
- Trigger automatically creates notifications when players are added
- Match players are saved to database
- Notifications are stored in database

### 🔄 What Needs Implementation:
- **Notification UI Screen** - To display notifications in the app
- **Notification Badge** - To show unread count in app bar
- **Match Detail Screen** - For players to view match info from notification
- **Real-time Updates** - To show notifications instantly when they arrive

## Quick Test (Database Only)

If you want to test the trigger manually:

```sql
-- Insert a test player to a match (replace with actual IDs)
INSERT INTO public.match_players (
  match_id,
  player_id,
  team_type,
  role,
  added_by
) VALUES (
  'YOUR_MATCH_ID',
  'YOUR_PLAYER_USER_ID',
  'team1',
  'Batsman',
  'YOUR_USER_ID'
);

-- Check if notification was created
SELECT * FROM public.notifications 
WHERE user_id = 'YOUR_PLAYER_USER_ID' 
ORDER BY created_at DESC 
LIMIT 1;
```

## Expected Behavior

1. **When player is added:**
   - Notification is automatically created ✅
   - Notification has correct team name ✅
   - Notification has action URL to match ✅

2. **When player logs in:**
   - Should see notification (once UI is implemented)
   - Can tap notification to view match
   - Can see all match-related info

## Troubleshooting

### Notification Not Created?
- Check if trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'on_player_added_to_match';`
- Check trigger function: `SELECT * FROM pg_proc WHERE proname = 'notify_player_added_to_match';`
- Check match_players table for the entry
- Check Supabase logs for errors

### Player Not Found?
- Ensure player has a profile with username
- Check if username is NULL in profiles table
- Run `supabase_fix_null_usernames.sql` if needed

### RLS Policy Blocking?
- Check RLS policies: `SELECT * FROM pg_policies WHERE tablename = 'match_players';`
- Ensure user is authenticated
- Check if user has permission to insert

## Next Steps for Full Implementation

1. Create notification list screen
2. Add notification badge to app bar
3. Implement real-time notification updates
4. Create match detail screen
5. Add deep linking from notifications to matches

