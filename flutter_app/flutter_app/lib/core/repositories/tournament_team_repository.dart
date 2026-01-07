import '../config/supabase_config.dart';
import '../models/tournament_model.dart';

class TournamentTeamRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all teams for a tournament
  Future<List<TournamentTeamModel>> getTournamentTeams(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournament_teams')
          .select()
          .eq('tournament_id', tournamentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => TournamentTeamModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tournament teams: $e');
    }
  }

  /// Add a team to tournament (manual)
  Future<TournamentTeamModel> addTeamToTournament({
    required String tournamentId,
    required String teamName,
    String? teamLogo,
    String? captainId,
    String? captainName,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_teams')
          .insert({
            'tournament_id': tournamentId,
            'team_name': teamName,
            'team_logo': teamLogo,
            'join_type': 'manual',
            'captain_id': captainId,
            'captain_name': captainName,
          })
          .select()
          .single();

      return TournamentTeamModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add team to tournament: $e');
    }
  }

  /// Add a team via invite link
  Future<TournamentTeamModel> addTeamViaInvite({
    required String tournamentId,
    required String teamName,
    String? teamLogo,
    String? captainId,
    String? captainName,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_teams')
          .insert({
            'tournament_id': tournamentId,
            'team_name': teamName,
            'team_logo': teamLogo,
            'join_type': 'invite',
            'captain_id': captainId,
            'captain_name': captainName,
          })
          .select()
          .single();

      return TournamentTeamModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add team via invite: $e');
    }
  }

  /// Remove a team from tournament
  Future<void> removeTeamFromTournament(String teamId) async {
    try {
      await _supabase
          .from('tournament_teams')
          .delete()
          .eq('id', teamId);
    } catch (e) {
      throw Exception('Failed to remove team from tournament: $e');
    }
  }

  /// Get team count for a tournament
  Future<int> getTeamCount(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournament_teams')
          .select('id')
          .eq('tournament_id', tournamentId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get team count: $e');
    }
  }

  /// Check if team name already exists in tournament
  Future<bool> teamNameExists(String tournamentId, String teamName) async {
    try {
      final response = await _supabase
          .from('tournament_teams')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('team_name', teamName)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

