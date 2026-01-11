import '../config/supabase_config.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final _supabase = SupabaseConfig.client;

  Future<PlayerModel?> getPlayerByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return PlayerModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting player by user id: $e');
      return null;
    }
  }

  Future<PlayerModel?> getPlayerById(String id) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return PlayerModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error getting player by id: $e');
      return null;
    }
  }

  Future<List<PlayerModel>> getAllPlayers({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .limit(limit);

      return (response as List)
          .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all players: $e');
      return [];
    }
  }
}
