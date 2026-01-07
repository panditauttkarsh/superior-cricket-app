import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachDashboardPage extends StatelessWidget {
  const CoachDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, 'Teams', '3', Icons.groups, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Players', '45', Icons.people, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, 'Matches', '25', Icons.sports_cricket, Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Win Rate', '72%', Icons.trending_up, Colors.orange),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Teams List
            Text(
              'My Teams',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups),
                    ),
                    title: Text('Team ${index + 1}'),
                    subtitle: const Text('Mumbai, Maharashtra'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/coach/teams/${index + 1}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create new team
        },
        icon: const Icon(Icons.add),
        label: const Text('New Team'),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

