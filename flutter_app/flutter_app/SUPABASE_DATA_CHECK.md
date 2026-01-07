# How to Check Data in Supabase

## Accessing Supabase Dashboard

1. Go to: https://supabase.com/dashboard
2. Sign in with your account
3. Select your project: `nhiyuosjiiabxxwpkpdi`

## Viewing Your Data

### 1. Check Matches
- Go to **Table Editor** in the left sidebar
- Click on **`matches`** table
- You'll see all created matches with:
  - `team1_name` and `team2_name`
  - `overs`, `ground_type`, `ball_type`
  - `status` (upcoming, live, completed)
  - `created_at` timestamp
  - `scorecard` (JSON data)

### 2. Check Teams
- Go to **Table Editor**
- Click on **`teams`** table
- You'll see all teams with:
  - `name`
  - `player_ids` (array of UUIDs)
  - `created_by` (user ID)
  - `created_at` timestamp

### 3. Check Users/Profiles
- Go to **Table Editor**
- Click on **`profiles`** table
- You'll see user profiles with:
  - `email`, `name`
  - `role` (player, coach, admin, etc.)
  - `created_at` timestamp

### 4. Check Authentication Users
- Go to **Authentication** → **Users** in the left sidebar
- You'll see all registered users
- Check email verification status
- View user metadata

## Using SQL Editor (Advanced)

1. Go to **SQL Editor** in the left sidebar
2. Click **New Query**
3. Run queries like:

```sql
-- Get all matches
SELECT * FROM matches ORDER BY created_at DESC;

-- Get matches with team names
SELECT 
  id,
  team1_name,
  team2_name,
  overs,
  ground_type,
  ball_type,
  status,
  created_at
FROM matches
ORDER BY created_at DESC
LIMIT 10;

-- Get teams created by a specific user
SELECT * FROM teams 
WHERE created_by = 'YOUR_USER_ID_HERE'
ORDER BY created_at DESC;

-- Count matches by status
SELECT status, COUNT(*) as count
FROM matches
GROUP BY status;
```

## Quick Tips

- **Filter Data**: Use the filter icon in Table Editor to filter by columns
- **Sort Data**: Click column headers to sort
- **View JSON**: Click on JSONB columns (like `scorecard`) to view formatted JSON
- **Edit Data**: Click on any row to edit (if you have permissions)
- **Export Data**: Use the export button to download data as CSV

## Common Tables to Check

1. **`matches`** - All cricket matches
2. **`teams`** - All teams
3. **`profiles`** - User profiles
4. **`players`** - Player information
5. **`tournaments`** - Tournament data
6. **`posts`** - Social feed posts
7. **`shop_items`** - Store products

## Troubleshooting

- **No data showing?** Check if RLS (Row Level Security) policies allow you to view data
- **Can't insert?** Check if you're logged in and have proper permissions
- **Data not updating?** Check the app logs and Supabase logs in the Dashboard

