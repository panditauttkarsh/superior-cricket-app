import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class PlayerComparisonDialog extends ConsumerStatefulWidget {
  final PlayerModel currentPlayer;
  const PlayerComparisonDialog({super.key, required this.currentPlayer});

  @override
  ConsumerState<PlayerComparisonDialog> createState() => _PlayerComparisonDialogState();
}

class _PlayerComparisonDialogState extends ConsumerState<PlayerComparisonDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<PlayerModel> _searchResults = [];
  bool _isSearching = false;
  PlayerModel? _comparisonPlayer;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final playerRepo = ref.read(playerRepositoryProvider);
      final results = await playerRepo.searchPlayers(query);
      
      setState(() {
        // Filter out the current player from search results
        _searchResults = results.where((p) => p.id != widget.currentPlayer.id).toList();
        _isSearching = false;
        if (_searchResults.isEmpty) {
          _errorMessage = 'No players found matching "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching players: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _comparisonPlayer == null ? 'Compare Players' : 'Comparison',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                if (_comparisonPlayer != null)
                  TextButton(
                    onPressed: () => setState(() => _comparisonPlayer = null),
                    child: const Text('Change'),
                  )
                else
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _comparisonPlayer == null 
                  ? _buildSearchState() 
                  : _buildComparisonState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchState() {
    return KeyedSubtree(
      key: const ValueKey('search'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search player name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchPlayers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (val) {
                // Debounce simple version
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == val) {
                    _searchPlayers(val);
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final player = _searchResults[index];
                            return _buildPlayerCard(player);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Search for another player to compare stats',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerModel player) {
    return InkWell(
      onTap: () => setState(() => _comparisonPlayer = player),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0,2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(player.profileImageUrl ?? 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=200&h=200&fit=crop'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Matches: ${player.totalMatches ?? 0}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.compare_arrows, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonState() {
    return KeyedSubtree(
      key: const ValueKey('comparison'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Side-by-side header
            Row(
              children: [
                Expanded(child: _buildComparisonPlayerHeader(widget.currentPlayer)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18)),
                ),
                Expanded(child: _buildComparisonPlayerHeader(_comparisonPlayer!)),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Batting Stats'),
            _buildStatComparisonRow('Matches', widget.currentPlayer.totalMatches ?? 0, _comparisonPlayer!.totalMatches ?? 0),
            _buildStatComparisonRow('Runs', widget.currentPlayer.battingStats?['runs'] ?? 0, _comparisonPlayer!.battingStats?['runs'] ?? 0),
            _buildStatComparisonRow('Average', widget.currentPlayer.battingStats?['average'] ?? 0.0, _comparisonPlayer!.battingStats?['average'] ?? 0.0, isDouble: true),
            _buildStatComparisonRow('Strike Rate', widget.currentPlayer.battingStats?['strike_rate'] ?? 0.0, _comparisonPlayer!.battingStats?['strike_rate'] ?? 0.0, isDouble: true),
            _buildStatComparisonRow('100s', widget.currentPlayer.battingStats?['hundreds'] ?? 0, _comparisonPlayer!.battingStats?['hundreds'] ?? 0),
            _buildStatComparisonRow('50s', widget.currentPlayer.battingStats?['fifties'] ?? 0, _comparisonPlayer!.battingStats?['fifties'] ?? 0),

            const SizedBox(height: 24),
            _buildSectionTitle('Bowling Stats'),
            _buildStatComparisonRow('Wickets', widget.currentPlayer.bowlingStats?['wickets'] ?? 0, _comparisonPlayer!.bowlingStats?['wickets'] ?? 0),
            _buildStatComparisonRow('Average', widget.currentPlayer.bowlingStats?['average'] ?? 0.0, _comparisonPlayer!.bowlingStats?['average'] ?? 0.0, isDouble: true, lowerIsBetter: true),
            _buildStatComparisonRow('Economy', widget.currentPlayer.bowlingStats?['economy'] ?? 0.0, _comparisonPlayer!.bowlingStats?['economy'] ?? 0.0, isDouble: true, lowerIsBetter: true),
            _buildStatComparisonRow('5W', widget.currentPlayer.bowlingStats?['five_w'] ?? 0, _comparisonPlayer!.bowlingStats?['five_w'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonPlayerHeader(PlayerModel player) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(player.profileImageUrl ?? 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=200&h=200&fit=crop'),
        ),
        const SizedBox(height: 12),
        Text(
          player.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildStatComparisonRow(String label, dynamic val1, dynamic val2, {bool isDouble = false, bool lowerIsBetter = false}) {
    final num n1 = val1 is num ? val1 : 0;
    final num n2 = val2 is num ? val2 : 0;
    
    bool is1Better = lowerIsBetter ? n1 < n2 : n1 > n2;
    bool is2Better = lowerIsBetter ? n2 < n1 : n2 > n1;
    if (n1 == n2) {
      is1Better = false;
      is2Better = false;
    }

    String s1 = isDouble ? n1.toStringAsFixed(1) : n1.toString();
    String s2 = isDouble ? n2.toStringAsFixed(1) : n2.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: is1Better ? Colors.green : (is2Better ? Colors.red : AppColors.textMain),
                ),
              ),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(
                s2,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: is2Better ? Colors.green : (is1Better ? Colors.red : AppColors.textMain),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  child: LinearProgressIndicator(
                    value: _calculateProgressValue(n1, n2, true),
                    backgroundColor: Colors.grey[200],
                    color: is1Better ? Colors.green : AppColors.primary,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                    child: LinearProgressIndicator(
                      value: _calculateProgressValue(n1, n2, false),
                      backgroundColor: Colors.grey[200],
                      color: is2Better ? Colors.green : AppColors.primary,
                      minHeight: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgressValue(num n1, num n2, bool first) {
    if (n1 == 0 && n2 == 0) return 0;
    final total = n1 + n2;
    if (first) {
      return (n1 / total).toDouble();
    } else {
      return (n2 / total).toDouble();
    }
  }
}
