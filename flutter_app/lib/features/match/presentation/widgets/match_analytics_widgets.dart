import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/cricket_engine/models/delivery_model.dart';
import 'dart:math' as math;

/// Analytics widgets for match details
/// Includes: Manhattan, Wagon Wheel, Worm, Run Rate, Partnership, Types of Runs, Wickets

class MatchAnalyticsWidgets {
  /// Build Manhattan graph (runs per over)
  static Widget buildManhattanChart({
    required List<DeliveryModel> team1Deliveries,
    required List<DeliveryModel> team2Deliveries,
    required String team1Name,
    required String team2Name,
    required int maxOvers,
  }) {
    // Group deliveries by over for both teams
    final team1OverData = _groupDeliveriesByOver(team1Deliveries, maxOvers);
    final team2OverData = _groupDeliveriesByOver(team2Deliveries, maxOvers);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manhattan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _buildLegendItem(team1Name, Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(team2Name, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBgColor: Colors.grey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final over = group.x.toInt();
                      final runs = rod.toY.toInt();
                      final wickets = _getWicketsInOver(
                        over < team1OverData.length ? team1Deliveries : team2Deliveries,
                        over,
                      );
                      return BarTooltipItem(
                        'Over: $over\nScore: $runs${wickets > 0 ? '\n$wickets W' : ''}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 3 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(maxOvers, (index) {
                  final team1Runs = index < team1OverData.length ? team1OverData[index] : 0;
                  final team2Runs = index < team2OverData.length ? team2OverData[index] : 0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: team1Runs.toDouble(),
                        color: Colors.blue,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: team2Runs.toDouble(),
                        color: Colors.orange,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Wagon Wheel (shot placement)
  static Widget buildWagonWheel({
    required List<DeliveryModel> deliveries,
    required String teamName,
  }) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Wagon Wheel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                ],
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: WagonWheelPainter(deliveries),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            children: [
              _buildWagonWheelLegendItem('Out', Colors.orange),
              _buildWagonWheelLegendItem("0's", Colors.grey[300]!),
              _buildWagonWheelLegendItem("1's", Colors.lightBlue),
              _buildWagonWheelLegendItem("2's and 3's", Colors.yellow),
              _buildWagonWheelLegendItem("4's", Colors.purple),
              _buildWagonWheelLegendItem("6's", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Worm graph (cumulative runs)
  static Widget buildWormChart({
    required List<DeliveryModel> team1Deliveries,
    required List<DeliveryModel> team2Deliveries,
    required String team1Name,
    required String team2Name,
    required int maxOvers,
  }) {
    final team1Data = _getCumulativeRuns(team1Deliveries, maxOvers);
    final team2Data = _getCumulativeRuns(team2Deliveries, maxOvers);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Worm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(team1Name, Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(team2Name, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final over = spot.x.toInt();
                        final runs = spot.y.toInt();
                        return LineTooltipItem(
                          'Over: $over\nScore: $runs',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 20 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: team1Data,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: team2Data,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Run Rate graph
  static Widget buildRunRateChart({
    required List<DeliveryModel> team1Deliveries,
    required List<DeliveryModel> team2Deliveries,
    required String team1Name,
    required String team2Name,
    required int maxOvers,
  }) {
    final team1Data = _getRunRateData(team1Deliveries, maxOvers);
    final team2Data = _getRunRateData(team2Deliveries, maxOvers);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Run rate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(team1Name, Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(team2Name, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: team1Data,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: team2Data,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Partnership chart
  static Widget buildPartnershipChart({
    required List<DeliveryModel> deliveries,
    required String teamName,
  }) {
    final partnerships = _calculatePartnerships(deliveries);

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Partnership',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: partnerships.length,
              itemBuilder: (context, index) {
                final p = partnerships[index];
                return _buildPartnershipBar(p);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build Types of Runs chart
  static Widget buildTypesOfRunsChart({
    required List<DeliveryModel> team1Deliveries,
    required List<DeliveryModel> team2Deliveries,
    required String team1Name,
    required String team2Name,
  }) {
    final team1Runs = _getTypesOfRuns(team1Deliveries);
    final team2Runs = _getTypesOfRuns(team2Deliveries);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Types of Runs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Both Teams',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(team1Name, Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem(team2Name, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 40,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true),
                barGroups: List.generate(6, (index) {
                  final runType = index + 1;
                  final team1Count = team1Runs[runType] ?? 0;
                  final team2Count = team2Runs[runType] ?? 0;
                  
                  return BarChartGroupData(
                    x: runType,
                    barRods: [
                      BarChartRodData(
                        toY: team1Count.toDouble(),
                        color: Colors.blue,
                        width: 8,
                      ),
                      BarChartRodData(
                        toY: team2Count.toDouble(),
                        color: Colors.orange,
                        width: 8,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Wickets pie chart
  static Widget buildWicketsChart({
    required List<DeliveryModel> team1Deliveries,
    required List<DeliveryModel> team2Deliveries,
  }) {
    final allDeliveries = [...team1Deliveries, ...team2Deliveries];
    final wicketTypes = _getWicketTypes(allDeliveries);

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wickets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.filter_list, size: 20), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.share, size: 20), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: wicketTypes.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.value.toStringAsFixed(0)}',
                    color: _getWicketTypeColor(entry.key),
                    radius: 80,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: wicketTypes.entries.map((entry) {
              return _buildWicketLegendItem(entry.key, _getWicketTypeColor(entry.key));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Helper methods
  static List<int> _groupDeliveriesByOver(List<DeliveryModel> deliveries, int maxOvers) {
    final overData = List<int>.filled(maxOvers, 0);
    for (final d in deliveries) {
      if (d.over < maxOvers && d.isLegalBall) {
        overData[d.over] += d.totalRuns;
      }
    }
    return overData;
  }

  static int _getWicketsInOver(List<DeliveryModel> deliveries, int over) {
    return deliveries.where((d) => d.over == over && d.wicketType != null).length;
  }

  static List<FlSpot> _getCumulativeRuns(List<DeliveryModel> deliveries, int maxOvers) {
    final spots = <FlSpot>[];
    int cumulativeRuns = 0;
    int lastOver = 0;
    
    for (final d in deliveries) {
      if (d.over < maxOvers && d.isLegalBall) {
        if (d.over > lastOver) {
          spots.add(FlSpot(lastOver.toDouble(), cumulativeRuns.toDouble()));
        }
        cumulativeRuns += d.totalRuns;
        lastOver = d.over;
      }
    }
    if (lastOver < maxOvers) {
      spots.add(FlSpot(lastOver.toDouble(), cumulativeRuns.toDouble()));
    }
    
    return spots;
  }

  static List<FlSpot> _getRunRateData(List<DeliveryModel> deliveries, int maxOvers) {
    final spots = <FlSpot>[];
    final overData = _groupDeliveriesByOver(deliveries, maxOvers);
    
    for (int i = 0; i < overData.length; i++) {
      final runRate = overData[i].toDouble(); // Runs per over
      spots.add(FlSpot(i.toDouble(), runRate));
    }
    
    return spots;
  }

  static Map<int, int> _getTypesOfRuns(List<DeliveryModel> deliveries) {
    final runs = <int, int>{};
    for (final d in deliveries) {
      if (d.isLegalBall && d.runs > 0) {
        final runType = d.runs.clamp(1, 6);
        runs[runType] = (runs[runType] ?? 0) + 1;
      }
    }
    return runs;
  }

  static Map<String, int> _getWicketTypes(List<DeliveryModel> deliveries) {
    final types = <String, int>{};
    for (final d in deliveries) {
      if (d.wicketType != null) {
        final type = _normalizeWicketType(d.wicketType!);
        types[type] = (types[type] ?? 0) + 1;
      }
    }
    return types;
  }

  static String _normalizeWicketType(String type) {
    if (type.toLowerCase().contains('caught') && type.toLowerCase().contains('behind')) {
      return 'Caught behind';
    } else if (type.toLowerCase().contains('caught')) {
      return 'Caught out';
    } else if (type.toLowerCase().contains('bowled')) {
      return 'Bowled';
    } else if (type.toLowerCase().contains('lbw')) {
      return 'LBW';
    } else if (type.toLowerCase().contains('stumped')) {
      return 'Stumped';
    } else if (type.toLowerCase().contains('run out') || type.toLowerCase().contains('runout')) {
      return 'Run out';
    }
    return type;
  }

  static Color _getWicketTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'caught out':
        return Colors.blue;
      case 'bowled':
        return Colors.orange;
      case 'caught behind':
        return Colors.yellow;
      case 'lbw':
        return Colors.green;
      case 'stumped':
        return Colors.teal;
      case 'run out':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static List<Map<String, dynamic>> _calculatePartnerships(List<DeliveryModel> deliveries) {
    // Simplified partnership calculation
    // In real implementation, track batsmen pairs
    final partnerships = <Map<String, dynamic>>[];
    String? currentBatsman1;
    String? currentBatsman2;
    int partnershipRuns = 0;
    int partnershipBalls = 0;
    
    for (final d in deliveries) {
      if (d.isLegalBall) {
        if (currentBatsman1 == null) {
          currentBatsman1 = d.striker;
          currentBatsman2 = d.nonStriker;
        }
        
        if (d.striker == currentBatsman1 || d.striker == currentBatsman2) {
          partnershipRuns += d.runs;
          partnershipBalls++;
        } else {
          // New partnership
          if (currentBatsman1 != null && currentBatsman2 != null) {
            partnerships.add({
              'player1': currentBatsman1,
              'player2': currentBatsman2,
              'runs': partnershipRuns,
              'balls': partnershipBalls,
            });
          }
          currentBatsman1 = d.striker;
          currentBatsman2 = d.nonStriker;
          partnershipRuns = d.runs;
          partnershipBalls = 1;
        }
        
        if (d.wicketType != null) {
          // Partnership ended
          if (currentBatsman1 != null && currentBatsman2 != null) {
            partnerships.add({
              'player1': currentBatsman1,
              'player2': currentBatsman2,
              'runs': partnershipRuns,
              'balls': partnershipBalls,
            });
          }
          currentBatsman1 = null;
          currentBatsman2 = null;
          partnershipRuns = 0;
          partnershipBalls = 0;
        }
      }
    }
    
    return partnerships;
  }

  static Widget _buildPartnershipBar(Map<String, dynamic> partnership) {
    final player1 = partnership['player1'] as String? ?? 'Unknown';
    final player2 = partnership['player2'] as String? ?? 'Unknown';
    final runs = partnership['runs'] as int? ?? 0;
    final balls = partnership['balls'] as int? ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$player1 $runs($balls)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: runs / 100.0,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$player2',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static Widget _buildWagonWheelLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  static Widget _buildWicketLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

/// Custom painter for Wagon Wheel
class WagonWheelPainter extends CustomPainter {
  final List<DeliveryModel> deliveries;

  WagonWheelPainter(this.deliveries);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    
    // Draw field (semicircle)
    final fieldPaint = Paint()
      ..color = Colors.green[100]!
      ..style = PaintingStyle.fill;
    
    final fieldPath = Path()
      ..moveTo(0, size.height)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(size.width, size.height)
      ..close();
    
    canvas.drawPath(fieldPath, fieldPaint);
    
    // Draw boundary
    final boundaryPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      boundaryPaint,
    );
    
    // Draw pitch
    final pitchPaint = Paint()
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;
    
    final pitchRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 20),
      width: 20,
      height: 60,
    );
    canvas.drawRect(pitchRect, pitchPaint);
    
    // Draw shots
    for (final d in deliveries) {
      if (d.isLegalBall && d.runs > 0) {
        final angle = _getShotAngle(d.runs);
        final distance = _getShotDistance(d.runs);
        final shotPaint = Paint()
          ..color = _getShotColor(d.runs, d.wicketType != null)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        
        final endX = center.dx + math.cos(angle) * distance * radius;
        final endY = center.dy - math.sin(angle) * distance * radius;
        
        canvas.drawLine(
          Offset(center.dx, center.dy - 30),
          Offset(endX, endY),
          shotPaint,
        );
      }
    }
  }

  double _getShotAngle(int runs) {
    // Simplified: distribute shots across field
    return (runs % 7) * (math.pi / 7) + math.pi / 2;
  }

  double _getShotDistance(int runs) {
    if (runs == 6) return 0.95;
    if (runs == 4) return 0.85;
    if (runs >= 2) return 0.6;
    return 0.3;
  }

  Color _getShotColor(int runs, bool isOut) {
    if (isOut) return Colors.orange;
    if (runs == 0) return Colors.grey[300]!;
    if (runs == 1) return Colors.lightBlue;
    if (runs >= 2 && runs <= 3) return Colors.yellow;
    if (runs == 4) return Colors.purple;
    if (runs == 6) return Colors.red;
    return Colors.grey;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

