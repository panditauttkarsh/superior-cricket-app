import '../config/supabase_config.dart';

class MatchPlayerRepository {
  final _supabase = SupabaseConfig.client;

  /// Add a player to a match team
  /// This will trigger the notification automatically via database trigger
  Future<void> addPlayerToMatch({
    required String matchId,
    required String playerId,
    required String teamType, // 'team1' or 'team2'
    String? role,
    bool isCaptain = false,
    bool isWicketKeeper = false,
    String? addedBy,
  }) async {
    try {
      await _supabase.from('match_players').insert({
        'match_id': matchId,
        'player_id': playerId,
        'team_type': teamType,
        'role': role,
        'is_captain': isCaptain,
        'is_wicket_keeper': isWicketKeeper,
        'added_by': addedBy,
      });
      print('MatchPlayer: Added player $playerId to match $matchId (team: $teamType)');
    } catch (e) {
      print('Error adding player to match: $e');
      rethrow;
    }
  }

  /// Add multiple players to a match team
  /// Accepts either List<Map> (from squad pages) or List<String> (player names)
  Future<void> addPlayersToMatch({
    required String matchId,
    required dynamic players, // Can be List<Map> or List<String>
    required String teamType,
    String? addedBy,
  }) async {
    try {
      List<Map<String, dynamic>> playersData = [];
      
      if (players is List<Map<String, dynamic>>) {
        // Players from squad pages (have id, role, etc.)
        playersData = players.map((player) {
          final playerId = player['id'] as String?;
          if (playerId == null || playerId.isEmpty) {
            print('MatchPlayer: Skipping player without ID: ${player['name']}');
            return null;
          }
          return {
            'match_id': matchId,
            'player_id': playerId,
            'team_type': teamType,
            'role': player['role'] as String?,
            'is_captain': player['isCaptain'] as bool? ?? false,
            'is_wicket_keeper': player['isWicketKeeper'] as bool? ?? false,
            'added_by': addedBy,
          };
        }).whereType<Map<String, dynamic>>().toList();
      } else if (players is List<String>) {
        // Just player names - need to look up by username/name
        // For now, skip these as we need profile IDs
        print('MatchPlayer: Cannot add players by name only. Need profile IDs.');
        return;
      }
      
      if (playersData.isEmpty) {
        print('MatchPlayer: No valid players to add');
        return;
      }

      await _supabase.from('match_players').insert(playersData);
      print('MatchPlayer: Added ${playersData.length} players to match $matchId (team: $teamType)');
    } catch (e) {
      print('Error adding players to match: $e');
      // Don't rethrow - allow match creation to continue even if player saving fails
    }
  }

  /// Get all players for a match
  Future<List<Map<String, dynamic>>> getMatchPlayers(String matchId) async {
    try {
      final response = await _supabase
          .from('match_players')
          .select('''
            *,
            profiles:player_id (
              id,
              username,
              full_name,
              email,
              avatar_url
            )
          ''')
          .eq('match_id', matchId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching match players: $e');
      return [];
    }
  }

  /// Get matches for a player
  Future<List<Map<String, dynamic>>> getPlayerMatches(String playerId) async {
    try {
      final response = await _supabase
          .from('match_players')
          .select('''
            *,
            matches:match_id (
              id,
              team1_name,
              team2_name,
              status,
              scheduled_at,
              created_at
            )
          ''')
          .eq('player_id', playerId)
          .order('added_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching player matches: $e');
      return [];
    }
  }

  /// Remove a player from a match
  Future<void> removePlayerFromMatch({
    required String matchId,
    required String playerId,
    required String teamType,
  }) async {
    try {
      await _supabase
          .from('match_players')
          .delete()
          .eq('match_id', matchId)
          .eq('player_id', playerId)
          .eq('team_type', teamType);
    } catch (e) {
      print('Error removing player from match: $e');
      rethrow;
    }
  }
}

