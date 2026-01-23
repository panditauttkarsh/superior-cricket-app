import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../repositories/match_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/tournament_repository.dart';
import '../repositories/academy_repository.dart';
import '../repositories/shop_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/commentary_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/match_player_repository.dart';
import '../repositories/tournament_team_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/mvp_repository.dart';
import '../models/player_model.dart';
import '../services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository();
});

final academyRepositoryProvider = Provider<AcademyRepository>((ref) {
  return AcademyRepository();
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository();
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

final commentaryRepositoryProvider = Provider<CommentaryRepository>((ref) {
  return CommentaryRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final matchPlayerRepositoryProvider = Provider<MatchPlayerRepository>((ref) {
  return MatchPlayerRepository();
});

final tournamentTeamRepositoryProvider = Provider<TournamentTeamRepository>((ref) {
  return TournamentTeamRepository();
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});

final mvpRepositoryProvider = Provider<MvpRepository>((ref) {
  return MvpRepository(Supabase.instance.client);
});

final playerDataProvider = FutureProvider<PlayerModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null) return null;
  
  final playerRepo = ref.watch(playerRepositoryProvider);
  return await playerRepo.getOrCreatePlayerByUserId(user.id);
});

