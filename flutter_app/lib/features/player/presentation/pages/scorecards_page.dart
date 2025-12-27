import 'package:flutter/material.dart';

class ScorecardsPage extends StatelessWidget {
  const ScorecardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scorecards'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.sports_cricket),
              title: Text('Match #${index + 1}'),
              subtitle: const Text('2024-03-15 • T20'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('Runs', '45'),
                      _buildStatRow('Balls', '38'),
                      _buildStatRow('Strike Rate', '118.42'),
                      _buildStatRow('Fours', '5'),
                      _buildStatRow('Sixes', '2'),
                      const Divider(),
                      _buildStatRow('Overs', '4.0'),
                      _buildStatRow('Wickets', '2'),
                      _buildStatRow('Economy', '7.0'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

