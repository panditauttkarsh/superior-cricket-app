import 'package:flutter/material.dart';

class PlayerSelectionDialog extends StatefulWidget {
  final String myTeam;
  final String opponentTeam;
  final List<String> myTeamPlayers;
  final List<String> opponentTeamPlayers;
  final String tossWinner;
  final String tossChoice;
  final Function(String striker, String nonStriker, String bowler) onStartMatch;

  const PlayerSelectionDialog({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    required this.myTeamPlayers,
    required this.opponentTeamPlayers,
    required this.tossWinner,
    required this.tossChoice,
    required this.onStartMatch,
  });

  @override
  State<PlayerSelectionDialog> createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  String? _striker;
  String? _nonStriker;
  String? _bowler;
  
  List<String> get _battingTeamPlayers {
    return widget.tossChoice == 'Bat' ? widget.myTeamPlayers : widget.opponentTeamPlayers;
  }
  
  List<String> get _bowlingTeamPlayers {
    return widget.tossChoice == 'Bat' ? widget.opponentTeamPlayers : widget.myTeamPlayers;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Players',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.tossWinner} won toss & chose to ${widget.tossChoice}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Striker Selection
            _buildPlayerSelector(
              'Striker',
              _striker,
              _battingTeamPlayers,
              (player) => setState(() => _striker = player),
            ),
            const SizedBox(height: 16),
            
            // Non-Striker Selection
            _buildPlayerSelector(
              'Non-Striker',
              _nonStriker,
              _battingTeamPlayers.where((p) => p != _striker).toList(),
              (player) => setState(() => _nonStriker = player),
            ),
            const SizedBox(height: 16),
            
            // Bowler Selection
            _buildPlayerSelector(
              'Bowler',
              _bowler,
              _bowlingTeamPlayers,
              (player) => setState(() => _bowler = player),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _striker != null && _nonStriker != null && _bowler != null
                  ? () {
                      widget.onStartMatch(_striker!, _nonStriker!, _bowler!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Start Match',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelector(String label, String? selected, List<String> players, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            hint: Text(
              'Select $label',
              style: TextStyle(color: Colors.grey[400]),
            ),
            items: players.map((player) {
              return DropdownMenuItem(
                value: player,
                child: Text(player),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSelect(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

