import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyTeamSquadPage extends ConsumerStatefulWidget {
  final String teamName;
  final List<Map<String, dynamic>> initialPlayers;

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
    // Use initial players if provided, otherwise use defaults
    _players = widget.initialPlayers.isNotEmpty
        ? List<Map<String, dynamic>>.from(widget.initialPlayers)
        : widget.initialPlayers.isEmpty
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
    String selectedRole = 'Batsman';
    bool isLoading = false;
    String? errorMessage;
    
    await showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Player',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    enabled: !isLoading,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g. utkarsh_pandita',
                      prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SELECT ROLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleSelectionCard(
                          label: 'Batsman',
                          icon: Icons.sports_cricket,
                          isSelected: selectedRole == 'Batsman',
                          onTap: () => setDialogState(() => selectedRole = 'Batsman'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleSelectionCard(
                          label: 'Bowler',
                          icon: Icons.sports_baseball,
                          isSelected: selectedRole == 'Bowler',
                          onTap: () => setDialogState(() => selectedRole = 'Bowler'),
                        ),
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (usernameController.text.trim().isNotEmpty) {
                          await _handleAddPlayer(
                            usernameController.text.trim(),
                            selectedRole,
                            setDialogState,
                            (loading) => setDialogState(() => isLoading = loading),
                            (error) => setDialogState(() => errorMessage = error),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Add to Squad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      final profile = await profileRepo.getProfileByUsername(usernameInput, exactOnly: true);
      
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
    String selectedRole = player['role'] as String;
    if (selectedRole != 'Batsman' && selectedRole != 'Bowler') {
      selectedRole = 'Batsman'; // Default if unknown
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Player',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Player Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ROLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleSelectionCard(
                        label: 'Batsman',
                        icon: Icons.sports_cricket,
                        isSelected: selectedRole == 'Batsman',
                        onTap: () => setDialogState(() => selectedRole = 'Batsman'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleSelectionCard(
                        label: 'Bowler',
                        icon: Icons.sports_baseball,
                        isSelected: selectedRole == 'Bowler',
                        onTap: () => setDialogState(() => selectedRole = 'Bowler'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _players[index] = {
                          ...player,
                          'name': nameController.text.trim(),
                          'role': selectedRole,
                        };
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Premium Mesh Header
          _buildPremiumHeader(),

          // Starting XI Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STARTING XI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: AppColors.primary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            '${_players.length}/15',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).scale(),
                  ],
                ),
                const SizedBox(height: 16),

                // Player List with Staggered Animations
                ..._players.asMap().entries.map((entry) {
                  return _buildPlayerCard(entry.value, entry.key)
                      .animate()
                      .fadeIn(delay: (100 * entry.key).ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
                }),

                const SizedBox(height: 16),

                // Add New Player Button - Redesigned
                _buildAddPlayerButton()
                    .animate()
                    .fadeIn(delay: (100 * _players.length + 100).ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB().animate().scale(delay: 800.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Elements
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderCircleButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => context.pop(),
                      ),
                      const Text(
                        'TEAM SQUAD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn().slideY(begin: -0.5, end: 0),
                      _buildHeaderCircleButton(
                        icon: Icons.more_vert,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOME TEAM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 1,
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 4),
                            Text(
                              widget.teamName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildAddPlayerButton() {
    return GestureDetector(
      onTap: _addPlayer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Player',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Find players by their unique username',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => context.pop(_players),
        backgroundColor: AppColors.primary,
        elevation: 0,
        label: const Text(
          'DONE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    final bool isBatsman = player['role'].toString().toLowerCase().contains('batsman');
    final Color accentColor = isBatsman ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editPlayer(index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar with Gradient Ring
                  Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [accentColor.withOpacity(0.7), accentColor.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: player['avatar'] != null
                                ? Image.network(
                                    player['avatar'] as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(player),
                                  )
                                : _buildPlaceholder(player),
                          ),
                        ),
                      ),
                      if (player['isCaptain'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Text('C', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Player Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['name'] as String,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                player['role'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      _buildActionIcon(
                        icon: Icons.edit_note_rounded,
                        color: Colors.indigo,
                        onTap: () => _editPlayer(index),
                      ),
                      const SizedBox(width: 8),
                      _buildActionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: () => _deletePlayer(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Map<String, dynamic> player) {
    final initials = (player['name'] as String).split(' ').take(2).map((e) => e[0]).join().toUpperCase();
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _RoleSelectionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

