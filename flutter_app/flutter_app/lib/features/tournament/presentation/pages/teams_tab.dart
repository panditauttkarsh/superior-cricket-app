import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/tournament_model.dart';
import '../providers/tournament_providers.dart';

/// Provider for tournament teams
final tournamentTeamsProvider = FutureProvider.family<List<TournamentTeamModel>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentTeamRepositoryProvider);
  return await repository.getTournamentTeams(tournamentId);
});

class TeamsTab extends ConsumerWidget {
  final String tournamentId;

  const TeamsTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return teamsAsync.when(
      data: (teams) {
        return tournamentAsync.when(
          data: (tournament) {
            if (tournament == null) {
              return const Center(child: Text('Tournament not found'));
            }
            return _buildContent(context, ref, teams, tournament);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TournamentTeamModel> teams,
    TournamentModel tournament,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${teams.length} Teams',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () {
                  // Edit teams
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Invite Captains Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite Captains to Add Teams',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save time! Share this link with captains, and they\'ll add their teams and players.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSec,
                  ),
                ),
                const SizedBox(height: 20),
                // Arrow pointing down
                Center(
                  child: Icon(
                    Icons.arrow_downward,
                    color: AppColors.textMeta,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // Share Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/tournament/$tournamentId/add-teams');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'SHARE WITH CAPTAINS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ADD MANUALLY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 16),

          // Teams List
          if (teams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppColors.textMeta,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No teams added yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...teams.map((team) => _buildTeamCard(context, team)),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, TournamentTeamModel team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: team.teamLogo != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(team.teamLogo!),
                radius: 24,
              )
            : CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 24,
                child: Text(
                  team.teamName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          team.teamName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        subtitle: Text(
          'Joined via ${team.joinType}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSec,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textMeta,
        ),
        onTap: () {
          // Navigate to team details
        },
      ),
    );
  }
}

