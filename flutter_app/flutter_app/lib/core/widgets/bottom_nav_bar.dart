import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.home,
              'Home',
              0,
              '/',
              currentLocation,
            ),
            _buildNavItem(
              context,
              Icons.sports_cricket,
              'Matches',
              1,
              '/matches',
              currentLocation,
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              context,
              Icons.newspaper,
              'Feed',
              2,
              '/feed',
              currentLocation,
            ),
            _buildNavItem(
              context,
              Icons.person,
              'Profile',
              3,
              '/profile',
              currentLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    String path,
    String currentLocation,
  ) {
    final isActive = currentLocation == path || 
                     (path == '/' && currentLocation == '/') ||
                     (path != '/' && currentLocation.startsWith(path));
    
    return GestureDetector(
      onTap: () => context.go(path),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1B5E20) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1B5E20) : Colors.grey[600],
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
