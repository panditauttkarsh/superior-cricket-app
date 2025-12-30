import 'dart:async';
import '../config/supabase_config.dart';
import '../models/commentary_model.dart';

class CommentaryRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all commentary entries for a match, ordered by timestamp (newest first)
  Future<List<CommentaryModel>> getCommentaryByMatchId(String matchId) async {
    try {
      print('Commentary: Fetching all entries for matchId=$matchId');
      final response = await _supabase
          .from('commentary')
          .select()
          .eq('match_id', matchId)
          .order('over', ascending: false)
          .order('timestamp', ascending: false);

      final entries = (response as List)
          .map((json) => CommentaryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('Commentary: Fetched ${entries.length} entries from database');
      for (var entry in entries) {
        print('Commentary: DB Entry - ${entry.over} - ${entry.commentaryText}');
      }
      
      return entries;
    } catch (e, stackTrace) {
      print('Error fetching commentary: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Create a new commentary entry
  Future<CommentaryModel> createCommentary(CommentaryModel commentary) async {
    try {
      print('Commentary: Inserting entry - ${commentary.over} - ${commentary.commentaryText}');
      final response = await _supabase
          .from('commentary')
          .insert(commentary.toJson())
          .select()
          .single();

      final created = CommentaryModel.fromJson(response as Map<String, dynamic>);
      print('Commentary: Successfully inserted entry with id=${created.id}');
      return created;
    } catch (e, stackTrace) {
      print('Commentary: Error creating commentary: $e');
      print('Commentary: Stack trace: $stackTrace');
      throw Exception('Failed to create commentary: $e');
    }
  }

  /// Stream commentary updates for a match (real-time)
  /// On each change, refetch ALL entries to ensure complete list
  Stream<List<CommentaryModel>> streamCommentary(String matchId) {
    print('Commentary: Starting stream for matchId=$matchId');
    return _supabase
        .from('commentary')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .asyncMap((data) async {
          print('Commentary: Stream event received, data length: ${data.length}');
          // On each stream event, refetch ALL entries to get complete list
          final allEntries = await getCommentaryByMatchId(matchId);
          print('Commentary: Stream update - refetched ${allEntries.length} entries for matchId=$matchId');
          return allEntries;
        })
        .handleError((error, stackTrace) {
          print('Commentary: Stream error: $error');
          print('Commentary: Stack trace: $stackTrace');
          // Return empty list on error to prevent stream from closing
          return <CommentaryModel>[];
        });
  }

  /// Delete commentary entries for a match (useful for testing/reset)
  Future<void> deleteCommentaryByMatchId(String matchId) async {
    try {
      await _supabase.from('commentary').delete().eq('match_id', matchId);
    } catch (e) {
      throw Exception('Failed to delete commentary: $e');
    }
  }

  /// Delete a single commentary entry by ID (for undo functionality)
  Future<void> deleteCommentaryById(String commentaryId) async {
    try {
      await _supabase.from('commentary').delete().eq('id', commentaryId);
      print('Commentary: Deleted entry with id=$commentaryId');
    } catch (e) {
      throw Exception('Failed to delete commentary: $e');
    }
  }

  /// Get the last commentary entry for a match (for undo)
  Future<CommentaryModel?> getLastCommentary(String matchId) async {
    try {
      final response = await _supabase
          .from('commentary')
          .select()
          .eq('match_id', matchId)
          .order('timestamp', ascending: false)
          .order('over', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return CommentaryModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching last commentary: $e');
      return null;
    }
  }
}

