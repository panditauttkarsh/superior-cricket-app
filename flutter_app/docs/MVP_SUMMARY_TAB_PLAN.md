# Enhancement 1: Show MVP in Summary Tab - Implementation Plan

## 🎯 **Objective:**
Display MVP details in the Match Details → Summary tab after the match ends.

## 📊 **Current Status:**
- ✅ MVP calculation working
- ✅ MVP data saved to database
- ✅ MVP shows on result screen
- ❌ MVP NOT showing in Summary tab during/after match

## 🔍 **Where to Add MVP:**

The user sees a "Summary" tab when viewing match details. We need to add an MVP section there that shows:

1. **Top 3 Performers** with their MVP scores
2. **Player of the Match** highlighted
3. **Breakdown** of Batting, Bowling, Fielding MVP

## 📝 **Implementation Steps:**

### **Step 1: Fetch MVP Data**
Add a function to fetch MVP data for the current match:

```dart
Future<List<PlayerMvpModel>> _fetchMatchMvp() async {
  if (widget.matchId == null) return [];
  
  try {
    final mvpRepo = ref.read(mvpRepositoryProvider);
    final mvpData = await mvpRepo.getMatchMvpData(widget.matchId!);
    return mvpData;
  } catch (e) {
    debugPrint('Error fetching MVP: $e');
    return [];
  }
}
```

### **Step 2: Create MVP Display Widget**
Add a widget to display MVP in the summary:

```dart
Widget _buildMvpSection(List<PlayerMvpModel> mvpData) {
  if (mvpData.isEmpty) {
    return const SizedBox.shrink();
  }
  
  // Get top 3 performers
  final topPerformers = mvpData.take(3).toList();
  final potm = mvpData.firstWhere(
    (p) => p.isPlayerOfTheMatch == true,
    orElse: () => mvpData.first,
  );
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      const Text(
        '🏆 Top Performers',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      const SizedBox(height: 12),
      
      // Player of the Match
      _buildPotmCard(potm),
      
      const SizedBox(height: 16),
      
      // Top 3 performers
      ...topPerformers.map((player) => _buildMvpCard(player)),
    ],
  );
}

Widget _buildPotmCard(PlayerMvpModel player) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.2),
          AppColors.accent.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary, width: 2),
    ),
    child: Row(
      children: [
        const Icon(Icons.emoji_events, color: AppColors.primary, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Player of the Match',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMeta,
                ),
              ),
              Text(
                player.playerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                'MVP: ${player.totalMvp.toStringAsFixed(2)} (B: ${player.battingMvp.toStringAsFixed(1)}, Bo: ${player.bowlingMvp.toStringAsFixed(1)}, F: ${player.fieldingMvp.toStringAsFixed(1)})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSec,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMvpCard(PlayerMvpModel player) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            player.playerName[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.playerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                'MVP: ${player.totalMvp.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSec,
                ),
              ),
            ],
          ),
        ),
        Text(
          player.performanceGrade,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _getGradeColor(player.performanceGrade),
          ),
        ),
      ],
    ),
  );
}

Color _getGradeColor(String grade) {
  switch (grade) {
    case 'S': return const Color(0xFFFFD700); // Gold
    case 'A': return const Color(0xFF00D9FF); // Cyan
    case 'B': return const Color(0xFF00FF88); // Green
    case 'C': return const Color(0xFFFFA500); // Orange
    default: return AppColors.textMeta;
  }
}
```

### **Step 3: Add to Summary Tab**
Find where the summary content is displayed and add the MVP section at the bottom.

## 🎯 **Expected Result:**

When user views match summary, they'll see:

```
Summary Tab:
├── Match Score
├── Batting Stats
├── Bowling Stats
└── 🏆 Top Performers (NEW!)
    ├── 👑 Player of the Match: Virat Kohli (MVP: 8.5)
    ├── 2. Rohit Sharma (MVP: 6.8)
    └── 3. MS Dhoni (MVP: 5.2)
```

---

## ⏱️ **Status:**
Ready to implement! This will make MVP visible during and after the match in the summary tab.

**Shall I proceed with the implementation?** 🚀
