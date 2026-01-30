import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/commentary_model.dart';
import '../../../../core/repositories/commentary_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

/// Provider for commentary stream with initial data and real-time updates
final commentaryStreamProvider = StreamProvider.family<List<CommentaryModel>, String>((ref, matchId) async* {
  final repository = ref.watch(commentaryRepositoryProvider);
  
  // First, fetch all existing commentary
  print('Commentary: Provider - Starting for matchId=$matchId');
  final initialCommentary = await repository.getCommentaryByMatchId(matchId);
  print('Commentary: Provider - Initial fetch got ${initialCommentary.length} entries');
  yield initialCommentary;
  
  // Then stream updates - each update will refetch ALL entries
  print('Commentary: Provider - Starting stream for matchId=$matchId');
  yield* repository.streamCommentary(matchId);
});

class CommentaryPage extends ConsumerStatefulWidget {
  final String matchId;
  final bool showAppBar;

  const CommentaryPage({
    super.key,
    required this.matchId,
    this.showAppBar = false,
  });

  @override
  ConsumerState<CommentaryPage> createState() => _CommentaryPageState();
}

class _CommentaryPageState extends ConsumerState<CommentaryPage> {
  bool _isInnings1Expanded = false;
  bool _isInnings2Expanded = true;
  bool _hasInitializedExpansion = false;

  @override
  Widget build(BuildContext context) {
    final commentaryAsync = ref.watch(commentaryStreamProvider(widget.matchId));

    final content = commentaryAsync.when(
      data: (commentaryList) {
        if (commentaryList.isEmpty) {
          return _buildEmptyState();
        }

        final sortedList = List<CommentaryModel>.from(commentaryList)
          ..sort((a, b) {
            final timeCompare = a.timestamp.compareTo(b.timestamp);
            if (timeCompare != 0) return timeCompare;
            return a.over.compareTo(b.over);
          });
        
        final inningsData = _splitCommentaryByInnings(sortedList);
        final inn1Grouped = _groupCommentaryWithSummaries(inningsData['inn1']!).reversed.toList();
        final inn2Grouped = _groupCommentaryWithSummaries(inningsData['inn2']!).reversed.toList();

        // Initialize expansion state once we have data
        if (!_hasInitializedExpansion) {
          if (inn2Grouped.isNotEmpty) {
            _isInnings1Expanded = false;
            _isInnings2Expanded = true;
          } else {
            _isInnings1Expanded = true;
            _isInnings2Expanded = false;
          }
          _hasInitializedExpansion = true;
        }

        if (widget.showAppBar) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (inn2Grouped.isNotEmpty) ...[
                _buildInningsHeader(
                  title: 'Second Innings',
                  isExpanded: _isInnings2Expanded,
                  onTap: () => setState(() => _isInnings2Expanded = !_isInnings2Expanded),
                ),
                if (_isInnings2Expanded)
                  ...inn2Grouped.map((item) => _buildCommentaryItem(item, item == inn2Grouped.first)),
                const SizedBox(height: 16),
              ],
              _buildInningsHeader(
                title: 'First Innings',
                isExpanded: _isInnings1Expanded,
                onTap: () => setState(() => _isInnings1Expanded = !_isInnings1Expanded),
              ),
              if (_isInnings1Expanded)
                ...inn1Grouped.map((item) => _buildCommentaryItem(item, item == inn1Grouped.first && inn2Grouped.isEmpty)),
            ],
          );
        }

