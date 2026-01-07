import '../config/supabase_config.dart';
import '../models/academy_model.dart';

class AcademyRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<AcademyModel>> getAcademies({String? userId, int? limit}) async {
    try {
      dynamic query = _supabase.from('academies').select();

      if (userId != null) {
        query = query.eq('created_by', userId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return (response as List)
          .map((json) => AcademyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch academies: $e');
    }
  }

  Future<AcademyModel?> getAcademyById(String academyId) async {
    try {
      final response = await _supabase
          .from('academies')
          .select()
          .eq('id', academyId)
          .single();

      return AcademyModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<AcademyModel> createAcademy(Map<String, dynamic> academyData) async {
    try {
      final response = await _supabase
          .from('academies')
          .insert(academyData)
          .select()
          .single();

      return AcademyModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create academy: $e');
    }
  }

  Future<AcademyModel> updateAcademy(
      String academyId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('academies')
          .update(updates)
          .eq('id', academyId)
          .select()
          .single();

      return AcademyModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update academy: $e');
    }
  }

  Future<void> deleteAcademy(String academyId) async {
    try {
      await _supabase.from('academies').delete().eq('id', academyId);
    } catch (e) {
      throw Exception('Failed to delete academy: $e');
    }
  }
}

