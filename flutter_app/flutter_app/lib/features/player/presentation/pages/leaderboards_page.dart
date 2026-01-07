import 'package:flutter/material.dart';

class LeaderboardsPage extends StatelessWidget {
  const LeaderboardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboards'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Runs'),
              Tab(text: 'Wickets'),
              Tab(text: 'Average'),
              Tab(text: 'Strike Rate'),
              Tab(text: 'Economy'),
              Tab(text: 'Catches'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeaderboardList('runs'),
            _buildLeaderboardList('wickets'),
            _buildLeaderboardList('average'),
            _buildLeaderboardList('strike-rate'),
            _buildLeaderboardList('economy'),
            _buildLeaderboardList('catches'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String type) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isTopThree = index < 3;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isTopThree ? Colors.amber.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTopThree ? Colors.amber : Colors.grey,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isTopThree ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('Player ${index + 1}'),
            subtitle: Text('Team Name'),
            trailing: Text(
              '${1000 - (index * 50)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

