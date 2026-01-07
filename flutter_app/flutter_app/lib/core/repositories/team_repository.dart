import '../config/supabase_config.dart';
import '../models/team_model.dart';

class TeamRepository {
  final _supabase = SupabaseConfig.client;

  // Get all teams
  Future<List<TeamModel>> getTeams({
    String? userId,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('teams').select();

      if (userId != null) {
        query = query.eq('created_by', userId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return (response as List)
          .map((json) => TeamModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch teams: $e');
    }
  }

  // Get team by ID
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final response = await _supabase
          .from('teams')
          .select()
          .eq('id', teamId)
          .single();

      return TeamModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Create a new team
  Future<TeamModel> createTeam(Map<String, dynamic> teamData) async {
    try {
      // Ensure player_ids is properly formatted as an array
      if (teamData.containsKey('player_ids') && teamData['player_ids'] is List) {
        final playerIds = teamData['player_ids'] as List;
        // Convert to proper format for Supabase UUID array
        teamData['player_ids'] = playerIds.isEmpty ? [] : playerIds;
      } else if (!teamData.containsKey('player_ids')) {
        teamData['player_ids'] = [];
      }

      final response = await _supabase
          .from('teams')
          .insert(teamData)
          .select()
          .single();

      return TeamModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Provide more detailed error message
      final errorMsg = e.toString();
      if (errorMsg.contains('duplicate key') || errorMsg.contains('already exists')) {
        throw Exception('A team with this name already exists');
      } else if (errorMsg.contains('permission denied') || errorMsg.contains('RLS')) {
        throw Exception('Permission denied. Please check your database policies.');
      } else if (errorMsg.contains('player_ids')) {
        throw Exception('Invalid player IDs format');
      }
      throw Exception('Failed to create team: $errorMsg');
    }
  }

  // Update team
  Future<TeamModel> updateTeam(String teamId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('teams')
          .update(updates)
          .eq('id', teamId)
          .select()
          .single();

      return TeamModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  // Add player to team
  Future<void> addPlayerToTeam(String teamId, String playerId) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) throw Exception('Team not found');

      final updatedPlayerIds = [...team.playerIds, playerId];
      await _supabase
          .from('teams')
          .update({'player_ids': updatedPlayerIds})
          .eq('id', teamId);
    } catch (e) {
      throw Exception('Failed to add player to team: $e');
    }
  }

  // Remove player from team
  Future<void> removePlayerFromTeam(String teamId, String playerId) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) throw Exception('Team not found');

      final updatedPlayerIds = team.playerIds.where((id) => id != playerId).toList();
      await _supabase
          .from('teams')
          .update({'player_ids': updatedPlayerIds})
          .eq('id', teamId);
    } catch (e) {
      throw Exception('Failed to remove player from team: $e');
    }
  }

  // Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _supabase.from('teams').delete().eq('id', teamId);
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }
}

