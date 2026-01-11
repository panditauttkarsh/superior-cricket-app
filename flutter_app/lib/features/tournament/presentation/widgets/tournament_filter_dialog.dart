import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_providers.dart';

class TournamentFilterDialog extends ConsumerStatefulWidget {
  const TournamentFilterDialog({super.key});

  @override
  ConsumerState<TournamentFilterDialog> createState() => _TournamentFilterDialogState();
}

class _TournamentFilterDialogState extends ConsumerState<TournamentFilterDialog> {
  String? selectedFormat;
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    final filters = ref.read(tournamentFiltersProvider);
    selectedFormat = filters.format;
    selectedStatus = filters.status;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F2A20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1A3D30)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Tournaments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Filter
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D26A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Live Now', 'Upcoming', 'Completed'].map((status) {
                final isSelected = selectedStatus == status;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedStatus = status;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00D26A) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00D26A) : const Color(0xFF1A3D30),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF0A1A14) : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Format Filter
            const Text(
              'Format',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D26A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'T20', 'ODI', 'Test'].map((format) {
                final isSelected = selectedFormat == format || (format == 'All' && selectedFormat == null);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFormat = format == 'All' ? null : format;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00D26A) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00D26A) : const Color(0xFF1A3D30),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      format,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF0A1A14) : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(tournamentFiltersProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00D26A),
                      side: const BorderSide(color: Color(0xFF00D26A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(tournamentFiltersProvider.notifier).updateStatus(selectedStatus);
                      ref.read(tournamentFiltersProvider.notifier).updateFormat(selectedFormat);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D26A),
                      foregroundColor: const Color(0xFF0A1A14),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
