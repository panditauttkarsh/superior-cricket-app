import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/match_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/tournament_repository.dart';
import '../repositories/academy_repository.dart';
import '../repositories/shop_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/commentary_repository.dart';

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

