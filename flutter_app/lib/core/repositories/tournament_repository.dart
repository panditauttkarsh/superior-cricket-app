import '../config/supabase_config.dart';
import '../models/tournament_model.dart';

class TournamentRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all tournaments
  Future<List<TournamentModel>> getTournaments({
    String? status,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('tournaments').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('start_date', ascending: true);

      final response = await query;
      return (response as List)
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tournaments: $e');
    }
  }

  /// Get tournaments created by a specific user
  Future<List<TournamentModel>> getUserTournaments(String userId) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user tournaments: $e');
    }
  }

  /// Get user's most recent tournament (for navigation logic)
  Future<TournamentModel?> getUserLatestTournament(String userId) async {
    try {
      final tournaments = await getUserTournaments(userId);
      return tournaments.isNotEmpty ? tournaments.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Get tournament by ID
  Future<TournamentModel?> getTournamentById(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('id', tournamentId)
          .single();

      return TournamentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get tournament by invite token
  Future<TournamentModel?> getTournamentByInviteToken(String token) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('invite_link_token', token)
          .eq('invite_link_enabled', true)
          .single();

      return TournamentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Create a new tournament
  Future<TournamentModel> createTournament(Map<String, dynamic> tournamentData) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      return TournamentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create tournament: $e');
    }
  }

  /// Update tournament
  Future<TournamentModel> updateTournament(
      String tournamentId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .update(updates)
          .eq('id', tournamentId)
          .select()
          .single();

      return TournamentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update tournament: $e');
    }
  }

  /// Toggle invite link enabled/disabled
  Future<TournamentModel> toggleInviteLink(String tournamentId, bool enabled) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .update({'invite_link_enabled': enabled})
          .eq('id', tournamentId)
          .select()
          .single();

      return TournamentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to toggle invite link: $e');
    }
  }

  /// Delete tournament
  Future<void> deleteTournament(String tournamentId) async {
    try {
      await _supabase.from('tournaments').delete().eq('id', tournamentId);
    } catch (e) {
      throw Exception('Failed to delete tournament: $e');
    }
  }
}

