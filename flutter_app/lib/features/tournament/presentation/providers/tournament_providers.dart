import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/tournament_model.dart';

/// Provider for tournament data
final tournamentProvider = FutureProvider.family<TournamentModel?, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return await repository.getTournamentById(tournamentId);
});

/// Provider for all tournaments list
final tournamentsListProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return await repository.getTournaments();
});

/// State class for tournament filters
class TournamentFilters {
  final String searchQuery;
  final String status; // 'All', 'Live Now', 'Upcoming', etc.
  final String? format; // 'T20', 'ODI', 'Test', etc.

  TournamentFilters({
    this.searchQuery = '',
    this.status = 'All',
    this.format,
  });

  TournamentFilters copyWith({
    String? searchQuery,
    String? status,
    String? format,
  }) {
    return TournamentFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      format: format ?? this.format,
    );
  }
}

/// State notifier for managing tournament filters
class TournamentFiltersNotifier extends StateNotifier<TournamentFilters> {
  TournamentFiltersNotifier() : super(TournamentFilters());

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  void updateFormat(String? format) {
    state = state.copyWith(format: format);
  }

  void reset() {
    state = TournamentFilters();
  }
}

/// Provider for tournament filters state
final tournamentFiltersProvider = StateNotifierProvider<TournamentFiltersNotifier, TournamentFilters>((ref) {
  return TournamentFiltersNotifier();
});

/// Provider for filtered tournaments based on search and filters
final filteredTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  final filters = ref.watch(tournamentFiltersProvider);
  
  // Map UI status to database status
  String? dbStatus;
  if (filters.status == 'Live Now') {
    dbStatus = 'ongoing';
  } else if (filters.status == 'Upcoming') {
    dbStatus = 'upcoming';
  } else if (filters.status != 'All') {
    dbStatus = filters.status.toLowerCase();
  }

  return await repository.searchTournaments(
    filters.searchQuery,
    status: dbStatus,
    format: filters.format,
  );
});
