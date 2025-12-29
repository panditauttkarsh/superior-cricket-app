import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class OpponentTeamSquadPage extends StatefulWidget {
  final String teamName;
  final List<String> initialPlayers;

  const OpponentTeamSquadPage({
    super.key,
    required this.teamName,
    this.initialPlayers = const [],
  });

  @override
  State<OpponentTeamSquadPage> createState() => _OpponentTeamSquadPageState();
}

class _OpponentTeamSquadPageState extends State<OpponentTeamSquadPage> {
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _players = widget.initialPlayers.isEmpty
        ? [
            {
              'name': 'Virat K.',
              'role': 'Top Order Batter',
              'initials': 'VK',
            },
            {
              'name': 'Rohit S.',
              'role': 'Opener • Captain',
              'initials': 'RS',
            },
            {
              'name': 'Jasprit J.',
              'role': 'Fast Bowler',
              'initials': 'JJ',
            },
            {
              'name': 'Hardik P.',
              'role': 'All-Rounder',
              'initials': 'HP',
            },
          ]
        : widget.initialPlayers.map((name) {
            final parts = name.split(' ');
            final initials = parts.length > 1
                ? '${parts[0][0]}${parts[1][0]}'
                : (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
            return {
              'name': name,
              'role': 'Player',
              'initials': initials,
            };
          }).toList();
  }

  void _addPlayer() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Player'),
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
              if (nameController.text.trim().isNotEmpty) {
                final name = nameController.text.trim();
                final parts = name.split(' ');
                final initials = parts.length > 1
                    ? '${parts[0][0]}${parts[1][0]}'
                    : (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
                setState(() {
                  _players.add({
                    'name': name,
                    'role': roleController.text.trim().isEmpty
                        ? 'Player'
                        : roleController.text.trim(),
                    'initials': initials,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
              final name = nameController.text.trim();
              final parts = name.split(' ');
              final initials = parts.length > 1
                  ? '${parts[0][0]}${parts[1][0]}'
                  : (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
              setState(() {
                _players[index] = {
                  ...player,
                  'name': name,
                  'role': roleController.text.trim(),
                  'initials': initials,
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
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6).withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF205A28)),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                    ).createShader(bounds),
                    child: const Text(
                      'OPPONENT TEAM SQUAD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Team Info Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
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
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.teamName,
                            style: const TextStyle(
                              fontSize: 28,
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
                                child: Text(
                                  '${_players.length}/15 Players',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC72B32).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Unverified',
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC72B32), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.teamName.length >= 2 
                              ? widget.teamName.substring(0, 2).toUpperCase()
                              : widget.teamName.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFC72B32),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Squad Members Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                          ).createShader(bounds),
                          child: const Text(
                            'SQUAD MEMBERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                            ).createShader(bounds),
                            child: const Icon(Icons.sort, size: 16, color: Colors.white),
                          ),
                          label: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                            ).createShader(bounds),
                            child: const Text(
                              'Sort by Role',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Player List
                    ...List.generate(_players.length, (index) {
                      final player = _players[index];
                      return _buildPlayerCard(player, index);
                    }),

                    const SizedBox(height: 12),

                    // Quick Add Player Button
                    InkWell(
                      onTap: _addPlayer,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF205A28).withOpacity(0.3),
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
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
                              ).createShader(bounds),
                              child: const Text(
                                'Quick Add Player',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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
      // Removed FloatingActionButton (plus icon) as requested
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6).withOpacity(0.9),
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: InkWell(
          onTap: () {
            final players = _players.map((p) => p['name'] as String).toList();
            context.pop(players);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Save Opponent Squad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
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
          // Avatar with Initials
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player['initials'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player['role'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
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
                icon: const Icon(Icons.edit, color: Color(0xFF1E3A5F), size: 20),
                onPressed: () => _editPlayer(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFC72B32), size: 20),
                onPressed: () => _deletePlayer(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

