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

  // Search tournaments by name or description
  Future<List<TournamentModel>> searchTournaments(String query, {
    String? status,
    String? format,
  }) async {
    try {
      dynamic queryBuilder = _supabase.from('tournaments').select();

      // Apply status filter if provided
      if (status != null && status != 'All') {
        if (status == 'past') {
          queryBuilder = queryBuilder.in_('status', ['completed', 'locked']);
        } else {
          queryBuilder = queryBuilder.eq('status', status.toLowerCase());
        }
      }

      // Apply format filter if provided
      if (format != null && format != 'All') {
        queryBuilder = queryBuilder.eq('format', format);
      }

      queryBuilder = queryBuilder.order('start_date', ascending: true);

      final response = await queryBuilder;
      
      // Filter results by search query (client-side filtering)
      final tournaments = (response as List)
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (query.isEmpty) {
        return tournaments;
      }

      final lowercaseQuery = query.toLowerCase();
      return tournaments.where((tournament) {
        final name = tournament.name.toLowerCase();
        final description = (tournament.description ?? '').toLowerCase();
        return name.contains(lowercaseQuery) || description.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tournaments: $e');
    }
  }

  // Get user's latest created tournament
  Future<TournamentModel?> getUserLatestTournament(String userId) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) return null;
      return TournamentModel.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

