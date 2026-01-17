# MVP Integration - Current Status

## ⚠️ **Current Issue: Player ID Mapping**

### **Problem:**
The MVP system is calculating correctly, but **cannot save to database** because:
- The scorecard uses **player names** (e.g., "Virat Kohli")
- The database expects **player UUIDs** (e.g., "123e4567-e89b-12d3-a456-426614174000")

### **Error:**
```
❌ Error calculating MVP: PostgrestException
message: invalid input syntax for type uuid: "Virat Kohli"
```

---

## ✅ **What's Working:**

1. ✅ **MVP Calculation** - Correctly calculates batting, bowling, fielding MVP
2. ✅ **Console Logs** - Shows all player MVP scores:
   ```
   🏆 Starting MVP calculation
   📊 Team 1: 52 runs in 15 balls
   📊 Team 2: 21 runs in 7 balls
   ✅ Virat Kohli: 2.18 MVP (B: 2.2, Bo: 0.0, F: 0.0)
   ✅ Virat K.: 4.82 MVP (B: 0.0, Bo: 4.8, F: 0.0)
   👑 Player of the Match: Virat K.
   ```
3. ✅ **Match Completion** - Match ends successfully without errors

---

## ❌ **What's Not Working:**

1. ❌ **Database Save** - Cannot save MVP data (player ID mismatch)
2. ❌ **MVP Display** - Shows "MVP data not available" (no data in database)
3. ❌ **POTM Selection** - Cannot determine from database

---

## 🔧 **Solutions:**

### **Option 1: Map Player Names to IDs** (Recommended)
Before saving MVP data, look up each player's UUID from the database:

```dart
// For each player name
final playerRecord = await supabase
    .from('players')
    .select('id')
    .eq('name', playerName)
    .single();

final playerId = playerRecord['id'];
```

**Pros:** ✅ Works with existing database schema  
**Cons:** ❌ Requires extra database queries

### **Option 2: Change Database Schema**
Modify `player_mvp` table to use `player_name` (TEXT) instead of `player_id` (UUID):

```sql
ALTER TABLE player_mvp 
DROP COLUMN player_id,
ADD COLUMN player_name TEXT NOT NULL;
```

**Pros:** ✅ Simple, no lookups needed  
**Cons:** ❌ Less normalized, harder to link to player profiles

### **Option 3: Store MVP in Match Data**
Save MVP data as JSON in the match record instead of separate table:

```dart
await matchRepo.updateMatch(matchId, {
  'mvp_data': jsonEncode(allMvpData),
});
```

**Pros:** ✅ Quick fix, no schema changes  
**Cons:** ❌ Can't query/filter by MVP, less flexible

---

## 📋 **Current Workaround:**

MVP calculation runs but **doesn't save to database**. The console shows:
```
💾 Calculated 5 player MVP records (not saved - need player UUIDs)
👑 Player of the Match: Virat K.
```

Match result screen shows:
```
ℹ️ MVP data not available
Player statistics will be calculated automatically in future matches
```

---

## 🎯 **Recommended Next Step:**

**Implement Option 1** - Add player name-to-ID mapping:

1. Create a helper function to get player ID from name
2. Call it for each player before creating `PlayerMvpModel`
3. Use the UUID in the model instead of the name
4. Save to database successfully
5. MVP display will work!

---

**Status:** MVP calculation works, but needs player ID mapping to save/display results.
