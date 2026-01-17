# MVP System - Complete Testing Guide

## 🎯 Overview
This guide will help you test the MVP (Most Valuable Player) system end-to-end in your Superior Cricket App.

## 📋 Prerequisites

### 1. Database Setup
First, run the SQL migration to create the MVP tables:

```bash
# Navigate to your Supabase dashboard
# Go to SQL Editor
# Copy and paste the contents of:
# flutter_app/supabase/migrations/create_mvp_tables.sql
# Execute the SQL
```

**Verify Tables Created:**
```sql
-- Check if table exists
SELECT * FROM player_mvp LIMIT 1;

-- Check if views exist
SELECT * FROM tournament_mvp_leaderboard LIMIT 1;
SELECT * FROM player_mvp_stats LIMIT 1;
```

### 2. Hot Reload the App
```bash
# In your terminal where flutter run is active
# Press 'r' for hot reload
# Or 'R' for hot restart
```

## 🧪 Testing Steps

### Test 1: Calculate MVP for a Single Player

**Objective**: Verify batting MVP calculation

```dart
import 'package:superior_cricket_app/core/services/mvp_calculation_service.dart';

void testBattingMvp() {
  // Test Case: Opening batter scores 75 runs in 50 balls
  double mvp = MvpCalculationService.calculateBattingMvp(
    runsScored: 75,
    ballsFaced: 50,
    battingOrder: 1,
    teamTotalRuns: 180,
    teamTotalBalls: 120,
  );
  
  print('Batting MVP: ${MvpCalculationService.formatMvpPoints(mvp)}');
  print('Grade: ${MvpCalculationService.getPerformanceGrade(mvp)}');
  
  // Expected: ~7.5-8.5 MVP points (Very Good 🔥)
}
```

**How to Test:**
1. Create a test file: `test/mvp_calculation_test.dart`
2. Add the above code
3. Run: `flutter test test/mvp_calculation_test.dart`

**Expected Output:**
```
Batting MVP: 7.50-8.50
Grade: Very Good 🔥
```

---

### Test 2: Calculate Bowling MVP

**Objective**: Verify bowling MVP with wickets and maidens

```dart
void testBowlingMvp() {
  double mvp = MvpCalculationService.calculateBowlingMvp(
    wickets: [
      {'battingOrder': 1, 'dismissalType': 'bowled', 'runsScored': 15},
      {'battingOrder': 5, 'dismissalType': 'caught', 'runsScored': 10},
      {'battingOrder': 9, 'dismissalType': 'lbw', 'runsScored': 1},
    ],
    runsConceded: 30,
    ballsBowled: 24,
    maidenOvers: 1,
    teamTotalRuns: 180,
    teamTotalBalls: 120,
    totalOvers: 20,
  );
  
  print('Bowling MVP: ${MvpCalculationService.formatMvpPoints(mvp)}');
  print('Grade: ${MvpCalculationService.getPerformanceGrade(mvp)}');
  
  // Expected: ~3-4 MVP points (Average-Good)
}
```

---

### Test 3: Save MVP to Database

**Objective**: Test MVP repository save operation

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> testSaveMvp(WidgetRef ref) async {
  final mvpRepo = ref.read(mvpRepositoryProvider);
  
  final mvpData = PlayerMvpModel(
    playerId: 'test-player-1',
    playerName: 'Test Player',
    matchId: 'test-match-1',
    teamId: 'test-team-1',
    teamName: 'Test Team',
    battingMvp: 7.5,
    bowlingMvp: 3.2,
    fieldingMvp: 0.8,
    totalMvp: 11.5,
    runsScored: 75,
    ballsFaced: 50,
    wicketsTaken: 3,
    runsConceded: 30,
    ballsBowled: 24,
    catches: 2,
    runOuts: 0,
    stumpings: 0,
    battingOrder: 1,
    strikeRate: 150.0,
    bowlingEconomy: 7.5,
    performanceGrade: 'Excellent 💎',
    calculatedAt: DateTime.now(),
  );
  
  try {
    final saved = await mvpRepo.saveMvpData(mvpData);
    print('✅ MVP saved successfully: ${saved.playerName}');
    print('Total MVP: ${saved.formattedMvpScore}');
  } catch (e) {
    print('❌ Error saving MVP: $e');
  }
}
```

**How to Test:**
1. Add a test button in your app
2. Call `testSaveMvp(ref)` on button press
3. Check Supabase dashboard → `player_mvp` table

**Expected Result:**
- New row in `player_mvp` table
- All fields populated correctly
- `total_mvp` = 11.5

---

### Test 4: Display MVP Card

**Objective**: Test MVP UI component

**Steps:**
1. Navigate to match details page
2. Add MVP card widget:

```dart
import 'package:superior_cricket_app/features/match/presentation/widgets/mvp_award_card.dart';

