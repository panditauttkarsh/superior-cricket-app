import 'package:flutter/material.dart';

class PointsTablePage extends StatelessWidget {
  final String tournamentId;
  
  const PointsTablePage({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Table'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Pos')),
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('P')),
                DataColumn(label: Text('W')),
                DataColumn(label: Text('L')),
                DataColumn(label: Text('T')),
                DataColumn(label: Text('NR')),
                DataColumn(label: Text('Pts')),
                DataColumn(label: Text('NRR')),
              ],
              rows: List.generate(6, (index) {
                final isTopThree = index < 3;
                return DataRow(
                  color: isTopThree
                      ? MaterialStateProperty.all(Colors.amber.withOpacity(0.1))
                      : null,
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text('Team ${index + 1}')),
                    DataCell(Text('5')),
                    DataCell(Text('${4 - index}')),
                    DataCell(Text('${1 + index}')),
                    DataCell(Text('0')),
                    DataCell(Text('0')),
                    DataCell(Text('${8 - index * 2}')),
                    DataCell(Text('${0.85 - index * 0.1}')),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

