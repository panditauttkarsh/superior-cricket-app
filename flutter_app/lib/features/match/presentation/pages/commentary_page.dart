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

class CommentaryPage extends ConsumerWidget {
  final String matchId;
  final bool showAppBar;

  const CommentaryPage({
    super.key,
    required this.matchId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentaryAsync = ref.watch(commentaryStreamProvider(matchId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: showAppBar
          ? AppBar(
              title: const Text('Ball-by-Ball Commentary'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: commentaryAsync.when(
        data: (commentaryList) {
          if (commentaryList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No commentary yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commentary will appear here as the match progresses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Debug: Print commentary list
          print('Commentary: Displaying ${commentaryList.length} entries');
          for (var entry in commentaryList) {
            print('Commentary: ${entry.over} - ${entry.commentaryText}');
          }
          
          // Sort by timestamp first (strict chronological order), then by over as fallback
          // This ensures Innings 1 (earlier) comes before Innings 2 (later)
          final sortedList = List<CommentaryModel>.from(commentaryList)
            ..sort((a, b) {
              final timeCompare = a.timestamp.compareTo(b.timestamp);
              if (timeCompare != 0) return timeCompare;
              return a.over.compareTo(b.over);
            });
          
          // Convert to grouped format
          var groupedCommentary = _groupCommentaryWithSummaries(sortedList);
          
          // Reverse for display (newest first in UI)
          // Since ListView has reverse: true, we reverse the list so newest appears at bottom
          groupedCommentary = groupedCommentary.reversed.toList();
          
          print('Commentary: Grouped into ${groupedCommentary.length} items');
          
          return ListView.builder(
            reverse: true, // Show latest at bottom, but scroll to bottom
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: groupedCommentary.length,
            itemBuilder: (context, index) {
              final item = groupedCommentary[index];
              final isLatest = index == 0; // Latest is first in reversed list
              
              if (item['type'] == 'overSummary') {
                return OverSummaryCard(
                  summaryText: item['text'] as String,
                  isLatest: isLatest,
                );
              } else if (item['type'] == 'inningsBreak') {
                return const InningsBreakCard();
              } else {
                final commentary = item['commentary'] as CommentaryModel;
                // Skip newBatsman entries in grouping, show them directly
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
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading commentary',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        // Extract over number from summary text (e.g., "OVER 16" -> 16)
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
    
    // Second pass: add ALL entries, inserting summaries before their over's balls
    // List is chronological (oldest to newest)
    int? currentOverInt = -1;
    double? lastOverDouble = -1.0;
    
    for (final commentary in commentaryList) {
      // Skip over summaries in main loop, we'll insert them manually
      if (commentary.ballType == 'overSummary') {
        continue;
      }
      
      final overNumInt = commentary.over.toInt();
      final currentOverDouble = commentary.over;
      
      // Check for Innings Break detection (Current ball is "earlier" than last ball)
      // e.g. 19.6 -> 0.1 OR 0.5 -> 0.1
      if (lastOverDouble != -1.0 && currentOverDouble < lastOverDouble!) {
         // Force insert summary for previous over if pending (cleanup)
         if (currentOverInt != -1 && overSummaries.containsKey(currentOverInt)) {
            grouped.add(overSummaries[currentOverInt]!);
            overSummaries.remove(currentOverInt);
         }
         
         grouped.add({
           'type': 'inningsBreak', 
           'text': 'Innings Break',
           'timestamp': commentary.timestamp,
         });
         
         // Reset tracking for new innings
         currentOverInt = -1; 
      }
      
      // If we've moved to a new over (integer change)
      if (currentOverInt != -1 && overNumInt != currentOverInt) {
        // Insert summary for the COMPLETED over
        if (overSummaries.containsKey(currentOverInt)) {
          grouped.add(overSummaries[currentOverInt]!);
          overSummaries.remove(currentOverInt);
        }
      }
      
      // Add regular commentary entry
      grouped.add({
        'type': 'commentary',
        'commentary': commentary,
        'over': overNumInt,
      });
      
      currentOverInt = overNumInt;
      lastOverDouble = currentOverDouble;
    }
    
    // Add summary for the last over if exists
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
      margin: const EdgeInsets.symmetric(vertical: 24),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                'New batsman: $batsmanName comes to the crease',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[900],
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
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
      margin: const EdgeInsets.only(bottom: 20, top: 12),
      decoration: BoxDecoration(
        color: isLatest ? AppColors.primary.withOpacity(0.1) : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? AppColors.primary : Colors.blue[300]!,
          width: isLatest ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Over Title
            Text(
              overTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Ball Runs (6 legal ball outcomes)
            Text(
              ballRuns,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 2.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Summary (Runs | Wickets | Match Score)
            Text(
              summary,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                height: 1.5,
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
                    fontSize: 13,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLatest 
            ? AppColors.primary.withOpacity(0.05) 
            : isWicket 
                ? Colors.red[50] 
                : isBoundary
                    ? Colors.blue[50]
                    : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest 
              ? AppColors.primary.withOpacity(0.3) 
              : isWicket
                  ? Colors.red[200]!
                  : isBoundary
                      ? Colors.blue[200]!
                      : Colors.grey[300]!,
          width: isLatest ? 2 : isWicket || isBoundary ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Over and Ball Type
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getBallTypeColor(commentary.ballType),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    commentary.overDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 16),
            // Commentary Text
            Text(
              commentary.commentaryText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[900],
                fontWeight: isLatest || isWicket || isBoundary 
                    ? FontWeight.w600 
                    : FontWeight.w400,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (commentary.runs > 0) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${commentary.strikerName} • ${commentary.bowlerName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Timestamp (optional, show relative time)
                Text(
                  _formatTimestamp(commentary.timestamp),
                  style: TextStyle(
                    fontSize: 12,
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

