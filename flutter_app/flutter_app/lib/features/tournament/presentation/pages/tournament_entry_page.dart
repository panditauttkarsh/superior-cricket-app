import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';

/// Entry page that checks if user has tournament and navigates accordingly
class TournamentEntryPage extends ConsumerStatefulWidget {
  const TournamentEntryPage({super.key});

  @override
  ConsumerState<TournamentEntryPage> createState() => _TournamentEntryPageState();
}

class _TournamentEntryPageState extends ConsumerState<TournamentEntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  Future<void> _checkAndNavigate() async {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    
    if (user == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final latestTournament = await tournamentRepo.getUserLatestTournament(user.id);

      if (mounted) {
        if (latestTournament == null) {
          // No tournament exists, go to Add Tournament
          context.go('/tournament/add');
        } else {
          // Tournament exists, go to Tournament Home
          context.go('/tournament/${latestTournament.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        // On error, go to Add Tournament
        context.go('/tournament/add');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

