import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/points_table_providers.dart';

class PointsTableTab extends ConsumerWidget {
  final String tournamentId;

  const PointsTableTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(pointsTableProvider(tournamentId));

    return standingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load points table\n$error',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 64,
                    color: AppColors.textMeta,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Points table will appear once matches are completed.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSec,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Team',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    _buildHeaderColumn('M'),
                    _buildHeaderColumn('W'),
                    _buildHeaderColumn('L'),
                    _buildHeaderColumn('T'),
                    _buildHeaderColumn('NR'),
                    _buildHeaderColumn('Pt.'),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'NRR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSec,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Table rows
              ...entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final nrr = entry.netRunRate;
                final isEven = index % 2 == 0;

                Color nrrColor;
                if (nrr > 0.001) {
                  nrrColor = Colors.green[700]!;
                } else if (nrr < -0.001) {
                  nrrColor = Colors.red[700]!;
                } else {
                  nrrColor = AppColors.textSec;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : AppColors.surface.withOpacity(0.5),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderLight ?? Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.teamName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildDataColumn(entry.played.toString()),
                      _buildDataColumn(entry.won.toString()),
                      _buildDataColumn(entry.lost.toString()),
                      _buildDataColumn(entry.tied.toString()),
                      _buildDataColumn(entry.noResult.toString()),
                      _buildDataColumn(entry.points.toString()),
                      SizedBox(
                        width: 50,
                        child: Text(
                          nrr.toStringAsFixed(3),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nrrColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildHeaderColumn(String label) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSec,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget _buildDataColumn(String value) {
    return SizedBox(
      width: 32,
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

