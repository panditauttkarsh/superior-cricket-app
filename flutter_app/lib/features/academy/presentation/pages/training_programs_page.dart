import 'package:flutter/material.dart';

class TrainingProgramsPage extends StatelessWidget {
  final String academyId;
  
  const TrainingProgramsPage({super.key, required this.academyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Programs'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
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
                          'Program ${index + 1}',
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
                  const Text('Focus on power hitting and timing'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      const Text('Coach Name'),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      const Text('Mon, Wed, Fri'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      const Text('16:00 • 120 min'),
                      const SizedBox(width: 16),
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 4),
                      const Text('12/15 Students'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create program
        },
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
    );
  }
}

