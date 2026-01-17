# MVP Enhancement Plan

## ✅ Current Status
- MVP calculation working
- Players auto-created
- Saves to database
- Shows on result screen

---

## 🎯 Enhancement 1: Show MVP in Summary Tab

### **Location:**
Match Details page → Summary tab → Below batting/bowling stats

### **Implementation:**
1. Add MVP section in Summary tab
2. Fetch MVP data from database
3. Display top 3 performers with their scores
4. Show live MVP updates as match progresses

### **UI Design:**
```
Summary Tab:
├── Match Score
├── Batting Stats
├── Bowling Stats
└── 🏆 Top Performers (NEW)
    ├── Player 1: 8.5 MVP (B: 7.2, Bo: 1.3)
    ├── Player 2: 6.8 MVP (B: 0.0, Bo: 6.8)
    └── Player 3: 5.2 MVP (B: 4.5, Bo: 0.7)
```

---

## 🎯 Enhancement 2: Fielding Credits

### **When Wicket Falls:**

#### **Current Flow:**
```
Ball → Wicket → Select Dismissal Type → Next Ball
```

#### **New Flow:**
```
Ball → Wicket → Select Dismissal Type
    ↓
If "Caught" → Show dialog: "Who took the catch?"
    ↓
If "Run Out" → Show dialog: "Who did the run-out?"
    ↓
Save fielder name → Add to fielding MVP → Next Ball
```

### **Implementation Steps:**

#### **1. Update Delivery Model**
Add fielder information:
```dart
class _Delivery {
  final String? fielder;        // Who took catch/run-out
  final String? assistFielder;  // For run-outs (thrower)
  // ... existing fields
}
```

#### **2. Add Fielder Selection Dialog**
```dart
Future<String?> _showFielderSelectionDialog({
  required String dismissalType,
  required List<String> fieldingTeamPlayers,
}) async {
  // Show dialog with list of fielding team players
  // Return selected player name
}
```

#### **3. Update Wicket Handling**
```dart
void _recordWicket() async {
  // Existing wicket logic...
  
  // NEW: If caught or run-out, ask for fielder
  if (dismissalType == 'caught' || dismissalType == 'run out') {
    final fielder = await _showFielderSelectionDialog(
      dismissalType: dismissalType,
      fieldingTeamPlayers: _bowlingTeamPlayers,
    );
    
    // Save fielder in delivery
    delivery.fielder = fielder;
  }
}
```

#### **4. Update MVP Calculation**
```dart
// Count catches and run-outs per player
final catches = _deliveries
    .where((d) => d.fielder == playerName && d.wicketType == 'caught')
    .length;

final runOuts = _deliveries
    .where((d) => d.fielder == playerName && d.wicketType == 'run out')
    .length;

// Calculate fielding MVP
fieldingMvp = MvpCalculationService.calculateFieldingMvp(
  assists: List.generate(catches, (_) => {'battingOrder': 5}),
  runOuts: List.generate(runOuts, (_) => {'battingOrder': 5}),
  totalOvers: 20,
);
```

---

## 📊 **Expected Results:**

### **Enhancement 1:**
- ✅ MVP visible in Summary tab
- ✅ Updates live during match
- ✅ Shows top 3 performers

### **Enhancement 2:**
- ✅ Fielder selection dialog on catches
- ✅ Fielder selection dialog on run-outs
- ✅ Fielding MVP calculated correctly
- ✅ Fielders get credit in final MVP

---

## 🚀 **Priority:**

1. **Enhancement 2 (Fielding Credits)** - More important for accurate MVP
2. **Enhancement 1 (Summary Tab)** - Better UX

---

## ⏱️ **Estimated Time:**
- Enhancement 2: ~2 hours
- Enhancement 1: ~1 hour

**Total: ~3 hours of development**

---

**Ready to implement?** Let me know which one you want first! 🎯
