# Notification System Implementation

## Overview
When a player is added to a match team, they receive a notification. When they log in, they can see:
- The notification
- Team info
- Match info
- All match-related details

## Database Schema

### 1. Run SQL Migration
Execute `supabase_notifications_schema.sql` in Supabase SQL Editor. This creates:
- `match_players` table - Tracks which players are in which matches
- `notifications` table - Stores in-app notifications
- Database trigger - Automatically creates notification when player is added

### 2. Tables Created

#### `match_players`
- `id` - Primary key
- `match_id` - References matches table
- `player_id` - References auth.users (the player's user ID)
- `team_type` - 'team1' or 'team2'
- `role` - Player role (batsman, bowler, etc.)
- `is_captain`, `is_wicket_keeper` - Boolean flags
- `added_by` - Who added this player
- `added_at` - Timestamp

#### `notifications`
- `id` - Primary key
- `user_id` - Who receives the notification
- `type` - 'team_added', 'match_invite', etc.
- `title`, `message` - Notification content
- `is_read` - Read status
- `action_url` - Deep link to match/team screen
- `metadata` - Additional data (match_id, team_name, etc.)

## Automatic Notification Creation

The database trigger `on_player_added_to_match` automatically creates a notification when a player is added to `match_players`:

```sql
-- Trigger fires when INSERT happens on match_players
-- Creates notification with:
-- Title: "Added to Team"
-- Message: "You have been added to {Team Name} for a match. Tap to view match details."
-- Action URL: "/match/{matchId}"
```

## Implementation Status

### ✅ Completed
1. Database schema (`supabase_notifications_schema.sql`)
2. Notification model (`lib/core/models/notification_model.dart`)
3. Notification repository (`lib/core/repositories/notification_repository.dart`)
4. Match player repository (`lib/core/repositories/match_player_repository.dart`)
5. Providers added to `repository_providers.dart`
6. Match creation flow updated to save players

### 🔄 In Progress
1. Update squad pages to return full player data (with IDs) instead of just names
2. Create notification UI screen
3. Add notification badge to app bar
4. Create match detail screen that players can access from notifications

## Next Steps

### 1. Update Squad Pages Return Type
Currently, squad pages return `List<String>` (just names). Need to return `List<Map<String, dynamic>>` with full player data including IDs.

**Files to update:**
- `lib/features/mycricket/presentation/pages/my_team_squad_page.dart`
- `lib/features/mycricket/presentation/pages/opponent_team_squad_page.dart`
- `lib/features/mycricket/presentation/pages/create_match_page.dart`

### 2. Create Notification UI
- Notification list screen
- Notification badge component
- Mark as read functionality
- Deep linking to matches

### 3. Create Match Detail Screen
- Show match info
- Show team info
- Show player list
- Show match status

## Testing

1. Run `supabase_notifications_schema.sql` in Supabase
2. Create a match and add players
3. Check `notifications` table - should see notifications created
4. Log in as the added player
5. Should see notification in app
6. Tap notification - should navigate to match details

## Files Created/Modified

**New Files:**
- `supabase_notifications_schema.sql`
- `lib/core/models/notification_model.dart`
- `lib/core/repositories/notification_repository.dart`
- `lib/core/repositories/match_player_repository.dart`

**Modified Files:**
- `lib/core/providers/repository_providers.dart`
- `lib/features/mycricket/presentation/pages/create_match_page.dart`