// In your match details page
MvpAwardCard(
  mvpData: playerMvpModel,
  isPlayerOfTheMatch: true,
  onTap: () {
    // Navigate to detailed stats
    print('MVP card tapped');
  },
)
```

**Expected UI:**
- Gradient card with player info
- MVP score prominently displayed
- Performance breakdown bars (Batting, Bowling, Fielding)
- Player stats at bottom
- POTM badge if `isPlayerOfTheMatch = true`

---

### Test 5: Get Match MVP Data

**Objective**: Retrieve MVP data for a match

```dart
Future<void> testGetMatchMvp(WidgetRef ref, String matchId) async {
  final mvpRepo = ref.read(mvpRepositoryProvider);
  
  try {
    // Get all MVP data for match
    final mvpList = await mvpRepo.getMatchMvpData(matchId);
    print('📊 Found ${mvpList.length} players with MVP data');
    
    for (var mvp in mvpList) {
      print('${mvp.playerName}: ${mvp.formattedMvpScore} ${mvp.performanceEmoji}');
    }
    
    // Get Player of the Match
    final potm = await mvpRepo.getPlayerOfTheMatch(matchId);
    if (potm != null) {
      print('👑 POTM: ${potm.playerName} (${potm.formattedMvpScore})');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

### Test 6: Tournament MVP Leaderboard

**Objective**: Test tournament leaderboard

```dart
Future<void> testTournamentLeaderboard(WidgetRef ref, String tournamentId) async {
  final mvpRepo = ref.read(mvpRepositoryProvider);
  
  try {
    final leaderboard = await mvpRepo.getTournamentMvpLeaderboard(
      tournamentId,
      limit: 10,
    );
    
    print('🏆 TOURNAMENT MVP LEADERBOARD');
    print('=' * 50);
    
    for (int i = 0; i < leaderboard.length; i++) {
      final entry = leaderboard[i];
      print('${i + 1}. ${entry['player_name']}');
      print('   Total MVP: ${entry['total_mvp_points']}');
      print('   Matches: ${entry['matches_played']}');
      print('   POTM Awards: ${entry['potm_count']}');
      print('   Avg MVP: ${entry['avg_mvp_per_match']}');
      print('');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

### Test 7: Real-time MVP Updates

**Objective**: Test streaming MVP data

```dart
import 'package:flutter/material.dart';

class MvpStreamTest extends ConsumerWidget {
  final String matchId;
  
  const MvpStreamTest({required this.matchId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvpRepo = ref.read(mvpRepositoryProvider);
    
    return StreamBuilder<List<PlayerMvpModel>>(
      stream: mvpRepo.streamMatchMvpData(matchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final mvpList = snapshot.data!;
        
        return ListView.builder(
          itemCount: mvpList.length,
          itemBuilder: (context, index) {
            final mvp = mvpList[index];
            return MvpAwardCard(
              mvpData: mvp,
              isPlayerOfTheMatch: mvp.isPlayerOfTheMatch,
            );
          },
        );
      },
    );
  }
}
```

---

## 🔍 Integration Testing

### Full Match Flow Test

**Scenario**: Complete a match and calculate MVP

```dart
Future<void> testFullMatchMvpFlow(WidgetRef ref) async {
  final matchId = 'your-match-id';
  final mvpRepo = ref.read(mvpRepositoryProvider);
  
  print('🏏 Starting Full Match MVP Test');
  print('=' * 50);
  
  // Step 1: Create sample MVP data for all players
  final players = [
    {
      'id': 'player-1',
      'name': 'Virat Kohli',
      'teamId': 'team-1',
      'teamName': 'Team A',
      'batting': {'runs': 85, 'balls': 60, 'order': 3},
      'bowling': {'wickets': 0, 'runs': 0, 'balls': 0, 'maidens': 0},
      'fielding': {'catches': 2, 'runOuts': 0, 'stumpings': 0},
    },
    {
      'id': 'player-2',
      'name': 'Jasprit Bumrah',
      'teamId': 'team-1',
      'teamName': 'Team A',
      'batting': {'runs': 5, 'balls': 8, 'order': 11},
      'bowling': {
        'wickets': [
          {'battingOrder': 1, 'dismissalType': 'bowled', 'runsScored': 15},
          {'battingOrder': 3, 'dismissalType': 'caught', 'runsScored': 25},
          {'battingOrder': 5, 'dismissalType': 'lbw', 'runsScored': 10},
        ],
        'runs': 28,
        'balls': 24,
        'maidens': 2,
      },
      'fielding': {'catches': 0, 'runOuts': 1, 'stumpings': 0},
    },
  ];
  
  List<PlayerMvpModel> allMvpData = [];
  
  // Step 2: Calculate MVP for each player
  for (var player in players) {
    final battingMvp = MvpCalculationService.calculateBattingMvp(
      runsScored: player['batting']['runs'],
      ballsFaced: player['batting']['balls'],
      battingOrder: player['batting']['order'],
      teamTotalRuns: 180,
      teamTotalBalls: 120,
    );
    
    final bowlingMvp = MvpCalculationService.calculateBowlingMvp(
      wickets: player['bowling']['wickets'] ?? [],
      runsConceded: player['bowling']['runs'],
      ballsBowled: player['bowling']['balls'],
      maidenOvers: player['bowling']['maidens'],
      teamTotalRuns: 180,
      teamTotalBalls: 120,
      totalOvers: 20,
    );
    
    final fieldingMvp = MvpCalculationService.calculateFieldingMvp(
      assists: List.generate(
        player['fielding']['catches'],
        (_) => {'battingOrder': 3},
      ),
      runOuts: List.generate(
        player['fielding']['runOuts'],
        (_) => {'battingOrder': 5},
      ),
      totalOvers: 20,
    );
    
    final totalMvp = battingMvp + bowlingMvp + fieldingMvp;
    
    final mvpData = PlayerMvpModel(
      playerId: player['id'],
      playerName: player['name'],
      matchId: matchId,
      teamId: player['teamId'],
      teamName: player['teamName'],
      battingMvp: battingMvp,
      bowlingMvp: bowlingMvp,
      fieldingMvp: fieldingMvp,
      totalMvp: totalMvp,
      runsScored: player['batting']['runs'],
      ballsFaced: player['batting']['balls'],
      wicketsTaken: (player['bowling']['wickets'] as List?)?.length ?? 0,
      runsConceded: player['bowling']['runs'],
      ballsBowled: player['bowling']['balls'],
      catches: player['fielding']['catches'],
      runOuts: player['fielding']['runOuts'],
      stumpings: player['fielding']['stumpings'],
      battingOrder: player['batting']['order'],
      strikeRate: player['batting']['balls'] > 0
          ? (player['batting']['runs'] / player['batting']['balls']) * 100
          : null,
      performanceGrade: MvpCalculationService.getPerformanceGrade(totalMvp),
      calculatedAt: DateTime.now(),
    );
    
    allMvpData.add(mvpData);
    
    print('${player['name']}:');
    print('  Batting: ${battingMvp.toStringAsFixed(2)}');
    print('  Bowling: ${bowlingMvp.toStringAsFixed(2)}');
    print('  Fielding: ${fieldingMvp.toStringAsFixed(2)}');
    print('  Total: ${totalMvp.toStringAsFixed(2)} ${mvpData.performanceEmoji}');
    print('');
  }
  
  // Step 3: Save all MVP data
  try {
    await mvpRepo.saveBatchMvpData(allMvpData);
    print('✅ All MVP data saved');
  } catch (e) {
    print('❌ Error saving: $e');
    return;
  }
  
  // Step 4: Determine Player of the Match
  await mvpRepo.updatePlayerOfTheMatch(matchId);
  print('✅ Player of the Match updated');
  
  // Step 5: Retrieve and display results
  final potm = await mvpRepo.getPlayerOfTheMatch(matchId);
  if (potm != null) {
    print('');
    print('👑 PLAYER OF THE MATCH');
    print('=' * 50);
    print('${potm.playerName} (${potm.teamName})');
    print('MVP Score: ${potm.formattedMvpScore} ${potm.performanceEmoji}');
    print('Grade: ${potm.performanceGrade}');
  }
  
  print('');
  print('✅ Full Match MVP Test Complete!');
}
```

---

## 📱 UI Testing Checklist

### MVP Award Card
- [ ] Card displays with correct gradient
- [ ] Player avatar loads correctly
- [ ] MVP score is prominently displayed
- [ ] Performance grade shows correct emoji
- [ ] Breakdown bars animate smoothly
- [ ] Stats section shows all values
- [ ] POTM badge appears when applicable
- [ ] Tap gesture works

### Match Details Integration
- [ ] MVP section appears after match completion
- [ ] POTM card is highlighted
- [ ] Top performers list shows correctly
- [ ] Real-time updates work
- [ ] Loading states display properly
- [ ] Error states handled gracefully

### Tournament Leaderboard
- [ ] Leaderboard loads correctly
- [ ] Sorting works (by total MVP, POTM count, etc.)
- [ ] Player cards are clickable
- [ ] Pagination works (if implemented)
- [ ] Refresh functionality works

---

## 🐛 Common Issues & Solutions

### Issue 1: "Table player_mvp does not exist"
**Solution**: Run the SQL migration in Supabase dashboard

### Issue 2: "Failed to save MVP data"
**Solution**: Check RLS policies in Supabase. Ensure authenticated users can insert.

### Issue 3: MVP calculations seem incorrect
**Solution**: 
- Verify input data (runs, balls, wickets)
- Check team totals are correct
- Review match type (T20, ODI, Test)

### Issue 4: POTM not updating
**Solution**:
- Ensure `update_player_of_the_match` function exists in database
- Check winning team ID is correct
- Verify at least one player has MVP data

### Issue 5: Real-time updates not working
**Solution**:
- Check Supabase Realtime is enabled for `player_mvp` table
- Verify RLS policies allow SELECT
- Check network connection

---

## 📊 Performance Testing

### Load Test
Test with multiple players (11 per team = 22 total):

```dart
Future<void> loadTest(WidgetRef ref, String matchId) async {
  final stopwatch = Stopwatch()..start();
  
  // Generate 22 players
  List<PlayerMvpModel> players = List.generate(22, (i) {
    return PlayerMvpModel(
      playerId: 'player-$i',
      playerName: 'Player $i',
      matchId: matchId,
      teamId: i < 11 ? 'team-1' : 'team-2',
      teamName: i < 11 ? 'Team A' : 'Team B',
      battingMvp: (i * 0.5),
      bowlingMvp: (i * 0.3),
      fieldingMvp: (i * 0.2),
      totalMvp: (i * 1.0),
      runsScored: i * 5,
      ballsFaced: i * 4,
      wicketsTaken: i % 3,
      runsConceded: i * 6,
      ballsBowled: i * 4,
      catches: i % 2,
      runOuts: 0,
      stumpings: 0,
      battingOrder: (i % 11) + 1,
      performanceGrade: 'Good ⭐',
      calculatedAt: DateTime.now(),
    );
  });
  
  final mvpRepo = ref.read(mvpRepositoryProvider);
  await mvpRepo.saveBatchMvpData(players);
  
  stopwatch.stop();
  print('⏱️  Saved 22 players in ${stopwatch.elapsedMilliseconds}ms');
  
  // Expected: < 1000ms
}
```

---

## ✅ Final Verification

Before considering MVP system complete, verify:

1. **Database**
   - [ ] All tables created
   - [ ] Indexes working
   - [ ] Views returning data
   - [ ] Functions executing
   - [ ] RLS policies configured

2. **Backend**
   - [ ] MVP calculations accurate
   - [ ] Repository CRUD operations work
   - [ ] Real-time streaming functional
   - [ ] Error handling robust

3. **Frontend**
   - [ ] MVP cards display correctly
   - [ ] Animations smooth
   - [ ] Loading states present
   - [ ] Error messages clear

4. **Integration**
   - [ ] Match completion triggers MVP calculation
   - [ ] POTM determined correctly
   - [ ] Tournament leaderboard updates
   - [ ] Player profiles show MVP stats

---

## 🚀 Next Steps

After testing:
1. Add social sharing for MVP achievements
2. Create MVP badges/achievements system
3. Add MVP trends/analytics
4. Implement push notifications for POTM
5. Add MVP comparison features

---

**Happy Testing! 🏏**
