import '../config/supabase_config.dart';
import '../models/match_model.dart';

class MatchRepository {
  final _supabase = SupabaseConfig.client;

  // Get all matches
  Future<List<MatchModel>> getMatches({
    String? status,
    String? userId,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('matches').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (userId != null) {
        query = query.or('team1_id.eq.$userId,team2_id.eq.$userId,created_by.eq.$userId');
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

