import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerDashboardPage extends ConsumerStatefulWidget {
  const PlayerDashboardPage({super.key});

  @override
  ConsumerState<PlayerDashboardPage> createState() => _PlayerDashboardPageState();
}

class _PlayerDashboardPageState extends ConsumerState<PlayerDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Batting'),
            Tab(icon: Icon(Icons.circle), text: 'Bowling'),
            Tab(icon: Icon(Icons.shield), text: 'Fielding'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBattingStats(),
          _buildBowlingStats(),
          _buildFieldingStats(),
        ],
      ),
    );
  }

  Widget _buildBattingStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Matches', '25', Icons.calendar_today),
          _buildStatCard('Runs', '1250', Icons.trending_up),
          _buildStatCard('Average', '35.71', Icons.bar_chart),
          _buildStatCard('Strike Rate', '69.44', Icons.speed),
          _buildStatCard('Highest Score', '89', Icons.emoji_events),
          _buildStatCard('Centuries', '0', Icons.star),
          _buildStatCard('Half Centuries', '8', Icons.star_border),
        ],
      ),
    );
  }

  Widget _buildBowlingStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Matches', '25', Icons.calendar_today),
          _buildStatCard('Wickets', '32', Icons.circle),
          _buildStatCard('Average', '14.06', Icons.bar_chart),
          _buildStatCard('Economy', '5.27', Icons.speed),
          _buildStatCard('Best Bowling', '4/25', Icons.emoji_events),
          _buildStatCard('4 Wickets', '2', Icons.star),
          _buildStatCard('5 Wickets', '0', Icons.star_border),
        ],
      ),
    );
  }

  Widget _buildFieldingStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('Catches', '18', Icons.shield),
          _buildStatCard('Stumpings', '0', Icons.handshake),
          _buildStatCard('Run Outs', '5', Icons.running_with_errors),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

