import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  
  const TournamentDetailsPage({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Teams'),
              Tab(text: 'Fixtures'),
              Tab(text: 'Points'),
              Tab(text: 'Leaderboards'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(context),
            _buildTeams(context),
            _buildFixtures(context),
            _buildPoints(context),
            _buildLeaderboards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, 'Dates', 'Mar 1 - Mar 31, 2024'),
                  _buildInfoRow(Icons.location_on, 'Location', 'Mumbai'),
                  _buildInfoRow(Icons.groups, 'Teams', '6/8'),
                  _buildInfoRow(Icons.emoji_events, 'Prize Pool', '₹1,00,000'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: '),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTeams(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.groups),
            ),
            title: Text('Team ${index + 1}'),
            subtitle: const Text('Registered: Mar 1, 2024'),
            trailing: const Chip(
              label: Text('Confirmed'),
              backgroundColor: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFixtures(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.sports_cricket),
            title: Text('Match #${index + 1}'),
            subtitle: const Text('Team 1 vs Team 2 • Mar 5, 2024'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/matches/${index + 1}'),
          ),
        );
      },
    );
  }

  Widget _buildPoints(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Pos')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('P')),
            DataColumn(label: Text('W')),
            DataColumn(label: Text('L')),
            DataColumn(label: Text('Pts')),
          ],
          rows: List.generate(6, (index) {
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text('Team ${index + 1}')),
                DataCell(Text('${5 + index}')),
                DataCell(Text('${4 - index}')),
                DataCell(Text('${1 + index}')),
                DataCell(Text('${8 - index * 2}')),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLeaderboards(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.leaderboard,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'View Tournament Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/tournament/$tournamentId/leaderboard'),
            icon: const Icon(Icons.emoji_events),
            label: const Text('Open Leaderboard'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

