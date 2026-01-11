import 'package:superior_cricket_app/core/repositories/tournament_repository.dart';

/// Helper class to seed test tournament data
class TournamentTestData {
  final TournamentRepository _repository;

  TournamentTestData(this._repository);

  Future<void> seedTestTournaments() async {
    final testTournaments = [
      {
        'name': 'Premier Championship League',
        'description': 'The biggest T20 tournament of the year',
        'image_url': 'https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=400',
        'start_date': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 45)).toIso8601String(),
        'status': 'registration_open',
        'total_teams': 64,
        'registered_teams': 32,
        'prize_pool': 500000.0,
        'location': 'Mumbai, India',
        'category': 'T20',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Super Sixes League',
        'description': 'Weekend special cricket tournament for all',
        'image_url': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=400',
        'start_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
        'status': 'registration_open',
        'total_teams': 500,
        'registered_teams': 120,
        'prize_pool': 0.0,
        'location': 'Delhi, India',
        'category': 'T20',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Global Cricket Cup',
        'description': 'International ODI tournament',
        'image_url': 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=400',
        'start_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
        'status': 'upcoming',
        'total_teams': 16,
        'registered_teams': 8,
        'prize_pool': 1000000.0,
        'location': 'Bangalore, India',
        'category': 'ODI',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'City Masters League',
        'description': 'Local city-level cricket championship',
        'image_url': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400',
        'start_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'status': 'ongoing',
        'total_teams': 32,
        'registered_teams': 32,
        'prize_pool': 50000.0,
        'location': 'Pune, India',
        'category': 'T20',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Youth Cricket Festival',
        'description': 'Tournament for young cricket enthusiasts',
        'image_url': 'https://images.unsplash.com/photo-1593766787879-e8c78e09cec1?w=400',
        'start_date': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 35)).toIso8601String(),
        'status': 'registration_open',
        'total_teams': 24,
        'registered_teams': 10,
        'prize_pool': 25000.0,
        'location': 'Kolkata, India',
        'category': 'T20',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    try {
      for (final tournament in testTournaments) {
        await _repository.createTournament(tournament);
      }
      print('✅ Successfully seeded ${testTournaments.length} test tournaments');
    } catch (e) {
      print('❌ Error seeding tournaments: $e');
    }
  }
}
