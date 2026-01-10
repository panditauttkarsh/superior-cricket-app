import '../config/supabase_config.dart';
import '../models/tournament_model.dart';

class TournamentRepository {
  final _supabase = SupabaseConfig.client;

  // Get all tournaments
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

  // Get tournament by ID
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

  // Create a new tournament
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

  // Update tournament
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

  // Register team for tournament
  Future<void> registerTeamForTournament(String tournamentId, String teamId) async {
    try {
      await _supabase.from('tournament_registrations').insert({
        'tournament_id': tournamentId,
        'team_id': teamId,
        'registered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to register team: $e');
    }
  }

  // Delete tournament
  Future<void> deleteTournament(String tournamentId) async {
    try {
      await _supabase.from('tournaments').delete().eq('id', tournamentId);
    } catch (e) {
      throw Exception('Failed to delete tournament: $e');
    }
  }
  // Toggle invite link
  Future<void> toggleInviteLink(String tournamentId, bool enabled) async {
    try {
      await _supabase.from('tournaments').update({
        'invite_link_enabled': enabled,
        'invite_link': enabled
            ? 'https://pitchpoint.app/tournament/$tournamentId'
            : '',
      }).eq('id', tournamentId);
    } catch (e) {
      throw Exception('Failed to toggle invite link: $e');
    }
  }
}

