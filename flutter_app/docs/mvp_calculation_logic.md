# MVP Calculation Logic - Superior Cricket App

This document explains the mathematical formulas and logic used to calculate Most Valuable Player (MVP) points in the Superior Cricket App.

## Overview

The MVP system converts player performances into points using a base conversion rate:
**10 Runs = 1.0 MVP Point**

Points are calculated across three main categories: **Batting**, **Bowling**, and **Fielding**.

---

## 1. Batting MVP Calculation

Batting points are based on runs scored, with a bonus for maintaining a high Strike Rate (SR).

### Formula
$$Total Batting MVP = Basic MVP + Strike Rate Bonus$$

#### A. Basic MVP
$$Basic MVP = \frac{Runs Scored}{10}$$

#### B. Strike Rate Bonus
The SR bonus is awarded if the player's strike rate is higher than the team's overall strike rate. It does not penalize for lower strike rates.

$$Bonus = (\frac{Player SR}{Team SR} \times SR Bonus \%) \times Basic MVP$$

**SR Bonus %** depends on the match length:
| Match Overs | SR Bonus % |
| :--- | :--- |
| ≤ 20 Overs | 8% |
| 21 - 35 Overs | 6% |
| 36 - 50 Overs | 4% |
| 51+ Overs | 2% |

---

## 2. Bowling MVP Calculation

Bowling points are based on wickets taken, with adjustments for the strength of the batsman dismissed and bonuses for economy and milestones.

### Formula
$$Total Bowling MVP = Wicket Points + Milestone Bonus + Economy Bonus + Maiden Bonus$$

#### A. Wicket Points
Each wicket has a "Base Runs" value depending on the match format. This value is then multiplied by the **Batter Strength**.

$$Wicket Value = \frac{Base Runs \times Batter Strength}{10}$$

**Base Runs per Wicket:**
| Match Overs | Base Runs |
| :--- | :--- |
| ≤ 7 | 12 |
| 8 - 12 | 14 |
| 13 - 16 | 16 |
| 17 - 20 | 18 |
| 21 - 26 | 20 |
| 27 - 40 | 22 |
| 41 - 50 | 25 |
| 51+ / Test | 27 |

**Batter Strength Multiplier:**
- **Top Order (1-4):** 100% (1.0)
- **Middle Order (5-8):** 80% (0.8)
- **Lower Order (9-11):** 60% (0.6)

#### B. Wicket Milestone Bonus
| Wickets Taken | Bonus Points |
| :--- | :--- |
| 3 Wickets | +0.5 |
| 5 Wickets | +1.0 |
| 10 Wickets | +1.5 |

#### C. Strike Rate (Economy) Bonus
Awarded if the bowler's runs-per-ball is lower than the team's overall runs-per-ball (indicating a better economy).

$$Bonus = (\frac{Team SR}{Player SR} \times SR Bonus \%) \times Current MVP$$

#### D. Maiden Over Bonus
$$Maiden Bonus = \frac{Maiden Overs}{Required Maidens Per Wicket} \times \frac{Base Runs}{10}$$

---

## 3. Fielding MVP Calculation

Fielding points are awarded for direct contributions to dismissals.

| Action | Point Value |❌ WHAT IS NOT CORRECT / INCOMPLETE
These are important because they change behavior.
❌ 1. Batting SR Bonus Formula (Missing Constraints)
Your document states:
Bonus = (Player SR / Team SR) × SR% × Basic MVP
⚠️ INCOMPLETE
Your actual logic ALSO includes:
Minimum balls faced requirement (≥ 10 balls)
Maximum SR multiplier cap (2×)
📌 Current doc allows tail-ender distortion — your code does not
REQUIRED FIX (Documentation)
Add this under SR Bonus:
Conditions:
Player must face at least 10 balls to be eligible
SR ratio is capped at 2.0× to prevent small-sample distortion
❌ 2. Bowling Economy Bonus Formula is WRONG
Your document says:
Bonus = (Team SR / Player SR × SR%) × Current MVP
❌ This is outdated and incorrect
Your code explicitly fixes this.
Actual logic:
Economy bonus is calculated ONLY on base wicket MVP
Milestone bonus is excluded
Prevents compounding inflation
REQUIRED FIX (Critical)
Replace this line with:
Economy bonus is calculated only on base wicket MVP,
excluding milestone and maiden bonuses to prevent inflation.
❌ 3. Zero Runs Conceded Case Missing
Your document does not mention:
Perfect spells (0 runs conceded)
Special handling
Double economy bonus
But your code explicitly does.
REQUIRED FIX
Add a subsection:
Perfect Spell Handling:
If a bowler concedes 0 runs, a special maximum economy bonus is awarded to avoid division errors and ensure fair reward.
❌ 4. Maiden Overs Per Wicket Mapping Missing
Your document says:
“Required Maidens Per Wicket”
…but never defines it.
Your code does.
REQUIRED FIX
Add this table:
Match Overs	Maidens = 1 Wicket
≤7	1
8–26	2
27–50	3
51+	6
❌ 5. Bowling Without Wickets Not Documented
Your code allows:
MVP for economical spells with zero wickets
Your document implies wickets are required.
REQUIRED FIX
Add:
Bowlers can earn MVP points even without wickets through economy and maiden bonuses.
❌ 6. Fielding Wicket Value Context Missing
Your doc implies a fixed wicket value.
Your code:
Recalculates wicket value using batting order + match format
Same logic as bowling
REQUIRED FIX
Clarify:
Fielding wicket value uses the same base wicket calculation as bowling, including batter strength and match format.
⚠️ MINOR BUT IMPORTANT CLARIFICATIONS
Batting Order
Batting order is tracked
Not used for batting MVP
Used only for bowling & fielding wicket valuation
Add a note to avoid confusion.
✅ FINAL VERDICT
Is this document correct?
🟡 Partially
Accuracy Score
Conceptual: 9/10
Implementation-accurate: 7/10
What’s needed to make it production-perfect
Add SR eligibility & cap
Fix bowling economy formula
Document zero-run spells
Define maiden conversion
Clarify no-wicket bowling MVP
Clarify wicket value reuse in fielding
| :--- | :--- |
| **Catch / Stumping** | 20% of the Wicket Value |
| **Direct Hit Run Out** | 100% of the Wicket Value |

---

## 4. Player of the Match Determination

The "Player of the Match" is determined by:
1. Identifying the players with the highest total MVP points.
2. Checking the top 3 players.
3. If a player from the **winning team** is in the top 3, the highest-ranked winner is chosen.
4. If no winner is in the top 3, the overall MVP leader is chosen.

---

## Performance Grading

MVP points are also used to assign a descriptive grade to the performance:
- **15.0+** : Outstanding 🌟
- **10.0+** : Excellent 💎
- **7.0+**  : Very Good 🔥
- **5.0+**  : Good ⭐
- **3.0+**  : Average 👍
- **< 3.0** : Below Average 📊
