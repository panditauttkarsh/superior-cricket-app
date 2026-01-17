import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mvp_model.dart';

/// Repository for MVP (Most Valuable Player) data operations
class MvpRepository {
  final SupabaseClient _supabase;

  MvpRepository(this._supabase);

  // ==================== CREATE ====================

  /// Save player MVP data to database
  Future<PlayerMvpModel> saveMvpData(PlayerMvpModel mvpData) async {
    try {
      final response = await _supabase
          .from('player_mvp')
          .upsert(mvpData.toJson())
          .select()
          .single();

      return PlayerMvpModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save MVP data: $e');
    }
  }

  /// Save multiple player MVP data (batch operation)
  Future<List<PlayerMvpModel>> saveBatchMvpData(
    List<PlayerMvpModel> mvpDataList,
  ) async {
    try {
      final jsonList = mvpDataList.map((mvp) => mvp.toJson()).toList();
      
      final response = await _supabase
          .from('player_mvp')
          .upsert(jsonList)
          .select();

      return (response as List)
          .map((json) => PlayerMvpModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to save batch MVP data: $e');
    }
  }

  // ==================== READ ====================

  /// Get MVP data for a specific match
  Future<List<PlayerMvpModel>> getMatchMvpData(String matchId) async {
    try {
      final response = await _supabase
          .from('player_mvp')
          .select()
          .eq('match_id', matchId)
          .order('total_mvp', ascending: false);

      return (response as List)
          .map((json) => PlayerMvpModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get match MVP data: $e');
    }
  }

  /// Get Player of the Match
  Future<PlayerMvpModel?> getPlayerOfTheMatch(String matchId) async {
    try {
      final response = await _supabase
          .from('player_mvp')
          .select()
          .eq('match_id', matchId)
          .eq('is_player_of_the_match', true)
          .maybeSingle();

      if (response == null) return null;
      return PlayerMvpModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get Player of the Match: $e');
    }
  }

  /// Get top performers for a match
  Future<List<PlayerMvpModel>> getTopPerformers(
    String matchId, {
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('player_mvp')
          .select()
          .eq('match_id', matchId)
          .order('total_mvp', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PlayerMvpModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get top performers: $e');
    }
  }

  /// Get player's MVP history
  Future<List<PlayerMvpModel>> getPlayerMvpHistory(
    String playerId, {
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('player_mvp')
          .select()
          .eq('player_id', playerId)
          .order('calculated_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => PlayerMvpModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get player MVP history: $e');
    }
  }

  /// Get tournament MVP leaderboard
  Future<List<Map<String, dynamic>>> getTournamentMvpLeaderboard(
    String tournamentId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_mvp_leaderboard')
          .select()
          .eq('tournament_id', tournamentId)
          .order('total_mvp_points', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get tournament MVP leaderboard: $e');
    }
  }

  /// Get player's all-time MVP stats
  Future<Map<String, dynamic>?> getPlayerMvpStats(String playerId) async {
    try {
      final response = await _supabase
          .from('player_mvp_stats')
          .select()
          .eq('player_id', playerId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get player MVP stats: $e');
    }
  }

  /// Get top MVP players (all time)
  Future<List<Map<String, dynamic>>> getTopMvpPlayers({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('player_mvp_stats')
          .select()
          .order('total_mvp_points', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get top MVP players: $e');
    }
  }

  /// Get most POTM awards
  Future<List<Map<String, dynamic>>> getMostPotmAwards({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('player_mvp_stats')
          .select()
          .order('potm_count', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get most POTM awards: $e');
    }
  }

  // ==================== UPDATE ====================

  /// Update Player of the Match using database function
  Future<void> updatePlayerOfTheMatch(String matchId) async {
    try {
      await _supabase.rpc('update_player_of_the_match', params: {
        'match_uuid': matchId,
      });
    } catch (e) {
      throw Exception('Failed to update Player of the Match: $e');
    }
  }

  // ==================== DELETE ====================

  /// Delete MVP data for a match
  Future<void> deleteMatchMvpData(String matchId) async {
    try {
      await _supabase
          .from('player_mvp')
          .delete()
          .eq('match_id', matchId);
    } catch (e) {
      throw Exception('Failed to delete match MVP data: $e');
    }
  }

  /// Delete player's MVP data
  Future<void> deletePlayerMvpData(String playerId, String matchId) async {
    try {
      await _supabase
          .from('player_mvp')
          .delete()
          .eq('player_id', playerId)
          .eq('match_id', matchId);
    } catch (e) {
      throw Exception('Failed to delete player MVP data: $e');
    }
  }

  // ==================== STREAM ====================

  /// Stream match MVP data (real-time updates)
  Stream<List<PlayerMvpModel>> streamMatchMvpData(String matchId) {
    return _supabase
        .from('player_mvp')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('total_mvp', ascending: false)
        .map((data) => data
            .map((json) => PlayerMvpModel.fromJson(json))
            .toList());
  }

  /// Stream Player of the Match (real-time)
  Stream<PlayerMvpModel?> streamPlayerOfTheMatch(String matchId) {
    return _supabase
        .from('player_mvp')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter for this match and POTM
          final potmList = data.where((json) => 
            json['match_id'] == matchId && 
            json['is_player_of_the_match'] == true
          ).toList();
          
          if (potmList.isEmpty) return null;
          return PlayerMvpModel.fromJson(potmList.first);
        });
  }

  // ==================== ANALYTICS ====================

  /// Get MVP trends for a player (last N matches)
  Future<List<double>> getPlayerMvpTrend(
    String playerId, {
    int matchCount = 10,
  }) async {
    try {
      final response = await _supabase
          .from('player_mvp')
          .select('total_mvp')
          .eq('player_id', playerId)
          .order('calculated_at', ascending: false)
          .limit(matchCount);

      return (response as List)
          .map((json) => (json['total_mvp'] as num).toDouble())
          .toList();
    } catch (e) {
      throw Exception('Failed to get player MVP trend: $e');
    }
  }

  /// Get average MVP by match type
  Future<Map<String, double>> getAverageMvpByMatchType() async {
    try {
      // This would require joining with matches table
      // Implementation depends on your match_type field
      throw UnimplementedError('Implement based on your match schema');
    } catch (e) {
      throw Exception('Failed to get average MVP by match type: $e');
    }
  }

  /// Get all MVP data for a tournament (all players across all matches)
  Future<List<PlayerMvpModel>> getTournamentMvpData(String tournamentId) async {
    try {
      print('🏆 Fetching tournament MVP data for: $tournamentId');
      
      // Get all matches for the tournament
      final matchesResponse = await _supabase
          .from('matches')
          .select('id, status')
          .eq('tournament_id', tournamentId);

      print('📋 Matches response: $matchesResponse');

      if (matchesResponse == null || (matchesResponse as List).isEmpty) {
        print('❌ No matches found for tournament: $tournamentId');
        return [];
      }

      final allMatches = matchesResponse as List;
      print('📊 Total matches in tournament: ${allMatches.length}');
      
      // Filter only completed matches
      final completedMatches = allMatches.where((match) => match['status'] == 'completed').toList();
      print('✅ Completed matches: ${completedMatches.length}');

      if (completedMatches.isEmpty) {
        print('⚠️ No completed matches found');
        return [];
      }

      final matchIds = completedMatches
          .map((match) => match['id'] as String)
          .toList();

      print('🎯 Fetching MVP data for match IDs: $matchIds');

      // Get all MVP data for these matches
      final response = await _supabase
          .from('player_mvp')
          .select()
          .inFilter('match_id', matchIds)
          .order('total_mvp', ascending: false);

      print('📈 MVP data response: ${response?.length ?? 0} records');

      if (response == null || (response as List).isEmpty) {
        print('❌ No MVP data found for completed matches');
        return [];
      }

      final mvpList = (response as List)
          .map((json) => PlayerMvpModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('🎉 Successfully fetched ${mvpList.length} MVP records');
      return mvpList;
    } catch (e) {
      print('❌ Error fetching tournament MVP data: $e');
      throw Exception('Failed to get tournament MVP data: $e');
    }
  }
}
