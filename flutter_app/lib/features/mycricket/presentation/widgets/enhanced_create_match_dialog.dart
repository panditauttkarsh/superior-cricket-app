import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/scorecard_page.dart';
import 'player_selection_dialog.dart';

class EnhancedCreateMatchDialog extends StatefulWidget {
  const EnhancedCreateMatchDialog({super.key});

  @override
  State<EnhancedCreateMatchDialog> createState() => _EnhancedCreateMatchDialogState();
}

class _EnhancedCreateMatchDialogState extends State<EnhancedCreateMatchDialog> {
  int _currentStep = 0;
  final TextEditingController _myTeamController = TextEditingController();
  final TextEditingController _opponentTeamController = TextEditingController();
  String? _overs;
  String? _groundType;
  String? _ballType;
  double _tossPrice = 0.0;
  String? _tossWinner;
  String? _tossChoice; // 'Bat' or 'Bowl'
  
  List<String> _myTeamPlayers = [];
  List<String> _opponentTeamPlayers = [];
  
  final List<String> _oversOptions = ['5', '10', '15', '20', '25', '50'];
  final List<String> _groundTypes = ['Turf', 'Cemented', 'Grassed', 'Synthetic', 'Clay'];
  final List<String> _ballTypes = ['Leather', 'Tennis', 'Rubber', 'Cork'];

  @override
  void dispose() {
    _myTeamController.dispose();
    _opponentTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create New Match',
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
            const SizedBox(height: 16),
            _buildStepIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildStepContent(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() => _currentStep--);
                    },
                    child: const Text('Back', style: TextStyle(color: Colors.white)),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _canProceed()
                      ? () {
                          if (_currentStep < 6) {
                            setState(() => _currentStep++);
                          } else {
                            _handleToss();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                  child: Text(
                    _currentStep < 6 ? 'Next' : 'Start Match',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _myTeamController.text.isNotEmpty && _opponentTeamController.text.isNotEmpty;
      case 1:
        return _myTeamPlayers.length >= 2 && _opponentTeamPlayers.length >= 2;
      case 2:
        return _overs != null;
      case 3:
        return _groundType != null;
      case 4:
        return _ballType != null;
      case 5:
        return _tossPrice > 0;
      case 6:
        return _tossWinner != null && _tossChoice != null;
      default:
        return false;
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
            decoration: BoxDecoration(
              color: index <= _currentStep
                  ? const Color(0xFF1B5E20)
                  : Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTeamSelectionStep();
      case 1:
        return _buildSquadManagementStep();
      case 2:
        return _buildOversSelectionStep();
      case 3:
        return _buildGroundSelectionStep();
      case 4:
        return _buildBallSelectionStep();
      case 5:
        return _buildTossPriceStep();
      case 6:
        return _buildTossResultStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTeamSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register Teams',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _myTeamController,
          decoration: InputDecoration(
            labelText: 'My Team Name',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _opponentTeamController,
          decoration: InputDecoration(
            labelText: 'Opponent Team Name',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSquadManagementStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Manage Squads',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddPlayerDialog(true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('My Team'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddPlayerDialog(false),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Opponent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // My Team Players
        Text(
          '${_myTeamController.text.isNotEmpty ? _myTeamController.text : "My Team"} (${_myTeamPlayers.length})',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._myTeamPlayers.asMap().entries.map((entry) {
          return _buildPlayerCard(entry.value, true, entry.key);
        }),
        if (_myTeamPlayers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No players added yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        const SizedBox(height: 24),
        // Opponent Team Players
        Text(
          '${_opponentTeamController.text.isNotEmpty ? _opponentTeamController.text : "Opponent Team"} (${_opponentTeamPlayers.length})',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._opponentTeamPlayers.asMap().entries.map((entry) {
          return _buildPlayerCard(entry.value, false, entry.key);
        }),
        if (_opponentTeamPlayers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No players added yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerCard(String playerName, bool isMyTeam, int index) {
    return Card(
      color: const Color(0xFF334155),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text(
          playerName,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              if (isMyTeam) {
                _myTeamPlayers.removeAt(index);
              } else {
                _opponentTeamPlayers.removeAt(index);
              }
            });
          },
        ),
      ),
    );
  }

  void _showAddPlayerDialog(bool isMyTeam) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Add Player to ${isMyTeam ? _myTeamController.text : _opponentTeamController.text}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Player Name',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (isMyTeam) {
                    _myTeamPlayers.add(controller.text);
                  } else {
                    _opponentTeamPlayers.add(controller.text);
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOversSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Overs',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _oversOptions.map((over) {
            final isSelected = _overs == over;
            return ChoiceChip(
              label: Text('$over Overs'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _overs = selected ? over : null);
              },
              selectedColor: const Color(0xFF1B5E20),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroundSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Ground Type',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._groundTypes.map((type) {
          final isSelected = _groundType == type;
          return Card(
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF334155),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(type, style: const TextStyle(color: Colors.white)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.white)
                  : null,
              onTap: () {
                setState(() => _groundType = type);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBallSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Ball Type',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._ballTypes.map((type) {
          final isSelected = _ballType == type;
          return Card(
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF334155),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(type, style: const TextStyle(color: Colors.white)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.white)
                  : null,
              onTap: () {
                setState(() => _groundType = type);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTossPriceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toss Price',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter Toss Price (₹)',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _tossPrice = double.tryParse(value) ?? 0.0;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Match Summary',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildSummaryItem('My Team', _myTeamController.text.isNotEmpty ? _myTeamController.text : 'Not set'),
        _buildSummaryItem('Opponent', _opponentTeamController.text.isNotEmpty ? _opponentTeamController.text : 'Not set'),
        _buildSummaryItem('My Team Players', '${_myTeamPlayers.length}'),
        _buildSummaryItem('Opponent Players', '${_opponentTeamPlayers.length}'),
        _buildSummaryItem('Overs', _overs ?? 'Not set'),
        _buildSummaryItem('Ground', _groundType ?? 'Not set'),
        _buildSummaryItem('Ball Type', _ballType ?? 'Not set'),
        _buildSummaryItem('Toss Price', '₹${_tossPrice.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildTossResultStep() {
    if (_tossWinner == null) {
      // Simulate toss
      final teams = [_myTeamController.text, _opponentTeamController.text];
      _tossWinner = teams[DateTime.now().millisecond % 2];
      _tossChoice = ['Bat', 'Bowl'][DateTime.now().millisecond % 2];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Toss Result',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Text(
                '$_tossWinner won the toss!',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Chose to: $_tossChoice',
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Match will start with these settings',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleToss() {
    Navigator.pop(context);
    
    // Show player selection dialog for match start
    showDialog(
      context: context,
      builder: (context) => PlayerSelectionDialog(
        myTeam: _myTeamController.text,
        opponentTeam: _opponentTeamController.text,
        myTeamPlayers: _myTeamPlayers,
        opponentTeamPlayers: _opponentTeamPlayers,
        tossWinner: _tossWinner!,
        tossChoice: _tossChoice!,
        onStartMatch: (striker, nonStriker, bowler) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScorecardPage(
                matchId: DateTime.now().millisecondsSinceEpoch.toString(),
                team1: _tossChoice == 'Bat' ? _myTeamController.text : _opponentTeamController.text,
                team2: _tossChoice == 'Bat' ? _opponentTeamController.text : _myTeamController.text,
                overs: int.tryParse(_overs ?? '20') ?? 20,
              ),
            ),
          );
        },
      ),
    );
  }
}

