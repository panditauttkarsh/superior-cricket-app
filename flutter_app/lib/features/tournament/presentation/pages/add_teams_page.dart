import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../../core/models/team_model.dart';
import '../providers/tournament_providers.dart';
import '../providers/points_table_providers.dart';
import 'teams_tab.dart';

class AddTeamsPage extends ConsumerStatefulWidget {
  final String tournamentId;

  const AddTeamsPage({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<AddTeamsPage> createState() => _AddTeamsPageState();
}

class _AddTeamsPageState extends ConsumerState<AddTeamsPage> {
  bool _inviteLinkEnabled = true;
  File? _teamLogo;
  final _teamNameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<TeamModel> _userTeams = [];
  bool _isLoadingTeams = false;
  Set<String> _tournamentTeamNames = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserTeams();
      _loadTournamentTeams();
    });
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTeams() async {
    setState(() {
      _isLoadingTeams = true;
    });

    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final authState = ref.read(authStateProvider);
      final user = authState.user;

      if (user != null) {
        final teams = await teamRepo.getTeams(userId: user.id);
        if (mounted) {
          setState(() {
            _userTeams = teams;
            _isLoadingTeams = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTeams = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeams = false;
        });
      }
    }
  }

  Future<void> _loadTournamentTeams() async {
    try {
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final tournamentTeams = await teamRepo.getTournamentTeams(widget.tournamentId);
      if (mounted) {
        setState(() {
          _tournamentTeamNames = tournamentTeams.map((t) => t.teamName.toLowerCase()).toSet();
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _addExistingTeamToTournament(TeamModel team) async {
    // Check if team already exists in tournament
    if (_tournamentTeamNames.contains(team.name.toLowerCase())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This team is already in the tournament'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final authState = ref.read(authStateProvider);
      final user = authState.user;

      await teamRepo.addTeamToTournament(
        tournamentId: widget.tournamentId,
        teamName: team.name,
        teamLogo: team.logoUrl,
        captainId: user?.id,
        captainName: user?.name,
      );

      // Update local state
      _tournamentTeamNames.add(team.name.toLowerCase());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh tournament teams provider
        ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
        // Reload tournament teams to get updated list
        await _loadTournamentTeams();
        // Return success to parent
        if (context.mounted) {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add team: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleInviteLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null) {
        await tournamentRepo.toggleInviteLink(
          widget.tournamentId,
          !_inviteLinkEnabled,
        );
        setState(() {
          _inviteLinkEnabled = !_inviteLinkEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle invite link: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareInviteLink() async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null && tournament.inviteLink.isNotEmpty) {
        await Share.share(tournament.inviteLink);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share link: $e')),
        );
      }
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournament = await tournamentRepo.getTournamentById(widget.tournamentId);
      if (tournament != null && tournament.inviteLink.isNotEmpty) {
        await Share.share(
          tournament.inviteLink,
          subject: 'Join ${tournament.name} Tournament',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share via WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _pickTeamLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _teamLogo = File(pickedFile.path);
      });
    }
  }

  Future<void> _addTeamManually() async {
    if (_teamNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter team name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final storageService = ref.read(storageServiceProvider);
      final authState = ref.read(authStateProvider);
      final user = authState.user;

      String? logoUrl;
      if (_teamLogo != null) {
        // Generate a temporary ID for the team
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        logoUrl = await storageService.uploadTeamLogo(_teamLogo!, tempId);
      }

      // Check if team name already exists
      final teamNameExists = await teamRepo.teamNameExists(
        widget.tournamentId,
        _teamNameController.text.trim(),
      );

      if (teamNameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A team with this name already exists in the tournament'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      await teamRepo.addTeamToTournament(
        tournamentId: widget.tournamentId,
        teamName: _teamNameController.text.trim(),
        teamLogo: logoUrl,
        captainId: user?.id,
        captainName: user?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh tournament teams provider
        ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
        // Clear form
        final addedTeamName = _teamNameController.text.trim();
        _teamNameController.clear();
        _teamLogo = null;
        // Update local state
        _tournamentTeamNames.add(addedTeamName.toLowerCase());
        // Reload tournament teams to get updated list
        await _loadTournamentTeams();
        // Navigate back with success result
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add team: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Teams'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textMain,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tournamentAsync.when(
              data: (tournament) {
                if (tournament == null) {
                  return const Center(child: Text('Tournament not found'));
                }
                return _buildContent(tournament);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
    );
  }

  Widget _buildContent(TournamentModel tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Teams Section
          _buildMyTeamsSection(),
          const SizedBox(height: 24),

          // Add New Teams Section
          _buildAddNewTeamsSection(),
        ],
      ),
    );
  }


  Widget _buildMyTeamsSection() {
    final filteredTeams = _searchQuery.isEmpty
        ? _userTeams
        : _userTeams
            .where((team) => team.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    
    final defaultTeams = filteredTeams.take(3).toList();
    final hasMoreTeams = filteredTeams.length > 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Teams',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Quickly add teams from your network.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search team by name',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSec),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSec),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_isLoadingTeams)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_userTeams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: AppColors.textMeta,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No teams found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSec,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a team first to add it to the tournament',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMeta,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (defaultTeams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No teams match your search',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSec,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                ...defaultTeams.map((team) => _buildTeamRow(team)),
                if (hasMoreTeams)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showSeeMoreTeamsDialog(filteredTeams),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('See more'),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(TeamModel team) {
    final isAlreadyAdded = _tournamentTeamNames.contains(team.name.toLowerCase());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 20,
            child: Text(
              team.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.playerIds.length} players',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec,
                  ),
                ),
              ],
            ),
          ),
          isAlreadyAdded
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Added',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _addExistingTeamToTournament(team),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Add'),
                ),
        ],
      ),
    );
  }

  void _showSeeMoreTeamsDialog(List<TeamModel> allTeams) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String searchQuery = '';
          final filteredTeams = searchQuery.isEmpty
              ? allTeams
              : allTeams
                  .where((team) => team.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Teams',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search team by name',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSec),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSec),
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() {
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredTeams.isEmpty
                        ? Center(
                            child: Text(
                              'No teams match your search',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSec,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredTeams.length,
                            itemBuilder: (context, index) {
                              final team = filteredTeams[index];
                              final isAlreadyAdded = _tournamentTeamNames.contains(team.name.toLowerCase());
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.elevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      radius: 20,
                                      child: Text(
                                        team.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            team.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textMain,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${team.playerIds.length} players',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSec,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    isAlreadyAdded
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Added',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () async {
                                                    await _addExistingTeamToTournament(team);
                                                    if (mounted && context.mounted) {
                                                      Navigator.pop(context);
                                                      // Refresh parent screen
                                                      setState(() {});
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: const Text('Add'),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddNewTeamsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Teams',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      'Add one or more teams manually.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Team Logo
          GestureDetector(
            onTap: _pickTeamLogo,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.elevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: _teamLogo != null
                  ? ClipOval(
                      child: Image.file(_teamLogo!, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.textMeta,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Team Name
          TextField(
            controller: _teamNameController,
            decoration: const InputDecoration(
              labelText: 'Team Name',
              hintText: 'Enter team name',
            ),
          ),
          const SizedBox(height: 16),
          // Add Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTeamManually,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Team'),
            ),
          ),
        ],
      ),
    );
  }

}

