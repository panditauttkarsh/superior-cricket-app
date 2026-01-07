import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/match_model.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../../core/providers/repository_providers.dart';

/// Provider for tournament teams - shared across tabs
final tournamentTeamsProvider = FutureProvider.family<List<TournamentTeamModel>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentTeamRepositoryProvider);
  return await repository.getTournamentTeams(tournamentId);
});

/// Configuration for points – kept simple and centralized
class _PointsConfig {
  static const int winPoints = 2;
  static const int tieOrNoResultPoints = 1;
}

/// Aggregate stats used to build a single table row
class TournamentPointsEntry {
  final String teamName;
  final String? teamLogo;

  final int played;
  final int won;
  final int lost;
  final int tied;
  final int noResult;
  final int points;
  final double netRunRate;

  const TournamentPointsEntry({
    required this.teamName,
    required this.teamLogo,
    required this.played,
    required this.won,
    required this.lost,
    required this.tied,
    required this.noResult,
    required this.points,
    required this.netRunRate,
  });
}

class _TeamAggregate {
  int played = 0;
  int won = 0;
  int lost = 0;
  int tied = 0;
  int noResult = 0;

  int runsFor = 0;
  int runsAgainst = 0;
  double oversFaced = 0;
  double oversBowled = 0;
}

/// Points table provider – derives standings from completed matches only.
///
/// Source of truth:
/// - `tournament_teams` for which teams belong to the tournament
/// - `matches` + `scorecard` for actual results and scores
final pointsTableProvider =
    FutureProvider.family<List<TournamentPointsEntry>, String>((ref, tournamentId) async {
  final tournamentRepo = ref.read(tournamentRepositoryProvider);
  final tournamentTeamRepo = ref.read(tournamentTeamRepositoryProvider);
  final matchRepo = ref.read(matchRepositoryProvider);

  // Watch tournament teams provider to auto-invalidate when teams change
  // This ensures points table updates when teams are added/removed
  final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));
  
  // Load tournament (for date range)
  final TournamentModel? tournament = await tournamentRepo.getTournamentById(tournamentId);
  if (tournament == null) return [];
  
  // Get teams from the watched provider (will auto-update when teams change)
  final teams = teamsAsync.when(
    data: (data) => data,
    loading: () => <TournamentTeamModel>[],
    error: (_, __) => <TournamentTeamModel>[],
  );
  // Return empty list if no teams (will show empty state in UI)
  if (teams.isEmpty) return [];

  // Build quick lookup for team names → logo
  final teamNameToLogo = {
    for (final t in teams) t.teamName: t.teamLogo,
  };
  final tournamentTeamNames = teamNameToLogo.keys.toSet();

  // Fetch all completed matches – we will filter to matches that look like
  // they belong to this tournament based on:
  // - both team names are registered in this tournament
  // - match completed within tournament date window
  final allCompletedMatches = await matchRepo.getMatches(status: 'completed');

  final relevantMatches = allCompletedMatches.where((match) {
    if (match.completedAt == null) return false;

    final t1Name = match.team1Name ?? '';
    final t2Name = match.team2Name ?? '';

    if (!tournamentTeamNames.contains(t1Name) || !tournamentTeamNames.contains(t2Name)) {
      return false;
    }

    final completedAt = match.completedAt!;
    // Use inclusive date range for tournament
    final startsOnOrAfter = !completedAt.isBefore(tournament.startDate);
    final endsOnOrBefore = !completedAt.isAfter(tournament.endDate);

    return startsOnOrAfter && endsOnOrBefore;
  }).toList();

  if (relevantMatches.isEmpty) {
    // No completed matches yet – still return rows for teams with zeros
    return teams
        .map(
          (team) => TournamentPointsEntry(
            teamName: team.teamName,
            teamLogo: team.teamLogo,
            played: 0,
            won: 0,
            lost: 0,
            tied: 0,
            noResult: 0,
            points: 0,
            netRunRate: 0.0,
          ),
        )
        .toList();
  }

  final Map<String, _TeamAggregate> aggregates = {
    for (final t in teams) t.teamName: _TeamAggregate(),
  };

  for (final match in relevantMatches) {
    _applyMatchToAggregates(match, aggregates);
  }

  // Build final entries
  final entries = <TournamentPointsEntry>[];
  aggregates.forEach((teamName, agg) {
    final points = agg.won * _PointsConfig.winPoints +
        (agg.tied + agg.noResult) * _PointsConfig.tieOrNoResultPoints;

    double nrr = 0.0;
    if (agg.oversFaced > 0 && agg.oversBowled > 0) {
      final forRate = agg.runsFor / agg.oversFaced;
      final againstRate = agg.runsAgainst / agg.oversBowled;
      nrr = forRate - againstRate;
    }

    entries.add(
      TournamentPointsEntry(
        teamName: teamName,
        teamLogo: teamNameToLogo[teamName],
        played: agg.played,
        won: agg.won,
        lost: agg.lost,
        tied: agg.tied,
        noResult: agg.noResult,
        points: points,
        netRunRate: nrr,
      ),
    );
  });

  // Sort standings: points desc, NRR desc, then team name
  entries.sort((a, b) {
    if (b.points != a.points) return b.points.compareTo(a.points);
    if (b.netRunRate != a.netRunRate) return b.netRunRate.compareTo(a.netRunRate);
    return a.teamName.compareTo(b.teamName);
  });

  return entries;
});

