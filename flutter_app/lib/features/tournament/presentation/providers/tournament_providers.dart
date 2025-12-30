import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/tournament_model.dart';

/// Provider for tournament data
final tournamentProvider = FutureProvider.family<TournamentModel?, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return await repository.getTournamentById(tournamentId);
});

