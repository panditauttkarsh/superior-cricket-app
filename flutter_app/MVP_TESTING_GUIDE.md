# MVP Feature Testing Guide

## 🎯 What the MVP Feature Shows

The MVP (Most Valuable Player) feature calculates and displays player performance using the **CricHeroes algorithm** with the new **ScorecardEngine** for accurate calculations.

### What You'll See:

1. **Player of the Match (POTM)**
   - Large card with player photo, name, team
   - Total MVP score (e.g., "5.810")
   - Performance grade (e.g., "Excellent 💎", "Outstanding 🌟")
   - Batting stats: Runs (Balls), Strike Rate
   - Bowling stats: Wickets/Runs, Economy
   - Fielding stats: Catches, Run Outs, Stumpings

2. **Best Batsman & Best Bowler**
   - Two side-by-side compact cards
   - Best Batsman: Highest batting MVP points
   - Best Bowler: Highest bowling MVP points

3. **Top Performers List**
   - Top 5 players ranked by total MVP points
   - Shows MVP breakdown (Batting + Bowling + Fielding)

4. **MVP Tab in Match Details**
   - Expandable list of all players
   - Ranked by MVP points
   - Shows detailed breakdown when expanded
   - Batting, Bowling, and Fielding stats per player

---

## 🧪 How to Test

### **Step 1: Start a Match**
1. Create a new match (T20, ODI, or Test)
2. Add players to both teams
3. Start scoring

### **Step 2: Score Both Innings**
**Important:** MVP is calculated across **BOTH innings**, so you need to complete both innings to see accurate results.

#### First Innings:
- Score runs for Team 1 batsmen
- Take wickets (bowled, caught, LBW, etc.)
- Record fielding contributions (catches, run-outs)
- Complete the innings

#### Second Innings:
- Score runs for Team 2 batsmen
- Take wickets
- Record fielding contributions
- Complete the innings

### **Step 3: Complete the Match**
1. When the match ends, select the winning team
2. Click "Complete Match"
3. The MVP calculation will run automatically using **ScorecardEngine**

### **Step 4: View MVP Results**
You'll see the **Match Result** screen with:

#### **Immediate Display:**
- ✅ **Player of the Match** card (large, prominent)
- ✅ **Best Batsman** and **Best Bowler** cards (side-by-side)
- ✅ **Top Performers** list (top 5 players)

#### **In Match Details:**
1. Go to Dashboard → Click on the completed match
2. Navigate to **"MVP"** tab
3. See all players ranked by MVP points
4. Expand any player to see detailed breakdown:
   - Batting MVP breakdown
   - Bowling MVP breakdown
   - Fielding MVP breakdown
   - Total MVP score

---

## ✅ What to Verify

### **1. Both Innings Stats Combined**
- ✅ If a player batted in 1st innings and bowled in 2nd innings, both should be counted
- ✅ Example: Jasprit J. batted 10 runs in 1st innings, took 1 wicket in 2nd innings
  - **Should show:** Batting MVP + Bowling MVP combined

### **2. Fielding Points from Both Innings**
- ✅ Catches, run-outs, stumpings from both innings should be counted
- ✅ Fielding MVP should reflect contributions from both innings

### **3. Accurate Calculations**
- ✅ Batting MVP: Based on runs, strike rate, team performance
- ✅ Bowling MVP: Based on wickets, economy, maidens, batting order of dismissed players
- ✅ Fielding MVP: Based on catches (20% of wicket value), direct run-outs (100% of wicket value)

### **4. Player of the Match Selection**
- ✅ Winning team player gets precedence if in top 3
- ✅ Otherwise, highest MVP scorer wins

### **5. Performance Grades**
- ✅ Outstanding 🌟: 15+ MVP points
- ✅ Excellent 💎: 10-14.99 MVP points
- ✅ Very Good 🔥: 7-9.99 MVP points
- ✅ Good ⭐: 5-6.99 MVP points
- ✅ Average 👍: 3-4.99 MVP points
- ✅ Below Average 📊: <3 MVP points

---

## 🔍 Debugging Tips

### Check Console Logs:
When MVP is calculated, you'll see debug logs:
```
🏆 Starting MVP calculation using ScorecardEngine for match [id]
📊 First innings: 120/5 in 20.0 overs
📊 Second innings: 115/7 in 19.3 overs
📋 Found 22 unique players across both innings
👤 PlayerName: Team=1 (TeamName), Batting: 50(30), Bowling: 2-25(12)
✅ PlayerName: 5.810 MVP (B: 4.030, Bo: 1.560, F: 0.220)
```

### Common Issues:
1. **MVP not showing?**
   - Ensure match is completed (both innings finished)
   - Check if MVP calculation ran (check console logs)
   - Verify players have stats (runs, wickets, or fielding)

2. **Stats missing from one innings?**
   - Verify both innings were completed
   - Check if ScorecardEngine calculated both innings correctly
   - Look for errors in console logs

3. **Fielding points not showing?**
   - Ensure catches/run-outs were recorded during scoring
   - Check if fielder name was entered correctly
   - Verify wicket type matches (Catch Out, Run Out, Stumped)

---

## 📊 Example Test Scenario

### **Test Match Setup:**
- **Team 1:** DEV (bats first)
- **Team 2:** MAHA (bats second)
- **Format:** T20 (20 overs)

### **First Innings (Team 1 - DEV):**
- Rohit Sharma: 37 runs (9 balls) - **Batting MVP**
- Virat Kohli: 20 runs (15 balls)
- Jasprit J. (MAHA): 1 wicket, 48 runs (2 overs) - **Bowling MVP**

### **Second Innings (Team 2 - MAHA):**
- Jasprit J.: 5 runs (3 balls) - **Combined with 1st innings bowling**
- Bowler from DEV: 2 wickets, 30 runs (3 overs)

### **Expected Results:**
- **Player of the Match:** Rohit Sharma (highest batting MVP)
- **Best Batsman:** Rohit Sharma
- **Best Bowler:** Jasprit J. (combined from both innings)
- **Jasprit J. MVP:** Should show both batting (2nd innings) and bowling (1st innings) MVP combined

---

## 🎉 Success Criteria

✅ MVP calculation uses ScorecardEngine (not old manual stats)  
✅ Both innings stats are combined correctly  
✅ Fielding points from both innings are counted  
✅ Player of the Match is selected correctly  
✅ Best Batsman and Best Bowler are identified  
✅ All MVP breakdowns show accurate numbers  
✅ Performance grades match MVP scores  
✅ MVP tab in match details shows all players ranked correctly

---

## 📝 Notes

- MVP is calculated **only when match is completed**
- Uses **CricHeroes algorithm** for fair scoring
- **ScorecardEngine** ensures 100% accuracy from delivery data
- All calculations are **delivery-driven** (no stored stats used)
- MVP points are saved to database for career stats tracking

