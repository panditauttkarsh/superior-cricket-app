import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, 'Users', '1250', Icons.people, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Matches', '450', Icons.sports_cricket, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, 'Tournaments', '25', Icons.emoji_events, Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, 'Academies', '15', Icons.school, Colors.orange),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Admin Sections
            _buildAdminSection(
              context,
              'User Management',
              Icons.people,
              () {
                // Navigate to user management
              },
            ),
            _buildAdminSection(
              context,
              'Match Scheduling',
              Icons.calendar_today,
              () {
                // Navigate to match scheduling
              },
            ),
            _buildAdminSection(
              context,
              'Tournament Administration',
              Icons.emoji_events,
              () {
                // Navigate to tournament admin
              },
            ),
            _buildAdminSection(
              context,
              'Analytics Dashboard',
              Icons.bar_chart,
              () {
                // Navigate to analytics
              },
            ),
          ],
        ),
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

  Widget _buildAdminSection(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

