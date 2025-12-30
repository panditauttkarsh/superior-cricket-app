import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service for uploading files to Supabase Storage
class StorageService {
  final _supabase = SupabaseConfig.client;

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    required String bucket,
    required String path, // e.g., 'tournaments/banners/'
    String? fileName, // Optional custom filename, otherwise uses timestamp
  }) async {
    try {
      // Generate filename if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final finalFileName = fileName ?? '${timestamp}.$extension';
      final fullPath = '$path$finalFileName';

      // Upload file
      await _supabase.storage.from(bucket).upload(
        fullPath,
        imageFile,
        fileOptions: const FileOptions(
          upsert: true, // Overwrite if exists
        ),
      );

      // Get public URL
      final url = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteImage({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Upload tournament banner
  Future<String> uploadTournamentBanner(File imageFile, String tournamentId) async {
    return uploadImage(
      imageFile: imageFile,
      bucket: 'tournaments',
      path: 'banners/',
      fileName: '$tournamentId-banner',
    );
  }

  /// Upload tournament logo
  Future<String> uploadTournamentLogo(File imageFile, String tournamentId) async {
    return uploadImage(
      imageFile: imageFile,
      bucket: 'tournaments',
      path: 'logos/',
      fileName: '$tournamentId-logo',
    );
  }

  /// Upload team logo
  Future<String> uploadTeamLogo(File imageFile, String teamId) async {
    return uploadImage(
      imageFile: imageFile,
      bucket: 'teams',
      path: 'logos/',
      fileName: '$teamId-logo',
    );
  }
}

