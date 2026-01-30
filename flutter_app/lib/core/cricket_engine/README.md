# Cricket Scorecard Engine

A production-grade, delivery-driven cricket scoring engine that calculates all statistics from ball-by-ball data.

## Architecture

### Models (`models/`)
- **DeliveryModel**: Immutable representation of a single ball
- **ScorecardModel**: Complete match statistics (batting, bowling, extras, partnerships, fall-of-wickets)

### Engine (`engine/`)
- **ScorecardEngine**: Pure calculation logic that processes deliveries and outputs scorecard
  - Never relies on stored stats
  - Always recalculates from deliveries
  - Handles all ICC/BCCI edge cases

### Adapter (`adapter/`)
- **ScorecardAdapter**: Transforms engine output to match existing UI format
  - Ensures UI remains unchanged
  - Converts between engine models and UI models

## Key Features

### ✅ Legal Ball Counting
- Wides and no-balls don't count as legal balls
- Overs calculated from legal balls only
- Format: `legalBalls / 6.0` (e.g., 11 balls = 1.833, displays as 1.5)

### ✅ All Dismissal Types
- Bowled, Caught, LBW, Stumped, Hit Wicket (credited to bowler)
- Run Out, Retired Hurt (not credited to bowler)
- Proper wicket attribution

### ✅ Partnerships
- Calculated since last wicket
- Tracks runs and balls for each partnership
- Identifies wicket that ended partnership

### ✅ Fall of Wickets
- Complete timeline of dismissals
- Shows runs and overs when each wicket fell
- Includes dismissal type and dismissed by

### ✅ Extras Breakdown
- Wides, No Balls, Byes, Leg Byes, Penalty
- Proper attribution (bowler vs team)

### ✅ Super Overs
- Handled as separate innings
- Same calculation logic applies

### ✅ Edge Cases
- No-ball run distribution
- Run-outs on no-balls
- Short runs
- Multiple extras on same ball

## Usage

```dart
// Load deliveries from database
final deliveriesJson = scorecard['deliveries'] as List<dynamic>;
final deliveries = ScorecardAdapter.deliveriesFromJson(deliveriesJson);

// Calculate scorecard
final scorecardModel = ScorecardEngine.calculateScorecard(
  deliveries: deliveries,
  teamName: 'Team 1',
  isSuperOver: false,
);

// Use in UI
final uiFormat = ScorecardAdapter.toUIScorecardFormat(scorecardModel);
```

## Testing

Use `TestMatchDetailPage` to test the new engine:
- Navigate to `/test-match-details/{matchId}`
- Compares new engine output with existing UI
- Validates all calculations

## Migration Path

1. Test with `TestMatchDetailPage` - verify calculations match
2. Once validated, replace old calculation logic with engine
3. UI remains unchanged - only calculation layer changes

