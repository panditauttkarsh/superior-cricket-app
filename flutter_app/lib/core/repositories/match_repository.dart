import '../config/supabase_config.dart';
import '../models/match_model.dart';

class MatchRepository {
  final _supabase = SupabaseConfig.client;

  // Get all matches
  Future<List<MatchModel>> getMatches({
    String? status,
    String? userId,
    int? limit,
    bool includePlayerMatches = false, // If true, also include matches where user is a player
  }) async {
    try {
      dynamic query = _supabase.from('matches').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (userId != null) {
        if (includePlayerMatches) {
          // Get matches where user is a player (from match_players table)
          final playerMatchesResponse = await _supabase
              .from('match_players')
              .select('match_id')
              .eq('player_id', userId);
          
          final playerMatchIds = (playerMatchesResponse as List)
              .map((e) => e['match_id'] as String)
              .toList();
          
          // Query matches: created by user, OR user is in team, OR user is a player
          if (playerMatchIds.isNotEmpty) {
            query = query.or(
              'team1_id.eq.$userId,team2_id.eq.$userId,created_by.eq.$userId,id.in.(${playerMatchIds.join(',')})'
            );
          } else {
            query = query.or('team1_id.eq.$userId,team2_id.eq.$userId,created_by.eq.$userId');
          }
        } else {
          query = query.or('team1_id.eq.$userId,team2_id.eq.$userId,created_by.eq.$userId');
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch matches: $e');
    }
  }
  
  // Get matches where user is a player (from match_players table)
  Future<List<MatchModel>> getPlayerMatches(String playerId) async {
    try {
      // Get match IDs where user is a player
      final playerMatchesResponse = await _supabase
          .from('match_players')
          .select('match_id')
          .eq('player_id', playerId);
      
      final matchIds = (playerMatchesResponse as List)
          .map((e) => e['match_id'] as String)
          .toList();
      
      if (matchIds.isEmpty) {
        return [];
      }
      
      // Fetch match details - build OR query for multiple IDs
      dynamic query = _supabase.from('matches').select();
      
      if (matchIds.length == 1) {
        query = query.eq('id', matchIds[0]);
      } else {
        // Build OR condition: id = id1 OR id = id2 OR ...
        final orConditions = matchIds.map((id) => 'id.eq.$id').join(',');
        query = query.or(orConditions);
      }
      
      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch player matches: $e');
    }
  }

  // Get match by ID
  Future<MatchModel?> getMatchById(String matchId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select()
          .eq('id', matchId)
          .single();

      return MatchModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Stream match by ID for real-time updates
  Stream<MatchModel?> streamMatchById(String matchId) {
    try {
      return _supabase
          .from('matches')
          .stream(primaryKey: ['id'])
          .eq('id', matchId)
          .map((data) {
            if (data.isEmpty) return null;
            try {
              return MatchModel.fromJson(data[0] as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing match data: $e');
              return null;
            }
          })
          .handleError((error) {
            print('Error in match stream: $error');
            return null;
          });
    } catch (e) {
      print('Error creating stream for match $matchId: $e');
      // Fallback: return a stream that fetches once
      return Stream.value(null).asyncMap((_) async {
        try {
          return await getMatchById(matchId);
        } catch (e) {
          print('Error fetching match: $e');
          return null;
        }
      });
    }
  }

  // Create a new match
  Future<MatchModel> createMatch(Map<String, dynamic> matchData) async {
    try {
      final response = await _supabase
          .from('matches')
          .insert(matchData)
          .select()
          .single();

      return MatchModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  // Update match
  Future<MatchModel> updateMatch(String matchId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('matches')
          .update(updates)
          .eq('id', matchId)
          .select()
          .single();

      return MatchModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update match: $e');
    }
  }

  // Update match scorecard
  Future<void> updateScorecard(String matchId, Map<String, dynamic> scorecard) async {
    try {
      await _supabase
          .from('matches')
          .update({'scorecard': scorecard, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', matchId);
    } catch (e) {
      throw Exception('Failed to update scorecard: $e');
    }
  }

  // Delete match
  Future<void> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches').delete().eq('id', matchId);
    } catch (e) {
      throw Exception('Failed to delete match: $e');
    }
  }
}

