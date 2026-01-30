# MVP Calculation System - Complete Documentation

## 📋 Table of Contents
1. [Overview](#overview)
2. [Base Principles](#base-principles)
3. [Batting MVP Calculation](#batting-mvp-calculation)
4. [Bowling MVP Calculation](#bowling-mvp-calculation)
5. [Fielding MVP Calculation](#fielding-mvp-calculation)
6. [Total MVP Calculation](#total-mvp-calculation)
7. [Player of the Match Selection](#player-of-the-match-selection)
8. [Data Sources & Architecture](#data-sources--architecture)
9. [Complete Examples](#complete-examples)
10. [Edge Cases & Scenarios](#edge-cases--scenarios)

---

## 🎯 Overview

The MVP (Most Valuable Player) calculation system uses the **CricHeroes algorithm** to fairly evaluate player performance across batting, bowling, and fielding. The system is built on the following principles:

- **Delivery-Driven**: All calculations use ball-by-ball delivery data from the ScorecardEngine
- **Both Innings Combined**: Stats from first and second innings are aggregated
- **Fair Evaluation**: Considers match context, team performance, and player roles
- **No Penalties**: Only rewards good performance, never penalizes poor performance

---

## 🔢 Base Principles

### Core Conversion Rate
```
10 runs = 1 MVP Point
```

This is the fundamental conversion used throughout all calculations.

### Match Type Classification
Match types are determined by total overs:
- **0-7 overs**: Very short format
- **8-12 overs**: Short format
- **13-16 overs**: Medium-short format
- **17-20 overs**: T20 format
- **21-26 overs**: Extended T20
- **27-40 overs**: Medium format
- **41-50 overs**: ODI format
- **51-99 overs**: Extended ODI
- **100+ overs**: Test match

---

## 🏏 Batting MVP Calculation

### Formula
```
Total Batting MVP = Basic MVP Score + Strike Rate Bonus
```

### Step 1: Basic MVP Score
```
Basic MVP Score = Runs Scored / 10
```

**Example:**
- Player scores 60 runs
- Basic MVP Score = 60 / 10 = **6.0 points**

### Step 2: Strike Rate Bonus

#### Strike Rate Bonus Percentage by Match Type
| Match Type (Overs) | SR Bonus % |
|-------------------|------------|
| 0-20 overs        | 8%         |
| 21-35 overs       | 6%         |
| 36-50 overs       | 4%         |
| 51+ overs / Test  | 2%         |

#### Calculation Formula
```
Player SR = (Runs Scored / Balls Faced) × 100
Team SR = (Team Total Runs / Team Total Balls) × 100

IF Player SR >= Team SR:
    SR Bonus = ((Player SR / Team SR) × SR Bonus %) × Basic MVP Score
ELSE:
    SR Bonus = 0 (No penalty for slower scoring)
```

**Example 1: T20 Match (20 overs)**
- Player: 60 runs in 40 balls → Player SR = 150
- Team: 180 runs in 120 balls → Team SR = 150
- Basic MVP Score = 6.0
- SR Bonus % = 8% (T20)
- Player SR (150) >= Team SR (150) ✓
- SR Bonus = (150/150) × 0.08 × 6.0 = **0.48 points**
- **Total Batting MVP = 6.0 + 0.48 = 6.48 points**

**Example 2: Player slower than team**
- Player: 30 runs in 40 balls → Player SR = 75
- Team: 180 runs in 120 balls → Team SR = 150
- Basic MVP Score = 3.0
- Player SR (75) < Team SR (150) ✗
- SR Bonus = **0 points** (no penalty)
- **Total Batting MVP = 3.0 + 0 = 3.0 points**

### Important Notes
- ✅ **No Penalties**: Players are never penalized for scoring slower than team average
- ✅ **Both Innings Combined**: Runs and balls from both innings are summed
- ✅ **Zero Runs**: If player scored 0 runs or faced 0 balls, Batting MVP = 0

---

## ⚾ Bowling MVP Calculation

### Formula
```
Total Bowling MVP = Wicket Base MVP + Additional Wicket Bonus + SR Bonus + Maiden Over Bonus
```

### Step 1: Wicket Base MVP

#### Base Runs Per Wicket by Match Type
| Match Type (Overs) | Base Runs/Wicket |
|-------------------|------------------|
| 0-7 overs         | 12 runs          |
| 8-12 overs        | 14 runs          |
| 13-16 overs       | 16 runs          |
| 17-20 overs       | 18 runs          |
| 21-26 overs       | 20 runs          |
| 27-40 overs       | 22 runs          |
| 41-50 overs       | 25 runs          |
| 51-99 overs       | 27 runs          |
| Test match        | 25 runs          |

#### Batter Strength by Batting Order
| Batting Order | Strength % | Description        |
|--------------|------------|-------------------|
| 1-4          | 100%       | Top order         |
| 5-8          | 80%        | Middle order      |
| 9-11         | 60%        | Lower order       |

#### Wicket Value Calculation
```
Wicket Value = (Base Runs Per Wicket × Batter Strength) / 10

For each wicket:
    Wicket Base MVP += Wicket Value
```

**Example: T20 Match (20 overs)**
- Bowler takes 3 wickets:
  - Wicket 1: Opening batsman (Order 1) → Strength = 100%
  - Wicket 2: Middle order (Order 6) → Strength = 80%
  - Wicket 3: Lower order (Order 10) → Strength = 60%
- Base Runs Per Wicket = 18 (T20)
- Wicket 1 MVP = (18 × 1.0) / 10 = **1.8 points**
- Wicket 2 MVP = (18 × 0.8) / 10 = **1.44 points**
- Wicket 3 MVP = (18 × 0.6) / 10 = **1.08 points**
- **Wicket Base MVP = 1.8 + 1.44 + 1.08 = 4.32 points**

### Step 2: Additional Wicket Bonus (Milestone Bonus)

| Wickets Taken | Bonus Points | Equivalent Runs |
|--------------|--------------|------------------|
| 3 wickets    | 0.5 points   | 5 runs           |
| 5 wickets    | 1.0 point    | 10 runs          |
| 10 wickets   | 1.5 points   | 15 runs          |

**Example:**
- Bowler takes 5 wickets
- Additional Wicket Bonus = **1.0 point**

### Step 3: Strike Rate Bonus (Economy Bonus)

#### Calculation Formula
```
Player SR = (Runs Conceded / Balls Bowled) × 100
Team SR = (Team Total Runs / Team Total Balls) × 100

IF Team SR >= Player SR (Bowler is economical):
    SR Bonus = ((Team SR / Player SR) × SR Bonus %) × Total MVP (so far)
ELSE:
    SR Bonus = 0 (No penalty for expensive bowling)
```

**SR Bonus Percentage** (same as batting):
- 0-20 overs: 8%
- 21-35 overs: 6%
- 36-50 overs: 4%
- 51+ overs / Test: 2%

**Example: T20 Match**
- Bowler: 40 runs in 24 balls → Player SR = 166.67
- Team: 180 runs in 120 balls → Team SR = 150
- Total MVP so far = 4.32 (from wickets)
- Team SR (150) < Player SR (166.67) ✗
- SR Bonus = **0 points** (no penalty)
- **Total Bowling MVP = 4.32 + 1.0 + 0 = 5.32 points**

**Example: Economical Bowler**
- Bowler: 20 runs in 24 balls → Player SR = 83.33
- Team: 180 runs in 120 balls → Team SR = 150
- Total MVP so far = 4.32
- Team SR (150) >= Player SR (83.33) ✓
- SR Bonus = (150/83.33) × 0.08 × 4.32 = **0.622 points**
- **Total Bowling MVP = 4.32 + 1.0 + 0.622 = 5.942 points**

### Step 4: Maiden Over Bonus

#### Maiden Overs to Wicket Conversion
| Match Type (Overs) | Maidens = 1 Wicket |
|-------------------|-------------------|
| 0-7 overs         | 1 maiden          |
| 8-26 overs        | 2 maidens         |
| 27-50 overs       | 3 maidens         |
| 51+ overs / Test  | 6 maidens         |

#### Calculation Formula
```
Maiden Bonus = (Maiden Overs / Maidens Per Wicket) × (Base Runs Per Wicket / 10)
```

**Example: T20 Match**
- Bowler bowls 2 maiden overs
- Maidens Per Wicket = 2 (T20)
- Base Runs Per Wicket = 18
- Maiden Bonus = (2 / 2) × (18 / 10) = **1.8 points**
- Added to total Bowling MVP

### Important Notes
- ✅ **No Penalties**: Bowlers are never penalized for expensive bowling
- ✅ **Both Innings Combined**: Wickets, runs, balls, maidens from both innings are summed
- ✅ **Wicket Batting Order**: Determined from scorecard data (which innings the wicket was taken)
- ✅ **Maiden Overs**: Only counted if bowler bowled at least 1 maiden over

---

## 🧤 Fielding MVP Calculation

### Formula
```
Total Fielding MVP = Assisted Wickets MVP + Direct Run-Outs MVP
```

### Step 1: Assisted Wickets (Catches & Stumpings)

**Rule**: Fielder gets **20% of the wicket's MVP value**

#### Calculation
```
For each catch/stumping:
    Wicket Value = (Base Runs Per Wicket × Batter Strength) / 10
    Fielding MVP += Wicket Value × 0.20
```

**Example: T20 Match**
- Fielder takes 2 catches:
  - Catch 1: Opening batsman (Order 1) → Strength = 100%
  - Catch 2: Middle order (Order 6) → Strength = 80%
- Base Runs Per Wicket = 18 (T20)
- Catch 1 MVP = ((18 × 1.0) / 10) × 0.20 = **0.36 points**
- Catch 2 MVP = ((18 × 0.8) / 10) × 0.20 = **0.288 points**
- **Total Assisted Wickets MVP = 0.36 + 0.288 = 0.648 points**

### Step 2: Direct Run-Outs (Unassisted)

**Rule**: Fielder gets **100% of the wicket's MVP value** (full credit)

#### Calculation
```
For each direct run-out (no assist fielder):
    Wicket Value = (Base Runs Per Wicket × Batter Strength) / 10
    Fielding MVP += Wicket Value
```

**Example: T20 Match**
- Fielder effects 1 direct run-out:
  - Run-out: Opening batsman (Order 1) → Strength = 100%
- Base Runs Per Wicket = 18 (T20)
- Run-Out MVP = (18 × 1.0) / 10 = **1.8 points**

### Combined Example
- 2 catches (assisted) = 0.648 points
- 1 direct run-out = 1.8 points
- **Total Fielding MVP = 0.648 + 1.8 = 2.448 points**

### Important Notes
- ✅ **Both Innings Combined**: Catches, run-outs, stumpings from both innings are counted
- ✅ **Assisted vs Unassisted**: Only direct run-outs (no assist fielder) get full credit
- ✅ **Wicket Batting Order**: Determined from scorecard data (which innings the dismissal occurred)
- ✅ **Stumpings**: Treated same as catches (20% of wicket value)

---

## 🎯 Total MVP Calculation

### Formula
```
Total MVP = Batting MVP + Bowling MVP + Fielding MVP
```

### Example: All-Rounder Performance

**Player: Jasprit J. (T20 Match - 20 overs)**

#### Batting (2nd Innings):
- 10 runs in 5 balls
- Team: 120 runs in 80 balls
- Basic MVP = 10 / 10 = 1.0
- Player SR = 200, Team SR = 150
- SR Bonus = (200/150) × 0.08 × 1.0 = 0.107
- **Batting MVP = 1.107 points**

#### Bowling (1st Innings):
- 3 wickets (Order 1, 5, 9)
- 40 runs in 24 balls
- 1 maiden over
- Wicket Base MVP = 1.8 + 1.44 + 1.08 = 4.32
- Additional Bonus (3 wickets) = 0.5
- SR Bonus = 0 (expensive)
- Maiden Bonus = (1/2) × 1.8 = 0.9
- **Bowling MVP = 4.32 + 0.5 + 0 + 0.9 = 5.72 points**

#### Fielding (Both Innings):
- 1 catch (Order 3) = 0.36 points
- **Fielding MVP = 0.36 points**

#### Total MVP:
- **Total MVP = 1.107 + 5.72 + 0.36 = 7.187 points**

---

## 👑 Player of the Match Selection

### Selection Rules

1. **Calculate Total MVP** for all players
2. **Sort by Total MVP** (descending)
3. **Get Top 3** players
4. **Check Winning Team**:
   - If any player from **winning team** is in Top 3 → **That player becomes POTM**
   - If no winning team player in Top 3 → **Highest MVP scorer becomes POTM** (even if from losing team)

### Example Scenarios

**Scenario 1: Winning Team Player in Top 3**
- Top 3 MVP:
  1. Player A (Losing Team) - 8.5 MVP
  2. Player B (Winning Team) - 7.2 MVP
  3. Player C (Losing Team) - 6.8 MVP
- **Result**: Player B becomes POTM (winning team precedence)

**Scenario 2: No Winning Team Player in Top 3**
- Top 3 MVP:
  1. Player A (Losing Team) - 8.5 MVP
  2. Player B (Losing Team) - 7.2 MVP
  3. Player C (Losing Team) - 6.8 MVP
- **Result**: Player A becomes POTM (highest scorer, even from losing team)

---

## 🏗️ Data Sources & Architecture

### ScorecardEngine Integration

The MVP calculation uses the **ScorecardEngine** for accurate, delivery-driven statistics:

1. **First Innings Scorecard**:
   ```dart
   ScorecardEngine.calculateScorecard(
     deliveries: firstInningsDeliveries,
     teamName: team1Name,
   )
   ```

2. **Second Innings Scorecard**:
   ```dart
   ScorecardEngine.calculateScorecard(
     deliveries: secondInningsDeliveries,
     teamName: team2Name,
   )
   ```

### Data Aggregation

#### Batting Stats (Combined from Both Innings)
- **Runs Scored**: Sum of runs from both innings
- **Balls Faced**: Sum of balls from both innings
- **Is Not Out**: False if dismissed in either innings

#### Bowling Stats (Combined from Both Innings)
- **Balls Bowled**: Sum of legal balls from both innings
- **Runs Conceded**: Sum of runs from both innings
- **Wickets Taken**: Sum of wickets from both innings
- **Maiden Overs**: Sum of maidens from both innings

#### Fielding Stats (Combined from Both Innings)
- **Catches**: Count from all deliveries (both innings)
- **Run-Outs**: Count from all deliveries (both innings)
- **Stumpings**: Count from all deliveries (both innings)

### Team Totals

For MVP calculations, team totals are determined from the scorecard:
- **Team Total Runs**: From scorecard (both innings combined for player's team)
- **Team Total Balls**: Legal balls from scorecard (both innings combined)

---

## 📊 Complete Examples

### Example 1: Pure Batsman (T20 - 20 overs)

**Player: Rohit Sharma**
- **Batting**: 60 runs in 40 balls
- **Team**: 180 runs in 120 balls
- **Bowling**: 0 wickets, 0 balls
- **Fielding**: 0 catches, 0 run-outs

**Calculation:**
- Basic MVP = 60 / 10 = 6.0
- Player SR = 150, Team SR = 150
- SR Bonus = (150/150) × 0.08 × 6.0 = 0.48
- **Batting MVP = 6.48**
- **Bowling MVP = 0**
- **Fielding MVP = 0**
- **Total MVP = 6.48 points**

---

### Example 2: Pure Bowler (T20 - 20 overs)

**Player: Jasprit Bumrah**
- **Batting**: 0 runs, 0 balls
- **Bowling**: 4 wickets (Order 1, 2, 5, 7), 30 runs in 24 balls, 1 maiden
- **Team**: 180 runs in 120 balls
- **Fielding**: 0 catches, 0 run-outs

**Calculation:**
- Wicket Base MVP:
  - Order 1: (18 × 1.0) / 10 = 1.8
  - Order 2: (18 × 1.0) / 10 = 1.8
  - Order 5: (18 × 0.8) / 10 = 1.44
  - Order 7: (18 × 0.8) / 10 = 1.44
  - Total = 6.48
- Additional Bonus (4 wickets) = 0.5
- Player SR = 125, Team SR = 150
- SR Bonus = (150/125) × 0.08 × 6.48 = 0.622
- Maiden Bonus = (1/2) × 1.8 = 0.9
- **Bowling MVP = 6.48 + 0.5 + 0.622 + 0.9 = 8.502**
- **Batting MVP = 0**
- **Fielding MVP = 0**
- **Total MVP = 8.502 points**

---

### Example 3: All-Rounder (T20 - 20 overs)

**Player: Hardik Pandya**
- **Batting**: 40 runs in 25 balls
- **Team Batting**: 180 runs in 120 balls
- **Bowling**: 2 wickets (Order 3, 6), 35 runs in 18 balls
- **Team Bowling**: 150 runs in 100 balls
- **Fielding**: 1 catch (Order 4), 1 direct run-out (Order 8)

**Calculation:**

**Batting MVP:**
- Basic MVP = 40 / 10 = 4.0
- Player SR = 160, Team SR = 150
- SR Bonus = (160/150) × 0.08 × 4.0 = 0.341
- **Batting MVP = 4.341**

**Bowling MVP:**
- Wicket Base MVP:
  - Order 3: (18 × 1.0) / 10 = 1.8
  - Order 6: (18 × 0.8) / 10 = 1.44
  - Total = 3.24
- Additional Bonus (2 wickets) = 0
- Player SR = 194.44, Team SR = 150
- SR Bonus = 0 (expensive)
- **Bowling MVP = 3.24**

**Fielding MVP:**
- Catch (Order 4): ((18 × 1.0) / 10) × 0.20 = 0.36
- Run-Out (Order 8): (18 × 0.8) / 10 = 1.44
- **Fielding MVP = 1.8**

**Total MVP:**
- **Total MVP = 4.341 + 3.24 + 1.8 = 9.381 points**

---

### Example 4: Wicket-Keeper (ODI - 50 overs)

**Player: MS Dhoni**
- **Batting**: 50 runs in 60 balls
- **Team**: 280 runs in 300 balls
- **Bowling**: 0 wickets, 0 balls
- **Fielding**: 3 catches (Order 1, 3, 5), 2 stumpings (Order 2, 4)

**Calculation:**

**Batting MVP:**
- Basic MVP = 50 / 10 = 5.0
- Player SR = 83.33, Team SR = 93.33
- SR Bonus = 0 (slower than team)
- **Batting MVP = 5.0**

**Bowling MVP = 0**

**Fielding MVP:**
- Base Runs Per Wicket = 25 (ODI)
- Catch Order 1: ((25 × 1.0) / 10) × 0.20 = 0.5
- Catch Order 3: ((25 × 1.0) / 10) × 0.20 = 0.5
- Catch Order 5: ((25 × 0.8) / 10) × 0.20 = 0.4
- Stumping Order 2: ((25 × 1.0) / 10) × 0.20 = 0.5
- Stumping Order 4: ((25 × 1.0) / 10) × 0.20 = 0.5
- **Fielding MVP = 2.4**

**Total MVP:**
- **Total MVP = 5.0 + 0 + 2.4 = 7.4 points**

---

## 🔍 Edge Cases & Scenarios

### Scenario 1: Player Batted in 1st Innings, Bowled in 2nd Innings

**Player: Jasprit J.**
- **1st Innings (Batting)**: 10 runs in 5 balls
- **2nd Innings (Bowling)**: 2 wickets, 30 runs in 18 balls
- **Team 1**: 120 runs in 80 balls
- **Team 2**: 115 runs in 100 balls

**Calculation:**
- **Batting MVP**: Uses Team 1 totals (10 runs, 5 balls vs 120 runs, 80 balls)
- **Bowling MVP**: Uses Team 2 totals (2 wickets, 30 runs, 18 balls vs 115 runs, 100 balls)
- Both are calculated and **combined** for Total MVP

### Scenario 2: Zero Runs Scored

**Player**: 0 runs in 10 balls
- **Batting MVP = 0** (no runs = no MVP)
- Other contributions (bowling, fielding) still count

### Scenario 3: Expensive Bowling (No Penalty)

**Player**: 60 runs in 24 balls (very expensive)
- **SR Bonus = 0** (no penalty)
- Still gets credit for wickets and maidens

### Scenario 4: Maiden Overs Only (No Wickets)

**Player**: 0 wickets, 0 runs in 12 balls (2 maidens)
- **Wicket Base MVP = 0**
- **Maiden Bonus = (2/2) × 1.8 = 1.8 points**
- **Total Bowling MVP = 1.8 points**

### Scenario 5: Multiple Fielding Contributions

**Player**: 2 catches, 1 stumping, 1 direct run-out
- All are counted and combined
- Catches/Stumpings: 20% each
- Direct Run-Out: 100%

### Scenario 6: Test Match (100+ overs)

**Player**: 100 runs in 200 balls
- **SR Bonus % = 2%** (Test match)
- Lower bonus percentage for longer formats

---

## 📈 Performance Grades

Based on Total MVP points:

| MVP Points | Grade              |
|-----------|-------------------|
| 15.0+     | Outstanding 🌟    |
| 10.0-14.99| Excellent 💎      |
| 7.0-9.99  | Very Good 🔥      |
| 5.0-6.99  | Good ⭐           |
| 3.0-4.99  | Average 👍        |
| <3.0      | Below Average 📊  |

---

## ✅ Key Features

1. ✅ **No Penalties**: Players are never penalized for poor performance
2. ✅ **Fair Evaluation**: Considers match context and team performance
3. ✅ **Both Innings**: Stats from both innings are combined
4. ✅ **Delivery-Driven**: Uses ScorecardEngine for 100% accuracy
5. ✅ **Role-Aware**: Different values for top/middle/lower order batsmen
6. ✅ **Match Type Aware**: Different bonuses for T20/ODI/Test
7. ✅ **Winning Team Precedence**: POTM selection favors winning team

---

## 🔧 Technical Implementation

### Calculation Flow

1. **Load Match Data**: Get deliveries from both innings
2. **Calculate Scorecards**: Use ScorecardEngine for both innings
3. **Aggregate Stats**: Combine batting, bowling, fielding from both innings
4. **Calculate MVP Components**:
   - Batting MVP (runs + SR bonus)
   - Bowling MVP (wickets + SR bonus + maidens)
   - Fielding MVP (catches + run-outs + stumpings)
5. **Calculate Total MVP**: Sum all components
6. **Select POTM**: Apply winning team precedence rule
7. **Save to Database**: Store all MVP data for career stats

### Data Persistence

All MVP data is saved to the database:
- Player ID, Name, Avatar
- Match ID, Team ID, Team Name
- Batting MVP, Bowling MVP, Fielding MVP, Total MVP
- Detailed stats (runs, balls, wickets, catches, etc.)
- Performance Grade
- Is Player of the Match flag
- Calculated timestamp

---

## 📝 Summary

The MVP calculation system provides a **fair, comprehensive, and accurate** evaluation of player performance using:

- **CricHeroes Algorithm**: Industry-standard calculation method
- **ScorecardEngine**: Delivery-driven accuracy
- **Both Innings**: Complete match performance
- **No Penalties**: Only rewards, never punishes
- **Context-Aware**: Match type, team performance, player roles

This ensures that the **Most Valuable Player** truly represents the best overall performance in the match! 🏆

