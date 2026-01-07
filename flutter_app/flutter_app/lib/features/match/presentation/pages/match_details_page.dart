import 'package:flutter/material.dart';

class MatchDetailsPage extends StatelessWidget {
  final String matchId;
  
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Squads'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfo(),
            _buildSquads(),
            _buildScorecard(),
            _buildCommentary(),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Match Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Date: March 15, 2024'),
              Text('Type: T20'),
              Text('Venue: Wankhede Stadium, Mumbai'),
              Text('Status: Live'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquads() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Team 1 Squad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...List.generate(11, (index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Player ${index + 1}'),
          subtitle: const Text('Batsman'),
        )),
      ],
    );
  }

  Widget _buildScorecard() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Scorecard details...'),
        ),
      ),
    );
  }

  Widget _buildCommentary() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text('16.$index'),
            title: const Text('FOUR! Beautiful cover drive.'),
            trailing: const Text('+4', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.event, color: Colors.white),
            ),
            title: Text('Event ${index + 1}'),
            subtitle: const Text('Match event description'),
            trailing: const Text('14:30'),
          ),
        );
      },
    );
  }
}

