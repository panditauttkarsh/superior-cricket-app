import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/providers/repository_providers.dart';

class MyTeamSquadPage extends ConsumerStatefulWidget {
  final String teamName;
  final List<String> initialPlayers;

  const MyTeamSquadPage({
    super.key,
    required this.teamName,
    this.initialPlayers = const [],
  });

  @override
  ConsumerState<MyTeamSquadPage> createState() => _MyTeamSquadPageState();
}

class _MyTeamSquadPageState extends ConsumerState<MyTeamSquadPage> {
  List<Map<String, dynamic>> _players = [];
  
  // Track player IDs to prevent duplicates
  Set<String> _addedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _players = widget.initialPlayers.isEmpty
        ? [
            {
              'name': 'Virat Kohli',
              'role': 'Batsman • Right Hand',
              'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCue7JILQgAOG1HN-g0zpWwLDcKjkdQj_pOnWKWFIFyFrX-ejDvRzkeTv3dWiOles3U16S_4j7uKT473oHYw_KdJgCKUJXllot8uF-bH3f1qwH1B8PmyeunyNp_MeJkgpAe_BZoQ-sNktD2Oi6Bz0plf5iTmlAW3bYKq_0ejgcK30lH-c3d3UQA26Y1aVrKw772bimkLUyt2VSD4g3JUbwDkkFsrbrakcNMWD17qx2HHRQKz4cFB22TG_e5qRaMq-moAMlRzJYDypoZ',
              'isCaptain': true,
              'isWicketKeeper': false,
            },
            {
              'name': 'Rohit Sharma',
              'role': 'Batsman • Right Hand',
              'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBZLASm_isHmi9Wefa-zpfJFgO35leEU31KnoiB1vFUbVHjiiXuoYw9Hrut_IuWOUr8tVXj72NQW_AzJL7_ldAU6vpU0abidukOetRmWGoFwaC13gvFffUAgW9OWRO0Dn1dnciK0V2L3J6J-gt7Qxhh_j0pxyaAnuG6OkAy_ztIkm41LT10A7MbVn3_xlNnyLhEhlfyHn49pk-kji87bWg2LQtuhMyDNEYOUEMZUq0iK5inGSAGznVe8ojC9E-0Z7fr5Tj4d2o0IZJS',
              'isCaptain': false,
              'isWicketKeeper': false,
            },
            {
              'name': 'MS Dhoni',
              'role': 'Wicket Keeper',
              'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB44Snd4kgImiJFb5P-UcbcTzgSlkUl7nyzMoXsfhhIFCO21E-8_jSbAqZKVDUYlkQGbl29IgpkjT8jXfzVWuS0Qz_f6hEd1uOg2Og3Lm6dEPwYP6eiwPiw-LNUv9fQ-3doxZWGFrUls11u58KCaoqYT_zTBeF8g9ukX_YvddYk1l6HGNMz1TRAO0QpEmnzTxjbYJMPFY-22tbQ0YHGnA40Khi7g_kDInNnvtsqmXKg2ghO2I3L6aKJmkMcRX4l6BAKiwcTehipisWz',
              'isCaptain': false,
              'isWicketKeeper': true,
            },
            {
              'name': 'Hardik Pandya',
              'role': 'All Rounder',
              'avatar': null,
              'isCaptain': false,
              'isWicketKeeper': false,
            },
            {
              'name': 'Jasprit Bumrah',
              'role': 'Bowler • Fast',
              'avatar': null,
              'isCaptain': false,
              'isWicketKeeper': false,
            },
          ]
        : widget.initialPlayers.map((name) => {
            'name': name,
            'role': 'Player',
            'avatar': null,
            'isCaptain': false,
            'isWicketKeeper': false,
          }).toList();
  }

  Future<void> _addPlayer() async {
    final usernameController = TextEditingController();
    final roleController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Player by Username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Enter player username',
                  hintText: '@utkarsh_pandita or utkarsh_pandita',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                onSubmitted: isLoading ? null : (value) async {
                  if (value.trim().isNotEmpty) {
                    await _handleAddPlayer(
                      usernameController.text.trim(),
                      roleController.text.trim(),
                      setDialogState,
                      (loading) => setDialogState(() => isLoading = loading),
                      (error) => setDialogState(() => errorMessage = error),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Role (optional, e.g., Batsman, Bowler)',
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (usernameController.text.trim().isNotEmpty) {
                  await _handleAddPlayer(
                    usernameController.text.trim(),
                    roleController.text.trim(),
                    setDialogState,
                    (loading) => setDialogState(() => isLoading = loading),
                    (error) => setDialogState(() => errorMessage = error),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleAddPlayer(
    String usernameInput,
    String roleInput,
    StateSetter setDialogState,
    Function(bool) setIsLoading,
    Function(String?) setError,
  ) async {
    setIsLoading(true);
    setError(null);
    
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfileByUsername(usernameInput);
      
      if (profile == null) {
        setError('Player with this username does not exist');
        setIsLoading(false);
        return;
      }
      
      // Check for duplicate
      if (_addedPlayerIds.contains(profile.id)) {
        setError('Player already added to this team');
        setIsLoading(false);
        return;
      }
      
      // Add player
      setState(() {
        _addedPlayerIds.add(profile.id);
        _players.add({
          'id': profile.id, // Internal ID (hidden from UI)
          'name': profile.name ?? profile.username,
          'username': profile.username, // Public username
          'role': roleInput.isEmpty ? 'Player' : roleInput,
          'avatar': profile.profileImageUrl,
          'isCaptain': false,
          'isWicketKeeper': false,
        });
      });
      
      Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${profile.name ?? profile.username} added to ${widget.teamName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setError('Error adding player: $e');
      setIsLoading(false);
    }
  }

  void _editPlayer(int index) {
    final player = _players[index];
    final nameController = TextEditingController(text: player['name']);
    final roleController = TextEditingController(text: player['role']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _players[index] = {
                  ...player,
                  'name': nameController.text.trim(),
                  'role': roleController.text.trim(),
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePlayer(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Are you sure you want to remove ${_players[index]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final playerId = _players[index]['id'] as String?;
                if (playerId != null) {
                  _addedPlayerIds.remove(playerId);
                }
                _players.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const Text(
                    'My Team Squad',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Team Info Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Name',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.teamName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'T20',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Season 5',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_players.length}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/15',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Players Selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Starting XI Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Starting XI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Drag to reorder',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Player List
                    ...List.generate(_players.length, (index) {
                      final player = _players[index];
                      return _buildPlayerCard(player, index);
                    }),

                    const SizedBox(height: 16),

                    // Add New Player Button
                    InkWell(
                      onTap: _addPlayer,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_add,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Add New Player',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Return players list
          final players = _players.map((p) => p['name'] as String).toList();
          context.pop(players);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: player['avatar'] != null
                    ? ClipOval(
                        child: Image.network(
                          player['avatar'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
              ),
              if (player['isCaptain'] == true)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (player['isWicketKeeper'] == true)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      'WK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player['role'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                onPressed: () => _editPlayer(index),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Color(0xFFC72B32),
                    size: 18,
                  ),
                ),
                onPressed: () => _deletePlayer(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

