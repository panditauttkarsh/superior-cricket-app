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

  Future<PlayerModel?> getOrCreatePlayerByUserId(String userId) async {
    try {
      // 1. Try to get existing player already linked to this userId
      final linkedPlayer = await getPlayerByUserId(userId);
      if (linkedPlayer != null) return linkedPlayer;

      // 2. Get user info from profiles table to know who we are looking for
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return null;

      final name = profileResponse['full_name'] as String? ?? profileResponse['username'] as String? ?? 'Player';
      final email = profileResponse['email'] as String?;

      // 3. Check if a player record already exists for this name but without a user_id
      // (This happens when the player was created during scoring)
      final unlinkedPlayerResponse = await _supabase
          .from('players')
          .select()
          .ilike('name', name)
          .filter('user_id', 'is', null)
          .maybeSingle();

      if (unlinkedPlayerResponse != null) {
        final playerId = unlinkedPlayerResponse['id'] as String;
        // Link this existing player record to the current user
        await _supabase.from('players').update({
          'user_id': userId,
          'email': email,
          'profile_image_url': profileResponse['avatar_url'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', playerId);

        // Fetch and return the updated player
        final updatedPlayerResponse = await _supabase
            .from('players')
            .select()
            .eq('id', playerId)
            .single();
        return PlayerModel.fromJson(updatedPlayerResponse as Map<String, dynamic>);
      }

      // 4. If still not found, create a brand new player record
      final playerData = {
        'user_id': userId,
        'name': name,
        'email': email,
        'profile_image_url': profileResponse['avatar_url'],
        'total_matches': 0,
        'batting_stats': {
          'runs': 0,
          'balls': 0,
          'average': 0.0,
          'strike_rate': 0.0,
          'fifties': 0,
          'hundreds': 0,
          'catches': 0,
          'run_outs': 0,
          'stumpings': 0,
        },
        'bowling_stats': {
          'wickets': 0,
          'runs_conceded': 0,
          'average': 0.0,
          'economy': 0.0,
          'best_bowling': '-/-',
          'five_w': 0,
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final insertResponse = await _supabase.from('players').insert(playerData).select().single();
      return PlayerModel.fromJson(insertResponse as Map<String, dynamic>);
    } catch (e) {
      print('Error in getOrCreatePlayerByUserId: $e');
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

  Future<List<PlayerModel>> searchPlayers(String query) async {
    try {
      final response = await _supabase
          .from('players')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List)
          .map((json) => PlayerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching players: $e');
      return [];
    }
  }

  Future<void> updatePlayerAggregateStats(String playerId) async {
    try {
      // Fetch all MVP records for this player
      final response = await _supabase
          .from('player_mvp')
          .select()
          .eq('player_id', playerId);

      if (response == null || (response as List).isEmpty) return;

      final records = response as List<dynamic>;
      
      int totalMatches = records.length;
      int inningsPlayed = 0;
      int totalRuns = 0;
      int totalBallsFaced = 0;
      int totalWickets = 0;
      int totalRunsConceded = 0;
      int totalBallsBowled = 0;
      int totalCatches = 0;
      int totalRunOuts = 0;
      int totalStumpings = 0;
      int fifties = 0;
      int hundreds = 0;
      int fiveWickets = 0;
      String bestBowling = '-/-';
      int bestWickets = -1;
      int bestRuns = 1000;

      for (var record in records) {
        final rScored = record['runs_scored'] as int? ?? 0;
        final bFaced = record['balls_faced'] as int? ?? 0;
        
        totalRuns += rScored;
        totalBallsFaced += bFaced;
        
        if (bFaced > 0) {
          inningsPlayed++;
        }
        
        if (rScored >= 100) {
          hundreds++;
        } else if (rScored >= 50) {
          fifties++;
        }

        final wTaken = record['wickets_taken'] as int? ?? 0;
        final rConceded = record['runs_conceded'] as int? ?? 0;
        final bBowled = record['balls_bowled'] as int? ?? 0;
        
        totalWickets += wTaken;
        totalRunsConceded += rConceded;
        totalBallsBowled += bBowled;

        if (wTaken >= 5) {
          fiveWickets++;
        }
        
        // Track best bowling
        if (wTaken > bestWickets || (wTaken == bestWickets && rConceded < bestRuns)) {
          bestWickets = wTaken;
          bestRuns = rConceded;
          bestBowling = '$wTaken/$rConceded';
        }

        totalCatches += record['catches'] as int? ?? 0;
        totalRunOuts += record['run_outs'] as int? ?? 0;
        totalStumpings += record['stumpings'] as int? ?? 0;
      }

      // Calculate averages and rates
      // simplified batting avg: total runs / innings played (since we don't track is_out)
      double battingAverage = inningsPlayed > 0 ? totalRuns / inningsPlayed : 0.0;
      double strikeRate = totalBallsFaced > 0 ? (totalRuns / totalBallsFaced) * 100 : 0.0;
      double bowlingAverage = totalWickets > 0 ? totalRunsConceded / totalWickets : 0.0;
      double economy = totalBallsBowled > 0 ? (totalRunsConceded / (totalBallsBowled / 6)) : 0.0;

      await _supabase.from('players').update({
        'total_matches': totalMatches,
        'batting_stats': {
          'runs': totalRuns,
          'balls': totalBallsFaced,
          'average': battingAverage,
          'strike_rate': strikeRate,
          'fifties': fifties,
          'hundreds': hundreds,
          'catches': totalCatches,
          'run_outs': totalRunOuts,
          'stumpings': totalStumpings,
        },
        'bowling_stats': {
          'wickets': totalWickets,
          'runs_conceded': totalRunsConceded,
          'average': bowlingAverage,
          'economy': economy,
          'best_bowling': bestBowling,
          'five_w': fiveWickets,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', playerId);

      print('✅ Updated aggregate stats for player $playerId');
    } catch (e) {
      print('Error updating player aggregate stats: $e');
    }
  }
}
