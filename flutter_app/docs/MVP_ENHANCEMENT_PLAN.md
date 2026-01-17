# 🏆 MVP Enhancement - Complete Implementation Plan

## 📋 **User Requirements:**

### **1. Tournament Matches - MVP in Summary Tab** ✅
- Add MVP section below summary in every tournament match
- Same as regular matches

### **2. MVP Tab in Match Details Slider** 🆕
- Add new "MVP" tab after "Commentary" tab
- Show ALL players with their stats:
  - Batting stats
  - Bowling stats
  - Fielding stats
  - Total MVP score
- Apply to BOTH tournament matches AND regular matches

### **3. Tournament Leaderboard** 🆕
- Add 3 tabs in tournament leaderboard:
  1. **MVP** - Overall best performers
  2. **Batting** - Best batsmen
  3. **Bowling** - Best bowlers
- Show ALL players across all matches in the tournament
- Ranked by performance

---

## 🎯 **Implementation Steps:**

### **Step 1: Add MVP Tab to Match Details** ⏱️ 30 mins

**File:** `match_detail_page_comprehensive.dart`

**Changes:**
1. Add "MVP" to the tab list (after Commentary)
2. Create `_buildMvpTab()` function
3. Display all players with their stats

**Code Location:** Around line 269 (where tabs are defined)

```dart
// Current tabs
Tab(text: 'Summary'),
Tab(text: 'Info'),
Tab(text: 'Squads'),
Tab(text: 'Scorecard'),
Tab(text: 'Commentary'),
Tab(text: 'MVP'), // NEW!
```

**New Function:**
```dart
Widget _buildMvpTab(MatchModel match) {
  return Consumer(
    builder: (context, ref, child) {
      final mvpAsync = ref.watch(matchMvpProvider(widget.matchId));
      
      return mvpAsync.when(
        data: (mvpData) {
          if (mvpData.isEmpty) {
            return Center(
              child: Text('MVP data not available'),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: mvpData.length,
            itemBuilder: (context, index) {
              final player = mvpData[index];
              return _buildPlayerMvpCard(player, index + 1);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('Error loading MVP data')),
      );
    },
  );
}

Widget _buildPlayerMvpCard(PlayerMvpModel player, int rank) {
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank and Name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppColors.primary : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Grade: ${player.performanceGrade}',
                      style: TextStyle(
                        color: _getGradeColor(player.performanceGrade),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                player.totalMvp.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 12),
          
          // Batting Stats
          Text(
            '🏏 Batting',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Runs', '${player.runsScored}'),
              _buildStatItem('Balls', '${player.ballsFaced}'),
              _buildStatItem('SR', player.strikeRate?.toStringAsFixed(1) ?? '-'),
              _buildStatItem('MVP', player.battingMvp.toStringAsFixed(1)),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Bowling Stats
          Text(
            '⚾ Bowling',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Wickets', '${player.wicketsTaken}'),
              _buildStatItem('Runs', '${player.runsConceded}'),
              _buildStatItem('Eco', player.economy?.toStringAsFixed(1) ?? '-'),
              _buildStatItem('MVP', player.bowlingMvp.toStringAsFixed(1)),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Fielding Stats
          Text(
            '🧤 Fielding',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Catches', '${player.catches}'),
              _buildStatItem('Run-outs', '${player.runOuts}'),
              _buildStatItem('Stumpings', '${player.stumpings}'),
              _buildStatItem('MVP', player.fieldingMvp.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatItem(String label, String value) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSec,
        ),
      ),
    ],
  );
}
```

---

### **Step 2: Add Tournament Leaderboard** ⏱️ 45 mins

**File:** Create new `tournament_leaderboard_page.dart`

**Features:**
- 3 tabs: MVP, Batting, Bowling
- Aggregate stats from all matches in tournament
- Rank players by performance

**Provider:**
```dart
final tournamentLeaderboardProvider = FutureProvider.autoDispose.family<
  Map<String, List<PlayerMvpModel>>, 
  String
>((ref, tournamentId) async {
  final mvpRepo = ref.watch(mvpRepositoryProvider);
  
  // Get all matches in tournament
  final matches = await getTournamentMatches(tournamentId);
  
  // Aggregate MVP data
  final allMvpData = <String, PlayerMvpModel>{};
  
  for (final match in matches) {
    final mvpData = await mvpRepo.getMatchMvpData(match.id);
    
    for (final player in mvpData) {
      if (allMvpData.containsKey(player.playerId)) {
        // Aggregate stats
        allMvpData[player.playerId] = _aggregatePlayerStats(
          allMvpData[player.playerId]!,
          player,
        );
      } else {
        allMvpData[player.playerId] = player;
      }
    }
  }
  
  final players = allMvpData.values.toList();
  
  return {
    'mvp': players..sort((a, b) => b.totalMvp.compareTo(a.totalMvp)),
    'batting': players..sort((a, b) => b.battingMvp.compareTo(a.battingMvp)),
    'bowling': players..sort((a, b) => b.bowlingMvp.compareTo(a.bowlingMvp)),
  };
});
```

---

### **Step 3: Update Tournament Match Details** ⏱️ 15 mins

**File:** Tournament match details page

**Changes:**
- Ensure MVP section appears in Summary tab
- Add MVP tab to slider
- Same functionality as regular matches

---

## 📊 **Summary:**

### **What Will Be Added:**

1. ✅ **MVP Tab in Match Details**
   - Shows ALL players
   - Complete stats (batting, bowling, fielding)
   - Works for both regular and tournament matches

2. ✅ **Tournament Leaderboard**
   - 3 tabs: MVP, Batting, Bowling
   - Aggregated stats across all matches
   - Ranked by performance

3. ✅ **Tournament Match Summary**
   - MVP section in Summary tab
   - Same as regular matches

---

## ⏱️ **Estimated Time:**
- MVP Tab: 30 minutes
- Tournament Leaderboard: 45 minutes
- Testing: 15 minutes
- **Total: ~1.5 hours**

---

## 🚀 **Next Steps:**

Would you like me to:
1. **Start with MVP Tab** (easiest, immediate impact)
2. **Start with Tournament Leaderboard** (more complex)
3. **Do both in sequence**

Which would you prefer? 🤔
