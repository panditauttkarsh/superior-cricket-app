# Testing Guide - New Cricket Scorecard Engine

## 🎯 Overview

The new cricket scorecard engine has been integrated into test pages. When you start a new match or view match details, you'll now use the new engine for all calculations.

## 📍 Navigation Changes

### 1. **Starting a New Match**
- **Before**: Navigated to `ScorecardPage` (old calculation logic)
- **Now**: Navigates to `TestScorecardPage` (uses new engine)
- **Location**: When you complete toss and player selection, it navigates to `/scorecard` route
- **Visual Indicator**: Orange banner at top saying "TEST MODE: Using New Scorecard Engine"

### 2. **Viewing Match Details**
- **Before**: Navigated to `MatchDetailPageComprehensive` (old calculation logic)
- **Now**: Navigates to `TestMatchDetailPage` (uses new engine)
- **Location**: When you click on a match card from Dashboard → My Matches
- **Route**: `/matches/:id`

## 🧪 How to Test

### Test 1: Start a New Match

1. **Navigate to Create Match**
   - Go to Dashboard → My Cricket → Create Match
   - Fill in match details (teams, overs, players)
   - Complete toss
   - Select initial players (striker, non-striker, bowler)

2. **Start Scoring**
   - You should see the orange "TEST MODE" banner at the top
   - Score some runs, take wickets, add extras
   - Complete first innings

3. **Verify Calculations**
   - Check that overs are calculated correctly (6 balls per over)
   - Verify bowler overs sum equals total overs
   - Check batting stats (runs, balls, strike rate)
   - Verify dismissal status shows correctly

### Test 2: View Match Details

1. **Complete a Match**
   - Complete both innings of a match
   - End the match

2. **View Match Details**
   - Go to Dashboard → My Matches
   - Click on any completed match card
   - Navigate to "Scorecard" tab

3. **Verify Stats**
   - Check first innings stats:
     - Total overs should match sum of bowler overs
     - All dismissed players should show as "out"
     - Batting stats should be accurate
   - Check second innings stats:
     - Same validations as first innings
   - Verify no missing balls in bowler sections

### Test 3: Edge Cases

1. **Last Wicket Ball**
   - Complete a match where last wicket falls
   - Verify the last wicket ball is counted in bowler stats
   - Check that bowler overs match total overs

2. **Wides and No-Balls**
   - Score some wides and no-balls
   - Verify they don't count as legal balls
   - Check extras are calculated correctly

3. **Partnerships**
   - Score runs with different batsmen
   - Verify partnerships are calculated correctly

4. **Fall of Wickets**
   - Take multiple wickets
   - Verify fall-of-wicket timeline is accurate

## ✅ What to Check

### Batting Stats
- [ ] Runs match actual runs scored
- [ ] Balls faced match legal balls only
- [ ] Fours and sixes are correct
- [ ] Strike rate is accurate
- [ ] Dismissal status shows correctly (out/not out)
- [ ] Dismissal type is shown

### Bowling Stats
- [ ] Overs match total overs (no missing balls)
- [ ] Legal balls are counted correctly
- [ ] Runs conceded are accurate
- [ ] Wickets are credited correctly
- [ ] Maidens are calculated correctly
- [ ] Economy rate is accurate

### Team Totals
- [ ] Total runs are correct
- [ ] Total wickets are correct
- [ ] Total overs match sum of bowler overs
- [ ] Extras breakdown is accurate

### Consistency Checks
- [ ] Bowler overs sum = Total overs
- [ ] Batsman balls sum = Total legal balls (approximately, accounting for dismissals)
- [ ] All dismissed players show as "out"
- [ ] No missing balls in any section

## 🐛 Troubleshooting

### If stats don't match:

1. **Check Debug Console**
   - Look for warnings about deliveries with empty striker/bowler
   - Check for duplicate delivery warnings

2. **Verify Data**
   - Ensure deliveries are being saved correctly
   - Check that all deliveries have valid bowler and striker fields

3. **Compare with Old Page**
   - Temporarily switch back to old pages to compare
   - Note any discrepancies

## 🔄 Switching Back (If Needed)

If you need to switch back to old pages temporarily:

### In `app_router.dart`:

**For Scorecard (Line ~386):**
```dart
// Change from:
return TestScorecardPage(...);

// To:
return ScorecardPage(...);
```

**For Match Details (Line ~188):**
```dart
// Change from:
return TestMatchDetailPage(matchId: matchId);

// To:
return MatchDetailPageComprehensive(matchId: matchId);
```

## 📊 Expected Results

After testing, you should see:
- ✅ All calculations are accurate
- ✅ No missing balls in bowler stats
- ✅ Dismissal status shows correctly
- ✅ Overs match between different sections
- ✅ All edge cases handled correctly

## 🚀 Next Steps

Once testing is complete and validated:
1. The test pages can be made permanent
2. Old calculation logic can be removed
3. Test pages can be renamed (remove "Test" prefix)

## 📝 Notes

- The test pages use the same UI as original pages
- Only the calculation logic is different
- All data is saved the same way
- You can switch between test and original pages easily

