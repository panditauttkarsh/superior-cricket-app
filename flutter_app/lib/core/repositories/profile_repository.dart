import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Profile model for user profiles
class ProfileModel {
  final String id; // Internal user ID (hidden from UI)
  final String username; // Public username
  final String? name;
  final String? email;
  final String? profileImageUrl;
  final String? role; // 'player', 'coach', 'admin', etc.
  final String? subscriptionPlan;

  ProfileModel({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.profileImageUrl,
    this.role,
    this.subscriptionPlan,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'name' and 'full_name' fields (schema migration)
    final name = json['full_name'] as String? ?? json['name'] as String?;
    
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      name: name,
      email: json['email'] as String?,
      profileImageUrl: json['avatar_url'] as String? ?? json['profile_image_url'] as String?,
      role: json['role'] as String?,
      subscriptionPlan: json['subscription_plan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
      'role': role,
      'subscription_plan': subscriptionPlan,
    };
  }
}

class ProfileRepository {
  final _supabase = SupabaseConfig.client;

  Future<ProfileModel?> getProfileById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      print('Error getting profile by id: $e');
      return null;
    }
  }

  /// Fetch profile by username (case-insensitive)
  /// Also tries email and name as fallbacks unless exactOnly is true
  /// Returns null if user not found
  Future<ProfileModel?> getProfileByUsername(String username, {bool exactOnly = false}) async {
    try {
      // Remove @ if present
      final cleanUsername = username.startsWith('@') 
          ? username.substring(1) 
          : username.trim();
      
      print('Profile: Searching for username: $cleanUsername');
      
      // Try 1: Exact username match (case-insensitive)
      var response = await _supabase
          .from('profiles')
          .select()
          .ilike('username', cleanUsername)
          .limit(1)
          .maybeSingle();

      // Try 2: If not found, try partial username match (handles typos) - skip if exactOnly is true
      if (response == null && !exactOnly) {
        print('Profile: Exact match not found, trying partial match...');
        final partialMatches = await _supabase
            .from('profiles')
            .select()
            .ilike('username', '$cleanUsername%')
            .limit(5);
        
        if (partialMatches.isNotEmpty) {
          // Return the first partial match (closest match)
          response = partialMatches[0] as Map<String, dynamic>;
          print('Profile: Found partial match: ${response['username']}');
        }
      }
 
      // Try 3: Search by email - skip if exactOnly is true
      if (response == null && !exactOnly && cleanUsername.contains('@')) {
        print('Profile: Trying email search...');
        response = await _supabase
            .from('profiles')
            .select()
            .ilike('email', cleanUsername)
            .limit(1)
            .maybeSingle();
      }
 
      // Try 4: Search by name - skip if exactOnly is true
      if (response == null && !exactOnly) {
        print('Profile: Trying name search...');
        // Clean the input similar to how usernames are generated
        final cleanedName = cleanUsername.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        
        // Search in full_name field (name column might not exist)
        final nameMatches = await _supabase
            .from('profiles')
            .select()
            .ilike('full_name', '%$cleanedName%')
            .limit(5);
        
        if (nameMatches.isNotEmpty) {
          // Find the best match (username that contains the cleaned name)
          for (var match in nameMatches) {
            final matchUsername = (match['username'] as String? ?? '').toLowerCase();
            if (matchUsername.contains(cleanedName) || cleanedName.contains(matchUsername)) {
              response = match as Map<String, dynamic>;
              print('Profile: Found name match: ${response['username']}');
              break;
            }
          }
          
          // If no good match, return first result
          if (response == null && nameMatches.isNotEmpty) {
            response = nameMatches[0] as Map<String, dynamic>;
            print('Profile: Found name match (first result): ${response['username']}');
          }
        }
      }

      if (response == null) {
        print('Profile: No user found with username/email/name: $cleanUsername');
        print('Profile: Debug - Check if user exists in profiles table with this username');
        return null;
      }

      final profile = ProfileModel.fromJson(response as Map<String, dynamic>);
      print('Profile: Found user - ${profile.name} (username: ${profile.username}, email: ${profile.email})');
      return profile;
    } catch (e, stackTrace) {
      print('Profile: Error fetching profile by username: $e');
      print('Profile: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Search profiles by username (for autocomplete)
  /// Returns list of matching profiles
  Future<List<ProfileModel>> searchProfilesByUsername(String query) async {
    try {
      final cleanQuery = query.startsWith('@') ? query.substring(1) : query;
      
      if (cleanQuery.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '$cleanQuery%') // Starts with query
          .limit(10);

      return (response as List)
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Profile: Error searching profiles: $e');
      return [];
    }
  }

  Future<void> updateSubscriptionPlan(String userId, String plan) async {
    try {
      await _supabase
          .from('profiles')
          .update({'subscription_plan': plan})
          .eq('id', userId);
    } catch (e) {
      print('Error updating subscription plan: $e');
      // rethrow; // Optional: suppress or rethrow. I'll print.
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      print('Profile: Updating image URL for user $userId to $imageUrl');
      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);
      print('Profile: Image URL updated successfully');
    } catch (e) {
      print('Error updating profile image: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatars/$fileName';

    print('Profile: Uploading image to $filePath');
    
    try {
      await _supabase.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
    } on StorageException catch (e) {
      // If bucket not found, try to create it
      if (e.statusCode == '404' || e.message.contains('Bucket not found')) {
        print('Profile: Bucket "avatars" not found. Attempting to create it...');
        try {
          await _supabase.storage.createBucket('avatars', const BucketOptions(public: true));
          print('Profile: Bucket "avatars" created successfully. Retrying upload...');
          
          await _supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
        } catch (createError) {
          print('Profile: Failed to create bucket: $createError');
          throw 'The "avatars" storage bucket does not exist. Please create a public bucket named "avatars" in your Supabase Dashboard to enable image uploads.';
        }
      } else if (e.statusCode == '403' || e.message.contains('row-level security')) {
        throw 'Permission denied. Please ensure you have "insert" permissions for the "avatars" bucket in Supabase Storage policies.';
      } else {
        rethrow;
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }

    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
    print('Profile: Image uploaded, public URL: $imageUrl');
    
    return imageUrl;
  }
}