        // Inline view (e.g. in tabs) - show all grouped (latest first)
        var allGrouped = _groupCommentaryWithSummaries(sortedList);
        allGrouped = allGrouped.reversed.toList();
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: allGrouped.length,
          itemBuilder: (context, index) => _buildCommentaryItem(allGrouped[index], index == 0),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Match Commentary'),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: content,
      );
    }
    return content;
  }

  Widget _buildInningsHeader({required String title, required bool isExpanded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentaryItem(Map<String, dynamic> item, bool isLatest) {
    if (item['type'] == 'overSummary') {
      return OverSummaryCard(
        summaryText: item['text'] as String,
        isLatest: isLatest,
      );
    } else if (item['type'] == 'inningsBreak') {
      return const InningsBreakCard();
    } else {
      final commentary = item['commentary'] as CommentaryModel;
      if (commentary.ballType == 'newBatsman') {
        return NewBatsmanCard(
          batsmanName: commentary.strikerName,
          isLatest: isLatest,
        );
      }
      return CommentaryCard(
        commentary: commentary,
        isLatest: isLatest,
      );
    }
  }

  Map<String, List<CommentaryModel>> _splitCommentaryByInnings(List<CommentaryModel> list) {
    final List<CommentaryModel> inn1 = [];
    final List<CommentaryModel> inn2 = [];
    
    double? lastOver = -1.0;
    bool inInnings2 = false;

    for (final item in list) {
      if (lastOver != -1.0 && item.over < lastOver!) {
        inInnings2 = true;
      }
      
      if (inInnings2) {
        inn2.add(item);
      } else {
        inn1.add(item);
      }
      lastOver = item.over;
    }
    
    return {'inn1': inn1, 'inn2': inn2};
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No commentary yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Commentary will appear as the match progresses',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Couldn\'t load commentary', style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error.toString(), style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Group commentary entries and insert over summaries and innings breaks
  List<Map<String, dynamic>> _groupCommentaryWithSummaries(List<CommentaryModel> commentaryList) {
    final List<Map<String, dynamic>> grouped = [];
    final Map<int, Map<String, dynamic>> overSummaries = {};
    
    // First pass: collect over summaries
    for (final commentary in commentaryList) {
      if (commentary.ballType == 'overSummary') {
        final match = RegExp(r'OVER (\d+)').firstMatch(commentary.commentaryText);
        if (match != null) {
          final overNum = int.parse(match.group(1)!);
          overSummaries[overNum] = {
            'type': 'overSummary',
            'text': commentary.commentaryText,
            'over': overNum,
            'timestamp': commentary.timestamp,
          };
        }
      }
    }
    
    int? currentOverInt = -1;
    double? lastOverDouble = -1.0;
    
    for (final commentary in commentaryList) {
      if (commentary.ballType == 'overSummary') continue;
      
      final overNumInt = commentary.over.toInt();
      final currentOverDouble = commentary.over;
      
      if (lastOverDouble != -1.0 && currentOverDouble < lastOverDouble!) {
         if (currentOverInt != -1 && overSummaries.containsKey(currentOverInt)) {
            grouped.add(overSummaries[currentOverInt]!);
            overSummaries.remove(currentOverInt);
         }
         grouped.add({
           'type': 'inningsBreak', 
           'text': 'Innings Break',
           'timestamp': commentary.timestamp,
         });
         currentOverInt = -1; 
      }
      
      if (currentOverInt != -1 && overNumInt != currentOverInt) {
        if (overSummaries.containsKey(currentOverInt)) {
          grouped.add(overSummaries[currentOverInt]!);
          overSummaries.remove(currentOverInt);
        }
      }
      
      grouped.add({
        'type': 'commentary',
        'commentary': commentary,
        'over': overNumInt,
      });
      
      currentOverInt = overNumInt;
      lastOverDouble = currentOverDouble;
    }
    
    if (currentOverInt != -1 && overSummaries.containsKey(currentOverInt)) {
      grouped.add(overSummaries[currentOverInt]!);
    }
    
    return grouped;
  }
}

class InningsBreakCard extends StatelessWidget {
  const InningsBreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_cricket, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'INNINGS BREAK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.primary, thickness: 1)),
        ],
      ),
    );
  }
}


/// New Batsman Card Widget
class NewBatsmanCard extends StatelessWidget {
  final String batsmanName;
  final bool isLatest;

  const NewBatsmanCard({
    super.key,
    required this.batsmanName,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[300]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: Colors.green[700],
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'New batsman: $batsmanName',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[900],
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Over Summary Card Widget
class OverSummaryCard extends StatelessWidget {
  final String summaryText;
  final bool isLatest;

  const OverSummaryCard({
    super.key,
    required this.summaryText,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final lines = summaryText.split('\n');
    final overTitle = lines.isNotEmpty ? lines[0] : '';
    final ballRuns = lines.length > 1 ? lines[1] : '';
    final summary = lines.length > 2 ? lines[2] : '';
    final battingPair = lines.length > 3 ? lines[3] : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.primary.withOpacity(0.1) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest ? AppColors.primary : Colors.blue[300]!,
          width: isLatest ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Over Title
            Text(
              overTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            // Ball Runs (6 legal ball outcomes)
            Text(
              ballRuns,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 1.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Summary (Runs | Wickets | Match Score)
            Text(
              summary,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            // Batting Pair Stats (after end-of-over strike rotation)
            if (battingPair.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  battingPair,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommentaryCard extends StatelessWidget {
  final CommentaryModel commentary;
  final bool isLatest;

  const CommentaryCard({
    super.key,
    required this.commentary,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWicket = commentary.ballType == 'wicket';
    final isBoundary = commentary.runs == 4 || commentary.runs == 6;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isLatest 
            ? AppColors.primary.withOpacity(0.05) 
            : isWicket 
                ? Colors.red[50] 
                : isBoundary
                    ? Colors.blue[50]
                    : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest 
              ? AppColors.primary.withOpacity(0.3) 
              : isWicket
                  ? Colors.red[200]!
                  : isBoundary
                      ? Colors.blue[200]!
                      : Colors.grey[300]!,
          width: isLatest ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Over and Ball Type
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getBallTypeColor(commentary.ballType),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    commentary.overDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const Spacer(),
                if (commentary.isExtra)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      commentary.extraType ?? 'EXTRA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Commentary Text
            Text(
              commentary.commentaryText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[900],
                fontWeight: isLatest || isWicket || isBoundary 
                    ? FontWeight.w600 
                    : FontWeight.w400,
                height: 1.4,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),
            // Runs and Players Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (commentary.runs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRunsColor(commentary.runs),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${commentary.runs} run${commentary.runs > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (commentary.runs > 0) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${commentary.strikerName} • ${commentary.bowlerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Timestamp (optional, show relative time)
                Text(
                  _formatTimestamp(commentary.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBallTypeColor(String ballType) {
    switch (ballType) {
      case 'wicket':
        return Colors.red;
      case 'wide':
      case 'noBall':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Color _getRunsColor(int runs) {
    if (runs == 6) return Colors.purple;
    if (runs == 4) return Colors.blue;
    if (runs >= 1) return Colors.green;
    return Colors.grey;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

