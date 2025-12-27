import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TournamentListPage extends StatelessWidget {
  const TournamentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => context.push('/tournament/${index + 1}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Tournament ${index + 1}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Chip(
                          label: const Text('Ongoing'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Premier cricket tournament'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        const Text('Mar 1 - Mar 31, 2024'),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        const Text('Mumbai'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.groups, size: 16),
                        const SizedBox(width: 4),
                        const Text('6/8 Teams'),
                        const SizedBox(width: 16),
                        const Icon(Icons.emoji_events, size: 16),
                        const SizedBox(width: 4),
                        const Text('₹1,00,000'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create tournament
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
      ),
    );
  }
}

