import 'package:flutter/material.dart';
import '../pages/scorecard_page.dart';

class CreateMatchDialog extends StatefulWidget {
  const CreateMatchDialog({super.key});

  @override
  State<CreateMatchDialog> createState() => _CreateMatchDialogState();
}

class _CreateMatchDialogState extends State<CreateMatchDialog> {
  int _currentStep = 0;
  String? _myTeam;
  String? _opponentTeam;
  String? _overs;
  String? _groundType;
  String? _ballType;
  double _tossPrice = 0.0;

  final List<String> _oversOptions = ['5', '10', '15', '20', '25', '50'];
  final List<String> _groundTypes = ['Turf', 'Cemented', 'Grassed'];
  final List<String> _ballTypes = ['Leather', 'Tennis', 'Rubber'];

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
            const SizedBox(height: 24),
            _buildStepIndicator(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildStepContent(),
            ),
            const SizedBox(height: 24),
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
                  onPressed: _currentStep < 5
                      ? () {
                          setState(() => _currentStep++);
                        }
                      : () {
                          _createMatch();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                  child: Text(
                    _currentStep < 5 ? 'Next' : 'Create Match',
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

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
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
      default:
        return const SizedBox();
    }
  }

  Widget _buildTeamSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Teams',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'My Team',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => _myTeam = value,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Opponent Team',
            labelStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => _opponentTeam = value,
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
            ElevatedButton.icon(
              onPressed: () {
                // Add player
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return Card(
                color: const Color(0xFF334155),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    'Player ${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Delete player
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
                setState(() => _ballType = type);
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
            _tossPrice = double.tryParse(value) ?? 0.0;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Match Summary',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildSummaryItem('My Team', _myTeam ?? 'Not set'),
        _buildSummaryItem('Opponent', _opponentTeam ?? 'Not set'),
        _buildSummaryItem('Overs', _overs ?? 'Not set'),
        _buildSummaryItem('Ground', _groundType ?? 'Not set'),
        _buildSummaryItem('Ball Type', _ballType ?? 'Not set'),
        _buildSummaryItem('Toss Price', '₹${_tossPrice.toStringAsFixed(0)}'),
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

  void _createMatch() {
    // Simulate toss
    final tossWinner = _myTeam ?? 'Team A';
    final tossChoice = ['Bat', 'Bowl'][DateTime.now().millisecond % 2];
    
    Navigator.pop(context);
    
    // Show toss result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Toss Result', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$tossWinner won the toss!',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chose to: $tossChoice',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to scorecard
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScorecardPage(
                    matchId: '1',
                    team1: _myTeam ?? 'Team A',
                    team2: _opponentTeam ?? 'Team B',
                    overs: int.tryParse(_overs ?? '20') ?? 20,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text('Start Match', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

