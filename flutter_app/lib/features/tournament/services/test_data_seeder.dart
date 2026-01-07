import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/tournament_repository.dart';
import '../../../../core/repositories/tournament_team_repository.dart';
import '../../../../core/repositories/match_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Test Data Seeder for Tournament Points Table
/// Creates a test tournament with teams and completed matches
class TournamentTestDataSeeder {
  final _supabase = SupabaseConfig.client;

  /// Find tournament by name
  Future<String?> findTournamentByName(WidgetRef ref, String tournamentName) async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final allTournaments = await tournamentRepo.getTournaments();
      final tournament = allTournaments.firstWhere(
        (t) => t.name.toLowerCase() == tournamentName.toLowerCase(),
        orElse: () => throw Exception('Tournament not found'),
      );
      return tournament.id;
    } catch (e) {
      return null;
    }
  }

  /// Seed test data into existing tournament (e.g., KPL)
  /// Returns the tournament ID
  Future<String> seedIntoExistingTournament(WidgetRef ref, String tournamentName) async {
    try {
      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be logged in to create test data');
      }

      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final matchRepo = ref.read(matchRepositoryProvider);

      // 1. Find existing tournament
      final allTournaments = await tournamentRepo.getTournaments();
      final tournament = allTournaments.firstWhere(
        (t) => t.name.toLowerCase() == tournamentName.toLowerCase(),
        orElse: () => throw Exception('Tournament "$tournamentName" not found'),
      );
      final tournamentId = tournament.id;
      print('✅ Found tournament: ${tournament.name} (ID: $tournamentId)');

      // 2. Get existing teams to avoid duplicates
      final existingTeams = await teamRepo.getTournamentTeams(tournamentId);
      final existingTeamNames = existingTeams.map((t) => t.teamName.toLowerCase()).toSet();
      print('✅ Found ${existingTeams.length} existing teams');

      // 3. Create Teams and store their IDs
      final teamNames = [
        'Black Panthers',
        'Valley Warriors',
        'Brave Hearts',
        'Tikdi Tigers',
        'Asset Assassins',
        'Staff Mavericks',
        'Retired XI',
      ];

      final Map<String, String> teamNameToId = {};
      
      // First, map existing teams
      for (final existingTeam in existingTeams) {
        teamNameToId[existingTeam.teamName] = existingTeam.id;
      }

      // Then, add new teams that don't exist
      for (final teamName in teamNames) {
        if (!existingTeamNames.contains(teamName.toLowerCase())) {
          try {
            final team = await teamRepo.addTeamToTournament(
              tournamentId: tournamentId,
              teamName: teamName,
            );
            teamNameToId[teamName] = team.id;
            print('✅ Added team: $teamName (ID: ${team.id})');
          } catch (e) {
            // Team might already exist, try to find it
            final teams = await teamRepo.getTournamentTeams(tournamentId);
            final foundTeam = teams.firstWhere(
              (t) => t.teamName.toLowerCase() == teamName.toLowerCase(),
              orElse: () => throw Exception('Could not add or find team: $teamName'),
            );
            teamNameToId[teamName] = foundTeam.id;
            print('✅ Found existing team: $teamName (ID: ${foundTeam.id})');
          }
        } else {
          // Find the existing team ID
          final existingTeam = existingTeams.firstWhere(
            (t) => t.teamName.toLowerCase() == teamName.toLowerCase(),
          );
          teamNameToId[teamName] = existingTeam.id;
          print('ℹ️  Team already exists: $teamName (ID: ${existingTeam.id})');
        }
      }
      print('✅ Total teams: ${teamNameToId.length}');

      // 4. Create Completed Matches with Scorecards
      final now = DateTime.now();
      
      // Match 1: Black Panthers vs Valley Warriors
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[0]]!,
        teamNameToId[teamNames[1]]!,
        teamNameToId[teamNames[0]]!,
        teamNames[0],
        teamNames[1],
        runs1: 150,
        wickets1: 5,
        overs1: 20.0,
        runs2: 120,
        wickets2: 8,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 25)),
      );

      // Match 2: Brave Hearts vs Tikdi Tigers
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[2]]!,
        teamNameToId[teamNames[3]]!,
        teamNameToId[teamNames[2]]!,
        teamNames[2],
        teamNames[3],
        runs1: 180,
        wickets1: 3,
        overs1: 20.0,
        runs2: 175,
        wickets2: 7,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 24)),
      );

      // Match 3: Black Panthers vs Brave Hearts
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[0]]!,
        teamNameToId[teamNames[2]]!,
        teamNameToId[teamNames[0]]!,
        teamNames[0],
        teamNames[2],
        runs1: 200,
        wickets1: 4,
        overs1: 20.0,
        runs2: 195,
        wickets2: 6,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 23)),
      );

      // Match 4: Valley Warriors vs Tikdi Tigers
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[1]]!,
        teamNameToId[teamNames[3]]!,
        teamNameToId[teamNames[1]]!,
        teamNames[1],
        teamNames[3],
        runs1: 165,
        wickets1: 2,
        overs1: 19.3,
        runs2: 140,
        wickets2: 9,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 22)),
      );

      // Match 5: Asset Assassins vs Staff Mavericks
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[4]]!,
        teamNameToId[teamNames[5]]!,
        teamNameToId[teamNames[5]]!,
        teamNames[4],
        teamNames[5],
        runs1: 100,
        wickets1: 10,
        overs1: 15.2,
        runs2: 101,
        wickets2: 2,
        overs2: 12.5,
        completedAt: now.subtract(const Duration(days: 21)),
      );

      // Match 6: Valley Warriors vs Brave Hearts
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[1]]!,
        teamNameToId[teamNames[2]]!,
        teamNameToId[teamNames[1]]!,
        teamNames[1],
        teamNames[2],
        runs1: 175,
        wickets1: 6,
        overs1: 20.0,
        runs2: 170,
        wickets2: 8,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 20)),
      );

      // Match 7: Black Panthers vs Tikdi Tigers
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[0]]!,
        teamNameToId[teamNames[3]]!,
        teamNameToId[teamNames[0]]!,
        teamNames[0],
        teamNames[3],
        runs1: 190,
        wickets1: 5,
        overs1: 20.0,
        runs2: 150,
        wickets2: 10,
        overs2: 18.4,
        completedAt: now.subtract(const Duration(days: 19)),
      );

      // Match 8: Retired XI vs Asset Assassins
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[6]]!,
        teamNameToId[teamNames[4]]!,
        teamNameToId[teamNames[4]]!,
        teamNames[6],
        teamNames[4],
        runs1: 80,
        wickets1: 10,
        overs1: 14.0,
        runs2: 81,
        wickets2: 1,
        overs2: 10.2,
        completedAt: now.subtract(const Duration(days: 18)),
      );

      // Match 9: Valley Warriors vs Asset Assassins
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[1]]!,
        teamNameToId[teamNames[4]]!,
        teamNameToId[teamNames[1]]!,
        teamNames[1],
        teamNames[4],
        runs1: 160,
        wickets1: 4,
        overs1: 20.0,
        runs2: 120,
        wickets2: 8,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 17)),
      );

      // Match 10: Brave Hearts vs Staff Mavericks
      await _createCompletedMatch(
        matchRepo,
        teamNameToId[teamNames[2]]!,
        teamNameToId[teamNames[5]]!,
        teamNameToId[teamNames[2]]!,
        teamNames[2],
        teamNames[5],
        runs1: 140,
        wickets1: 6,
        overs1: 18.5,
        runs2: 135,
        wickets2: 9,
        overs2: 20.0,
        completedAt: now.subtract(const Duration(days: 16)),
      );

      print('✅ Created 10 completed matches');
      print('✅ Test data seeding complete for tournament: ${tournament.name} (ID: $tournamentId)');
      return tournamentId;
    } catch (e) {
      print('Error seeding into existing tournament: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Seed test tournament data (creates new tournament)
  /// Returns the created tournament ID
  Future<String> seedTestTournament(WidgetRef ref) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be logged in to create test data');
      }

      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final matchRepo = ref.read(matchRepositoryProvider);

      final now = DateTime.now();
      final tournamentData = {
        'name': 'Test Tournament Points Table',
        'city': 'Test City',
        'ground': 'Test Ground',
        'organizer_name': 'Test Organizer',
        'organizer_mobile': '1234567890',
        'start_date': now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0],
        'end_date': now.add(const Duration(days: 30)).toIso8601String().split('T')[0],
        'category': 'open',
        'ball_type': 'leather',
        'pitch_type': 'matting',
        'created_by': userId,
      };

      final tournament = await tournamentRepo.createTournament(tournamentData);
      final tournamentId = tournament.id;
      print('✅ Created tournament: ${tournament.name} (ID: $tournamentId)');

      final teamNames = [
        'Black Panthers',
        'Valley Warriors',
        'Brave Hearts',
        'Tikdi Tigers',
        'Asset Assassins',
        'Staff Mavericks',
        'Retired XI',
      ];

      final Map<String, String> teamNameToId = {};
      for (final teamName in teamNames) {
        final team = await teamRepo.addTeamToTournament(
          tournamentId: tournamentId,
          teamName: teamName,
        );
        teamNameToId[teamName] = team.id;
        print('✅ Added team: $teamName (ID: ${team.id})');
      }
      print('✅ Created ${teamNames.length} teams');

      // Create matches (same as seedIntoExistingTournament)
      await _createMatchesForTeams(matchRepo, teamNameToId, teamNames, now);

      print('✅ Created 10 completed matches');
      print('✅ Test tournament seeding complete! Tournament ID: $tournamentId');
      return tournamentId;
    } catch (e) {
      print('Error seeding test tournament: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> _createMatchesForTeams(
    MatchRepository matchRepo,
    Map<String, String> teamNameToId,
    List<String> teamNames,
    DateTime now,
  ) async {
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[0]]!, teamNameToId[teamNames[1]]!, teamNameToId[teamNames[0]]!, teamNames[0], teamNames[1], runs1: 150, wickets1: 5, overs1: 20.0, runs2: 120, wickets2: 8, overs2: 20.0, completedAt: now.subtract(const Duration(days: 25)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[2]]!, teamNameToId[teamNames[3]]!, teamNameToId[teamNames[2]]!, teamNames[2], teamNames[3], runs1: 180, wickets1: 3, overs1: 20.0, runs2: 175, wickets2: 7, overs2: 20.0, completedAt: now.subtract(const Duration(days: 24)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[0]]!, teamNameToId[teamNames[2]]!, teamNameToId[teamNames[0]]!, teamNames[0], teamNames[2], runs1: 200, wickets1: 4, overs1: 20.0, runs2: 195, wickets2: 6, overs2: 20.0, completedAt: now.subtract(const Duration(days: 23)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[1]]!, teamNameToId[teamNames[3]]!, teamNameToId[teamNames[1]]!, teamNames[1], teamNames[3], runs1: 165, wickets1: 2, overs1: 19.3, runs2: 140, wickets2: 9, overs2: 20.0, completedAt: now.subtract(const Duration(days: 22)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[4]]!, teamNameToId[teamNames[5]]!, teamNameToId[teamNames[5]]!, teamNames[4], teamNames[5], runs1: 100, wickets1: 10, overs1: 15.2, runs2: 101, wickets2: 2, overs2: 12.5, completedAt: now.subtract(const Duration(days: 21)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[1]]!, teamNameToId[teamNames[2]]!, teamNameToId[teamNames[1]]!, teamNames[1], teamNames[2], runs1: 175, wickets1: 6, overs1: 20.0, runs2: 170, wickets2: 8, overs2: 20.0, completedAt: now.subtract(const Duration(days: 20)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[0]]!, teamNameToId[teamNames[3]]!, teamNameToId[teamNames[0]]!, teamNames[0], teamNames[3], runs1: 190, wickets1: 5, overs1: 20.0, runs2: 150, wickets2: 10, overs2: 18.4, completedAt: now.subtract(const Duration(days: 19)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[6]]!, teamNameToId[teamNames[4]]!, teamNameToId[teamNames[4]]!, teamNames[6], teamNames[4], runs1: 80, wickets1: 10, overs1: 14.0, runs2: 81, wickets2: 1, overs2: 10.2, completedAt: now.subtract(const Duration(days: 18)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[1]]!, teamNameToId[teamNames[4]]!, teamNameToId[teamNames[1]]!, teamNames[1], teamNames[4], runs1: 160, wickets1: 4, overs1: 20.0, runs2: 120, wickets2: 8, overs2: 20.0, completedAt: now.subtract(const Duration(days: 17)));
    await _createCompletedMatch(matchRepo, teamNameToId[teamNames[2]]!, teamNameToId[teamNames[5]]!, teamNameToId[teamNames[2]]!, teamNames[2], teamNames[5], runs1: 140, wickets1: 6, overs1: 18.5, runs2: 135, wickets2: 9, overs2: 20.0, completedAt: now.subtract(const Duration(days: 16)));
  }

  /// Create a completed match with scorecard
  Future<void> _createCompletedMatch(
    MatchRepository matchRepo,
    String team1Id,
    String team2Id,
    String winnerId,
    String team1Name,
    String team2Name, {
    required int runs1,
    required int wickets1,
    required double overs1,
    required int runs2,
    required int wickets2,
    required double overs2,
    required DateTime completedAt,
  }) async {
    final matchData = {
      'team1_id': team1Id,
      'team2_id': team2Id,
      'team1_name': team1Name,
      'team2_name': team2Name,
      'overs': 20,
      'ground_type': 'turf',
      'ball_type': 'leather',
      'status': 'completed',
      'completed_at': completedAt.toIso8601String(),
      'started_at': completedAt.subtract(const Duration(hours: 3)).toIso8601String(),
      'winner_id': winnerId,
      'scorecard': {
        'team1_score': {
          'runs': runs1,
          'wickets': wickets1,
          'overs': overs1,
        },
        'team2_score': {
          'runs': runs2,
          'wickets': wickets2,
          'overs': overs2,
        },
        'current_innings': 2,
      },
      'created_by': _supabase.auth.currentUser?.id,
    };

    await matchRepo.createMatch(matchData);
  }
}
