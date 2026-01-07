import '../config/supabase_config.dart';
import '../models/shop_item_model.dart';

class ShopRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<ShopItemModel>> getShopItems({
    String? category,
    int? limit,
    String? searchQuery,
  }) async {
    try {
      dynamic query = _supabase.from('shop_items').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return (response as List)
          .map((json) => ShopItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shop items: $e');
    }
  }

  Future<ShopItemModel?> getShopItemById(String itemId) async {
    try {
      final response = await _supabase
          .from('shop_items')
          .select()
          .eq('id', itemId)
          .single();

      return ShopItemModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