void _applyMatchToAggregates(MatchModel match, Map<String, _TeamAggregate> aggregates) {
  final team1Name = match.team1Name ?? '';
  final team2Name = match.team2Name ?? '';

  if (!aggregates.containsKey(team1Name) || !aggregates.containsKey(team2Name)) {
    return;
  }

  final scorecard = match.scorecard ?? {};
  final team1Score = scorecard['team1_score'] as Map<String, dynamic>? ?? {};
  final team2Score = scorecard['team2_score'] as Map<String, dynamic>? ?? {};

  final team1Runs = (team1Score['runs'] as num?)?.toInt() ?? 0;
  final team2Runs = (team2Score['runs'] as num?)?.toInt() ?? 0;
  final team1OversRaw = (team1Score['overs'] as num?)?.toDouble() ?? 0.0;
  final team2OversRaw = (team2Score['overs'] as num?)?.toDouble() ?? 0.0;

  final team1Overs = _oversDecimalToOvers(team1OversRaw);
  final team2Overs = _oversDecimalToOvers(team2OversRaw);

  final team1Agg = aggregates[team1Name]!;
  final team2Agg = aggregates[team2Name]!;

  team1Agg.played += 1;
  team2Agg.played += 1;

  // Runs / overs for & against
  team1Agg.runsFor += team1Runs;
  team1Agg.runsAgainst += team2Runs;
  team2Agg.runsFor += team2Runs;
  team2Agg.runsAgainst += team1Runs;

  team1Agg.oversFaced += team1Overs;
  team1Agg.oversBowled += team2Overs;
  team2Agg.oversFaced += team2Overs;
  team2Agg.oversBowled += team1Overs;

  // Determine match result
  // First check if it's a tie (equal runs and both > 0)
  final bool isTie = team1Runs == team2Runs && (team1Runs > 0 || team2Runs > 0);
  
  if (isTie) {
    team1Agg.tied += 1;
    team2Agg.tied += 1;
    return;
  }

  // If winner_id is set, use it; otherwise determine from runs
  if (match.winnerId != null) {
    final winnerId = match.winnerId!;
    
    // If team IDs are available, compare with winner_id
    if (match.team1Id != null && match.team2Id != null) {
      final team1IsWinner = winnerId == match.team1Id;
      final team2IsWinner = winnerId == match.team2Id;
      
      if (team1IsWinner) {
        team1Agg.won += 1;
        team2Agg.lost += 1;
      } else if (team2IsWinner) {
        team2Agg.won += 1;
        team1Agg.lost += 1;
      }
      return;
    }
  }
  
  // Fallback: determine winner from runs comparison
  // (This handles cases where winner_id is null or team IDs are missing)
  if (team1Runs > team2Runs) {
    team1Agg.won += 1;
    team2Agg.lost += 1;
  } else if (team2Runs > team1Runs) {
    team2Agg.won += 1;
    team1Agg.lost += 1;
  } else {
    // Equal runs but not a tie (both 0) - treat as no result
    team1Agg.noResult += 1;
    team2Agg.noResult += 1;
  }
}

/// Convert overs stored as decimal (e.g., 19.3 for 19 overs 3 balls)
/// into actual overs value used for run rate (19 + 3/6).
double _oversDecimalToOvers(double oversDecimal) {
  final wholeOvers = oversDecimal.floor();
  final fraction = oversDecimal - wholeOvers;

  // Fraction is stored as x/10 where x is balls (0–5)
  final balls = (fraction * 10).round();
  if (balls <= 0) return wholeOvers.toDouble();

  return wholeOvers + (balls / 6.0);
}


